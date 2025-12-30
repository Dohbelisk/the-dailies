import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  final bool isDark;

  const AnimatedBackground({super.key, required this.isDark});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  final List<_FloatingShape> _shapes = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Generate floating shapes
    for (int i = 0; i < 15; i++) {
      _shapes.add(_FloatingShape(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 60 + 20,
        speed: _random.nextDouble() * 0.5 + 0.2,
        delay: _random.nextDouble(),
        type: _random.nextInt(3),
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isDark
              ? [
                  const Color(0xFF0F1020),
                  const Color(0xFF1A1B2E),
                  const Color(0xFF0F1020),
                ]
              : [
                  const Color(0xFFF0EDE5),
                  const Color(0xFFFAFAFA),
                  const Color(0xFFF5F2EA),
                ],
        ),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: size,
            painter: _BackgroundPainter(
              shapes: _shapes,
              progress: _controller.value,
              isDark: widget.isDark,
            ),
          );
        },
      ),
    );
  }
}

class _FloatingShape {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double delay;
  final int type; // 0: circle, 1: square, 2: grid dots

  _FloatingShape({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.delay,
    required this.type,
  });
}

class _BackgroundPainter extends CustomPainter {
  final List<_FloatingShape> shapes;
  final double progress;
  final bool isDark;

  _BackgroundPainter({
    required this.shapes,
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw grid pattern
    _drawGridPattern(canvas, size);

    // Draw floating shapes
    for (final shape in shapes) {
      final animatedProgress = (progress + shape.delay) % 1.0;
      final yOffset = sin(animatedProgress * 2 * pi) * 30;
      final xOffset = cos(animatedProgress * 2 * pi * shape.speed) * 20;

      final centerX = shape.x * size.width + xOffset;
      final centerY = shape.y * size.height + yOffset;

      final opacity = isDark ? 0.05 : 0.08;
      paint.color = (isDark
              ? const Color(0xFF6366F1)
              : const Color(0xFF2D3A4A))
          .withValues(alpha: opacity);

      switch (shape.type) {
        case 0:
          canvas.drawCircle(
            Offset(centerX, centerY),
            shape.size / 2,
            paint,
          );
          break;
        case 1:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(centerX, centerY),
                width: shape.size,
                height: shape.size,
              ),
              Radius.circular(shape.size * 0.2),
            ),
            paint,
          );
          break;
        case 2:
          _drawMiniGrid(canvas, centerX, centerY, shape.size, paint);
          break;
      }
    }
  }

  void _drawGridPattern(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark
              ? Colors.white
              : const Color(0xFF2D3A4A))
          .withValues(alpha: isDark ? 0.03 : 0.04)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const gridSize = 40.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  void _drawMiniGrid(
      Canvas canvas, double cx, double cy, double size, Paint paint) {
    final dotSize = size / 8;
    final spacing = size / 4;

    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        final x = cx + (i - 1) * spacing;
        final y = cy + (j - 1) * spacing;
        canvas.drawCircle(Offset(x, y), dotSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
