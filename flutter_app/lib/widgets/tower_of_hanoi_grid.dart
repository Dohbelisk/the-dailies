import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_models.dart';

/// Tower of Hanoi puzzle widget
class TowerOfHanoiGrid extends StatefulWidget {
  final TowerOfHanoiPuzzle puzzle;
  final VoidCallback? onComplete;
  final VoidCallback? onMove;

  const TowerOfHanoiGrid({
    super.key,
    required this.puzzle,
    this.onComplete,
    this.onMove,
  });

  @override
  State<TowerOfHanoiGrid> createState() => _TowerOfHanoiGridState();
}

class _TowerOfHanoiGridState extends State<TowerOfHanoiGrid> {
  void _onPegTap(int pegIndex) {
    final wasComplete = widget.puzzle.isComplete;
    final oldSelected = widget.puzzle.selectedPeg;
    final hadSelection = oldSelected != null;

    widget.puzzle.selectPeg(pegIndex);
    setState(() {});

    // Check if a move was made (had selection, now doesn't, and different peg)
    if (hadSelection && widget.puzzle.selectedPeg == null && oldSelected != pegIndex) {
      HapticFeedback.mediumImpact();
      widget.onMove?.call();

      if (!wasComplete && widget.puzzle.isComplete) {
        widget.onComplete?.call();
      }
    } else if (widget.puzzle.selectedPeg != null) {
      HapticFeedback.lightImpact();
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
              _buildInfoBox(theme, 'Moves', '${widget.puzzle.moveCount}'),
              const SizedBox(width: 12),
              _buildInfoBox(theme, 'Optimal', '${widget.puzzle.optimalMoves}'),
              const Spacer(),
              IconButton(
                onPressed: () {
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

        // Pegs and disks
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;
              final pegWidth = width / 3;
              final pegHeight = height * 0.7;
              final maxDiskWidth = pegWidth * 0.9;

              return Stack(
                children: [
                  // Base
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 16,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B4513),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // Pegs
                  Row(
                    children: List.generate(3, (pegIndex) {
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _onPegTap(pegIndex),
                          behavior: HitTestBehavior.opaque,
                          child: _buildPeg(
                            theme,
                            pegIndex,
                            pegHeight,
                            maxDiskWidth,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),

        // Instructions
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            widget.puzzle.selectedPeg != null
                ? 'Tap another peg to move the disk'
                : 'Tap a peg to select a disk',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBox(ThemeData theme, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeg(ThemeData theme, int pegIndex, double height, double maxDiskWidth) {
    final disks = widget.puzzle.pegs[pegIndex];
    final isSelected = widget.puzzle.selectedPeg == pegIndex;
    final diskHeight = height / (widget.puzzle.diskCount + 2);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Peg pole
        Container(
          width: 12,
          height: height * 0.8,
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : const Color(0xFF8B4513),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            border: isSelected
                ? Border.all(color: theme.colorScheme.primary, width: 2)
                : null,
          ),
        ),
        // Disks
        ...disks.map((diskSize) {
          final diskWidth = (diskSize / widget.puzzle.diskCount) * maxDiskWidth;
          return Container(
            width: diskWidth,
            height: diskHeight - 4,
            margin: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getDiskColor(diskSize),
                  _getDiskColor(diskSize).withValues(alpha: 0.7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16), // Space above base
      ],
    );
  }

  Color _getDiskColor(int size) {
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
    ];
    return colors[(size - 1) % colors.length];
  }
}

// ============================================
// STANDALONE TEST WIDGET FOR PROTOTYPING
// ============================================

class TowerOfHanoiTestScreen extends StatefulWidget {
  const TowerOfHanoiTestScreen({super.key});

  @override
  State<TowerOfHanoiTestScreen> createState() => _TowerOfHanoiTestScreenState();
}

class _TowerOfHanoiTestScreenState extends State<TowerOfHanoiTestScreen> {
  late TowerOfHanoiPuzzle _puzzle;
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
          _puzzle = TowerOfHanoiPuzzle.sampleLevel1();
          break;
        case 2:
          _puzzle = TowerOfHanoiPuzzle.sampleLevel2();
          break;
        case 3:
          _puzzle = TowerOfHanoiPuzzle.sampleLevel3();
          break;
        default:
          _puzzle = TowerOfHanoiPuzzle.sampleLevel1();
      }
    });
  }

  void _onComplete() {
    final efficiency = (_puzzle.efficiency * 100).toStringAsFixed(1);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Puzzle Complete!'),
        content: Text(
          'Moves: ${_puzzle.moveCount}\n'
          'Optimal: ${_puzzle.optimalMoves}\n'
          'Efficiency: $efficiency%',
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
        title: const Text('Tower of Hanoi Prototype'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.layers),
            tooltip: 'Select Level',
            onSelected: _loadLevel,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 1, child: Text('Level 1: 3 Disks')),
              const PopupMenuItem(value: 2, child: Text('Level 2: 4 Disks')),
              const PopupMenuItem(value: 3, child: Text('Level 3: 5 Disks')),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TowerOfHanoiGrid(
          key: ValueKey(_currentLevel),
          puzzle: _puzzle,
          onComplete: _onComplete,
          onMove: () => setState(() {}),
        ),
      ),
    );
  }
}
