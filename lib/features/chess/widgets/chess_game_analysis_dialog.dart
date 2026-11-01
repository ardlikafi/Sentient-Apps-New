import 'package:flutter/material.dart';
import 'package:sentient/features/chess/models/chess_game_analysis.dart';
import 'package:sentient/features/chess/widgets/chess_piece_widget.dart';

class ChessGameAnalysisDialog extends StatefulWidget {
  final GameAnalysisReport report;
  final String whitePlayerName;
  final String blackPlayerName;

  const ChessGameAnalysisDialog({
    super.key,
    required this.report,
    required this.whitePlayerName,
    required this.blackPlayerName,
  });

  @override
  State<ChessGameAnalysisDialog> createState() => _ChessGameAnalysisDialogState();
}

class _ChessGameAnalysisDialogState extends State<ChessGameAnalysisDialog> {
  int _currentMoveIndex = 0;
  String _filterType = 'all'; // 'all', 'blunder', 'good'

  @override
  void initState() {
    super.initState();
    if (widget.report.moves.isNotEmpty) {
      _currentMoveIndex = 0;
    }
  }

  Color _getQualityColor(MoveQuality q) {
    switch (q) {
      case MoveQuality.brilliant:
        return const Color(0xFFF59E0B); // Gold / Amber
      case MoveQuality.good:
        return const Color(0xFF10B981); // Emerald Green
      case MoveQuality.normal:
        return const Color(0xFF3B82F6); // Blue
      case MoveQuality.blunder:
        return const Color(0xFFEF4444); // Red
    }
  }

