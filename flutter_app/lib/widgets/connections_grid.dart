import 'package:flutter/material.dart';
import '../models/game_models.dart';

class ConnectionsGrid extends StatelessWidget {
  final ConnectionsPuzzle puzzle;
  final Function(String word) onWordTap;
  final VoidCallback onSubmit;
  final VoidCallback onClear;
  final VoidCallback onReset;

  const ConnectionsGrid({
    super.key,
    required this.puzzle,
    required this.onWordTap,
    required this.onSubmit,
    required this.onClear,
    required this.onReset,
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
              IconButton.outlined(
                onPressed: (puzzle.foundCategories.isEmpty &&
                        puzzle.mistakesRemaining == 4)
                    ? null
                    : onReset,
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Reset puzzle',
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

        // Remaining words grid
        Expanded(
          child: _buildWordsGrid(context),
        ),

        // Action buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      puzzle.selectedWords.isEmpty ? null : onClear,
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed:
                      puzzle.selectedWords.length == 4 ? onSubmit : null,
                  child: Text(
                    'Submit (${puzzle.selectedWords.length}/4)',
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
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Text(
            category.name.toUpperCase(),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.8),
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
        final cols = 4;
        final rows = (remainingWords.length / cols).ceil();
        final cellWidth = (constraints.maxWidth - 24) / cols;
        final cellHeight = 50.0;

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

    return GestureDetector(
      onTap: () => onWordTap(word),
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
                : theme.colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.2),
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
