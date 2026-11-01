enum MoveQuality {
  brilliant,
  good,
  normal,
  blunder,
}

class AnalyzedMove {
  final int moveIndex; // 0-indexed sequence
  final int moveNumber; // 1, 2, 3...
  final String player; // 'white' or 'black'
  final String playerName;
  final String notation;
  final String piece;
  final int fromRow;
  final int fromCol;
  final int toRow;
  final int toCol;
  final String? capturedPiece;
  final MoveQuality quality;
  final String title;
  final String explanation;
  final List<List<String>> boardAfter;
  final bool isCheck;
  final bool isCheckmate;

  const AnalyzedMove({
    required this.moveIndex,
    required this.moveNumber,
    required this.player,
    required this.playerName,
    required this.notation,
    required this.piece,
    required this.fromRow,
    required this.fromCol,
    required this.toRow,
    required this.toCol,
    this.capturedPiece,
    required this.quality,
    required this.title,
    required this.explanation,
    required this.boardAfter,
    this.isCheck = false,
    this.isCheckmate = false,
  });

  bool get isWhiteMove => player == 'white';
}

class GameAnalysisReport {
  final List<AnalyzedMove> moves;
  final double whiteAccuracy;
  final double blackAccuracy;
  final int whiteBrilliant;
  final int whiteGood;
  final int whiteNormal;
  final int whiteBlunder;
  final int blackBrilliant;
  final int blackGood;
  final int blackNormal;
  final int blackBlunder;
  final String overallSummary;

  const GameAnalysisReport({
    required this.moves,
    required this.whiteAccuracy,
    required this.blackAccuracy,
    required this.whiteBrilliant,
    required this.whiteGood,
    required this.whiteNormal,
    required this.whiteBlunder,
    required this.blackBrilliant,
    required this.blackGood,
    required this.blackNormal,
    required this.blackBlunder,
    required this.overallSummary,
  });

