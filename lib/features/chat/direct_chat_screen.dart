import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sentient/core/providers/user_provider.dart';
import 'package:sentient/core/services/notification_service.dart';
import 'package:sentient/core/utils/image_helper.dart';
import 'package:sentient/features/chat/models/chat_message_model.dart';
import 'package:sentient/features/chat/services/chat_service.dart';
import 'package:sentient/features/chess/chess_game_screen.dart';
import 'package:sentient/features/chess/models/chess_challenge_model.dart';
import 'package:sentient/features/chess/models/chess_time_control.dart';
import 'package:sentient/features/chess/widgets/chess_time_control_dialog.dart';
import 'package:sentient/features/chess/services/chess_online_service.dart';

class DirectChatScreen extends StatefulWidget {
  final String targetUserId;
  final String targetUserName;
  final String? targetUserAvatar;

  const DirectChatScreen({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
    this.targetUserAvatar,
  });

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription? _outgoingChallengeSub;
  StreamSubscription? _acceptedChallengeSub;
  Timer? _presenceRefreshTimer;
  String? _joinedMatchId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initChallengeWatcher();
    });
    // Auto-refresh presence every 15 seconds so relative/exact time stays accurate in real-time
    _presenceRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _presenceRefreshTimer?.cancel();
    _outgoingChallengeSub?.cancel();
    _acceptedChallengeSub?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initChallengeWatcher() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUserId = userProvider.userData?['id']?.toString() ??
        ChessOnlineService.currentUserId ?? '';
    if (currentUserId.isEmpty) return;

    _acceptedChallengeSub?.cancel();
    // Dengarkan bila tantangan yang dikirim ke lawan ini diterima
    _acceptedChallengeSub = FirebaseFirestore.instance
        .collection('chess_challenges')
        .where('sender_id', isEqualTo: currentUserId)
        .where('receiver_id', isEqualTo: widget.targetUserId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .listen((snapshot) {
          if (!mounted) return;
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final matchId = data['match_id']?.toString();
            if (matchId != null && matchId.isNotEmpty && matchId != _joinedMatchId) {
              _joinedMatchId = matchId;
              _enterMatch(matchId, 'white');
              break;
            }
          }
        });
  }

  void _enterMatch(String matchId, String playerColor) async {
    if (!mounted) return;
    _joinedMatchId = matchId;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Entering online match with ${widget.targetUserName}...'),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
      ),
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChessGameScreen(
          isAIGame: false,
          isOnlineGame: true,
          onlineMatchId: matchId,
          onlinePlayerColor: playerColor,
          onlineOpponentName: widget.targetUserName,
          onlineOpponentAvatar: widget.targetUserAvatar,
        ),
      ),
    );

    // Saat keluar dari game, periksa apakah pertandingan sudah selesai/aborted
    try {
      final doc = await FirebaseFirestore.instance.collection('chess_matches').doc(matchId).get();
      if (doc.exists) {
        final matchStatus = doc.data()?['status']?.toString();
        final challengeId = doc.data()?['challenge_id']?.toString() ?? matchId;
        if (matchStatus != null && matchStatus != 'ongoing') {
          final newChatStatus = (matchStatus == 'aborted') ? 'aborted' : 'completed';
          await ChatService.updateChallengeStatusByChallengeId(
            targetUserId: widget.targetUserId,
            challengeId: challengeId,
            status: newChatStatus,
            matchId: matchId,
          );
          await ChatService.syncChallengeStatus(
            challengeId: challengeId,
            status: newChatStatus,
            matchId: matchId,
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating post-match status in chat: $e');
    }
  }

  void _sendMessage({
    String type = 'text',
    String? customText,
    String? challengeId,
    String? matchId,
  }) async {
    final text = customText ?? _messageController.text.trim();
    if (text.isEmpty && type == 'text') return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.userData;
    final currentName = currentUser?['username']?.toString() ?? 'Player';
    final currentAvatar = currentUser?['avatar']?.toString();

    _messageController.clear();

    await ChatService.sendMessage(
      targetUserId: widget.targetUserId,
      text: text,
      type: type,
      challengeId: challengeId,
      matchId: matchId,
      currentUserName: currentName,
      currentUserAvatar: currentAvatar,
    );
  }

  void _sendChessChallengeInvite() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.userData;
    final currentName = currentUser?['username']?.toString() ?? 'Player';
    final currentAvatar = currentUser?['avatar']?.toString();

    final isBot = widget.targetUserId.startsWith('bot_');
    if (isBot) {
      final chosenSeconds = await ChessTimeControlDialog.show(
        context,
        title: 'VS Bot (${widget.targetUserName})',
        subtitle: 'Select chess time control format',
        allowUnlimited: true,
        defaultSeconds: 0,
        actionButtonText: 'Start Game 🚀',
      );
      if (chosenSeconds == null || !mounted) return;

      _sendMessage(
        type: 'chess_invite',
        customText: 'Let\'s play Chess together! ♟️ (${ChessTimeControl.formatSummary(chosenSeconds)})',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚡ ${widget.targetUserName} accepted the challenge! Starting match...'),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
          ),
        );
        Future.delayed(const Duration(milliseconds: 700), () {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChessGameScreen(
                isAIGame: true,
                aiDifficulty: 'medium',
                onlineOpponentName: widget.targetUserName,
                initialTimeSeconds: chosenSeconds,
              ),
            ),
          );
        });
      }
      return;
    }

    // Select chess time control for human player
    final chosenSeconds = await ChessTimeControlDialog.show(
      context,
      title: 'Challenge ${widget.targetUserName}',
      subtitle: 'Select time control for online chess match',
      allowUnlimited: false,
      defaultSeconds: 600,
      actionButtonText: 'Send Invite ⚔️',
    );
    if (chosenSeconds == null || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sending challenge (${ChessTimeControl.formatSummary(chosenSeconds)}) to ${widget.targetUserName}... ⏳'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF1E3A8A),
      ),
    );

    // 1. Send formal challenge to Firestore with timeControl
    final challengeId = await ChessOnlineService.sendChallenge(
      targetUserId: widget.targetUserId,
      targetUserName: widget.targetUserName,
      targetUserAvatar: widget.targetUserAvatar,
      currentUserName: currentName,
      currentUserAvatar: currentAvatar,
      timeControl: chosenSeconds,
    );

    // 2. Post invitation card message into the chat room WITH challengeId and time summary
    if (challengeId != null) {
      _sendMessage(
        type: 'chess_invite',
        challengeId: challengeId,
        customText: 'Let\'s play Chess together! ♟️ (${ChessTimeControl.formatSummary(chosenSeconds)})',
      );

      _listenToOutgoingChallenge(challengeId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chess challenge sent to ${widget.targetUserName}! ⚔️'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send challenge (check network or Firebase rules)'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _listenToOutgoingChallenge(String challengeId) {
    _outgoingChallengeSub?.cancel();
    _outgoingChallengeSub = ChessOnlineService.streamChallenge(challengeId).listen((doc) {
      if (!doc.exists || !mounted) return;
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return;

      final status = data['status']?.toString();
      final matchId = data['match_id']?.toString();

      if (status == 'accepted' && matchId != null && matchId != _joinedMatchId) {
        _outgoingChallengeSub?.cancel();

        _enterMatch(matchId, 'white');
      } else if (status == 'declined' || status == 'cancelled') {
        _outgoingChallengeSub?.cancel();
        ChatService.updateChallengeStatusByChallengeId(
          targetUserId: widget.targetUserId,
          challengeId: challengeId,
          status: 'declined',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${widget.targetUserName} declined the chess challenge.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    });
  }

  void _declineChallengeFromChat(ChatMessageModel msg) async {
    if (msg.challengeId != null && msg.challengeId!.isNotEmpty) {
      await ChessOnlineService.declineChallenge(msg.challengeId!);
    }
    await ChatService.updateMessageChallengeStatus(
      targetUserId: widget.targetUserId,
      messageId: msg.id,
      status: 'declined',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chess challenge declined.'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _acceptChallengeFromChat(ChatMessageModel msg) async {
    final isBot = widget.targetUserId.startsWith('bot_');
    if (isBot) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚡ Starting chess match with ${widget.targetUserName}...'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChessGameScreen(
            isAIGame: true,
            aiDifficulty: 'medium',
            onlineOpponentName: widget.targetUserName,
          ),
        ),
      );
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final myId = userProvider.userData?['id']?.toString() ??
        ChessOnlineService.currentUserId ?? '';
    final currentName = userProvider.userData?['username']?.toString() ?? 'Player';
    final currentAvatar = userProvider.userData?['avatar']?.toString();
    final isMe = msg.senderId == myId;

    // Jika pertandingan sudah ada / match_id sudah terisi, periksa statusnya terlebih dahulu
    if (msg.matchId != null && msg.matchId!.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance.collection('chess_matches').doc(msg.matchId).get();
        if (doc.exists) {
          final mStatus = doc.data()?['status']?.toString();
          if (mStatus != null && mStatus != 'ongoing') {
            final newStatus = (mStatus == 'aborted') ? 'aborted' : 'completed';
            await ChatService.updateMessageChallengeStatus(
              targetUserId: widget.targetUserId,
              messageId: msg.id,
              status: newStatus,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('This match has already ended ($mStatus).'),
                  backgroundColor: Colors.grey.shade800,
                ),
              );
            }
            return;
          }
        }
      } catch (e) {
        debugPrint('Error verifying match status: $e');
      }
      _enterMatch(msg.matchId!, isMe ? 'white' : 'black');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Accepting challenge... Setting up online chessboard ⏳'),
        backgroundColor: Color(0xFF1E3A8A),
      ),
    );

    ChessChallengeModel? targetChallenge;

    // 1. Ambil dokumen tantangan asli dari challengeId pada pesan jika ada
    if (msg.challengeId != null && msg.challengeId!.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('chess_challenges')
            .doc(msg.challengeId)
            .get();
        if (doc.exists) {
          final cStatus = doc.data()?['status']?.toString();
          if (cStatus == 'declined' || cStatus == 'cancelled') {
            await ChatService.updateMessageChallengeStatus(
              targetUserId: widget.targetUserId,
              messageId: msg.id,
              status: 'declined',
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This challenge has been declined or cancelled.'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
            return;
          }
          targetChallenge = ChessChallengeModel.fromFirestore(doc);
        }
      } catch (e) {
        debugPrint('Error fetching challenge doc by id: $e');
      }
    }

    // 2. Fallback: cari pending challenge dari lawan
    if (targetChallenge == null && myId.isNotEmpty) {
      try {
        final incomingList = await ChessOnlineService.getIncomingChallengesOnce(myId);
        final matchFound = incomingList.where((c) => c.senderId == widget.targetUserId);
        if (matchFound.isNotEmpty) {
          targetChallenge = matchFound.first;
        }
      } catch (e) {
        debugPrint('Error searching incoming challenges: $e');
      }
    }

    // 3. Robust Ultimate Fallback: Jika tidak ditemukan di Firestore, buat model secara instan
    // dari data percakapan chat agar tantangan TIDAK PERNAH gagal dibuat!
    targetChallenge ??= ChessChallengeModel(
      id: (msg.challengeId != null && msg.challengeId!.isNotEmpty)
          ? msg.challengeId!
          : 'chat_inv_${msg.id}',
      senderId: msg.senderId.isNotEmpty ? msg.senderId : widget.targetUserId,
      senderName: msg.senderName.isNotEmpty ? msg.senderName : widget.targetUserName,
      senderAvatar: msg.senderAvatar ?? widget.targetUserAvatar,
      receiverId: myId,
      receiverName: currentName,
      receiverAvatar: currentAvatar,
      status: 'pending',
      timeControl: 600,
      createdAt: msg.timestamp,
    );

    final matchId = await ChessOnlineService.acceptChallenge(targetChallenge);
    if (matchId != null && mounted) {
      // Update pesan di chat room agar menyimpan matchId
      await ChatService.updateMessageMatchId(
        targetUserId: widget.targetUserId,
        messageId: msg.id,
        matchId: matchId,
      );

      // Penerima tantangan masuk sebagai Hitam (Black)
      _enterMatch(matchId, 'black');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create chess match. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUserId = userProvider.userData?['id']?.toString() ??
        ChessOnlineService.currentUserId ?? '';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
              Color(0xFF0F172A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: StreamBuilder<List<ChatMessageModel>>(
                  stream: ChatService.streamMessages(widget.targetUserId, customSenderId: currentUserId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.blueAccent),
                      );
                    }

                    final messages = snapshot.data ?? [];

                    // Auto-sync: Jika tantangan yang saya kirim telah diterima lawan (punya matchId)
                    // dan belum dinavigasi, langsung arahkan penantang (Putih) masuk ke game!
                    for (final m in messages) {
                      if (m.senderId == currentUserId &&
                          m.type == 'chess_invite' &&
                          m.matchId != null &&
                          m.matchId!.isNotEmpty &&
                          m.matchId != _joinedMatchId) {
                        _joinedMatchId = m.matchId;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _enterMatch(m.matchId!, 'white');
                        });
                        break;
                      }
                    }

                    if (messages.isEmpty || snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.forum_outlined, size: 64, color: Colors.white.withValues(alpha: 0.25)),
                            const SizedBox(height: 12),
                            Text(
                              'Mulai percakapan dengan ${widget.targetUserName}',
                              style: const TextStyle(color: Colors.white60, fontSize: 14),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.sports_esports_rounded, size: 18),
                              label: const Text('Ajak Main Catur ♟️'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _sendChessChallengeInvite,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg.senderId == currentUserId;
                        return _buildMessageBubble(msg, isMe);
                      },
                    );
                  },
                ),
              ),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.95),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blueGrey,
                backgroundImage: widget.targetUserAvatar != null && widget.targetUserAvatar!.isNotEmpty
                    ? ImageHelper.getImageProvider(widget.targetUserAvatar)
                    : null,
                child: widget.targetUserAvatar == null || widget.targetUserAvatar!.isEmpty
                    ? Text(
                        widget.targetUserName.isNotEmpty ? widget.targetUserName[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              // Stream status online di avatar
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(widget.targetUserId).snapshots(),
                builder: (context, snapshot) {
                  Map<String, dynamic>? userData;
                  if (snapshot.hasData && snapshot.data!.exists) {
                    userData = snapshot.data!.data() as Map<String, dynamic>?;
                  }
                  final isOnline = NotificationService.isUserOnline(userData);
                  return Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: isOnline ? const Color(0xFF22C55E) : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF1E293B), width: 2),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Username & Real-time Presence WhatsApp-style
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.targetUserName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(widget.targetUserId).snapshots(),
                  builder: (context, snapshot) {
                    Map<String, dynamic>? userData;
                    if (snapshot.hasData && snapshot.data!.exists) {
                      userData = snapshot.data!.data() as Map<String, dynamic>?;
                    }
                    final isOnline = NotificationService.isUserOnline(userData);
                    final presenceText = NotificationService.formatLastSeen(userData);

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isOnline ? const Color(0xFF22C55E) : Colors.white38,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            isOnline ? 'Online' : presenceText,
                            style: TextStyle(
                              color: isOnline ? const Color(0xFF22C55E) : Colors.white60,
                              fontSize: 11,
                              fontWeight: isOnline ? FontWeight.w600 : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.sports_esports, size: 16),
            label: const Text('Challenge', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _sendChessChallengeInvite,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel msg, bool isMe) {
    final timeStr = DateFormat('HH:mm').format(msg.timestamp);

    if (msg.type == 'chess_invite') {
      if (msg.challengeId != null && msg.challengeId!.isNotEmpty) {
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chess_challenges')
              .doc(msg.challengeId!)
              .snapshots(),
          builder: (context, snapshot) {
            String challengeStatus = msg.challengeStatus ?? 'pending';
            String? matchId = msg.matchId;

            if (snapshot.hasData && snapshot.data!.exists) {
              final cData = snapshot.data!.data() as Map<String, dynamic>?;
              if (cData != null) {
                final remoteStatus = cData['status']?.toString();
                final remoteMatchId = cData['match_id']?.toString();
                if (remoteStatus != null && remoteStatus.isNotEmpty) {
                  challengeStatus = remoteStatus;
                }
                if (remoteMatchId != null && remoteMatchId.isNotEmpty) {
                  matchId = remoteMatchId;
                }
              }
            }

            return _buildInviteBubble(
              msg: msg,
              isMe: isMe,
              timeStr: timeStr,
              challengeStatus: challengeStatus,
              matchId: matchId,
            );
          },
        );
      }
      return _buildInviteBubble(
        msg: msg,
        isMe: isMe,
        timeStr: timeStr,
        challengeStatus: msg.challengeStatus ?? 'pending',
        matchId: msg.matchId,
      );
    }
  }

  Widget _buildInviteBubble({
    required ChatMessageModel msg,
    required bool isMe,
    required String timeStr,
    required String challengeStatus,
    required String? matchId,
  }) {
    final isMatchCreated = matchId != null && matchId.isNotEmpty && challengeStatus == 'accepted';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 290),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isMe
                ? [const Color(0xFF1E3A8A), const Color(0xFF2563EB)]
                : [const Color(0xFF1E293B), const Color(0xFF334155)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMatchCreated ? const Color(0xFF10B981) : Colors.blueAccent.withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isMatchCreated ? const Color(0xFF10B981) : Colors.blueAccent).withValues(alpha: 0.25),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sports_esports_rounded, color: Colors.amberAccent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    challengeStatus == 'declined'
                        ? '❌ Challenge Declined'
                        : challengeStatus == 'aborted'
                            ? '⏱️ Match Aborted'
                            : challengeStatus == 'completed'
                                ? '🏁 Match Completed'
                                : isMatchCreated
                                    ? '🎮 Active Chess Match'
                                    : (isMe ? 'Chess Invitation Sent' : '⚔️ Incoming Chess Challenge!'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              msg.text,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 10),
            // Status Badge & Action Buttons
            if (challengeStatus == 'declined') ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Challenge was declined',
                      style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ] else if (challengeStatus == 'aborted') ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_off_rounded, color: Colors.orangeAccent, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Match was aborted',
                      style: TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ] else if (challengeStatus == 'completed') ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.purpleAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events_rounded, color: Colors.purpleAccent, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Match has finished',
                      style: TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ] else if (isMatchCreated) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Challenge Accepted & Active!',
                      style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_circle_fill_rounded, size: 16),
                  label: Text(
                    isMe ? 'Enter Match (White ⚪)' : 'Enter Match (Black ⚫)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _enterMatch(matchId, isMe ? 'white' : 'black'),
                ),
              ),
            ] else if (!isMe) ...[
              // Penerima: tombol Terima & Tolak
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.sports_esports_rounded, size: 16),
                      label: const Text('Accept ♟️', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _acceptChallengeFromChat(msg),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _declineChallengeFromChat(msg),
                      child: const Text('Decline', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Pengirim: indikator menunggu lawan
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amberAccent),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Waiting for opponent to accept...',
                      style: TextStyle(color: Colors.amberAccent, fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                timeStr,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF2563EB) : const Color(0xFF334155),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.sports_esports_outlined, color: Colors.amberAccent),
            tooltip: 'Send Chess Challenge',
            onPressed: _sendChessChallengeInvite,
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: () => _sendMessage(),
            ),
          ),
        ],
      ),
    );
  }
}
