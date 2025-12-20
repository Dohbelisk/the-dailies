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

  const WordForgeGrid({
    super.key,
    required this.puzzle,
    required this.currentWord,
    required this.onLetterTap,
    required this.onDelete,
    required this.onShuffle,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Score display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${puzzle.currentScore}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                ' / ${puzzle.maxScore}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${puzzle.foundWords.length} words',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Current word display
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Center(
            child: Text(
              currentWord.isEmpty ? 'Tap letters to form a word' : currentWord,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: currentWord.isEmpty
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Honeycomb layout
        SizedBox(
          height: 280,
          child: _buildHoneycomb(context),
        ),
        const SizedBox(height: 24),

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
            const SizedBox(width: 16),
            // Shuffle button
            _ActionButton(
              icon: Icons.shuffle,
              onTap: onShuffle,
              theme: theme,
            ),
            const SizedBox(width: 16),
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
    const double hexSize = 60;
    const double spacing = 8;
    final double hexWidth = hexSize * 2;
    final double hexHeight = hexSize * sqrt(3);

    return Center(
      child: SizedBox(
        width: hexWidth * 2.5,
        height: hexHeight * 2.5,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center hexagon (center letter - yellow/amber)
            _HexagonButton(
              letter: puzzle.centerLetter,
              isCenter: true,
              size: hexSize,
              onTap: () => onLetterTap(puzzle.centerLetter),
              theme: theme,
            ),
            // Outer hexagons
            for (int i = 0; i < 6 && i < outerLetters.length; i++)
              Positioned(
                left: (hexWidth * 1.25) +
                    (hexSize + spacing) * cos(i * pi / 3 - pi / 6) -
                    hexSize,
                top: (hexHeight * 1.25) +
                    (hexSize + spacing) * sin(i * pi / 3 - pi / 6) -
                    hexSize * sqrt(3) / 2,
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
                fontSize: 28,
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

/// Widget to display found words
class WordForgeWordList extends StatelessWidget {
  final WordForgePuzzle puzzle;

  const WordForgeWordList({super.key, required this.puzzle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedWords = puzzle.foundWords.toList()..sort();

    if (sortedWords.isEmpty) {
      return Center(
        child: Text(
          'No words found yet',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Wrap(
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
            word,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isPangram ? FontWeight.bold : FontWeight.normal,
              color: isPangram
                  ? Colors.amber.shade900
                  : theme.colorScheme.onSurface,
            ),
          ),
        );
      }).toList(),
    );
  }
}
