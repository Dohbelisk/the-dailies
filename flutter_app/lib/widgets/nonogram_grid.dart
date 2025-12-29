import 'package:flutter/material.dart';
import '../models/game_models.dart';

class NonogramGrid extends StatefulWidget {
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
  State<NonogramGrid> createState() => _NonogramGridState();
}

class _NonogramGridState extends State<NonogramGrid> {
  // Track cells visited during current drag to avoid re-triggering
  final Set<String> _draggedCells = {};

  // Track cells we've already changed in this drag (to avoid re-toggling)
  final Set<String> _changedCells = {};

  // Grid layout info for drag detection
  double _cellSize = 0;
  double _rowClueWidth = 0;
  double _colClueHeight = 0;

  // Track the target state for the current drag
  // null = no drag, 1 = filling, -1 = marking, 0 = clearing
  int? _dragTargetState;

  // Track drag direction: null = not set, true = horizontal, false = vertical
  bool? _dragIsHorizontal;
  int? _dragStartRow;
  int? _dragStartCol;

  void _handleDragStart(DragStartDetails details) {
    _draggedCells.clear();
    _changedCells.clear();
    _dragTargetState = null;
    _dragIsHorizontal = null;
    _dragStartRow = null;
    _dragStartCol = null;
    _handleDragAt(details.localPosition, isStart: true);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _handleDragAt(details.localPosition, isStart: false);
  }

  void _handleDragAt(Offset position, {bool isStart = false}) {
    if (_cellSize <= 0) return;

    // Calculate which cell is at this position
    final gridX = position.dx - _rowClueWidth;
    final gridY = position.dy - _colClueHeight;

    if (gridX < 0 || gridY < 0) return;

    var col = (gridX / _cellSize).floor();
    var row = (gridY / _cellSize).floor();

    if (row < 0 || row >= widget.puzzle.rows ||
        col < 0 || col >= widget.puzzle.cols) {
      return;
    }

    // On first cell, record starting position
    if (_dragStartRow == null) {
      _dragStartRow = row;
      _dragStartCol = col;
    } else if (_dragIsHorizontal == null && (row != _dragStartRow || col != _dragStartCol)) {
      // Determine direction on first movement away from start
      // If only column changed -> horizontal
      // If only row changed -> vertical
      // If both changed, pick based on which moved more (using raw position)
      final rowDiff = (row - _dragStartRow!).abs();
      final colDiff = (col - _dragStartCol!).abs();

      if (colDiff > 0 && rowDiff == 0) {
        _dragIsHorizontal = true;
      } else if (rowDiff > 0 && colDiff == 0) {
        _dragIsHorizontal = false;
      } else {
        // Both changed - use pixel distance to determine intent
        final pixelRowDiff = (position.dy - (_colClueHeight + (_dragStartRow! + 0.5) * _cellSize)).abs();
        final pixelColDiff = (position.dx - (_rowClueWidth + (_dragStartCol! + 0.5) * _cellSize)).abs();
        _dragIsHorizontal = pixelColDiff > pixelRowDiff;
      }
    }

    // Lock to row or column based on drag direction
    if (_dragIsHorizontal == true) {
      row = _dragStartRow!; // Lock to starting row
    } else if (_dragIsHorizontal == false) {
      col = _dragStartCol!; // Lock to starting column
    }

    final cellKey = '$row,$col';
    if (!_draggedCells.contains(cellKey)) {
      _draggedCells.add(cellKey);

      // Read the current state from the grid
      final currentState = widget.puzzle.userGrid[row][col];

      // On first cell, determine target state based on current cell and mode
      if (_dragTargetState == null) {
        if (widget.markMode) {
          // Mark mode: if empty (0), mark it (-1); if marked (-1), clear it (0)
          _dragTargetState = currentState == -1 ? 0 : -1;
        } else {
          // Fill mode: if empty (0), fill it (1); if filled (1), clear it (0)
          _dragTargetState = currentState == 1 ? 0 : 1;
        }
      }

      // Only tap if:
      // 1. We haven't already changed this cell in this drag
      // 2. The cell needs to change to match target state
      if (!_changedCells.contains(cellKey) && currentState != _dragTargetState) {
        _changedCells.add(cellKey);
        widget.onCellTap(row, col);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate the maximum clue width for rows and height for columns
    final maxRowClueLength =
        widget.puzzle.rowClues.map((c) => c.length).reduce((a, b) => a > b ? a : b);
    final maxColClueLength =
        widget.puzzle.colClues.map((c) => c.length).reduce((a, b) => a > b ? a : b);

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
                '${widget.puzzle.filledCount} / ${widget.puzzle.totalToFill} cells',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Toggle between Fill and Mark modes
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment<bool>(
                    value: false,
                    label: const Text('Fill'),
                    icon: const Icon(Icons.square_rounded, size: 18),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    label: const Text('X'),
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
                selected: {widget.markMode},
                onSelectionChanged: (Set<bool> selected) {
                  if (selected.first != widget.markMode) {
                    widget.onToggleMarkMode();
                  }
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
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
              final cellSize = (gridWidth / widget.puzzle.cols)
                  .clamp(0.0, gridHeight / widget.puzzle.rows);

              // Store for drag detection
              _cellSize = cellSize;
              _rowClueWidth = rowClueWidth;
              _colClueHeight = colClueHeight;

              return GestureDetector(
                // Use only pan gestures - a tap is just a pan that doesn't move
                onPanStart: _handleDragStart,
                onPanUpdate: _handleDragUpdate,
                child: _buildGridWithClues(
                  context,
                  cellSize,
                  rowClueWidth,
                  colClueHeight,
                  clueUnitSize,
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
            for (int c = 0; c < widget.puzzle.cols; c++)
              SizedBox(
                width: cellSize,
                height: colClueHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (final clue in widget.puzzle.colClues[c])
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
        for (int r = 0; r < widget.puzzle.rows; r++)
          Row(
            children: [
              // Row clues
              SizedBox(
                width: rowClueWidth,
                height: cellSize,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (final clue in widget.puzzle.rowClues[r])
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
              for (int c = 0; c < widget.puzzle.cols; c++)
                _buildCell(context, r, c, cellSize),
            ],
          ),
      ],
    );
  }

  Widget _buildCell(BuildContext context, int row, int col, double size) {
    final theme = Theme.of(context);
    final cellValue = widget.puzzle.userGrid[row][col];

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

    // No GestureDetector here - taps and drags handled by parent
    return Container(
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
    );
  }
}
