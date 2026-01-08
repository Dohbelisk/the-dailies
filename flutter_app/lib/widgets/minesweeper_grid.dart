import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_models.dart';

/// Minesweeper grid widget
class MinesweeperGrid extends StatefulWidget {
  final MinesweeperPuzzle puzzle;
  final VoidCallback? onComplete;
  final VoidCallback? onGameOver;

  const MinesweeperGrid({
    super.key,
    required this.puzzle,
    this.onComplete,
    this.onGameOver,
  });

  @override
  State<MinesweeperGrid> createState() => _MinesweeperGridState();
}

class _MinesweeperGridState extends State<MinesweeperGrid> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final puzzle = widget.puzzle;

    return Column(
      children: [
        // Mine counter and status
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Remaining mines
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text('💣', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      '${puzzle.remainingMines}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              // Status indicator
              if (puzzle.isWon)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        'You Win!',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else if (puzzle.isGameOver)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.dangerous, color: Colors.red, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        'Game Over',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

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

                      return _buildCell(
                        context,
                        row,
                        col,
                        cellSize,
                        theme,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),

        // Instructions
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Tap to reveal. Long-press to flag.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
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
    final state = puzzle.cellStates[row][col];
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _onCellTap(row, col),
      onLongPress: () => _onCellLongPress(row, col),
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: _getCellColor(state, row, col, isDark, theme),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: state == MinesweeperCellState.hidden
              ? [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.5),
                    offset: const Offset(-1, -1),
                    blurRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.2),
                    offset: const Offset(1, 1),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: _buildCellContent(state, row, col, size, theme),
        ),
      ),
    );
  }

  Color _getCellColor(
    MinesweeperCellState state,
    int row,
    int col,
    bool isDark,
    ThemeData theme,
  ) {
    final puzzle = widget.puzzle;

    if (state == MinesweeperCellState.hidden) {
      return isDark
          ? const Color(0xFF4A5568)
          : const Color(0xFFBDBDBD);
    }

    if (state == MinesweeperCellState.flagged) {
      return isDark
          ? const Color(0xFF4A5568)
          : const Color(0xFFBDBDBD);
    }

    // Revealed
    if (puzzle.mines[row][col]) {
      return Colors.red.withValues(alpha: 0.3);
    }

    return isDark
        ? const Color(0xFF2D3748)
        : const Color(0xFFE0E0E0);
  }

  Widget? _buildCellContent(
    MinesweeperCellState state,
    int row,
    int col,
    double size,
    ThemeData theme,
  ) {
    final puzzle = widget.puzzle;
    final fontSize = size * 0.5;

    if (state == MinesweeperCellState.flagged) {
      return Icon(
        Icons.flag_rounded,
        size: fontSize,
        color: Colors.red,
      );
    }

    if (state == MinesweeperCellState.hidden) {
      return null;
    }

    // Revealed
    if (puzzle.mines[row][col]) {
      return Text(
        '💣',
        style: TextStyle(fontSize: fontSize * 0.8),
      );
    }

    final count = puzzle.adjacentCounts[row][col];
    if (count == 0) return null;

    return Text(
      '$count',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: _getNumberColor(count),
      ),
    );
  }

  Color _getNumberColor(int count) {
    switch (count) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.red;
      case 4:
        return Colors.purple;
      case 5:
        return Colors.brown;
      case 6:
        return Colors.cyan;
      case 7:
        return Colors.black;
      case 8:
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  void _onCellTap(int row, int col) {
    if (widget.puzzle.isGameOver || widget.puzzle.isWon) return;

    HapticFeedback.lightImpact();

    final continued = widget.puzzle.reveal(row, col);
    setState(() {});

    if (!continued) {
      HapticFeedback.heavyImpact();
      widget.onGameOver?.call();
    } else if (widget.puzzle.isWon) {
      HapticFeedback.mediumImpact();
      widget.onComplete?.call();
    }
  }

  void _onCellLongPress(int row, int col) {
    if (widget.puzzle.isGameOver || widget.puzzle.isWon) return;

    HapticFeedback.mediumImpact();
    widget.puzzle.toggleFlag(row, col);
    setState(() {});
  }
}

// =============================================================================
// TEST SCREEN
// =============================================================================

class MinesweeperTestScreen extends StatefulWidget {
  const MinesweeperTestScreen({super.key});

  @override
  State<MinesweeperTestScreen> createState() => _MinesweeperTestScreenState();
}

class _MinesweeperTestScreenState extends State<MinesweeperTestScreen> {
  late MinesweeperPuzzle _puzzle;
  int _currentLevel = 1;

  @override
  void initState() {
    super.initState();
    _puzzle = MinesweeperPuzzle.sampleLevel1();
  }

  void _selectLevel(int level) {
    setState(() {
      _currentLevel = level;
      switch (level) {
        case 1:
          _puzzle = MinesweeperPuzzle.sampleLevel1();
        case 2:
          _puzzle = MinesweeperPuzzle.sampleLevel2();
        case 3:
          _puzzle = MinesweeperPuzzle.sampleLevel3();
        default:
          _puzzle = MinesweeperPuzzle.sampleLevel1();
      }
    });
  }

  void _onComplete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Congratulations!'),
        content: const Text('You cleared all the mines!'),
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
                _selectLevel(_currentLevel + 1);
              },
              child: const Text('Next Level'),
            ),
        ],
      ),
    );
  }

  void _onGameOver() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Game Over'),
        content: const Text('You hit a mine!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _puzzle.reset());
            },
            child: const Text('Try Again'),
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
        title: const Text('Minesweeper'),
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
                    onSelected: (_) => _selectLevel(i),
                  ),
                ],
              ],
            ),
          ),

          // Grid info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${_puzzle.rows}x${_puzzle.cols} grid, ${_puzzle.mineCount} mines',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Game grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: MinesweeperGrid(
                key: ValueKey('$_currentLevel-${_puzzle.hashCode}'),
                puzzle: _puzzle,
                onComplete: _onComplete,
                onGameOver: _onGameOver,
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
