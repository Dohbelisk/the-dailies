import 'package:flutter/material.dart';
import '../models/game_models.dart';

class WordSearchGrid extends StatefulWidget {
  final WordSearchPuzzle puzzle;
  final List<List<int>>? currentSelection;
  final Function(int row, int col) onSelectionStart;
  final Function(int row, int col) onSelectionUpdate;
  final bool Function() onSelectionEnd;

  const WordSearchGrid({
    super.key,
    required this.puzzle,
    this.currentSelection,
    required this.onSelectionStart,
    required this.onSelectionUpdate,
    required this.onSelectionEnd,
  });

  @override
  State<WordSearchGrid> createState() => _WordSearchGridState();
}

class _WordSearchGridState extends State<WordSearchGrid> {
  double? _cellSize;
  Offset? _gridOffset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final gridSize = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        _cellSize = gridSize / widget.puzzle.cols;

        return GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: (_) => widget.onSelectionEnd(),
          child: Container(
            width: gridSize,
            height: gridSize * (widget.puzzle.rows / widget.puzzle.cols),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
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
                painter: _WordSearchPainter(
                  puzzle: widget.puzzle,
                  currentSelection: widget.currentSelection,
                  cellSize: _cellSize!,
                  theme: theme,
                ),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: widget.puzzle.cols,
                  ),
                  itemCount: widget.puzzle.rows * widget.puzzle.cols,
                  itemBuilder: (context, index) {
                    final row = index ~/ widget.puzzle.cols;
                    final col = index % widget.puzzle.cols;
                    return _buildCell(context, row, col);
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onPanStart(DragStartDetails details) {
    final box = context.findRenderObject() as RenderBox;
    _gridOffset = box.localToGlobal(Offset.zero);
    final localPos = details.globalPosition - _gridOffset!;
    final row = (localPos.dy / _cellSize!).floor();
    final col = (localPos.dx / _cellSize!).floor();
    
    if (_isValidCell(row, col)) {
      widget.onSelectionStart(row, col);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_gridOffset == null || _cellSize == null) return;
    
    final localPos = details.globalPosition - _gridOffset!;
    final row = (localPos.dy / _cellSize!).floor();
    final col = (localPos.dx / _cellSize!).floor();
    
    if (_isValidCell(row, col)) {
      widget.onSelectionUpdate(row, col);
    }
  }

  bool _isValidCell(int row, int col) {
    return row >= 0 &&
        row < widget.puzzle.rows &&
        col >= 0 &&
        col < widget.puzzle.cols;
  }

  Widget _buildCell(BuildContext context, int row, int col) {
    final theme = Theme.of(context);
    final letter = widget.puzzle.grid[row][col];
    final isInFoundWord = _isInFoundWord(row, col);
    final isInSelection = _isInCurrentSelection(row, col);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isInFoundWord
                ? theme.colorScheme.primary
                : isInSelection
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  bool _isInFoundWord(int row, int col) {
    for (final word in widget.puzzle.words) {
      if (word.found) {
        for (final pos in word.cellPositions) {
          if (pos[0] == row && pos[1] == col) return true;
        }
      }
    }
    return false;
  }

  bool _isInCurrentSelection(int row, int col) {
    if (widget.currentSelection == null) return false;
    for (final pos in widget.currentSelection!) {
      if (pos[0] == row && pos[1] == col) return true;
    }
    return false;
  }
}

class _WordSearchPainter extends CustomPainter {
  final WordSearchPuzzle puzzle;
  final List<List<int>>? currentSelection;
  final double cellSize;
  final ThemeData theme;

  _WordSearchPainter({
    required this.puzzle,
    this.currentSelection,
    required this.cellSize,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw found words with highlight
    for (final word in puzzle.words) {
      if (word.found) {
        _drawWordHighlight(
          canvas,
          word.cellPositions,
          theme.colorScheme.primary.withValues(alpha: 0.3),
        );
      }
    }

    // Draw current selection
    if (currentSelection != null && currentSelection!.isNotEmpty) {
      _drawWordHighlight(
        canvas,
        currentSelection!,
        theme.colorScheme.secondary.withValues(alpha: 0.4),
      );
    }
  }

  void _drawWordHighlight(
    Canvas canvas,
    List<List<int>> positions,
    Color color,
  ) {
    if (positions.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = cellSize * 0.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final first = positions.first;
    final last = positions.last;

    final startX = first[1] * cellSize + cellSize / 2;
    final startY = first[0] * cellSize + cellSize / 2;
    final endX = last[1] * cellSize + cellSize / 2;
    final endY = last[0] * cellSize + cellSize / 2;

    path.moveTo(startX, startY);
    path.lineTo(endX, endY);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WordSearchPainter oldDelegate) {
    return oldDelegate.currentSelection != currentSelection ||
        oldDelegate.puzzle.foundCount != puzzle.foundCount;
  }
}
