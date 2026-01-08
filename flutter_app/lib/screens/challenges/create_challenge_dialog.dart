import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/game_models.dart';
import '../../services/challenge_service.dart';

class CreateChallengeDialog extends StatefulWidget {
  final String opponentId;
  final String opponentUsername;

  const CreateChallengeDialog({
    super.key,
    required this.opponentId,
    required this.opponentUsername,
  });

  @override
  State<CreateChallengeDialog> createState() => _CreateChallengeDialogState();
}

class _CreateChallengeDialogState extends State<CreateChallengeDialog> {
  GameType _selectedGameType = GameType.sudoku;
  Difficulty _selectedDifficulty = Difficulty.medium;
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.sports_esports_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Challenge ${widget.opponentUsername}',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Game Type Selection
              Text(
                'Game Type',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: GameType.values.map((type) {
                  final isSelected = type == _selectedGameType;
                  return ChoiceChip(
                    selected: isSelected,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getGameTypeIcon(type),
                          size: 18,
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                        ),
                        const SizedBox(width: 8),
                        Text(_getGameTypeName(type)),
                      ],
                    ),
                    selectedColor: theme.colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedGameType = type);
                      }
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Difficulty Selection
              Text(
                'Difficulty',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: Difficulty.values.map((difficulty) {
                  final isSelected = difficulty == _selectedDifficulty;
                  final color = _getDifficultyColor(difficulty);
                  return ChoiceChip(
                    selected: isSelected,
                    label: Text(difficulty.displayName),
                    selectedColor: color,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : color,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedDifficulty = difficulty);
                      }
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Message (optional)
              Text(
                'Message (optional)',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'e.g., "Good luck!"',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
                maxLength: 100,
                maxLines: 2,
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendChallenge,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Send Challenge'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getGameTypeIcon(GameType type) {
    switch (type) {
      case GameType.sudoku:
        return Icons.grid_on_rounded;
      case GameType.killerSudoku:
        return Icons.grid_4x4_rounded;
      case GameType.crossword:
        return Icons.abc_rounded;
      case GameType.wordSearch:
        return Icons.search_rounded;
      case GameType.wordForge:
        return Icons.text_fields_rounded;
      case GameType.nonogram:
        return Icons.grid_view_rounded;
      case GameType.numberTarget:
        return Icons.calculate_rounded;
      case GameType.ballSort:
        return Icons.sports_baseball_rounded;
      case GameType.pipes:
        return Icons.route_rounded;
      case GameType.lightsOut:
        return Icons.lightbulb_rounded;
      case GameType.wordLadder:
        return Icons.stairs_rounded;
      case GameType.connections:
        return Icons.link_rounded;
      case GameType.mathora:
        return Icons.calculate_outlined;
      case GameType.mobius:
        return Icons.all_inclusive;
      case GameType.slidingPuzzle:
        return Icons.grid_view_rounded;
      case GameType.memoryMatch:
        return Icons.flip_rounded;
      case GameType.game2048:
        return Icons.grid_4x4_rounded;
    }
  }

  String _getGameTypeName(GameType type) {
    switch (type) {
      case GameType.sudoku:
        return 'Sudoku';
      case GameType.killerSudoku:
        return 'Killer Sudoku';
      case GameType.crossword:
        return 'Crossword';
      case GameType.wordSearch:
        return 'Word Search';
      case GameType.wordForge:
        return 'Word Forge';
      case GameType.nonogram:
        return 'Nonogram';
      case GameType.numberTarget:
        return 'Number Target';
      case GameType.ballSort:
        return 'Ball Sort';
      case GameType.pipes:
        return 'Pipes';
      case GameType.lightsOut:
        return 'Lights Out';
      case GameType.wordLadder:
        return 'Word Ladder';
      case GameType.connections:
        return 'Connections';
      case GameType.mathora:
        return 'Mathora';
      case GameType.mobius:
        return 'Mobius';
      case GameType.slidingPuzzle:
        return 'Sliding Puzzle';
      case GameType.memoryMatch:
        return 'Memory Match';
      case GameType.game2048:
        return '2048';
    }
  }

  Color _getDifficultyColor(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return Colors.green;
      case Difficulty.medium:
        return Colors.orange;
      case Difficulty.hard:
        return Colors.red;
      case Difficulty.expert:
        return Colors.purple;
    }
  }

  Future<void> _sendChallenge() async {
    setState(() => _isLoading = true);

    try {
      final challengeService =
          Provider.of<ChallengeService>(context, listen: false);
      await challengeService.createChallenge(
        opponentId: widget.opponentId,
        gameType: _selectedGameType,
        difficulty: _selectedDifficulty,
        message: _messageController.text.trim().isNotEmpty
            ? _messageController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Challenge sent to ${widget.opponentUsername}!'),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send challenge: $e')),
        );
      }
    }
  }
}
