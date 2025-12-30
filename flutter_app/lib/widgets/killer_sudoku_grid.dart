import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/game_models.dart';

/// Muted colors for cage backgrounds - designed to be visually distinct when adjacent
const List<Color> _cageColors = [
  Color(0xFFFEF3C7), // amber-100
  Color(0xFFE0F2FE), // sky-100
  Color(0xFFFFE4E6), // rose-100
  Color(0xFFD1FAE5), // emerald-100
  Color(0xFFEDE9FE), // violet-100
  Color(0xFFFFEDD5), // orange-100
  Color(0xFFCCFBF1), // teal-100
  Color(0xFFFCE7F3), // pink-100
];

const List<Color> _cageColorsDark = [
  Color(0xFF78350F), // amber-900
  Color(0xFF0C4A6E), // sky-900
  Color(0xFF881337), // rose-900
  Color(0xFF064E3B), // emerald-900
  Color(0xFF4C1D95), // violet-900
  Color(0xFF7C2D12), // orange-900
  Color(0xFF134E4A), // teal-900
  Color(0xFF831843), // pink-900
];

/// Compute cage colors using graph coloring algorithm
/// Adjacent cages (sharing an edge) get different colors
List<int> _computeCageColors(List<KillerCage> cages) {
  if (cages.isEmpty) return [];

  // Build a map of cell -> cage index
  final cellToCage = <String, int>{};
  for (int i = 0; i < cages.length; i++) {
    for (final cell in cages[i].cells) {
      cellToCage['${cell[0]},${cell[1]}'] = i;
    }
  }

  // Build adjacency list - two cages are adjacent if they share an orthogonal edge
  final adjacency = List.generate(cages.length, (_) => <int>{});

  for (int cageIdx = 0; cageIdx < cages.length; cageIdx++) {
    for (final cell in cages[cageIdx].cells) {
      final row = cell[0];
      final col = cell[1];
      // Check all 4 orthogonal neighbors
      final neighbors = [
        [row - 1, col],
        [row + 1, col],
        [row, col - 1],
        [row, col + 1],
      ];

      for (final neighbor in neighbors) {
        final key = '${neighbor[0]},${neighbor[1]}';
        final neighborCageIdx = cellToCage[key];
        if (neighborCageIdx != null && neighborCageIdx != cageIdx) {
          adjacency[cageIdx].add(neighborCageIdx);
          adjacency[neighborCageIdx].add(cageIdx);
        }
      }
    }
  }

  // Greedy graph coloring
  final colors = List<int>.filled(cages.length, -1);

  for (int cageIdx = 0; cageIdx < cages.length; cageIdx++) {
    // Find colors used by adjacent cages
    final usedColors = <int>{};
    for (final neighborIdx in adjacency[cageIdx]) {
      if (colors[neighborIdx] != -1) {
        usedColors.add(colors[neighborIdx]);
      }
    }

    // Assign the first available color
    int color = 0;
    while (usedColors.contains(color)) {
      color++;
    }
    colors[cageIdx] = color % _cageColors.length;
  }

  return colors;
}

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
    // Compute cage colors using graph coloring
    final cageColorIndices = _computeCageColors(puzzle.cages);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
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
              cageColorIndices: cageColorIndices,
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
                return _buildCell(context, row, col, cageColorIndices, isDark);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCell(BuildContext context, int row, int col, List<int> cageColorIndices, bool isDark) {
    final theme = Theme.of(context);
    final value = puzzle.grid[row][col];
    final isInitial = puzzle.initialGrid[row][col] != null;
    final isSelected = row == selectedRow && col == selectedCol;
    final isHighlighted = _shouldHighlight(row, col);
    final isError = value != null && !puzzle.isValidPlacement(row, col, value);
    final cageInfo = puzzle.getCageForCell(row, col);
    final notes = puzzle.notes[row][col];

    // Get cage background color
    Color? cageColor;
    if (cageInfo != null && cageColorIndices.isNotEmpty) {
      final colorIdx = cageColorIndices[cageInfo[0]];
      cageColor = isDark
          ? _cageColorsDark[colorIdx].withValues(alpha: 0.4)
          : _cageColors[colorIdx];
    }

    Color? backgroundColor;
    if (isSelected) {
      backgroundColor = theme.colorScheme.primary.withValues(alpha: 0.4);
    } else if (isHighlighted) {
      // Blend highlight with cage color
      backgroundColor = cageColor != null
          ? Color.lerp(cageColor, theme.colorScheme.primary, 0.15)
          : theme.colorScheme.primary.withValues(alpha: 0.1);
    } else {
      backgroundColor = cageColor;
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
                top: 0,
                left: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.2),
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
                        fontWeight: isInitial ? FontWeight.w800 : FontWeight.w500,
                        color: isError
                            ? theme.colorScheme.error
                            : isInitial
                                ? theme.colorScheme.onSurface.withValues(alpha: 0.85)
                                : theme.colorScheme.primary,
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
    final textStyle = TextStyle(
      fontSize: 7,
      height: 1.0,
      fontWeight: FontWeight.w500,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
              SizedBox(width: 8, height: 8, child: Center(child: Text(notes.contains(1) ? '1' : '', style: textStyle))),
              SizedBox(width: 8, height: 8, child: Center(child: Text(notes.contains(2) ? '2' : '', style: textStyle))),
              SizedBox(width: 8, height: 8, child: Center(child: Text(notes.contains(3) ? '3' : '', style: textStyle))),
            ],
          ),
          // Row 2: 4, 5, 6
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 8, height: 8, child: Center(child: Text(notes.contains(4) ? '4' : '', style: textStyle))),
              SizedBox(width: 8, height: 8, child: Center(child: Text(notes.contains(5) ? '5' : '', style: textStyle))),
              SizedBox(width: 8, height: 8, child: Center(child: Text(notes.contains(6) ? '6' : '', style: textStyle))),
            ],
          ),
          // Row 3: 7, 8, 9
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 8, height: 8, child: Center(child: Text(notes.contains(7) ? '7' : '', style: textStyle))),
              SizedBox(width: 8, height: 8, child: Center(child: Text(notes.contains(8) ? '8' : '', style: textStyle))),
              SizedBox(width: 8, height: 8, child: Center(child: Text(notes.contains(9) ? '9' : '', style: textStyle))),
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
  final List<int> cageColorIndices;

  _KillerSudokuGridPainter({
    required this.puzzle,
    this.selectedRow,
    this.selectedCol,
    required this.theme,
    required this.cageColorIndices,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 9;
    final thinPaint = Paint()
      ..color = theme.colorScheme.onSurface.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;
    final thickPaint = Paint()
      ..color = theme.colorScheme.onSurface.withValues(alpha: 0.4)
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
    // Build a map of which cage each cell belongs to
    final cageMap = List.generate(9, (_) => List<int>.filled(9, -1));
    for (int i = 0; i < puzzle.cages.length; i++) {
      for (final cell in puzzle.cages[i].cells) {
        cageMap[cell[0]][cell[1]] = i;
      }
    }

    // Draw dotted borders between cells of different cages
    final dashPaint = Paint()
      ..color = theme.colorScheme.secondary.withValues(alpha: 0.5)
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
        oldDelegate.selectedCol != selectedCol ||
        oldDelegate.puzzle != puzzle;
  }
}
