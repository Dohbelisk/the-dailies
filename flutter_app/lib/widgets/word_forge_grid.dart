import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_models.dart';

class WordForgeGrid extends StatelessWidget {
  final WordForgePuzzle puzzle;
  final String currentWord;
  final Function(String letter) onLetterTap;
  final VoidCallback onDelete;
  final VoidCallback onShuffle;
  final VoidCallback onSubmit;
  final VoidCallback? onShowHints;

  const WordForgeGrid({
    super.key,
    required this.puzzle,
    required this.currentWord,
    required this.onLetterTap,
    required this.onDelete,
    required this.onShuffle,
    required this.onSubmit,
    this.onShowHints,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Progress bar with level indicator (Spelling Bee style)
        _buildProgressBar(context),
        const SizedBox(height: 12),

        // Current word display
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Center(
            child: Text(
              currentWord.isEmpty ? 'Tap letters...' : currentWord,
              style: theme.textTheme.titleLarge?.copyWith(
                color: currentWord.isEmpty
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Honeycomb layout
        SizedBox(
          height: 220,
          child: _buildHoneycomb(context),
        ),
        const SizedBox(height: 16),

        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Delete button
            _ActionButton(
              icon: Icons.backspace_outlined,
              onTap: onDelete,
              theme: theme,
            ),
            const SizedBox(width: 12),
            // Shuffle button
            _ActionButton(
              icon: Icons.shuffle,
              onTap: onShuffle,
              theme: theme,
            ),
            const SizedBox(width: 12),
            // Hints button
            if (onShowHints != null)
              _ActionButton(
                icon: Icons.lightbulb_outline,
                onTap: onShowHints!,
                theme: theme,
              ),
            if (onShowHints != null) const SizedBox(width: 12),
            // Submit button
            FilledButton(
              onPressed: currentWord.length >= 4 ? onSubmit : null,
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Enter'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHoneycomb(BuildContext context) {
    final theme = Theme.of(context);

    // Get outer letters (all except center)
    final outerLetters = puzzle.letters
        .where((l) => l != puzzle.centerLetter)
        .toList();

    // Honeycomb positions for 7 hexagons
    // Center hexagon at (0, 0)
    // 6 surrounding hexagons arranged in a circle
    const double hexSize = 38;
    // Distance from center to outer hexagon centers (hexSize * sqrt(3) for touching)
    final double distanceToOuter = hexSize * 1.85;
    final double hexWidth = hexSize * 2;
    final double hexHeight = hexSize * sqrt(3);
    final double containerWidth = hexWidth + distanceToOuter * 2 + 8;
    final double containerHeight = hexHeight + distanceToOuter * 2 + 8;

    return Center(
      child: SizedBox(
        width: containerWidth,
        height: containerHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center hexagon (center letter - yellow/amber)
            Positioned(
              left: containerWidth / 2 - hexSize,
              top: containerHeight / 2 - hexHeight / 2,
              child: _HexagonButton(
                letter: puzzle.centerLetter,
                isCenter: true,
                size: hexSize,
                onTap: () => onLetterTap(puzzle.centerLetter),
                theme: theme,
              ),
            ),
            // Outer hexagons
            for (int i = 0; i < 6 && i < outerLetters.length; i++)
              Positioned(
                left: containerWidth / 2 + distanceToOuter * cos(i * pi / 3 - pi / 2) - hexSize,
                top: containerHeight / 2 + distanceToOuter * sin(i * pi / 3 - pi / 2) - hexHeight / 2,
                child: _HexagonButton(
                  letter: outerLetters[i],
                  isCenter: false,
                  size: hexSize,
                  onTap: () => onLetterTap(outerLetters[i]),
                  theme: theme,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    final theme = Theme.of(context);
    final levels = WordForgePuzzle.levels;

    return Column(
      children: [
        // Level name and score
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              puzzle.currentLevel,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              '${puzzle.currentScore} pts',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Progress bar with level markers
        SizedBox(
          height: 24,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return Stack(
                children: [
                  // Background track
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  // Filled progress
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: width * (puzzle.progressPercent / 100),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.amber.shade400,
                            Colors.amber.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  // Level markers (dots)
                  for (final level in levels)
                    if (level['percent'] > 0 && level['percent'] < 100)
                      Positioned(
                        left: width * (level['percent'] / 100) - 4,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: puzzle.progressPercent >= level['percent']
                                ? Colors.amber.shade800
                                : theme.colorScheme.outline,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        // Words found count
        Text(
          '${puzzle.foundWords.length} word${puzzle.foundWords.length == 1 ? '' : 's'} found',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _HexagonButton extends StatelessWidget {
  final String letter;
  final bool isCenter;
  final double size;
  final VoidCallback onTap;
  final ThemeData theme;

  const _HexagonButton({
    required this.letter,
    required this.isCenter,
    required this.size,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _HexagonPainter(
          fillColor:
              isCenter ? Colors.amber.shade400 : theme.colorScheme.surfaceContainerHighest,
          strokeColor:
              isCenter ? Colors.amber.shade700 : theme.colorScheme.outline,
        ),
        child: SizedBox(
          width: size * 2,
          height: size * sqrt(3),
          child: Center(
            child: Text(
              letter,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color:
                    isCenter ? Colors.black87 : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HexagonPainter extends CustomPainter {
  final Color fillColor;
  final Color strokeColor;

  _HexagonPainter({required this.fillColor, required this.strokeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final path = _createHexagonPath(size);

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  Path _createHexagonPath(Size size) {
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width / 2 - 2;

    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * pi / 180;
      final x = centerX + radius * cos(angle);
      final y = centerY + radius * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _HexagonPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.strokeColor != strokeColor;
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final ThemeData theme;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Icon(
            icon,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Two-letter hints grid (FREE - Spelling Bee style)
class WordForgeTwoLetterGrid extends StatelessWidget {
  final Map<String, int> hints;

  const WordForgeTwoLetterGrid({super.key, required this.hints});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedKeys = hints.keys.toList()..sort();

    if (sortedKeys.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No hints available - you found them all!',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    // Group by first letter
    final Map<String, List<MapEntry<String, int>>> grouped = {};
    for (final entry in hints.entries) {
      final firstLetter = entry.key[0];
      grouped.putIfAbsent(firstLetter, () => []);
      grouped[firstLetter]!.add(entry);
    }

    final sortedFirstLetters = grouped.keys.toList()..sort();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final firstLetter in sortedFirstLetters) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: grouped[firstLetter]!.map((entry) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${entry.key}: ${entry.value}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'SpaceMono',
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Hints bottom sheet content
class WordForgeHintsSheet extends StatelessWidget {
  final Map<String, int> twoLetterHints;
  final bool hasUnfoundPangrams;
  final bool pangramHintUsed;
  final Map<String, dynamic>? pangramHint;
  final VoidCallback onUsePangramHint;
  final Function(String word) onRevealWord;
  final Map<String, dynamic>? wordHint;

  const WordForgeHintsSheet({
    super.key,
    required this.twoLetterHints,
    required this.hasUnfoundPangrams,
    required this.pangramHintUsed,
    required this.pangramHint,
    required this.onUsePangramHint,
    required this.onRevealWord,
    this.wordHint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Hints',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Two-letter grid (FREE)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.grid_view,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Two-Letter Grid',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'FREE',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Shows how many words start with each two-letter combination',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    WordForgeTwoLetterGrid(hints: twoLetterHints),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Pangram hint (only if hasn't found one yet)
              if (hasUnfoundPangrams)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.shade300,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Pangram Hint',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade800,
                            ),
                          ),
                          const Spacer(),
                          if (!pangramHintUsed)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '1 HINT',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.amber.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (pangramHintUsed && pangramHint != null)
                        Text(
                          'Pangram starts with "${pangramHint!['firstLetter']}" and is ${pangramHint!['length']} letters long',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Get a hint for an unfound pangram (7-letter word using all letters)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            FilledButton.tonal(
                              onPressed: onUsePangramHint,
                              child: const Text('Reveal Pangram Hint'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              if (hasUnfoundPangrams) const SizedBox(height: 16),

              // Word reveal hint
              if (wordHint != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.error.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.visibility,
                            color: theme.colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Reveal a Word',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.error,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '1 HINT',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onErrorContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Reveal a random word and add it to your found words',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: () {
                          onRevealWord(wordHint!['word']);
                          Navigator.pop(context);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.errorContainer,
                        ),
                        child: const Text('Reveal Random Word'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Spelling Bee style word tracker
class WordForgeWordList extends StatelessWidget {
  final WordForgePuzzle puzzle;

  const WordForgeWordList({super.key, required this.puzzle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedWords = puzzle.foundWords.toList()..sort();

    if (sortedWords.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Your words will appear here',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    // Group words by first letter
    final Map<String, List<String>> groupedWords = {};
    for (final word in sortedWords) {
      final firstLetter = word[0].toUpperCase();
      groupedWords.putIfAbsent(firstLetter, () => []);
      groupedWords[firstLetter]!.add(word);
    }

    final sortedKeys = groupedWords.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Letter tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: sortedKeys.map((letter) {
              final count = groupedWords[letter]!.length;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$letter ($count)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        // Words list
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sortedWords.map((word) {
            final isPangram = puzzle.pangrams.contains(word);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isPangram
                    ? Colors.amber.shade100
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: isPangram
                    ? Border.all(color: Colors.amber.shade400, width: 2)
                    : null,
              ),
              child: Text(
                word.toLowerCase(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isPangram ? FontWeight.bold : FontWeight.normal,
                  color: isPangram
                      ? Colors.amber.shade900
                      : theme.colorScheme.onSurface,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
