import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_models.dart';

/// Möbius puzzle grid widget - displays impossible geometry puzzles
/// with isometric rendering and swipe-based navigation
class MobiusGrid extends StatefulWidget {
  final MobiusPuzzle puzzle;
  final VoidCallback? onComplete;
  final VoidCallback? onMove;

  const MobiusGrid({
    super.key,
    required this.puzzle,
    this.onComplete,
    this.onMove,
  });

  @override
  State<MobiusGrid> createState() => _MobiusGridState();
}

class _MobiusGridState extends State<MobiusGrid> with TickerProviderStateMixin {
  late AnimationController _moveController;
  late Animation<double> _moveAnimation;

  MobiusNode? _animatingFrom;
  MobiusNode? _animatingTo;
  bool _isAnimating = false;

  // Swipe detection
  Offset? _dragStart;
  static const double _swipeThreshold = 30.0;

  @override
  void initState() {
    super.initState();
    _moveController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _moveAnimation = CurvedAnimation(
      parent: _moveController,
      curve: Curves.easeOut,
    );
    _moveController.addStatusListener(_onAnimationStatus);
  }

  @override
  void dispose() {
    _moveController.dispose();
    super.dispose();
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _isAnimating = false;
        _animatingFrom = null;
        _animatingTo = null;
      });

      // Check for completion
      if (widget.puzzle.isComplete) {
        widget.onComplete?.call();
      }
    }
  }

  void _handleSwipe(SwipeDirection direction) {
    if (_isAnimating) return;

    final fromNode = widget.puzzle.currentNode;
    final targetId = widget.puzzle.tryMove(direction);

    if (targetId != null && fromNode != null) {
      final toNode = widget.puzzle.getNode(targetId);
      if (toNode != null) {
        setState(() {
          _isAnimating = true;
          _animatingFrom = fromNode;
          _animatingTo = toNode;
        });
        _moveController.forward(from: 0);
        HapticFeedback.lightImpact();
        widget.onMove?.call();
      }
    } else {
      // Invalid move feedback
      HapticFeedback.heavyImpact();
    }
  }

  void _onPanStart(DragStartDetails details) {
    _dragStart = details.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_dragStart == null || _isAnimating) return;

    final delta = details.localPosition - _dragStart!;

    if (delta.distance > _swipeThreshold) {
      SwipeDirection? direction;

      if (delta.dx.abs() > delta.dy.abs()) {
        // Horizontal swipe
        direction = delta.dx > 0 ? SwipeDirection.right : SwipeDirection.left;
      } else {
        // Vertical swipe
        direction = delta.dy > 0 ? SwipeDirection.down : SwipeDirection.up;
      }

      _dragStart = null; // Prevent multiple triggers
      _handleSwipe(direction);
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _dragStart = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Info bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Move counter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.puzzle.moveCount}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'moves',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              // Undo button
              IconButton(
                onPressed: widget.puzzle.moveHistory.isEmpty
                    ? null
                    : () {
                        setState(() {
                          widget.puzzle.undoMove();
                        });
                        HapticFeedback.selectionClick();
                      },
                icon: const Icon(Icons.undo, size: 22),
                tooltip: 'Undo',
              ),
              // Reset button
              IconButton(
                onPressed: widget.puzzle.moveCount == 0
                    ? null
                    : () {
                        setState(() {
                          widget.puzzle.reset();
                        });
                        HapticFeedback.selectionClick();
                      },
                icon: const Icon(Icons.refresh, size: 22),
                tooltip: 'Reset',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Game grid
        Expanded(
          child: GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CustomPaint(
                  painter: _MobiusPainter(
                    puzzle: widget.puzzle,
                    theme: theme,
                    animationValue: _moveAnimation.value,
                    animatingFrom: _animatingFrom,
                    animatingTo: _animatingTo,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ),

        // Direction hints
        const SizedBox(height: 16),
        _buildDirectionHints(theme),
      ],
    );
  }

  Widget _buildDirectionHints(ThemeData theme) {
    final availableEdges = widget.puzzle.availableEdges;
    final canUp = availableEdges.any((e) => e.direction == SwipeDirection.up);
    final canDown = availableEdges.any((e) => e.direction == SwipeDirection.down);
    final canLeft = availableEdges.any((e) => e.direction == SwipeDirection.left);
    final canRight = availableEdges.any((e) => e.direction == SwipeDirection.right);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildArrow(Icons.keyboard_arrow_up, canUp, theme),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildArrow(Icons.keyboard_arrow_left, canLeft, theme),
              const SizedBox(width: 32),
              _buildArrow(Icons.keyboard_arrow_right, canRight, theme),
            ],
          ),
          _buildArrow(Icons.keyboard_arrow_down, canDown, theme),
        ],
      ),
    );
  }

  Widget _buildArrow(IconData icon, bool active, ThemeData theme) {
    return Icon(
      icon,
      size: 32,
      color: active
          ? theme.colorScheme.primary
          : theme.colorScheme.outline.withValues(alpha: 0.3),
    );
  }
}

