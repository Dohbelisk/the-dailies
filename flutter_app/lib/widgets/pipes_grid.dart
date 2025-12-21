import 'package:flutter/material.dart';
import '../models/game_models.dart';

class PipesGrid extends StatelessWidget {
  final PipesPuzzle puzzle;
  final Function(String color, int row, int col) onPathStart;
  final Function(int row, int col) onPathExtend;
  final VoidCallback onPathEnd;
  final VoidCallback onReset;

  const PipesGrid({
    super.key,
    required this.puzzle,
    required this.onPathStart,
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
            final endpoint = puzzle.getEndpointAt(cellPos[0], cellPos[1]);
            if (endpoint != null) {
              onPathStart(endpoint.color, cellPos[0], cellPos[1]);
            }
          }
        },
        onPanUpdate: (details) {
          final cellPos = _getCellFromPosition(details.localPosition, cellSize);
          if (cellPos != null) {
            onPathExtend(cellPos[0], cellPos[1]);
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
              color: theme.colorScheme.outline.withOpacity(0.3),
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
      ..color = theme.colorScheme.outline.withOpacity(0.2)
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
        Paint()..color = theme.colorScheme.outline.withOpacity(0.5),
      );
    }

    // Draw paths
    for (final entry in puzzle.currentPaths.entries) {
      final color = getColor(entry.key);
      final path = entry.value;
      if (path.length < 2) continue;

      final pathPaint = Paint()
        ..color = color
        ..strokeWidth = cellSize * 0.4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final pathPath = Path();
      for (int i = 0; i < path.length; i++) {
        final centerX = (path[i][1] + 0.5) * cellSize;
        final centerY = (path[i][0] + 0.5) * cellSize;
        if (i == 0) {
          pathPath.moveTo(centerX, centerY);
        } else {
          pathPath.lineTo(centerX, centerY);
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
        Paint()..color = Colors.white.withOpacity(0.4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PipesGridPainter oldDelegate) => true;
}
