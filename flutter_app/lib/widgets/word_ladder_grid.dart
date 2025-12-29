import 'package:flutter/material.dart';
import '../models/game_models.dart';
import 'keyboard_input.dart';

class WordLadderGrid extends StatelessWidget {
  final WordLadderPuzzle puzzle;
  final String currentInput;
  final Function(String) onLetterTap;
  final VoidCallback onDeleteTap;
  final VoidCallback onSubmit;
  final VoidCallback onUndo;
  final VoidCallback onReset;
  final String? message;
  final bool? messageSuccess;

  const WordLadderGrid({
    super.key,
    required this.puzzle,
    required this.currentInput,
    required this.onLetterTap,
    required this.onDeleteTap,
    required this.onSubmit,
    required this.onUndo,
    required this.onReset,
    this.message,
    this.messageSuccess,
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
                    onPressed: (puzzle.pathFromStart.length <= 1 && puzzle.pathFromTarget.length <= 1) ? null : onUndo,
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
                    onPressed: (puzzle.pathFromStart.length <= 1 && puzzle.pathFromTarget.length <= 1) ? null : onReset,
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
          // Target path (building down from target)
          // Show in reverse order so target is at top
          for (int i = 0; i < puzzle.pathFromTarget.length; i++) ...[
            _buildWordCard(
              context,
              puzzle.pathFromTarget[i],
              isTarget: i == 0,
              isStart: false,
              isCurrent: i == puzzle.pathFromTarget.length - 1 && puzzle.pathFromTarget.length > 1,
            ),
            if (i < puzzle.pathFromTarget.length - 1) ...[
              Icon(
                Icons.arrow_downward,
                size: 20,
                color: theme.colorScheme.tertiary,
              ),
            ],
          ],

          // Gap between paths (if not complete)
          if (!puzzle.isComplete) ...[
            const SizedBox(height: 8),
            for (int i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.outline.withAlpha(77),
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ] else ...[
            Icon(
              Icons.arrow_downward,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ],

          // Start path (building up from start)
          // Show in reverse order so most recent is at top (closest to target)
          for (int i = puzzle.pathFromStart.length - 1; i >= 0; i--) ...[
            _buildWordCard(
              context,
              puzzle.pathFromStart[i],
              isTarget: false,
              isStart: i == 0,
              isCurrent: i == puzzle.pathFromStart.length - 1 && puzzle.pathFromStart.length > 1,
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
                    color: theme.colorScheme.onSurface,
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Message display
        if (message != null && message!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: messageSuccess == true
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: messageSuccess == true
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        // Current input display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                'Enter next word (change one letter)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Letter boxes for input
                  for (int i = 0; i < puzzle.wordLength; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Container(
                      width: 44,
                      height: 52,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: i < currentInput.length
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withAlpha(128),
                          width: i < currentInput.length ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          i < currentInput.length ? currentInput[i] : '',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 16),
                  // Add button
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
        ),
        const SizedBox(height: 12),
        // Keyboard
        KeyboardInput(
          onLetterTap: onLetterTap,
          onDeleteTap: onDeleteTap,
        ),
      ],
    );
  }
}
