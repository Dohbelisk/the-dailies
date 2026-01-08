import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_models.dart';

/// Sokoban grid widget - push boxes to target positions
class SokobanGrid extends StatefulWidget {
  final SokobanPuzzle puzzle;
  final VoidCallback? onComplete;
  final VoidCallback? onMove;

  const SokobanGrid({
    super.key,
    required this.puzzle,
    this.onComplete,
    this.onMove,
  });

  @override
  State<SokobanGrid> createState() => _SokobanGridState();
}

class _SokobanGridState extends State<SokobanGrid> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final puzzle = widget.puzzle;

    return Column(
      children: [
        // Stats bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatChip(
                context,
                icon: Icons.directions_walk_rounded,
                label: 'Moves',
                value: '${puzzle.moveCount}',
              ),
              _buildStatChip(
                context,
                icon: Icons.push_pin_rounded,
                label: 'Pushes',
                value: '${puzzle.pushCount}',
              ),
              _buildStatChip(
                context,
                icon: Icons.flag_rounded,
                label: 'Boxes',
                value: '${_getBoxesOnTarget()}/${puzzle.targetPositions.length}',
              ),
            ],
          ),
        ),

        // Grid
        Expanded(
          child: Center(
            child: GestureDetector(
              onPanEnd: _onSwipe,
              child: AspectRatio(
                aspectRatio: puzzle.cols / puzzle.rows,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cellSize = constraints.maxWidth / puzzle.cols;

                    return CustomPaint(
                      painter: _SokobanPainter(
                        puzzle: puzzle,
                        cellSize: cellSize,
                        theme: theme,
                      ),
                      size: Size(
                        puzzle.cols * cellSize,
                        puzzle.rows * cellSize,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),

        // Controls
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // D-pad controls
              SizedBox(
                width: 180,
                height: 180,
                child: Stack(
                  children: [
                    // Up
                    Positioned(
                      left: 60,
                      top: 0,
                      child: _buildControlButton(
                        icon: Icons.arrow_upward_rounded,
                        onPressed: () => _move(-1, 0),
                      ),
                    ),
                    // Down
                    Positioned(
                      left: 60,
                      bottom: 0,
                      child: _buildControlButton(
                        icon: Icons.arrow_downward_rounded,
                        onPressed: () => _move(1, 0),
                      ),
                    ),
                    // Left
                    Positioned(
                      left: 0,
                      top: 60,
                      child: _buildControlButton(
                        icon: Icons.arrow_back_rounded,
                        onPressed: () => _move(0, -1),
                      ),
                    ),
                    // Right
                    Positioned(
                      right: 0,
                      top: 60,
                      child: _buildControlButton(
                        icon: Icons.arrow_forward_rounded,
                        onPressed: () => _move(0, 1),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Undo button
              TextButton.icon(
                onPressed: puzzle.moveHistory.isNotEmpty
                    ? () {
                        setState(() => puzzle.undo());
                        widget.onMove?.call();
                      }
                    : null,
                icon: const Icon(Icons.undo_rounded),
                label: const Text('Undo'),
              ),
            ],
          ),
        ),

        // Instructions
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'Push all boxes to the target spots',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 60,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Icon(icon, size: 28),
      ),
    );
  }

  int _getBoxesOnTarget() {
    int count = 0;
    for (final box in widget.puzzle.boxPositions) {
      if (widget.puzzle.isBoxOnTarget(box.$1, box.$2)) {
        count++;
      }
    }
    return count;
  }

  void _move(int dRow, int dCol) {
    if (widget.puzzle.isComplete) return;

    HapticFeedback.lightImpact();

    final moved = widget.puzzle.move(dRow, dCol);
    if (moved) {
      setState(() {});
      widget.onMove?.call();

      if (widget.puzzle.isComplete) {
        HapticFeedback.mediumImpact();
        widget.onComplete?.call();
      }
    }
  }

  void _onSwipe(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond;
    final dx = velocity.dx;
    final dy = velocity.dy;

    if (dx.abs() > dy.abs()) {
      // Horizontal swipe
      if (dx > 100) {
        _move(0, 1); // Right
      } else if (dx < -100) {
        _move(0, -1); // Left
      }
    } else {
      // Vertical swipe
      if (dy > 100) {
        _move(1, 0); // Down
      } else if (dy < -100) {
        _move(-1, 0); // Up
      }
    }
  }
}

class _SokobanPainter extends CustomPainter {
  final SokobanPuzzle puzzle;
  final double cellSize;
  final ThemeData theme;

  _SokobanPainter({
    required this.puzzle,
    required this.cellSize,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = theme.brightness == Brightness.dark;

    // Draw cells
    for (int row = 0; row < puzzle.rows; row++) {
      for (int col = 0; col < puzzle.cols; col++) {
        final cell = puzzle.map[row][col];
        final rect = Rect.fromLTWH(
          col * cellSize,
          row * cellSize,
          cellSize,
          cellSize,
        );

        // Draw cell background
        final cellPaint = Paint();
        switch (cell) {
          case SokobanCell.wall:
            cellPaint.color = isDark
                ? const Color(0xFF4A5568)
                : const Color(0xFF718096);
            canvas.drawRect(rect, cellPaint);
            // Draw brick pattern
            _drawBrickPattern(canvas, rect, isDark);
            break;
          case SokobanCell.floor:
            cellPaint.color = isDark
                ? const Color(0xFF2D3748)
                : const Color(0xFFE2E8F0);
            canvas.drawRect(rect, cellPaint);
            break;
          case SokobanCell.target:
            cellPaint.color = isDark
                ? const Color(0xFF2D3748)
                : const Color(0xFFE2E8F0);
            canvas.drawRect(rect, cellPaint);
            // Draw target marker
            _drawTarget(canvas, rect);
            break;
        }
      }
    }

    // Draw boxes
    for (final box in puzzle.boxPositions) {
      final rect = Rect.fromLTWH(
        box.$2 * cellSize + 2,
        box.$1 * cellSize + 2,
        cellSize - 4,
        cellSize - 4,
      );
      final isOnTarget = puzzle.isBoxOnTarget(box.$1, box.$2);
      _drawBox(canvas, rect, isOnTarget);
    }

    // Draw player
    _drawPlayer(canvas, puzzle.playerRow, puzzle.playerCol);
  }

  void _drawBrickPattern(Canvas canvas, Rect rect, bool isDark) {
    final linePaint = Paint()
      ..color = (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.3)
      ..strokeWidth = 1;

    // Horizontal lines
    final step = cellSize / 3;
    for (double y = rect.top + step; y < rect.bottom; y += step) {
      canvas.drawLine(
        Offset(rect.left, y),
        Offset(rect.right, y),
        linePaint,
      );
    }
  }

  void _drawTarget(Canvas canvas, Rect rect) {
    final center = rect.center;
    final radius = cellSize * 0.3;

    final targetPaint = Paint()
      ..color = Colors.green.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, radius, targetPaint);

    // Draw X
    final halfSize = radius * 0.5;
    canvas.drawLine(
      Offset(center.dx - halfSize, center.dy - halfSize),
      Offset(center.dx + halfSize, center.dy + halfSize),
      targetPaint,
    );
    canvas.drawLine(
      Offset(center.dx + halfSize, center.dy - halfSize),
      Offset(center.dx - halfSize, center.dy + halfSize),
      targetPaint,
    );
  }

  void _drawBox(Canvas canvas, Rect rect, bool isOnTarget) {
    final boxPaint = Paint()
      ..color = isOnTarget
          ? Colors.green.shade600
          : Colors.brown.shade400;

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
    canvas.drawRRect(rrect, boxPaint);

    // Draw box highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left + 2, rect.top + 2, rect.width - 4, rect.height - 4),
        const Radius.circular(3),
      ),
      highlightPaint,
    );

    // Draw box pattern
    final linePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..strokeWidth = 1;

    // Cross pattern
    canvas.drawLine(
      Offset(rect.left + 4, rect.top + 4),
      Offset(rect.right - 4, rect.bottom - 4),
      linePaint,
    );
    canvas.drawLine(
      Offset(rect.right - 4, rect.top + 4),
      Offset(rect.left + 4, rect.bottom - 4),
      linePaint,
    );
  }

  void _drawPlayer(Canvas canvas, int row, int col) {
    final center = Offset(
      col * cellSize + cellSize / 2,
      row * cellSize + cellSize / 2,
    );
    final radius = cellSize * 0.35;

    // Body
    final bodyPaint = Paint()
      ..color = Colors.blue.shade600;
    canvas.drawCircle(center, radius, bodyPaint);

    // Face highlight
    final facePaint = Paint()
      ..color = Colors.blue.shade300;
    canvas.drawCircle(
      Offset(center.dx, center.dy - radius * 0.1),
      radius * 0.7,
      facePaint,
    );

    // Eyes
    final eyePaint = Paint()..color = Colors.white;
    final eyeRadius = radius * 0.15;
    canvas.drawCircle(
      Offset(center.dx - radius * 0.25, center.dy - radius * 0.15),
      eyeRadius,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.25, center.dy - radius * 0.15),
      eyeRadius,
      eyePaint,
    );

    // Pupils
    final pupilPaint = Paint()..color = Colors.black;
    canvas.drawCircle(
      Offset(center.dx - radius * 0.25, center.dy - radius * 0.15),
      eyeRadius * 0.5,
      pupilPaint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.25, center.dy - radius * 0.15),
      eyeRadius * 0.5,
      pupilPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SokobanPainter oldDelegate) {
    return puzzle.playerRow != oldDelegate.puzzle.playerRow ||
        puzzle.playerCol != oldDelegate.puzzle.playerCol ||
        puzzle.moveCount != oldDelegate.puzzle.moveCount;
  }
}

