import 'package:flutter/material.dart';
import '../models/game_models.dart';

class NonogramGrid extends StatefulWidget {
  final NonogramPuzzle puzzle;
  final bool markMode;
  final Function(int row, int col) onCellTap;
  final Function(int row, int col, int state) onSetCellState;
  final VoidCallback onToggleMarkMode;
  final VoidCallback onSaveStateForUndo;
  final VoidCallback onUndo;
  final VoidCallback onDragEnd;
  final bool canUndo;

  const NonogramGrid({
    super.key,
    required this.puzzle,
    required this.markMode,
    required this.onCellTap,
    required this.onSetCellState,
    required this.onToggleMarkMode,
    required this.onSaveStateForUndo,
    required this.onUndo,
    required this.onDragEnd,
    required this.canUndo,
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

  // Track the drag action for the current drag
  // null = no drag started
  // In Fill mode: 'fill' or 'clear'
  // In Mark mode: 'mark' or 'unmark'
  String? _dragAction;

  // Track drag direction: null = not set, true = horizontal, false = vertical
  bool? _dragIsHorizontal;
  int? _dragStartRow;
  int? _dragStartCol;

  void _handleDragStart(DragStartDetails details) {
    _draggedCells.clear();
    _changedCells.clear();
    _dragAction = null;
    _dragIsHorizontal = null;
    _dragStartRow = null;
    _dragStartCol = null;
    // Save state for undo before making any changes
    widget.onSaveStateForUndo();
    _handleDragAt(details.localPosition, isStart: true);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _handleDragAt(details.localPosition, isStart: false);
  }

  void _handleDragEnd(DragEndDetails details) {
    // Notify that drag ended so listeners can update
    widget.onDragEnd();
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
    if (_draggedCells.contains(cellKey)) return;
    _draggedCells.add(cellKey);

    // Get current state: null or 0 = empty, 1 = filled, -1 = marked
    final rawState = widget.puzzle.userGrid[row][col];
    final currentState = rawState ?? 0; // Treat null as empty (0)
    final isEmpty = rawState == null || rawState == 0;

    // Check if this is the first cell (origin) of the drag
    final isFirstCell = _dragAction == null;

    // On first cell, determine the action based on origin cell state and mode
    if (isFirstCell) {
      if (widget.markMode) {
        // Mark mode:
        // - Origin is Marked (-1) -> action is 'unmark'
        // - Origin is Empty or Filled -> action is 'mark'
        _dragAction = (currentState == -1) ? 'unmark' : 'mark';
      } else {
        // Fill mode:
        // - Origin is Filled (1) -> action is 'clear'
        // - Origin is Empty or Marked -> action is 'fill'
        _dragAction = (currentState == 1) ? 'clear' : 'fill';
      }
    }

    // Safety check: ensure we're not in a mark action when in fill mode
    if (!widget.markMode && (_dragAction == 'mark' || _dragAction == 'unmark')) {
      return;
    }
    if (widget.markMode && (_dragAction == 'fill' || _dragAction == 'clear')) {
      return;
    }

    // Determine what to do with this cell based on action and current state
    // States: null/0 = empty, 1 = filled, -1 = marked
    int? newState;

    if (isFirstCell) {
      // FIRST CELL (tap or drag start): Always toggle based on mode
      if (widget.markMode) {
        // Mark mode: toggle between empty and marked
        if (currentState == -1) {
          newState = 0; // marked -> empty
        } else {
          newState = -1; // empty or filled -> marked
        }
      } else {
        // Fill mode: toggle between empty and filled
        if (currentState == 1) {
          newState = 0; // filled -> empty
        } else {
          newState = 1; // empty or marked -> filled
        }
      }
    } else {
      // SUBSEQUENT CELLS: Follow drag action, respect other cell types
      switch (_dragAction) {
        case 'fill':
          // Fill action: ONLY empty cells become filled
          if (isEmpty) {
            newState = 1;
          }
          break;

        case 'clear':
          // Clear action: ONLY filled cells become empty
          if (currentState == 1) {
            newState = 0;
          }
          break;

        case 'mark':
          // Mark action: ONLY empty cells become marked
          if (isEmpty) {
            newState = -1;
          }
          break;

        case 'unmark':
          // Unmark action: ONLY marked cells become empty
          if (currentState == -1) {
            newState = 0;
          }
          break;
      }
    }

    // Apply the change if needed
    if (newState != null && !_changedCells.contains(cellKey)) {
      _changedCells.add(cellKey);
      widget.onSetCellState(row, col, newState);
    }
  }

  Widget _buildModeToggle(BuildContext context) {
    final theme = Theme.of(context);
    final fillSelected = !widget.markMode;
    final markSelected = widget.markMode;

    // Muted red for mark mode
    final markColor = theme.colorScheme.error.withValues(alpha: 0.7);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fill button
          GestureDetector(
            onTap: widget.markMode ? widget.onToggleMarkMode : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: fillSelected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.square_rounded,
                    size: 16,
                    color: fillSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Fill',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: fillSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Mark button
          GestureDetector(
            onTap: !widget.markMode ? widget.onToggleMarkMode : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: markSelected ? markColor : Colors.transparent,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.close,
                    size: 16,
                    color: markSelected
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Mark',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: markSelected
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
              Row(
                children: [
                  // Undo button
                  IconButton.outlined(
                    onPressed: widget.canUndo ? widget.onUndo : null,
                    icon: const Icon(Icons.undo, size: 20),
                    tooltip: 'Undo',
                  ),
                  const SizedBox(width: 8),
                  // Toggle between Fill and Mark modes
                  _buildModeToggle(context),
                ],
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
                onPanEnd: _handleDragEnd,
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

  /// Calculate the interval for bold lines based on grid size.
  /// Prefers 5 if the size is divisible by 5, otherwise finds a good factor.
  int _getBoldLineInterval(int size) {
    // Prefer 5 for standard nonogram sizes (5, 10, 15, 20)
    if (size % 5 == 0) return 5;
    // For sizes like 12, use 4; for 9, use 3
    if (size % 4 == 0) return 4;
    if (size % 3 == 0) return 3;
    // For prime sizes, just use the size itself (only edges are bold)
    return size;
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
        size: size * 0.75,
        color: theme.colorScheme.error,
        weight: 700,
      );
    } else {
      // Unmarked
      bgColor = theme.colorScheme.surface;
    }

    // Thicker borders at regular intervals for easier counting
    // Interval is based on grid size: prefer 5, otherwise use the largest factor that divides evenly
    final thinBorder = theme.colorScheme.outline.withValues(alpha: 0.3);
    final thickBorder = theme.colorScheme.outline.withValues(alpha: 0.8);
    const thinWidth = 0.5;
    const thickWidth = 1.5;

    final rowInterval = _getBoldLineInterval(widget.puzzle.rows);
    final colInterval = _getBoldLineInterval(widget.puzzle.cols);

    final isLeftThick = col % colInterval == 0;
    final isTopThick = row % rowInterval == 0;
    final isRightThick = col == widget.puzzle.cols - 1;
    final isBottomThick = row == widget.puzzle.rows - 1;

    // No GestureDetector here - taps and drags handled by parent
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          left: BorderSide(
            color: isLeftThick ? thickBorder : thinBorder,
            width: isLeftThick ? thickWidth : thinWidth,
          ),
          top: BorderSide(
            color: isTopThick ? thickBorder : thinBorder,
            width: isTopThick ? thickWidth : thinWidth,
          ),
          right: BorderSide(
            color: isRightThick ? thickBorder : thinBorder,
            width: isRightThick ? thickWidth : thinWidth,
          ),
          bottom: BorderSide(
            color: isBottomThick ? thickBorder : thinBorder,
            width: isBottomThick ? thickWidth : thinWidth,
          ),
        ),
      ),
      child: child,
    );
  }
}
