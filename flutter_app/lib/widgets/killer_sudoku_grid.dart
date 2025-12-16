import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/game_models.dart';

class KillerSudokuGrid extends StatelessWidget {
  final KillerSudokuPuzzle puzzle;
  final int? selectedRow;
  final int? selectedCol;
  final Function(int row, int col) onCellTap;

  const KillerSudokuGrid({
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
            painter: _KillerSudokuGridPainter(
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
    final isSelected = row == selectedRow && col == selectedCol;
    final isHighlighted = _shouldHighlight(row, col);
    final cageInfo = puzzle.getCageForCell(row, col);
    final notes = puzzle.notes[row][col];

    Color? backgroundColor;
    if (isSelected) {
      backgroundColor = theme.colorScheme.primary.withOpacity(0.3);
    } else if (isHighlighted) {
      backgroundColor = theme.colorScheme.primary.withOpacity(0.1);
    }

    // Check if this is the top-left cell of the cage (to show sum)
    bool showCageSum = false;
    int? cageSum;
    if (cageInfo != null) {
      final cage = puzzle.cages[cageInfo[0]];
      final topLeft = cage.topLeftCell;
      if (topLeft[0] == row && topLeft[1] == col) {
        showCageSum = true;
        cageSum = cage.sum;
      }
    }

    return GestureDetector(
      onTap: () => onCellTap(row, col),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
        ),
        child: Stack(
          children: [
            // Cage sum indicator
            if (showCageSum)
              Positioned(
                top: 2,
                left: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '$cageSum',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
              ),

            // Cell value or notes
            Center(
              child: value != null
                  ? Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : notes.isNotEmpty
                      ? _buildNotes(context, notes)
                      : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotes(BuildContext context, Set<int> notes) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GridView.count(
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(2),
        children: List.generate(9, (index) {
          final number = index + 1;
          return Center(
            child: Text(
              notes.contains(number) ? '$number' : '',
              style: TextStyle(
                fontSize: 9,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          );
        }),
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

    // Same cage
    final selectedCage = puzzle.getCageForCell(selectedRow!, selectedCol!);
    final currentCage = puzzle.getCageForCell(row, col);
    if (selectedCage != null &&
        currentCage != null &&
        selectedCage[0] == currentCage[0]) {
      return true;
    }

    return false;
  }
}

class _KillerSudokuGridPainter extends CustomPainter {
  final KillerSudokuPuzzle puzzle;
  final int? selectedRow;
  final int? selectedCol;
  final ThemeData theme;

  _KillerSudokuGridPainter({
    required this.puzzle,
    this.selectedRow,
    this.selectedCol,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 9;
    final thinPaint = Paint()
      ..color = theme.colorScheme.onSurface.withOpacity(0.15)
      ..strokeWidth = 0.5;
    final thickPaint = Paint()
      ..color = theme.colorScheme.onSurface.withOpacity(0.4)
      ..strokeWidth = 2;

    // Draw thin grid lines
    for (int i = 0; i <= 9; i++) {
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

    // Draw thick lines (box borders)
    for (int i = 0; i <= 9; i += 3) {
      canvas.drawLine(
        Offset(0, i * cellSize),
        Offset(size.width, i * cellSize),
        thickPaint,
      );
      canvas.drawLine(
        Offset(i * cellSize, 0),
        Offset(i * cellSize, size.height),
        thickPaint,
      );
    }

    // Draw cage borders
    _drawCageBorders(canvas, size, cellSize);
  }

  void _drawCageBorders(Canvas canvas, Size size, double cellSize) {
    final cagePaint = Paint()
      ..color = theme.colorScheme.secondary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Build a map of which cage each cell belongs to
    final cageMap = List.generate(9, (_) => List<int>.filled(9, -1));
    for (int i = 0; i < puzzle.cages.length; i++) {
      for (final cell in puzzle.cages[i].cells) {
        cageMap[cell[0]][cell[1]] = i;
      }
    }

    // Draw dotted borders between cells of different cages
    final dashPaint = Paint()
      ..color = theme.colorScheme.secondary.withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        final currentCage = cageMap[row][col];
        final x = col * cellSize;
        final y = row * cellSize;

        // Check right neighbor
        if (col < 8 && cageMap[row][col + 1] != currentCage) {
          _drawDashedLine(
            canvas,
            Offset(x + cellSize, y + 2),
            Offset(x + cellSize, y + cellSize - 2),
            dashPaint,
          );
        }

        // Check bottom neighbor
        if (row < 8 && cageMap[row + 1][col] != currentCage) {
          _drawDashedLine(
            canvas,
            Offset(x + 2, y + cellSize),
            Offset(x + cellSize - 2, y + cellSize),
            dashPaint,
          );
        }
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLength = 4.0;
    const gapLength = 3.0;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final unitDx = dx / distance;
    final unitDy = dy / distance;

    var currentX = start.dx;
    var currentY = start.dy;
    var drawn = 0.0;

    while (drawn < distance) {
      final remainingDistance = distance - drawn;
      final dashEnd = (dashLength < remainingDistance) ? dashLength : remainingDistance;

      canvas.drawLine(
        Offset(currentX, currentY),
        Offset(currentX + unitDx * dashEnd, currentY + unitDy * dashEnd),
        paint,
      );

      currentX += unitDx * (dashLength + gapLength);
      currentY += unitDy * (dashLength + gapLength);
      drawn += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant _KillerSudokuGridPainter oldDelegate) {
    return oldDelegate.selectedRow != selectedRow ||
        oldDelegate.selectedCol != selectedCol;
  }
}