/// Custom painter for isometric Möbius puzzle rendering
/// Creates impossible geometry illusion with thick 3D bars
class _MobiusPainter extends CustomPainter {
  final MobiusPuzzle puzzle;
  final ThemeData theme;
  final double animationValue;
  final MobiusNode? animatingFrom;
  final MobiusNode? animatingTo;

  // Isometric projection constants
  static const double _isoAngle = 30.0 * math.pi / 180; // 30 degrees
  static const double _scale = 80.0; // Base scale for node spacing

  // Bar dimensions for 3D effect
  static const double _barWidth = 28.0;
  static const double _barDepth = 20.0;

  // Colors for 3D metallic bars
  static const Color _barTop = Color(0xFF8A8A8A);
  static const Color _barLeft = Color(0xFF6A6A6A);
  static const Color _barRight = Color(0xFF4A4A4A);
  static const Color _barFront = Color(0xFF5A5A5A);

  _MobiusPainter({
    required this.puzzle,
    required this.theme,
    required this.animationValue,
    this.animatingFrom,
    this.animatingTo,
  });

  /// Convert 3D isometric coordinates to 2D screen coordinates
  Offset _toScreen(double x, double y, double z, Size size) {
    // Isometric projection formula
    final screenX = (x - z) * math.cos(_isoAngle) * _scale;
    final screenY = -y * _scale + (x + z) * math.sin(_isoAngle) * _scale;

    // Center in the canvas
    return Offset(
      size.width / 2 + screenX,
      size.height / 2 + screenY,
    );
  }

  Offset _nodeToScreen(MobiusNode node, Size size) {
    return _toScreen(node.x, node.y, node.z, size);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Sort edges by depth for proper draw order (back to front)
    final sortedEdges = _getSortedEdges();

    // Draw 3D beams
    for (final edgeData in sortedEdges) {
      _draw3DBeam(canvas, size, edgeData.$1, edgeData.$2, edgeData.$3);
    }

    // Draw goal marker
    _drawGoalMarker(canvas, size);

    // Draw cube (player) on top
    _drawCube(canvas, size);
  }

  /// Sort edges for proper depth rendering
  List<(Offset, Offset, int)> _getSortedEdges() {
    final List<(Offset, Offset, int)> edges = [];
    final drawnPairs = <String>{};

    for (final edge in puzzle.edges) {
      final pairKey = edge.fromNode < edge.toNode
          ? '${edge.fromNode}-${edge.toNode}'
          : '${edge.toNode}-${edge.fromNode}';

      if (drawnPairs.contains(pairKey)) continue;
      drawnPairs.add(pairKey);

      final fromNode = puzzle.getNode(edge.fromNode);
      final toNode = puzzle.getNode(edge.toNode);

      if (fromNode == null || toNode == null) continue;

      // Calculate depth for sorting (average z + y position)
      final depth = ((fromNode.z + toNode.z) / 2 + (fromNode.y + toNode.y) / 2).toInt();
      edges.add((
        Offset(fromNode.x, fromNode.y * 0.8 + fromNode.z * 0.2),
        Offset(toNode.x, toNode.y * 0.8 + toNode.z * 0.2),
        depth,
      ));
    }

    // Sort by depth (draw far edges first)
    edges.sort((a, b) => b.$3.compareTo(a.$3));
    return edges;
  }

