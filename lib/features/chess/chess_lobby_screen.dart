import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sentient/core/providers/user_provider.dart';
import 'package:sentient/core/services/notification_service.dart';
import 'package:sentient/core/utils/image_helper.dart';
import 'package:sentient/features/chess/chess_game_screen.dart';
import 'package:sentient/features/chess/models/chess_challenge_model.dart';
import 'package:sentient/features/chess/models/chess_time_control.dart';
import 'package:sentient/features/chess/widgets/chess_time_control_dialog.dart';
import 'package:sentient/features/chess/services/chess_online_service.dart';
import 'package:sentient/features/chat/direct_chat_screen.dart';

class ChessLobbyScreen extends StatefulWidget {
  const ChessLobbyScreen({super.key});

  @override
  State<ChessLobbyScreen> createState() => _ChessLobbyScreenState();
}

class _ChessLobbyScreenState extends State<ChessLobbyScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _activeChallengeId;
  String? _challengedUserName;
  String? _challengedUserAvatar;
  StreamSubscription? _challengeSub;
  StreamSubscription? _acceptedSentSub;
  Timer? _presenceRefreshTimer;
  String? _joinedMatchId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLobbyListeners();
    });
    // Auto-refresh lobby presence every 15 seconds
    _presenceRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _presenceRefreshTimer?.cancel();
    _searchController.dispose();
    _challengeSub?.cancel();
    _acceptedSentSub?.cancel();
    super.dispose();
  }

  void _initLobbyListeners() {
    final myId = Provider.of<UserProvider>(context, listen: false).userData?['id']?.toString() ??
        ChessOnlineService.currentUserId ?? '';
    if (myId.isEmpty) return;

    // Bersihkan tantangan accepted dari match lama yang sudah selesai
    ChessOnlineService.cleanUpStaleAcceptedChallenges(myId);

    _acceptedSentSub?.cancel();
    _acceptedSentSub = ChessOnlineService.streamAcceptedSentChallenges(myId).listen((challenges) async {
      if (!mounted) return;
      for (final c in challenges) {
        if (c.matchId != null && c.matchId!.isNotEmpty && c.matchId != _joinedMatchId) {
          // Validasi ketat: Apakah pertandingan benar-benar masih aktif (ongoing)?
          final isOngoing = await ChessOnlineService.isMatchOngoing(c.matchId!);
          if (!isOngoing) {
            // Match sudah selesai (resigned/checkmate/aborted/draw/dsb). Tandai tantangan completed & jangan masuk!
            await ChessOnlineService.completeChallenge(c.id);
            continue;
          }

          _joinedMatchId = c.matchId;
          // Tandai tantangan sudah dimulai agar tidak ter-trigger ulang
          await ChessOnlineService.markChallengeStarted(c.id);

          _challengeSub?.cancel();
          if (mounted) {
            setState(() {
              _activeChallengeId = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🎉 ${c.receiverName} accepted the challenge! Starting chess match...'),
                backgroundColor: const Color(0xFF10B981),
              ),
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChessGameScreen(
                  isAIGame: false,
                  isOnlineGame: true,
                  onlineMatchId: c.matchId!,
                  onlinePlayerColor: 'white',
                  onlineOpponentName: c.receiverName,
                  onlineOpponentAvatar: c.receiverAvatar,
                ),
              ),
            );
          }
          break;
        }
      }
    });
  }

  void _sendChallengeToUser(Map<String, dynamic> targetUser, Map<String, dynamic>? currentUser) async {
    final targetId = targetUser['id']?.toString() ?? '';
    final targetName = targetUser['username']?.toString() ?? 'Player';
    final targetAvatar = targetUser['avatar']?.toString();
    final currentName = currentUser?['username']?.toString() ?? 'Player';
    final currentAvatar = currentUser?['avatar']?.toString();

    // Select chess time control first
    final selectedTimeControl = await ChessTimeControlDialog.show(
      context,
      title: 'Challenge $targetName',
      subtitle: 'Select time control for online chess match',
      allowUnlimited: false,
      defaultSeconds: 600,
      actionButtonText: 'Send Challenge ⚔️',
    );
    if (selectedTimeControl == null || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sending challenge (${ChessTimeControl.formatSummary(selectedTimeControl)}) to $targetName... ⏳'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF1E3A8A),
      ),
    );

    final challengeId = await ChessOnlineService.sendChallenge(
      targetUserId: targetId,
      targetUserName: targetName,
      targetUserAvatar: targetAvatar,
      currentUserName: currentName,
      currentUserAvatar: currentAvatar,
      timeControl: selectedTimeControl,
    );

    if (challengeId != null && mounted) {
      setState(() {
        _activeChallengeId = challengeId;
        _challengedUserName = targetName;
        _challengedUserAvatar = targetAvatar;
      });

      _listenToSentChallenge(challengeId);
    } else if (mounted) {
      _showFirestoreRulesDialog();
    }
  }

  void _showFirestoreRulesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2638),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.security_rounded, color: Colors.amber, size: 24),
            SizedBox(width: 8),
            Text(
              'Firestore Rules',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ensure Firestore read/write rules are properly configured in Firebase Console for online multiplayer synchronization.',
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Text(
                  'match /users/{userId} { allow read: if request.auth != null; }\n'
                  'match /chess_challenges/{id} { allow read, write: if request.auth != null; }\n'
                  'match /chess_matches/{id} { allow read, write: if request.auth != null; }',
                  style: TextStyle(color: Colors.cyanAccent, fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Rules'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: '''rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
      allow create: if request.auth != null;
    }
    match /chess_challenges/{challengeId} {
      allow read, write: if request.auth != null;
    }
    match /chess_matches/{matchId} {
      allow read, write: if request.auth != null;
    }
    match /chat_rooms/{roomId} {
      allow read, write: if request.auth != null;
      match /messages/{messageId} {
        allow read, write: if request.auth != null;
      }
    }
  }
}'''));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Firestore rules copied to clipboard!'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _listenToSentChallenge(String challengeId) {
    _challengeSub?.cancel();
    _challengeSub = ChessOnlineService.streamChallenge(challengeId).listen((doc) {
      if (!doc.exists || !mounted) return;
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return;

      final status = data['status']?.toString();
      final matchId = data['match_id']?.toString();

      if (status == 'accepted' && matchId != null) {
        _joinedMatchId = matchId;
        ChessOnlineService.markChallengeStarted(challengeId);
        _challengeSub?.cancel();
        setState(() {
          _activeChallengeId = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Challenge accepted! Starting chess match...'),
            backgroundColor: Color(0xFF10B981),
          ),
        );

        // Opponent accepted: Challenger automatically enters as White
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChessGameScreen(
              isAIGame: false,
              isOnlineGame: true,
              onlineMatchId: matchId,
              onlinePlayerColor: 'white',
              onlineOpponentName: _challengedUserName ?? 'Opponent',
              onlineOpponentAvatar: _challengedUserAvatar,
            ),
          ),
        );
      } else if (status == 'declined') {
        _challengeSub?.cancel();
        setState(() {
          _activeChallengeId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $_challengedUserName declined the chess challenge.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });
  }

  void _cancelActiveChallenge([String? targetId]) async {
    final id = targetId ?? _activeChallengeId;
    if (id != null) {
      await ChessOnlineService.cancelChallenge(id);
      _challengeSub?.cancel();
      if (mounted) {
        setState(() {
          _activeChallengeId = null;
          _challengedUserName = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Challenge cancelled')),
        );
      }
    }
  }

  void _acceptIncomingChallenge(ChessChallengeModel challenge) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Accepting challenge... Setting up chessboard ♟️'),
        backgroundColor: Color(0xFF1E3A8A),
      ),
    );

    final matchId = await ChessOnlineService.acceptChallenge(challenge);
    if (matchId != null && mounted) {
      _joinedMatchId = matchId;
      await ChessOnlineService.markChallengeStarted(challenge.id);
      // Challenge receiver enters as Black
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChessGameScreen(
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
  }

  void _declineIncomingChallenge(ChessChallengeModel challenge) async {
    await ChessOnlineService.declineChallenge(challenge.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Challenge declined')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserProvider>(context).userData;
    final currentUserId = currentUser?['id']?.toString() ??
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
              _buildSearchBar(),
              // Banner tantangan masuk realtime dari Firestore
              StreamBuilder<List<ChessChallengeModel>>(
                stream: ChessOnlineService.streamIncomingChallenges(currentUserId),
                builder: (context, snapshot) {
                  final list = snapshot.data ?? [];
                  if (list.isEmpty) return const SizedBox.shrink();
                  return _buildIncomingChallengeBanner(list.first);
                },
              ),
              // Banner tantangan keluar realtime dari Firestore
              StreamBuilder<List<ChessChallengeModel>>(
                stream: ChessOnlineService.streamOutgoingChallenges(currentUserId),
                builder: (context, snapshot) {
                  final list = snapshot.data ?? [];
                  if (list.isEmpty && _activeChallengeId == null) return const SizedBox.shrink();
                  final targetName = list.isNotEmpty ? list.first.receiverName : (_challengedUserName ?? 'Opponent');
                  final challengeId = list.isNotEmpty ? list.first.id : _activeChallengeId;
                  return _buildPendingChallengeBanner(targetName, challengeId);
                },
              ),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: ChessOnlineService.streamRegisteredUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.blueAccent),
                      );
                    }

                    final allUsers = (snapshot.hasError || snapshot.data == null)
                        ? <Map<String, dynamic>>[]
                        : snapshot.data!;

                    // Filter search query
                    var filteredUsers = allUsers.where((u) {
                      final name = (u['username'] ?? '').toString().toLowerCase();
                      final email = (u['email'] ?? '').toString().toLowerCase();
                      return name.contains(_searchQuery.toLowerCase()) ||
                             email.contains(_searchQuery.toLowerCase());
                    }).toList();

                    // Urutkan user online di atas
                    filteredUsers.sort((a, b) {
                      final aOnline = NotificationService.isUserOnline(a) ? 1 : 0;
                      final bOnline = NotificationService.isUserOnline(b) ? 1 : 0;
                      return bOnline.compareTo(aOnline);
                    });

                    return Column(
                      children: [
                        Expanded(
                          child: filteredUsers.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.person_off_rounded, size: 64, color: Colors.white.withValues(alpha: 0.3)),
                                      const SizedBox(height: 16),
                                      Text(
                                        _searchQuery.isEmpty 
                                            ? 'No other players registered yet.' 
                                            : 'No players found matching "$_searchQuery"',
                                        style: const TextStyle(color: Colors.white60, fontSize: 15),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  physics: const ClampingScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  itemCount: filteredUsers.length,
                                  itemBuilder: (context, index) {
                                    final user = filteredUsers[index];
                                    return _buildUserCard(user, currentUser);
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Online Players Lobby',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  'Challenge other players to play chess online',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search players by username...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white60),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (val) {
          setState(() => _searchQuery = val.trim());
        },
      ),
    );
  }

  /// Banner tantangan masuk yang diterima pemain saat ini
  Widget _buildIncomingChallengeBanner(ChessChallengeModel challenge) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF065F46), Color(0xFF047857)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF34D399), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.35),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sports_esports_rounded, color: Colors.amberAccent, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '⚔️ Incoming Challenge from ${challenge.senderName}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text(
                'Opponent invites you to play: ',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  ChessTimeControl.formatSummary(challenge.timeControl),
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _declineIncomingChallenge(challenge),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white30),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Decline ❌'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Accept & Play ♟️', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF065F46),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _acceptIncomingChallenge(challenge),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Banner menunggu ketika kita mengirim tantangan ke pemain lain
  Widget _buildPendingChallengeBanner([String? opponentName, String? challengeId]) {
    final displayName = opponentName ?? _challengedUserName ?? 'Opponent';
    final targetId = challengeId ?? _activeChallengeId;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blueAccent, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withValues(alpha: 0.3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Waiting for Opponent to Accept...',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Challenge sent to $displayName',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _cancelActiveChallenge(targetId),
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, Map<String, dynamic>? currentUser) {
    final username = user['username']?.toString() ?? 'Player';
    final avatar = user['avatar']?.toString();
    final isOnline = NotificationService.isUserOnline(user);
    final statusText = NotificationService.formatLastSeen(user);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isOnline
            ? const Color(0xFF1E293B).withValues(alpha: 0.9)
            : const Color(0xFF1E293B).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOnline
              ? const Color(0xFF10B981).withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.08),
          width: isOnline ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar dengan indicator online WhatsApp-style
          Stack(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: isOnline ? const Color(0xFF0F766E) : Colors.blueGrey,
                backgroundImage: avatar != null && avatar.isNotEmpty
                    ? ImageHelper.getImageProvider(avatar)
                    : null,
                child: avatar == null || avatar.isEmpty
                    ? Text(
                        username.isNotEmpty ? username[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: isOnline ? const Color(0xFF22C55E) : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF1E293B), width: 2.2),
                    boxShadow: isOnline
                        ? [
                            BoxShadow(
                              color: const Color(0xFF22C55E).withValues(alpha: 0.6),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Username & Status WhatsApp-style
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isOnline ? const Color(0xFF22C55E) : Colors.white38,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: isOnline ? const Color(0xFF22C55E) : Colors.white54,
                          fontSize: 12,
                          fontWeight: isOnline ? FontWeight.w600 : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Action Buttons: Chat & Challenge
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DirectChatScreen(
                            targetUserId: user['id']?.toString() ?? '',
                            targetUserName: username,
                            targetUserAvatar: avatar,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.blueAccent, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.sports_esports_rounded, size: 15),
                  label: const Text('Challenge', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOnline ? const Color(0xFF2563EB) : const Color(0xFF3B82F6).withValues(alpha: 0.8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _activeChallengeId == null
                      ? () => _sendChallengeToUser(user, currentUser)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
