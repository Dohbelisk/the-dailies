import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_models.dart';

/// Kakuro grid widget - cross-sums puzzle
class KakuroGrid extends StatefulWidget {
  final KakuroPuzzle puzzle;
  final VoidCallback? onComplete;
  final VoidCallback? onMove;

  const KakuroGrid({
    super.key,
    required this.puzzle,
    this.onComplete,
    this.onMove,
  });

  @override
  State<KakuroGrid> createState() => _KakuroGridState();
}

class _KakuroGridState extends State<KakuroGrid> {
  int? selectedRow;
  int? selectedCol;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final puzzle = widget.puzzle;

    return Column(
      children: [
        // Grid
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: puzzle.cols / puzzle.rows,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cellSize = constraints.maxWidth / puzzle.cols;

                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: puzzle.cols,
                    ),
                    itemCount: puzzle.rows * puzzle.cols,
                    itemBuilder: (context, index) {
                      final row = index ~/ puzzle.cols;
                      final col = index % puzzle.cols;
                      return _buildCell(context, row, col, cellSize, theme);
                    },
                  );
                },
              ),
            ),
          ),
        ),

        // Number pad
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildNumberPad(theme),
        ),

        // Instructions
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'Fill numbers 1-9. Each run must sum to its clue with no repeats.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildCell(
    BuildContext context,
    int row,
    int col,
    double size,
    ThemeData theme,
  ) {
    final puzzle = widget.puzzle;
    final cellType = puzzle.cellTypes[row][col];
    final isDark = theme.brightness == Brightness.dark;

    switch (cellType) {
      case KakuroCellType.blocked:
        return Container(
          margin: const EdgeInsets.all(0.5),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A202C) : const Color(0xFF2D3748),
          ),
        );

      case KakuroCellType.clue:
        final clue = puzzle.clues[(row, col)];
        return Container(
          margin: const EdgeInsets.all(0.5),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A202C) : const Color(0xFF2D3748),
          ),
          child: CustomPaint(
            painter: _ClueCellPainter(
              acrossSum: clue?.acrossSum,
              downSum: clue?.downSum,
              size: size,
              isDark: isDark,
            ),
          ),
        );

      case KakuroCellType.entry:
        final value = puzzle.entries[row][col];
        final isSelected = selectedRow == row && selectedCol == col;
        final hasError = puzzle.hasError(row, col);

        return GestureDetector(
          onTap: () {
            setState(() {
              selectedRow = row;
              selectedCol = col;
            });
            HapticFeedback.selectionClick();
          },
          child: Container(
            margin: const EdgeInsets.all(0.5),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.3)
                  : hasError
                      ? Colors.red.withValues(alpha: 0.2)
                      : isDark
                          ? const Color(0xFF2D3748)
                          : Colors.white,
              border: isSelected
                  ? Border.all(color: theme.colorScheme.primary, width: 2)
                  : null,
            ),
            child: Center(
              child: value != 0
                  ? Text(
                      '$value',
                      style: TextStyle(
                        fontSize: size * 0.5,
                        fontWeight: FontWeight.bold,
                        color: hasError
                            ? Colors.red
                            : theme.colorScheme.onSurface,
                      ),
                    )
                  : null,
            ),
          ),
        );
    }
  }

  Widget _buildNumberPad(ThemeData theme) {
    return Column(
      children: [
        // Numbers 1-5
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) => _buildNumberButton(i + 1, theme)),
        ),
        const SizedBox(height: 8),
        // Numbers 6-9 and clear
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ...List.generate(4, (i) => _buildNumberButton(i + 6, theme)),
            const SizedBox(width: 4),
            _buildClearButton(theme),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberButton(int number, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        width: 48,
        height: 48,
        child: ElevatedButton(
          onPressed: selectedRow != null && selectedCol != null
              ? () => _enterNumber(number)
              : null,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClearButton(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        width: 48,
        height: 48,
        child: ElevatedButton(
          onPressed: selectedRow != null && selectedCol != null
              ? _clearEntry
              : null,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: theme.colorScheme.errorContainer,
            foregroundColor: theme.colorScheme.onErrorContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Icon(Icons.backspace_outlined, size: 20),
        ),
      ),
    );
  }

  void _enterNumber(int number) {
    if (selectedRow == null || selectedCol == null) return;

    HapticFeedback.lightImpact();
    widget.puzzle.setEntry(selectedRow!, selectedCol!, number);
    widget.onMove?.call();
    setState(() {});

    if (widget.puzzle.isComplete) {
      HapticFeedback.mediumImpact();
      widget.onComplete?.call();
    }
  }

  void _clearEntry() {
    if (selectedRow == null || selectedCol == null) return;

    HapticFeedback.lightImpact();
    widget.puzzle.clearEntry(selectedRow!, selectedCol!);
    widget.onMove?.call();
    setState(() {});
  }
}

