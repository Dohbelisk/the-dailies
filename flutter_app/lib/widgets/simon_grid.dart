import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_models.dart';

/// Simon game widget with classic 4-button layout
class SimonGrid extends StatefulWidget {
  final SimonPuzzle puzzle;
  final VoidCallback? onComplete;
  final VoidCallback? onMove;
  final VoidCallback? onGameOver;

  const SimonGrid({
    super.key,
    required this.puzzle,
    this.onComplete,
    this.onMove,
    this.onGameOver,
  });

  @override
  State<SimonGrid> createState() => _SimonGridState();
}

class _SimonGridState extends State<SimonGrid> {
  SimonColor? _activeColor;
  bool _showingSequence = false;
  bool _gameStarted = false;

  @override
  void initState() {
    super.initState();
  }

  void _startGame() {
    setState(() {
      _gameStarted = true;
      widget.puzzle.startNewGame();
    });
    _showSequence();
  }

  Future<void> _showSequence() async {
    setState(() => _showingSequence = true);

    await Future.delayed(const Duration(milliseconds: 500));

    for (final color in widget.puzzle.sequence) {
      if (!mounted) return;
      setState(() => _activeColor = color);
      HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() => _activeColor = null);
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (mounted) {
      setState(() {
        _showingSequence = false;
        widget.puzzle.beginPlayerTurn();
      });
    }
  }

  void _onButtonTap(SimonColor color) {
    if (_showingSequence || !widget.puzzle.isPlayerTurn) return;

    setState(() => _activeColor = color);
    HapticFeedback.mediumImpact();

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _activeColor = null);
    });

    final result = widget.puzzle.processInput(color);
    widget.onMove?.call();

    if (result == 'wrong') {
      HapticFeedback.heavyImpact();
      widget.onGameOver?.call();
    } else if (result == 'complete') {
      // Next round
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          widget.puzzle.addToSequence();
          _showSequence();
        }
      });
    } else if (result == 'win') {
      widget.onComplete?.call();
    }

    setState(() {});
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
              _buildInfoBox(theme, 'Level', '${widget.puzzle.level}/${widget.puzzle.targetLevel}'),
              const SizedBox(width: 12),
              _buildInfoBox(theme, 'Best', '${widget.puzzle.highScore}'),
              const Spacer(),
              if (!_gameStarted || widget.puzzle.isGameOver)
                ElevatedButton.icon(
                  onPressed: _startGame,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: Text(widget.puzzle.isGameOver ? 'Try Again' : 'Start'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Game status
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            _getStatusText(),
            style: theme.textTheme.titleMedium?.copyWith(
              color: widget.puzzle.isGameOver
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Simon buttons
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _SimonButton(
                            color: SimonColor.red,
                            isActive: _activeColor == SimonColor.red,
                            isEnabled: widget.puzzle.isPlayerTurn && !_showingSequence,
                            onTap: () => _onButtonTap(SimonColor.red),
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(120)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SimonButton(
                            color: SimonColor.blue,
                            isActive: _activeColor == SimonColor.blue,
                            isEnabled: widget.puzzle.isPlayerTurn && !_showingSequence,
                            onTap: () => _onButtonTap(SimonColor.blue),
                            borderRadius: const BorderRadius.only(topRight: Radius.circular(120)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _SimonButton(
                            color: SimonColor.green,
                            isActive: _activeColor == SimonColor.green,
                            isEnabled: widget.puzzle.isPlayerTurn && !_showingSequence,
                            onTap: () => _onButtonTap(SimonColor.green),
                            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(120)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SimonButton(
                            color: SimonColor.yellow,
                            isActive: _activeColor == SimonColor.yellow,
                            isEnabled: widget.puzzle.isPlayerTurn && !_showingSequence,
                            onTap: () => _onButtonTap(SimonColor.yellow),
                            borderRadius: const BorderRadius.only(bottomRight: Radius.circular(120)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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

  String _getStatusText() {
    if (!_gameStarted) return 'Press Start to play';
    if (widget.puzzle.isGameOver) return 'Game Over!';
    if (_showingSequence) return 'Watch the sequence...';
    if (widget.puzzle.isPlayerTurn) return 'Your turn! ${widget.puzzle.currentIndex}/${widget.puzzle.sequence.length}';
    return 'Get ready...';
  }
}

/// Individual Simon button
class _SimonButton extends StatelessWidget {
  final SimonColor color;
  final bool isActive;
  final bool isEnabled;
  final VoidCallback onTap;
  final BorderRadius borderRadius;

  const _SimonButton({
    required this.color,
    required this.isActive,
    required this.isEnabled,
    required this.onTap,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final (baseColor, activeColor) = _getColors();

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          color: isActive ? activeColor : baseColor,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: isActive ? 2 : 8,
              offset: isActive ? const Offset(1, 1) : const Offset(4, 4),
            ),
          ],
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.1),
            width: 2,
          ),
        ),
      ),
    );
  }

  (Color, Color) _getColors() {
    switch (color) {
      case SimonColor.red:
        return (const Color(0xFFB71C1C), const Color(0xFFFF5252));
      case SimonColor.blue:
        return (const Color(0xFF0D47A1), const Color(0xFF448AFF));
      case SimonColor.green:
        return (const Color(0xFF1B5E20), const Color(0xFF69F0AE));
      case SimonColor.yellow:
        return (const Color(0xFFF57F17), const Color(0xFFFFFF00));
    }
  }
}

// ============================================
// STANDALONE TEST WIDGET FOR PROTOTYPING
// ============================================

class SimonTestScreen extends StatefulWidget {
  const SimonTestScreen({super.key});

  @override
  State<SimonTestScreen> createState() => _SimonTestScreenState();
}

class _SimonTestScreenState extends State<SimonTestScreen> {
  late SimonPuzzle _puzzle;
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
          _puzzle = SimonPuzzle.sampleLevel1();
          break;
        case 2:
          _puzzle = SimonPuzzle.sampleLevel2();
          break;
        case 3:
          _puzzle = SimonPuzzle.sampleLevel3();
          break;
        default:
          _puzzle = SimonPuzzle.sampleLevel1();
      }
    });
  }

  void _onComplete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('You Win!'),
        content: Text(
          'You completed ${_puzzle.targetLevel} levels!\n'
          'High Score: ${_puzzle.highScore}',
        ),
        actions: [
          if (_currentLevel < 3)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _loadLevel(_currentLevel + 1);
              },
              child: const Text('Next Difficulty'),
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
        title: const Text('Simon Prototype'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.layers),
            tooltip: 'Select Difficulty',
            onSelected: _loadLevel,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 1, child: Text('Easy (5 levels)')),
              const PopupMenuItem(value: 2, child: Text('Medium (10 levels)')),
              const PopupMenuItem(value: 3, child: Text('Hard (15 levels)')),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SimonGrid(
          key: ValueKey(_currentLevel),
          puzzle: _puzzle,
          onComplete: _onComplete,
          onMove: () => setState(() {}),
        ),
      ),
    );
  }
}
