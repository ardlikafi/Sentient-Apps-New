class ChessTimeControl {
  final String label;
  final String category; // Bullet, Blitz, Rapid, Classical, Casual
  final int seconds; // 0 means Unlimited / No Timer
  final String icon;
  final String description;

  const ChessTimeControl({
    required this.label,
    required this.category,
    required this.seconds,
    required this.icon,
    required this.description,
  });

  bool get isUnlimited => seconds <= 0;

  static const ChessTimeControl unlimited = ChessTimeControl(
    label: 'No Timer',
    category: 'Casual',
    seconds: 0,
    icon: '♾️',
    description: 'Casual play without any time pressure',
  );

  static const List<ChessTimeControl> standardOptions = [
    ChessTimeControl(
      label: '1 Min',
      category: 'Bullet',
      seconds: 60,
      icon: '⚡',
      description: 'Ultra fast, high adrenaline',
    ),
    ChessTimeControl(
      label: '2 Min',
      category: 'Bullet',
      seconds: 120,
      icon: '⚡',
      description: 'Fast & instant tactical play',
    ),
    ChessTimeControl(
      label: '3 Min',
      category: 'Blitz',
      seconds: 180,
      icon: '🔥',
      description: 'Popular blitz for quick action',
    ),
    ChessTimeControl(
      label: '5 Min',
      category: 'Blitz',
      seconds: 300,
      icon: '🔥',
      description: 'Standard competitive blitz',
    ),
    ChessTimeControl(
      label: '10 Min',
      category: 'Rapid',
      seconds: 600,
      icon: '⏱️',
      description: 'Most popular Rapid on Chess.com',
    ),
    ChessTimeControl(
      label: '15 Min',
      category: 'Rapid',
      seconds: 900,
      icon: '⏱️',
      description: 'Official FIDE Rapid tournament time',
    ),
    ChessTimeControl(
      label: '30 Min',
      category: 'Classical',
      seconds: 1800,
      icon: '⏳',
      description: 'Long game for deep positional thinking',
    ),
  ];

  static List<ChessTimeControl> getOptions({bool allowUnlimited = false}) {
    if (allowUnlimited) {
      return [unlimited, ...standardOptions];
    }
    return standardOptions;
  }

  static String formatSummary(int seconds) {
    if (seconds <= 0) return 'No Timer (Casual)';
    final minutes = seconds ~/ 60;
    if (minutes < 3) return '$minutes Min (Bullet)';
    if (minutes <= 5) return '$minutes Min (Blitz)';
    if (minutes <= 15) return '$minutes Min (Rapid)';
    return '$minutes Min (Classical)';
  }
}