  static GameAnalysisReport analyzeGame({
    required List<Map<String, dynamic>> recordedMoves,
    required String whitePlayerName,
    required String blackPlayerName,
    required String? winner,
  }) {
    final analyzedMoves = <AnalyzedMove>[];

    int wBrilliant = 0, wGood = 0, wNormal = 0, wBlunder = 0;
    int bBrilliant = 0, bGood = 0, bNormal = 0, bBlunder = 0;

    for (int i = 0; i < recordedMoves.length; i++) {
      final m = recordedMoves[i];
      final player = m['player']?.toString() ?? (i % 2 == 0 ? 'white' : 'black');
      final isWhite = player == 'white';
      final playerName = isWhite ? whitePlayerName : blackPlayerName;

      final notation = m['notation']?.toString() ?? '';
      final piece = m['piece']?.toString() ?? '';
      final fromRow = m['fromRow'] as int? ?? 0;
      final fromCol = m['fromCol'] as int? ?? 0;
      final toRow = m['toRow'] as int? ?? 0;
      final toCol = m['toCol'] as int? ?? 0;
      final captured = m['captured']?.toString();
      final isCheck = m['isCheck'] == true || notation.contains('+');
      final isCheckmate = m['isCheckmate'] == true || notation.contains('#');
      final boardAfter = (m['boardAfter'] as List<dynamic>?)
              ?.map((r) => (r as List<dynamic>).map((c) => c.toString()).toList())
              .toList() ??
          [];

      MoveQuality quality = MoveQuality.normal;
      String title = 'Standard Move';
      String explanation = 'Standard move: Maintains positional structure and solidifies squares.';

      final pVal = _getPieceValue(piece);
      final cVal = _getPieceValue(captured ?? '');

      // 1. Checkmate = Brilliant
      if (isCheckmate) {
        quality = MoveQuality.brilliant;
        title = '🌟 Brilliant Move!';
        explanation = 'Outstanding move! Secures victory with an unavoidable checkmate.';
      }
      // 2. Hanging piece / Blunder check
      else if (pVal >= 3 && _isSquareAttackedByLowerOrEqual(toRow, toCol, !isWhite, boardAfter) && !_isSquareProtected(toRow, toCol, isWhite, boardAfter)) {
        quality = MoveQuality.blunder;
        title = '🔴 Blunder!';
        explanation = 'The ${_getPieceName(piece)} was placed on a square where the opponent can capture it for free without protection!';
      }
      // 3. Capturing valuable piece
      else if (captured != null && captured.isNotEmpty && cVal >= 3) {
        if (cVal >= pVal) {
          quality = MoveQuality.good;
          title = '🟢 Great Move!';
          explanation = 'Captures opponent\'s ${_getPieceName(captured)} and secures material advantage.';
        } else {
          quality = MoveQuality.normal;
          title = '⚪ Piece Exchange';
          explanation = 'Material exchange with opponent\'s ${_getPieceName(captured)}.';
        }
      }
      // 4. Checking enemy king
      else if (isCheck) {
        quality = MoveQuality.good;
        title = '🟢 Accurate Move!';
        explanation = 'Delivers check to the enemy king and seizes offensive tempo.';
      }
      // 5. Opening development (moves <= 10)
      else if (i < 10 && (piece == '♘' || piece == '♞' || piece == '♗' || piece == '♝' || piece == '♙' || piece == '♟')) {
        final isCenter = (toRow >= 2 && toRow <= 5) && (toCol >= 2 && toCol <= 5);
        if (isCenter) {
          quality = MoveQuality.good;
          title = '🟢 Good Development!';
          explanation = 'Develops the ${_getPieceName(piece)} to an active square controlling the center.';
        } else {
          quality = MoveQuality.normal;
          title = '⚪ Standard Move';
          explanation = 'Solid opening move to coordinate pieces.';
        }
      }
      // 6. Pawn promotion
      else if ((piece == '♙' && toRow == 0) || (piece == '♟' && toRow == 7)) {
        quality = MoveQuality.good;
        title = '🟢 Pawn Promotion!';
        explanation = 'Pawn reaches the back rank and promotes into a powerful piece.';
      }

      // Hitung statistik
      if (isWhite) {
        switch (quality) {
          case MoveQuality.brilliant:
            wBrilliant++;
            break;
          case MoveQuality.good:
            wGood++;
            break;
          case MoveQuality.normal:
            wNormal++;
            break;
          case MoveQuality.blunder:
            wBlunder++;
            break;
        }
      } else {
        switch (quality) {
          case MoveQuality.brilliant:
            bBrilliant++;
            break;
          case MoveQuality.good:
            bGood++;
            break;
          case MoveQuality.normal:
            bNormal++;
            break;
          case MoveQuality.blunder:
            bBlunder++;
            break;
        }
      }

      analyzedMoves.add(
        AnalyzedMove(
          moveIndex: i,
          moveNumber: (i ~/ 2) + 1,
          player: player,
          playerName: playerName,
          notation: notation,
          piece: piece,
          fromRow: fromRow,
          fromCol: fromCol,
          toRow: toRow,
          toCol: toCol,
          capturedPiece: captured,
          quality: quality,
          title: title,
          explanation: explanation,
          boardAfter: boardAfter,
          isCheck: isCheck,
          isCheckmate: isCheckmate,
        ),
      );
    }

    // Hitung persentase akurasi
    final totalW = (wBrilliant + wGood + wNormal + wBlunder);
    final totalB = (bBrilliant + bGood + bNormal + bBlunder);

    double wAcc = 85.0;
    if (totalW > 0) {
      wAcc = 100.0 - (wBlunder * 18.0) + (wBrilliant * 5.0) + (wGood * 2.0) - (wNormal * 1.5);
      wAcc = wAcc.clamp(25.0, 98.5);
    }

    double bAcc = 82.0;
    if (totalB > 0) {
      bAcc = 100.0 - (bBlunder * 18.0) + (bBrilliant * 5.0) + (bGood * 2.0) - (bNormal * 1.5);
      bAcc = bAcc.clamp(25.0, 98.5);
    }

    // Ringkasan umum pelatih (Coach Note)
    String summary;
    if (wBlunder == 0 && bBlunder == 0) {
      summary = 'A clean and disciplined match! Both sides played solid chess without committing fatal blunders.';
    } else if (winner == 'white') {
      summary = 'Impressive victory for White ($whitePlayerName)! Capitalized on tactical moments with ${wAcc.toStringAsFixed(1)}% accuracy and punished weaknesses.';
    } else if (winner == 'black') {
      summary = 'Strategic victory for Black ($blackPlayerName)! Converted advantages with ${bAcc.toStringAsFixed(1)}% accuracy and capitalized on counterplay.';
    } else {
      summary = 'A hard-fought draw! Dynamic trades and tactical battles across the board.';
    }

    return GameAnalysisReport(
      moves: analyzedMoves,
      whiteAccuracy: wAcc,
      blackAccuracy: bAcc,
      whiteBrilliant: wBrilliant,
      whiteGood: wGood,
      whiteNormal: wNormal,
      whiteBlunder: wBlunder,
      blackBrilliant: bBrilliant,
      blackGood: bGood,
      blackNormal: bNormal,
      blackBlunder: bBlunder,
      overallSummary: summary,
    );
  }

