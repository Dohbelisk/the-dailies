import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_models.dart';

/// 2048 game grid widget with swipe controls
class Game2048Grid extends StatefulWidget {
  final Game2048Puzzle puzzle;
  final VoidCallback? onComplete;
  final VoidCallback? onMove;
  final VoidCallback? onGameOver;

  const Game2048Grid({
    super.key,
    required this.puzzle,
    this.onComplete,
    this.onMove,
    this.onGameOver,
  });

  @override
  State<Game2048Grid> createState() => _Game2048GridState();
}

class _Game2048GridState extends State<Game2048Grid> {
  Offset? _dragStart;
  static const double _minSwipeDistance = 50;

  void _onPanStart(DragStartDetails details) {
    _dragStart = details.globalPosition;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_dragStart == null) return;
    if (widget.puzzle.isGameOver) return;

    final delta = details.globalPosition - _dragStart!;
    if (delta.distance < _minSwipeDistance) return;

    SwipeDirection? direction;

    if (delta.dx.abs() > delta.dy.abs()) {
      direction = delta.dx > 0 ? SwipeDirection.right : SwipeDirection.left;
    } else {
      direction = delta.dy > 0 ? SwipeDirection.down : SwipeDirection.up;
    }

    _dragStart = null;

    final moved = widget.puzzle.move(direction);
    if (moved) {
      setState(() {});
      HapticFeedback.lightImpact();
      widget.onMove?.call();

      if (widget.puzzle.hasWon) {
        widget.onComplete?.call();
      } else if (widget.puzzle.isGameOver) {
        widget.onGameOver?.call();
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _dragStart = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Score bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildScoreBox(theme, 'Score', widget.puzzle.score),
              const SizedBox(width: 12),
              _buildScoreBox(theme, 'Best', widget.puzzle.bestTile),
              const Spacer(),
              IconButton(
                onPressed: () {
                  setState(() {
                    widget.puzzle.reset();
                  });
                  HapticFeedback.selectionClick();
                },
                icon: const Icon(Icons.refresh, size: 22),
                tooltip: 'New Game',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Game grid
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFBBADA0),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final gridSize = constraints.maxWidth;
                    final cellSize = (gridSize - 8 * 3) / 4; // 4 gaps of 8px

                    return Stack(
                      children: [
                        // Empty cell backgrounds
                        ..._buildEmptyCells(cellSize),
                        // Tiles
                        ..._buildTiles(cellSize),
                        // Game over overlay
                        if (widget.puzzle.isGameOver && !widget.puzzle.hasWon)
                          _buildGameOverOverlay(theme),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Instructions
        Text(
          'Swipe to move tiles. Merge matching numbers!',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreBox(ThemeData theme, String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFBBADA0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: const Color(0xFFEEE4DA),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '$value',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildEmptyCells(double cellSize) {
    final cells = <Widget>[];
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        cells.add(
          Positioned(
            left: c * (cellSize + 8),
            top: r * (cellSize + 8),
            child: Container(
              width: cellSize,
              height: cellSize,
              decoration: BoxDecoration(
                color: const Color(0xFFCDC1B4),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
      }
    }
    return cells;
  }

  List<Widget> _buildTiles(double cellSize) {
    final tiles = <Widget>[];
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        final value = widget.puzzle.board[r][c];
        if (value == 0) continue;

        tiles.add(
          AnimatedPositioned(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            left: c * (cellSize + 8),
            top: r * (cellSize + 8),
            child: _Tile2048(
              value: value,
              size: cellSize,
            ),
          ),
        );
      }
    }
    return tiles;
  }

  Widget _buildGameOverOverlay(ThemeData theme) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Game Over!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: const Color(0xFF776E65),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Final Score: ${widget.puzzle.score}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF776E65),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    widget.puzzle.reset();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8F7A66),
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual 2048 tile
class _Tile2048 extends StatelessWidget {
  final int value;
  final double size;

  const _Tile2048({
    required this.value,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor, fontSize) = _getTileStyle();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$value',
          style: TextStyle(
            fontSize: size * fontSize,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }

  (Color, Color, double) _getTileStyle() {
    switch (value) {
      case 2:
        return (const Color(0xFFEEE4DA), const Color(0xFF776E65), 0.4);
      case 4:
        return (const Color(0xFFEDE0C8), const Color(0xFF776E65), 0.4);
      case 8:
        return (const Color(0xFFF2B179), Colors.white, 0.4);
      case 16:
        return (const Color(0xFFF59563), Colors.white, 0.4);
      case 32:
        return (const Color(0xFFF67C5F), Colors.white, 0.4);
      case 64:
        return (const Color(0xFFF65E3B), Colors.white, 0.4);
      case 128:
        return (const Color(0xFFEDCF72), Colors.white, 0.35);
      case 256:
        return (const Color(0xFFEDCC61), Colors.white, 0.35);
      case 512:
        return (const Color(0xFFEDC850), Colors.white, 0.35);
      case 1024:
        return (const Color(0xFFEDC53F), Colors.white, 0.28);
      case 2048:
        return (const Color(0xFFEDC22E), Colors.white, 0.28);
      default:
        return (const Color(0xFF3C3A32), Colors.white, 0.25);
    }
  }
}

// ============================================
// STANDALONE TEST WIDGET FOR PROTOTYPING
// ============================================

class Game2048TestScreen extends StatefulWidget {
  const Game2048TestScreen({super.key});

  @override
  State<Game2048TestScreen> createState() => _Game2048TestScreenState();
}

class _Game2048TestScreenState extends State<Game2048TestScreen> {
  late Game2048Puzzle _puzzle;
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
          _puzzle = Game2048Puzzle.sampleLevel1();
          break;
        case 2:
          _puzzle = Game2048Puzzle.sampleLevel2();
          break;
        case 3:
          _puzzle = Game2048Puzzle.sampleLevel3();
          break;
        default:
          _puzzle = Game2048Puzzle.sampleLevel1();
      }
    });
  }

  void _onComplete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('You Win!'),
        content: Text(
          'You reached 2048!\n'
          'Score: ${_puzzle.score}\n'
          'Moves: ${_puzzle.moveCount}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Keep playing
            },
            child: const Text('Keep Playing'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadLevel(_currentLevel);
            },
            child: const Text('New Game'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('2048 Prototype'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.layers),
            tooltip: 'Select Level',
            onSelected: _loadLevel,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 1, child: Text('Level 1: New Game')),
              const PopupMenuItem(value: 2, child: Text('Level 2: In Progress')),
              const PopupMenuItem(value: 3, child: Text('Level 3: Advanced')),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Game2048Grid(
          key: ValueKey('$_currentLevel-${_puzzle.hashCode}'),
          puzzle: _puzzle,
          onComplete: _onComplete,
          onMove: () => setState(() {}),
        ),
      ),
    );
  }
}
