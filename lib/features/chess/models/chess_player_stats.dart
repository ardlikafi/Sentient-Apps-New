class ChessMatchRecord {
  final String id;
  final String opponent;
  final String result; // 'win', 'loss', 'draw'
  final int movesCount;
  final double accuracy;
  final String date;
  final String mode; // 'vs Bot (Med)', 'vs Friend', 'Online', etc.

  ChessMatchRecord({
    required this.id,
    required this.opponent,
    required this.result,
    required this.movesCount,
    required this.accuracy,
    required this.date,
    required this.mode,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'opponent': opponent,
      'result': result,
      'movesCount': movesCount,
      'accuracy': accuracy,
      'date': date,
      'mode': mode,
    };
  }

  factory ChessMatchRecord.fromMap(Map<String, dynamic> map) {
    return ChessMatchRecord(
      id: map['id']?.toString() ?? '',
      opponent: map['opponent']?.toString() ?? 'Opponent',
      result: map['result']?.toString() ?? 'draw',
      movesCount: (map['movesCount'] is num) ? (map['movesCount'] as num).toInt() : 0,
      accuracy: (map['accuracy'] is num) ? (map['accuracy'] as num).toDouble() : 75.0,
      date: map['date']?.toString() ?? '',
      mode: map['mode']?.toString() ?? 'vs Bot',
    );
  }
}

class ChessPlayerStats {
  final int totalGames;
  final int wins;
  final int losses;
  final int draws;
  final int currentStreak;
  final int bestStreak;
  final double averageAccuracy;
  final int brilliantMoves;
  final int goodMoves;
  final int normalMoves;
  final int blunders;
  final int fastestMateMoves;
  final List<ChessMatchRecord> recentMatches;

  // Breakdown Khusus Online (Untuk Papan Peringkat)
  final int onlineGames;
  final int onlineWins;
  final int onlineLosses;
  final int onlineDraws;

  // Breakdown Khusus Offline (Latihan Bot & Teman Lokal)
  final int offlineGames;
  final int offlineWins;
  final int offlineLosses;
  final int offlineDraws;

  ChessPlayerStats({
    required this.totalGames,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.currentStreak,
    required this.bestStreak,
    required this.averageAccuracy,
    required this.brilliantMoves,
    required this.goodMoves,
    required this.normalMoves,
    required this.blunders,
    required this.fastestMateMoves,
    required this.recentMatches,
    this.onlineGames = 0,
    this.onlineWins = 0,
    this.onlineLosses = 0,
    this.onlineDraws = 0,
    this.offlineGames = 0,
    this.offlineWins = 0,
    this.offlineLosses = 0,
    this.offlineDraws = 0,
  });

  double get winRate => totalGames > 0 ? (wins / totalGames) * 100 : 0.0;
  double get onlineWinRate => onlineGames > 0 ? (onlineWins / onlineGames) * 100 : 0.0;
  double get offlineWinRate => offlineGames > 0 ? (offlineWins / offlineGames) * 100 : 0.0;

  String get playerTitle {
    if (onlineGames >= 5) {
      if (onlineWinRate >= 75 && onlineGames >= 15) return 'Online Grandmaster 👑';
      if (onlineWinRate >= 60 && onlineGames >= 10) return 'Online Master ⚔️';
      if (onlineWins >= 5) return 'Skilled Online Player 🌐';
    }
    if (totalGames == 0) return 'Chess Novice 🌱';
    if (winRate >= 75 && totalGames >= 10) return 'Sentient Grandmaster 👑';
    if (winRate >= 60 && totalGames >= 5) return 'Tactical Master ⚔️';
    if (totalGames >= 5) return 'Candidate Master 🛡️';
    return 'Talented Tactician 🌟';
  }

  String get playstyle {
    if (totalGames == 0) return 'No Style Detected Yet';
    if (brilliantMoves > 5) return 'Aggressive & Spectacular ⚡';
    if (blunders <= 2 && totalGames >= 3) return 'Solid & Defensive 🛡️';
    if (goodMoves > normalMoves) return 'Positional Control 🎯';
    return 'Dynamic & Flexible ♟️';
  }

  Map<String, dynamic> toMap() {
    return {
      'totalGames': totalGames,
      'wins': wins,
      'losses': losses,
      'draws': draws,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'averageAccuracy': averageAccuracy,
      'brilliantMoves': brilliantMoves,
      'goodMoves': goodMoves,
      'normalMoves': normalMoves,
      'blunders': blunders,
      'fastestMateMoves': fastestMateMoves,
      'recentMatches': recentMatches.map((m) => m.toMap()).toList(),
      'onlineGames': onlineGames,
      'onlineWins': onlineWins,
      'onlineLosses': onlineLosses,
      'onlineDraws': onlineDraws,
      'offlineGames': offlineGames,
      'offlineWins': offlineWins,
      'offlineLosses': offlineLosses,
      'offlineDraws': offlineDraws,
    };
  }

  factory ChessPlayerStats.fromMap(Map<String, dynamic> map) {
    return ChessPlayerStats(
      totalGames: (map['totalGames'] as num?)?.toInt() ?? 0,
      wins: (map['wins'] as num?)?.toInt() ?? 0,
      losses: (map['losses'] as num?)?.toInt() ?? 0,
      draws: (map['draws'] as num?)?.toInt() ?? 0,
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      bestStreak: (map['bestStreak'] as num?)?.toInt() ?? 0,
      averageAccuracy: (map['averageAccuracy'] as num?)?.toDouble() ?? 0.0,
      brilliantMoves: (map['brilliantMoves'] as num?)?.toInt() ?? 0,
      goodMoves: (map['goodMoves'] as num?)?.toInt() ?? 0,
      normalMoves: (map['normalMoves'] as num?)?.toInt() ?? 0,
      blunders: (map['blunders'] as num?)?.toInt() ?? 0,
      fastestMateMoves: (map['fastestMateMoves'] as num?)?.toInt() ?? 0,
      recentMatches: (map['recentMatches'] as List<dynamic>?)
              ?.map((item) => ChessMatchRecord.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      onlineGames: (map['onlineGames'] as num?)?.toInt() ?? 0,
      onlineWins: (map['onlineWins'] as num?)?.toInt() ?? 0,
      onlineLosses: (map['onlineLosses'] as num?)?.toInt() ?? 0,
      onlineDraws: (map['onlineDraws'] as num?)?.toInt() ?? 0,
      offlineGames: (map['offlineGames'] as num?)?.toInt() ?? 0,
      offlineWins: (map['offlineWins'] as num?)?.toInt() ?? 0,
      offlineLosses: (map['offlineLosses'] as num?)?.toInt() ?? 0,
      offlineDraws: (map['offlineDraws'] as num?)?.toInt() ?? 0,
    );
  }

  static ChessPlayerStats starterDefault() {
    return ChessPlayerStats(
      totalGames: 0,
      wins: 0,
      losses: 0,
      draws: 0,
      currentStreak: 0,
      bestStreak: 0,
      averageAccuracy: 0.0,
      brilliantMoves: 0,
      goodMoves: 0,
      normalMoves: 0,
      blunders: 0,
      fastestMateMoves: 0,
      recentMatches: [],
      onlineGames: 0,
      onlineWins: 0,
      onlineLosses: 0,
      onlineDraws: 0,
      offlineGames: 0,
      offlineWins: 0,
      offlineLosses: 0,
      offlineDraws: 0,
    );
  }
}
