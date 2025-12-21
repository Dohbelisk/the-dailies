import 'package:flutter/material.dart';
import '../models/game_models.dart';

class WordLadderGrid extends StatelessWidget {
  final WordLadderPuzzle puzzle;
  final String currentInput;
  final Function(String) onInputChanged;
  final VoidCallback onSubmit;
  final VoidCallback onUndo;
  final VoidCallback onReset;

  const WordLadderGrid({
    super.key,
    required this.puzzle,
    required this.currentInput,
    required this.onInputChanged,
    required this.onSubmit,
    required this.onUndo,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Info bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Steps: ${puzzle.currentSteps}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Optimal: ${puzzle.minSteps}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  FilledButton.tonal(
                    onPressed: puzzle.currentPath.length <= 1 ? null : onUndo,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.undo, size: 18),
                        SizedBox(width: 4),
                        Text('Undo'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    onPressed: puzzle.currentPath.length <= 1 ? null : onReset,
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: 'Reset puzzle',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Word ladder display
        Expanded(
          child: _buildLadder(context),
        ),

        // Input area
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildInputArea(context),
        ),
      ],
    );
  }

  Widget _buildLadder(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Target word at top
          _buildWordCard(
            context,
            puzzle.targetWord,
            isTarget: true,
            isStart: false,
            isCurrent: puzzle.currentPath.last == puzzle.targetWord,
          ),
          const SizedBox(height: 8),

          // Dots indicating steps needed
          if (puzzle.currentPath.last != puzzle.targetWord) ...[
            for (int i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],

          // Current path (reversed so most recent is at top)
          for (int i = puzzle.currentPath.length - 1; i >= 0; i--) ...[
            _buildWordCard(
              context,
              puzzle.currentPath[i],
              isTarget: false,
              isStart: i == 0,
              isCurrent: i == puzzle.currentPath.length - 1,
            ),
            if (i > 0) ...[
              Icon(
                Icons.arrow_downward,
                size: 20,
                color: theme.colorScheme.primary,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildWordCard(
    BuildContext context,
    String word, {
    required bool isTarget,
    required bool isStart,
    required bool isCurrent,
  }) {
    final theme = Theme.of(context);

    Color bgColor;
    Color textColor;
    if (isTarget) {
      bgColor = theme.colorScheme.primaryContainer;
      textColor = theme.colorScheme.onPrimaryContainer;
    } else if (isStart) {
      bgColor = theme.colorScheme.secondaryContainer;
      textColor = theme.colorScheme.onSecondaryContainer;
    } else if (isCurrent) {
      bgColor = theme.colorScheme.tertiaryContainer;
      textColor = theme.colorScheme.onTertiaryContainer;
    } else {
      bgColor = theme.colorScheme.surfaceContainerHigh;
      textColor = theme.colorScheme.onSurface;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: (isTarget || isCurrent)
            ? Border.all(
                color: theme.colorScheme.primary,
                width: 2,
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < word.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Container(
              width: 36,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  word[i],
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Enter next word (change one letter)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: onInputChanged,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: puzzle.wordLength,
                  decoration: InputDecoration(
                    hintText: 'Enter ${puzzle.wordLength}-letter word',
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: theme.textTheme.titleLarge?.copyWith(
                    letterSpacing: 4,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: currentInput.length == puzzle.wordLength
                    ? onSubmit
                    : null,
                child: const Text('Add'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
