import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:sentient/core/providers/user_provider.dart';
import 'package:sentient/core/utils/image_helper.dart';
import 'package:sentient/features/chess/widgets/chess_piece_widget.dart';
import 'package:sentient/features/chess/services/chess_online_service.dart';
import 'package:sentient/features/chess/services/chess_ai_service.dart';
import 'package:sentient/features/chess/models/chess_game_analysis.dart';
import 'package:sentient/features/chess/widgets/chess_game_analysis_dialog.dart';
import 'package:sentient/features/chess/services/chess_stats_service.dart';

class ChessGameScreen extends StatefulWidget {
  final String? aiDifficulty;
  final bool isAIGame;
  final bool isOnlineGame;
  final String? onlineMatchId;
  final String onlinePlayerColor; // 'white' or 'black'
  final String? onlineOpponentName;
  final String? onlineOpponentAvatar;
  final int? initialTimeSeconds; // null or <= 0 means Unlimited / Tanpa Waktu

  /// Status global untuk mengecek apakah user sedang berada di dalam game aktif
  static bool isUserInMatch = false;
  static String? activeMatchId;
  
  const ChessGameScreen({
    super.key, 
    this.aiDifficulty, 
    this.isAIGame = false,
    this.isOnlineGame = false,
    this.onlineMatchId,
    this.onlinePlayerColor = 'white',
    this.onlineOpponentName,
    this.onlineOpponentAvatar,
    this.initialTimeSeconds,
  });

  @override
  State<ChessGameScreen> createState() => _ChessGameScreenState();
}

