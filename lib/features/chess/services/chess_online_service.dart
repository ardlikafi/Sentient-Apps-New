import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:sentient/features/chess/models/chess_challenge_model.dart';
import 'package:sentient/core/services/fcm_sender_service.dart';
import 'package:sentient/features/chat/services/chat_service.dart';

class ChessOnlineService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get currentUserId => _auth.currentUser?.uid;

  /// Meratakan papan 2D (8x8) menjadi 1D List (64 elemen) karena Firestore tidak mendukung nested arrays
  static List<String> flattenBoard(List<List<String>> board) {
    final flat = <String>[];
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (r < board.length && c < board[r].length) {
          flat.add(board[r][c]);
        } else {
          flat.add('');
        }
      }
    }
    return flat;
  }

  /// Mengembalikan papan 2D (8x8) dari data Firestore (baik format 1D 64-item atau format lama 2D jika ada)
  static List<List<String>> unflattenBoard(dynamic raw) {
    if (raw is List) {
      if (raw.length == 64) {
        return List.generate(
          8,
          (r) => List.generate(8, (c) => raw[r * 8 + c]?.toString() ?? ''),
        );
      }
      if (raw.length == 8 && raw.first is List) {
        return raw
            .map((r) => (r as List).map((c) => c?.toString() ?? '').toList())
            .toList();
      }
    }
    return [
      ['♜', '♞', '♝', '♛', '♚', '♝', '♞', '♜'],
      ['♟', '♟', '♟', '♟', '♟', '♟', '♟', '♟'],
      ['', '', '', '', '', '', '', ''],
      ['', '', '', '', '', '', '', ''],
      ['', '', '', '', '', '', '', ''],
      ['', '', '', '', '', '', '', ''],
      ['♙', '♙', '♙', '♙', '♙', '♙', '♙', '♙'],
      ['♖', '♘', '♗', '♕', '♔', '♗', '♘', '♖'],
    ];
  }

  /// Stream daftar user terdaftar di Sentient (selain user saat ini)
  static Stream<List<Map<String, dynamic>>> streamRegisteredUsers() async* {
    final currentId = currentUserId;
    try {
      await for (final snapshot in _firestore.collection('users').snapshots()) {
        final list = <Map<String, dynamic>>[];
        for (var doc in snapshot.docs) {
          if (doc.id == currentId) continue;
          final data = doc.data();
          data['id'] = doc.id;
          list.add(data);
        }
        yield list;
      }
    } catch (e) {
      debugPrint('Firestore users stream error: $e');
      yield <Map<String, dynamic>>[];
    }
  }

  /// Kirim tantangan catur ke pemain lain
  static Future<String?> sendChallenge({
    required String targetUserId,
    required String targetUserName,
    String? targetUserAvatar,
    required String currentUserName,
    String? currentUserAvatar,
    int timeControl = 600,
  }) async {
    final senderId = currentUserId;
    if (senderId == null) return null;

    try {
      final docRef = _firestore.collection('chess_challenges').doc();
      final challenge = ChessChallengeModel(
        id: docRef.id,
        senderId: senderId,
        senderName: currentUserName,
        senderAvatar: currentUserAvatar,
        receiverId: targetUserId,
        receiverName: targetUserName,
        receiverAvatar: targetUserAvatar,
        status: 'pending',
        timeControl: timeControl,
        createdAt: DateTime.now(),
      );

      await docRef.set(challenge.toMap());
      debugPrint('Chess challenge sent successfully: ${docRef.id}');

      // Kirim push notifikasi langsung via Google FCM HTTP v1 ke HP penerima
      unawaited(FcmSenderService.sendChallengeNotification(
        receiverId: targetUserId,
        senderId: senderId,
        senderName: currentUserName,
        challengeId: docRef.id,
        timeControl: timeControl,
      ));
      return docRef.id;
    } catch (e) {
      debugPrint('Error sending challenge: $e');
      return null;
    }
  }

  /// Batalkan tantangan yang dikirim
  static Future<void> cancelChallenge(String challengeId) async {
    try {
      await _firestore.collection('chess_challenges').doc(challengeId).update({
        'status': 'cancelled',
      });
    } catch (e) {
      debugPrint('Error cancelling challenge: $e');
    }
  }

  /// Terima tantangan dan buat ruangan pertandingan real-time
  static Future<String?> acceptChallenge(ChessChallengeModel challenge) async {
    try {
      final matchRef = _firestore.collection('chess_matches').doc();
      final matchDuration = challenge.timeControl > 0 ? challenge.timeControl : 600;

      // Inisialisasi papan catur standar
      final initialBoard = [
        ['♜', '♞', '♝', '♛', '♚', '♝', '♞', '♜'],
        ['♟', '♟', '♟', '♟', '♟', '♟', '♟', '♟'],
        ['', '', '', '', '', '', '', ''],
        ['', '', '', '', '', '', '', ''],
        ['', '', '', '', '', '', '', ''],
        ['', '', '', '', '', '', '', ''],
        ['♙', '♙', '♙', '♙', '♙', '♙', '♙', '♙'],
        ['♖', '♘', '♗', '♕', '♔', '♗', '♘', '♖'],
      ];

      await matchRef.set({
        'match_id': matchRef.id,
        'challenge_id': challenge.id,
        'white_player_id': challenge.senderId,
        'white_player_name': challenge.senderName,
        'white_player_avatar': challenge.senderAvatar,
        'black_player_id': challenge.receiverId,
        'black_player_name': challenge.receiverName,
        'black_player_avatar': challenge.receiverAvatar,
        'current_turn': 'white',
        'board_state': flattenBoard(initialBoard),
        'white_captured': [],
        'black_captured': [],
        'move_history': [],
        'last_move': null,
        'status': 'ongoing',
        'winner': null,
        'white_time': matchDuration,
        'black_time': matchDuration,
        'time_control': matchDuration,
        'latest_reaction': null,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Update/set status challenge jadi accepted dengan SetOptions(merge: true)
      await _firestore.collection('chess_challenges').doc(challenge.id).set({
        'id': challenge.id,
        'sender_id': challenge.senderId,
        'sender_name': challenge.senderName,
        'sender_avatar': challenge.senderAvatar,
        'receiver_id': challenge.receiverId,
        'receiver_name': challenge.receiverName,
        'receiver_avatar': challenge.receiverAvatar,
        'status': 'accepted',
        'match_id': matchRef.id,
        'time_control': matchDuration,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Sinkronkan status tantangan ke chat message terkait
      unawaited(ChatService.syncChallengeStatus(
        challengeId: challenge.id,
        status: 'accepted',
        matchId: matchRef.id,
        user1Id: challenge.senderId,
        user2Id: challenge.receiverId,
      ));

      // Kirim push notifikasi langsung ke pengirim tantangan bahwa tantangan diterima
      unawaited(FcmSenderService.sendChallengeAcceptedNotification(
        senderId: challenge.senderId,
        receiverName: challenge.receiverName,
        matchId: matchRef.id,
      ));

      return matchRef.id;
    } catch (e) {
      debugPrint('Error accepting challenge: $e');
      return null;
    }
  }

  /// Tolak tantangan catur
  static Future<void> declineChallenge(String challengeId) async {
    try {
      await _firestore.collection('chess_challenges').doc(challengeId).update({
        'status': 'declined',
      });
      // Sinkronkan status penolakan ke chat message terkait
      unawaited(ChatService.syncChallengeStatus(
        challengeId: challengeId,
        status: 'declined',
      ));
    } catch (e) {
      debugPrint('Error declining challenge: $e');
    }
  }

  /// Stream tantangan masuk untuk user saat ini
  static Stream<List<ChessChallengeModel>> streamIncomingChallenges(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    try {
      return _firestore
          .collection('chess_challenges')
          .where('receiver_id', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => ChessChallengeModel.fromFirestore(doc)).toList())
          .handleError((e) {
            debugPrint('Error streaming incoming challenges: $e');
            return <ChessChallengeModel>[];
          });
    } catch (e) {
      debugPrint('Error in streamIncomingChallenges: $e');
      return Stream.value([]);
    }
  }

  /// Ambil daftar tantangan masuk pending sekali panggil
  static Future<List<ChessChallengeModel>> getIncomingChallengesOnce(String userId) async {
    if (userId.isEmpty) return [];
    try {
      final snap = await _firestore
          .collection('chess_challenges')
          .where('receiver_id', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();
      return snap.docs.map((doc) => ChessChallengeModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting incoming challenges once: $e');
      return [];
    }
  }

  /// Stream tantangan keluar untuk user saat ini
  static Stream<List<ChessChallengeModel>> streamOutgoingChallenges(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    try {
      return _firestore
          .collection('chess_challenges')
          .where('sender_id', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => ChessChallengeModel.fromFirestore(doc)).toList())
          .handleError((e) {
            debugPrint('Error streaming outgoing challenges: $e');
            return <ChessChallengeModel>[];
          });
    } catch (e) {
      debugPrint('Error in streamOutgoingChallenges: $e');
      return Stream.value([]);
    }
  }

  /// Stream tantangan terkirim yang baru saja diterima oleh lawan
  static Stream<List<ChessChallengeModel>> streamAcceptedSentChallenges(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    try {
      return _firestore
          .collection('chess_challenges')
          .where('sender_id', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => ChessChallengeModel.fromFirestore(doc)).toList())
          .handleError((e) {
            debugPrint('Error streaming accepted sent challenges: $e');
            return <ChessChallengeModel>[];
          });
    } catch (e) {
      debugPrint('Error in streamAcceptedSentChallenges: $e');
      return Stream.value([]);
    }
  }

  /// Stream detail satu tantangan (untuk memantau apakah penantang diterima)
  static Stream<DocumentSnapshot> streamChallenge(String challengeId) {
    return _firestore.collection('chess_challenges').doc(challengeId).snapshots();
  }

  /// Stream ruangan pertandingan catur online
  static Stream<DocumentSnapshot> streamMatch(String matchId) {
    return _firestore.collection('chess_matches').doc(matchId).snapshots();
  }

  /// Cek apakah pertandingan online masih aktif dan berstatus ongoing
  static Future<bool> isMatchOngoing(String matchId) async {
    if (matchId.isEmpty) return false;
    try {
      final doc = await _firestore.collection('chess_matches').doc(matchId).get();
      if (!doc.exists) return false;
      final status = doc.data()?['status']?.toString();
      return status == 'ongoing';
    } catch (e) {
      debugPrint('Error checking isMatchOngoing: $e');
      return false;
    }
  }

  /// Tandai tantangan catur sudah dimulai agar tidak ter-trigger ulang di stream accepted
  static Future<void> markChallengeStarted(String challengeId) async {
    if (challengeId.isEmpty) return;
    try {
      await _firestore.collection('chess_challenges').doc(challengeId).update({
        'status': 'started',
        'started_at': FieldValue.serverTimestamp(),
      });
      debugPrint('Challenge marked as started: $challengeId');
    } catch (e) {
      debugPrint('Error marking challenge started: $e');
    }
  }

  /// Selesaikan tantangan catur secara permanen
  static Future<void> completeChallenge(String challengeId) async {
    if (challengeId.isEmpty) return;
    try {
      await _firestore.collection('chess_challenges').doc(challengeId).update({
        'status': 'completed',
        'completed_at': FieldValue.serverTimestamp(),
      });
      unawaited(ChatService.syncChallengeStatus(
        challengeId: challengeId,
        status: 'completed',
      ));
      debugPrint('Challenge completed: $challengeId');
    } catch (e) {
      debugPrint('Error completing challenge: $e');
    }
  }

  /// Finalisasi match dan tantangan terkait saat match selesai atau pemain keluar
  static Future<void> finalizeMatchAndChallenge(String matchId) async {
    if (matchId.isEmpty) return;
    try {
      final doc = await _firestore.collection('chess_matches').doc(matchId).get();
      if (doc.exists) {
        final data = doc.data();
        final challengeId = data?['challenge_id']?.toString();
        final matchStatus = data?['status']?.toString();
        final finalStatus = (matchStatus == 'aborted') ? 'aborted' : 'completed';
        if (challengeId != null && challengeId.isNotEmpty) {
          await completeChallenge(challengeId);
          unawaited(ChatService.syncChallengeStatus(
            challengeId: challengeId,
            status: finalStatus,
            matchId: matchId,
            user1Id: data?['white_player_id']?.toString(),
            user2Id: data?['black_player_id']?.toString(),
          ));
        }
      }
    } catch (e) {
      debugPrint('Error finalizing match and challenge: $e');
    }
  }

  /// Bersihkan tantangan accepted lama yang pertandingannya sudah selesai
  static Future<void> cleanUpStaleAcceptedChallenges(String userId) async {
    if (userId.isEmpty) return;
    try {
      // 1. Bersihkan tantangan terkirim (sender) yang statusnya masih 'accepted'
      final sentSnap = await _firestore
          .collection('chess_challenges')
          .where('sender_id', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .get();

      for (var doc in sentSnap.docs) {
        final matchId = doc.data()['match_id']?.toString();
        if (matchId == null || matchId.isEmpty) {
          await doc.reference.update({'status': 'completed'});
        } else {
          final isOngoing = await isMatchOngoing(matchId);
          if (!isOngoing) {
            await doc.reference.update({'status': 'completed'});
          }
        }
      }

      // 2. Bersihkan tantangan diterima (receiver) yang statusnya masih 'accepted'
      final receivedSnap = await _firestore
          .collection('chess_challenges')
          .where('receiver_id', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .get();

      for (var doc in receivedSnap.docs) {
        final matchId = doc.data()['match_id']?.toString();
        if (matchId == null || matchId.isEmpty) {
          await doc.reference.update({'status': 'completed'});
        } else {
          final isOngoing = await isMatchOngoing(matchId);
          if (!isOngoing) {
            await doc.reference.update({'status': 'completed'});
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up stale accepted challenges: $e');
    }
  }

  /// Stream daftar pertandingan aktif yang sedang berlangsung untuk user saat ini
  static Stream<List<Map<String, dynamic>>> streamActiveMatches(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    try {
      return _firestore
          .collection('chess_matches')
          .where('status', isEqualTo: 'ongoing')
          .snapshots()
          .map((snapshot) {
            final list = <Map<String, dynamic>>[];
            for (var doc in snapshot.docs) {
              final data = doc.data();
              if (data['white_player_id'] == userId || data['black_player_id'] == userId) {
                data['id'] = doc.id;
                list.add(data);
              }
            }
            return list;
          })
          .handleError((e) {
            debugPrint('Error streaming active matches: $e');
            return <Map<String, dynamic>>[];
          });
    } catch (e) {
      debugPrint('Error initiating streamActiveMatches: $e');
      return Stream.value([]);
    }
  }

  /// Kirim langkah catur online ke Firestore
  static Future<void> sendOnlineMove({
    required String matchId,
    required List<List<String>> board,
    required String nextTurn,
    required List<String> whiteCaptured,
    required List<String> blackCaptured,
    required List<String> moveHistory,
    required Map<String, dynamic> lastMove,
    String? winner,
    String status = 'ongoing',
    int? whiteTimeRemaining,
    int? blackTimeRemaining,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'board_state': flattenBoard(board),
        'current_turn': nextTurn,
        'white_captured': whiteCaptured,
        'black_captured': blackCaptured,
        'move_history': moveHistory,
        'last_move': lastMove,
        'status': status,
        'winner': winner,
        'updated_at': FieldValue.serverTimestamp(),
      };
      if (whiteTimeRemaining != null) updateData['white_time'] = whiteTimeRemaining;
      if (blackTimeRemaining != null) updateData['black_time'] = blackTimeRemaining;

      await _firestore.collection('chess_matches').doc(matchId).update(updateData);
      if (status != 'ongoing') {
        await finalizeMatchAndChallenge(matchId);
      }
    } catch (e) {
      debugPrint('Error sending online move: $e');
    }
  }

  /// Laporkan bahwa salah satu pemain kehabisan waktu (Timeout)
  static Future<void> timeoutMatch({
    required String matchId,
    required String winner,
  }) async {
    try {
      await _firestore.collection('chess_matches').doc(matchId).update({
        'status': 'timeout',
        'winner': winner,
        'updated_at': FieldValue.serverTimestamp(),
      });
      await finalizeMatchAndChallenge(matchId);
    } catch (e) {
      debugPrint('Error reporting match timeout: $e');
    }
  }

  /// Kirim reaksi emotikon dan pesan singkat in-game
  static Future<void> sendInGameReaction({
    required String matchId,
    required String senderId,
    required String senderColor,
    String? emoji,
    String? message,
  }) async {
    try {
      await _firestore.collection('chess_matches').doc(matchId).update({
        'latest_reaction': {
          'sender_id': senderId,
          'sender_color': senderColor,
          'emoji': emoji,
          'message': message,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      });
    } catch (e) {
      debugPrint('Error sending in-game reaction: $e');
    }
  }

  /// Set status koneksi pemain dalam pertandingan online (untuk mendeteksi disconnect / reconnect)
  static Future<void> setPlayerConnectionStatus({
    required String matchId,
    required String playerColor,
    required bool isConnected,
  }) async {
    try {
      if (isConnected) {
        await _firestore.collection('chess_matches').doc(matchId).update({
          '${playerColor}_connected': true,
          'disconnected_player': null,
          'disconnect_time': null,
        });
      } else {
        await _firestore.collection('chess_matches').doc(matchId).update({
          '${playerColor}_connected': false,
          'disconnected_player': playerColor,
          'disconnect_time': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error updating player connection status: $e');
    }
  }

  /// Batalkan pertandingan catur online sebelum langkah dimulai (Abort)
  static Future<void> abortOnlineMatch({required String matchId}) async {
    try {
      await _firestore.collection('chess_matches').doc(matchId).update({
        'status': 'aborted',
        'updated_at': FieldValue.serverTimestamp(),
      });
      await finalizeMatchAndChallenge(matchId);
      debugPrint('Online match aborted: $matchId');
    } catch (e) {
      debugPrint('Error aborting online match: $e');
    }
  }

  /// Menyerah dalam pertandingan catur online
  static Future<void> resignOnlineMatch({
    required String matchId,
    required String winnerColor,
  }) async {
    try {
      await _firestore.collection('chess_matches').doc(matchId).update({
        'status': 'resigned',
        'winner': winnerColor,
        'updated_at': FieldValue.serverTimestamp(),
      });
      await finalizeMatchAndChallenge(matchId);
    } catch (e) {
      debugPrint('Error resigning online match: $e');
    }
  }

  /// Klaim kemenangan karena lawan disconnect / abandon pertandingan
  static Future<void> claimAbandonmentVictory({
    required String matchId,
    required String winnerColor,
  }) async {
    try {
      await _firestore.collection('chess_matches').doc(matchId).update({
        'status': 'abandoned',
        'winner': winnerColor,
        'updated_at': FieldValue.serverTimestamp(),
      });
      await finalizeMatchAndChallenge(matchId);
    } catch (e) {
      debugPrint('Error claiming abandonment victory: $e');
    }
  }

  /// Menawarkan kesepakatan remis (seri) dalam pertandingan online
  static Future<void> offerOnlineDraw({
    required String matchId,
    required String playerColor,
  }) async {
    try {
      await _firestore.collection('chess_matches').doc(matchId).update({
        'draw_offer_by': playerColor,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error offering online draw: $e');
    }
  }

  /// Menerima tawaran remis (seri) dari lawan
  static Future<void> acceptOnlineDraw({
    required String matchId,
  }) async {
    try {
      await _firestore.collection('chess_matches').doc(matchId).update({
        'status': 'draw',
        'winner': null,
        'draw_offer_by': null,
        'updated_at': FieldValue.serverTimestamp(),
      });
      await finalizeMatchAndChallenge(matchId);
    } catch (e) {
      debugPrint('Error accepting online draw: $e');
    }
  }

  /// Menolak tawaran remis dari lawan
  static Future<void> declineOnlineDraw({
    required String matchId,
  }) async {
    try {
      await _firestore.collection('chess_matches').doc(matchId).update({
        'draw_offer_by': null,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error declining online draw: $e');
    }
  }

  /// Stream Papan Peringkat Komunitas Sentient (Leaderboard)
  /// Khusus menghitung pertandingan Online Multiplayer antar pemain (Bot & Lokal diabaikan)
  static Stream<List<Map<String, dynamic>>> streamLeaderboard({int limit = 10}) {
    return _firestore.collection('users').snapshots().map((snapshot) {
      final list = <Map<String, dynamic>>[];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        list.add(data);
      }

      // Sort: Standar Poin Catur Internasional (Menang = 1.0 poin, Draw = 0.5 poin), lalu Wins, lalu Win Rate
      list.sort((a, b) {
        final winsA = (a['chess_online_wins'] as num?)?.toInt() ?? 0;
        final winsB = (b['chess_online_wins'] as num?)?.toInt() ?? 0;
        final drawsA = (a['chess_online_draws'] as num?)?.toInt() ?? 0;
        final drawsB = (b['chess_online_draws'] as num?)?.toInt() ?? 0;
        final pointsA = winsA + (0.5 * drawsA);
        final pointsB = winsB + (0.5 * drawsB);
        if (pointsB != pointsA) return pointsB.compareTo(pointsA);
        if (winsB != winsA) return winsB.compareTo(winsA);

        final rateA = (a['chess_online_win_rate'] as num?)?.toDouble() ?? 0.0;
        final rateB = (b['chess_online_win_rate'] as num?)?.toDouble() ?? 0.0;
        if (rateB != rateA) return rateB.compareTo(rateA);

        final gamesA = (a['chess_online_games'] as num?)?.toInt() ?? 0;
        final gamesB = (b['chess_online_games'] as num?)?.toInt() ?? 0;
        if (gamesB != gamesA) return gamesB.compareTo(gamesA);

        final nameA = (a['username'] ?? '').toString().toLowerCase();
        final nameB = (b['username'] ?? '').toString().toLowerCase();
        return nameA.compareTo(nameB);
      });

      return list.take(limit).toList();
    }).handleError((e) {
      debugPrint('Error in streamLeaderboard: $e');
      return <Map<String, dynamic>>[];
    });
  }
}
