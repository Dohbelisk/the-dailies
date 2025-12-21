import 'package:flutter/material.dart';
import '../models/game_models.dart';

class SudokuGrid extends StatelessWidget {
  final SudokuPuzzle puzzle;
  final int? selectedRow;
  final int? selectedCol;
  final Function(int row, int col) onCellTap;

  const SudokuGrid({
    super.key,
    required this.puzzle,
    this.selectedRow,
    this.selectedCol,
    required this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CustomPaint(
            painter: _SudokuGridPainter(
              puzzle: puzzle,
              selectedRow: selectedRow,
              selectedCol: selectedCol,
              theme: Theme.of(context),
            ),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 9,
              ),
              itemCount: 81,
              itemBuilder: (context, index) {
                final row = index ~/ 9;
                final col = index % 9;
                return _buildCell(context, row, col);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCell(BuildContext context, int row, int col) {
    final theme = Theme.of(context);
    final value = puzzle.grid[row][col];
    final isInitial = puzzle.initialGrid[row][col] != null;
    final isSelected = row == selectedRow && col == selectedCol;
    final isHighlighted = _shouldHighlight(row, col);
    final isError = value != null && !puzzle.isValidPlacement(row, col, value);
    final notes = puzzle.notes[row][col];

    Color? backgroundColor;
    if (isSelected) {
      backgroundColor = theme.colorScheme.primary.withOpacity(0.3);
    } else if (isHighlighted) {
      backgroundColor = theme.colorScheme.primary.withOpacity(0.1);
    }

    return GestureDetector(
      onTap: () => onCellTap(row, col),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
        ),
        child: Center(
          child: value != null
              ? Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: isInitial ? FontWeight.w800 : FontWeight.w500,
                    color: isError
                        ? theme.colorScheme.error
                        : isInitial
                            ? theme.colorScheme.onSurface.withOpacity(0.85)
                            : theme.colorScheme.primary,
                  ),
                )
              : notes.isNotEmpty
                  ? _buildNotes(context, notes)
                  : null,
        ),
      ),
    );
  }

  Widget _buildNotes(BuildContext context, Set<int> notes) {
    final theme = Theme.of(context);
    final textStyle = TextStyle(
      fontSize: 8,
      height: 1.0,
      fontWeight: FontWeight.w500,
      color: theme.colorScheme.onSurface.withOpacity(0.6),
    );

    // Build a compact 3x3 grid of notes, centered in the cell
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Row 1: 1, 2, 3
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 9, height: 9, child: Center(child: Text(notes.contains(1) ? '1' : '', style: textStyle))),
              SizedBox(width: 9, height: 9, child: Center(child: Text(notes.contains(2) ? '2' : '', style: textStyle))),
              SizedBox(width: 9, height: 9, child: Center(child: Text(notes.contains(3) ? '3' : '', style: textStyle))),
            ],
          ),
          // Row 2: 4, 5, 6
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 9, height: 9, child: Center(child: Text(notes.contains(4) ? '4' : '', style: textStyle))),
              SizedBox(width: 9, height: 9, child: Center(child: Text(notes.contains(5) ? '5' : '', style: textStyle))),
              SizedBox(width: 9, height: 9, child: Center(child: Text(notes.contains(6) ? '6' : '', style: textStyle))),
            ],
          ),
          // Row 3: 7, 8, 9
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 9, height: 9, child: Center(child: Text(notes.contains(7) ? '7' : '', style: textStyle))),
              SizedBox(width: 9, height: 9, child: Center(child: Text(notes.contains(8) ? '8' : '', style: textStyle))),
              SizedBox(width: 9, height: 9, child: Center(child: Text(notes.contains(9) ? '9' : '', style: textStyle))),
            ],
          ),
        ],
      ),
    );
  }

  bool _shouldHighlight(int row, int col) {
    if (selectedRow == null || selectedCol == null) return false;

    // Same row or column
    if (row == selectedRow || col == selectedCol) return true;

    // Same 3x3 box
    final boxRow = (selectedRow! ~/ 3) * 3;
    final boxCol = (selectedCol! ~/ 3) * 3;
    if (row >= boxRow &&
        row < boxRow + 3 &&
        col >= boxCol &&
        col < boxCol + 3) {
      return true;
    }

    // Same number
    final selectedValue = puzzle.grid[selectedRow!][selectedCol!];
    if (selectedValue != null && puzzle.grid[row][col] == selectedValue) {
      return true;
    }

    return false;
  }
}

class _SudokuGridPainter extends CustomPainter {
  final SudokuPuzzle puzzle;
  final int? selectedRow;
  final int? selectedCol;
  final ThemeData theme;

  _SudokuGridPainter({
    required this.puzzle,
    this.selectedRow,
    this.selectedCol,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 9;
    final thinPaint = Paint()
      ..color = theme.colorScheme.onSurface.withOpacity(0.2)
      ..strokeWidth = 1;
    final thickPaint = Paint()
      ..color = theme.colorScheme.onSurface.withOpacity(0.5)
      ..strokeWidth = 2.5;

    // Draw thin lines
    for (int i = 0; i <= 9; i++) {
      if (i % 3 != 0) {
        // Horizontal
        canvas.drawLine(
          Offset(0, i * cellSize),
          Offset(size.width, i * cellSize),
          thinPaint,
        );
        // Vertical
        canvas.drawLine(
          Offset(i * cellSize, 0),
          Offset(i * cellSize, size.height),
          thinPaint,
        );
      }
    }

    // Draw thick lines (box borders)
    for (int i = 0; i <= 9; i += 3) {
      // Horizontal
      canvas.drawLine(
        Offset(0, i * cellSize),
        Offset(size.width, i * cellSize),
        thickPaint,
      );
      // Vertical
      canvas.drawLine(
        Offset(i * cellSize, 0),
        Offset(i * cellSize, size.height),
        thickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SudokuGridPainter oldDelegate) {
    return oldDelegate.selectedRow != selectedRow ||
        oldDelegate.selectedCol != selectedCol;
  }
}
