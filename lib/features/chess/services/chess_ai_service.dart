import 'dart:math';

/// High-performance Chess AI Service.
/// Designed to run inside background worker isolates via `compute()`
/// so the main Flutter UI thread never freezes, animations stay 60/120fps,
/// and chess clocks decrement smoothly in real time.
class ChessAIService {
  static const Set<String> _whitePieces = {'♙', '♘', '♗', '♖', '♕', '♔'};
  static const Set<String> _blackPieces = {'♟', '♞', '♝', '♜', '♛', '♚'};

  static bool isWhitePiece(String p) => _whitePieces.contains(p);
  static bool isBlackPiece(String p) => _blackPieces.contains(p);

  // Positional Piece-Square Tables (Row 0 = Black backrank, Row 7 = White backrank)
  static const List<List<int>> _blackPawnPST = [
    [0,   0,   0,   0,   0,   0,   0,   0],
    [5,  10,  10, -20, -20,  10,  10,   5],
    [5,  -5, -10,   0,   0, -10,  -5,   5],
    [0,   0,   0,  20,  20,   0,   0,   0],
    [5,   5,  10,  25,  25,  10,   5,   5],
    [10, 10,  20,  30,  30,  20,  10,  10],
    [50, 50,  50,  50,  50,  50,  50,  50],
    [0,   0,   0,   0,   0,   0,   0,   0],
  ];

  static const List<List<int>> _whitePawnPST = [
    [0,   0,   0,   0,   0,   0,   0,   0],
    [50, 50,  50,  50,  50,  50,  50,  50],
    [10, 10,  20,  30,  30,  20,  10,  10],
    [5,   5,  10,  25,  25,  10,   5,   5],
    [0,   0,   0,  20,  20,   0,   0,   0],
    [5,  -5, -10,   0,   0, -10,  -5,   5],
    [5,  10,  10, -20, -20,  10,  10,   5],
    [0,   0,   0,   0,   0,   0,   0,   0],
  ];

  static const List<List<int>> _knightPST = [
    [-50, -40, -30, -30, -30, -30, -40, -50],
    [-40, -20,   0,   5,   5,   0, -20, -40],
    [-30,   5,  10,  15,  15,  10,   5, -30],
    [-30,   0,  15,  20,  20,  15,   0, -30],
    [-30,   5,  15,  20,  20,  15,   5, -30],
    [-30,   0,  10,  15,  15,  10,   0, -30],
    [-40, -20,   0,   0,   0,   0, -20, -40],
    [-50, -40, -30, -30, -30, -30, -40, -50],
  ];

  static const List<List<int>> _bishopPST = [
    [-20, -10, -10, -10, -10, -10, -10, -20],
    [-10,   5,   0,   0,   0,   0,   5, -10],
    [-10,  10,  10,  10,  10,  10,  10, -10],
    [-10,   0,  10,  10,  10,  10,   0, -10],
    [-10,   5,   5,  10,  10,   5,   5, -10],
    [-10,   0,   5,  10,  10,   5,   0, -10],
    [-10,   0,   0,   0,   0,   0,   0, -10],
    [-20, -10, -10, -10, -10, -10, -10, -20],
  ];

  static const List<List<int>> _blackRookPST = [
    [0,   0,   0,   5,   5,   0,   0,   0],
    [-5,  0,   0,   0,   0,   0,   0,  -5],
    [-5,  0,   0,   0,   0,   0,   0,  -5],
    [-5,  0,   0,   0,   0,   0,   0,  -5],
    [-5,  0,   0,   0,   0,   0,   0,  -5],
    [-5,  0,   0,   0,   0,   0,   0,  -5],
    [5,  10,  10,  10,  10,  10,  10,   5],
    [0,   0,   0,   0,   0,   0,   0,   0],
  ];

