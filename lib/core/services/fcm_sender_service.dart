import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:googleapis_auth/auth_io.dart';

/// Service untuk mengirim notifikasi push secara langsung via Google FCM HTTP v1.
/// Bekerja 100% pada Spark Plan (Free) tanpa memerlukan Cloud Functions atau kartu kredit.
class FcmSenderService {
  static const String _projectId = 'sentient-chess-app';
  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/firebase.messaging',
  ];

  /// Kredensial Service Account Firebase resmi
  static const Map<String, dynamic> _serviceAccount = {
    "type": "service_account",
    "project_id": "sentient-chess-app",
    "private_key_id": "74ae5b9a534bb18270b2fe054970bc18aae932d9",
    "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDc3O5OMSD603xS\n6oac3X5hgYrJPg3t6E//7vzzXmTkSbVsHZvaNvc3HAvAzBQBx09Wya/G9dCBvsPE\nEBBDDMtEFCENAvoUU9KzkmGmVT3BhwMsYIaalCdBn7t4Cj8vF1ZrpT+kXLvgpTjp\nlTwWgpKvRIMQ1knlFU/vwlmLrKzwKy74YXvU87+IqPTTBFtl5VfOD1y5c+185HDL\nD5btmiyyBGlIZN0G8c9MESpde3vAhMSLyYI7a5yuRAyk/DACpzb+zsHK7x4rI6/N\n1+lAdorHD00Donr9R1bSUsKHtAyGlqWgTRbJsag97FJPlm5nJpm4qBRh+Yw9wBS0\nRkpSBwKTAgMBAAECggEADs2N+Vaon7cZ/5KxeAUOaemdTDSpCVeHOR+i+4rJl1Vr\nX/YyEnOZqStrjD4BX0clBauZ6Otj0LZg95yeAmhynTr+Jhmbek5N8nQusE/JRlXO\nvCQyEV05rlfO4FJLftQBGlDmjZUbkIhyYpF6iAWzYCTm5fN+22hMxcSQbOCjbKtQ\nUwJsHKYTmf23Vcpuzj3gMz0EWQmN7Cud04Socn/tvaKyTM8LZ2n4e8uVHytaDzQA\nIcCDnlxHyq1RfqbKkxk8Ba146jQ/nBuh8kZEmccFbIKDBltFuVvyBQvzoZesCjAZ\n4tgUer84BmN+MCvhly23s7yckf1818aLl1uJSgeXdQKBgQD/kPEGJQ8ke+qEGFJR\nNdrHfi12ru9wZL3V5XXP18mbOp+AL4WnbJlqQHKwX3Z3MPelLIB/iDZOujl52ZPB\nvJmi09PslAoSQdWG2U0hhT1KjBtB6qWiWqWb5bfzOr4eC4vuXzI0mMueX8irKxDq\nftUA+dBdjOVhZI1EhjWblWsijQKBgQDdPOioVEsMosUulGsTrWS6Ymc2NCLPz7R9\nocMoyM2rVuf1oJax+jIrEbwWlD2nXbAwM2QW9cVsyVgMV3hUDbTPPbA6Q4DI3gOH\nHSbOX2x34xGtY6DnKzQrLJlfG1iBphMEPzZ9btcD6rKkKSaeRrdczlO/bEG5TSfG\n1NvBNUIBnwKBgQCZdbZVI0Gxfbs3sMcVPsptiiXQo4Dhs4yOeSfCM2g7Dvuh5GdU\nPpDszWBQ6jHfpoa+JzfN3MQHiCllMrJX3mE+9gXGhKp7hg6q16dKHpDMR89CSJ1H\nHTleoJVRt49byUEwVPd3v9xc8FU1+zlAJgLPgDKPSkCet9tgL1rXXuSjLQKBgQDD\nnaZtp9KQAp/slqiyxl7I+lceMy0QqCuD5fLkbeCEfhwtL+fuyDVxpYW0RTDaelld\n1SLLtlXw4Xprty+ayl+z2mymp6cIdF2UKy9zzCXhPzITKINNwwKmphGaaVhxkkFA\nQRBSCh4txWhdBFG0IvzgH0Mnf3YBfPoNsYn5JLkPKwKBgDdx03toRDLn2CqTH1uR\nwqg5iTzO2/lmDukan2uZ8iVpwzmZ62k9/hz0gLgLQVhtRmpH9o1j1nhQqKOTYBhs\nm6rnN+FLk3vfOIxRp7MAzCEUGgrO2rH5aL5UhUc9p6byzyy2frXht7pD5I5+wHG4\nBthgO97T9FfOyPf38XB3xxSN\n-----END PRIVATE KEY-----\n",
    "client_email": "firebase-adminsdk-fbsvc@sentient-chess-app.iam.gserviceaccount.com",
    "client_id": "114304432756121755943",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
  };

  static AutoRefreshingAuthClient? _authClient;

  /// Mendapatkan klien HTTP terotentikasi dengan caching token otomatis
  static Future<AutoRefreshingAuthClient?> _getAuthClient() async {
    try {
      if (_authClient != null) {
        // Klien googleapis_auth otomatis merefresh token sebelum expired
        return _authClient;
      }
      final credentials = ServiceAccountCredentials.fromJson(_serviceAccount);
      _authClient = await clientViaServiceAccount(credentials, _scopes);
      return _authClient;
    } catch (e) {
      debugPrint('Error getting Google FCM Auth Client: $e');
      return null;
    }
  }

  /// Ambil token FCM pengguna target dari Firestore
  static Future<String?> _getUserFcmToken(String userId) async {
    try {
      if (userId.isEmpty) return null;
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      final token = doc.data()?['fcm_token']?.toString();
      return (token != null && token.isNotEmpty) ? token : null;
    } catch (e) {
      debugPrint('Error fetching FCM token for user $userId: $e');
      return null;
    }
  }

  /// 1. Kirim push notifikasi saat ada Pesan Chat baru
  static Future<void> sendChatNotification({
    required String receiverId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    required String text,
    String type = 'text',
    String? challengeId,
  }) async {
    try {
      final token = await _getUserFcmToken(receiverId);
      if (token == null) {
        debugPrint('FCM: Recipient $receiverId has no active FCM token.');
        return;
      }

      final title = type == 'chess_invite' ? '⚔️ Incoming Chess Challenge!' : '💬 $senderName';
      final body = type == 'chess_invite'
          ? '$senderName challenged you to an online chess match!'
          : text;

      final payload = type == 'chess_invite'
          ? 'challenge:${challengeId ?? ""}'
          : 'chat:$senderId:$senderName:${senderAvatar ?? ""}';

      await _dispatchFCM(
        token: token,
        title: title,
        body: body,
        data: {
          'type': type,
          'sender_id': senderId,
          'sender_name': senderName,
          'payload': payload,
          'title': title,
          'body': body,
        },
      );
    } catch (e) {
      debugPrint('Error in sendChatNotification: $e');
    }
  }

  /// 2. Kirim push notifikasi saat ada Tantangan Catur baru dari Lobby
  static Future<void> sendChallengeNotification({
    required String receiverId,
    required String senderId,
    required String senderName,
    required String challengeId,
    int timeControl = 600,
  }) async {
    try {
      final token = await _getUserFcmToken(receiverId);
      if (token == null) {
        debugPrint('FCM: Challenge recipient $receiverId has no active FCM token.');
        return;
      }

      final timeMinutes = (timeControl / 60).round();
      final timeText = timeMinutes > 0 ? ' ($timeMinutes Min)' : '';
      const title = '⚔️ Incoming Chess Challenge!';
      final body = '$senderName invited you to play chess online$timeText. Tap to accept!';
      final payload = 'challenge:$challengeId';

      await _dispatchFCM(
        token: token,
        title: title,
        body: body,
        data: {
          'type': 'challenge',
          'challenge_id': challengeId,
          'sender_id': senderId,
          'sender_name': senderName,
          'payload': payload,
          'title': title,
          'body': body,
        },
      );
    } catch (e) {
      debugPrint('Error in sendChallengeNotification: $e');
    }
  }

  /// 3. Kirim push notifikasi ke Penantang saat tantangan diterima oleh lawan
  static Future<void> sendChallengeAcceptedNotification({
    required String senderId,
    required String receiverName,
    required String matchId,
  }) async {
    try {
      final token = await _getUserFcmToken(senderId);
      if (token == null) {
        debugPrint('FCM: Challenge sender $senderId has no active FCM token.');
        return;
      }

      const title = '🎮 Opponent Entered Chess Game!';
      final body = '$receiverName accepted your chess challenge. Join the match now!';
      // Format payload yang diharapkan: match:<matchId>:<opponentName>:<playerColor>
      final payload = 'match:$matchId:$receiverName:white';

      await _dispatchFCM(
        token: token,
        title: title,
        body: body,
        data: {
          'type': 'challenge_accepted',
          'match_id': matchId,
          'opponent_name': receiverName,
          'payload': payload,
          'title': title,
          'body': body,
        },
      );
    } catch (e) {
      debugPrint('Error in sendChallengeAcceptedNotification: $e');
    }
  }

  /// Eksekusi pengiriman HTTP v1 ke Google Cloud Messaging Endpoint
  static Future<void> _dispatchFCM({
    required String token,
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    final client = await _getAuthClient();
    if (client == null) {
      debugPrint('FCM Dispatch aborted: Google Auth Client is null.');
      return;
    }

    final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$_projectId/messages:send');

    final messagePayload = {
      'message': {
        'token': token,
        'notification': {
          'title': title,
          'body': body,
        },
        'data': data,
        'android': {
          'priority': 'HIGH',
          'notification': {
            'channel_id': 'sentient_high_importance_channel',
            'sound': 'default',
            'default_sound': true,
            'default_vibrate_timings': true,
            'priority': 'PRIORITY_MAX',
            'visibility': 'PUBLIC',
          },
        },
        'apns': {
          'headers': {
            'apns-priority': '10',
          },
          'payload': {
            'aps': {
              'sound': 'default',
              'badge': 1,
              'content-available': 1,
              'alert': {
                'title': title,
                'body': body,
              },
            },
          },
        },
      },
    };

    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(messagePayload),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      debugPrint('✅ FCM Push Notification sent successfully to token: ${token.substring(0, 15)}...');
    } else {
      debugPrint('⚠️ FCM Push Notification response error: ${response.statusCode} -> ${response.body}');
    }
  }
}

