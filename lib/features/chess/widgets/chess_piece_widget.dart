import 'package:flutter/material.dart';

enum PieceType { pawn, rook, knight, bishop, queen, king }

class ChessPieceWidget extends StatelessWidget {
  final String piece;
  final double size;
  final bool isSelected;
  final bool isKingInDanger;

  const ChessPieceWidget({
    super.key,
    required this.piece,
    this.size = 38.0,
    this.isSelected = false,
    this.isKingInDanger = false,
  });

  static bool isWhite(String p) {
    return '♔♕♖♗♘♙'.contains(p);
  }

  static PieceType? getPieceType(String p) {
    switch (p) {
      case '♙': case '♟': return PieceType.pawn;
      case '♖': case '♜': return PieceType.rook;
      case '♘': case '♞': return PieceType.knight;
      case '♗': case '♝': return PieceType.bishop;
      case '♕': case '♛': return PieceType.queen;
      case '♔': case '♚': return PieceType.king;
      default: return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (piece.isEmpty) return const SizedBox.shrink();

    final pieceType = getPieceType(piece);
    if (pieceType == null) return const SizedBox.shrink();

    final white = isWhite(piece);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StauntonPiecePainter(
          type: pieceType,
          isWhite: white,
          isSelected: isSelected,
          isKingInDanger: isKingInDanger,
        ),
      ),
    );
  }
}

class _StauntonPiecePainter extends CustomPainter {
  final PieceType type;
  final bool isWhite;
  final bool isSelected;
  final bool isKingInDanger;

  _StauntonPiecePainter({
    required this.type,
    required this.isWhite,
    required this.isSelected,
    required this.isKingInDanger,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Shading and Gradients
    final fillPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final detailStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035
      ..strokeCap = StrokeCap.round;

    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03
      ..color = isWhite ? Colors.white.withOpacity(0.9) : Colors.white.withOpacity(0.35)
      ..strokeCap = StrokeCap.round;

    if (isWhite) {
      // Luxurious White/Ivory Gradient
      fillPaint.shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFFAF7F0),
          Color(0xFFEBE3D3),
          Color(0xFFDCD2C0),
        ],
        stops: [0.0, 0.35, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

      // Dark Wood / Walnut contour border for crisp visibility on light squares
      strokePaint.color = const Color(0xFF332219);
      detailStroke.color = const Color(0xFF5A4436);
    } else {
      // Obsidian Onyx / Midnight Black Gradient
      fillPaint.shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF3D4756),
          Color(0xFF252C36),
          Color(0xFF141920),
          Color(0xFF0B0E13),
        ],
        stops: [0.0, 0.35, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

      // Luminous Platinum / Cool Silver contour border for crisp visibility on dark squares
      strokePaint.color = const Color(0xFFC8D6E5);
      detailStroke.color = const Color(0xFF8395A7);
    }

    // 2. Draw Soft Drop Shadow under the entire piece
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.save();
    canvas.translate(w * 0.02, h * 0.04);
    _drawPieceGeometry(canvas, w, h, shadowPaint, Paint()..color = Colors.transparent);
    canvas.restore();

    // 3. Draw Main Piece Body & Contours
    _drawPieceGeometry(canvas, w, h, fillPaint, strokePaint);