  /// Draw a thick 3D beam between two points
  void _draw3DBeam(Canvas canvas, Size size, Offset from3D, Offset to3D, int depth) {
    final fromNode = puzzle.nodes.firstWhere(
      (n) => (n.x - from3D.dx).abs() < 0.1,
      orElse: () => puzzle.nodes.first,
    );
    final toNode = puzzle.nodes.firstWhere(
      (n) => (n.x - to3D.dx).abs() < 0.1,
      orElse: () => puzzle.nodes.first,
    );

    final fromPos = _nodeToScreen(fromNode, size);
    final toPos = _nodeToScreen(toNode, size);

    // Calculate beam direction
    final dx = toPos.dx - fromPos.dx;
    final dy = toPos.dy - fromPos.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    if (length < 1) return;

    // Normalized direction
    final dirX = dx / length;
    final dirY = dy / length;

    // Perpendicular for bar width
    final perpX = -dirY;
    final perpY = dirX;

    // Half widths
    final hw = _barWidth / 2;
    final hd = _barDepth / 2;

    // 3D bar vertices (creates a rectangular prism effect)
    // Top face offset
    const topOffsetY = -12.0;

    // Define the 8 corners of the 3D bar
    // Front top
    final ft1 = Offset(fromPos.dx + perpX * hw, fromPos.dy + perpY * hw + topOffsetY);
    final ft2 = Offset(toPos.dx + perpX * hw, toPos.dy + perpY * hw + topOffsetY);
    // Front bottom
    final fb1 = Offset(fromPos.dx + perpX * hw, fromPos.dy + perpY * hw + hd);
    final fb2 = Offset(toPos.dx + perpX * hw, toPos.dy + perpY * hw + hd);
    // Back top
    final bt1 = Offset(fromPos.dx - perpX * hw, fromPos.dy - perpY * hw + topOffsetY);
    final bt2 = Offset(toPos.dx - perpX * hw, toPos.dy - perpY * hw + topOffsetY);
    // Back bottom
    final bb1 = Offset(fromPos.dx - perpX * hw, fromPos.dy - perpY * hw + hd);
    final bb2 = Offset(toPos.dx - perpX * hw, toPos.dy - perpY * hw + hd);

    // Draw shadow first
    final shadowPath = Path()
      ..moveTo(fb1.dx + 4, fb1.dy + 8)
      ..lineTo(fb2.dx + 4, fb2.dy + 8)
      ..lineTo(bb2.dx + 4, bb2.dy + 8)
      ..lineTo(bb1.dx + 4, bb1.dy + 8)
      ..close();
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Determine which faces to draw based on direction
    final goingRight = dx > 0;
    final goingDown = dy > 0;

    // Draw faces in correct order for depth
    // Right/Left side face
    if (goingRight) {
      // Draw left side
      final leftPath = Path()
        ..moveTo(bt1.dx, bt1.dy)
        ..lineTo(bt2.dx, bt2.dy)
        ..lineTo(bb2.dx, bb2.dy)
        ..lineTo(bb1.dx, bb1.dy)
        ..close();
      canvas.drawPath(leftPath, Paint()..color = _barLeft);
      _drawPathEdge(canvas, leftPath);
    } else {
      // Draw right side
      final rightPath = Path()
        ..moveTo(ft1.dx, ft1.dy)
        ..lineTo(ft2.dx, ft2.dy)
        ..lineTo(fb2.dx, fb2.dy)
        ..lineTo(fb1.dx, fb1.dy)
        ..close();
      canvas.drawPath(rightPath, Paint()..color = _barRight);
      _drawPathEdge(canvas, rightPath);
    }

    // Top face (always visible)
    final topPath = Path()
      ..moveTo(ft1.dx, ft1.dy)
      ..lineTo(ft2.dx, ft2.dy)
      ..lineTo(bt2.dx, bt2.dy)
      ..lineTo(bt1.dx, bt1.dy)
      ..close();
    canvas.drawPath(topPath, Paint()..color = _barTop);
    _drawPathEdge(canvas, topPath);

    // Front face (visible when going down or specific angles)
    if (goingDown || (!goingRight && !goingDown)) {
      final frontPath = Path()
        ..moveTo(ft1.dx, ft1.dy)
        ..lineTo(ft2.dx, ft2.dy)
        ..lineTo(fb2.dx, fb2.dy)
        ..lineTo(fb1.dx, fb1.dy)
        ..close();
      canvas.drawPath(frontPath, Paint()..color = _barFront);
      _drawPathEdge(canvas, frontPath);
    }

    // End caps for visual polish
    _drawEndCap(canvas, fromPos, perpX, perpY, hw, hd, topOffsetY);
    _drawEndCap(canvas, toPos, perpX, perpY, hw, hd, topOffsetY);
  }