  static int _getPieceValue(String piece) {
    if (piece.isEmpty) return 0;
    switch (piece) {
      case '♙':
      case '♟':
        return 1;
      case '♘':
      case '♞':
      case '♗':
      case '♝':
        return 3;
      case '♖':
      case '♜':
        return 5;
      case '♕':
      case '♛':
        return 9;
      case '♔':
      case '♚':
        return 1000;
      default:
        return 1;
    }
  }

  static String _getPieceName(String piece) {
    switch (piece) {
      case '♙':
      case '♟':
        return 'Pawn';
      case '♘':
      case '♞':
        return 'Knight';
      case '♗':
      case '♝':
        return 'Bishop';
      case '♖':
      case '♜':
        return 'Rook';
      case '♕':
      case '♛':
        return 'Queen';
      case '♔':
      case '♚':
        return 'King';
      default:
        return 'Piece';
    }
  }

  static bool _isSquareAttackedByLowerOrEqual(int row, int col, bool byWhite, List<List<String>> board) {
    if (board.isEmpty || row < 0 || row > 7 || col < 0 || col > 7) return false;
    // Cek serangan pion lawan terdekat
    final pawnRow = byWhite ? row + 1 : row - 1;
    if (pawnRow >= 0 && pawnRow <= 7) {
      for (final pCol in [col - 1, col + 1]) {
        if (pCol >= 0 && pCol <= 7) {
          final piece = board[pawnRow][pCol];
          if (piece == (byWhite ? '♙' : '♟')) return true;
        }
      }
    }
    // Cek serangan kuda
    final knightMoves = [
      [-2, -1], [-2, 1], [-1, -2], [-1, 2],
      [1, -2], [1, 2], [2, -1], [2, 1]
    ];
    for (final km in knightMoves) {
      final r = row + km[0];
      final c = col + km[1];
      if (r >= 0 && r <= 7 && c >= 0 && c <= 7) {
        final piece = board[r][c];
        if (piece == (byWhite ? '♘' : '♞')) return true;
      }
    }
    return false;
  }

  static bool _isSquareProtected(int row, int col, bool byWhite, List<List<String>> board) {
    if (board.isEmpty || row < 0 || row > 7 || col < 0 || col > 7) return false;
    // Cek pelindung pion
    final defPawnRow = byWhite ? row + 1 : row - 1;
    if (defPawnRow >= 0 && defPawnRow <= 7) {
      for (final pCol in [col - 1, col + 1]) {
        if (pCol >= 0 && pCol <= 7) {
          final piece = board[defPawnRow][pCol];
          if (piece == (byWhite ? '♙' : '♟')) return true;
        }
      }
    }
    return false;
  }
}