// =============================================================================
// TEST SCREEN
// =============================================================================

class SokobanTestScreen extends StatefulWidget {
  const SokobanTestScreen({super.key});

  @override
  State<SokobanTestScreen> createState() => _SokobanTestScreenState();
}

class _SokobanTestScreenState extends State<SokobanTestScreen> {
  late SokobanPuzzle _puzzle;
  late List<(int, int)> _initialBoxPositions;
  late int _initialPlayerRow;
  late int _initialPlayerCol;
  int _currentLevel = 1;

  @override
  void initState() {
    super.initState();
    _loadLevel(1);
  }

  void _loadLevel(int level) {
    setState(() {
      _currentLevel = level;
      switch (level) {
        case 1:
          _puzzle = SokobanPuzzle.sampleLevel1();
        case 2:
          _puzzle = SokobanPuzzle.sampleLevel2();
        case 3:
          _puzzle = SokobanPuzzle.sampleLevel3();
        default:
          _puzzle = SokobanPuzzle.sampleLevel1();
      }
      _initialBoxPositions = List.from(_puzzle.boxPositions);
      _initialPlayerRow = _puzzle.playerRow;
      _initialPlayerCol = _puzzle.playerCol;
    });
  }

  void _onComplete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Level Complete!'),
        content: Text(
          'Moves: ${_puzzle.moveCount}\n'
          'Pushes: ${_puzzle.pushCount}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetLevel();
            },
            child: const Text('Play Again'),
          ),
          if (_currentLevel < 3)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _loadLevel(_currentLevel + 1);
              },
              child: const Text('Next Level'),
            ),
        ],
      ),
    );
  }

  void _resetLevel() {
    setState(() {
      _puzzle.reset(_initialBoxPositions, _initialPlayerRow, _initialPlayerCol);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sokoban'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetLevel,
            tooltip: 'Reset',
          ),
        ],
      ),
      body: Column(
        children: [
          // Level selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 1; i <= 3; i++) ...[
                  if (i > 1) const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('Level $i'),
                    selected: _currentLevel == i,
                    onSelected: (_) => _loadLevel(i),
                  ),
                ],
              ],
            ),
          ),

          // Grid info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${_puzzle.rows}x${_puzzle.cols} grid, ${_puzzle.boxPositions.length} boxes',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Game grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SokobanGrid(
                key: ValueKey('sokoban-$_currentLevel-${_puzzle.hashCode}'),
                puzzle: _puzzle,
                onComplete: _onComplete,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