  static const List<List<int>> _whiteRookPST = [
    [0,   0,   0,   0,   0,   0,   0,   0],
    [5,  10,  10,  10,  10,  10,  10,   5],
    [-5,  0,   0,   0,   0,   0,   0,  -5],
    [-5,  0,   0,   0,   0,   0,   0,  -5],
    [-5,  0,   0,   0,   0,   0,   0,  -5],
    [-5,  0,   0,   0,   0,   0,   0,  -5],
    [-5,  0,   0,   0,   0,   0,   0,  -5],
    [0,   0,   0,   5,   5,   0,   0,   0],
  ];

  static const List<List<int>> _blackKingPST = [
    [20,  30,  10,   0,   0,  10,  30,  20],
    [20,  20,   0,   0,   0,   0,  20,  20],
    [-10,-20, -20, -20, -20, -20, -20, -10],
    [-20,-30, -30, -40, -40, -30, -30, -20],
    [-30,-40, -40, -50, -50, -40, -40, -30],
    [-30,-40, -40, -50, -50, -40, -40, -30],
    [-30,-40, -40, -50, -50, -40, -40, -30],
    [-30,-40, -40, -50, -50, -40, -40, -30],
  ];

  static const List<List<int>> _whiteKingPST = [
    [-30,-40, -40, -50, -50, -40, -40, -30],
    [-30,-40, -40, -50, -50, -40, -40, -30],
    [-30,-40, -40, -50, -50, -40, -40, -30],
    [-30,-40, -40, -50, -50, -40, -40, -30],
    [-20,-30, -30, -40, -40, -30, -30, -20],
    [-10,-20, -20, -20, -20, -20, -20, -10],
    [20,  20,   0,   0,   0,   0,  20,  20],
    [20,  30,  10,   0,   0,  10,  30,  20],
  ];

  static int _getPieceValue(String p) {
    switch (p) {
      case '♙': case '♟': return 100;
      case '♘': case '♞': return 320;
      case '♗': case '♝': return 330;
      case '♖': case '♜': return 500;
      case '♕': case '♛': return 900;
      case '♔': case '♚': return 20000;
      default: return 0;
    }
  }

