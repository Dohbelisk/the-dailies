import 'package:flutter/material.dart';
import '../models/game_models.dart';

class CrosswordGrid extends StatelessWidget {
  final CrosswordPuzzle puzzle;
  final int? selectedRow;
  final int? selectedCol;
  final CrosswordClue? selectedClue;
  final Function(int row, int col) onCellTap;

  const CrosswordGrid({
    super.key,
    required this.puzzle,
    this.selectedRow,
    this.selectedCol,
    this.selectedClue,
    required this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AspectRatio(
      aspectRatio: puzzle.cols / puzzle.rows,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
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
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: puzzle.cols,
            ),
            itemCount: puzzle.rows * puzzle.cols,
            itemBuilder: (context, index) {
              final row = index ~/ puzzle.cols;
              final col = index % puzzle.cols;
              return _buildCell(context, row, col);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCell(BuildContext context, int row, int col) {
    final theme = Theme.of(context);
    final isBlack = puzzle.grid[row][col] == null;
    final cellNumber = puzzle.cellNumbers[row][col];
    final userValue = puzzle.userGrid[row][col];
    final correctValue = puzzle.grid[row][col];
    final isSelected = row == selectedRow && col == selectedCol;
    final isHighlighted = _isInSelectedClue(row, col);

    if (isBlack) {
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withOpacity(0.9),
          border: Border.all(
            color: theme.colorScheme.onSurface.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      );
    }

    // Determine background color and border
    Color backgroundColor = theme.colorScheme.surface;
    Border? cellBorder;

    if (isSelected) {
      // Current cursor cell - intense highlight with thicker border
      backgroundColor = theme.colorScheme.primary.withOpacity(0.5);
      cellBorder = Border.all(
        color: theme.colorScheme.primary,
        width: 2.5,
      );
    } else if (isHighlighted) {
      // Part of selected word - lighter highlight
      backgroundColor = theme.colorScheme.primary.withOpacity(0.15);
      cellBorder = Border.all(
        color: theme.colorScheme.primary.withOpacity(0.4),
        width: 1,
      );
    } else {
      cellBorder = Border.all(
        color: theme.colorScheme.onSurface.withOpacity(0.3),
        width: 0.5,
      );
    }

    final isCorrect = userValue?.toUpperCase() == correctValue?.toUpperCase();
    final hasValue = userValue != null && userValue.isNotEmpty;

    return GestureDetector(
      onTap: () => onCellTap(row, col),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: cellBorder,
        ),
        child: Stack(
          children: [
            // Cell number
            if (cellNumber != null)
              Positioned(
                top: 2,
                left: 3,
                child: Text(
                  '$cellNumber',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? theme.colorScheme.onPrimary.withOpacity(0.8)
                        : theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),

            // Letter
            Center(
              child: Text(
                hasValue ? userValue!.toUpperCase() : '',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: hasValue && !isCorrect && _showErrors
                      ? theme.colorScheme.error
                      : isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _showErrors => false; // Can be made configurable

  bool _isInSelectedClue(int row, int col) {
    if (selectedClue == null) return false;

    if (selectedClue!.direction == 'across') {
      if (row != selectedClue!.startRow) return false;
      return col >= selectedClue!.startCol &&
          col < selectedClue!.startCol + selectedClue!.length;
    } else {
      if (col != selectedClue!.startCol) return false;
      return row >= selectedClue!.startRow &&
          row < selectedClue!.startRow + selectedClue!.length;
    }
  }
}