class _ChessGameScreenState extends State<ChessGameScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  late List<List<String>> board;
  String currentPlayer = 'white';
  String? selectedPiece;
  int? selectedRow;
  int? selectedCol;
  bool isGameActive = true;
  bool _isAIThinking = false;
  String gameStatus = 'White to move';
  int whiteCapturedPieces = 0;
  int blackCapturedPieces = 0;
  List<String> whiteCapturedList = []; // Black pieces captured by White
  List<String> blackCapturedList = []; // White pieces captured by Black
  final List<Map<String, dynamic>> _moveSnapshots = [];
  final List<Map<String, dynamic>> _recordedGameMoves = [];
  int? hintFromRow;
  int? hintFromCol;
  int? hintToRow;
  int? hintToCol;
  List<String> moveHistory = [];
  int moveCount = 0;
  
  // Check & Checkmate State
  bool isCheck = false;
  List<int>? checkedKingPos;
  bool isCheckmate = false;
  bool isStalemate = false;
  String? winner;

  // Board Flipping perspective for Black
  bool get _isBoardFlipped => widget.isOnlineGame && widget.onlinePlayerColor == 'black';

  // Online Multiplayer State
  StreamSubscription? _onlineMatchSub;
  String? _topReactionText;
  String? _bottomReactionText;
  Timer? _topReactionTimer;
  Timer? _bottomReactionTimer;
  bool _isDrawOfferDialogShowing = false;
  bool _isGameOverDialogShowing = false;
  Timer? _abortCountdownTimer;
  int _abortSecondsRemaining = 60;

  // Disconnection Handling State (Chess.com style)
  bool _isOpponentDisconnected = false;
  Timer? _disconnectCountdownTimer;
  int _disconnectSecondsRemaining = 30;

  // Realtime Avatars for Online Match
  String? _remoteOpponentAvatar;
  String? _remoteMyAvatar;

  // Chess Clock System (Chess.com style Rapid / Blitz / Bullet or Untimed)
  late int _whiteTimeRemaining;
  late int _blackTimeRemaining;
  Timer? _chessClockTimer;
  bool get _isUntimed => widget.isOnlineGame
      ? false
      : (widget.initialTimeSeconds == null || widget.initialTimeSeconds! <= 0);

  // Skin System - Future Monetization
  String currentBoardTheme = 'classic'; // classic, wood, marble, glass
  String currentPieceSet = 'classic'; // classic, modern, royal, neon
  String currentBackgroundTheme = 'dark'; // dark, light, nature, space
  
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    ChessGameScreen.isUserInMatch = true;
    ChessGameScreen.activeMatchId = widget.onlineMatchId;

    final defaultTime = (widget.initialTimeSeconds != null && widget.initialTimeSeconds! > 0)
        ? widget.initialTimeSeconds!
        : 600;
    _whiteTimeRemaining = defaultTime;
    _blackTimeRemaining = defaultTime;

    _initializeBoard();
    _initializeAnimations();
    _updateGameStatus();
    if (!_isUntimed) {
      _startChessClockTimer();
    }

    WidgetsBinding.instance.addObserver(this);
    if (widget.isOnlineGame && widget.onlineMatchId != null) {
      ChessOnlineService.setPlayerConnectionStatus(
        matchId: widget.onlineMatchId!,
        playerColor: widget.onlinePlayerColor,
        isConnected: true,
      );
      _listenToOnlineMatch();
      _startAbortTimer();
    }
  }

  void _listenToOnlineMatch() {
    _onlineMatchSub = ChessOnlineService.streamMatch(widget.onlineMatchId!).listen((doc) {
      if (!doc.exists || !mounted) return;
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return;

      final remoteTurn = data['current_turn']?.toString() ?? 'white';
      final remoteStatus = data['status']?.toString() ?? 'ongoing';
      final remoteWinner = data['winner']?.toString();
      final remoteReaction = data['latest_reaction'] as Map<String, dynamic>?;

      // Sinkronkan avatar pemain secara realtime jika tersedia dari data match
      final oppAvatar = widget.onlinePlayerColor == 'white'
          ? data['black_player_avatar']?.toString()
          : data['white_player_avatar']?.toString();
      final myAvatar = widget.onlinePlayerColor == 'white'
          ? data['white_player_avatar']?.toString()
          : data['black_player_avatar']?.toString();
      if (oppAvatar != null && oppAvatar.isNotEmpty && oppAvatar != _remoteOpponentAvatar) {
        setState(() {
          _remoteOpponentAvatar = oppAvatar;
        });
      }
      if (myAvatar != null && myAvatar.isNotEmpty && myAvatar != _remoteMyAvatar) {
        setState(() {
          _remoteMyAvatar = myAvatar;
        });
      }

      // Handle remote in-game reaction & quick message
      if (remoteReaction != null) {
        final rSenderId = remoteReaction['sender_id']?.toString();
        final rSenderColor = remoteReaction['sender_color']?.toString();
        final rEmoji = remoteReaction['emoji']?.toString();
        final rMessage = remoteReaction['message']?.toString();
        final rTime = remoteReaction['timestamp'] as int? ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        final displayText = [rEmoji, rMessage].where((e) => e != null && e.isNotEmpty).join(' ');
        if (displayText.isNotEmpty && (now - rTime) < 5000 && rSenderId != ChessOnlineService.currentUserId) {
          final isTop = widget.isOnlineGame ? (rSenderColor != widget.onlinePlayerColor) : true;
          _showPlayerReaction(displayText, isTop: isTop);
        }
      }

      // Check disconnection status of opponent
      final disconnectedPlayer = data['disconnected_player']?.toString();
      final opponentColor = widget.onlinePlayerColor == 'white' ? 'black' : 'white';
      if (disconnectedPlayer == opponentColor && isGameActive) {
        if (!_isOpponentDisconnected) {
          _startOpponentDisconnectCountdown();
        }
      } else if (disconnectedPlayer == null && _isOpponentDisconnected) {
        _cancelOpponentDisconnectCountdown();
      }

      // Check if match was aborted
      if (remoteStatus == 'aborted' && isGameActive) {
        _abortCountdownTimer?.cancel();
        setState(() {
          isGameActive = false;
          winner = null;
          gameStatus = 'Game Aborted ⏱️';
        });
        _showGameOverDialog(
          title: 'Game Aborted ⏱️',
          subtitle: 'Match was aborted because the first move was not made within the time limit.',
          winner: null,
          isCheckmate: false,
        );
        return;
      }

      // Check if match ended by resignation
      if (remoteStatus == 'resigned' && isGameActive) {
        final isMeWinner = remoteWinner == widget.onlinePlayerColor;
        setState(() {
          isGameActive = false;
          winner = remoteWinner;
          gameStatus = isMeWinner
              ? 'Opponent Resigned! You Win! 🏆'
              : 'You Resigned the Match.';
        });
        _showGameOverDialog(
          title: isMeWinner ? 'Victory! 🏆' : 'Defeat',
          subtitle: isMeWinner
              ? 'Opponent has resigned from the match.'
              : 'You have resigned from the match.',
          winner: remoteWinner,
          isCheckmate: false,
        );
        return;
      }

      // Check if match ended in abandonment (lawan disconnect / keluar)
      if (remoteStatus == 'abandoned' && isGameActive) {
        _disconnectCountdownTimer?.cancel();
        setState(() {
          isGameActive = false;
          winner = remoteWinner;
          gameStatus = remoteWinner == widget.onlinePlayerColor
              ? 'Opponent Abandoned Match! You Win! 🏆'
              : 'Match Forfeited by Abandonment.';
        });
        _showGameOverDialog(
          title: remoteWinner == widget.onlinePlayerColor ? 'Victory! 🏆' : 'Match Forfeited',
          subtitle: remoteWinner == widget.onlinePlayerColor
              ? 'Opponent disconnected and did not return. You win!'
              : 'You were disconnected for too long and forfeited the match.',
          winner: remoteWinner,
          isCheckmate: false,
        );
        return;
      }

      // Check if match ended in draw (remis)
      if (remoteStatus == 'draw' && isGameActive) {
        setState(() {
          isGameActive = false;
          winner = null;
          gameStatus = 'Game Ended in a Draw 🤝';
        });
        _showGameOverDialog(
          title: 'DRAW 🤝',
          subtitle: 'Both players agreed to end the match in a draw.',
          winner: null,
          isCheckmate: false,
        );
        return;
      }

      // Check if match ended in timeout (waktu habis)
      if (remoteStatus == 'timeout' && isGameActive) {
        _chessClockTimer?.cancel();
        _abortCountdownTimer?.cancel();
        setState(() {
          isGameActive = false;
          winner = remoteWinner;
          gameStatus = remoteWinner == widget.onlinePlayerColor
              ? 'Victory! You Win on Time! ⏱️🏆'
              : 'Time\'s Up! Opponent Wins! ⏱️';
        });
        _showGameOverDialog(
          title: 'Time\'s Up! ⏱️',
          subtitle: remoteWinner == widget.onlinePlayerColor
              ? 'Opponent ran out of time! You win this chess match on time! 🏆'
              : 'You ran out of time! Opponent wins on time.',
          winner: remoteWinner,
          isCheckmate: false,
        );
        return;
      }

      // Check if incoming draw offer from opponent
      final remoteDrawOfferBy = data['draw_offer_by']?.toString();
      if (remoteDrawOfferBy != null &&
          remoteDrawOfferBy != widget.onlinePlayerColor &&
          isGameActive &&
          !_isDrawOfferDialogShowing) {
        _isDrawOfferDialogShowing = true;
        _showIncomingDrawOfferDialog();
      }

      // Sync clock timers from remote
      if (data['white_time'] is int) {
        _whiteTimeRemaining = data['white_time'] as int;
      }
      if (data['black_time'] is int) {
        _blackTimeRemaining = data['black_time'] as int;
      }

      // Sync board state if updated
      if (data['board_state'] != null) {
        final newBoard = ChessOnlineService.unflattenBoard(data['board_state']);

        final remoteWhiteCaptured = (data['white_captured'] as List?)?.map((e) => e.toString()).toList() ?? [];
        final remoteBlackCaptured = (data['black_captured'] as List?)?.map((e) => e.toString()).toList() ?? [];
        final remoteMoveHistory = (data['move_history'] as List?)?.map((e) => e.toString()).toList() ?? [];

        if (remoteMoveHistory.isNotEmpty) {
          _abortCountdownTimer?.cancel();
        }

        setState(() {
          board = newBoard;
          currentPlayer = remoteTurn;
          whiteCapturedList = remoteWhiteCaptured;
          blackCapturedList = remoteBlackCaptured;
          whiteCapturedPieces = whiteCapturedList.length;
          blackCapturedPieces = blackCapturedList.length;
          moveHistory = remoteMoveHistory;
          moveCount = moveHistory.length;
        });

        _updateGameStatus();
      }
    });
  }

  void _showPlayerReaction(String text, {required bool isTop}) {
    if (!mounted) return;
    setState(() {
      if (isTop) {
        _topReactionText = text;
      } else {
        _bottomReactionText = text;
      }
    });

    if (isTop) {
      _topReactionTimer?.cancel();
      _topReactionTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _topReactionText = null;
          });
        }
      });
    } else {
      _bottomReactionTimer?.cancel();
      _bottomReactionTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _bottomReactionText = null;
          });
        }
      });
    }
  }

  void _startOpponentDisconnectCountdown() {
    _disconnectCountdownTimer?.cancel();
    setState(() {
      _isOpponentDisconnected = true;
      _disconnectSecondsRemaining = 30;
    });

    _disconnectCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_disconnectSecondsRemaining > 1) {
          _disconnectSecondsRemaining--;
        } else {
          _disconnectSecondsRemaining = 0;
          timer.cancel();
          _claimAbandonmentVictory();
        }
      });
    });
  }

  void _cancelOpponentDisconnectCountdown() {
    _disconnectCountdownTimer?.cancel();
    if (mounted) {
      setState(() {
        _isOpponentDisconnected = false;
        _disconnectSecondsRemaining = 30;
      });
    }
  }

  void _claimAbandonmentVictory() {
    _disconnectCountdownTimer?.cancel();
    if (!mounted || !isGameActive) return;
    if (widget.isOnlineGame && widget.onlineMatchId != null) {
      ChessOnlineService.claimAbandonmentVictory(
        matchId: widget.onlineMatchId!,
        winnerColor: widget.onlinePlayerColor,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!widget.isOnlineGame || widget.onlineMatchId == null) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      ChessOnlineService.setPlayerConnectionStatus(
        matchId: widget.onlineMatchId!,
        playerColor: widget.onlinePlayerColor,
        isConnected: false,
      );
    } else if (state == AppLifecycleState.resumed) {
      ChessOnlineService.setPlayerConnectionStatus(
        matchId: widget.onlineMatchId!,
        playerColor: widget.onlinePlayerColor,
        isConnected: true,
      );
    }
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    _pulseController.repeat(reverse: true);
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    ChessGameScreen.isUserInMatch = false;
    ChessGameScreen.activeMatchId = null;
    WidgetsBinding.instance.removeObserver(this);
    if (widget.isOnlineGame && widget.onlineMatchId != null) {
      ChessOnlineService.setPlayerConnectionStatus(
        matchId: widget.onlineMatchId!,
        playerColor: widget.onlinePlayerColor,
        isConnected: false,
      );
    }
    _chessClockTimer?.cancel();
    _abortCountdownTimer?.cancel();
    _disconnectCountdownTimer?.cancel();
    _onlineMatchSub?.cancel();
    _topReactionTimer?.cancel();
    _bottomReactionTimer?.cancel();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _initializeBoard() {
    board = [
      ['♜', '♞', '♝', '♛', '♚', '♝', '♞', '♜'],
      ['♟', '♟', '♟', '♟', '♟', '♟', '♟', '♟'],
      ['', '', '', '', '', '', '', ''],
      ['', '', '', '', '', '', '', ''],
      ['', '', '', '', '', '', '', ''],
      ['', '', '', '', '', '', '', ''],
      ['♙', '♙', '♙', '♙', '♙', '♙', '♙', '♙'],
      ['♖', '♘', '♗', '♕', '♔', '♗', '♘', '♖'],
    ];
  }

  bool _isWhitePiece(String piece) {
    return '♔♕♖♗♘♙'.contains(piece);
  }

  int _getPieceValue(String piece) {
    switch (piece) {
      case '♙': case '♟': return 1;
      case '♘': case '♞': return 3;
      case '♗': case '♝': return 3;
      case '♖': case '♜': return 5;
      case '♕': case '♛': return 9;
      default: return 0;
    }
  }

  int _getMaterialAdvantage(bool forWhite) {
    int whiteScore = whiteCapturedList.fold(0, (sum, p) => sum + _getPieceValue(p));
    int blackScore = blackCapturedList.fold(0, (sum, p) => sum + _getPieceValue(p));
    return forWhite ? (whiteScore - blackScore) : (blackScore - whiteScore);
  }

  bool _isPathClearOnBoard(int fromRow, int fromCol, int toRow, int toCol, List<List<String>> b) {
    final rowStep = toRow > fromRow ? 1 : (toRow < fromRow ? -1 : 0);
    final colStep = toCol > fromCol ? 1 : (toCol < fromCol ? -1 : 0);

    int currentRow = fromRow + rowStep;
    int currentCol = fromCol + colStep;

    while (currentRow != toRow || currentCol != toCol) {
      if (b[currentRow][currentCol].isNotEmpty) return false;
      currentRow += rowStep;
      currentCol += colStep;
    }

    return true;
  }

  bool _isPseudoLegalMove(int fromRow, int fromCol, int toRow, int toCol, List<List<String>> b) {
    if (fromRow < 0 || fromRow > 7 || fromCol < 0 || fromCol > 7 ||
        toRow < 0 || toRow > 7 || toCol < 0 || toCol > 7) {
      return false;
    }
    if (fromRow == toRow && fromCol == toCol) return false;

    final piece = b[fromRow][fromCol];
    final targetPiece = b[toRow][toCol];

    if (piece.isEmpty) return false;

    final isWhite = _isWhitePiece(piece);
    if (targetPiece.isNotEmpty) {
      final isTargetWhite = _isWhitePiece(targetPiece);
      if (isWhite == isTargetWhite) return false;
    }

    final rowDiff = toRow - fromRow;
    final colDiff = toCol - fromCol;
    final absRowDiff = rowDiff.abs();
    final absColDiff = colDiff.abs();

    switch (piece) {
      case '♙': // White Pawn
        if (colDiff == 0 && targetPiece.isEmpty) {
          if (rowDiff == -1) return true;
          if (fromRow == 6 && rowDiff == -2 && b[5][fromCol].isEmpty) return true;
        }
        if (absColDiff == 1 && rowDiff == -1 && targetPiece.isNotEmpty) return true;
        return false;

      case '♟': // Black Pawn
        if (colDiff == 0 && targetPiece.isEmpty) {
          if (rowDiff == 1) return true;
          if (fromRow == 1 && rowDiff == 2 && b[2][fromCol].isEmpty) return true;
        }
        if (absColDiff == 1 && rowDiff == 1 && targetPiece.isNotEmpty) return true;
        return false;

      case '♖': case '♜': // Rook
        if (rowDiff == 0 || colDiff == 0) return _isPathClearOnBoard(fromRow, fromCol, toRow, toCol, b);
        return false;

      case '♘': case '♞': // Knight
        return (absRowDiff == 2 && absColDiff == 1) || (absRowDiff == 1 && absColDiff == 2);

      case '♗': case '♝': // Bishop
        if (absRowDiff == absColDiff) return _isPathClearOnBoard(fromRow, fromCol, toRow, toCol, b);
        return false;

      case '♕': case '♛': // Queen
        if (rowDiff == 0 || colDiff == 0 || absRowDiff == absColDiff) {
          return _isPathClearOnBoard(fromRow, fromCol, toRow, toCol, b);
        }
        return false;

      case '♔': case '♚': // King
        return absRowDiff <= 1 && absColDiff <= 1;

      default:
        return false;
    }
  }

  bool _isSquareAttacked(int targetRow, int targetCol, bool byWhite, List<List<String>> b) {
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final p = b[r][c];
        if (p.isNotEmpty && _isWhitePiece(p) == byWhite) {
          if (p == '♙' || p == '♟') {
            final dir = byWhite ? -1 : 1;
            if (targetRow - r == dir && (targetCol - c).abs() == 1) {
              return true;
            }
          } else if (p == '♘' || p == '♞') {
            final dr = (targetRow - r).abs();
            final dc = (targetCol - c).abs();
            if ((dr == 2 && dc == 1) || (dr == 1 && dc == 2)) return true;
          } else if (p == '♗' || p == '♝') {
            final dr = (targetRow - r).abs();
            final dc = (targetCol - c).abs();
            if (dr == dc && dr > 0 && _isPathClearOnBoard(r, c, targetRow, targetCol, b)) {
              return true;
            }
          } else if (p == '♖' || p == '♜') {
            final dr = (targetRow - r).abs();
            final dc = (targetCol - c).abs();
            if ((dr == 0 || dc == 0) && (dr + dc > 0) && _isPathClearOnBoard(r, c, targetRow, targetCol, b)) {
              return true;
            }
          } else if (p == '♕' || p == '♛') {
            final dr = (targetRow - r).abs();
            final dc = (targetCol - c).abs();
            if ((dr == dc || dr == 0 || dc == 0) && (dr + dc > 0) && _isPathClearOnBoard(r, c, targetRow, targetCol, b)) {
              return true;
            }
          } else if (p == '♔' || p == '♚') {
            final dr = (targetRow - r).abs();
            final dc = (targetCol - c).abs();
            if (dr <= 1 && dc <= 1 && (dr + dc > 0)) {
              return true;
            }
          }
        }
      }
    }
    return false;
  }

  List<int>? _findKingPosition(bool isWhite, List<List<String>> b) {
    final kingChar = isWhite ? '♔' : '♚';
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (b[r][c] == kingChar) {
          return [r, c];
        }
      }
    }
    return null;
  }

  bool _isKingInCheck(bool isWhite, List<List<String>> b) {
    final kingPos = _findKingPosition(isWhite, b);
    if (kingPos == null) return false;
    return _isSquareAttacked(kingPos[0], kingPos[1], !isWhite, b);
  }

  bool _isLegalMoveOnBoard(int fromRow, int fromCol, int toRow, int toCol, List<List<String>> b) {
    if (!_isPseudoLegalMove(fromRow, fromCol, toRow, toCol, b)) {
      return false;
    }

    final piece = b[fromRow][fromCol];
    final isWhite = _isWhitePiece(piece);

    // Simulate move on cloned board
    List<List<String>> cloned = b.map((row) => List<String>.from(row)).toList();
    cloned[toRow][toCol] = cloned[fromRow][fromCol];
    cloned[fromRow][fromCol] = '';

    // Handle Pawn promotion in simulation
    if (piece == '♙' && toRow == 0) {
      cloned[toRow][toCol] = '♕';
    } else if (piece == '♟' && toRow == 7) {
      cloned[toRow][toCol] = '♛';
    }

    // Move is legal only if player's king is NOT left in check
    return !_isKingInCheck(isWhite, cloned);
  }

  bool _isLegalMove(int fromRow, int fromCol, int toRow, int toCol) {
    return _isLegalMoveOnBoard(fromRow, fromCol, toRow, toCol, board);
  }

  List<Map<String, dynamic>> _getAllLegalMovesOnBoard(bool isWhite, List<List<String>> b) {
    final List<Map<String, dynamic>> moves = [];
    for (int fR = 0; fR < 8; fR++) {
      for (int fC = 0; fC < 8; fC++) {
        final p = b[fR][fC];
        if (p.isNotEmpty && _isWhitePiece(p) == isWhite) {
          for (int tR = 0; tR < 8; tR++) {
            for (int tC = 0; tC < 8; tC++) {
              if (_isLegalMoveOnBoard(fR, fC, tR, tC, b)) {
                moves.add({
                  'fromRow': fR,
                  'fromCol': fC,
                  'toRow': tR,
                  'toCol': tC,
                  'piece': p,
                  'captured': b[tR][tC],
                });
              }
            }
          }
        }
      }
    }
    return moves;
  }

  List<Map<String, dynamic>> _getAllLegalMoves(bool isWhite) {
    return _getAllLegalMovesOnBoard(isWhite, board);
  }

  void _updateGameStatus() {
    final isCurrentWhite = currentPlayer == 'white';
    final inCheck = _isKingInCheck(isCurrentWhite, board);
    final legalMoves = _getAllLegalMoves(isCurrentWhite);

    setState(() {
      isCheck = inCheck;
      checkedKingPos = inCheck ? _findKingPosition(isCurrentWhite, board) : null;
    });

    if (legalMoves.isEmpty) {
      if (inCheck) {
        // CHECKMATE!
        final winningColor = isCurrentWhite ? 'black' : 'white';
        final winningName = isCurrentWhite ? 'Black' : 'White';
        setState(() {
          isGameActive = false;
          isCheckmate = true;
          winner = winningColor;
          gameStatus = 'CHECKMATE! $winningName Wins! 🏆';
        });

        _showGameOverDialog(
          title: 'CHECKMATE! 🏆',
          subtitle: 'The King cannot be saved. $winningName wins the match!',
          winner: winningColor,
          isCheckmate: true,
        );
      } else {
        // STALEMATE (REMIS / PAT)
        setState(() {
          isGameActive = false;
          isStalemate = true;
          winner = null;
          gameStatus = 'Draw (Stalemate)! Game drawn.';
        });

        _showGameOverDialog(
          title: 'DRAW (STALEMATE) 🤝',
          subtitle: 'No legal moves remaining and King is not in check. Game ends in a draw.',
          winner: null,
          isCheckmate: false,
        );
      }
    } else {
      setState(() {
        if (inCheck) {
          final playerName = isCurrentWhite ? 'White' : 'Black';
          gameStatus = 'CHECK! $playerName King in Danger! ⚠️';
        } else {
          final playerName = isCurrentWhite ? 'White' : 'Black';
          gameStatus = '$playerName to move';
        }
      });
    }
  }

  void _showGameOverDialog({
    required String title,
    required String subtitle,
    required String? winner,
    required bool isCheckmate,
  }) {
    if (_isGameOverDialogShowing || !mounted) return;
    _isGameOverDialogShowing = true;
    _chessClockTimer?.cancel();
    _abortCountdownTimer?.cancel();
    isGameActive = false;

    _recordGameStats(winner);

    final myColor = widget.isOnlineGame ? widget.onlinePlayerColor : 'white';
    final isDraw = winner == null;
    final isMeWinner = winner != null && (widget.isOnlineGame || widget.isAIGame ? winner == myColor : true);

    final Color dialogAccentColor = isDraw
        ? Colors.blueAccent
        : (isMeWinner ? Colors.amber : const Color(0xFFEF4444));

    final String dialogIcon = isDraw
        ? '🤝'
        : (isMeWinner ? (isCheckmate ? '👑' : '🏆') : '💔');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: dialogAccentColor,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: dialogAccentColor.withValues(alpha: 0.35),
                blurRadius: 25,
                spreadRadius: 5,
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dialogAccentColor.withValues(alpha: 0.2),
                  border: Border.all(
                    color: dialogAccentColor,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    dialogIcon,
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  color: dialogAccentColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Moves', style: TextStyle(color: Colors.white60, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('$moveCount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    Container(width: 1, height: 30, color: Colors.white24),
                    Column(
                      children: [
                        const Text('White Lost', style: TextStyle(color: Colors.white60, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text('$whiteCapturedPieces', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    Container(width: 1, height: 30, color: Colors.white24),
                    Column(
                      children: [
                        const Text('Black Lost', style: TextStyle(color: Colors.white60, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text('$blackCapturedPieces', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 16),
              // Tombol Analisis Game
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.insights_rounded, size: 20),
                  label: const Text(
                    'Game Analysis (Review Moves) 📊',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1), // Indigo
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _openGameAnalysis();
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Tombol View Board (Play Again dihapus sesuai permintaan user)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.grid_on_rounded, size: 20, color: Colors.white70),
                  label: const Text(
                    'View Board',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white70),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white30),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.home_rounded, size: 20, color: Colors.white),
                  label: const Text(
                    'Return to Main Menu',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB), // Vibrant Royal Blue
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                    shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.5),
                  ),
                  onPressed: () {
                    if (widget.isOnlineGame && widget.onlineMatchId != null) {
                      ChessOnlineService.finalizeMatchAndChallenge(widget.onlineMatchId!);
                    }
                    Navigator.of(context, rootNavigator: true).pop();
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    ).then((_) {
      _isGameOverDialogShowing = false;
    });
  }

  void _recordGameStats(String? winner) {
    if (_recordedGameMoves.isEmpty) return;

    final myColor = widget.isOnlineGame ? widget.onlinePlayerColor : 'white';
    String result = 'draw';
    if (winner != null) {
      result = (winner == myColor) ? 'win' : 'loss';
    }

    final opponent = widget.isAIGame
        ? 'Sentient Bot (${widget.aiDifficulty ?? "Med"})'
        : widget.isOnlineGame
            ? (widget.onlineOpponentName ?? 'Online Opponent')
            : 'Player 2';

    final mode = widget.isAIGame
        ? 'vs Bot AI'
        : widget.isOnlineGame
            ? 'Online Multiplayer'
            : 'vs Friend (Local)';

    final report = GameAnalysisReport.analyzeGame(
      recordedMoves: _recordedGameMoves,
      whitePlayerName: 'White',
      blackPlayerName: 'Black',
      winner: winner,
    );

    final isWhite = myColor == 'white';
    final myAccuracy = isWhite ? report.whiteAccuracy : report.blackAccuracy;
    final blunders = isWhite ? report.whiteBlunder : report.blackBlunder;
    final good = isWhite ? report.whiteGood : report.blackGood;
    final brilliant = isWhite ? report.whiteBrilliant : report.blackBrilliant;
    final normal = isWhite ? report.whiteNormal : report.blackNormal;

    ChessStatsService.recordMatchResult(
      opponent: opponent,
      result: result,
      movesCount: moveCount,
      accuracy: myAccuracy,
      mode: mode,
      blunders: blunders,
      goodMoves: good,
      brilliantMoves: brilliant,
      normalMoves: normal,
    );
  }

  void _openGameAnalysis() {
    if (_recordedGameMoves.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No moves recorded yet for analysis.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final myName = userProvider.userData?['username']?.toString() ?? 'Player';

    String whiteName = myName;
    String blackName = 'Sentient Bot';

    if (widget.isAIGame) {
      whiteName = myName;
      blackName = 'Sentient Bot (${widget.aiDifficulty ?? "Med"})';
    } else if (widget.isOnlineGame) {
      if (widget.onlinePlayerColor == 'white') {
        whiteName = myName;
        blackName = widget.onlineOpponentName ?? 'Online Opponent';
      } else {
        whiteName = widget.onlineOpponentName ?? 'Online Opponent';
        blackName = myName;
      }
    } else {
      whiteName = '$myName (White)';
      blackName = 'Player 2 (Black)';
    }

    final report = GameAnalysisReport.analyzeGame(
      recordedMoves: _recordedGameMoves,
      whitePlayerName: whiteName,
      blackPlayerName: blackName,
      winner: winner,
    );

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ChessGameAnalysisDialog(
        report: report,
        whitePlayerName: whiteName,
        blackPlayerName: blackName,
      ),
    );
  }

  void _executeMove(int fromRow, int fromCol, int toRow, int toCol) {
    final movingPiece = board[fromRow][fromCol];
    final capturedPiece = board[toRow][toCol];

    // Save snapshot for Undo
    _moveSnapshots.add({
      'board': board.map((r) => List<String>.from(r)).toList(),
      'currentPlayer': currentPlayer,
      'whiteCapturedList': List<String>.from(whiteCapturedList),
      'blackCapturedList': List<String>.from(blackCapturedList),
      'whiteCapturedPieces': whiteCapturedPieces,
      'blackCapturedPieces': blackCapturedPieces,
      'moveHistory': List<String>.from(moveHistory),
      'moveCount': moveCount,
      'isCheck': isCheck,
      'checkedKingPos': checkedKingPos != null ? List<int>.from(checkedKingPos!) : null,
    });

    if (capturedPiece.isNotEmpty) {
      if (_isWhitePiece(capturedPiece)) {
        // Black captures White piece
        blackCapturedList.add(capturedPiece);
        blackCapturedPieces++;
      } else {
        // White captures Black piece
        whiteCapturedList.add(capturedPiece);
        whiteCapturedPieces++;
      }
    }

    // Pawn Promotion
    String finalPiece = movingPiece;
    if (movingPiece == '♙' && toRow == 0) {
      finalPiece = '♕';
    } else if (movingPiece == '♟' && toRow == 7) {
      finalPiece = '♛';
    }

    String moveNotation = '${board[fromRow][fromCol]}${String.fromCharCode(97 + fromCol)}${8 - fromRow} → ${String.fromCharCode(97 + toCol)}${8 - toRow}';

    setState(() {
      board[toRow][toCol] = finalPiece;
      board[fromRow][fromCol] = '';
      selectedPiece = null;
      selectedRow = null;
      selectedCol = null;
      hintFromRow = null;
      hintFromCol = null;
      hintToRow = null;
      hintToCol = null;
      currentPlayer = currentPlayer == 'white' ? 'black' : 'white';
      moveCount++;
    });

    _pulseController.reverse();

    // Check notation suffix
    final isCurrentWhite = currentPlayer == 'white';
    final inCheck = _isKingInCheck(isCurrentWhite, board);
    final legalMoves = _getAllLegalMoves(isCurrentWhite);

    if (inCheck && legalMoves.isEmpty) {
      moveNotation += '#';
    } else if (inCheck) {
      moveNotation += '+';
    }

    setState(() {
      moveHistory.add(moveNotation);
    });

    final movePlayer = !isCurrentWhite ? 'white' : 'black';
    _recordedGameMoves.add({
      'player': movePlayer,
      'piece': movingPiece,
      'fromRow': fromRow,
      'fromCol': fromCol,
      'toRow': toRow,
      'toCol': toCol,
      'captured': capturedPiece.isNotEmpty ? capturedPiece : null,
      'notation': moveNotation,
      'isCheck': inCheck,
      'isCheckmate': inCheck && legalMoves.isEmpty,
      'boardAfter': board.map((r) => List<String>.from(r)).toList(),
    });

    _updateGameStatus();
    _abortCountdownTimer?.cancel();

    // Online move sync
    if (widget.isOnlineGame && widget.onlineMatchId != null) {
      ChessOnlineService.sendOnlineMove(
        matchId: widget.onlineMatchId!,
        board: board,
        nextTurn: currentPlayer,
        whiteCaptured: whiteCapturedList,
        blackCaptured: blackCapturedList,
        moveHistory: moveHistory,
        lastMove: {
          'fromRow': fromRow,
          'fromCol': fromCol,
          'toRow': toRow,
          'toCol': toCol,
          'piece': movingPiece,
        },
        status: isCheckmate ? 'checkmate' : (isStalemate ? 'stalemate' : 'ongoing'),
        winner: winner,
        whiteTimeRemaining: _whiteTimeRemaining,
        blackTimeRemaining: _blackTimeRemaining,
      );
    }

    // AI move
    if (widget.isAIGame && currentPlayer == 'black' && isGameActive) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && isGameActive) {
          _makeAIMove();
        }
      });
    }
  }

  void _onCellTap(int row, int col) {
    if (!isGameActive || _isAIThinking) return;

    // Online turn restriction
    if (widget.isOnlineGame && currentPlayer != widget.onlinePlayerColor) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏳ Opponent\'s turn to move...'),
          duration: Duration(milliseconds: 800),
        ),
      );
      return;
    }

    if (selectedPiece == null) {
      if (board[row][col].isNotEmpty) {
        final piece = board[row][col];
        final isWhitePiece = _isWhitePiece(piece);
        final isCurrentPlayerWhite = currentPlayer == 'white';

        if (isWhitePiece == isCurrentPlayerWhite) {
          // Check if this piece has legal moves
          bool pieceHasLegalMove = false;
          for (int r = 0; r < 8; r++) {
            for (int c = 0; c < 8; c++) {
              if (_isLegalMove(row, col, r, c)) {
                pieceHasLegalMove = true;
                break;
              }
            }
            if (pieceHasLegalMove) break;
          }

          setState(() {
            selectedPiece = piece;
            selectedRow = row;
            selectedCol = col;
          });
          _pulseController.forward();

          if (isCheck && !pieceHasLegalMove) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your King is in CHECK! Move the King, block the attack, or capture the attacking piece.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Color(0xFFC62828),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } else {
      if (selectedRow == row && selectedCol == col) {
        setState(() {
          selectedPiece = null;
          selectedRow = null;
          selectedCol = null;
        });
        _pulseController.reverse();
      } else if (_isLegalMove(selectedRow!, selectedCol!, row, col)) {
        _executeMove(selectedRow!, selectedCol!, row, col);
      } else {
        final targetPiece = board[row][col];
        if (targetPiece.isNotEmpty && _isWhitePiece(targetPiece) == (currentPlayer == 'white')) {
          setState(() {
            selectedPiece = targetPiece;
            selectedRow = row;
            selectedCol = col;
          });
          _pulseController.forward();
        } else {
          if (isCheck) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Illegal move! Respond to the check threat first.'),
                backgroundColor: Color(0xFFC62828),
                duration: Duration(milliseconds: 1500),
              ),
            );
          }
          setState(() {
            selectedPiece = null;
            selectedRow = null;
            selectedCol = null;
          });
          _pulseController.reverse();
        }
      }
    }
  }

  void _resetGame() {
    setState(() {
      _initializeBoard();
      _isGameOverDialogShowing = false;
      currentPlayer = 'white';
      selectedPiece = null;
      selectedRow = null;
      selectedCol = null;
      hintFromRow = null;
      hintFromCol = null;
      hintToRow = null;
      hintToCol = null;
      isGameActive = true;
      isCheck = false;
      checkedKingPos = null;
      isCheckmate = false;
      isStalemate = false;
      winner = null;
      gameStatus = 'White to move';
      whiteCapturedPieces = 0;
      blackCapturedPieces = 0;
      whiteCapturedList.clear();
      blackCapturedList.clear();
      _moveSnapshots.clear();
      _recordedGameMoves.clear();
      moveHistory.clear();
      moveCount = 0;
    });
    _pulseController.reset();
    _updateGameStatus();
  }

  void _performUndo() {
    if (_isAIThinking) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for the bot to finish thinking...'), duration: Duration(milliseconds: 800)),
      );
      return;
    }

    if (!isGameActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Game is already over.'), duration: Duration(milliseconds: 1000)),
      );
      return;
    }

    if (_moveSnapshots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No moves to undo yet.'), duration: Duration(milliseconds: 1000)),
      );
      return;
    }

    // In AI mode, if it's White's turn, undo 2 steps (AI's move and player's move)
    int stepsToUndo = widget.isAIGame ? (currentPlayer == 'white' && _moveSnapshots.length >= 2 ? 2 : 1) : 1;

    Map<String, dynamic> snapshot = _moveSnapshots.removeLast();
    if (_recordedGameMoves.isNotEmpty) {
      _recordedGameMoves.removeLast();
    }
    if (stepsToUndo == 2 && _moveSnapshots.isNotEmpty) {
      snapshot = _moveSnapshots.removeLast();
      if (_recordedGameMoves.isNotEmpty) {
        _recordedGameMoves.removeLast();
      }
    }

    setState(() {
      board = (snapshot['board'] as List).map((r) => List<String>.from(r as List)).toList();
      currentPlayer = snapshot['currentPlayer'] as String;
      whiteCapturedList = List<String>.from(snapshot['whiteCapturedList'] as List);
      blackCapturedList = List<String>.from(snapshot['blackCapturedList'] as List);
      whiteCapturedPieces = snapshot['whiteCapturedPieces'] as int;
      blackCapturedPieces = snapshot['blackCapturedPieces'] as int;
      moveHistory = List<String>.from(snapshot['moveHistory'] as List);
      moveCount = snapshot['moveCount'] as int;
      isCheck = snapshot['isCheck'] as bool;
      checkedKingPos = snapshot['checkedKingPos'] != null ? List<int>.from(snapshot['checkedKingPos'] as List) : null;
      selectedPiece = null;
      selectedRow = null;
      selectedCol = null;
      hintFromRow = null;
      hintFromCol = null;
      hintToRow = null;
      hintToCol = null;
    });

    _updateGameStatus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('↩️ Move undone successfully!'),
        backgroundColor: Color(0xFF1976D2),
        duration: Duration(milliseconds: 1000),
      ),
    );
  }

  void _showHint() async {
    if (!isGameActive || _isAIThinking || widget.isOnlineGame || !widget.isAIGame) return;

    final isWhite = currentPlayer == 'white';
    final boardSnapshot = board.map((r) => List<String>.from(r)).toList();

    Map<String, int>? best;
    try {
      best = await compute(ChessAIService.computeHintMove, {
        'board': boardSnapshot,
        'isWhite': isWhite,
      });
    } catch (e) {
      debugPrint('Error computing hint: $e');
    }

    if (!mounted || best == null || !isGameActive) return;

    setState(() {
      hintFromRow = best!['fromRow'];
      hintFromCol = best['fromCol'];
      hintToRow = best['toRow'];
      hintToCol = best['toCol'];
      selectedRow = hintFromRow;
      selectedCol = hintFromCol;
      selectedPiece = board[hintFromRow!][hintFromCol!];
    });

    final fromNotation = '${String.fromCharCode(97 + hintFromCol!)}${8 - hintFromRow!}';
    final toNotation = '${String.fromCharCode(97 + hintToCol!)}${8 - hintToRow!}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('💡 Move Suggestion: Move $selectedPiece from $fromNotation to $toNotation'),
        backgroundColor: const Color(0xFFF57F17),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmResign() {
    if (!isGameActive) return;

    // Jika pertandingan online dan belum ada langkah pertama, arahkan ke pembatalan tanpa penalti
    if (widget.isOnlineGame && moveCount == 0) {
      _confirmAbortMatch();
      return;
    }

    final canAbort = moveCount == 0 && widget.isOnlineGame;

    if (canAbort) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E2638),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Abort Match?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text(
            'No moves have been played yet. Aborting will cancel the match without affecting anyone\'s statistics or rating.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () {
                Navigator.pop(context);
                if (widget.onlineMatchId != null) {
                  ChessOnlineService.abortOnlineMatch(matchId: widget.onlineMatchId!);
                }
                setState(() {
                  isGameActive = false;
                  winner = null;
                  gameStatus = 'Match Aborted ⏱️';
                });
                _showGameOverDialog(
                  title: 'Game Aborted ⏱️',
                  subtitle: 'Match was aborted before any moves were played.',
                  winner: null,
                  isCheckmate: false,
                );
              },
              child: const Text('Abort Match', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2638),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Resign?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to resign? Your opponent will win the match.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);
              final myColor = widget.isOnlineGame
                  ? widget.onlinePlayerColor
                  : (widget.isAIGame ? 'white' : currentPlayer);
              final winColor = myColor == 'white' ? 'black' : 'white';

              setState(() {
                isGameActive = false;
                winner = winColor;
                gameStatus = winColor == 'white' ? 'White Wins (Resignation)' : 'Black Wins (Resignation)';
              });

              if (widget.isOnlineGame && widget.onlineMatchId != null) {
                ChessOnlineService.resignOnlineMatch(
                  matchId: widget.onlineMatchId!,
                  winnerColor: winColor,
                );
              }

              _showGameOverDialog(
                title: widget.isOnlineGame ? 'Defeat' : 'Game Over',
                subtitle: widget.isOnlineGame ? 'You resigned from the match.' : '$gameStatus!',
                winner: winColor,
                isCheckmate: false,
              );
            },
            child: const Text('Resign', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CHESS.COM STYLE CHESS CLOCK & TIMEOUT SYSTEM
  // ==========================================

  void _startChessClockTimer() {
    if (_isUntimed) return;
    _chessClockTimer?.cancel();
    _chessClockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (!isGameActive || isCheckmate || isStalemate) {
        return;
      }
      // Jangan kurangi waktu sebelum langkah pertama dilakukan (aturan standar Chess.com)
      if (moveCount == 0) {
        return;
      }

      if (currentPlayer == 'white') {
        if (_whiteTimeRemaining > 0) {
          setState(() {
            _whiteTimeRemaining--;
          });
        } else {
          timer.cancel();
          _handleTimeout('black'); // Waktu Putih habis -> Hitam menang
        }
      } else {
        if (_blackTimeRemaining > 0) {
          setState(() {
            _blackTimeRemaining--;
          });
        } else {
          timer.cancel();
          _handleTimeout('white'); // Waktu Hitam habis -> Putih menang
        }
      }
    });
  }

  void _handleTimeout(String winningColor) {
    if (!isGameActive) return;
    _chessClockTimer?.cancel();
    _abortCountdownTimer?.cancel();

    final isWhiteWinner = winningColor == 'white';
    final winningName = isWhiteWinner ? 'White' : 'Black';

    setState(() {
      isGameActive = false;
      winner = winningColor;
      gameStatus = '$winningName Wins on Time! ⏱️🏆';
    });

    if (widget.isOnlineGame && widget.onlineMatchId != null) {
      ChessOnlineService.timeoutMatch(
        matchId: widget.onlineMatchId!,
        winner: winningColor,
      );
    }

    final isMeWinner = widget.isOnlineGame
        ? widget.onlinePlayerColor == winningColor
        : winningColor == 'white';

    _showGameOverDialog(
      title: 'Time\'s Up! ⏱️',
      subtitle: isMeWinner
          ? 'Opponent ran out of time! You win this chess match on time! 🏆'
          : 'You ran out of time! Opponent wins on time.',
      winner: winningColor,
      isCheckmate: false,
    );
  }

  Widget _buildUntimedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12, width: 1.0),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.all_inclusive_rounded, size: 13, color: Colors.cyanAccent),
          SizedBox(width: 4),
          Text(
            'No Timer',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChessClockBadge({
    required int secondsRemaining,
    required bool isTurn,
    required bool isDanger,
  }) {
    final isLowTime = secondsRemaining <= 30 && secondsRemaining > 0;
    final isOutOfTime = secondsRemaining <= 0;
    final minutes = secondsRemaining ~/ 60;
    final seconds = secondsRemaining % 60;
    final timeFormatted =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    Color bgColor;
    Color textColor;
    Color borderColor;

    if (isOutOfTime) {
      bgColor = Colors.red.shade900.withValues(alpha: 0.85);
      textColor = Colors.white;
      borderColor = Colors.redAccent;
    } else if (isLowTime && isTurn) {
      bgColor = Colors.red.shade900.withValues(alpha: 0.65);
      textColor = Colors.redAccent.shade100;
      borderColor = Colors.redAccent;
    } else if (isTurn) {
      bgColor = const Color(0xFF0F766E).withValues(alpha: 0.85); // Emerald highlight
      textColor = Colors.white;
      borderColor = const Color(0xFF2DD4BF);
    } else {
      bgColor = const Color(0xFF0F172A).withValues(alpha: 0.85);
      textColor = Colors.white70;
      borderColor = Colors.white12;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: isTurn ? 1.8 : 1.0),
        boxShadow: isTurn
            ? [
                BoxShadow(
                  color: borderColor.withValues(alpha: 0.35),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLowTime ? Icons.warning_amber_rounded : Icons.timer_outlined,
            size: 13,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            timeFormatted,
            style: TextStyle(
              color: textColor,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  void _startAbortTimer() {
    _abortCountdownTimer?.cancel();
    _abortSecondsRemaining = 60;
    _abortCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (moveCount > 0 || !isGameActive) {
        timer.cancel();
        return;
      }
      if (_abortSecondsRemaining > 0) {
        setState(() {
          _abortSecondsRemaining--;
        });
      } else {
        timer.cancel();
        _autoAbortGame();
      }
    });
  }

  void _autoAbortGame() {
    if (widget.isOnlineGame && widget.onlineMatchId != null && moveCount == 0 && isGameActive) {
      _executeAbortMatch();
    }
  }

  void _confirmAbortMatch() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2638),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.timer_off_outlined, color: Colors.amberAccent, size: 24),
            SizedBox(width: 8),
            Text(
              'Abort Match?',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Opponent has not made their first move yet. You can fairly abort this match without rating loss or penalty.',
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Wait', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.close_rounded, size: 16),
            label: const Text('Abort Match ❌'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              _executeAbortMatch();
            },
          ),
        ],
      ),
    );
  }

  void _executeAbortMatch() async {
    _abortCountdownTimer?.cancel();
    if (!isGameActive) return;

    setState(() {
      isGameActive = false;
      winner = null;
      gameStatus = 'Game Aborted ⏱️';
    });

    _showGameOverDialog(
      title: 'Game Aborted ⏱️',
      subtitle: 'Match was fairly aborted because the first move was not made within the time limit.',
      winner: null,
      isCheckmate: false,
    );

    if (widget.onlineMatchId != null) {
      await ChessOnlineService.abortOnlineMatch(matchId: widget.onlineMatchId!);
    }
  }

  Widget _buildOpponentDisconnectedBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF991B1B).withValues(alpha: 0.95),
            const Color(0xFFDC2626).withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Opponent Disconnected! ⚠️',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Auto-claiming victory in 0:${_disconnectSecondsRemaining.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF991B1B),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _claimAbandonmentVictory,
            child: const Text('Claim Win 🏆', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Bubble mengambang untuk reaksi pemain lawan (Top Opponent)
  Widget _buildReactionBubble(String text, {required bool isTop}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.7, end: 1.0),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF134E4A)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(2),
                bottomRight: Radius.circular(14),
              ),
              border: Border.all(
                color: Colors.cyanAccent.withValues(alpha: 0.9),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyan.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chat_bubble_rounded, size: 12, color: Colors.cyanAccent),
                const SizedBox(width: 6),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Bagian khusus / wadah tetap di bawah profil musuh/lawan untuk reaksi & emot lawan
  Widget _buildTopReactionSection() {
    if (!widget.isOnlineGame) return const SizedBox.shrink();
    final bool hasReaction = _topReactionText != null && _topReactionText!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      height: 44,
      decoration: BoxDecoration(
        color: hasReaction
            ? const Color(0xFF134E4A).withValues(alpha: 0.85)
            : const Color(0xFF141C2E).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasReaction
              ? Colors.cyanAccent
              : Colors.white.withValues(alpha: 0.1),
          width: hasReaction ? 1.5 : 1.0,
        ),
        boxShadow: hasReaction
            ? [
                BoxShadow(
                  color: Colors.cyanAccent.withValues(alpha: 0.25),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              ),
              child: child,
            ),
          );
        },
        child: hasReaction
            ? _buildActiveTopReactionContent(_topReactionText!)
            : _buildIdleTopReactionContent(),
      ),
    );
  }

  Widget _buildActiveTopReactionContent(String text) {
    return Container(
      key: ValueKey<String>('top_active_$text'),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.cyanAccent.withValues(alpha: 0.2),
              border: Border.all(color: Colors.cyanAccent, width: 1),
            ),
            child: const Icon(Icons.chat_bubble_rounded, size: 12, color: Colors.cyanAccent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                _topReactionText = null;
                _topReactionTimer?.cancel();
              });
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, size: 14, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleTopReactionContent() {
    final opponentLabel = widget.onlineOpponentName ?? 'Opponent';

    return Container(
      key: const ValueKey<String>('top_idle_remote'),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.tealAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.tealAccent.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.wifi_tethering_rounded,
                  size: 13,
                  color: Colors.tealAccent,
                ),
                const SizedBox(width: 5),
                Text(
                  opponentLabel,
                  style: const TextStyle(
                    color: Colors.tealAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Opponent Reactions & Live Emotes',
              style: TextStyle(color: Colors.white54, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Colors.greenAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          const Text('Live', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// Bagian khusus / wadah tetap di atas profil kita untuk reaksi & emot (Zero Layout Jitter / Naik Turun)
  Widget _buildBottomReactionSection() {
    if (!widget.isOnlineGame) return const SizedBox.shrink();
    final bool hasReaction = _bottomReactionText != null && _bottomReactionText!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      height: 44,
      decoration: BoxDecoration(
        color: hasReaction
            ? const Color(0xFF1E293B)
            : const Color(0xFF141C2E).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasReaction
              ? const Color(0xFF38BDF8)
              : Colors.white.withValues(alpha: 0.1),
          width: hasReaction ? 1.5 : 1.0,
        ),
        boxShadow: hasReaction
            ? [
                BoxShadow(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              ),
              child: child,
            ),
          );
        },
        child: hasReaction
            ? _buildActiveReactionContent(_bottomReactionText!)
            : _buildIdleReactionContent(),
      ),
    );
  }

  Widget _buildActiveReactionContent(String text) {
    return Container(
      key: ValueKey<String>('active_$text'),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
              border: Border.all(color: const Color(0xFF38BDF8), width: 1),
            ),
            child: const Icon(Icons.chat_bubble_rounded, size: 12, color: Color(0xFF38BDF8)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                _bottomReactionText = null;
                _bottomReactionTimer?.cancel();
              });
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, size: 14, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleReactionContent() {
    final quickEmojis = ['👏', '🔥', '👍', '😮', '🤝', '😎'];

    return Container(
      key: const ValueKey<String>('idle_reactions'),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          // Emote / Chat Pill
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: _showInGameChatSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_reaction_rounded, size: 13, color: Colors.cyanAccent),
                  SizedBox(width: 4),
                  Text(
                    'Emote',
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 1,
            height: 18,
            color: Colors.white12,
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          // Quick Emoji Bar (Responsive fitted down without overflow)
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: quickEmojis.map((emoji) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      if (widget.isOnlineGame && widget.onlineMatchId != null) {
                        ChessOnlineService.sendInGameReaction(
                          matchId: widget.onlineMatchId!,
                          senderId: ChessOnlineService.currentUserId ?? '',
                          senderColor: widget.onlinePlayerColor,
                          emoji: emoji,
                        );
                      }
                      _showPlayerReaction(emoji, isTop: false);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 19),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // More Reactions button
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: _showInGameChatSheet,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.more_horiz_rounded, size: 16, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineAbortCountdownBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7C2D12).withValues(alpha: 0.9),
            const Color(0xFFC2410C).withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amberAccent, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.25),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: Colors.amberAccent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Waiting for First Move...',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Time remaining: $_abortSecondsRemaining seconds',
                  style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.close_rounded, size: 14),
            label: const Text('Abort', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFC2410C),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _confirmAbortMatch,
          ),
        ],
      ),
    );
  }

  void _confirmOfferDraw() {
    if (!isGameActive) return;

    if (widget.isOnlineGame) {
      _showOnlineDrawOfferDialog();
    } else if (widget.isAIGame) {
      _handleAIDrawOffer();
    } else {
      _handleFriendDrawOffer();
    }
  }

  void _handleAIDrawOffer() {
    if (moveCount < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draw offer is too early (at least 6 moves must be played).'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Evaluasi posisi catur: score > 0 berarti Hitam (Bot) unggul, score < 0 berarti Putih unggul
    final evalScore = _evaluateBoard(board);

    // Jika bot unggul signifikan (score > 250), bot menolak remis
    if (evalScore > 250) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E2638),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Text('🤖', style: TextStyle(fontSize: 24)),
              SizedBox(width: 8),
              Text(
                'Offer Declined',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: const Text(
            'Bot declined the draw offer as it evaluates its position as favorable and wishes to continue.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue Playing', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    // Bot menerima remis
    setState(() {
      isGameActive = false;
      winner = null;
      gameStatus = 'Draw by Mutual Agreement 🤝';
    });

    _showGameOverDialog(
      title: 'DRAW 🤝',
      subtitle: 'Bot accepted the draw offer! The game ends in a fair draw.',
      winner: null,
      isCheckmate: false,
    );
  }

  void _handleFriendDrawOffer() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2638),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.handshake_rounded, color: Colors.cyanAccent, size: 24),
            SizedBox(width: 8),
            Text('Offer Draw? 🤝', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Do both players (White & Black) agree to conclude this match with a draw?',
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Playing', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.handshake_rounded, size: 16),
            label: const Text('Agree to Draw 🤝'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                isGameActive = false;
                winner = null;
                gameStatus = 'Draw by Mutual Agreement 🤝';
              });

              _showGameOverDialog(
                title: 'DRAW 🤝',
                subtitle: 'Both players agreed to end the game in a draw.',
                winner: null,
                isCheckmate: false,
              );
            },
          ),
        ],
      ),
    );
  }

  void _showOnlineDrawOfferDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2638),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.handshake_rounded, color: Colors.cyanAccent, size: 24),
            SizedBox(width: 8),
            Text('Offer Draw? 🤝', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          'A draw offer will be sent to ${widget.onlineOpponentName ?? "opponent"}. If accepted, the game will conclude as a draw.',
          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Send Offer 🤝'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              if (widget.onlineMatchId != null) {
                ChessOnlineService.offerOnlineDraw(
                  matchId: widget.onlineMatchId!,
                  playerColor: widget.onlinePlayerColor,
                );
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Draw offer sent to opponent... ⏳'),
                  backgroundColor: Color(0xFF1E3A8A),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showIncomingDrawOfferDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2638),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.handshake_rounded, color: Colors.cyanAccent, size: 24),
            SizedBox(width: 8),
            Text(
              'Draw Offer 🤝',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          '${widget.onlineOpponentName ?? "Opponent"} offered a draw. Do you agree to end this match in a tie?',
          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _isDrawOfferDialogShowing = false;
              if (widget.onlineMatchId != null) {
                ChessOnlineService.declineOnlineDraw(matchId: widget.onlineMatchId!);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('You declined the draw offer. Match resumed!'),
                  backgroundColor: Colors.blueAccent,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Decline', style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.handshake_rounded, size: 16),
            label: const Text('Accept Draw 🤝'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _isDrawOfferDialogShowing = false;
              if (widget.onlineMatchId != null) {
                ChessOnlineService.acceptOnlineDraw(matchId: widget.onlineMatchId!);
              }
            },
          ),
        ],
      ),
    );
  }

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

  int _evaluateBoard(List<List<String>> b) {
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

    if (_isKingInCheck(true, b)) score += 40;
    if (_isKingInCheck(false, b)) score -= 40;

    return score;
  }

  void _makeAIMove() async {
    if (!isGameActive || currentPlayer != 'black' || _isAIThinking) return;

    setState(() {
      _isAIThinking = true;
    });

    final stopwatch = Stopwatch()..start();
    final boardSnapshot = board.map((r) => List<String>.from(r)).toList();
    final diff = widget.aiDifficulty?.toLowerCase() ?? 'easy';

    Map<String, int>? selectedMove;
    try {
      selectedMove = await compute(ChessAIService.computeAIMove, {
        'board': boardSnapshot,
        'difficulty': diff,
      });
    } catch (e) {
      debugPrint('Error computing AI move in background isolate: $e');
    }

    // Realistic thinking time so the bot's clock visibly ticks down naturally (like Chess.com)
    final minThinkingTime = diff == 'easy' 
        ? 800 
        : (diff == 'medium' ? 1200 : (diff == 'hard' ? 1600 : 2200));
    final elapsed = stopwatch.elapsedMilliseconds;
    if (elapsed < minThinkingTime) {
      await Future.delayed(Duration(milliseconds: minThinkingTime - elapsed));
    }

    if (!mounted) return;
    setState(() {
      _isAIThinking = false;
    });

    if (!isGameActive || currentPlayer != 'black') return;

    if (selectedMove != null) {
      _executeMove(
        selectedMove['fromRow']!,
        selectedMove['fromCol']!,
        selectedMove['toRow']!,
        selectedMove['toCol']!,
      );
    } else {
      _updateGameStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showBackConfirmation();
      },
      child: Scaffold(
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
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      children: [
                        if (widget.isOnlineGame && moveCount == 0 && isGameActive)
                          _buildOnlineAbortCountdownBanner(),
                        if (widget.isOnlineGame && _isOpponentDisconnected && isGameActive)
                          _buildOpponentDisconnectedBanner(),
                        if (isCheck && isGameActive) _buildCheckAlertBanner(),
                        _buildTopPlayerCard(context),
                        if (widget.isOnlineGame) _buildTopReactionSection(),
                        _buildChessBoard(),
                        if (widget.isOnlineGame) _buildBottomReactionSection(),
                        _buildBottomPlayerCard(context),
                        _buildMoveHistoryTape(),
                        _buildBottomControls(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _showBackConfirmation,
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const ChessPieceWidget(piece: '♔', size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Sentient Chess',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.blue,
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const ChessPieceWidget(piece: '♚', size: 24),
                ],
              ),
            ),
          ),
          const SizedBox(width: 48), // Balance back button so title stays precisely centered
        ],
      ),
    );
  }

  void _showBackConfirmation() {
    // Jika permainan sudah berakhir (game over / aborted / resigned), langsung keluar tanpa dialog konfirmasi
    if (!isGameActive) {
      if (widget.isOnlineGame && widget.onlineMatchId != null) {
        ChessOnlineService.finalizeMatchAndChallenge(widget.onlineMatchId!);
      }
      Navigator.pop(context);
      return;
    }

    final isOnlineActive = widget.isOnlineGame && isGameActive;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
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
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: (isOnlineActive ? Colors.red : Colors.blue).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: (isOnlineActive ? Colors.redAccent : Colors.blue).withValues(alpha: 0.5)),
                ),
                child: Icon(
                  isOnlineActive ? Icons.flag_rounded : Icons.home_outlined,
                  size: 30,
                  color: isOnlineActive ? Colors.redAccent : Colors.blue,
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              Text(
                isOnlineActive ? 'Leave & Resign Match?' : 'Return to Home?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Description
              Text(
                isOnlineActive
                    ? 'Leaving an active online match will be counted as a Resignation (Menyerah). Your opponent will automatically win the game.'
                    : 'Are you sure you want to return to the Sentient home screen? Current game progress will be lost.',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.pop(context),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isOnlineActive
                              ? [const Color(0xFFE53935), const Color(0xFFC62828)]
                              : [const Color(0xFF4CAF50), const Color(0xFF45a049)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (isOnlineActive ? Colors.red : Colors.green).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.pop(context); // Close dialog
                            if (isOnlineActive && widget.onlineMatchId != null) {
                              if (moveCount == 0) {
                                ChessOnlineService.abortOnlineMatch(matchId: widget.onlineMatchId!);
                              } else {
                                final opponentColor = widget.onlinePlayerColor == 'white' ? 'black' : 'white';
                                ChessOnlineService.resignOnlineMatch(
                                  matchId: widget.onlineMatchId!,
                                  winnerColor: opponentColor,
                                );
                              }
                            } else if (widget.isOnlineGame && widget.onlineMatchId != null) {
                              ChessOnlineService.finalizeMatchAndChallenge(widget.onlineMatchId!);
                            }
                            Navigator.pop(context); // Return to chess menu
                          },
                          child: Center(
                            child: Text(
                              isOnlineActive
                                  ? (moveCount == 0 ? 'Abort & Exit' : 'Resign & Exit')
                                  : 'Yes, Exit',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckAlertBanner() {
    final checkedColor = currentPlayer == 'white' ? 'White' : 'Black';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.redAccent, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withValues(alpha: 0.35),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 18),
          const SizedBox(width: 8),
          Text(
            '⚠️ CHECK! $checkedColor King in Danger!',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPlayerCard(BuildContext context) {
    final topColor = widget.isOnlineGame
        ? (widget.onlinePlayerColor == 'white' ? 'black' : 'white')
        : 'black';
    final isTopTurn = currentPlayer == topColor;
    final isTopInDanger = isCheck && isTopTurn;
    final topSeconds = topColor == 'white' ? _whiteTimeRemaining : _blackTimeRemaining;

    String opponentName = 'Sentient Bot';
    String opponentFlag = '🤖';
    Color difficultyColor = Colors.greenAccent;

    if (widget.isAIGame) {
      final diff = widget.aiDifficulty?.toLowerCase() ?? 'easy';
      switch (diff) {
        case 'easy':
          opponentName = 'Sentient Bot (Easy)';
          difficultyColor = Colors.greenAccent;
          opponentFlag = '🤖';
          break;
        case 'medium':
          opponentName = 'Sentient Bot (Med)';
          difficultyColor = Colors.orangeAccent;
          opponentFlag = '🧠';
          break;
        case 'hard':
          opponentName = 'Sentient Bot (Hard)';
          difficultyColor = Colors.redAccent;
          opponentFlag = '⚡';
          break;
        case 'grandmaster':
          opponentName = 'Sentient Bot (GM)';
          difficultyColor = Colors.purpleAccent;
          opponentFlag = '👑';
          break;
        default:
          opponentName = 'Sentient Bot';
          difficultyColor = Colors.blueAccent;
          opponentFlag = '🤖';
      }
    } else if (widget.isOnlineGame) {
      opponentName = widget.onlineOpponentName ?? 'Online Opponent';
      difficultyColor = Colors.cyanAccent;
      opponentFlag = '🌐';
    } else {
      opponentName = 'Player 2 (Black)';
      difficultyColor = Colors.amber;
      opponentFlag = '⚔️';
    }

    final isTopWhite = topColor == 'white';
    final topCapturedList = isTopWhite ? whiteCapturedList : blackCapturedList;
    final materialAdv = _getMaterialAdvantage(isTopWhite);

    final opponentAvatar = _remoteOpponentAvatar ?? widget.onlineOpponentAvatar;
    ImageProvider? opponentImageProvider;
    if (opponentAvatar != null && opponentAvatar.isNotEmpty) {
      opponentImageProvider = ImageHelper.getImageProvider(opponentAvatar);
    }

    final cardWidget = Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isTopTurn 
            ? const Color(0xFF1E2638) 
            : Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isTopInDanger 
              ? Colors.redAccent 
              : (isTopTurn ? difficultyColor : Colors.white12),
          width: isTopTurn ? 2.0 : 1.0,
        ),
        boxShadow: isTopTurn ? [
          BoxShadow(
            color: (isTopInDanger ? Colors.redAccent : difficultyColor).withValues(alpha: 0.25),
            blurRadius: 10,
            spreadRadius: 1,
          )
        ] : null,
      ),
      child: Row(
        children: [
          // Avatar Opponent
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0xFF25334D),
                  image: opponentImageProvider != null
                      ? DecorationImage(
                          image: opponentImageProvider,
                          fit: BoxFit.cover,
                        )
                      : null,
                  gradient: opponentImageProvider == null
                      ? LinearGradient(
                          colors: [
                            difficultyColor.withValues(alpha: 0.3),
                            const Color(0xFF0F172A),
                          ],
                        )
                      : null,
                  border: Border.all(color: difficultyColor.withValues(alpha: 0.6), width: 1.5),
                ),
                child: opponentImageProvider == null
                    ? Center(
                        child: widget.isAIGame
                            ? Icon(Icons.smart_toy_rounded, color: difficultyColor, size: 24)
                            : widget.isOnlineGame
                                ? const Icon(Icons.person_rounded, color: Colors.cyanAccent, size: 24)
                                : ChessPieceWidget(piece: topColor == 'white' ? '♔' : '♚', size: 28),
                      )
                    : null,
              ),
              if (isTopTurn)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: difficultyColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Name, Rating, Flag, and Captured Pieces
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        opponentName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(opponentFlag, style: const TextStyle(fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 3),
                // Captured pieces row dinamis sesuai warna lawan
                _buildCapturedRow(topCapturedList, materialAdv),
              ],
            ),
          ),
          // Chess.com style Clock & Turn Badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isUntimed)
                _buildUntimedBadge()
              else
                _buildChessClockBadge(
                  secondsRemaining: topSeconds,
                  isTurn: isTopTurn,
                  isDanger: isTopInDanger,
                ),
              if (isTopTurn) ...[
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isTopInDanger ? Colors.redAccent : difficultyColor).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isTopInDanger ? Colors.redAccent : difficultyColor,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.isAIGame)
                        const SizedBox(
                          width: 8,
                          height: 8,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: Colors.white70,
                          ),
                        )
                      else if (widget.isOnlineGame)
                        const Icon(Icons.wifi_tethering, size: 10, color: Colors.cyanAccent)
                      else
                        const Icon(Icons.flash_on, size: 10, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        isTopInDanger 
                            ? 'CHECK!' 
                            : (widget.isAIGame 
                                ? 'Thinking...' 
                                : (widget.isOnlineGame ? 'Opponent\'s Turn' : 'Turn')),
                        style: TextStyle(
                          color: isTopInDanger ? Colors.redAccent : Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    return cardWidget;
  }

  Widget _buildBottomPlayerCard(BuildContext context) {
    final bottomColor = widget.isOnlineGame
        ? widget.onlinePlayerColor
        : 'white';
    final isBottomTurn = currentPlayer == bottomColor;
    final isBottomInDanger = isCheck && isBottomTurn;
    final bottomSeconds = bottomColor == 'white' ? _whiteTimeRemaining : _blackTimeRemaining;
    final capturedList = bottomColor == 'white' ? whiteCapturedList : blackCapturedList;
    final materialAdv = _getMaterialAdvantage(bottomColor == 'white');

    final userProvider = Provider.of<UserProvider>(context);
    String username = 'Player';
    ImageProvider? avatarImage;

    if (userProvider.userData != null) {
      final rawName = userProvider.userData!['username'] ?? 'Player';
      username = rawName.toString().isNotEmpty ? rawName.toString() : 'Player';
      final rawAvatar = userProvider.userData!['avatar'];
      if (rawAvatar != null && rawAvatar.toString().isNotEmpty) {
        avatarImage = ImageHelper.getImageProvider(rawAvatar.toString());
      }
    }
    if (avatarImage == null && _remoteMyAvatar != null && _remoteMyAvatar!.isNotEmpty) {
      avatarImage = ImageHelper.getImageProvider(_remoteMyAvatar!);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isBottomTurn 
            ? const Color(0xFF1E2638) 
            : Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isBottomInDanger 
              ? Colors.redAccent 
              : (isBottomTurn ? Colors.amber : Colors.white12),
          width: isBottomTurn ? 2.0 : 1.0,
        ),
        boxShadow: isBottomTurn ? [
          BoxShadow(
            color: (isBottomInDanger ? Colors.redAccent : Colors.amber).withValues(alpha: 0.25),
            blurRadius: 10,
            spreadRadius: 1,
          )
        ] : null,
      ),
      child: Row(
        children: [
          // User Avatar
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0xFF25334D),
                  border: Border.all(
                    color: isBottomTurn ? Colors.amber : Colors.white24,
                    width: 1.5,
                  ),
                  image: avatarImage != null
                      ? DecorationImage(
                          image: avatarImage,
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: avatarImage == null
                    ? Center(
                        child: ChessPieceWidget(piece: bottomColor == 'white' ? '♔' : '♚', size: 28),
                      )
                    : null,
              ),
              if (isBottomTurn)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Name, Rating, Flag, and Captured Pieces
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('🇮🇩', style: TextStyle(fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 3),
                // Captured pieces row
                _buildCapturedRow(capturedList, materialAdv),
              ],
            ),
          ),
          // Chess.com style Clock & Turn Badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isUntimed)
                _buildUntimedBadge()
              else
                _buildChessClockBadge(
                  secondsRemaining: bottomSeconds,
                  isTurn: isBottomTurn,
                  isDanger: isBottomInDanger,
                ),
              if (isBottomTurn) ...[
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isBottomInDanger ? Colors.redAccent : Colors.amber).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isBottomInDanger ? Colors.redAccent : Colors.amber,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.touch_app, size: 10, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        isBottomInDanger ? 'CHECK!' : 'Your Turn',
                        style: TextStyle(
                          color: isBottomInDanger ? Colors.redAccent : Colors.amber.shade200,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCapturedRow(List<String> pieces, int advantage) {
    if (pieces.isEmpty) {
      return Text(
        'No pieces captured yet',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.35),
          fontSize: 11,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final sortedPieces = List<String>.from(pieces)
      ..sort((a, b) => _getPieceValue(b).compareTo(_getPieceValue(a)));

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: sortedPieces.map((p) {
                return Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: ChessPieceWidget(piece: p, size: 16),
                );
              }).toList(),
            ),
          ),
        ),
        if (advantage > 0) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '+$advantage',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChessBoard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      padding: const EdgeInsets.fromLTRB(4, 6, 6, 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2E241E), // Rich Walnut wooden outer frame
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCheck ? Colors.redAccent.withValues(alpha: 0.8) : const Color(0xFF5D4037),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isCheck 
                ? Colors.redAccent.withValues(alpha: 0.4) 
                : Colors.black.withValues(alpha: 0.6),
            blurRadius: 24,
            spreadRadius: 4,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Rank Coordinates (8 down to 1 or 1 up to 8 if flipped) aligned with board frame
                SizedBox(
                  width: 12,
                  child: Column(
                    children: List.generate(8, (i) => Expanded(
                      child: Center(
                        child: Text(
                          '${_isBoardFlipped ? (1 + i) : (8 - i)}',
                          style: const TextStyle(
                            color: Color(0xFFD7CCC8),
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )),
                  ),
                ),
                const SizedBox(width: 3),
                // 8x8 Chessboard Grid
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: Stack(
                        children: [
                          AnimatedBuilder(
                            animation: Listenable.merge([_pulseController, _glowController]),
                            builder: (context, child) {
                              return GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 8,
                                ),
                                itemCount: 64,
                                itemBuilder: (context, index) {
                                  final displayRow = index ~/ 8;
                                  final displayCol = index % 8;
                                  final row = _isBoardFlipped ? 7 - displayRow : displayRow;
                                  final col = _isBoardFlipped ? 7 - displayCol : displayCol;
                                  final isLight = (row + col) % 2 == 0;
                                  final isSelected = selectedRow == row && selectedCol == col;
                                  final isValidMove = selectedPiece != null && 
                                                    selectedRow != null && 
                                                    selectedCol != null && 
                                                    _isLegalMove(selectedRow!, selectedCol!, row, col);
                                  final isTargetPiece = board[row][col].isNotEmpty;
                                  final isKingInDanger = isCheck &&
                                      checkedKingPos != null &&
                                      checkedKingPos![0] == row &&
                                      checkedKingPos![1] == col;
                                  final isHint = (hintFromRow == row && hintFromCol == col) || (hintToRow == row && hintToCol == col);

                                  Color cellColor;
                                  if (isKingInDanger) {
                                    cellColor = Colors.red.withValues(alpha: 0.65 + 0.35 * _glowAnimation.value);
                                  } else if (isSelected) {
                                    cellColor = Colors.amber.withValues(alpha: _glowAnimation.value * 0.7 + 0.3);
                                  } else if (isHint) {
                                    cellColor = Colors.cyanAccent.withValues(alpha: 0.35);
                                  } else if (isValidMove) {
                                    cellColor = isTargetPiece 
                                        ? Colors.orange.withValues(alpha: 0.6) 
                                        : Colors.green.withValues(alpha: 0.35);
                                  } else {
                                    cellColor = isLight ? const Color(0xFFF0D9B5) : const Color(0xFFB58863);
                                  }

                                  Border cellBorder;
                                  if (isKingInDanger) {
                                    cellBorder = Border.all(color: Colors.redAccent, width: 2.5);
                                  } else if (isSelected) {
                                    cellBorder = Border.all(color: Colors.amber, width: 2.5);
                                  } else if (isHint) {
                                    cellBorder = Border.all(color: Colors.cyanAccent, width: 2.0);
                                  } else if (isValidMove) {
                                    cellBorder = Border.all(
                                      color: isTargetPiece ? Colors.orangeAccent : Colors.greenAccent, 
                                      width: 2.0,
                                    );
                                  } else {
                                    cellBorder = Border.all(color: Colors.transparent);
                                  }

                                  return GestureDetector(
                                    onTap: () => _onCellTap(row, col),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      decoration: BoxDecoration(
                                        color: cellColor,
                                        border: cellBorder,
                                        boxShadow: isKingInDanger
                                            ? [
                                                BoxShadow(
                                                  color: Colors.redAccent.withValues(alpha: _glowAnimation.value * 0.8),
                                                  blurRadius: 12,
                                                  spreadRadius: 2,
                                                ),
                                              ]
                                            : isSelected
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.amber.withValues(alpha: _glowAnimation.value * 0.5),
                                                      blurRadius: 10,
                                                      spreadRadius: 2,
                                                    ),
                                                  ]
                                                : isHint
                                                    ? [
                                                        BoxShadow(
                                                          color: Colors.cyanAccent.withValues(alpha: 0.6),
                                                          blurRadius: 10,
                                                          spreadRadius: 2,
                                                        ),
                                                      ]
                                                    : null,
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Move hint dot for empty squares
                                          if (isValidMove && !isTargetPiece)
                                            Container(
                                              width: 13,
                                              height: 13,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF4CAF50).withValues(alpha: 0.9),
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.green.withValues(alpha: 0.5),
                                                    blurRadius: 4,
                                                    spreadRadius: 1,
                                                  ),
                                                ],
                                              ),
                                            ),

                                          // Capture indicator ring on enemy piece
                                          if (isValidMove && isTargetPiece)
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: const Color(0xFFE53935).withValues(alpha: 0.85),
                                                  width: 2.5,
                                                ),
                                              ),
                                            ),

                                          // Warning badge icon for King in check
                                          if (isKingInDanger)
                                            Positioned(
                                              top: 2,
                                              right: 2,
                                              child: Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.warning, size: 10, color: Colors.white),
                                              ),
                                            ),

                                          // Beautiful High-Fidelity Staunton Chess Piece (Ukuran Diperbesar 44px)
                                          if (board[row][col].isNotEmpty)
                                            Center(
                                              child: Padding(
                                                padding: const EdgeInsets.all(1.0),
                                                child: AnimatedScale(
                                                  scale: isSelected ? _pulseAnimation.value : (isKingInDanger ? _pulseAnimation.value : 1.0),
                                                  duration: const Duration(milliseconds: 200),
                                                  child: FittedBox(
                                                    fit: BoxFit.contain,
                                                    child: ChessPieceWidget(
                                                      piece: board[row][col],
                                                      size: 44,
                                                      isSelected: isSelected,
                                                      isKingInDanger: isKingInDanger,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          // Bottom File Coordinates (a to h or h to a if flipped) aligned with board frame
          Padding(
            padding: const EdgeInsets.only(left: 15),
            child: SizedBox(
              height: 12,
              child: Row(
                children: List.generate(8, (i) => Expanded(
                  child: Center(
                    child: Text(
                      String.fromCharCode(97 + (_isBoardFlipped ? (7 - i) : i)),
                      style: const TextStyle(
                        color: Color(0xFFD7CCC8),
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoveHistoryTape() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_toggle_off, size: 16, color: Colors.amber),
          const SizedBox(width: 6),
          Text(
            'Moves ($moveCount):',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: moveHistory.isEmpty
                ? Text(
                    'No moves recorded yet',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                : SizedBox(
                    height: 24,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      reverse: true,
                      itemCount: moveHistory.length,
                      itemBuilder: (context, index) {
                        final moveIdx = moveHistory.length - 1 - index;
                        final moveText = moveHistory[moveIdx];
                        final isLatest = moveIdx == moveHistory.length - 1;

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isLatest 
                                ? Colors.amber.withValues(alpha: 0.25)
                                : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: isLatest ? Colors.amber : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${moveIdx + 1}. $moveText',
                            style: TextStyle(
                              color: isLatest ? Colors.amber.shade200 : Colors.white70,
                              fontSize: 11,
                              fontWeight: isLatest ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: !isGameActive
              ? (widget.isOnlineGame
                  ? [
                      if (_recordedGameMoves.isNotEmpty)
                        _buildActionButton(
                          icon: Icons.insights_rounded,
                          label: 'Analysis 📊',
                          color: Colors.indigoAccent,
                          onTap: _openGameAnalysis,
                        ),
                      _buildActionButton(
                        icon: Icons.arrow_back_rounded,
                        label: 'Back',
                        color: Colors.cyanAccent,
                        onTap: () {
                          if (widget.onlineMatchId != null) {
                            ChessOnlineService.finalizeMatchAndChallenge(widget.onlineMatchId!);
                          }
                          Navigator.pop(context);
                        },
                      ),
                    ]
                  : [
                      if (_recordedGameMoves.isNotEmpty)
                        _buildActionButton(
                          icon: Icons.insights_rounded,
                          label: 'Analysis 📊',
                          color: Colors.indigoAccent,
                          onTap: _openGameAnalysis,
                        ),
                      _buildActionButton(
                        icon: Icons.replay_rounded,
                        label: 'New Game',
                        color: Colors.greenAccent,
                        onTap: _resetGame,
                      ),
                      _buildActionButton(
                        icon: Icons.arrow_back_rounded,
                        label: 'Back',
                        color: Colors.white70,
                        onTap: () => Navigator.pop(context),
                      ),
                    ])
              : widget.isOnlineGame
                  ? [
                      _buildActionButton(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Reactions & Chat',
                        color: Colors.cyanAccent,
                        onTap: _showInGameChatSheet,
                      ),
                      _buildActionButton(
                        icon: Icons.handshake_rounded,
                        label: 'Draw',
                        color: Colors.cyanAccent,
                        onTap: _confirmOfferDraw,
                      ),
                      _buildActionButton(
                        icon: moveCount == 0 ? Icons.cancel_outlined : Icons.flag_rounded,
                        label: moveCount == 0 ? 'Abort' : 'Resign',
                        color: moveCount == 0 ? Colors.orangeAccent : Colors.redAccent,
                        onTap: moveCount == 0 ? _confirmAbortMatch : _confirmResign,
                      ),
                    ]
                  : [
                      _buildActionButton(
                        icon: Icons.undo_rounded,
                        label: 'Undo',
                        color: Colors.blueAccent,
                        onTap: _performUndo,
                      ),
                      if (widget.isAIGame)
                        _buildActionButton(
                          icon: Icons.lightbulb_rounded,
                          label: 'Hint',
                          color: Colors.amber,
                          onTap: _showHint,
                        ),
                      _buildActionButton(
                        icon: Icons.handshake_rounded,
                        label: 'Draw',
                        color: Colors.cyanAccent,
                        onTap: _confirmOfferDraw,
                      ),
                      _buildActionButton(
                        icon: Icons.replay_rounded,
                        label: 'New Game',
                        color: Colors.greenAccent,
                        onTap: _resetGame,
                      ),
                      _buildActionButton(
                        icon: Icons.flag_rounded,
                        label: 'Resign',
                        color: Colors.redAccent,
                        onTap: _confirmResign,
                      ),
                    ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInGameChatSheet() {
    final quickEmojis = ['🔥', '👏', '😎', '🤯', '🤝', '😂', '♟️', '👑'];
    final quickPhrases = [
      'Great move! 👏',
      'That was close! 😅',
      'Thanks for the game! 🤝',
      'Your turn ⏱️',
      'Checkmate incoming! 👑',
      'Exciting match! 🔥',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Colors.cyanAccent, width: 2),
          ),
        ),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
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
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.emoji_emotions_rounded, color: Colors.cyanAccent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Quick Reactions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Emoji grid (Responsive 4 items per row, 2 rows, perfectly fitted)
              LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 8.0;
                  final itemWidth = (constraints.maxWidth - (3 * spacing)) / 4;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: 10,
                    children: quickEmojis.map((emoji) {
                      return InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          if (widget.onlineMatchId != null) {
                            ChessOnlineService.sendInGameReaction(
                              matchId: widget.onlineMatchId!,
                              senderId: ChessOnlineService.currentUserId ?? '',
                              senderColor: widget.onlinePlayerColor,
                              emoji: emoji,
                            );
                          }
                          _showPlayerReaction(emoji, isTop: false);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: itemWidth,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Center(
                            child: Text(emoji, style: const TextStyle(fontSize: 24)),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, color: Colors.amberAccent, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Quick Messages',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: quickPhrases.map((phrase) {
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      if (widget.onlineMatchId != null) {
                        ChessOnlineService.sendInGameReaction(
                          matchId: widget.onlineMatchId!,
                          senderId: ChessOnlineService.currentUserId ?? '',
                          senderColor: widget.onlinePlayerColor,
                          message: phrase,
                        );
                      }
                      _showPlayerReaction(phrase, isTop: false);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        phrase,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}




