import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/game_models.dart';
import 'game_icon.dart';

/// Large featured hero card for the home screen.
/// Shows a prominent puzzle with rich visual design.
class HeroPuzzleCard extends StatelessWidget {
  final DailyPuzzle puzzle;
  final VoidCallback onTap;
  final bool isCompleted;
  final bool isInProgress;
  final int? completionTime;
  final int? completionScore;

  const HeroPuzzleCard({
    super.key,
    required this.puzzle,
    required this.onTap,
    this.isCompleted = false,
    this.isInProgress = false,
    this.completionTime,
    this.completionScore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _getGameColors(puzzle.gameType);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.$1,
              colors.$2,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colors.$1.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 12),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -30,
              bottom: -30,
              child: GameIcon(
                gameType: puzzle.gameType,
                size: 180,
                color: Colors.white.withValues(alpha: 0.15),
                showBackground: false,
              ),
            ),

            // Shimmer overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.15),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.05),
                    ],
                    stops: const [0, 0.3, 0.7, 1],
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: Icon and status
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: GameIcon(
                          gameType: puzzle.gameType,
                          size: 28,
                          color: Colors.white,
                          showBackground: false,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'FEATURED',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                    ],
                  ),

                  const Spacer(),

                  // Title and difficulty
                  Text(
                    puzzle.gameType.displayName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Difficulty stars
                      ...List.generate(
                        4,
                        (index) => Icon(
                          index < puzzle.difficulty.stars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 14,
                          color: Colors.white.withValues(alpha: index < puzzle.difficulty.stars ? 1 : 0.5),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          puzzle.difficulty.displayName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      // Play button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCompleted
                                  ? Icons.replay_rounded
                                  : isInProgress
                                      ? Icons.play_arrow_rounded
                                      : Icons.play_arrow_rounded,
                              size: 16,
                              color: colors.$1,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isCompleted ? 'View' : isInProgress ? 'Continue' : 'Play',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colors.$1,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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
    ).animate()
      .fadeIn(duration: 600.ms)
      .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }

  (Color, Color) _getGameColors(GameType type) {
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
        return (const Color(0xFFEAB308), const Color(0xFFFDE047));
      case GameType.nonogram:
        return (const Color(0xFF64748B), const Color(0xFF94A3B8));
      case GameType.numberTarget:
        return (const Color(0xFF10B981), const Color(0xFF34D399));
      case GameType.ballSort:
        return (const Color(0xFFF472B6), const Color(0xFFFBCFE8));
      case GameType.pipes:
        return (const Color(0xFF06B6D4), const Color(0xFF14B8A6));
      case GameType.lightsOut:
        return (const Color(0xFFEAB308), const Color(0xFFF59E0B));
      case GameType.wordLadder:
        return (const Color(0xFF6366F1), const Color(0xFF8B5CF6));
      case GameType.connections:
        return (const Color(0xFFF43F5E), const Color(0xFFEC4899));
      case GameType.mathora:
        return (const Color(0xFF10B981), const Color(0xFF059669));
      case GameType.mobius:
        return (const Color(0xFF06B6D4), const Color(0xFF0891B2)); // Cyan/Teal
      case GameType.slidingPuzzle:
        return (const Color(0xFF14B8A6), const Color(0xFF0D9488)); // Teal
      case GameType.memoryMatch:
        return (const Color(0xFFEC4899), const Color(0xFFDB2777)); // Pink
      case GameType.game2048:
        return (const Color(0xFFEAB308), const Color(0xFFCA8A04)); // Yellow/Amber
      case GameType.simon:
        return (const Color(0xFF7C3AED), const Color(0xFF6D28D9)); // Purple
      case GameType.towerOfHanoi:
        return (const Color(0xFF92400E), const Color(0xFFB45309)); // Brown/Amber
    }
  }
}