    // 4. Draw Specific Piece Details & Inner highlights
    _drawPieceDetails(canvas, w, h, detailStroke, highlightPaint);
  }

  void _drawPieceGeometry(Canvas canvas, double w, double h, Paint fill, Paint stroke) {
    switch (type) {
      case PieceType.pawn:
        _drawPawn(canvas, w, h, fill, stroke);
        break;
      case PieceType.rook:
        _drawRook(canvas, w, h, fill, stroke);
        break;
      case PieceType.knight:
        _drawKnight(canvas, w, h, fill, stroke);
        break;
      case PieceType.bishop:
        _drawBishop(canvas, w, h, fill, stroke);
        break;
      case PieceType.queen:
        _drawQueen(canvas, w, h, fill, stroke);
        break;
      case PieceType.king:
        _drawKing(canvas, w, h, fill, stroke);
        break;
    }
  }

  // --- COMMON BASE ---
  void _drawBase(Canvas canvas, double w, double h, Paint fill, Paint stroke, {double yOffset = 0.0}) {
    // Bottom Wide Base
    final bottomRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.16, h * (0.84 + yOffset), w * 0.84, h * (0.94 + yOffset)),
      Radius.circular(w * 0.06),
    );
    canvas.drawRRect(bottomRect, fill);
    canvas.drawRRect(bottomRect, stroke);

    // Upper Base Ring
    final upperRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.25, h * (0.76 + yOffset), w * 0.75, h * (0.84 + yOffset)),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(upperRect, fill);
    canvas.drawRRect(upperRect, stroke);
  }

  // --- 1. PAWN ---
  void _drawPawn(Canvas canvas, double w, double h, Paint fill, Paint stroke) {
    _drawBase(canvas, w, h, fill, stroke);

    // Body
    final body = Path();
    body.moveTo(w * 0.32, h * 0.76);
    body.quadraticBezierTo(w * 0.43, h * 0.54, w * 0.35, h * 0.44);
    body.lineTo(w * 0.65, h * 0.44);
    body.quadraticBezierTo(w * 0.57, h * 0.54, w * 0.68, h * 0.76);
    body.close();
    canvas.drawPath(body, fill);
    canvas.drawPath(body, stroke);

    // Collar
    final collar = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.28, h * 0.39, w * 0.72, h * 0.46),
      Radius.circular(w * 0.035),
    );
    canvas.drawRRect(collar, fill);
    canvas.drawRRect(collar, stroke);

    // Head Ball
    final headCenter = Offset(w * 0.5, h * 0.25);
    final headRadius = w * 0.16;
    canvas.drawCircle(headCenter, headRadius, fill);
    canvas.drawCircle(headCenter, headRadius, stroke);
  }

  // --- 2. ROOK ---
  void _drawRook(Canvas canvas, double w, double h, Paint fill, Paint stroke) {
    _drawBase(canvas, w, h, fill, stroke);

    // Tower Body
    final tower = Path();
    tower.moveTo(w * 0.28, h * 0.76);
    tower.lineTo(w * 0.32, h * 0.38);
    tower.lineTo(w * 0.68, h * 0.38);
    tower.lineTo(w * 0.72, h * 0.76);
    tower.close();
    canvas.drawPath(tower, fill);
    canvas.drawPath(tower, stroke);

    // Cornice (rim under battlements)
    final cornice = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.23, h * 0.33, w * 0.77, h * 0.39),
      Radius.circular(w * 0.03),
    );
    canvas.drawRRect(cornice, fill);
    canvas.drawRRect(cornice, stroke);

    // Castle Battlements (Crenels)
    final battlements = Path();
    battlements.moveTo(w * 0.24, h * 0.33);
    battlements.lineTo(w * 0.24, h * 0.17); // Left wall
    battlements.lineTo(w * 0.36, h * 0.17); // Left merlon top
    battlements.lineTo(w * 0.36, h * 0.25); // Left gap down
    battlements.lineTo(w * 0.44, h * 0.25); // Left gap bottom
    battlements.lineTo(w * 0.44, h * 0.17); // Center merlon up
    battlements.lineTo(w * 0.56, h * 0.17); // Center merlon top
    battlements.lineTo(w * 0.56, h * 0.25); // Right gap down
    battlements.lineTo(w * 0.64, h * 0.25); // Right gap bottom
    battlements.lineTo(w * 0.64, h * 0.17); // Right merlon up
    battlements.lineTo(w * 0.76, h * 0.17); // Right merlon top
    battlements.lineTo(w * 0.76, h * 0.33); // Right wall
    battlements.close();
    canvas.drawPath(battlements, fill);
    canvas.drawPath(battlements, stroke);
  }

  // --- 3. KNIGHT ---
  void _drawKnight(Canvas canvas, double w, double h, Paint fill, Paint stroke) {
    _drawBase(canvas, w, h, fill, stroke);

    // Horse Head Profile
    final horse = Path();
    horse.moveTo(w * 0.28, h * 0.76);
    // Chest curve
    horse.quadraticBezierTo(w * 0.25, h * 0.62, w * 0.21, h * 0.52);
    // Muzzle / Snout
    horse.lineTo(w * 0.18, h * 0.40);
    horse.quadraticBezierTo(w * 0.23, h * 0.34, w * 0.33, h * 0.33);
    // Forehead to Ear
    horse.lineTo(w * 0.44, h * 0.25);
    horse.lineTo(w * 0.42, h * 0.13); // Front ear tip
    horse.lineTo(w * 0.50, h * 0.22);
    horse.lineTo(w * 0.53, h * 0.15); // Back ear tip
    horse.lineTo(w * 0.57, h * 0.24);
    // Arched Mane along back
    horse.quadraticBezierTo(w * 0.78, h * 0.36, w * 0.73, h * 0.60);
    horse.lineTo(w * 0.72, h * 0.76);
    horse.close();

    canvas.drawPath(horse, fill);
    canvas.drawPath(horse, stroke);
  }

  // --- 4. BISHOP ---
  void _drawBishop(Canvas canvas, double w, double h, Paint fill, Paint stroke) {
    _drawBase(canvas, w, h, fill, stroke);

    // Body
    final body = Path();
    body.moveTo(w * 0.30, h * 0.76);
    body.quadraticBezierTo(w * 0.42, h * 0.62, w * 0.36, h * 0.52);
    body.lineTo(w * 0.64, h * 0.52);
    body.quadraticBezierTo(w * 0.58, h * 0.62, w * 0.70, h * 0.76);
    body.close();
    canvas.drawPath(body, fill);
    canvas.drawPath(body, stroke);

    // Collar
    final collar = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.31, h * 0.48, w * 0.69, h * 0.54),
      Radius.circular(w * 0.03),
    );
    canvas.drawRRect(collar, fill);
    canvas.drawRRect(collar, stroke);

    // Miter (Oval Head)
    final miter = Path();
    miter.moveTo(w * 0.35, h * 0.48);
    miter.cubicTo(w * 0.24, h * 0.36, w * 0.42, h * 0.18, w * 0.50, h * 0.16);
    miter.cubicTo(w * 0.58, h * 0.18, w * 0.76, h * 0.36, w * 0.65, h * 0.48);
    miter.close();
    canvas.drawPath(miter, fill);
    canvas.drawPath(miter, stroke);

    // Top Pearl
    canvas.drawCircle(Offset(w * 0.50, h * 0.14), w * 0.045, fill);
    canvas.drawCircle(Offset(w * 0.50, h * 0.14), w * 0.045, stroke);
  }

  // --- 5. QUEEN ---
  void _drawQueen(Canvas canvas, double w, double h, Paint fill, Paint stroke) {
    _drawBase(canvas, w, h, fill, stroke);

    // Hourglass Royal Body
    final body = Path();
    body.moveTo(w * 0.28, h * 0.76);
    body.quadraticBezierTo(w * 0.42, h * 0.58, w * 0.35, h * 0.42);
    body.lineTo(w * 0.65, h * 0.42);
    body.quadraticBezierTo(w * 0.58, h * 0.58, w * 0.72, h * 0.76);
    body.close();
    canvas.drawPath(body, fill);
    canvas.drawPath(body, stroke);

    // Waist Ring
    final waist = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.30, h * 0.38, w * 0.70, h * 0.44),
      Radius.circular(w * 0.03),
    );
    canvas.drawRRect(waist, fill);
    canvas.drawRRect(waist, stroke);

    // Coronet / Crown (5 Points)
    final crown = Path();
    crown.moveTo(w * 0.33, h * 0.38);
    crown.lineTo(w * 0.20, h * 0.22); // Point 1 (left)
    crown.lineTo(w * 0.33, h * 0.28);
    crown.lineTo(w * 0.37, h * 0.18); // Point 2
    crown.lineTo(w * 0.47, h * 0.27);
    crown.lineTo(w * 0.50, h * 0.15); // Point 3 (center high)
    crown.lineTo(w * 0.53, h * 0.27);
    crown.lineTo(w * 0.63, h * 0.18); // Point 4
    crown.lineTo(w * 0.67, h * 0.28);
    crown.lineTo(w * 0.80, h * 0.22); // Point 5 (right)
    crown.lineTo(w * 0.67, h * 0.38);
    crown.close();
    canvas.drawPath(crown, fill);
    canvas.drawPath(crown, stroke);

    // 5 Pearls on Crown points
    final pearlRadius = w * 0.035;
    canvas.drawCircle(Offset(w * 0.20, h * 0.21), pearlRadius, fill);
    canvas.drawCircle(Offset(w * 0.20, h * 0.21), pearlRadius, stroke);
    canvas.drawCircle(Offset(w * 0.37, h * 0.17), pearlRadius, fill);
    canvas.drawCircle(Offset(w * 0.37, h * 0.17), pearlRadius, stroke);
    canvas.drawCircle(Offset(w * 0.50, h * 0.14), pearlRadius, fill);
    canvas.drawCircle(Offset(w * 0.50, h * 0.14), pearlRadius, stroke);
    canvas.drawCircle(Offset(w * 0.63, h * 0.17), pearlRadius, fill);
    canvas.drawCircle(Offset(w * 0.63, h * 0.17), pearlRadius, stroke);
    canvas.drawCircle(Offset(w * 0.80, h * 0.21), pearlRadius, fill);
    canvas.drawCircle(Offset(w * 0.80, h * 0.21), pearlRadius, stroke);
  }

  // --- 6. KING ---
  void _drawKing(Canvas canvas, double w, double h, Paint fill, Paint stroke) {
    _drawBase(canvas, w, h, fill, stroke);

    // Robe Body
    final body = Path();
    body.moveTo(w * 0.27, h * 0.76);
    body.quadraticBezierTo(w * 0.40, h * 0.58, w * 0.32, h * 0.44);
    body.lineTo(w * 0.68, h * 0.44);
    body.quadraticBezierTo(w * 0.60, h * 0.58, w * 0.73, h * 0.76);
    body.close();
    canvas.drawPath(body, fill);
    canvas.drawPath(body, stroke);

    // Collar
    final collar = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.28, h * 0.40, w * 0.72, h * 0.46),
      Radius.circular(w * 0.03),
    );
    canvas.drawRRect(collar, fill);
    canvas.drawRRect(collar, stroke);

    // Arched Imperial Crown
    final crown = Path();
    crown.moveTo(w * 0.31, h * 0.40);
    crown.cubicTo(w * 0.22, h * 0.28, w * 0.40, h * 0.21, w * 0.50, h * 0.20);
    crown.cubicTo(w * 0.60, h * 0.21, w * 0.78, h * 0.28, w * 0.69, h * 0.40);
    crown.close();
    canvas.drawPath(crown, fill);
    canvas.drawPath(crown, stroke);

    // Top Latin Cross
    final cross = Path();
    // Vertical post
    cross.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.47, h * 0.08, w * 0.53, h * 0.21),
      Radius.circular(w * 0.015),
    ));
    // Horizontal beam
    cross.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.39, h * 0.11, w * 0.61, h * 0.16),
      Radius.circular(w * 0.015),
    ));
    canvas.drawPath(cross, fill);
    canvas.drawPath(cross, stroke);
  }

  // --- SPECIFIC INNER DETAILS ---
  void _drawPieceDetails(Canvas canvas, double w, double h, Paint stroke, Paint highlight) {
    switch (type) {
      case PieceType.pawn:
        // Curved highlight on head
        final arc = Path();
        arc.addArc(Rect.fromCircle(center: Offset(w * 0.50, h * 0.25), radius: w * 0.11), 3.4, 1.2);
        canvas.drawPath(arc, highlight);
        break;

      case PieceType.rook:
        // Stone belt groove across tower shaft
        canvas.drawLine(
          Offset(w * 0.31, h * 0.52),
          Offset(w * 0.69, h * 0.52),
          stroke,
        );
        // Medieval cross arrowslit (embrasure)
        final arrowVert = Path()
          ..moveTo(w * 0.50, h * 0.58)
          ..lineTo(w * 0.50, h * 0.70);
        final arrowHoriz = Path()
          ..moveTo(w * 0.43, h * 0.62)
          ..lineTo(w * 0.57, h * 0.62);
        canvas.drawPath(arrowVert, stroke);
        canvas.drawPath(arrowHoriz, stroke);
        break;

      case PieceType.knight:
        // Eye Dot
        final eyeColor = isWhite ? const Color(0xFF332219) : const Color(0xFFC8D6E5);
        canvas.drawCircle(Offset(w * 0.34, h * 0.36), w * 0.035, Paint()..color = eyeColor);
        // Nostril Slit
        final nostril = Path();
        nostril.moveTo(w * 0.22, h * 0.44);
        nostril.lineTo(w * 0.25, h * 0.47);
        canvas.drawPath(nostril, stroke);
        // Mane details
        final maneLine = Path();
        maneLine.moveTo(w * 0.52, h * 0.32);
        maneLine.quadraticBezierTo(w * 0.62, h * 0.42, w * 0.60, h * 0.62);
        canvas.drawPath(maneLine, stroke);
        break;

      case PieceType.bishop:
        // The signature diagonal cleft cut in the miter
        final cleft = Path();
        cleft.moveTo(w * 0.42, h * 0.26);
        cleft.lineTo(w * 0.55, h * 0.37);
        canvas.drawPath(cleft, stroke);
        break;

      case PieceType.queen:
        // Jewel line on crown
        final arch = Path();
        arch.moveTo(w * 0.36, h * 0.34);
        arch.quadraticBezierTo(w * 0.50, h * 0.30, w * 0.64, h * 0.34);
        canvas.drawPath(arch, stroke);
        break;

      case PieceType.king:
        // Royal Crown Bands
        final band = Path();
        band.moveTo(w * 0.38, h * 0.34);
        band.quadraticBezierTo(w * 0.50, h * 0.28, w * 0.62, h * 0.34);
        canvas.drawPath(band, stroke);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _StauntonPiecePainter old) {
    return old.type != type ||
        old.isWhite != isWhite ||
        old.isSelected != isSelected ||
        old.isKingInDanger != isKingInDanger;
  }
}