class _ClueCellPainter extends CustomPainter {
  final int? acrossSum;
  final int? downSum;
  final double size;
  final bool isDark;

  _ClueCellPainter({
    this.acrossSum,
    this.downSum,
    required this.size,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = isDark ? Colors.white24 : Colors.white30
      ..strokeWidth = 1;

    // Draw diagonal line
    canvas.drawLine(
      Offset.zero,
      Offset(canvasSize.width, canvasSize.height),
      paint,
    );

    // Draw down sum (top-right triangle)
    if (downSum != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$downSum',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.25,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          canvasSize.width - textPainter.width - 4,
          4,
        ),
      );
    }

    // Draw across sum (bottom-left triangle)
    if (acrossSum != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$acrossSum',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.25,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          4,
          canvasSize.height - textPainter.height - 4,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ClueCellPainter oldDelegate) {
    return acrossSum != oldDelegate.acrossSum ||
        downSum != oldDelegate.downSum;
  }
}

// =============================================================================
// TEST SCREEN
// =============================================================================

class KakuroTestScreen extends StatefulWidget {
  const KakuroTestScreen({super.key});

  @override
  State<KakuroTestScreen> createState() => _KakuroTestScreenState();
}

class _KakuroTestScreenState extends State<KakuroTestScreen> {
  late KakuroPuzzle _puzzle;
  int _currentLevel = 1;

  @override
  void initState() {
    super.initState();
    _loadLevel(1);
  }

  void _loadLevel(int level) {
    setState(() {
      _currentLevel = level;
      switch (level) {
        case 1:
          _puzzle = KakuroPuzzle.sampleLevel1();
        case 2:
          _puzzle = KakuroPuzzle.sampleLevel2();
        case 3:
          _puzzle = KakuroPuzzle.sampleLevel3();
        default:
          _puzzle = KakuroPuzzle.sampleLevel1();
      }
    });
  }

  void _onComplete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Puzzle Complete!'),
        content: const Text('All sums are correct!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _puzzle.reset());
            },
            child: const Text('Play Again'),
          ),
          if (_currentLevel < 3)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _loadLevel(_currentLevel + 1);
              },
              child: const Text('Next Level'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kakuro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _puzzle.reset()),
            tooltip: 'Reset',
          ),
        ],
      ),
      body: Column(
        children: [
          // Level selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 1; i <= 3; i++) ...[
                  if (i > 1) const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(_getLevelName(i)),
                    selected: _currentLevel == i,
                    onSelected: (_) => _loadLevel(i),
                  ),
                ],
              ],
            ),
          ),

          // Grid info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${_puzzle.rows}x${_puzzle.cols} grid',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Game grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: KakuroGrid(
                key: ValueKey('kakuro-$_currentLevel'),
                puzzle: _puzzle,
                onComplete: _onComplete,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getLevelName(int level) {
    switch (level) {
      case 1:
        return 'Easy';
      case 2:
        return 'Medium';
      case 3:
        return 'Hard';
      default:
        return 'Level $level';
    }
  }
}
