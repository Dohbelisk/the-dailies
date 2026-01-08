import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_models.dart';

/// Sliding puzzle grid widget - classic 15-puzzle style game
class SlidingPuzzleGrid extends StatefulWidget {
  final SlidingPuzzle puzzle;
  final VoidCallback? onComplete;
  final VoidCallback? onMove;

  const SlidingPuzzleGrid({
    super.key,
    required this.puzzle,
    this.onComplete,
    this.onMove,
  });

  @override
  State<SlidingPuzzleGrid> createState() => _SlidingPuzzleGridState();
}

class _SlidingPuzzleGridState extends State<SlidingPuzzleGrid>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;

  int? _animatingTileIndex;
  int? _animatingToIndex;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    );
    _slideController.addStatusListener(_onAnimationStatus);
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _isAnimating = false;
        _animatingTileIndex = null;
        _animatingToIndex = null;
      });

      if (widget.puzzle.isComplete) {
        widget.onComplete?.call();
      }
    }
  }

  void _onTileTap(int index) {
    if (_isAnimating) return;
    if (!widget.puzzle.canMove(index)) {
      HapticFeedback.heavyImpact();
      return;
    }

    final emptyIndex = widget.puzzle.emptyIndex;

    setState(() {
      _isAnimating = true;
      _animatingTileIndex = index;
      _animatingToIndex = emptyIndex;
    });

    widget.puzzle.moveTile(index);
    _slideController.forward(from: 0);
    HapticFeedback.lightImpact();
    widget.onMove?.call();
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.puzzle.moveCount}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
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
                onPressed: widget.puzzle.moveHistory.isEmpty
                    ? null
                    : () {
                        setState(() {
                          widget.puzzle.undoMove();
                        });
                        HapticFeedback.selectionClick();
                      },
                icon: const Icon(Icons.undo, size: 22),
                tooltip: 'Undo',
              ),
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

        // Puzzle grid
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              padding: const EdgeInsets.all(8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final gridSize = constraints.maxWidth;
                  final tileSize = (gridSize - 8) / widget.puzzle.size;

                  return Stack(
                    children: _buildTiles(theme, tileSize),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildTiles(ThemeData theme, double tileSize) {
    final tiles = <Widget>[];
    final puzzle = widget.puzzle;

    for (int i = 0; i < puzzle.tiles.length; i++) {
      final tile = puzzle.tiles[i];
      if (tile == null) continue; // Skip empty space

      final row = puzzle.getRow(i);
      final col = puzzle.getCol(i);

      double left = col * tileSize + 4;
      double top = row * tileSize + 4;

      // Handle animation
      if (_isAnimating && _animatingTileIndex != null && _animatingToIndex != null) {
        // The tile that just moved - animate from its previous position
        final movedTileValue = puzzle.tiles[_animatingToIndex!];
        if (tile == movedTileValue && i == _animatingToIndex) {
          // This is the tile that was moved - animate from old position
          final fromRow = puzzle.getRow(_animatingTileIndex!);
          final fromCol = puzzle.getCol(_animatingTileIndex!);
          final toRow = puzzle.getRow(_animatingToIndex!);
          final toCol = puzzle.getCol(_animatingToIndex!);

          left = (fromCol + (toCol - fromCol) * _slideAnimation.value) * tileSize + 4;
          top = (fromRow + (toRow - fromRow) * _slideAnimation.value) * tileSize + 4;
        }
      }

      final canMove = puzzle.canMove(i);

      tiles.add(
        AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Positioned(
              left: left,
              top: top,
              child: _buildTile(theme, tile, tileSize - 8, canMove, i),
            );
          },
        ),
      );
    }

    return tiles;
  }

  Widget _buildTile(ThemeData theme, int number, double size, bool canMove, int index) {
    final isCorrectPosition = widget.puzzle.tiles[index] == widget.puzzle.solution[index];

    return GestureDetector(
      onTap: () => _onTileTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isCorrectPosition
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
          border: canMove
              ? Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  width: 2,
                )
              : null,
        ),
        child: Center(
          child: Text(
            '$number',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isCorrectPosition
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================
// STANDALONE TEST WIDGET FOR PROTOTYPING
// ============================================

class SlidingPuzzleTestScreen extends StatefulWidget {
  const SlidingPuzzleTestScreen({super.key});

  @override
  State<SlidingPuzzleTestScreen> createState() => _SlidingPuzzleTestScreenState();
}

class _SlidingPuzzleTestScreenState extends State<SlidingPuzzleTestScreen> {
  late SlidingPuzzle _puzzle;
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
          _puzzle = SlidingPuzzle.sampleLevel1();
          break;
        case 2:
          _puzzle = SlidingPuzzle.sampleLevel2();
          break;
        case 3:
          _puzzle = SlidingPuzzle.sampleLevel3();
          break;
        default:
          _puzzle = SlidingPuzzle.sampleLevel1();
      }
    });
  }

  void _onComplete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Puzzle Complete!'),
        content: Text('You solved level $_currentLevel in ${_puzzle.moveCount} moves!'),
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
        title: const Text('Sliding Puzzle Prototype'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.layers),
            tooltip: 'Select Level',
            onSelected: _loadLevel,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 1, child: Text('Level 1: 3x3 (Easy)')),
              const PopupMenuItem(value: 2, child: Text('Level 2: 4x4 (Medium)')),
              const PopupMenuItem(value: 3, child: Text('Level 3: 5x5 (Hard)')),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SlidingPuzzleGrid(
          key: ValueKey(_currentLevel),
          puzzle: _puzzle,
          onComplete: _onComplete,
          onMove: () => setState(() {}),
        ),
      ),
    );
  }
}
