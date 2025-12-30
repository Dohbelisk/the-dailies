import 'package:flutter/material.dart';
import '../models/game_models.dart';

class LightsOutGrid extends StatelessWidget {
  final LightsOutPuzzle puzzle;
  final Function(int row, int col) onCellTap;
  final VoidCallback onReset;

  const LightsOutGrid({
    super.key,
    required this.puzzle,
    required this.onCellTap,
    required this.onReset,
  });

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
                    'Moves: ${puzzle.moveCount}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Optimal: ${puzzle.minMoves} | Lights on: ${puzzle.lightsOnCount}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              IconButton.outlined(
                onPressed: puzzle.moveCount == 0 ? null : onReset,
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

        // Instructions
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            'Tap a light to toggle it and its neighbors',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context, BoxConstraints constraints) {
    final maxSize = constraints.maxWidth.clamp(0, constraints.maxHeight);
    final cellSize = (maxSize / puzzle.cols).clamp(40.0, 80.0);
    final gridWidth = cellSize * puzzle.cols;
    final gridHeight = cellSize * puzzle.rows;
    final gap = 4.0;

    return Center(
      child: SizedBox(
        width: gridWidth + gap * (puzzle.cols - 1),
        height: gridHeight + gap * (puzzle.rows - 1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int row = 0; row < puzzle.rows; row++) ...[
              if (row > 0) SizedBox(height: gap),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int col = 0; col < puzzle.cols; col++) ...[
                    if (col > 0) SizedBox(width: gap),
                    _buildCell(context, row, col, cellSize),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCell(BuildContext context, int row, int col, double size) {
    final theme = Theme.of(context);
    final isOn = puzzle.currentState[row][col];

    return GestureDetector(
      onTap: () => onCellTap(row, col),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isOn
              ? const Color(0xFFFDD835) // Bright yellow for "on"
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isOn
                ? const Color(0xFFF9A825)
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: isOn
              ? [
                  BoxShadow(
                    color: const Color(0xFFFDD835).withValues(alpha: 0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Icon(
            isOn ? Icons.lightbulb : Icons.lightbulb_outline,
            color: isOn
                ? const Color(0xFFF57F17)
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}
