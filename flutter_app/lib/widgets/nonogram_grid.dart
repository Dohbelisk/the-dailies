import 'package:flutter/material.dart';
import '../models/game_models.dart';

class NonogramGrid extends StatelessWidget {
  final NonogramPuzzle puzzle;
  final bool markMode;
  final Function(int row, int col) onCellTap;
  final VoidCallback onToggleMarkMode;

  const NonogramGrid({
    super.key,
    required this.puzzle,
    required this.markMode,
    required this.onCellTap,
    required this.onToggleMarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate the maximum clue width for rows and height for columns
    final maxRowClueLength =
        puzzle.rowClues.map((c) => c.length).reduce((a, b) => a > b ? a : b);
    final maxColClueLength =
        puzzle.colClues.map((c) => c.length).reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        // Progress indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${puzzle.filledCount} / ${puzzle.totalToFill} cells',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Toggle mark mode button
              FilledButton.tonal(
                onPressed: onToggleMarkMode,
                style: FilledButton.styleFrom(
                  backgroundColor: markMode
                      ? theme.colorScheme.errorContainer
                      : theme.colorScheme.surfaceContainerHighest,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      markMode ? Icons.close : Icons.square_rounded,
                      size: 18,
                      color: markMode
                          ? theme.colorScheme.onErrorContainer
                          : theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      markMode ? 'Mark X' : 'Fill',
                      style: TextStyle(
                        color: markMode
                            ? theme.colorScheme.onErrorContainer
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Grid with clues
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate cell size based on available space
              final availableWidth = constraints.maxWidth;
              final availableHeight = constraints.maxHeight;

              // Calculate space needed for clues
              const clueUnitSize = 20.0;
              final rowClueWidth = maxRowClueLength * clueUnitSize + 8;
              final colClueHeight = maxColClueLength * clueUnitSize + 8;

              // Calculate cell size
              final gridWidth = availableWidth - rowClueWidth;
              final gridHeight = availableHeight - colClueHeight;
              final cellSize = (gridWidth / puzzle.cols)
                  .clamp(0.0, gridHeight / puzzle.rows);

              return SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _buildGridWithClues(
                    context,
                    cellSize,
                    rowClueWidth,
                    colClueHeight,
                    clueUnitSize,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGridWithClues(
    BuildContext context,
    double cellSize,
    double rowClueWidth,
    double colClueHeight,
    double clueUnitSize,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row: empty corner + column clues
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Empty corner
            SizedBox(width: rowClueWidth, height: colClueHeight),
            // Column clues
            for (int c = 0; c < puzzle.cols; c++)
              SizedBox(
                width: cellSize,
                height: colClueHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (final clue in puzzle.colClues[c])
                      SizedBox(
                        height: clueUnitSize,
                        child: Center(
                          child: Text(
                            '$clue',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
        // Grid rows with row clues
        for (int r = 0; r < puzzle.rows; r++)
          Row(
            children: [
              // Row clues
              SizedBox(
                width: rowClueWidth,
                height: cellSize,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (final clue in puzzle.rowClues[r])
                      SizedBox(
                        width: clueUnitSize,
                        child: Center(
                          child: Text(
                            '$clue',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
              // Grid cells
              for (int c = 0; c < puzzle.cols; c++)
                _buildCell(context, r, c, cellSize),
            ],
          ),
      ],
    );
  }

  Widget _buildCell(BuildContext context, int row, int col, double size) {
    final theme = Theme.of(context);
    final cellValue = puzzle.userGrid[row][col];

    Color bgColor;
    Widget? child;

    if (cellValue == 1) {
      // Filled
      bgColor = theme.colorScheme.primary;
    } else if (cellValue == -1) {
      // Marked as empty (X)
      bgColor = theme.colorScheme.surface;
      child = Icon(
        Icons.close,
        size: size * 0.6,
        color: theme.colorScheme.error.withOpacity(0.7),
      );
    } else {
      // Unmarked
      bgColor = theme.colorScheme.surface;
    }

    return GestureDetector(
      onTap: () => onCellTap(row, col),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: child,
      ),
    );
  }
}
