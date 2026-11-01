import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sentient/core/providers/user_provider.dart';
import 'package:sentient/core/services/notification_service.dart';
import 'package:sentient/core/utils/image_helper.dart';
import 'package:sentient/features/chat/direct_chat_screen.dart';
import 'package:sentient/features/chat/services/chat_service.dart';
import 'package:sentient/features/chess/chess_game_screen.dart';
import 'package:sentient/features/chess/chess_lobby_screen.dart';
import 'package:sentient/features/chess/models/chess_challenge_model.dart';
import 'package:sentient/features/chess/models/chess_time_control.dart';
import 'package:sentient/features/chess/services/chess_online_service.dart';

class NotificationHubScreen extends StatelessWidget {
  const NotificationHubScreen({super.key});

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
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Incoming Chess Challenges
                      _buildIncomingChallengesSection(context, currentUserId),
                      const SizedBox(height: 8),
                      // Section 1.5: Active / Ongoing Matches
                      _buildActiveMatchesSection(context, currentUserId),
                      const SizedBox(height: 16),
                      // Section 2: Recent Chat Conversations
                      const Text(
                        'Recent Messages & Chats',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildChatsList(context, currentUserId),
                    ],
                  ),
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
                  'Messages & Challenges',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Chats & online chess challenges from other players',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingChallengesSection(BuildContext context, String currentUserId) {
    return StreamBuilder<List<ChessChallengeModel>>(
      stream: ChessOnlineService.streamIncomingChallenges(currentUserId),
      builder: (context, snapshot) {
        final challenges = snapshot.data ?? [];
        if (challenges.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sports_esports_rounded, color: Colors.amberAccent, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Incoming Chess Challenges (${challenges.length})',
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...challenges.map((challenge) => _buildChallengeCard(context, challenge)),
            const Divider(color: Colors.white12, height: 28),
          ],
        );
      },
    );
  }

  Widget _buildChallengeCard(BuildContext context, ChessChallengeModel challenge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF065F46), Color(0xFF047857)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF34D399), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.25),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white24,
                child: Text(
                  challenge.senderName.isNotEmpty ? challenge.senderName[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.senderName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      'Challenged you to play (${ChessTimeControl.formatSummary(challenge.timeControl)}) ♟️',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ChessOnlineService.declineChallenge(challenge.id),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final matchId = await ChessOnlineService.acceptChallenge(challenge);
                    if (matchId != null && context.mounted) {
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
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveMatchesSection(BuildContext context, String currentUserId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ChessOnlineService.streamActiveMatches(currentUserId),
      builder: (context, snapshot) {
        final matches = snapshot.data ?? [];
        if (matches.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.flash_on_rounded, color: Colors.cyanAccent, size: 20),
                SizedBox(width: 8),
                Text(
                  'Pertandingan Berlangsung',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...matches.map((m) => _buildActiveMatchCard(context, m, currentUserId)),
            const Divider(color: Colors.white12, height: 28),
          ],
        );
      },
    );
  }

  Widget _buildActiveMatchCard(BuildContext context, Map<String, dynamic> match, String currentUserId) {
    final matchId = match['id']?.toString() ?? match['match_id']?.toString() ?? '';
    final isWhite = match['white_player_id'] == currentUserId;
    final opponentName = isWhite
        ? (match['black_player_name']?.toString() ?? 'Opponent')
        : (match['white_player_name']?.toString() ?? 'Opponent');
    final opponentAvatar = isWhite
        ? match['black_player_avatar']?.toString()
        : match['white_player_avatar']?.toString();
    final currentTurn = match['current_turn']?.toString() ?? 'white';
    final isMyTurn = (isWhite && currentTurn == 'white') || (!isWhite && currentTurn == 'black');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isMyTurn
              ? [const Color(0xFF1E3A8A), const Color(0xFF2563EB)]
              : [const Color(0xFF1E293B), const Color(0xFF334155)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMyTurn ? Colors.cyanAccent : Colors.white24,
          width: isMyTurn ? 1.5 : 1,
        ),
        boxShadow: isMyTurn
            ? [
                BoxShadow(
                  color: Colors.cyanAccent.withValues(alpha: 0.2),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.black26,
              shape: BoxShape.circle,
            ),
            child: Text(
              isWhite ? '♔' : '♚',
              style: const TextStyle(fontSize: 22, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Opponent: $opponentName',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 3),
                Text(
                  isMyTurn ? '⚡ Your turn to move!' : '⏳ Waiting for $opponentName\'s move...',
                  style: TextStyle(
                    color: isMyTurn ? Colors.amberAccent : Colors.white70,
                    fontSize: 12,
                    fontWeight: isMyTurn ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChessGameScreen(
                    isAIGame: false,
                    isOnlineGame: true,
                    onlineMatchId: matchId,
                    onlinePlayerColor: isWhite ? 'white' : 'black',
                    onlineOpponentName: opponentName,
                    onlineOpponentAvatar: opponentAvatar,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isMyTurn ? const Color(0xFF10B981) : Colors.white24,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Main ♟️', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildChatsList(BuildContext context, String currentUserId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ChatService.streamUserChatRooms(customUserId: currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(color: Colors.blueAccent),
            ),
          );
        }

        final rooms = snapshot.data ?? [];

        if (rooms.isEmpty || snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 56,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Messages Yet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Chats and chess challenges from other players will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.people_alt_rounded, size: 18),
                    label: const Text(
                      'Open Online Players Lobby',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChessLobbyScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index];
            final users = (room['users'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
            final targetUserId = users.firstWhere((id) => id != currentUserId, orElse: () => '');

            final lastMsg = room['last_message']?.toString() ?? '';
            final lastSenderName = room['last_sender_name']?.toString() ?? 'Player';
            final lastMsgType = room['last_message_type']?.toString() ?? 'text';
            final isChessInvite = lastMsgType == 'chess_invite';

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(targetUserId).snapshots(),
              builder: (context, userSnap) {
                Map<String, dynamic>? targetUserData;
                if (userSnap.hasData && userSnap.data!.exists) {
                  targetUserData = userSnap.data!.data() as Map<String, dynamic>?;
                }
                final isOnline = NotificationService.isUserOnline(targetUserData);
                final statusText = NotificationService.formatLastSeen(targetUserData);
                final friendName = targetUserData?['username']?.toString() ?? lastSenderName;
                final friendAvatar = targetUserData?['avatar']?.toString();

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isChessInvite 
                          ? Colors.amber.withValues(alpha: 0.4) 
                          : Colors.white.withValues(alpha: 0.08),
                      width: isChessInvite ? 1.5 : 1.0,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: isChessInvite ? Colors.amber.shade900 : const Color(0xFF2563EB),
                          backgroundImage: friendAvatar != null && friendAvatar.isNotEmpty
                              ? ImageHelper.getImageProvider(friendAvatar)
                              : null,
                          child: friendAvatar == null || friendAvatar.isEmpty
                              ? Text(
                                  friendName.isNotEmpty ? friendName[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        Positioned(
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
                        ),
                      ],
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            friendName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isChessInvite)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                            ),
                            child: const Text(
                              '♟️ Challenge',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lastMsg,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isChessInvite ? Colors.amberAccent : Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: isOnline ? const Color(0xFF22C55E) : Colors.white30,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                statusText,
                                style: TextStyle(
                                  color: isOnline ? const Color(0xFF22C55E) : Colors.white38,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DirectChatScreen(
                            targetUserId: targetUserId,
                            targetUserName: friendName,
                            targetUserAvatar: friendAvatar,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