  IconData _getQualityIcon(MoveQuality q) {
    switch (q) {
      case MoveQuality.brilliant:
        return Icons.auto_awesome;
      case MoveQuality.good:
        return Icons.check_circle_rounded;
      case MoveQuality.normal:
        return Icons.arrow_forward_rounded;
      case MoveQuality.blunder:
        return Icons.warning_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final moves = report.moves;
    final currentMove = (moves.isNotEmpty && _currentMoveIndex < moves.length)
        ? moves[_currentMoveIndex]
        : null;

    final filteredMoves = moves.where((m) {
      if (_filterType == 'blunder') return m.quality == MoveQuality.blunder;
      if (_filterType == 'good') {
        return m.quality == MoveQuality.good || m.quality == MoveQuality.brilliant;
      }
      return true;
    }).toList();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 820),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withValues(alpha: 0.2),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            _buildDialogHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAccuracyHeader(report),
                    const SizedBox(height: 12),
                    _buildCoachSummaryCard(report),
                    const SizedBox(height: 16),
                    if (currentMove != null) ...[
                      _buildMiniBoard(currentMove),
                      const SizedBox(height: 12),
                      _buildCurrentMoveCard(currentMove),
                      const SizedBox(height: 12),
                      _buildStepNavigator(moves.length),
                    ],
                    const SizedBox(height: 18),
                    _buildFilterTabs(moves),
                    const SizedBox(height: 10),
                    _buildMoveList(filteredMoves),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.insights_rounded, color: Colors.blueAccent, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chess Game Analysis',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Review accuracy, best moves, and blunders',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
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
    );
  }

  Widget _buildAccuracyHeader(GameAnalysisReport report) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2638),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          // Putih
          Expanded(
            child: Column(
              children: [
                Text(
                  widget.whitePlayerName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '${report.whiteAccuracy.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                const Text('White Accuracy', style: TextStyle(color: Colors.white54, fontSize: 10)),
                const SizedBox(height: 8),
                _buildMiniBadges(
                  brilliant: report.whiteBrilliant,
                  good: report.whiteGood,
                  normal: report.whiteNormal,
                  blunder: report.whiteBlunder,
                ),
              ],
            ),
          ),
          Container(width: 1, height: 75, color: Colors.white12),
          // Hitam
          Expanded(
            child: Column(
              children: [
                Text(
                  widget.blackPlayerName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '${report.blackAccuracy.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                const Text('Black Accuracy', style: TextStyle(color: Colors.white54, fontSize: 10)),
                const SizedBox(height: 8),
                _buildMiniBadges(
                  brilliant: report.blackBrilliant,
                  good: report.blackGood,
                  normal: report.blackNormal,
                  blunder: report.blackBlunder,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadges({
    required int brilliant,
    required int good,
    required int normal,
    required int blunder,
  }) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 3,
      runSpacing: 3,
      children: [
        if (brilliant > 0)
          _badgeItem('🌟', brilliant, const Color(0xFFF59E0B)),
        _badgeItem('🟢', good, const Color(0xFF10B981)),
        _badgeItem('⚪', normal, Colors.white60),
        _badgeItem('🔴', blunder, const Color(0xFFEF4444)),
      ],
    );
  }

  Widget _badgeItem(String icon, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        '$icon $count',
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCoachSummaryCard(GameAnalysisReport report) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.psychology_rounded, color: Colors.blueAccent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              report.overallSummary,
              style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBoard(AnalyzedMove move) {
    final b = move.boardAfter;
    if (b.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final boardSize = (screenWidth * 0.68).clamp(210.0, 260.0);

    return Center(
      child: Container(
        width: boardSize,
        height: boardSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 15,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
          itemCount: 64,
          itemBuilder: (context, idx) {
            final r = idx ~/ 8;
            final c = idx % 8;
            final isLight = (r + c) % 2 == 0;
            final piece = (r < b.length && c < b[r].length) ? b[r][c] : '';

            final isFromSquare = r == move.fromRow && c == move.fromCol;
            final isToSquare = r == move.toRow && c == move.toCol;
            final qualityColor = _getQualityColor(move.quality);

            Color squareColor = isLight ? const Color(0xFFF0D9B5) : const Color(0xFFB58863);

            if (isToSquare) {
              squareColor = qualityColor.withValues(alpha: 0.65);
            } else if (isFromSquare) {
              squareColor = qualityColor.withValues(alpha: 0.35);
            }

            return Container(
              color: squareColor,
              child: Center(
                child: piece.isNotEmpty
                    ? ChessPieceWidget(piece: piece, size: 24)
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCurrentMoveCard(AnalyzedMove move) {
    final color = _getQualityColor(move.quality);
    final icon = _getQualityIcon(move.quality);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  move.title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${move.moveNumber}. ${move.notation}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            move.explanation,
            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildStepNavigator(int totalMoves) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.first_page_rounded, color: Colors.white70),
            tooltip: 'First Move',
            onPressed: _currentMoveIndex > 0
                ? () => setState(() => _currentMoveIndex = 0)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28),
            tooltip: 'Previous Move',
            onPressed: _currentMoveIndex > 0
                ? () => setState(() => _currentMoveIndex--)
                : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Move ${_currentMoveIndex + 1} / $totalMoves',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 28),
            tooltip: 'Next Move',
            onPressed: _currentMoveIndex < totalMoves - 1
                ? () => setState(() => _currentMoveIndex++)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.last_page_rounded, color: Colors.white70),
            tooltip: 'Last Move',
            onPressed: _currentMoveIndex < totalMoves - 1
                ? () => setState(() => _currentMoveIndex = totalMoves - 1)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(List<AnalyzedMove> moves) {
    final blunderCount = moves.where((m) => m.quality == MoveQuality.blunder).length;
    final goodCount = moves.where((m) => m.quality == MoveQuality.good || m.quality == MoveQuality.brilliant).length;

    return Row(
      children: [
        _tabButton('all', 'All (${moves.length})', Colors.blueAccent),
        const SizedBox(width: 8),
        _tabButton('blunder', 'Blunders ($blunderCount) 🔴', const Color(0xFFEF4444)),
        const SizedBox(width: 8),
        _tabButton('good', 'Good ($goodCount) 🟢', const Color(0xFF10B981)),
      ],
    );
  }

  Widget _tabButton(String key, String label, Color color) {
    final isSelected = _filterType == key;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _filterType = key),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : Colors.white12,
              width: 1.2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoveList(List<AnalyzedMove> moves) {
    if (moves.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No moves in this category.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: moves.length,
      itemBuilder: (context, index) {
        final m = moves[index];
        final isSelected = m.moveIndex == _currentMoveIndex;
        final color = _getQualityColor(m.quality);

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.2) : const Color(0xFF1E2638),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.white12,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: color.withValues(alpha: 0.2),
              child: Icon(_getQualityIcon(m.quality), size: 14, color: color),
            ),
            title: Row(
              children: [
                Text(
                  '${m.moveNumber}. ${m.notation}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '(${m.playerName})',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            subtitle: Text(
              m.explanation,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontSize: 11),
            ),
            trailing: isSelected
                ? Icon(Icons.visibility_rounded, color: color, size: 18)
                : const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 12),
            onTap: () {
              setState(() {
                _currentMoveIndex = m.moveIndex;
              });
            },
          ),
        );
      },
    );
  }
}
