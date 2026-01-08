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
class _MobiusPainter extends CustomPainter {
  final MobiusPuzzle puzzle;
  final ThemeData theme;
  final double animationValue;
  final MobiusNode? animatingFrom;
  final MobiusNode? animatingTo;

  // Isometric projection constants
  static const double _isoAngle = 30.0 * math.pi / 180; // 30 degrees
  static const double _scale = 60.0; // Base scale for node spacing

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
    // Draw beams (edges)
    _drawBeams(canvas, size);

    // Draw nodes
    _drawNodes(canvas, size);

    // Draw cube (player)
    _drawCube(canvas, size);
  }

  void _drawBeams(Canvas canvas, Size size) {
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

      final fromPos = _nodeToScreen(fromNode, size);
      final toPos = _nodeToScreen(toNode, size);

      // Draw thick beam line with 3D effect
      // Shadow
      canvas.drawLine(
        fromPos + const Offset(2, 4),
        toPos + const Offset(2, 4),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.2)
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round,
      );

      // Main beam (dark)
      canvas.drawLine(
        fromPos,
        toPos,
        Paint()
          ..color = const Color(0xFF4A4A4A)
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round,
      );

      // Highlight on top
      canvas.drawLine(
        fromPos + const Offset(0, -2),
        toPos + const Offset(0, -2),
        Paint()
          ..color = const Color(0xFF6A6A6A)
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawNodes(Canvas canvas, Size size) {
    // Sort nodes by depth (draw far nodes first)
    final sortedNodes = List<MobiusNode>.from(puzzle.nodes);
    sortedNodes.sort((a, b) => (b.z + b.y).compareTo(a.z + a.y));

    for (final node in sortedNodes) {
      final pos = _nodeToScreen(node, size);
      final isGoal = node.id == puzzle.goalNodeId;
      final isStart = node.id == puzzle.startNodeId;

      // Determine node color - using bright, distinct colors
      Color nodeColor;
      if (isGoal) {
        nodeColor = const Color(0xFF10B981); // Bright green
      } else if (isStart) {
        nodeColor = const Color(0xFF3B82F6); // Bright blue
      } else {
        nodeColor = const Color(0xFF6B7280); // Gray
      }

      // Draw larger isometric cube for each node
      const double cubeSize = 30.0;
      _drawIsometricCube(canvas, pos, cubeSize, nodeColor);

      // Draw goal star on top
      if (isGoal) {
        final starPos = Offset(pos.dx, pos.dy - cubeSize * 0.9);
        _drawStar(canvas, starPos, 12, Paint()..color = Colors.amber);
      }
    }
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
  }

  void _drawCube(Canvas canvas, Size size) {
    Offset cubePos;
    double cubeSize = 22.0;
    double bounceOffset = 0.0;

    if (animatingFrom != null && animatingTo != null) {
      // Interpolate position during animation
      final fromPos = _nodeToScreen(animatingFrom!, size);
      final toPos = _nodeToScreen(animatingTo!, size);
      cubePos = Offset.lerp(fromPos, toPos, animationValue)!;

      // Bounce effect - arc up then down during movement
      // Peak at 0.5 (middle of animation)
      bounceOffset = math.sin(animationValue * math.pi) * 15.0;

      // Scale pulse - slightly larger during movement
      cubeSize = 22.0 + math.sin(animationValue * math.pi) * 4.0;
    } else {
      final currentNode = puzzle.currentNode;
      if (currentNode == null) return;
      cubePos = _nodeToScreen(currentNode, size);
    }

    // Apply bounce offset (move up)
    cubePos = Offset(cubePos.dx, cubePos.dy - bounceOffset);

    // Draw cube shadow (moves with bounce, gets smaller when higher)
    final shadowDistance = 4.0 + bounceOffset * 0.3;
    final shadowSize = 14.0 - bounceOffset * 0.2;
    final shadowOpacity = 0.2 - bounceOffset * 0.005;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: shadowOpacity.clamp(0.05, 0.25))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + bounceOffset * 0.2);
    canvas.drawCircle(
      Offset(cubePos.dx + 2, cubePos.dy + bounceOffset + shadowDistance),
      shadowSize,
      shadowPaint,
    );

    // Draw isometric cube
    _drawIsometricCube(canvas, cubePos, cubeSize, theme.colorScheme.primary);
  }

  void _drawIsometricCube(Canvas canvas, Offset center, double size, Color color) {
    // Isometric cube vertices
    final topOffset = Offset(0, -size * 0.8);
    final leftOffset = Offset(-size * 0.7, size * 0.4);
    final rightOffset = Offset(size * 0.7, size * 0.4);

    // Top face (brightest)
    final topPath = Path()
      ..moveTo(center.dx, center.dy + topOffset.dy)
      ..lineTo(center.dx + rightOffset.dx * 0.7, center.dy)
      ..lineTo(center.dx, center.dy - topOffset.dy * 0.3)
      ..lineTo(center.dx + leftOffset.dx * 0.7, center.dy)
      ..close();

    // Left face (medium)
    final leftPath = Path()
      ..moveTo(center.dx + leftOffset.dx * 0.7, center.dy)
      ..lineTo(center.dx, center.dy - topOffset.dy * 0.3)
      ..lineTo(center.dx, center.dy + size * 0.6)
      ..lineTo(center.dx + leftOffset.dx * 0.7, center.dy + leftOffset.dy)
      ..close();

    // Right face (darkest)
    final rightPath = Path()
      ..moveTo(center.dx + rightOffset.dx * 0.7, center.dy)
      ..lineTo(center.dx, center.dy - topOffset.dy * 0.3)
      ..lineTo(center.dx, center.dy + size * 0.6)
      ..lineTo(center.dx + rightOffset.dx * 0.7, center.dy + rightOffset.dy)
      ..close();

    // Draw faces
    final topPaint = Paint()..color = _lighten(color, 0.2);
    final leftPaint = Paint()..color = color;
    final rightPaint = Paint()..color = _darken(color, 0.2);

    canvas.drawPath(rightPath, rightPaint);
    canvas.drawPath(leftPath, leftPaint);
    canvas.drawPath(topPath, topPaint);

    // Draw edges
    final edgePaint = Paint()
      ..color = _darken(color, 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(topPath, edgePaint);
    canvas.drawPath(leftPath, edgePaint);
    canvas.drawPath(rightPath, edgePaint);
  }

  Color _lighten(Color color, double amount) {
    return Color.fromARGB(
      color.a.toInt(),
      (color.r + (255 - color.r) * amount).clamp(0, 255).toInt(),
      (color.g + (255 - color.g) * amount).clamp(0, 255).toInt(),
      (color.b + (255 - color.b) * amount).clamp(0, 255).toInt(),
    );
  }

  Color _darken(Color color, double amount) {
    return Color.fromARGB(
      color.a.toInt(),
      (color.r * (1 - amount)).clamp(0, 255).toInt(),
      (color.g * (1 - amount)).clamp(0, 255).toInt(),
      (color.b * (1 - amount)).clamp(0, 255).toInt(),
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
