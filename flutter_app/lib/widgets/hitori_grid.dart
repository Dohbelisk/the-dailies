import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_models.dart';

/// Hitori grid widget - shade cells puzzle
class HitoriGrid extends StatefulWidget {
  final HitoriPuzzle puzzle;
  final VoidCallback? onComplete;
  final VoidCallback? onMove;

  const HitoriGrid({
    super.key,
    required this.puzzle,
    this.onComplete,
    this.onMove,
  });

  @override
  State<HitoriGrid> createState() => _HitoriGridState();
}

class _HitoriGridState extends State<HitoriGrid> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final puzzle = widget.puzzle;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Grid
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cellSize = constraints.maxWidth / puzzle.size;

                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: puzzle.size,
                    ),
                    itemCount: puzzle.size * puzzle.size,
                    itemBuilder: (context, index) {
                      final row = index ~/ puzzle.size;
                      final col = index % puzzle.size;
                      return _buildCell(context, row, col, cellSize, theme, isDark);
                    },
                  );
                },
              ),
            ),
          ),
        ),

        // Status indicators
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatusIndicator(
                'Duplicates',
                !puzzle.hasDuplicates(),
                theme,
              ),
              _buildStatusIndicator(
                'No Adjacent',
                !puzzle.hasAdjacentShaded(),
                theme,
              ),
              _buildStatusIndicator(
                'Connected',
                puzzle.areUnshadedConnected(),
                theme,
              ),
            ],
          ),
        ),

        // Instructions
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'Tap to shade cells. No duplicates in rows/columns. Shaded cells can\'t touch.',
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
    bool isDark,
  ) {
    final puzzle = widget.puzzle;
    final isShaded = puzzle.isShaded(row, col);
    final hasAdjacentError = puzzle.hasCellAdjacentShaded(row, col);
    final hasDuplicate = !isShaded && puzzle.cellCausesDuplicate(row, col);

    Color cellColor;
    Color textColor;

    if (isShaded) {
      if (hasAdjacentError) {
        cellColor = Colors.red.shade700;
        textColor = Colors.white.withValues(alpha: 0.5);
      } else {
        cellColor = isDark ? Colors.grey.shade800 : Colors.grey.shade900;
        textColor = Colors.white.withValues(alpha: 0.3);
      }
    } else {
      if (hasDuplicate) {
        cellColor = Colors.red.withValues(alpha: 0.2);
        textColor = Colors.red;
      } else {
        cellColor = isDark ? const Color(0xFF2D3748) : Colors.white;
        textColor = theme.colorScheme.onSurface;
      }
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          puzzle.toggleShade(row, col);
        });
        widget.onMove?.call();

        if (puzzle.isComplete) {
          HapticFeedback.mediumImpact();
          widget.onComplete?.call();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: cellColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            '${puzzle.numbers[row][col]}',
            style: TextStyle(
              fontSize: size * 0.45,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String label, bool isGood, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isGood ? Icons.check_circle : Icons.cancel,
          color: isGood ? Colors.green : Colors.red,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isGood ? Colors.green : Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// TEST SCREEN
// =============================================================================

class HitoriTestScreen extends StatefulWidget {
  const HitoriTestScreen({super.key});

  @override
  State<HitoriTestScreen> createState() => _HitoriTestScreenState();
}

class _HitoriTestScreenState extends State<HitoriTestScreen> {
  late HitoriPuzzle _puzzle;
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
          _puzzle = HitoriPuzzle.sampleLevel1();
        case 2:
          _puzzle = HitoriPuzzle.sampleLevel2();
        case 3:
          _puzzle = HitoriPuzzle.sampleLevel3();
        default:
          _puzzle = HitoriPuzzle.sampleLevel1();
      }
    });
  }

  void _onComplete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Puzzle Complete!'),
        content: const Text('All rules satisfied!'),
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
        title: const Text('Hitori'),
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
              '${_puzzle.size}x${_puzzle.size} grid',
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
              child: HitoriGrid(
                key: ValueKey('hitori-$_currentLevel'),
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
