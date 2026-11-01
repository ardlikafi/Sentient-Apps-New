import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:sentient/features/chat/models/chat_message_model.dart';
import 'package:sentient/core/services/fcm_sender_service.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get currentUserId => _auth.currentUser?.uid;

  /// Generate ID ruang chat yang konsisten untuk 2 pengguna
  static String getChatRoomId(String userIdA, String userIdB) {
    return userIdA.compareTo(userIdB) < 0 ? '${userIdA}_$userIdB' : '${userIdB}_$userIdA';
  }

  /// Kirim pesan chat (teks, ajakan catur, emotikon)
  static Future<void> sendMessage({
    required String targetUserId,
    required String text,
    String type = 'text',
    String? challengeId,
    String? matchId,
    required String currentUserName,
    String? currentUserAvatar,
  }) async {
    final senderId = currentUserId;
    if (senderId == null) return;

    final roomId = getChatRoomId(senderId, targetUserId);

    try {
      final msgRef = _firestore
          .collection('chat_rooms')
          .doc(roomId)
          .collection('messages')
          .doc();

      final message = ChatMessageModel(
        id: msgRef.id,
        senderId: senderId,
        senderName: currentUserName,
        senderAvatar: currentUserAvatar,
        receiverId: targetUserId,
        text: text,
        type: type,
        challengeId: challengeId,
        matchId: matchId,
        challengeStatus: (type == 'chess_invite') ? 'pending' : null,
        timestamp: DateTime.now(),
        isRead: false,
      );

      await msgRef.set(message.toMap());

      // Update metadata room untuk daftar percakapan terbaru
      await _firestore.collection('chat_rooms').doc(roomId).set({
        'room_id': roomId,
        'users': [senderId, targetUserId],
        'last_message': text,
        'last_message_type': type,
        'last_sender_id': senderId,
        'last_sender_name': currentUserName,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('Message sent successfully to room: $roomId');

      // Kirim push notifikasi langsung via Google FCM HTTP v1 ke HP penerima
      unawaited(FcmSenderService.sendChatNotification(
        receiverId: targetUserId,
        senderId: senderId,
        senderName: currentUserName,
        senderAvatar: currentUserAvatar,
        text: text,
        type: type,
        challengeId: challengeId,
      ));
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  /// Update matchId dan status tantangan pada pesan ajakan catur
  static Future<void> updateMessageMatchId({
    required String targetUserId,
    required String messageId,
    required String matchId,
  }) async {
    final senderId = currentUserId;
    if (senderId == null) return;
    final roomId = getChatRoomId(senderId, targetUserId);

    try {
      await _firestore
          .collection('chat_rooms')
          .doc(roomId)
          .collection('messages')
          .doc(messageId)
          .update({
        'match_id': matchId,
        'challenge_status': 'accepted',
      });
    } catch (e) {
      debugPrint('Error updating message match_id: $e');
    }
  }

  /// Update status tantangan catur pada pesan chat (pending, accepted, declined, completed, aborted)
  static Future<void> updateMessageChallengeStatus({
    required String targetUserId,
    required String messageId,
    required String status,
    String? matchId,
  }) async {
    final senderId = currentUserId;
    if (senderId == null) return;
    final roomId = getChatRoomId(senderId, targetUserId);

    try {
      final updateData = <String, dynamic>{
        'challenge_status': status,
      };
      if (matchId != null) {
        updateData['match_id'] = matchId;
      }
      await _firestore
          .collection('chat_rooms')
          .doc(roomId)
          .collection('messages')
          .doc(messageId)
          .update(updateData);
    } catch (e) {
      debugPrint('Error updating message challenge_status: $e');
    }
  }

  /// Update status pesan tantangan catur berdasarkan challengeId
  static Future<void> updateChallengeStatusByChallengeId({
    required String targetUserId,
    required String challengeId,
    required String status,
    String? matchId,
  }) async {
    final senderId = currentUserId;
    if (senderId == null) return;
    final roomId = getChatRoomId(senderId, targetUserId);

    try {
      final snap = await _firestore
          .collection('chat_rooms')
          .doc(roomId)
          .collection('messages')
          .where('challenge_id', isEqualTo: challengeId)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final updateData = <String, dynamic>{
          'challenge_status': status,
        };
        if (matchId != null) updateData['match_id'] = matchId;
        await snap.docs.first.reference.update(updateData);
      }
    } catch (e) {
      debugPrint('Error updating challenge status by challengeId: $e');
    }
  }

  /// Sinkronkan status tantangan catur ke pesan chat di semua room secara otomatis
  static Future<void> syncChallengeStatus({
    required String challengeId,
    required String status,
    String? matchId,
    String? user1Id,
    String? user2Id,
  }) async {
    if (challengeId.isEmpty) return;
    try {
      if (user1Id != null && user2Id != null) {
        final roomId = getChatRoomId(user1Id, user2Id);
        final snap = await _firestore
            .collection('chat_rooms')
            .doc(roomId)
            .collection('messages')
            .where('challenge_id', isEqualTo: challengeId)
            .get();
        for (final doc in snap.docs) {
          final updateData = <String, dynamic>{
            'challenge_status': status,
          };
          if (matchId != null) updateData['match_id'] = matchId;
          await doc.reference.update(updateData);
        }
      }

      // Fallback update pada collectionGroup messages
      final groupSnap = await _firestore
          .collectionGroup('messages')
          .where('challenge_id', isEqualTo: challengeId)
          .get();
      for (final doc in groupSnap.docs) {
        final updateData = <String, dynamic>{
          'challenge_status': status,
        };
        if (matchId != null) updateData['match_id'] = matchId;
        await doc.reference.update(updateData);
      }
    } catch (e) {
      debugPrint('Error syncing challenge status to chat messages: $e');
    }
  }

  /// Stream percakapan pesan realtime antara dua user
  static Stream<List<ChatMessageModel>> streamMessages(String targetUserId, {String? customSenderId}) {
    final senderId = customSenderId ?? currentUserId;
    if (senderId == null || senderId.isEmpty) return Stream.value(<ChatMessageModel>[]);

    final roomId = getChatRoomId(senderId, targetUserId);

    try {
      return _firestore
          .collection('chat_rooms')
          .doc(roomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => ChatMessageModel.fromFirestore(doc)).toList())
          .handleError((e) {
            debugPrint('Error streaming messages: $e');
            return <ChatMessageModel>[];
          });
    } catch (e) {
      debugPrint('Error initiating streamMessages: $e');
      return Stream.value(<ChatMessageModel>[]);
    }
  }

  /// Stream daftar percakapan aktif yang melibatkan user saat ini
  static Stream<List<Map<String, dynamic>>> streamUserChatRooms({String? customUserId}) {
    final uid = customUserId ?? currentUserId;
    if (uid == null || uid.isEmpty) {
      return Stream.value(<Map<String, dynamic>>[]);
    }

    try {
      return _firestore
          .collection('chat_rooms')
          .where('users', arrayContains: uid)
          .snapshots()
          .map((snapshot) {
            final list = snapshot.docs.map((doc) => doc.data()).toList();
            // Urutkan percakapan secara lokal berdasarkan updated_at terbaru
            list.sort((a, b) {
              final tA = a['updated_at'];
              final tB = b['updated_at'];
              final dateA = tA is Timestamp ? tA.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
              final dateB = tB is Timestamp ? tB.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
              return dateB.compareTo(dateA);
            });
            return list;
          })
          .handleError((e) {
            debugPrint('Error streaming user chat rooms: $e');
            return <Map<String, dynamic>>[];
          });
    } catch (e) {
      debugPrint('Error initiating streamUserChatRooms: $e');
      return Stream.value(<Map<String, dynamic>>[]);
    }
  }
}
