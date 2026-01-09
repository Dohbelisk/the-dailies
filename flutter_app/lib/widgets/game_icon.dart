import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/game_models.dart';

/// Custom illustrated icons for each game type.
/// These provide a more visually interesting representation than emojis.
class GameIcon extends StatelessWidget {
  final GameType gameType;
  final double size;
  final Color? color;
  final Color? backgroundColor;
  final bool showBackground;

  const GameIcon({
    super.key,
    required this.gameType,
    this.size = 48,
    this.color,
    this.backgroundColor,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getGameColors(gameType);
    final iconColor = color ?? colors.$1;
    final bgColor = backgroundColor ?? iconColor.withValues(alpha: 0.15);

    if (!showBackground) {
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _GameIconPainter(gameType, iconColor, size),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.15),
        child: CustomPaint(
          painter: _GameIconPainter(gameType, iconColor, size * 0.7),
        ),
      ),
    );
  }

  (Color, Color) _getGameColors(GameType type) {
    switch (type) {
      case GameType.sudoku:
        return (const Color(0xFF6366F1), const Color(0xFF8B5CF6));
      case GameType.killerSudoku:
        return (const Color(0xFFEC4899), const Color(0xFFF472B6));
      case GameType.crossword:
        return (const Color(0xFF14B8A6), const Color(0xFF22D3EE));
      case GameType.wordSearch:
        return (const Color(0xFFF59E0B), const Color(0xFFFBBF24));
      case GameType.wordForge:
        return (const Color(0xFFEAB308), const Color(0xFFFDE047));
      case GameType.nonogram:
        return (const Color(0xFF64748B), const Color(0xFF94A3B8));
      case GameType.numberTarget:
        return (const Color(0xFF10B981), const Color(0xFF34D399));
      case GameType.ballSort:
        return (const Color(0xFFF472B6), const Color(0xFFFBCFE8));
      case GameType.pipes:
        return (const Color(0xFF06B6D4), const Color(0xFF14B8A6));
      case GameType.lightsOut:
        return (const Color(0xFFEAB308), const Color(0xFFF59E0B));
      case GameType.wordLadder:
        return (const Color(0xFF6366F1), const Color(0xFF8B5CF6));
      case GameType.connections:
        return (const Color(0xFFF43F5E), const Color(0xFFEC4899));
      case GameType.mathora:
        return (const Color(0xFF10B981), const Color(0xFF059669));
      case GameType.mobius:
        return (const Color(0xFF06B6D4), const Color(0xFF0891B2)); // Cyan/Teal
      case GameType.slidingPuzzle:
        return (const Color(0xFF14B8A6), const Color(0xFF0D9488)); // Teal
      case GameType.memoryMatch:
        return (const Color(0xFFEC4899), const Color(0xFFDB2777)); // Pink
      case GameType.game2048:
        return (const Color(0xFFEAB308), const Color(0xFFCA8A04)); // Yellow/Amber
      case GameType.simon:
        return (const Color(0xFF7C3AED), const Color(0xFF6D28D9)); // Purple
      case GameType.towerOfHanoi:
        return (const Color(0xFF92400E), const Color(0xFFB45309)); // Brown/Amber
      case GameType.minesweeper:
        return (const Color(0xFF475569), const Color(0xFF64748B)); // Slate/Gray
      case GameType.sokoban:
        return (const Color(0xFF78350F), const Color(0xFF92400E)); // Amber/Brown
      case GameType.kakuro:
        return (const Color(0xFF8B5CF6), const Color(0xFFA78BFA)); // Purple
      case GameType.hitori:
        return (const Color(0xFF374151), const Color(0xFF4B5563)); // Gray
    }
  }
}

class _GameIconPainter extends CustomPainter {
  final GameType gameType;
  final Color color;
  final double size;

