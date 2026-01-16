import 'package:flutter/material.dart';
import '../models/game_models.dart';

class PipesGrid extends StatelessWidget {
  final PipesPuzzle puzzle;
  final Function(String color, int row, int col) onPathStart;
  final Function(String color) onPathContinue;
  final Function(String color, int index) onPathTruncateAndContinue;
  final Function(int row, int col, Offset? dragVelocity) onPathExtend;
  final VoidCallback onPathEnd;
  final VoidCallback onReset;

  const PipesGrid({
    super.key,
    required this.puzzle,
    required this.onPathStart,
    required this.onPathContinue,
    required this.onPathTruncateAndContinue,
    required this.onPathExtend,
    required this.onPathEnd,
    required this.onReset,
  });

  static const Map<String, Color> _pipeColors = {
    'red': Color(0xFFE53935),
    'blue': Color(0xFF1E88E5),
    'green': Color(0xFF43A047),
    'yellow': Color(0xFFFDD835),
    'orange': Color(0xFFFB8C00),
    'purple': Color(0xFF8E24AA),
    'pink': Color(0xFFEC407A),
    'cyan': Color(0xFF00ACC1),
  };

  Color _getPipeColor(String colorName) {
    return _pipeColors[colorName.toLowerCase()] ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Info bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connect all pairs',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${puzzle.colors.length} colors to connect',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              IconButton.outlined(
                onPressed: puzzle.currentPaths.isEmpty ? null : onReset,
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Reset puzzle',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Grid
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return _buildGrid(context, constraints);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context, BoxConstraints constraints) {
    final theme = Theme.of(context);
    final cellSize = (constraints.maxWidth.clamp(0, constraints.maxHeight) /
            puzzle.cols)
        .clamp(30.0, 60.0);
    final gridWidth = cellSize * puzzle.cols;
    final gridHeight = cellSize * puzzle.rows;

    return Center(
      child: GestureDetector(
        onPanStart: (details) {
          final cellPos = _getCellFromPosition(details.localPosition, cellSize);
          if (cellPos != null) {
            final row = cellPos[0];
            final col = cellPos[1];

            // Check if this is an endpoint - if so, start fresh from this endpoint
            final endpoint = puzzle.getEndpointAt(row, col);
            if (endpoint != null) {
              onPathStart(endpoint.color, row, col);
              return;
            }

            // Check if this cell is anywhere along an existing path
            for (final entry in puzzle.currentPaths.entries) {
              final color = entry.key;
              final path = entry.value;
              if (path.isNotEmpty) {
                // Find if this cell is in the path
                for (int i = 0; i < path.length; i++) {
                  if (path[i][0] == row && path[i][1] == col) {
                    // Found the cell in this path
                    // Truncate at this position and continue from here
                    // The path keeps cells from 0 to i (inclusive)
                    onPathTruncateAndContinue(color, i);
                    return;
                  }
                }
              }
            }
          }
        },
        onPanUpdate: (details) {
          final cellPos = _getCellFromPosition(details.localPosition, cellSize);
          if (cellPos != null) {
            // Pass velocity for fuzzy logic
            onPathExtend(cellPos[0], cellPos[1], details.delta);
          }
        },
        onPanEnd: (_) => onPathEnd(),
        child: Container(
          width: gridWidth,
          height: gridHeight,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: CustomPaint(
            painter: _PipesGridPainter(
              puzzle: puzzle,
              cellSize: cellSize,
              theme: theme,
              getColor: _getPipeColor,
            ),
          ),
        ),
      ),
    );
  }

  List<int>? _getCellFromPosition(Offset position, double cellSize) {
    final row = (position.dy / cellSize).floor();
    final col = (position.dx / cellSize).floor();
    if (row >= 0 && row < puzzle.rows && col >= 0 && col < puzzle.cols) {
      return [row, col];
    }
    return null;
  }
}

class _PipesGridPainter extends CustomPainter {
  final PipesPuzzle puzzle;
  final double cellSize;
  final ThemeData theme;
  final Color Function(String) getColor;

