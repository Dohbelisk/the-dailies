import 'package:flutter/material.dart';
import '../models/game_models.dart';
import 'game_icon.dart';

/// A more vibrant puzzle card with progress rings and bolder gradients.
/// Used in the magazine-style layout on the home screen.
class VibrantPuzzleCard extends StatelessWidget {
  final DailyPuzzle puzzle;
  final VoidCallback onTap;
  final bool isLocked;
  final bool isCompleted;
  final bool isInProgress;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final int? completionTime;
  final int? completionScore;
  final bool isLarge; // For magazine-style varied sizes

  const VibrantPuzzleCard({
    super.key,
    required this.puzzle,
    required this.onTap,
    this.isLocked = false,
    this.isCompleted = false,
    this.isInProgress = false,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.completionTime,
    this.completionScore,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _getGameColors(puzzle.gameType);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    colors.$1.withValues(alpha: 0.25),
                    colors.$2.withValues(alpha: 0.15),
                  ]
                : [
                    colors.$1.withValues(alpha: 0.2),
                    colors.$2.withValues(alpha: 0.1),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colors.$1.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.$1.withValues(alpha: isDark ? 0.25 : 0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background icon pattern
            Positioned(
              right: isLarge ? -20 : -15,
              bottom: isLarge ? -20 : -15,
              child: GameIcon(
                gameType: puzzle.gameType,
                size: isLarge ? 100 : 70,
                color: colors.$1.withValues(alpha: 0.12),
                showBackground: false,
              ),
            ),

            // Glow effect for completed
            if (isCompleted)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: RadialGradient(
                      center: Alignment.topLeft,
                      radius: 1.5,
                      colors: [
                        Colors.green.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

            // Locked overlay
            if (isLocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.lock_rounded,
                      size: isLarge ? 48 : 36,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),

            // Content
            Padding(
              padding: EdgeInsets.all(isLarge ? 16 : 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: Icon with progress ring, status, and favorite
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon with progress ring
                      _buildIconWithProgress(theme, colors),
                      const Spacer(),
                      // Status and favorite
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Status badge
                          if (isCompleted)
                            _buildStatusBadge(
                              Icons.check_circle_rounded,
                              Colors.green,
                            )
                          else if (isInProgress)
                            _buildStatusBadge(
                              Icons.play_arrow_rounded,
                              Colors.orange,
                            ),
                          // Favorite button
                          if (onFavoriteToggle != null) ...[
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: onFavoriteToggle,
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: isLarge ? 22 : 16,
                                color: isFavorite
                                    ? Colors.red
                                    : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Title
                  Text(
                    puzzle.gameType.displayName,
                    style: (isLarge
                            ? theme.textTheme.titleLarge
                            : theme.textTheme.titleSmall)
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (isLarge) const SizedBox(height: 4),

                  // Difficulty - only show stars on small cards to save space
                  if (isLarge)
                    Row(
                      children: [
                        ...List.generate(
                          4,
                          (index) => Icon(
                            index < puzzle.difficulty.stars
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 14,
                            color: index < puzzle.difficulty.stars
                                ? colors.$1
                                : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            puzzle.difficulty.displayName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  else
                    // Compact difficulty for small cards - just stars
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        4,
                        (index) => Icon(
                          index < puzzle.difficulty.stars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 10,
                          color: index < puzzle.difficulty.stars
                              ? colors.$1
                              : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                      ),
                    ),

                  if (isLarge) const SizedBox(height: 8),

                  // Bottom action/info
                  if (isLarge)
                    _buildBottomSection(theme, colors.$1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconWithProgress(ThemeData theme, (Color, Color) colors) {
    final iconSize = isLarge ? 48.0 : 32.0;
    final ringSize = iconSize + 6;

    return SizedBox(
      width: ringSize,
      height: ringSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Progress ring (shows completion or in-progress state)
          if (isCompleted || isInProgress)
            SizedBox(
              width: ringSize,
              height: ringSize,
              child: CircularProgressIndicator(
                value: isCompleted ? 1 : 0.5,
                strokeWidth: isLarge ? 3 : 2,
                strokeCap: StrokeCap.round,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation(
                  isCompleted ? Colors.green : Colors.orange,
                ),
              ),
            ),
          // Icon container
          Container(
            padding: EdgeInsets.all(isLarge ? 10 : 6),
            decoration: BoxDecoration(
              color: colors.$1.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(isLarge ? 14 : 10),
            ),
            child: GameIcon(
              gameType: puzzle.gameType,
              size: isLarge ? 28 : 20,
              color: colors.$1,
              showBackground: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: 14,
        color: color,
      ),
    );
  }

  Widget _buildBottomSection(ThemeData theme, Color accentColor) {
    if (isCompleted) {
      final minutes = (completionTime ?? 0) ~/ 60;
      final seconds = (completionTime ?? 0) % 60;
      final timeStr = '$minutes:${seconds.toString().padLeft(2, '0')}';

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 14,
              color: Colors.green,
            ),
            const SizedBox(width: 6),
            Text(
              'Completed',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (completionTime != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.timer_outlined,
                size: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 2),
              Text(
                timeStr,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Row(
      children: [
        Icon(
          Icons.play_circle_filled_rounded,
          size: 16,
          color: accentColor,
        ),
        const SizedBox(width: 4),
        Text(
          isInProgress ? 'Continue' : 'Play',
          style: theme.textTheme.labelMedium?.copyWith(
            color: accentColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
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
    }
  }
}
