import 'package:flutter/material.dart';
import 'package:sentient/features/chess/models/chess_time_control.dart';

class ChessTimeControlDialog extends StatefulWidget {
  final String title;
  final String? subtitle;
  final bool allowUnlimited;
  final int defaultSeconds;
  final String actionButtonText;

  const ChessTimeControlDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.allowUnlimited = false,
    this.defaultSeconds = 600,
    this.actionButtonText = 'Start Game 🚀',
  });

  static Future<int?> show(
    BuildContext context, {
    required String title,
    String? subtitle,
    bool allowUnlimited = false,
    int defaultSeconds = 600,
    String actionButtonText = 'Start Game 🚀',
  }) {
    return showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => ChessTimeControlDialog(
        title: title,
        subtitle: subtitle,
        allowUnlimited: allowUnlimited,
        defaultSeconds: defaultSeconds,
        actionButtonText: actionButtonText,
      ),
    );
  }

  @override
  State<ChessTimeControlDialog> createState() => _ChessTimeControlDialogState();
}

class _ChessTimeControlDialogState extends State<ChessTimeControlDialog> {
  late int _selectedSeconds;
  late List<ChessTimeControl> _options;

  @override
  void initState() {
    super.initState();
    _options = ChessTimeControl.getOptions(allowUnlimited: widget.allowUnlimited);
    _selectedSeconds = widget.defaultSeconds;

    final exists = _options.any((o) => o.seconds == _selectedSeconds);
    if (!exists && _options.isNotEmpty) {
      _selectedSeconds = _options.first.seconds;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Casual':
        return Colors.tealAccent;
      case 'Bullet':
        return Colors.amberAccent;
      case 'Blitz':
        return Colors.orangeAccent;
      case 'Rapid':
        return const Color(0xFF10B981); // Emerald
      case 'Classical':
        return Colors.cyanAccent;
      default:
        return Colors.blueAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E2638),
              Color(0xFF0F172A),
              Color(0xFF161F30),
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF10B981)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.timer_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle ?? 'Select chess time control format',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white10, height: 1),

            // Time Options List / Grid
            Flexible(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Unlimited option for Bot & Friend Local
                    if (widget.allowUnlimited) ...[
                      _buildUnlimitedCard(),
                      const SizedBox(height: 12),
                    ],

                    // Standard Options Header
                    Row(
                      children: [
                        Icon(Icons.bolt_rounded, size: 14, color: Colors.amberAccent.withValues(alpha: 0.8)),
                        const SizedBox(width: 4),
                        Text(
                          'STANDARD TIME (FIDE / CHESS.COM)',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    ...ChessTimeControl.standardOptions.map((opt) => _buildOptionTile(opt)),
                  ],
                ),
              ),
            ),

            const Divider(color: Colors.white10, height: 1),

            // Actions Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context, null),
                      child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context, _selectedSeconds),
                      child: Text(
                        widget.actionButtonText,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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

  Widget _buildUnlimitedCard() {
    final opt = ChessTimeControl.unlimited;
    final isSelected = _selectedSeconds == 0;
    final categoryColor = _getCategoryColor(opt.category);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        setState(() {
          _selectedSeconds = 0;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? categoryColor.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? categoryColor : Colors.white12,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: categoryColor.withValues(alpha: 0.25),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(opt.icon, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        opt.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          opt.category,
                          style: TextStyle(
                            color: categoryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    opt.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isSelected ? categoryColor : Colors.white24,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(ChessTimeControl opt) {
    final isSelected = _selectedSeconds == opt.seconds;
    final categoryColor = _getCategoryColor(opt.category);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _selectedSeconds = opt.seconds;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? categoryColor.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? categoryColor : Colors.white12,
              width: isSelected ? 1.8 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: categoryColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Text(opt.icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          opt.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: categoryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            opt.category,
                            style: TextStyle(
                              color: categoryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (opt.seconds == 600) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text(
                              '★ Popular',
                              style: TextStyle(
                                color: Colors.amberAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      opt.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: isSelected ? categoryColor : Colors.white24,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
