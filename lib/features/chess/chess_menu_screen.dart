import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentient/core/providers/user_provider.dart';
import 'package:sentient/core/utils/image_helper.dart';
import 'package:sentient/features/chess/chess_game_screen.dart';
import 'package:sentient/features/chess/chess_lobby_screen.dart';
import 'package:sentient/features/chess/widgets/chess_profile_dialog.dart';
import 'package:sentient/features/chess/services/chess_online_service.dart';
import 'package:sentient/features/chess/models/chess_challenge_model.dart';
import 'package:sentient/features/chess/widgets/chess_time_control_dialog.dart';
import 'package:sentient/features/notifications/notification_hub_screen.dart';

class ChessMenuScreen extends StatelessWidget {
  const ChessMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildVSAIBanner(context),
                      const SizedBox(height: 24),
                      _buildGameModes(context),
                      const SizedBox(height: 24),
                      _buildTournaments(context),
                      const SizedBox(height: 24),
                      _buildRanking(context),
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
    final currentUserId = Provider.of<UserProvider>(context).userData?['id']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Notification & Incoming Chess Challenges Hub Button
          StreamBuilder<List<ChessChallengeModel>>(
            stream: ChessOnlineService.streamIncomingChallenges(currentUserId),
            builder: (context, snapshot) {
              final challengeCount = snapshot.data?.length ?? 0;
              final hasIncoming = challengeCount > 0;

              return IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: hasIncoming 
                            ? Colors.redAccent.withValues(alpha: 0.25)
                            : Colors.blueAccent.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: hasIncoming 
                              ? Colors.redAccent.withValues(alpha: 0.8)
                              : Colors.cyanAccent.withValues(alpha: 0.6), 
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (hasIncoming ? Colors.redAccent : Colors.cyanAccent).withValues(alpha: 0.25),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        hasIncoming ? Icons.notifications_active_rounded : Icons.chat_bubble_outline_rounded,
                        color: hasIncoming ? Colors.amberAccent : Colors.cyanAccent,
                        size: 20,
                      ),
                    ),
                    if (hasIncoming)
                      Positioned(
                        top: -3,
                        right: -3,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.6),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Center(
                            child: Text(
                              challengeCount > 9 ? '9+' : '$challengeCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                tooltip: 'Messages & Chess Challenges',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationHubScreen(),
                    ),
                  );
                },
              );
            },
          ),
          const Expanded(
            child: Text(
              '♔ Sentient Chess ♚',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 10,
                    color: Colors.blue,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.6), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withValues(alpha: 0.25),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.person_rounded, color: Colors.cyanAccent, size: 20),
            ),
            tooltip: 'Chess Career & Profile',
            onPressed: () {
              ChessProfileDialog.show(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVSAIBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAIDialog(context),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 24),
        child: Stack(
          children: [
          // Background gradient with glass effect
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2563EB),
                  Color(0xFF1D4ED8),
                  Color(0xFF1E40AF),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.35),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
          ),
          
          // Glass overlay
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          
          // Content
          Container(
            height: 200,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // Left side - Robot Icon and Title
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.smart_toy_rounded,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'VS AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Challenge smart computer AI',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Right side - Button
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showAIDialog(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: const Text(
                              'CHOOSE\nLEVEL',
                              style: TextStyle(
                                color: Color(0xFF1D4ED8),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildGameModes(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Game Modes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.25,
          children: [
            _buildGameModeCard(
              context,
              icon: Icons.people_rounded,
              title: 'vs Friend',
              subtitle: 'Local multiplayer',
              color: Colors.blue,
              onTap: () => _showFriendDialog(context),
            ),
            _buildGameModeCard(
              context,
              icon: Icons.public_rounded,
              title: 'Online',
              subtitle: 'Play worldwide',
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChessLobbyScreen()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGameModeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournaments(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 22),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Community Tournaments',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_clock_rounded, size: 12, color: Colors.amber),
                  SizedBox(width: 4),
                  Text(
                    'Season 1',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showTournamentInfoSheet(context),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFB45309), // Amber-700
                    Color(0xFFD97706), // Amber-600
                    Color(0xFFF59E0B), // Amber-500
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.6), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(
                          Icons.military_tech_rounded,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sentient Chess League (Season 1)',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Sentient members tournament • Coming Soon',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildTournamentPill(Icons.account_tree_outlined, 'Knockout System'),
                          const SizedBox(width: 12),
                          Container(width: 1, height: 16, color: Colors.white24),
                          const SizedBox(width: 12),
                          _buildTournamentPill(Icons.workspace_premium_rounded, 'Master Title'),
                          const SizedBox(width: 12),
                          Container(width: 1, height: 16, color: Colors.white24),
                          const SizedBox(width: 12),
                          _buildTournamentPill(Icons.groups_rounded, 'All Members'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTournamentPill(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showTournamentInfoSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Colors.amber, width: 2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Text('🏆', style: TextStyle(fontSize: 28)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sentient Chess League (Season 1)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Inaugural Season Preparation',
                        style: TextStyle(color: Colors.amber, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Official tournament between Sentient members is currently in preparation! The tournament bracket system will be open soon.\n\nWhile waiting for registration to open, sharpen your skills against AI Bots or challenge other members in the Online Lobby to earn victories on the Leaderboard!',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.sports_esports_rounded, size: 18),
                label: const Text('Open Online Players Lobby 🌐', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChessLobbyScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildRanking(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.leaderboard_rounded, color: Colors.amber, size: 22),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Community Leaderboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'Online Ranked 🌐',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Online Multiplayer matches only (Bot/local matches not counted)',
          style: TextStyle(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
              ),
            ],
          ),
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: ChessOnlineService.streamLeaderboard(limit: 5),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.amber, strokeWidth: 2),
                  ),
                );
              }

              final users = snapshot.data ?? [];
              if (users.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(28),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.military_tech_outlined,
                          size: 48,
                          color: Colors.amber.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'No Online Matches Completed Yet',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Challenge other players in Online mode and earn victories to reach the top!',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  ...users.asMap().entries.map((entry) {
                    final rank = entry.key + 1;
                    final user = entry.value;
                    final isLast = rank == users.length;
                    return _buildRealRankingItem(context, rank, user, isLast);
                  }),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                      onTap: () => _showFullLeaderboardSheet(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.08),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                          border: const Border(top: BorderSide(color: Colors.white10)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'View Full Online Community Leaderboard',
                              style: TextStyle(
                                color: Colors.cyanAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded, color: Colors.cyanAccent, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRealRankingItem(BuildContext context, int rank, Map<String, dynamic> user, bool isLast) {
    final username = user['username']?.toString() ?? 'Player';
    final avatar = user['avatar']?.toString();
    final wins = (user['chess_online_wins'] as num?)?.toInt() ?? 0;
    final totalGames = (user['chess_online_games'] as num?)?.toInt() ?? 0;
    final draws = (user['chess_online_draws'] as num?)?.toInt() ?? 0;
    final winRate = (user['chess_online_win_rate'] as num?)?.toDouble() ?? 0.0;
    final title = user['chess_title']?.toString() ?? 'Chess Novice 🌱';

    final isMe = user['id'] == ChessOnlineService.currentUserId;
    final isTop1 = rank == 1;
    final isTop2 = rank == 2;
    final isTop3 = rank == 3;

    Color badgeBgColor;
    Color badgeTextColor;
    String badgeIcon = '';

    if (isTop1) {
      badgeBgColor = const Color(0xFFFFD700);
      badgeTextColor = const Color(0xFF78350F);
      badgeIcon = '👑';
    } else if (isTop2) {
      badgeBgColor = const Color(0xFFE2E8F0);
      badgeTextColor = const Color(0xFF1E293B);
      badgeIcon = '🥈';
    } else if (isTop3) {
      badgeBgColor = const Color(0xFFF97316);
      badgeTextColor = Colors.white;
      badgeIcon = '🥉';
    } else {
      badgeBgColor = Colors.white.withValues(alpha: 0.12);
      badgeTextColor = Colors.white70;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isTop1
            ? Colors.amber.withValues(alpha: 0.08)
            : (isMe ? Colors.blueAccent.withValues(alpha: 0.1) : Colors.transparent),
        border: isLast ? null : const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: badgeBgColor,
              shape: BoxShape.circle,
              boxShadow: isTop1
                  ? [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                rank <= 3 ? badgeIcon : '$rank',
                style: TextStyle(
                  color: badgeTextColor,
                  fontSize: rank <= 3 ? 16 : 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.blueGrey,
            backgroundImage: avatar != null && avatar.isNotEmpty
                ? ImageHelper.getImageProvider(avatar)
                : null,
            child: avatar == null || avatar.isEmpty
                ? Text(
                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // Username & Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        username,
                        style: TextStyle(
                          color: isTop1 ? Colors.amberAccent : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5)),
                        ),
                        child: const Text(
                          'You',
                          style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Total Online Wins & Win Rate
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$wins Wins',
                style: TextStyle(
                  color: isTop1 ? Colors.amber : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                totalGames > 0
                    ? (draws > 0
                        ? '${(wins + (0.5 * draws)).toStringAsFixed(draws % 2 == 0 ? 0 : 1)} Pts • ${winRate.toStringAsFixed(0)}% WR'
                        : '${winRate.toStringAsFixed(0)}% Win Rate')
                    : '0 Matches',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFullLeaderboardSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Colors.amber, width: 2)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sentient Online Leaderboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Top 20 Online Players (Bot & local matches excluded)',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: ChessOnlineService.streamLeaderboard(limit: 20),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.amber));
                  }

                  final users = snapshot.data ?? [];
                  if (users.isEmpty) {
                    return const Center(
                      child: Text('No players registered yet.', style: TextStyle(color: Colors.white60)),
                    );
                  }

                  return ListView.builder(
                    physics: const ClampingScrollPhysics(),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final rank = index + 1;
                      final user = users[index];
                      return _buildRealRankingItem(context, rank, user, index == users.length - 1);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAIDialog(BuildContext context) async {
    final selectedDiff = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1a1a2e),
                Color(0xFF16213e),
                Color(0xFF0f3460),
              ],
            ),
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withValues(alpha: 0.3),
                        Colors.purple.withValues(alpha: 0.2),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.blue, Colors.purple],
                          ),
                          borderRadius: BorderRadius.circular(29),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.4),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.smart_toy,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Select AI Difficulty',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Challenge AI with various difficulty levels',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Difficulty options
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Column(
                    children: [
                      _buildAIOption(dialogCtx, 'Easy', 'Perfect for beginners', Colors.green, 'easy', Icons.sports_esports),
                      const SizedBox(height: 8),
                      _buildAIOption(dialogCtx, 'Medium', 'For casual players', Colors.orange, 'medium', Icons.psychology),
                      const SizedBox(height: 8),
                      _buildAIOption(dialogCtx, 'Hard', 'Challenge yourself', Colors.red, 'hard', Icons.flash_on),
                      const SizedBox(height: 8),
                      _buildAIOption(dialogCtx, 'Grandmaster', 'Defeat the grandmaster', Colors.purple, 'grandmaster', Icons.military_tech),
                    ],
                  ),
                ),
                
                // Close button
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                  child: Container(
                    width: double.infinity,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.pop(dialogCtx, null),
                        child: const Center(
                          child: Text(
                            'Close',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (selectedDiff == null || !context.mounted) return;

    final diffCapitalized = selectedDiff[0].toUpperCase() + selectedDiff.substring(1);
    final chosenTimeSeconds = await ChessTimeControlDialog.show(
      context,
      title: 'VS Bot ($diffCapitalized)',
      subtitle: 'Select time control to play against AI',
      allowUnlimited: true,
      defaultSeconds: 0,
      actionButtonText: 'Start Game 🚀',
    );

    if (chosenTimeSeconds == null || !context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChessGameScreen(
          aiDifficulty: selectedDiff,
          isAIGame: true,
          initialTimeSeconds: chosenTimeSeconds,
        ),
      ),
    );
  }

  Widget _buildAIOption(BuildContext dialogCtx, String level, String description, Color color, String difficulty, IconData icon) {
    return GestureDetector(
      onTap: () => Navigator.pop(dialogCtx, difficulty),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.8),
                    color.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            // Play arrow
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: color,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFriendDialog(BuildContext context) async {
    final shouldProceed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1a1a2e),
                Color(0xFF16213e),
                Color(0xFF0f3460),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withValues(alpha: 0.3),
                      Colors.blue.withValues(alpha: 0.2),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.green, Colors.blue],
                        ),
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.people,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Local Multiplayer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Play with a friend on the same device',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.swap_horiz,
                            size: 48,
                            color: Colors.green.withValues(alpha: 0.8),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Pass & Play',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Take turns making moves with your friend. White player moves first.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Buttons
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 50,
                        margin: const EdgeInsets.only(left: 24, right: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.pop(dialogCtx, false),
                            child: const Center(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 50,
                        margin: const EdgeInsets.only(left: 12, right: 24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.green, Colors.blue],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.pop(dialogCtx, true),
                            child: const Center(
                              child: Text(
                                'Next',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldProceed != true || !context.mounted) return;

    final chosenTimeSeconds = await ChessTimeControlDialog.show(
      context,
      title: 'Pass & Play (vs Friend)',
      subtitle: 'Select time control for local multiplayer',
      allowUnlimited: true,
      defaultSeconds: 0,
      actionButtonText: 'Start Game 🚀',
    );

    if (chosenTimeSeconds == null || !context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChessGameScreen(
          initialTimeSeconds: chosenTimeSeconds,
        ),
      ),
    );
  }
}

