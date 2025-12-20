import 'package:flutter/material.dart';
import '../models/game_models.dart';

class PuzzleCard extends StatelessWidget {
  final DailyPuzzle puzzle;
  final VoidCallback onTap;
  final bool isLocked;

  const PuzzleCard({
    super.key,
    required this.puzzle,
    required this.onTap,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _getGameTypeColors(puzzle.gameType, theme);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.$1.withOpacity(0.15),
              colors.$2.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colors.$1.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.$1.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -20,
              bottom: -20,
              child: Text(
                puzzle.gameType.icon,
                style: TextStyle(
                  fontSize: 80,
                  color: colors.$1.withOpacity(0.1),
                ),
              ),
            ),

            // Locked overlay
            if (isLocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.lock_rounded,
                      size: 48,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.$1.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      puzzle.gameType.icon,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),

                  const Spacer(),

                  // Title
                  Text(
                    puzzle.gameType.displayName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Difficulty stars
                  Row(
                    children: [
                      ...List.generate(
                        4,
                        (index) => Icon(
                          index < puzzle.difficulty.stars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 16,
                          color: index < puzzle.difficulty.stars
                              ? colors.$1
                              : theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        puzzle.difficulty.displayName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Status indicator
                  if (puzzle.isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Completed',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      children: [
                        Icon(
                          Icons.play_circle_filled_rounded,
                          size: 18,
                          color: colors.$1,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Play Now',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.$1,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (Color, Color) _getGameTypeColors(GameType type, ThemeData theme) {
    switch (type) {
      case GameType.sudoku:
        return (const Color(0xFF6366F1), const Color(0xFF8B5CF6));
      case GameType.killerSudoku:
        return (const Color(0xFFEC4899), const Color(0xFFF472B6));
      case GameType.crossword:
        return (const Color(0xFF14B8A6), const Color(0xFF22D3EE));
      case GameType.wordSearch:
        return (const Color(0xFFF59E0B), const Color(0xFFFBBF24));
      case GameType.wordForge:
        return (const Color(0xFFEAB308), const Color(0xFFFDE047)); // Yellow/Amber
      case GameType.nonogram:
        return (const Color(0xFF64748B), const Color(0xFF94A3B8)); // Slate/Gray
      case GameType.numberTarget:
        return (const Color(0xFF10B981), const Color(0xFF34D399)); // Emerald/Green
    }
  }
}