  _GameIconPainter(this.gameType, this.color, this.size);

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size * 0.06
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (gameType) {
      case GameType.sudoku:
        _drawSudokuIcon(canvas, canvasSize, paint, fillPaint);
        break;
      case GameType.killerSudoku:
        _drawKillerSudokuIcon(canvas, canvasSize, paint, fillPaint);
        break;
      case GameType.crossword:
        _drawCrosswordIcon(canvas, canvasSize, paint, fillPaint);
        break;
      case GameType.wordSearch:
        _drawWordSearchIcon(canvas, canvasSize, paint, fillPaint);
        break;
      case GameType.wordForge:
        _drawWordForgeIcon(canvas, canvasSize, paint, fillPaint);
        break;
      case GameType.nonogram:
        _drawNonogramIcon(canvas, canvasSize, paint, fillPaint);
        break;
      case GameType.numberTarget:
        _drawNumberTargetIcon(canvas, canvasSize, paint, fillPaint);
        break;
      case GameType.ballSort:
        _drawBallSortIcon(canvas, canvasSize, paint, fillPaint);
        break;
      case GameType.pipes:
        _drawPipesIcon(canvas, canvasSize, paint, fillPaint);
        break;
      case GameType.lightsOut:
        _drawLightsOutIcon(canvas, canvasSize, paint, fillPaint);
        break;
      case GameType.wordLadder:
        _drawWordLadderIcon(canvas, canvasSize, paint, fillPaint);
        break;
      case GameType.connections:
        _drawConnectionsIcon(canvas, canvasSize, paint, fillPaint);
        break;
      case GameType.mathora:
        _drawMathoraIcon(canvas, canvasSize, paint, fillPaint);
        break;
      case GameType.mobius:
        _drawMobiusIcon(canvas, canvasSize, paint, fillPaint);
        break;
      case GameType.slidingPuzzle:
        _drawSlidingPuzzleIcon(canvas, canvasSize, paint, fillPaint);
        break;
      case GameType.memoryMatch:
        _drawMemoryMatchIcon(canvas, canvasSize, paint, fillPaint);
        break;
      case GameType.game2048:
        _draw2048Icon(canvas, canvasSize, paint, fillPaint);
        break;
      case GameType.simon:
        _drawSimonIcon(canvas, canvasSize, paint, fillPaint);
        break;
      case GameType.towerOfHanoi:
        _drawTowerOfHanoiIcon(canvas, canvasSize, paint, fillPaint);
        break;
      case GameType.minesweeper:
        _drawMinesweeperIcon(canvas, canvasSize, paint, fillPaint);
        break;
      case GameType.sokoban:
        _drawSokobanIcon(canvas, canvasSize, paint, fillPaint);
        break;
      case GameType.kakuro:
        _drawKakuroIcon(canvas, canvasSize, paint, fillPaint);
        break;
      case GameType.hitori:
        _drawHitoriIcon(canvas, canvasSize, paint, fillPaint);
        break;
    }
  }

  void _drawSokobanIcon(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final unit = size.width / 4;

    // Draw box
    final boxRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(unit * 0.5, unit * 0.5, unit * 1.5, unit * 1.5),
      const Radius.circular(4),
    );
    canvas.drawRRect(boxRect, fill);
    canvas.drawRRect(boxRect, stroke);

    // Draw player (circle)
    canvas.drawCircle(
      Offset(unit * 3, unit * 2.5),
      unit * 0.5,
      fill,
    );

    // Draw target (X mark)
    final targetPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(unit * 1.5, unit * 3),
      Offset(unit * 2.5, unit * 4),
      targetPaint,
    );
    canvas.drawLine(
      Offset(unit * 2.5, unit * 3),
      Offset(unit * 1.5, unit * 4),
      targetPaint,
    );
  }

  void _drawMinesweeperIcon(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final unit = size.width / 3;
    // Draw 3x3 grid
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(c * unit + 1, r * unit + 1, unit - 2, unit - 2),
          const Radius.circular(2),
        );
        if (r == 1 && c == 1) {
          // Draw mine in center
          canvas.drawRRect(rect, fill);
          // Draw mine spikes
          final center = Offset(size.width / 2, size.height / 2);
          final mineRadius = unit * 0.25;
          canvas.drawCircle(center, mineRadius, Paint()..color = Colors.white);
          for (int i = 0; i < 4; i++) {
            final angle = i * 0.785; // 45 degrees
            canvas.drawLine(
              center,
              Offset(
                center.dx + mineRadius * 1.5 * math.cos(angle),
                center.dy + mineRadius * 1.5 * math.sin(angle),
              ),
              Paint()..color = Colors.white..strokeWidth = 2,
            );
          }
        } else {
          canvas.drawRRect(rect, stroke);
        }
      }
    }
  }

  void _drawTowerOfHanoiIcon(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final baseY = size.height * 0.9;
    // Draw base
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.1, baseY - 4, size.width * 0.8, 4),
      fill,
    );
    // Draw peg
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.47, size.height * 0.3, size.width * 0.06, size.height * 0.6),
      fill,
    );
    // Draw disks
    final diskWidths = [0.7, 0.5, 0.3];
    for (int i = 0; i < 3; i++) {
      final w = size.width * diskWidths[i];
      final y = baseY - 8 - i * 10;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(size.width / 2, y), width: w, height: 8),
          const Radius.circular(2),
        ),
        fill,
      );
    }
  }

  void _drawSimonIcon(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;
    // Draw 4 quadrant arcs
    final colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow];
    for (int i = 0; i < 4; i++) {
      final arcPaint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * 1.57,
        1.47,
        true,
        arcPaint,
      );
    }
  }

  void _draw2048Icon(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final unit = size.width / 2;
    // Draw 2x2 grid with different sized tiles
    final tiles = [
      (0.0, 0.0, 0.45),
      (unit, 0.0, 0.45),
      (0.0, unit, 0.45),
      (unit, unit, 0.45),
    ];
    for (final (x, y, s) in tiles) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 2, y + 2, unit * s, unit * s),
          const Radius.circular(4),
        ),
        fill,
      );
    }
  }

  void _drawMemoryMatchIcon(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final cardWidth = size.width * 0.4;
    final cardHeight = size.height * 0.5;
    // Draw two overlapping cards
    final card1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.2, cardWidth, cardHeight),
      const Radius.circular(4),
    );
    final card2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.5, size.height * 0.3, cardWidth, cardHeight),
      const Radius.circular(4),
    );
    canvas.drawRRect(card1, fill);
    canvas.drawRRect(card1, stroke);
    canvas.drawRRect(card2, fill);
    canvas.drawRRect(card2, stroke);
  }

  void _drawSlidingPuzzleIcon(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final unit = size.width / 3;
    // Draw 3x3 grid of tiles with one missing
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        if (row == 2 && col == 2) continue; // Empty space
        final rect = Rect.fromLTWH(
          col * unit + 2,
          row * unit + 2,
          unit - 4,
          unit - 4,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          fill,
        );
      }
    }
  }

  void _drawSudokuIcon(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final unit = size.width / 3;
    // Draw 3x3 grid
    for (int i = 0; i <= 3; i++) {
      final pos = i * unit;
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), stroke);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), stroke);
    }
    // Draw some numbers
    _drawNumber(canvas, '9', Offset(unit * 0.5, unit * 0.5), size.width * 0.25, fill);
    _drawNumber(canvas, '4', Offset(unit * 2.5, unit * 1.5), size.width * 0.25, fill);
  }

  void _drawKillerSudokuIcon(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final unit = size.width / 3;
    // Draw grid
    for (int i = 0; i <= 3; i++) {
      final pos = i * unit;
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), stroke);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), stroke);
    }
    // Draw dashed cage outline
    final cagePaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = size.width * 0.04
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(unit * 0.1, unit * 0.1)
      ..lineTo(unit * 1.9, unit * 0.1)
      ..lineTo(unit * 1.9, unit * 0.9)
      ..lineTo(unit * 0.9, unit * 0.9)
      ..lineTo(unit * 0.9, unit * 1.9)
      ..lineTo(unit * 0.1, unit * 1.9)
      ..close();
    canvas.drawPath(path, cagePaint);
  }

  void _drawCrosswordIcon(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final unit = size.width / 5;
    // Draw crossword pattern
    final cells = [
      [1, 0], [1, 1], [1, 2], [1, 3], [1, 4],
      [0, 2], [2, 2], [3, 2],
    ];
    for (final cell in cells) {
      final rect = Rect.fromLTWH(
        cell[0] * unit,
        cell[1] * unit,
        unit,
        unit,
      );
      canvas.drawRect(rect, stroke);
    }
    // Fill intersection
    canvas.drawRect(
      Rect.fromLTWH(unit, unit * 2, unit, unit),
      fill..color = color.withValues(alpha: 0.3),
    );
  }

  void _drawWordSearchIcon(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final unit = size.width / 4;
    // Draw letter grid
    final letters = ['W', 'O', 'R', 'D'];
    for (int i = 0; i < 4; i++) {
      _drawLetter(canvas, letters[i],
        Offset(unit * (i + 0.5), unit * (i + 0.5)),
        size.width * 0.18, fill);
    }
    // Draw highlight line
    final highlightPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = unit * 0.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(unit * 0.5, unit * 0.5),
      Offset(unit * 3.5, unit * 3.5),
      highlightPaint,
    );
  }

  void _drawWordForgeIcon(Canvas canvas, Size size, Paint stroke, Paint fill) {
    // Draw honeycomb pattern
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.22;

    // Center hexagon
    _drawHexagon(canvas, center, radius, fill);

    // Surrounding hexagons
    final angles = [0, 60, 120, 180, 240, 300];
    for (final angle in angles) {
      final rad = angle * 3.14159 / 180;
      final offset = Offset(
        center.dx + radius * 1.75 * math.cos(rad),
        center.dy + radius * 1.75 * math.sin(rad),
      );
      _drawHexagon(canvas, offset, radius, stroke);
    }
  }

  void _drawNonogramIcon(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final unit = size.width / 5;
    // Draw partially filled grid
    final filled = [[1, 0], [2, 0], [0, 1], [1, 1], [2, 1], [1, 2], [0, 3], [2, 3]];
    for (final cell in filled) {
      canvas.drawRect(
        Rect.fromLTWH(cell[0] * unit + unit, cell[1] * unit + unit, unit * 0.9, unit * 0.9),
        fill,
      );
    }
    // Draw clue hints
    stroke.strokeWidth = size.width * 0.04;
    canvas.drawLine(Offset(unit * 0.5, unit * 1.5), Offset(unit * 0.5, unit * 4), stroke);
    canvas.drawLine(Offset(unit * 1.5, unit * 0.5), Offset(unit * 4, unit * 0.5), stroke);
  }

  void _drawNumberTargetIcon(Canvas canvas, Size size, Paint stroke, Paint fill) {
    // Draw target circle
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, size.width * 0.4, stroke);
    canvas.drawCircle(center, size.width * 0.25, stroke);
    canvas.drawCircle(center, size.width * 0.1, fill);
    // Draw number
    _drawNumber(canvas, '24', center, size.width * 0.2, fill..color = Colors.white);
  }

  void _drawBallSortIcon(Canvas canvas, Size size, Paint stroke, Paint fill) {
    // Draw tubes with colored balls
    final tubeWidth = size.width * 0.28;
    final tubeHeight = size.height * 0.7;

    for (int t = 0; t < 3; t++) {
      final x = size.width * 0.1 + t * (tubeWidth + size.width * 0.05);
      final y = size.height * 0.15;

      // Tube outline
      final tubePath = Path()
        ..moveTo(x, y)
        ..lineTo(x, y + tubeHeight)
        ..arcToPoint(Offset(x + tubeWidth, y + tubeHeight), radius: Radius.circular(tubeWidth / 2))
        ..lineTo(x + tubeWidth, y);
      canvas.drawPath(tubePath, stroke);

      // Draw balls
      final ballRadius = tubeWidth * 0.35;
      final colors = [color, color.withValues(alpha: 0.6), color.withValues(alpha: 0.3)];
      for (int b = 0; b < 3; b++) {
        canvas.drawCircle(
          Offset(x + tubeWidth / 2, y + tubeHeight - ballRadius - b * ballRadius * 2.2),
          ballRadius,
          fill..color = colors[(t + b) % 3],
        );
      }
    }
  }

  void _drawPipesIcon(Canvas canvas, Size size, Paint stroke, Paint fill) {
    // Draw connecting pipes
    final unit = size.width / 3;
    stroke.strokeWidth = size.width * 0.08;

    // Horizontal pipe
    canvas.drawLine(
      Offset(unit * 0.5, unit * 1.5),
      Offset(unit * 2.5, unit * 1.5),
      stroke,
    );

    // Vertical pipe with different color
    final pipe2 = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(unit * 1.5, unit * 0.5),
      Offset(unit * 1.5, unit * 2.5),
      pipe2,
    );

    // Endpoints
    canvas.drawCircle(Offset(unit * 0.5, unit * 1.5), size.width * 0.08, fill);
    canvas.drawCircle(Offset(unit * 2.5, unit * 1.5), size.width * 0.08, fill);
  }

  void _drawLightsOutIcon(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final unit = size.width / 3;
    // Draw 3x3 grid of lights
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        final isOn = (r + c) % 2 == 0;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(c * unit + 2, r * unit + 2, unit - 4, unit - 4),
          Radius.circular(size.width * 0.05),
        );
        canvas.drawRRect(rect, isOn ? fill : stroke);
      }
    }
  }

  void _drawWordLadderIcon(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final unit = size.height / 4;
    // Draw ladder rungs with words
    for (int i = 0; i < 4; i++) {
      final y = unit * (i + 0.5);
      canvas.drawLine(
        Offset(size.width * 0.1, y),
        Offset(size.width * 0.9, y),
        stroke,
      );
    }
    // Draw vertical sides
    canvas.drawLine(
      Offset(size.width * 0.2, 0),
      Offset(size.width * 0.2, size.height),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.8, 0),
      Offset(size.width * 0.8, size.height),
      stroke,
    );
  }

  void _drawConnectionsIcon(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final unit = size.width / 4;
    // Draw 4x4 grid of colored tiles
    final colors = [
      color,
      color.withValues(alpha: 0.7),
      color.withValues(alpha: 0.5),
      color.withValues(alpha: 0.3),
    ];
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(c * unit + 1, r * unit + 1, unit - 2, unit - 2),
          Radius.circular(size.width * 0.03),
        );
        canvas.drawRRect(rect, fill..color = colors[(r + c) % 4]);
      }
    }
  }

  void _drawMathoraIcon(Canvas canvas, Size size, Paint stroke, Paint fill) {
    // Draw math operation buttons (4 operation cells in a 2x2 grid)
    final unit = size.width / 3;
    for (int i = 0; i < 4; i++) {
      final x = (i % 2) * unit * 1.3 + unit * 0.35;
      final y = (i ~/ 2) * unit * 1.3 + unit * 0.35;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, unit * 1.1, unit * 1.1),
          Radius.circular(size.width * 0.1),
        ),
        i == 0 ? fill : stroke,
      );
    }
  }

  void _drawMobiusIcon(Canvas canvas, Size size, Paint stroke, Paint fill) {
    // Draw an infinity/mobius symbol
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final loopWidth = size.width * 0.35;
    final loopHeight = size.height * 0.25;

    final path = Path();
    // Left loop
    path.addOval(Rect.fromCenter(
      center: Offset(centerX - loopWidth * 0.5, centerY),
      width: loopWidth,
      height: loopHeight * 2,
    ));
    // Right loop
    path.addOval(Rect.fromCenter(
      center: Offset(centerX + loopWidth * 0.5, centerY),
      width: loopWidth,
      height: loopHeight * 2,
    ));

    canvas.drawPath(path, stroke);
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * 3.14159 / 180;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawNumber(Canvas canvas, String num, Offset center, double size, Paint paint) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: num,
        style: TextStyle(
          color: paint.color,
          fontSize: size,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  void _drawLetter(Canvas canvas, String letter, Offset center, double size, Paint paint) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          color: paint.color,
          fontSize: size,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  void _drawKakuroIcon(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final unit = size.width / 4;

    // Draw grid cells with clue diagonal
    // Clue cell (top-left with diagonal)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, unit, unit),
      fill,
    );
    canvas.drawLine(
      const Offset(0, 0),
      Offset(unit, unit),
      stroke..strokeWidth = size.width * 0.04,
    );

    // Entry cells
    stroke.strokeWidth = size.width * 0.05;
    for (int i = 1; i < 4; i++) {
      canvas.drawRect(
        Rect.fromLTWH(i * unit + 2, 2, unit - 4, unit - 4),
        stroke,
      );
    }
    for (int i = 1; i < 4; i++) {
      canvas.drawRect(
        Rect.fromLTWH(2, i * unit + 2, unit - 4, unit - 4),
        stroke,
      );
    }

    // Draw some numbers in cells
    _drawNumber(canvas, '3', Offset(unit * 1.5, unit * 0.5), size.width * 0.18, fill);
    _drawNumber(canvas, '1', Offset(unit * 2.5, unit * 0.5), size.width * 0.18, fill);
  }

  void _drawHitoriIcon(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final unit = size.width / 4;

    // Draw grid of cells (some shaded, some not)
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        final isShaded = (row == 1 && col == 1) || (row == 2 && col == 0);
        final rect = Rect.fromLTWH(
          col * unit + unit * 0.5 + 2,
          row * unit + unit * 0.5 + 2,
          unit - 4,
          unit - 4,
        );

        if (isShaded) {
          canvas.drawRect(rect, fill);
        } else {
          canvas.drawRect(rect, stroke);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
