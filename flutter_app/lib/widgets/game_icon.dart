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


  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
