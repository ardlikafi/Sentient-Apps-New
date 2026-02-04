import 'package:flutter/material.dart';
import 'dart:math';

class ChessGameScreen extends StatefulWidget {
  final String? aiDifficulty;
  final bool isAIGame;
  
  const ChessGameScreen({
    super.key, 
    this.aiDifficulty, 
    this.isAIGame = false
  });

  @override
  State<ChessGameScreen> createState() => _ChessGameScreenState();
}

class _ChessGameScreenState extends State<ChessGameScreen> with TickerProviderStateMixin {
  late List<List<String>> board;
  String currentPlayer = 'white';
  String? selectedPiece;
  int? selectedRow;
  int? selectedCol;
  bool isGameActive = true;
  String gameStatus = 'White to move';
  int whiteCapturedPieces = 0;
  int blackCapturedPieces = 0;
  List<String> moveHistory = [];
  int moveCount = 0;
  
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
    _initializeBoard();
    _initializeAnimations();
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

  bool _isValidMove(int fromRow, int fromCol, int toRow, int toCol) {
    final piece = board[fromRow][fromCol];
    final targetPiece = board[toRow][toCol];
    
    if (piece.isEmpty) return false;
    
    final isWhitePiece = _isWhitePiece(piece);
    final isTargetWhite = targetPiece.isNotEmpty ? _isWhitePiece(targetPiece) : false;
    
    if (isWhitePiece == isTargetWhite) return false;
    
    final rowDiff = toRow - fromRow;
    final colDiff = toCol - fromCol;
    final absRowDiff = rowDiff.abs();
    final absColDiff = colDiff.abs();
    
    switch (piece.toLowerCase()) {
      case '♟': case '♙': // Pawn
        final direction = isWhitePiece ? -1 : 1;
        if (colDiff == 0 && targetPiece.isEmpty) {
          if (rowDiff == direction) return true;
          if ((fromRow == 6 && isWhitePiece) || (fromRow == 1 && !isWhitePiece)) {
            if (rowDiff == 2 * direction && board[fromRow + direction][fromCol].isEmpty) return true;
          }
        }
        if (absColDiff == 1 && rowDiff == direction && targetPiece.isNotEmpty) return true;
        return false;
        
      case '♖': case '♜': // Rook
        if (rowDiff == 0 || colDiff == 0) return _isPathClear(fromRow, fromCol, toRow, toCol);
        return false;
        
      case '♘': case '♞': // Knight
        return (absRowDiff == 2 && absColDiff == 1) || (absRowDiff == 1 && absColDiff == 2);
        
      case '♗': case '♝': // Bishop
        if (absRowDiff == absColDiff) return _isPathClear(fromRow, fromCol, toRow, toCol);
        return false;
        
      case '♕': case '♛': // Queen
        if (rowDiff == 0 || colDiff == 0 || absRowDiff == absColDiff) {
          return _isPathClear(fromRow, fromCol, toRow, toCol);
        }
        return false;
        
      case '♔': case '♚': // King
        return absRowDiff <= 1 && absColDiff <= 1;
        
      default:
        return false;
    }
  }

  bool _isPathClear(int fromRow, int fromCol, int toRow, int toCol) {
    final rowStep = toRow > fromRow ? 1 : (toRow < fromRow ? -1 : 0);
    final colStep = toCol > fromCol ? 1 : (toCol < fromCol ? -1 : 0);
    
    int currentRow = fromRow + rowStep;
    int currentCol = fromCol + colStep;
    
    while (currentRow != toRow || currentCol != toCol) {
      if (board[currentRow][currentCol].isNotEmpty) return false;
      currentRow += rowStep;
      currentCol += colStep;
    }
    
    return true;
  }

  bool _isWhitePiece(String piece) {
    return '♔♕♖♗♘♙'.contains(piece);
  }

