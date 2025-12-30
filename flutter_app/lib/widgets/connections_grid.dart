import 'package:flutter/material.dart';
import '../models/game_models.dart';

class ConnectionsGrid extends StatelessWidget {
  final ConnectionsPuzzle puzzle;
  final Function(String word) onWordTap;
  final VoidCallback onSubmit;
  final VoidCallback onClear;
  final VoidCallback onShuffle;
  final String? message;
  final bool? messageSuccess;

  const ConnectionsGrid({
    super.key,
    required this.puzzle,
    required this.onWordTap,
    required this.onSubmit,
    required this.onClear,
    required this.onShuffle,
    this.message,
    this.messageSuccess,
  });

  static const Map<int, Color> _difficultyColors = {
    1: Color(0xFFFDD835), // Yellow - easiest
    2: Color(0xFF66BB6A), // Green
    3: Color(0xFF42A5F5), // Blue
    4: Color(0xFFAB47BC), // Purple - hardest
  };

  Color _getDifficultyColor(int difficulty) {
    return _difficultyColors[difficulty] ?? Colors.grey;
  }

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
                    'Find 4 groups of 4',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Mistakes: ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      for (int i = 0; i < 4; i++)
                        Icon(
                          i < puzzle.mistakesRemaining
                              ? Icons.circle
                              : Icons.circle_outlined,
                          size: 12,
                          color: i < puzzle.mistakesRemaining
                              ? theme.colorScheme.error
                              : theme.colorScheme.outline,
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Found categories
        if (puzzle.foundCategories.isNotEmpty) ...[
          for (final category in puzzle.foundCategories)
            _buildFoundCategory(context, category),
          const SizedBox(height: 8),
        ],

        // Remaining words grid with message overlay
        Expanded(
          child: Stack(
            children: [
              _buildWordsGrid(context),
              // Message overlay at bottom of grid
              if (message != null && message!.isNotEmpty)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: messageSuccess == true
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(40),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      message!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: messageSuccess == true
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Action buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Shuffle button
              IconButton.outlined(
                onPressed: puzzle.remainingWords.length > 1 && !puzzle.isGameOver
                    ? onShuffle
                    : null,
                icon: const Icon(Icons.shuffle, size: 20),
                tooltip: 'Shuffle words',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: puzzle.selectedWords.isEmpty || puzzle.isGameOver
                      ? null
                      : onClear,
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: puzzle.selectedWords.length == 4 && !puzzle.isGameOver
                      ? onSubmit
                      : null,
                  child: Text(
                    puzzle.isGameOver ? 'Game Over' : 'Submit (${puzzle.selectedWords.length}/4)',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFoundCategory(BuildContext context, ConnectionsCategory category) {
    final theme = Theme.of(context);
    final color = _getDifficultyColor(category.difficulty);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Text(
            category.name.toUpperCase(),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            category.words.join(', '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWordsGrid(BuildContext context) {
    final theme = Theme.of(context);
    final remainingWords = puzzle.remainingWords;

    if (remainingWords.isEmpty) {
      // Don't show celebration if game was lost
      if (puzzle.wasLost) {
        return const SizedBox.shrink();
      }
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.celebration,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'All categories found!',
              style: theme.textTheme.headlineSmall,
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const cols = 4;
        final cellWidth = (constraints.maxWidth - 24) / cols;
        // Make tiles more square - use width as base, cap at reasonable height
        final cellHeight = (cellWidth - 8).clamp(60.0, 80.0);

        return Center(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final word in remainingWords)
                _buildWordTile(context, word, cellWidth - 8, cellHeight),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWordTile(
    BuildContext context,
    String word,
    double width,
    double height,
  ) {
    final theme = Theme.of(context);
    final isSelected = puzzle.selectedWords.contains(word);
    final isGameOver = puzzle.mistakesRemaining <= 0;

    return GestureDetector(
      onTap: isGameOver ? null : () => onWordTap(word),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            word.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