  _PipesGridPainter({
    required this.puzzle,
    required this.cellSize,
    required this.theme,
    required this.getColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw grid lines
    final gridPaint = Paint()
      ..color = theme.colorScheme.outline.withValues(alpha: 0.2)
      ..strokeWidth = 1;

    for (int i = 0; i <= puzzle.rows; i++) {
      canvas.drawLine(
        Offset(0, i * cellSize),
        Offset(size.width, i * cellSize),
        gridPaint,
      );
    }
    for (int i = 0; i <= puzzle.cols; i++) {
      canvas.drawLine(
        Offset(i * cellSize, 0),
        Offset(i * cellSize, size.height),
        gridPaint,
      );
    }

    // Draw bridges
    for (final bridge in puzzle.bridges) {
      final centerX = (bridge[1] + 0.5) * cellSize;
      final centerY = (bridge[0] + 0.5) * cellSize;
      canvas.drawCircle(
        Offset(centerX, centerY),
        cellSize * 0.15,
        Paint()..color = theme.colorScheme.outline.withValues(alpha: 0.5),
      );
    }

    // Draw paths with rounded corners
    for (final entry in puzzle.currentPaths.entries) {
      final color = getColor(entry.key);
      final path = entry.value;
      if (path.length < 2) continue;

      final pathPaint = Paint()
        ..color = color
        ..strokeWidth = cellSize * 0.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final pathPath = Path();

      // Calculate cell centers for the path
      final centers = path.map((cell) => Offset(
        (cell[1] + 0.5) * cellSize,
        (cell[0] + 0.5) * cellSize,
      )).toList();

      // Start at first cell
      pathPath.moveTo(centers[0].dx, centers[0].dy);

      // For each segment, check if there's a turn and use bezier curve
      for (int i = 1; i < centers.length; i++) {
        if (i < centers.length - 1) {
          // Check if there's a turn at this point
          final prev = centers[i - 1];
          final curr = centers[i];
          final next = centers[i + 1];

          // Calculate direction vectors
          final dir1 = Offset(curr.dx - prev.dx, curr.dy - prev.dy);
          final dir2 = Offset(next.dx - curr.dx, next.dy - curr.dy);

          // Check if direction changes (turn detected)
          final isTurn = (dir1.dx != 0 && dir2.dy != 0) || (dir1.dy != 0 && dir2.dx != 0);

          if (isTurn) {
            // Use quadratic bezier for smooth corner
            // Calculate the corner radius (fraction of cell size)
            final cornerRadius = cellSize * 0.35;

            // Calculate points before and after the corner
            final dir1Norm = dir1.distance > 0
                ? Offset(dir1.dx / dir1.distance, dir1.dy / dir1.distance)
                : Offset.zero;
            final dir2Norm = dir2.distance > 0
                ? Offset(dir2.dx / dir2.distance, dir2.dy / dir2.distance)
                : Offset.zero;

            final beforeCorner = Offset(
              curr.dx - dir1Norm.dx * cornerRadius,
              curr.dy - dir1Norm.dy * cornerRadius,
            );
            final afterCorner = Offset(
              curr.dx + dir2Norm.dx * cornerRadius,
              curr.dy + dir2Norm.dy * cornerRadius,
            );

            // Draw line to before corner, then curve to after corner
            pathPath.lineTo(beforeCorner.dx, beforeCorner.dy);
            pathPath.quadraticBezierTo(curr.dx, curr.dy, afterCorner.dx, afterCorner.dy);
          } else {
            // Straight segment
            pathPath.lineTo(curr.dx, curr.dy);
          }
        } else {
          // Last segment - just draw to end
          pathPath.lineTo(centers[i].dx, centers[i].dy);
        }
      }

      canvas.drawPath(pathPath, pathPaint);
    }

    // Draw endpoints
    for (final endpoint in puzzle.endpoints) {
      final color = getColor(endpoint.color);
      final centerX = (endpoint.col + 0.5) * cellSize;
      final centerY = (endpoint.row + 0.5) * cellSize;

      // Outer circle
      canvas.drawCircle(
        Offset(centerX, centerY),
        cellSize * 0.35,
        Paint()..color = color,
      );

      // Inner highlight
      canvas.drawCircle(
        Offset(centerX - cellSize * 0.08, centerY - cellSize * 0.08),
        cellSize * 0.12,
        Paint()..color = Colors.white.withValues(alpha: 0.4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PipesGridPainter oldDelegate) => true;
}