  void _onCellTap(int row, int col) {
    if (!isGameActive) return;
    
    if (selectedPiece == null) {
      if (board[row][col].isNotEmpty) {
        final piece = board[row][col];
        final isWhitePiece = _isWhitePiece(piece);
        final isCurrentPlayerWhite = currentPlayer == 'white';
        
        if (isWhitePiece == isCurrentPlayerWhite) {
          setState(() {
            selectedPiece = piece;
            selectedRow = row;
            selectedCol = col;
          });
          _pulseController.forward();
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
      } else if (_isValidMove(selectedRow!, selectedCol!, row, col)) {
        final capturedPiece = board[row][col];
        if (capturedPiece.isNotEmpty) {
          if (_isWhitePiece(capturedPiece)) {
            whiteCapturedPieces++;
          } else {
            blackCapturedPieces++;
          }
        }
        
        final moveNotation = '${board[selectedRow!][selectedCol!]}${String.fromCharCode(97 + selectedCol!)}${8 - selectedRow!} → ${String.fromCharCode(97 + col)}${8 - row}';
        
        setState(() {
          board[row][col] = selectedPiece!;
          board[selectedRow!][selectedCol!] = '';
          selectedPiece = null;
          selectedRow = null;
          selectedCol = null;
          currentPlayer = currentPlayer == 'white' ? 'black' : 'white';
          gameStatus = '${currentPlayer == 'white' ? 'White' : 'Black'} to move';
          moveHistory.add(moveNotation);
          moveCount++;
        });
        
        _pulseController.reverse();
        _checkGameStatus();
        
        // AI move after player move
        if (widget.isAIGame && currentPlayer == 'black' && isGameActive) {
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted && isGameActive) {
              _makeAIMove();
            }
          });
        }
      } else {
        setState(() {
          selectedPiece = null;
          selectedRow = null;
          selectedCol = null;
        });
        _pulseController.reverse();
      }
    }
  }

  void _checkGameStatus() {
    // Simplified check - only check if current player has any valid moves
    bool hasValidMove = false;
    
    for (int fromRow = 0; fromRow < 8; fromRow++) {
      for (int fromCol = 0; fromCol < 8; fromCol++) {
        final piece = board[fromRow][fromCol];
        if (piece.isNotEmpty) {
          final isWhitePiece = _isWhitePiece(piece);
          final isCurrentPlayerWhite = currentPlayer == 'white';
          
          // Only check pieces belonging to current player
          if (isWhitePiece == isCurrentPlayerWhite) {
            for (int toRow = 0; toRow < 8; toRow++) {
              for (int toCol = 0; toCol < 8; toCol++) {
                if (_isValidMove(fromRow, fromCol, toRow, toCol)) {
                  hasValidMove = true;
                  break;
                }
              }
              if (hasValidMove) break;
            }
          }
        }
        if (hasValidMove) break;
      }
      if (hasValidMove) break;
    }
    
    // Only end game if NO valid moves found (stalemate/checkmate)
    if (!hasValidMove && moveCount > 10) { // Add minimum moves requirement
      setState(() {
        isGameActive = false;
        gameStatus = '${currentPlayer == 'white' ? 'Black' : 'White'} wins!';
      });
    }
  }

  void _resetGame() {
    setState(() {
      _initializeBoard();
      currentPlayer = 'white';
      selectedPiece = null;
      selectedRow = null;
      selectedCol = null;
      isGameActive = true;
      gameStatus = 'White to move';
      whiteCapturedPieces = 0;
      blackCapturedPieces = 0;
      moveHistory.clear();
      moveCount = 0;
    });
    _pulseController.reset();
  }

  void _makeAIMove() {
    final List<Map<String, dynamic>> possibleMoves = [];
    
    // Find all possible moves for black pieces
    for (int fromRow = 0; fromRow < 8; fromRow++) {
      for (int fromCol = 0; fromCol < 8; fromCol++) {
        final piece = board[fromRow][fromCol];
        if (piece.isNotEmpty && !_isWhitePiece(piece)) {
          for (int toRow = 0; toRow < 8; toRow++) {
            for (int toCol = 0; toCol < 8; toCol++) {
              if (_isValidMove(fromRow, fromCol, toRow, toCol)) {
                int score = _evaluateMove(fromRow, fromCol, toRow, toCol);
                possibleMoves.add({
                  'fromRow': fromRow,
                  'fromCol': fromCol,
                  'toRow': toRow,
                  'toCol': toCol,
                  'score': score,
                });
              }
            }
          }
        }
      }
    }
    
    if (possibleMoves.isEmpty) return;
    
    // Sort moves by score and add some randomness based on difficulty
    possibleMoves.sort((a, b) => b['score'].compareTo(a['score']));
    
    Map<String, dynamic> selectedMove;
    switch (widget.aiDifficulty) {
      case 'easy':
        // Random move from worst 30%
        final worstMoves = possibleMoves.skip((possibleMoves.length * 0.7).floor()).toList();
        selectedMove = worstMoves[Random().nextInt(worstMoves.length)];
        break;
      case 'medium':
        // Random move from middle 40%
        final middleMoves = possibleMoves.skip((possibleMoves.length * 0.3).floor())
                                   .take((possibleMoves.length * 0.4).floor()).toList();
        selectedMove = middleMoves[Random().nextInt(middleMoves.length)];
        break;
      case 'hard':
        // Random move from best 20%
        final bestMoves = possibleMoves.take((possibleMoves.length * 0.2).ceil()).toList();
        selectedMove = bestMoves[Random().nextInt(bestMoves.length)];
        break;
      case 'grandmaster':
        // Always best move
        selectedMove = possibleMoves.first;
        break;
      default:
        selectedMove = possibleMoves.first;
    }
    
    // Make the AI move
    final fromRow = selectedMove['fromRow'] as int;
    final fromCol = selectedMove['fromCol'] as int;
    final toRow = selectedMove['toRow'] as int;
    final toCol = selectedMove['toCol'] as int;
    
    final capturedPiece = board[toRow][toCol];
    if (capturedPiece.isNotEmpty) {
      if (_isWhitePiece(capturedPiece)) {
        whiteCapturedPieces++;
      } else {
        blackCapturedPieces++;
      }
    }
    
    final moveNotation = '${board[fromRow][fromCol]}${String.fromCharCode(97 + fromCol)}${8 - fromRow} → ${String.fromCharCode(97 + toCol)}${8 - toRow}';
    
    setState(() {
      board[toRow][toCol] = board[fromRow][fromCol];
      board[fromRow][fromCol] = '';
      currentPlayer = 'white';
      gameStatus = 'White to move';
      moveHistory.add(moveNotation);
      moveCount++;
    });
    
    _checkGameStatus();
  }

  int _evaluateMove(int fromRow, int fromCol, int toRow, int toCol) {
    int score = 0;
    final piece = board[fromRow][fromCol];
    final targetPiece = board[toRow][toCol];
    
    // Capture value
    if (targetPiece.isNotEmpty) {
      switch (targetPiece) {
        case '♙': score += 10; break;
        case '♖': score += 50; break;
        case '♘': case '♗': score += 30; break;
        case '♕': score += 90; break;
        case '♔': score += 1000; break;
      }
    }
    
    // Center control
    final centerDistance = (toRow - 3.5).abs() + (toCol - 3.5).abs();
    score += (7 - centerDistance).round() * 2;
    
    // Piece development
    if (piece == '♟' && toRow > fromRow) score += 5;
    if (piece == '♜' && (fromRow == 0 || fromCol == 0 || fromCol == 7)) score += 3;
    
    return score;
  }

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
              _buildHeader(),
              _buildGameStats(),
              Expanded(child: _buildChessBoard()),
              _buildMoveHistory(),
              _buildBottomControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _showBackConfirmation,
          ),
          Expanded(
            child: Text(
              '♔ Sentient Chess ♚',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
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
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _resetGame,
          ),
          IconButton(
            icon: const Icon(Icons.palette, color: Colors.blue),
            onPressed: _showSkinSelector,
            tooltip: 'Customize Appearance (Coming Soon)',
          ),
        ],
      ),
    );
  }

  void _showBackConfirmation() {
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
              // Icon dengan animasi
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.blue.withOpacity(0.5)),
                ),
                child: const Icon(
                  Icons.home_outlined,
                  size: 30,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 20),
              
              // Judul
              const Text(
                'Kembali ke Beranda?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Deskripsi
              const Text(
                'Apakah Anda yakin ingin kembali ke beranda aplikasi Sentient? Progress permainan akan hilang.',
                style: TextStyle(
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
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.pop(context),
                          child: const Center(
                            child: Text(
                              'Batal',
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
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF45a049)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
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
                            Navigator.pop(context); // Tutup dialog
                            Navigator.popUntil(context, (route) => route.isFirst); // Kembali ke home
                          },
                          child: const Center(
                            child: Text(
                              'Ya, Keluar',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                gameStatus,
                style: TextStyle(
                  color: isGameActive ? Colors.white : Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Move $moveCount',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPlayerIndicator('White', '♔', currentPlayer == 'white'),
              _buildCapturedPieces(whiteCapturedPieces, 'white'),
              _buildCapturedPieces(blackCapturedPieces, 'black'),
              _buildPlayerIndicator('Black', '♚', currentPlayer == 'black'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerIndicator(String name, String icon, bool isActive) {
    return Column(
      children: [
        Text(
          icon,
          style: TextStyle(
            fontSize: 24,
            color: isActive ? Colors.amber : Colors.white60,
          ),
        ),
        Text(
          name,
          style: TextStyle(
            color: isActive ? Colors.amber : Colors.white60,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildCapturedPieces(int count, String color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color == 'white' ? Colors.white : Colors.black,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.amber),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: color == 'white' ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Text(
          'Captured',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildChessBoard() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulseController, _glowController]),
          builder: (context, child) {
            return GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
              ),
              itemCount: 64,
              itemBuilder: (context, index) {
                final row = index ~/ 8;
                final col = index % 8;
                final isLight = (row + col) % 2 == 0;
                final isSelected = selectedRow == row && selectedCol == col;
                final isValidMove = selectedPiece != null && 
                                  selectedRow != null && 
                                  selectedCol != null && 
                                  _isValidMove(selectedRow!, selectedCol!, row, col);
                
                return GestureDetector(
                  onTap: () => _onCellTap(row, col),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Colors.amber.withOpacity(_glowAnimation.value)
                          : isValidMove
                              ? Colors.green.withOpacity(0.5)
                              : isLight 
                                  ? const Color(0xFFF0D9B5)
                                  : const Color(0xFFB58863),
                      border: Border.all(
                        color: isSelected 
                            ? Colors.amber.withOpacity(_glowAnimation.value)
                            : isValidMove
                                ? Colors.green
                                : Colors.transparent,
                        width: isSelected ? 3 : 2,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: Colors.amber.withOpacity(_glowAnimation.value * 0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ] : null,
                    ),
                    child: Center(
                      child: AnimatedScale(
                        scale: isSelected ? _pulseAnimation.value : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          board[row][col],
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 2,
                                color: Colors.black.withOpacity(0.5),
                                offset: const Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildMoveHistory() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Move History',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: moveHistory.isEmpty
                ? const Center(
                    child: Text(
                      'No moves yet',
                      style: TextStyle(color: Colors.white60),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: moveHistory.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          moveHistory[index],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: Icons.refresh,
            label: 'New Game',
            onPressed: _resetGame,
          ),
          _buildControlButton(
            icon: Icons.undo,
            label: 'Undo',
            onPressed: () {
              // TODO: Implement undo functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Undo coming soon!')),
              );
            },
          ),
          _buildControlButton(
            icon: Icons.lightbulb,
            label: 'Hint',
            onPressed: () {
              // TODO: Implement hint functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Hint system coming soon!')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withOpacity(0.5)),
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.amber),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showSkinSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.palette, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('Customize Chess'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎨 Premium Skins Coming Soon!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            _buildSkinCategory('Board Themes', ['Classic Wood', 'Marble', 'Glass', 'Crystal']),
            const SizedBox(height: 12),
            _buildSkinCategory('Piece Sets', ['Royal Gold', 'Neon Lights', 'Crystal Clear', 'Dragon Style']),
            const SizedBox(height: 12),
            _buildSkinCategory('Backgrounds', ['Space Galaxy', 'Nature Forest', 'Ocean Deep', 'Fire Mountain']),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💎 Premium Features:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Unlock exclusive board themes\n'
                    '• Collect rare piece sets\n'
                    '• Special animated backgrounds\n'
                    '• Custom sound effects\n'
                    '• Victory celebrations',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Premium shop coming in next update! 🎉'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Notify Me'),
          ),
        ],
      ),
    );
  }

  Widget _buildSkinCategory(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: items.map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Text(
                item,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