  void _drawPathEdge(Canvas canvas, Path path) {
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF3A3A3A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawEndCap(Canvas canvas, Offset pos, double perpX, double perpY,
      double hw, double hd, double topOffsetY) {
    final capPath = Path()
      ..moveTo(pos.dx + perpX * hw, pos.dy + perpY * hw + topOffsetY)
      ..lineTo(pos.dx - perpX * hw, pos.dy - perpY * hw + topOffsetY)
      ..lineTo(pos.dx - perpX * hw, pos.dy - perpY * hw + hd)
      ..lineTo(pos.dx + perpX * hw, pos.dy + perpY * hw + hd)
      ..close();
    canvas.drawPath(capPath, Paint()..color = _barFront);
    _drawPathEdge(canvas, capPath);
  }

  void _drawGoalMarker(Canvas canvas, Size size) {
    final goalNode = puzzle.nodes.firstWhere(
      (n) => n.id == puzzle.goalNodeId,
      orElse: () => puzzle.nodes.first,
    );
    final pos = _nodeToScreen(goalNode, size);

    // Draw star above goal position
    final starPos = Offset(pos.dx, pos.dy - 30);
    _drawStar(canvas, starPos, 14, Paint()..color = Colors.amber);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    const points = 5;
    const innerRatio = 0.4;

    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : radius * innerRatio;
      final angle = (i * math.pi / points) - math.pi / 2;
      final point = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // Star outline
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.amber.shade800
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawCube(Canvas canvas, Size size) {
    Offset cubePos;
    double cubeSize = 32.0;
    double bounceOffset = 0.0;

    if (animatingFrom != null && animatingTo != null) {
      // Interpolate position during animation
      final fromPos = _nodeToScreen(animatingFrom!, size);
      final toPos = _nodeToScreen(animatingTo!, size);
      cubePos = Offset.lerp(fromPos, toPos, animationValue)!;

      // Bounce effect
      bounceOffset = math.sin(animationValue * math.pi) * 20.0;

      // Scale pulse
      cubeSize = 32.0 + math.sin(animationValue * math.pi) * 6.0;
    } else {
      final currentNode = puzzle.currentNode;
      if (currentNode == null) return;
      cubePos = _nodeToScreen(currentNode, size);
    }

    // Position cube on top of the bar
    cubePos = Offset(cubePos.dx, cubePos.dy - 20 - bounceOffset);

    // Draw cube shadow
    final shadowOpacity = (0.3 - bounceOffset * 0.008).clamp(0.1, 0.3);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cubePos.dx, cubePos.dy + bounceOffset + cubeSize * 0.8),
        width: cubeSize * 1.2,
        height: cubeSize * 0.4,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: shadowOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Draw isometric cube (red like reference)
    _drawIsometricCube(canvas, cubePos, cubeSize, const Color(0xFFE53935));
  }

  void _drawIsometricCube(Canvas canvas, Offset center, double size, Color color) {
    // Isometric cube dimensions
    final halfWidth = size * 0.5;
    final height = size * 0.6;

    // Top diamond
    final top = Offset(center.dx, center.dy - height);
    final right = Offset(center.dx + halfWidth, center.dy - height * 0.3);
    final bottom = Offset(center.dx, center.dy);
    final left = Offset(center.dx - halfWidth, center.dy - height * 0.3);

    // Bottom points (for side faces)
    final bottomRight = Offset(center.dx + halfWidth, center.dy + height * 0.4);
    final bottomLeft = Offset(center.dx - halfWidth, center.dy + height * 0.4);
    final bottomCenter = Offset(center.dx, center.dy + height * 0.7);

    // Draw faces back to front

    // Left face (medium brightness)
    final leftPath = Path()
      ..moveTo(left.dx, left.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(bottomCenter.dx, bottomCenter.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..close();
    canvas.drawPath(leftPath, Paint()..color = _adjustBrightness(color, 0.8));

    // Right face (darkest)
    final rightPath = Path()
      ..moveTo(right.dx, right.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(bottomCenter.dx, bottomCenter.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..close();
    canvas.drawPath(rightPath, Paint()..color = _adjustBrightness(color, 0.6));

    // Top face (brightest)
    final topPath = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(left.dx, left.dy)
      ..close();
    canvas.drawPath(topPath, Paint()..color = _adjustBrightness(color, 1.0));

    // Draw edges
    final edgePaint = Paint()
      ..color = _adjustBrightness(color, 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(topPath, edgePaint);
    canvas.drawPath(leftPath, edgePaint);
    canvas.drawPath(rightPath, edgePaint);
  }

  Color _adjustBrightness(Color color, double factor) {
    return Color.fromARGB(
      (color.a * 255).round(),
      (color.r * 255 * factor).clamp(0, 255).toInt(),
      (color.g * 255 * factor).clamp(0, 255).toInt(),
      (color.b * 255 * factor).clamp(0, 255).toInt(),
    );
  }

  @override
  bool shouldRepaint(covariant _MobiusPainter oldDelegate) {
    return oldDelegate.puzzle.currentNodeId != puzzle.currentNodeId ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.animatingFrom != animatingFrom ||
        oldDelegate.animatingTo != animatingTo;
  }
}

// ============================================
// STANDALONE TEST WIDGET FOR PROTOTYPING
// ============================================

/// A standalone test screen for the Möbius puzzle prototype
class MobiusTestScreen extends StatefulWidget {
  const MobiusTestScreen({super.key});

  @override
  State<MobiusTestScreen> createState() => _MobiusTestScreenState();
}

class _MobiusTestScreenState extends State<MobiusTestScreen> {
  late MobiusPuzzle _puzzle;
  int _currentLevel = 1;

  @override
  void initState() {
    super.initState();
    _loadLevel(_currentLevel);
  }

  void _loadLevel(int level) {
    setState(() {
      _currentLevel = level;
      switch (level) {
        case 1:
          _puzzle = MobiusPuzzle.sampleLevel1();
          break;
        case 2:
          _puzzle = MobiusPuzzle.sampleLevel2();
          break;
        case 3:
          _puzzle = MobiusPuzzle.sampleLevel3();
          break;
        default:
          _puzzle = MobiusPuzzle.sampleLevel1();
      }
    });
  }

  void _onComplete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Level Complete!'),
        content: Text('You completed level $_currentLevel in ${_puzzle.moveCount} moves!'),
        actions: [
          if (_currentLevel < 3)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _loadLevel(_currentLevel + 1);
              },
              child: const Text('Next Level'),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadLevel(_currentLevel);
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Möbius Prototype'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.layers),
            tooltip: 'Select Level',
            onSelected: _loadLevel,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 1, child: Text('Level 1: Tutorial')),
              const PopupMenuItem(value: 2, child: Text('Level 2: Staircase')),
              const PopupMenuItem(value: 3, child: Text('Level 3: Complex')),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: MobiusGrid(
          key: ValueKey(_currentLevel), // Force rebuild on level change
          puzzle: _puzzle,
          onComplete: _onComplete,
          onMove: () => setState(() {}),
        ),
      ),
    );
  }
}
