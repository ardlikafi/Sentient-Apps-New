import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentient/core/providers/user_provider.dart';
import 'package:sentient/core/utils/image_helper.dart';
import 'package:sentient/features/chess/models/chess_player_stats.dart';
import 'package:sentient/features/chess/services/chess_stats_service.dart';

class ChessProfileDialog extends StatefulWidget {
  const ChessProfileDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ChessProfileDialog(),
    );
  }

  @override
  State<ChessProfileDialog> createState() => _ChessProfileDialogState();
}

class _ChessProfileDialogState extends State<ChessProfileDialog> {
  ChessPlayerStats? _stats;
  bool _isLoading = true;
  String _selectedScope = 'online'; // 'online', 'offline', 'all'

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final s = await ChessStatsService.getStats();
    if (mounted) {
      setState(() {
        _stats = s;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserProvider>(context).userData;
    final username = currentUser?['username']?.toString() ?? 'Sentient Player';
    final avatarUrl = currentUser?['avatar']?.toString();

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 25,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),

          // Top Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: const Text('👑', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chess Career & Statistics',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        'Online vs Practice Stats (Bot & Friends)',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 24),

          // Body Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                : _stats == null
                    ? const Center(child: Text('Failed to load statistics', style: TextStyle(color: Colors.white70)))
                    : SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Hero Player Card
                            _buildHeroPlayerCard(username, avatarUrl, _stats!),
                            const SizedBox(height: 18),

                            // 2. Online vs Offline Quick Comparison Card
                            _buildComparisonCard(_stats!),
                            const SizedBox(height: 18),

                            // 3. Mode Scope Selector (Online / Latihan / Semua)
                            _buildScopeSelector(),
                            const SizedBox(height: 14),

                            // 4. Win Rate & Match Records (Dinamis berdasarkan mode terpilih)
                            _buildWinRateCard(_stats!),
                            const SizedBox(height: 18),

                            // 5. Gameplay Quality & Analysis Metrics
                            _buildQualityMetricsCard(_stats!),
                            const SizedBox(height: 18),

                            // 6. Highlight & Rekor
                            _buildHighlightRow(_stats!),
                            const SizedBox(height: 22),

                            // 7. Recent Matches Section (Disesuaikan berdasarkan mode terpilih)
                            _buildRecentMatchesSection(_stats!),
                            const SizedBox(height: 18),

                            // 8. Tombol Reset Statistik Testing
                            Center(
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                                  ),
                                ),
                                onPressed: _confirmResetStats,
                                icon: const Icon(Icons.restart_alt_rounded, color: Colors.white70, size: 18),
                                label: const Text(
                                  'Reset Test Statistics (Mulai Ulang dari 0)',
                                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroPlayerCard(String username, String? avatarUrl, ChessPlayerStats stats) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar dengan ring bersinar
          Stack(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Colors.amber, Colors.orangeAccent, Colors.blueAccent],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundImage: ImageHelper.getImageProvider(avatarUrl),
                  backgroundColor: const Color(0xFF1E293B),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🇮🇩', style: TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blueAccent.withValues(alpha: 0.3),
                        Colors.purpleAccent.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    stats.playerTitle,
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.psychology_rounded, size: 14, color: Colors.white60),
                    const SizedBox(width: 4),
                    Text(
                      stats.playstyle,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Kartu perbandingan cepat antara Match Online vs Latihan (Bot / Teman)
  Widget _buildComparisonCard(ChessPlayerStats stats) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.compare_arrows_rounded, color: Colors.cyanAccent, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Match Mode Comparison',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Kolom Online
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🌐', style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 4),
                          const Expanded(
                            child: Text(
                              'Online',
                              style: TextStyle(
                                color: Colors.cyanAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Ranked 🏆',
                                style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${stats.onlineWins} Wins',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${stats.onlineGames} Games • ${stats.onlineWinRate.toStringAsFixed(0)}% WR',
                          style: const TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Kolom Latihan / Bot
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🤖', style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 4),
                          const Expanded(
                            child: Text(
                              'Practice',
                              style: TextStyle(
                                color: Colors.purpleAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Bot / Friends',
                                style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${stats.offlineWins} Wins',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${stats.offlineGames} Games • ${stats.offlineWinRate.toStringAsFixed(0)}% WR',
                          style: const TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Segmented Tab Selector untuk memilih lingkup statistik yang ingin dilihat
  Widget _buildScopeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(child: _buildScopeTab('online', '🌐 Online Ranked')),
          Expanded(child: _buildScopeTab('offline', '🤖 Practice & Bot')),
          Expanded(child: _buildScopeTab('all', '📊 All Modes')),
        ],
      ),
    );
  }

  Widget _buildScopeTab(String scope, String label) {
    final isSelected = _selectedScope == scope;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedScope = scope;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blueAccent.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWinRateCard(ChessPlayerStats stats) {
    final int games;
    final int wins;
    final int draws;
    final int losses;
    final double winRate;
    final String cardTitle;
    final String badgeLabel;
    final Color badgeColor;
    final String subtitle;

    if (_selectedScope == 'online') {
      games = stats.onlineGames;
      wins = stats.onlineWins;
      draws = stats.onlineDraws;
      losses = stats.onlineLosses;
      winRate = stats.onlineWinRate;
      cardTitle = 'Online Match Record';
      badgeLabel = 'Ranked Leaderboard 🌐';
      badgeColor = Colors.cyanAccent;
      subtitle = 'Online Multiplayer Win Rate';
    } else if (_selectedScope == 'offline') {
      games = stats.offlineGames;
      wins = stats.offlineWins;
      draws = stats.offlineDraws;
      losses = stats.offlineLosses;
      winRate = stats.offlineWinRate;
      cardTitle = 'Practice & Bot Record';
      badgeLabel = 'Practice / Unranked 🤖';
      badgeColor = Colors.purpleAccent;
      subtitle = 'Win Rate vs AI Bot & Friends';
    } else {
      games = stats.totalGames;
      wins = stats.wins;
      draws = stats.draws;
      losses = stats.losses;
      winRate = stats.winRate;
      cardTitle = 'All Matches Record';
      badgeLabel = 'Total Cumulative 📊';
      badgeColor = Colors.blueAccent;
      subtitle = 'All Modes Overall Win Rate';
    }

    final winPercent = winRate.toStringAsFixed(1);
    final winRatio = games > 0 ? (wins / games) : 0.0;
    final drawRatio = games > 0 ? (draws / games) : 0.0;
    final lossRatio = games > 0 ? (losses / games) : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  cardTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Win Rate Highlight
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$winPercent%',
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Visual Proportion Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  if (winRatio > 0)
                    Expanded(
                      flex: (winRatio * 1000).toInt(),
                      child: Container(color: Colors.greenAccent),
                    ),
                  if (drawRatio > 0)
                    Expanded(
                      flex: (drawRatio * 1000).toInt(),
                      child: Container(color: Colors.grey),
                    ),
                  if (lossRatio > 0)
                    Expanded(
                      flex: (lossRatio * 1000).toInt(),
                      child: Container(color: Colors.redAccent),
                    ),
                  if (games == 0)
                    Expanded(child: Container(color: Colors.white24)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Details breakdown chips
          Row(
            children: [
              Expanded(
                child: _buildResultChip('Won', '$wins', Colors.greenAccent, Icons.check_circle_rounded),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildResultChip('Draw', '$draws', Colors.white70, Icons.remove_circle_rounded),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildResultChip('Lost', '$losses', Colors.redAccent, Icons.cancel_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultChip(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityMetricsCard(ChessPlayerStats stats) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.insights_rounded, color: Colors.cyanAccent, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Move Quality & Analysis',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Accuracy: ${stats.averageAccuracy.toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Total accumulated moves from analyzed matches:',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 14),

          // 4 Badges Grid
          Row(
            children: [
              Expanded(
                child: _buildMoveBadge('🌟 Brilliant', '${stats.brilliantMoves}', Colors.amber),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMoveBadge('🟢 Good', '${stats.goodMoves}', Colors.greenAccent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMoveBadge('⚪ Normal', '${stats.normalMoves}', Colors.white70),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMoveBadge('🔴 Blunder', '${stats.blunders}', Colors.redAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoveBadge(String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              count,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightRow(ChessPlayerStats stats) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.withValues(alpha: 0.2),
                  const Color(0xFF1E293B),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${stats.currentStreak} Wins',
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Streak (${stats.bestStreak}x)',
                          style: const TextStyle(color: Colors.white60, fontSize: 11),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.withValues(alpha: 0.2),
                  const Color(0xFF1E293B),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Text('⚡', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          stats.fastestMateMoves > 0 ? '${stats.fastestMateMoves} Moves' : '-',
                          style: const TextStyle(
                            color: Colors.purpleAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                        ),
                      ),
                      const FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Fastest Mate',
                          style: TextStyle(color: Colors.white60, fontSize: 11),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentMatchesSection(ChessPlayerStats stats) {
    final filteredMatches = stats.recentMatches.where((m) {
      final isOnline = m.mode.toLowerCase().contains('online');
      if (_selectedScope == 'online') return isOnline;
      if (_selectedScope == 'offline') return !isOnline;
      return true;
    }).toList();

    String sectionSubtitle;
    if (_selectedScope == 'online') {
      sectionSubtitle = 'Online match history only';
    } else if (_selectedScope == 'offline') {
      sectionSubtitle = 'Practice & bot match history';
    } else {
      sectionSubtitle = 'All match history';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Match History',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    sectionSubtitle,
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.history_rounded, color: Colors.white60, size: 20),
          ],
        ),
        const SizedBox(height: 12),

        if (filteredMatches.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                Icon(
                  _selectedScope == 'online'
                      ? Icons.public_off_rounded
                      : (_selectedScope == 'offline' ? Icons.smart_toy_outlined : Icons.inbox_rounded),
                  size: 36,
                  color: Colors.white38,
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedScope == 'online'
                      ? 'No online match history yet.'
                      : (_selectedScope == 'offline'
                          ? 'No practice / bot match history yet.'
                          : 'No match history yet.'),
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                if (_selectedScope == 'online') ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Play online matches to record your rank on the leaderboard!',
                    style: TextStyle(color: Colors.cyanAccent, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          )
        else
          ...filteredMatches.map((m) => _buildMatchCard(m)),
      ],
    );
  }

  void _confirmResetStats() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2638),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Chess Statistics?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'This action will clear all trial match history, online wins, draws, and leaderboard data back to 0.\n\nAre you sure you want to reset?',
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              await ChessStatsService.resetStats();
              await _loadStats();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chess statistics successfully reset to 0!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Yes, Reset to 0', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(ChessMatchRecord match) {
    final isWin = match.result == 'win';
    final isDraw = match.result == 'draw';
    final badgeColor = isWin ? Colors.greenAccent : (isDraw ? Colors.white70 : Colors.redAccent);
    final badgeText = isWin ? 'WIN' : (isDraw ? 'DRAW' : 'LOSS');
    final isOnlineMatch = match.mode.toLowerCase().contains('online');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOnlineMatch
              ? Colors.cyanAccent.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          // Icon result
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isWin ? Icons.emoji_events_rounded : (isDraw ? Icons.handshake_rounded : Icons.close_rounded),
              color: badgeColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Match details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        match.opponent,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      match.date,
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    // Mode Tag (Online vs Latihan)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isOnlineMatch
                              ? Colors.blueAccent.withValues(alpha: 0.18)
                              : Colors.purpleAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isOnlineMatch
                                ? Colors.cyanAccent.withValues(alpha: 0.4)
                                : Colors.purpleAccent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          isOnlineMatch ? '🌐 Online' : '🤖 Practice',
                          style: TextStyle(
                            color: isOnlineMatch ? Colors.cyanAccent : Colors.purpleAccent,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${match.movesCount} moves',
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${match.accuracy.toStringAsFixed(1)}% Accuracy',
                          style: const TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
