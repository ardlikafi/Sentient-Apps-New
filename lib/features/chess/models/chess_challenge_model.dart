import 'package:cloud_firestore/cloud_firestore.dart';

class ChessChallengeModel {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String receiverId;
  final String receiverName;
  final String? receiverAvatar;
  final String status; // 'pending', 'accepted', 'declined', 'cancelled'
  final String? matchId;
  final int timeControl; // Durasi waktu dalam detik (default 600 = 10 Menit)
  final DateTime createdAt;

  ChessChallengeModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.receiverId,
    required this.receiverName,
    this.receiverAvatar,
    required this.status,
    this.matchId,
    this.timeControl = 600,
    required this.createdAt,
  });

  factory ChessChallengeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime created = DateTime.now();
    if (data['created_at'] is Timestamp) {
      created = (data['created_at'] as Timestamp).toDate();
    }

    return ChessChallengeModel(
      id: doc.id,
      senderId: data['sender_id'] ?? '',
      senderName: data['sender_name'] ?? 'Player',
      senderAvatar: data['sender_avatar'],
      receiverId: data['receiver_id'] ?? '',
      receiverName: data['receiver_name'] ?? 'Opponent',
      receiverAvatar: data['receiver_avatar'],
      status: data['status'] ?? 'pending',
      matchId: data['match_id'],
      timeControl: (data['time_control'] as num?)?.toInt() ?? 600,
      createdAt: created,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'receiver_id': receiverId,
      'receiver_name': receiverName,
      'receiver_avatar': receiverAvatar,
      'status': status,
      'match_id': matchId,
      'time_control': timeControl,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}
