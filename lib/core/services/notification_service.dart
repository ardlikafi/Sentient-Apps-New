import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sentient/features/chat/direct_chat_screen.dart';
import 'package:sentient/features/chess/chess_game_screen.dart';
import 'package:sentient/features/chess/models/chess_challenge_model.dart';
import 'package:sentient/features/chess/services/chess_online_service.dart';
import 'package:sentient/features/chess/chess_lobby_screen.dart';
import 'package:sentient/features/chat/services/chat_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    debugPrint("Handling background FCM message: ${message.messageId}");
    // If Google Play Services already handled notification via notification block, do not duplicate
    if (message.notification != null) return;

    final data = message.data;
    final type = data['type']?.toString() ?? '';
    final title = data['title']?.toString() ??
        (type == 'chess_invite' || type == 'challenge'
            ? '⚔️ Incoming Chess Challenge!'
            : type == 'challenge_accepted'
                ? '🎮 Opponent Entered the Chess Game!'
                : '💬 New Message');
    final body = data['body']?.toString() ??
        (data['text']?.toString() ?? 'Open Sentient app to view.');
    final payload = data['payload']?.toString() ?? '';

    final localNotifications = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);
    await localNotifications.initialize(settings: initSettings);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'sentient_high_importance_channel',
      'Sentient Notifications',
      channelDescription: 'Notifications for incoming chats and chess challenges',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
      icon: '@mipmap/ic_launcher',
    );
    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: platformDetails,
      payload: payload,
    );
  } catch (e) {
    debugPrint("Error in firebaseMessagingBackgroundHandler: $e");
  }
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Stores payload if tapped during app cold start before main navigation is mounted
  static String? pendingNotificationPayload;

  /// Dispatches any notification payload that was clicked during app cold start (terminated)
  static void consumePendingPayload(BuildContext context) {
    if (pendingNotificationPayload != null && pendingNotificationPayload!.isNotEmpty) {
      final payload = pendingNotificationPayload!;
      pendingNotificationPayload = null;
      debugPrint('Consuming pending notification payload: ' + payload);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationPayload(payload);
      });
    }
  }
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// Global navigator key to navigate or display dialogs/overlays from anywhere
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Timer? _presenceTimer;
  static StreamSubscription? _challengeSub;
  static StreamSubscription? _roomsSub;
  static StreamSubscription? _acceptedSentSub;
  static final Set<String> _seenChallengeIds = {};
  static final Set<String> _seenAcceptedChallengeIds = {};
  static final Map<String, dynamic> _lastSeenRoomTimestamps = {};
  static bool _listenersInitialized = false;

  /// High importance notification channel for Android
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'sentient_high_importance_channel',
    'Sentient Notifications',
    description: 'Notifications for incoming chats and chess challenges',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static Future<void> initialize() async {
    try {
      // 1. Initialize local notifications plugin for real Android status-bar notifications
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings =
          InitializationSettings(android: androidSettings);

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _handleNotificationPayload(response.payload);
        },
      );

      // Create Android Notification Channel
      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(_channel);
        await androidPlugin.requestNotificationsPermission();
      }

      // 2. Request FCM permissions
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('User granted notification permission: ${settings.authorizationStatus}');

      // 3. Set background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 4. Sync FCM device token for currently logged-in user
      await syncUserFCMToken();

      // Listen for auth state changes so token is ALWAYS kept in sync when signing in
      _auth.authStateChanges().listen((user) {
        if (user != null) {
          debugPrint('Auth state changed -> User signed in: ' + user.uid + '. Syncing FCM token...');
          syncUserFCMToken();
          startPresenceSystem();
        }
      });

      // 5. Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _updateTokenInFirestore(newToken);
      });

      // 6. Listen for foreground FCM messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Foreground message: ${message.data}');
        final title = message.notification?.title ?? message.data['title'] ?? 'Sentient';
        final body = message.notification?.body ?? message.data['body'] ?? '';
        showSystemNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: title,
          body: body,
          payload: message.data['payload'],
        );
      });

      // 7. Handle notification click when app was in background (minimized)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM onMessageOpenedApp: ${message.data}');
        final payload = message.data['payload'];
        if (payload != null && payload.isNotEmpty) {
          _handleNotificationPayload(payload);
        }
      });

      // 8. Handle cold start when app was completely terminated / force-closed
      _messaging.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          debugPrint('FCM getInitialMessage (from terminated state): ${message.data}');
          final payload = message.data['payload'];
          if (payload != null && payload.isNotEmpty) {
            pendingNotificationPayload = payload;
            Future.delayed(const Duration(milliseconds: 3500), () {
              if (pendingNotificationPayload != null) {
                final p = pendingNotificationPayload;
                pendingNotificationPayload = null;
                _handleNotificationPayload(p);
              }
            });
          }
        }
      });

      // 9. Handle local notification tap when opened from terminated state
      _localNotifications.getNotificationAppLaunchDetails().then((details) {
        if (details != null && details.didNotificationLaunchApp) {
          final payload = details.notificationResponse?.payload;
          if (payload != null && payload.isNotEmpty) {
            pendingNotificationPayload = payload;
            Future.delayed(const Duration(milliseconds: 3500), () {
              if (pendingNotificationPayload != null) {
                final p = pendingNotificationPayload;
                pendingNotificationPayload = null;
                _handleNotificationPayload(p);
              }
            });
          }
        }
      });
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  /// Show a real device notification in the phone status bar and lockscreen
  static Future<void> showSystemNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'sentient_high_importance_channel',
        'Sentient Notifications',
        channelDescription: 'Notifications for incoming chats and chess challenges',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        color: Color(0xFF2563EB),
        icon: '@mipmap/ic_launcher',
      );

      const NotificationDetails platformDetails =
          NotificationDetails(android: androidDetails);

      await _localNotifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: platformDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  /// Handle notification tap action
  static void _handleNotificationPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    final ctx = navigatorKey.currentContext;
    if (ctx == null) {
      pendingNotificationPayload = payload;
      return;
    }

    if (payload.startsWith('chat:')) {
      final parts = payload.split(':');
      if (parts.length >= 3) {
        final targetUserId = parts[1];
        final targetUserName = parts[2];
        final targetUserAvatar = parts.length > 3 && parts[3].isNotEmpty ? parts[3] : null;
        Navigator.of(ctx).push(
          MaterialPageRoute(
            builder: (_) => DirectChatScreen(
              targetUserId: targetUserId,
              targetUserName: targetUserName,
              targetUserAvatar: targetUserAvatar,
            ),
          ),
        );
      }
    } else if (payload.startsWith('match:')) {
      final parts = payload.split(':');
      if (parts.length >= 3) {
        final matchId = parts[1];
        final opponentName = parts[2];
        final playerColor = parts.length > 3 && parts[3].isNotEmpty ? parts[3] : 'white';
        if (ChessGameScreen.isUserInMatch) {
          Navigator.of(ctx).pop();
        }
        Navigator.of(ctx).push(
          MaterialPageRoute(
            builder: (_) => ChessGameScreen(
              isAIGame: false,
              isOnlineGame: true,
              onlineMatchId: matchId,
              onlinePlayerColor: playerColor,
              onlineOpponentName: opponentName,
            ),
          ),
        );
      }
    } else if (payload.startsWith('challenge:')) {
      Navigator.of(ctx).push(
        MaterialPageRoute(
          builder: (_) => const ChessLobbyScreen(),
        ),
      );
    }
  }

  /// Sync device FCM token to Firestore
  static Future<void> syncUserFCMToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      String? token = await _messaging.getToken();
      if (token != null) {
        await _updateTokenInFirestore(token);
      }
    } catch (e) {
      debugPrint('Error syncing FCM token: $e');
    }
  }

  static Future<void> _updateTokenInFirestore(String token) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).set({
        'fcm_token': token,
        'is_online': true,
        'last_active': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('FCM Token synced to Firestore for user: ${user.uid}');
    } catch (e) {
      debugPrint('Error updating FCM token in Firestore: $e');
    }
  }

  // ==========================================
  // REAL-TIME PRESENCE SYSTEM (WHATSAPP-STYLE)
  // ==========================================

  /// Start periodic heartbeat presence (every 30 seconds)
  static void startPresenceSystem() {
    _presenceTimer?.cancel();
    setOnlineStatus(true);

    _presenceTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      final user = _auth.currentUser;
      if (user != null) {
        _firestore.collection('users').doc(user.uid).set({
          'is_online': true,
          'last_active': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)).catchError((e) {
          debugPrint('Presence heartbeat error: $e');
        });
      }
    });
  }

  /// Stop heartbeat presence
  static void stopPresenceSystem() {
    _presenceTimer?.cancel();
    _presenceTimer = null;
    setOnlineStatus(false);
  }

  /// Set user online / offline status in Firestore
  static Future<void> setOnlineStatus(bool isOnline) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).set({
        'is_online': isOnline,
        'last_active': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('Presence status updated: is_online = $isOnline for ${user.uid}');
    } catch (e) {
      debugPrint('Error updating online status: $e');
    }
  }

  /// Safely parse various date representations (Timestamp, DateTime, int, String)
  static DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) {
      return value > 10000000000
          ? DateTime.fromMillisecondsSinceEpoch(value)
          : DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Check if user is actively online (within 75 seconds and flag is true)
  static bool isUserOnline(Map<String, dynamic>? user) {
    if (user == null) return false;
    final isOnlineFlag = user['is_online'] == true;
    final lastActiveDate = parseDateTime(user['last_active']);

    if (lastActiveDate != null) {
      final diffSeconds = DateTime.now().difference(lastActiveDate).inSeconds;
      // Allow minor clock skew down to -15s, and timeout at 75s (heartbeat is 30s)
      return isOnlineFlag && diffSeconds >= -15 && diffSeconds <= 75;
    }
    return isOnlineFlag;
  }

  /// WhatsApp-style presence formatter
  /// Menampilkan:
  /// - 'Online'
  /// - 'Terakhir dilihat baru saja' (jika baru offline < 1 menit)
  /// - 'Terakhir dilihat hari ini pukul 14:35' (lengkap dengan jam dan menit)
  /// - 'Terakhir dilihat kemarin pukul 22:15'
  /// - 'Terakhir dilihat 24 Okt pukul 16:20'
  /// - 'Terakhir dilihat 24 Okt 2025 pukul 16:20'
  static String formatLastSeen(Map<String, dynamic>? user) {
    if (user == null) return 'Offline';
    if (isUserOnline(user)) return 'Online';

    final date = parseDateTime(user['last_active']);
    if (date == null) return 'Offline';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(date.year, date.month, date.day);
    final dayDiff = today.difference(targetDay).inDays;

    final hourStr = date.hour.toString().padLeft(2, '0');
    final minuteStr = date.minute.toString().padLeft(2, '0');
    final timeStr = '$hourStr:$minuteStr';

    // English short month names
    const monthNames = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final monthStr = (date.month >= 1 && date.month <= 12) ? monthNames[date.month] : '';

    if (dayDiff == 0) {
      // Today
      final diffSeconds = now.difference(date).inSeconds;
      if (diffSeconds >= -15 && diffSeconds < 60) {
        return 'Last seen just now';
      }
      return 'Last seen today at $timeStr';
    } else if (dayDiff == 1) {
      // Yesterday
      return 'Last seen yesterday at $timeStr';
    } else if (date.year == now.year) {
      // Same year
      return 'Last seen ${date.day} $monthStr at $timeStr';
    } else {
      // Different year
      return 'Last seen ${date.day} $monthStr ${date.year} at $timeStr';
    }
  }

  // ==========================================
  // GLOBAL REAL-TIME NOTIFICATIONS & CHALLENGE PROMPT
  // ==========================================

  /// Start global listeners for incoming challenges and messages across the entire app
  static void startGlobalListeners(String userId) {
    if (_listenersInitialized || userId.isEmpty) return;
    _listenersInitialized = true;

    // 1. Listen for incoming chess challenges in real-time
    _challengeSub?.cancel();
    _challengeSub = ChessOnlineService.streamIncomingChallenges(userId).listen((challenges) {
      for (final challenge in challenges) {
        if (!_seenChallengeIds.contains(challenge.id) && challenge.status == 'pending') {
          _seenChallengeIds.add(challenge.id);
          _triggerIncomingChallengeAlert(challenge);
        }
      }
    });

    // 2. Listen for incoming chat messages in real-time
    _roomsSub?.cancel();
    _roomsSub = ChatService.streamUserChatRooms(customUserId: userId).listen((rooms) {
      for (final room in rooms) {
        final roomId = room['room_id']?.toString() ?? '';
        final lastSenderId = room['last_sender_id']?.toString() ?? '';
        final updatedAt = room['updated_at'];

        // Only alert if message is sent by someone else
        if (lastSenderId.isNotEmpty && lastSenderId != userId) {
          final previousTimestamp = _lastSeenRoomTimestamps[roomId];
          final currentMillis = updatedAt is Timestamp ? updatedAt.millisecondsSinceEpoch : 0;

          if (previousTimestamp != null && currentMillis > previousTimestamp) {
            _triggerIncomingMessageAlert(room);
          }
          _lastSeenRoomTimestamps[roomId] = currentMillis;
        }
      }
    });

    // 3. Listen for sent challenges that get accepted by opponent
    _acceptedSentSub?.cancel();
    _acceptedSentSub = ChessOnlineService.streamAcceptedSentChallenges(userId).listen((challenges) async {
      for (final challenge in challenges) {
        if (!_seenAcceptedChallengeIds.contains(challenge.id) &&
            challenge.matchId != null &&
            challenge.matchId!.isNotEmpty) {
          final isOngoing = await ChessOnlineService.isMatchOngoing(challenge.matchId!);
          if (!isOngoing) {
            _seenAcceptedChallengeIds.add(challenge.id);
            continue;
          }
          _seenAcceptedChallengeIds.add(challenge.id);
          _triggerChallengeAcceptedAlert(challenge);
        }
      }
    });
  }

  /// Trigger rich sound, vibration, device notification, and in-app challenge prompt
  static void _triggerIncomingChallengeAlert(ChessChallengeModel challenge) {
    // Vibrate device
    HapticFeedback.vibrate();

    // Show system device notification
    showSystemNotification(
      id: challenge.id.hashCode,
      title: '⚔️ Incoming Chess Challenge!',
      body: '${challenge.senderName} challenged you to play chess online.',
      payload: 'challenge:${challenge.id}',
    );

    // Show high-priority in-app prompt if app is currently visible
    final context = navigatorKey.currentContext;
    if (context == null) return;

    // Jika user sedang berada di dalam game aktif (vs Bot atau Online), jangan tutupi papan catur dengan modal dialog!
    // Sebaliknya, tampilkan notifikasi floating SnackBar yang tidak mengganggu permainan.
    if (ChessGameScreen.isUserInMatch) {
      final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
      if (scaffoldMessenger != null) {
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.sports_esports_rounded, color: Colors.amberAccent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '⚔️ ${challenge.senderName} menantang Anda bermain catur online!',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1E2638),
            duration: const Duration(seconds: 10),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.amberAccent, width: 1.2),
            ),
            action: SnackBarAction(
              label: 'LIHAT',
              textColor: Colors.amberAccent,
              onPressed: () {
                _showChallengeInGameConfirmationDialog(challenge);
              },
            ),
          ),
        );
        return;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2638),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.amberAccent, width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amberAccent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sports_esports_rounded, color: Colors.amberAccent, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Chess Challenge!',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                children: [
                  TextSpan(
                    text: challenge.senderName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const TextSpan(text: ' wants to play an online chess match with you right now! ♟️'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.timer_outlined, color: Colors.cyanAccent, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Mode: 1v1 Real-time Online',
                    style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              ChessOnlineService.declineChallenge(challenge.id);
            },
            child: const Text('Decline ❌', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Accept & Play ♟️', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final matchId = await ChessOnlineService.acceptChallenge(challenge);
              if (matchId != null && navigatorKey.currentContext != null) {
                Navigator.of(navigatorKey.currentContext!).push(
                  MaterialPageRoute(
                    builder: (_) => ChessGameScreen(
                      isAIGame: false,
                      isOnlineGame: true,
                      onlineMatchId: matchId,
                      onlinePlayerColor: 'black',
                      onlineOpponentName: challenge.senderName,
                      onlineOpponentAvatar: challenge.senderAvatar,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// Dialog konfirmasi khusus jika user sedang bermain aktif dan ingin menerima tantangan baru
  static void _showChallengeInGameConfirmationDialog(ChessChallengeModel challenge) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2638),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.amberAccent, width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amberAccent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Permainan Berjalan',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'Anda sedang berada dalam permainan aktif. Menerima tantangan online dari ${challenge.senderName} ini akan mengakhiri/menyerah (resign) dari game saat ini. Lanjutkan?',
          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              ChessOnlineService.declineChallenge(challenge.id);
            },
            child: const Text('Tolak Tantangan', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              // Tutup game yang sedang aktif sebelum membuka game baru agar backstack bersih
              if (ChessGameScreen.isUserInMatch && navigatorKey.currentContext != null) {
                Navigator.of(navigatorKey.currentContext!).pop();
              }
              final matchId = await ChessOnlineService.acceptChallenge(challenge);
              if (matchId != null && navigatorKey.currentContext != null) {
                Navigator.of(navigatorKey.currentContext!).push(
                  MaterialPageRoute(
                    builder: (_) => ChessGameScreen(
                      isAIGame: false,
                      isOnlineGame: true,
                      onlineMatchId: matchId,
                      onlinePlayerColor: 'black',
                      onlineOpponentName: challenge.senderName,
                      onlineOpponentAvatar: challenge.senderAvatar,
                    ),
                  ),
                );
              }
            },
            child: const Text('Resign & Terima ♟️', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Trigger alert for incoming chat message
  static void _triggerIncomingMessageAlert(Map<String, dynamic> room) {
    final senderName = room['last_sender_name']?.toString() ?? 'Your Friend';
    final senderId = room['last_sender_id']?.toString() ?? '';
    final messageText = room['last_message']?.toString() ?? 'New message';

    // Device vibration
    HapticFeedback.lightImpact();

    // Show system device notification
    showSystemNotification(
      id: roomIdToHash(room['room_id']?.toString() ?? ''),
      title: '💬 $senderName',
      body: messageText,
      payload: 'chat:$senderId:$senderName:',
    );

    // Show in-app top notification pill
    final context = navigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: const Color(0xFF1E293B),
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Colors.blueAccent, width: 1.2),
        ),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_rounded, color: Colors.blueAccent, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    senderName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    messageText,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Reply',
          textColor: Colors.cyanAccent,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DirectChatScreen(
                  targetUserId: senderId,
                  targetUserName: senderName,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Trigger alert when opponent accepts our challenge and enters game
  static void _triggerChallengeAcceptedAlert(ChessChallengeModel challenge) {
    HapticFeedback.vibrate();

    showSystemNotification(
      id: 'accepted_${challenge.id}'.hashCode,
      title: '🎮 Opponent Entered Chess Game!',
      body: '${challenge.receiverName} accepted your challenge and joined the game. Tap to play!',
      payload: 'match:${challenge.matchId}:${challenge.receiverName}:white',
    );

    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2638),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF10B981), width: 1.8),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sports_esports_rounded, color: Color(0xFF10B981), size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Opponent Joined Game! ♟️',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
            children: [
              TextSpan(
                text: challenge.receiverName,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const TextSpan(
                text: ' has accepted your challenge and entered the match! It is your turn to move first as White.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Later', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Enter Match ♟️', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              // Jika user sedang berada di dalam game catur lain, pop rutenya terlebih dahulu
              if (ChessGameScreen.isUserInMatch) {
                Navigator.of(context).pop();
              }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChessGameScreen(
                    isAIGame: false,
                    isOnlineGame: true,
                    onlineMatchId: challenge.matchId!,
                    onlinePlayerColor: 'white',
                    onlineOpponentName: challenge.receiverName,
                    onlineOpponentAvatar: challenge.receiverAvatar,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static int roomIdToHash(String str) {
    return str.hashCode.abs() % 100000;
  }

  static void dispose() {
    _presenceTimer?.cancel();
    _challengeSub?.cancel();
    _roomsSub?.cancel();
    _acceptedSentSub?.cancel();
    _listenersInitialized = false;
  }
}