  /// Evaluates board from Black's perspective (positive = Black advantage, negative = White advantage)
  static int evaluateBoard(List<List<String>> b) {
    int score = 0;
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final p = b[r][c];
        if (p.isEmpty) continue;
        switch (p) {
          case '♟':
            score += 100 + _blackPawnPST[r][c];
            break;
          case '♞':
            score += 320 + _knightPST[r][c];
            break;
          case '♝':
            score += 330 + _bishopPST[r][c];
            break;
          case '♜':
            score += 500 + _blackRookPST[r][c];
            break;
          case '♛':
            score += 900 + (_knightPST[r][c] ~/ 2);
            break;
          case '♚':
            score += 20000 + _blackKingPST[r][c];
            break;
          case '♙':
            score -= 100 + _whitePawnPST[r][c];
            break;
          case '♘':
            score -= 320 + _knightPST[r][c];
            break;
          case '♗':
            score -= 330 + _bishopPST[r][c];
            break;
          case '♖':
            score -= 500 + _whiteRookPST[r][c];
            break;
          case '♕':
            score -= 900 + (_knightPST[r][c] ~/ 2);
            break;
          case '♔':
            score -= 20000 + _whiteKingPST[r][c];
            break;
        }
      }
    }
    if (isKingInCheck(true, b)) score += 45;
    if (isKingInCheck(false, b)) score -= 45;
    return score;
  }

  static List<int>? findKing(bool isWhite, List<List<String>> b) {
    final target = isWhite ? '♔' : '♚';
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (b[r][c] == target) return [r, c];
      }
    }
    return null;
  }

  /// Fast reverse check detection directly from king position
  static bool isKingInCheck(bool isWhite, List<List<String>> b) {
    final kPos = findKing(isWhite, b);
    if (kPos == null) return false;
    final kR = kPos[0];
    final kC = kPos[1];

    // 1. Knight attacks
    const knightDeltas = [
      [-2, -1], [-2, 1], [-1, -2], [-1, 2],
      [1, -2], [1, 2], [2, -1], [2, 1]
    ];
    final enemyKnight = isWhite ? '♞' : '♘';
    for (final d in knightDeltas) {
      final nr = kR + d[0];
      final nc = kC + d[1];
      if (nr >= 0 && nr < 8 && nc >= 0 && nc < 8) {
        if (b[nr][nc] == enemyKnight) return true;
      }
    }

    // 2. Pawn attacks
    final pawnDir = isWhite ? -1 : 1;
    final enemyPawn = isWhite ? '♟' : '♙';
    final pR = kR + pawnDir;
    if (pR >= 0 && pR < 8) {
      if (kC - 1 >= 0 && b[pR][kC - 1] == enemyPawn) return true;
      if (kC + 1 < 8 && b[pR][kC + 1] == enemyPawn) return true;
    }

    // 3. Orthogonal rays (Rook / Queen)
    final enemyRook = isWhite ? '♜' : '♖';
    final enemyQueen = isWhite ? '♛' : '♕';
    const ortho = [[1, 0], [-1, 0], [0, 1], [0, -1]];
    for (final d in ortho) {
      int r = kR + d[0];
      int c = kC + d[1];
      while (r >= 0 && r < 8 && c >= 0 && c < 8) {
        final p = b[r][c];
        if (p.isNotEmpty) {
          if (p == enemyRook || p == enemyQueen) return true;
          break; // Blocked by another piece
        }
        r += d[0];
        c += d[1];
      }
    }

    // 4. Diagonal rays (Bishop / Queen)
    final enemyBishop = isWhite ? '♝' : '♗';
    const diag = [[1, 1], [1, -1], [-1, 1], [-1, -1]];
    for (final d in diag) {
      int r = kR + d[0];
      int c = kC + d[1];
      while (r >= 0 && r < 8 && c >= 0 && c < 8) {
        final p = b[r][c];
        if (p.isNotEmpty) {
          if (p == enemyBishop || p == enemyQueen) return true;
          break; // Blocked
        }
        r += d[0];
        c += d[1];
      }
    }

    // 5. Enemy king adjacent
    final enemyKing = isWhite ? '♚' : '♔';
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final nr = kR + dr;
        final nc = kC + dc;
        if (nr >= 0 && nr < 8 && nc >= 0 && nc < 8) {
          if (b[nr][nc] == enemyKing) return true;
        }
      }
    }

    return false;
  }

  /// Fast move simulator
  static List<List<String>> applyMove(List<List<String>> b, int fR, int fC, int tR, int tC) {
    final cloned = [
      List<String>.from(b[0]),
      List<String>.from(b[1]),
      List<String>.from(b[2]),
      List<String>.from(b[3]),
      List<String>.from(b[4]),
      List<String>.from(b[5]),
      List<String>.from(b[6]),
      List<String>.from(b[7]),
    ];
    final piece = cloned[fR][fC];
    cloned[tR][tC] = piece;
    cloned[fR][fC] = '';

    // Pawn Promotion
    if (piece == '♟' && tR == 7) cloned[tR][tC] = '♛';
    if (piece == '♙' && tR == 0) cloned[tR][tC] = '♕';

    return cloned;
  }

  /// High-speed ray-cast move generator (only explores reachable squares, avoiding 4096-square checks)
  static List<Map<String, dynamic>> generateLegalMoves(bool isWhite, List<List<String>> b) {
    final List<Map<String, dynamic>> legalMoves = [];

    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final p = b[r][c];
        if (p.isEmpty) continue;
        if (isWhite && !isWhitePiece(p)) continue;
        if (!isWhite && !isBlackPiece(p)) continue;

        switch (p) {
          // --- BLACK PAWN ---
          case '♟':
            if (r + 1 < 8 && b[r + 1][c].isEmpty) {
              _addIfLegal(legalMoves, isWhite, b, r, c, r + 1, c, p, '');
              if (r == 1 && b[r + 2][c].isEmpty) {
                _addIfLegal(legalMoves, isWhite, b, r, c, r + 2, c, p, '');
              }
            }
            if (r + 1 < 8 && c - 1 >= 0 && isWhitePiece(b[r + 1][c - 1])) {
              _addIfLegal(legalMoves, isWhite, b, r, c, r + 1, c - 1, p, b[r + 1][c - 1]);
            }
            if (r + 1 < 8 && c + 1 < 8 && isWhitePiece(b[r + 1][c + 1])) {
              _addIfLegal(legalMoves, isWhite, b, r, c, r + 1, c + 1, p, b[r + 1][c + 1]);
            }
            break;

          // --- WHITE PAWN ---
          case '♙':
            if (r - 1 >= 0 && b[r - 1][c].isEmpty) {
              _addIfLegal(legalMoves, isWhite, b, r, c, r - 1, c, p, '');
              if (r == 6 && b[r - 2][c].isEmpty) {
                _addIfLegal(legalMoves, isWhite, b, r, c, r - 2, c, p, '');
              }
            }
            if (r - 1 >= 0 && c - 1 >= 0 && isBlackPiece(b[r - 1][c - 1])) {
              _addIfLegal(legalMoves, isWhite, b, r, c, r - 1, c - 1, p, b[r - 1][c - 1]);
            }
            if (r - 1 >= 0 && c + 1 < 8 && isBlackPiece(b[r - 1][c + 1])) {
              _addIfLegal(legalMoves, isWhite, b, r, c, r - 1, c + 1, p, b[r - 1][c + 1]);
            }
            break;

          // --- KNIGHTS ---
          case '♞':
          case '♘':
            const knightDeltas = [
              [-2, -1], [-2, 1], [-1, -2], [-1, 2],
              [1, -2], [1, 2], [2, -1], [2, 1]
            ];
            for (final d in knightDeltas) {
              final nr = r + d[0];
              final nc = c + d[1];
              if (nr >= 0 && nr < 8 && nc >= 0 && nc < 8) {
                final target = b[nr][nc];
                if (target.isEmpty || (isWhite ? isBlackPiece(target) : isWhitePiece(target))) {
                  _addIfLegal(legalMoves, isWhite, b, r, c, nr, nc, p, target);
                }
              }
            }
            break;

          // --- ROOKS ---
          case '♜':
          case '♖':
            _generateRayMoves(legalMoves, isWhite, b, r, c, p, const [[1, 0], [-1, 0], [0, 1], [0, -1]]);
            break;

          // --- BISHOPS ---
          case '♝':
          case '♗':
            _generateRayMoves(legalMoves, isWhite, b, r, c, p, const [[1, 1], [1, -1], [-1, 1], [-1, -1]]);
            break;

          // --- QUEENS ---
          case '♛':
          case '♕':
            _generateRayMoves(legalMoves, isWhite, b, r, c, p, const [
              [1, 0], [-1, 0], [0, 1], [0, -1],
              [1, 1], [1, -1], [-1, 1], [-1, -1]
            ]);
            break;

          // --- KINGS ---
          case '♚':
          case '♔':
            for (int dr = -1; dr <= 1; dr++) {
              for (int dc = -1; dc <= 1; dc++) {
                if (dr == 0 && dc == 0) continue;
                final nr = r + dr;
                final nc = c + dc;
                if (nr >= 0 && nr < 8 && nc >= 0 && nc < 8) {
                  final target = b[nr][nc];
                  if (target.isEmpty || (isWhite ? isBlackPiece(target) : isWhitePiece(target))) {
                    _addIfLegal(legalMoves, isWhite, b, r, c, nr, nc, p, target);
                  }
                }
              }
            }
            break;
        }
      }
    }

    return legalMoves;
  }

  static void _generateRayMoves(
    List<Map<String, dynamic>> moves,
    bool isWhite,
    List<List<String>> b,
    int r,
    int c,
    String piece,
    List<List<int>> directions,
  ) {
    for (final d in directions) {
      int nr = r + d[0];
      int nc = c + d[1];
      while (nr >= 0 && nr < 8 && nc >= 0 && nc < 8) {
        final target = b[nr][nc];
        if (target.isEmpty) {
          _addIfLegal(moves, isWhite, b, r, c, nr, nc, piece, '');
        } else {
          if (isWhite ? isBlackPiece(target) : isWhitePiece(target)) {
            _addIfLegal(moves, isWhite, b, r, c, nr, nc, piece, target);
          }
          break; // Ray blocked
        }
        nr += d[0];
        nc += d[1];
      }
    }
  }

  static void _addIfLegal(
    List<Map<String, dynamic>> moves,
    bool isWhite,
    List<List<String>> b,
    int fR,
    int fC,
    int tR,
    int tC,
    String piece,
    String captured,
  ) {
    final next = applyMove(b, fR, fC, tR, tC);
    if (!isKingInCheck(isWhite, next)) {
      moves.add({
        'fromRow': fR,
        'fromCol': fC,
        'toRow': tR,
        'toCol': tC,
        'piece': piece,
        'captured': captured,
      });
    }
  }

  /// Orders moves by MVV-LVA (Most Valuable Victim - Least Valuable Attacker)
  /// Crucial for Alpha-Beta cutoff efficiency (prunes ~95% of non-viable nodes)
  static void orderMoves(List<Map<String, dynamic>> moves) {
    for (final m in moves) {
      int priority = 0;
      final captured = m['captured'] as String? ?? '';
      if (captured.isNotEmpty) {
        final victimVal = _getPieceValue(captured);
        final attackerVal = _getPieceValue(m['piece'] as String);
        priority += 10000 + (victimVal * 10) - attackerVal;
      }
      final p = m['piece'] as String;
      final tR = m['toRow'] as int;
      if ((p == '♟' && tR == 7) || (p == '♙' && tR == 0)) {
        priority += 9000; // Pawn Promotion
      }
      m['priority'] = priority;
    }
    moves.sort((a, b) => (b['priority'] as int).compareTo(a['priority'] as int));
  }

  /// Alpha-Beta Minimax search
  static int alphaBeta(List<List<String>> b, int depth, int alpha, int beta, bool isMaximizing) {
    if (depth == 0) {
      return evaluateBoard(b);
    }

    final isWhiteTurn = !isMaximizing;
    final moves = generateLegalMoves(isWhiteTurn, b);
    if (moves.isEmpty) {
      if (isKingInCheck(isWhiteTurn, b)) {
        return isMaximizing ? -100000 - depth : 100000 + depth;
      }
      return 0; // Stalemate
    }

    orderMoves(moves);

    if (isMaximizing) {
      int maxScore = -9999999;
      for (final m in moves) {
        final next = applyMove(b, m['fromRow'] as int, m['fromCol'] as int, m['toRow'] as int, m['toCol'] as int);
        final eval = alphaBeta(next, depth - 1, alpha, beta, false);
        if (eval > maxScore) maxScore = eval;
        if (eval > alpha) alpha = eval;
        if (beta <= alpha) break; // Alpha-beta cutoff
      }
      return maxScore;
    } else {
      int minScore = 9999999;
      for (final m in moves) {
        final next = applyMove(b, m['fromRow'] as int, m['fromCol'] as int, m['toRow'] as int, m['toCol'] as int);
        final eval = alphaBeta(next, depth - 1, alpha, beta, true);
        if (eval < minScore) minScore = eval;
        if (eval < beta) beta = eval;
        if (beta <= alpha) break; // Alpha-beta cutoff
      }
      return minScore;
    }
  }

  /// Main entrypoint to be executed via `compute(ChessAIService.computeAIMove, params)`
  /// Runs inside a background worker isolate so the Flutter UI thread never freezes.
  static Map<String, int>? computeAIMove(Map<String, dynamic> params) {
    final rawBoard = params['board'] as List;
    final List<List<String>> board = rawBoard
        .map((r) => (r as List).map((c) => c.toString()).toList())
        .toList();
    final String diff = (params['difficulty'] ?? 'easy').toString().toLowerCase();

    // Black is the AI
    final moves = generateLegalMoves(false, board);
    if (moves.isEmpty) return null;

    final random = Random();
    Map<String, dynamic> selectedMove;

    if (diff == 'easy') {
      // EASY (~400 ELO): 50% random move, 50% depth 1 (captures & immediate gains)
      final roll = random.nextDouble();
      if (roll < 0.50) {
        selectedMove = moves[random.nextInt(moves.length)];
      } else {
        for (final m in moves) {
          final next = applyMove(board, m['fromRow'] as int, m['fromCol'] as int, m['toRow'] as int, m['toCol'] as int);
          m['score'] = evaluateBoard(next);
        }
        moves.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
        selectedMove = moves.first;
      }
    } else if (diff == 'medium') {
      // MEDIUM (~1000 ELO): Depth 2 Minimax Alpha-Beta
      orderMoves(moves);
      for (final m in moves) {
        final next = applyMove(board, m['fromRow'] as int, m['fromCol'] as int, m['toRow'] as int, m['toCol'] as int);
        m['score'] = alphaBeta(next, 1, -9999999, 9999999, false);
      }
      moves.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
      // 15% chance to pick second best move for human-like realism
      if (moves.length > 1 && random.nextDouble() < 0.15) {
        selectedMove = moves[1];
      } else {
        selectedMove = moves.first;
      }
    } else if (diff == 'hard') {
      // HARD (~1600 ELO): Depth 3 Minimax Alpha-Beta with move ordering
      orderMoves(moves);
      for (final m in moves) {
        final next = applyMove(board, m['fromRow'] as int, m['fromCol'] as int, m['toRow'] as int, m['toCol'] as int);
        m['score'] = alphaBeta(next, 2, -9999999, 9999999, false);
      }
      moves.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
      selectedMove = moves.first;
    } else {
      // GRANDMASTER (~2200 ELO): Depth 3/4 Minimax Alpha-Beta with move ordering
      orderMoves(moves);
      for (final m in moves) {
        final next = applyMove(board, m['fromRow'] as int, m['fromCol'] as int, m['toRow'] as int, m['toCol'] as int);
        m['score'] = alphaBeta(next, 3, -9999999, 9999999, false);
      }
      moves.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
      selectedMove = moves.first;
    }

    return {
      'fromRow': selectedMove['fromRow'] as int,
      'fromCol': selectedMove['fromCol'] as int,
      'toRow': selectedMove['toRow'] as int,
      'toCol': selectedMove['toCol'] as int,
    };
  }

  /// Background isolate entrypoint for Hint calculation
  static Map<String, int>? computeHintMove(Map<String, dynamic> params) {
    final rawBoard = params['board'] as List;
    final List<List<String>> board = rawBoard
        .map((r) => (r as List).map((c) => c.toString()).toList())
        .toList();
    final bool isWhite = params['isWhite'] as bool? ?? true;

    final moves = generateLegalMoves(isWhite, board);
    if (moves.isEmpty) return null;

    orderMoves(moves);
    for (final m in moves) {
      final next = applyMove(board, m['fromRow'] as int, m['fromCol'] as int, m['toRow'] as int, m['toCol'] as int);
      m['score'] = isWhite
          ? -alphaBeta(next, 2, -9999999, 9999999, true)
          : alphaBeta(next, 2, -9999999, 9999999, false);
    }
    moves.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    final best = moves.first;

    return {
      'fromRow': best['fromRow'] as int,
      'fromCol': best['fromCol'] as int,
      'toRow': best['toRow'] as int,
      'toCol': best['toCol'] as int,
    };
  }
}
