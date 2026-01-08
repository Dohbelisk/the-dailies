import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_models.dart';

/// Memory Match grid widget with card flip animations
class MemoryMatchGrid extends StatefulWidget {
  final MemoryMatchPuzzle puzzle;
  final VoidCallback? onComplete;
  final VoidCallback? onMove;

  const MemoryMatchGrid({
    super.key,
    required this.puzzle,
    this.onComplete,
    this.onMove,
  });

  @override
  State<MemoryMatchGrid> createState() => _MemoryMatchGridState();
}

class _MemoryMatchGridState extends State<MemoryMatchGrid> {
  bool _processing = false;

  void _onCardTap(int row, int col) async {
    if (_processing) return;

    final result = widget.puzzle.flipCard(row, col);

    if (result == 'invalid') {
      return;
    }

    setState(() {});
    HapticFeedback.lightImpact();
    widget.onMove?.call();

    if (result == 'match') {
      HapticFeedback.mediumImpact();
      if (widget.puzzle.isComplete) {
        widget.onComplete?.call();
      }
    } else if (result == 'nomatch') {
      _processing = true;
      // Wait for player to see the cards
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) {
        setState(() {
          widget.puzzle.hideUnmatchedPair();
          _processing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Info bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Pairs found
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.puzzle.pairsFound}/${widget.puzzle.totalPairs}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'pairs',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              // Moves counter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.puzzle.moveCount}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'moves',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: widget.puzzle.moveCount == 0
                    ? null
                    : () {
                        setState(() {
                          widget.puzzle.reset();
                        });
                        HapticFeedback.selectionClick();
                      },
                icon: const Icon(Icons.refresh, size: 22),
                tooltip: 'Reset',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Card grid
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final gridWidth = constraints.maxWidth;
              final gridHeight = constraints.maxHeight;

              // Calculate card size to fit the grid
              final cardWidth = (gridWidth - (widget.puzzle.cols - 1) * 8) / widget.puzzle.cols;
              final cardHeight = (gridHeight - (widget.puzzle.rows - 1) * 8) / widget.puzzle.rows;
              final cardSize = math.min(cardWidth, cardHeight);

              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(widget.puzzle.rows, (row) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: row < widget.puzzle.rows - 1 ? 8 : 0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(widget.puzzle.cols, (col) {
                          return Padding(
                            padding: EdgeInsets.only(right: col < widget.puzzle.cols - 1 ? 8 : 0),
                            child: _MemoryCard(
                              symbol: widget.puzzle.board[row][col],
                              isRevealed: widget.puzzle.revealed[row][col],
                              isMatched: widget.puzzle.matched[row][col],
                              size: cardSize,
                              onTap: () => _onCardTap(row, col),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Individual memory card with flip animation
class _MemoryCard extends StatefulWidget {
  final String symbol;
  final bool isRevealed;
  final bool isMatched;
  final double size;
  final VoidCallback onTap;

  const _MemoryCard({
    required this.symbol,
    required this.isRevealed,
    required this.isMatched,
    required this.size,
    required this.onTap,
  });

  @override
  State<_MemoryCard> createState() => _MemoryCardState();
}

class _MemoryCardState extends State<_MemoryCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showFront = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.addListener(() {
      if (_animation.value >= 0.5 && !_showFront) {
        setState(() => _showFront = true);
      } else if (_animation.value < 0.5 && _showFront) {
        setState(() => _showFront = false);
      }
    });

    if (widget.isRevealed || widget.isMatched) {
      _controller.value = 1;
      _showFront = true;
    }
  }

  @override
  void didUpdateWidget(_MemoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isRevealed != oldWidget.isRevealed || widget.isMatched != oldWidget.isMatched) {
      if (widget.isRevealed || widget.isMatched) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * math.pi;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);

          return Transform(
            alignment: Alignment.center,
            transform: transform,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: _showFront
                    ? (widget.isMatched
                        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                        : theme.colorScheme.surface)
                    : theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isMatched
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.3),
                  width: widget.isMatched ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: Center(
                child: _showFront
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(math.pi),
                        child: Text(
                          widget.symbol,
                          style: TextStyle(
                            fontSize: widget.size * 0.5,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.question_mark,
                        size: widget.size * 0.4,
                        color: theme.colorScheme.onPrimary,
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================
// STANDALONE TEST WIDGET FOR PROTOTYPING
// ============================================

class MemoryMatchTestScreen extends StatefulWidget {
  const MemoryMatchTestScreen({super.key});

  @override
  State<MemoryMatchTestScreen> createState() => _MemoryMatchTestScreenState();
}

class _MemoryMatchTestScreenState extends State<MemoryMatchTestScreen> {
  late MemoryMatchPuzzle _puzzle;
  int _currentLevel = 1;

  @override
  void initState() {
    super.initState();
    _loadLevel(_currentLevel);
  }

  void _loadLevel(int level) {
    setState(() {
      _currentLevel = level;
      switch (level) {
        case 1:
          _puzzle = MemoryMatchPuzzle.sampleLevel1();
          break;
        case 2:
          _puzzle = MemoryMatchPuzzle.sampleLevel2();
          break;
        case 3:
          _puzzle = MemoryMatchPuzzle.sampleLevel3();
          break;
        default:
          _puzzle = MemoryMatchPuzzle.sampleLevel1();
      }
    });
  }

  void _onComplete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Puzzle Complete!'),
        content: Text(
          'You found all pairs in ${_puzzle.moveCount} moves!\n'
          'Total flips: ${_puzzle.flipCount}',
        ),
        actions: [
          if (_currentLevel < 3)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _loadLevel(_currentLevel + 1);
              },
              child: const Text('Next Level'),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadLevel(_currentLevel);
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Match Prototype'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.layers),
            tooltip: 'Select Level',
            onSelected: _loadLevel,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 1, child: Text('Level 1: 3x4 (Easy)')),
              const PopupMenuItem(value: 2, child: Text('Level 2: 4x4 (Medium)')),
              const PopupMenuItem(value: 3, child: Text('Level 3: 4x5 (Hard)')),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: MemoryMatchGrid(
          key: ValueKey(_currentLevel),
          puzzle: _puzzle,
          onComplete: _onComplete,
          onMove: () => setState(() {}),
        ),
      ),
    );
  }
}
