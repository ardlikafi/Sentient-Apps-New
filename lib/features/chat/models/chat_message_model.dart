import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String receiverId;
  final String text;
  final String type; // 'text', 'chess_invite', 'emoji'
  final String? challengeId;
  final String? matchId;
  final String? challengeStatus; // 'pending', 'accepted', 'declined', 'completed', 'aborted'
  final DateTime timestamp;
  final bool isRead;

  ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.receiverId,
    required this.text,
    this.type = 'text',
    this.challengeId,
    this.matchId,
    this.challengeStatus,
    required this.timestamp,
    this.isRead = false,
  });

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime time = DateTime.now();
    if (data['timestamp'] is Timestamp) {
      time = (data['timestamp'] as Timestamp).toDate();
    }

    return ChatMessageModel(
      id: doc.id,
      senderId: data['sender_id'] ?? '',
      senderName: data['sender_name'] ?? 'User',
      senderAvatar: data['sender_avatar'],
      receiverId: data['receiver_id'] ?? '',
      text: data['text'] ?? '',
      type: data['type'] ?? 'text',
      challengeId: data['challenge_id']?.toString(),
      matchId: data['match_id']?.toString(),
      challengeStatus: data['challenge_status']?.toString(),
      timestamp: time,
      isRead: data['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'receiver_id': receiverId,
      'text': text,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
      'is_read': isRead,
    };
    if (challengeId != null) map['challenge_id'] = challengeId;
    if (matchId != null) map['match_id'] = matchId;
    if (challengeStatus != null) map['challenge_status'] = challengeStatus;
    return map;
  }
}
