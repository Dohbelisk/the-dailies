import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/achievement_models.dart';

/// Displays a toast notification when an achievement is unlocked.
class AchievementUnlockToast extends StatelessWidget {
  final AchievementType achievement;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const AchievementUnlockToast({
    super.key,
    required this.achievement,
    this.onTap,
    this.onDismiss,
  });

  /// Show the achievement unlock toast as an overlay.
  static void show(
    BuildContext context,
    AchievementType achievement, {
    VoidCallback? onTap,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: AchievementUnlockToast(
            achievement: achievement,
            onTap: () {
              entry.remove();
              onTap?.call();
            },
            onDismiss: () => entry.remove(),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }

  /// Show multiple achievement unlocks in sequence.
  static Future<void> showMultiple(
    BuildContext context,
    List<AchievementType> achievements, {
    VoidCallback? onComplete,
  }) async {
    for (final achievement in achievements) {
      show(context, achievement);
      await Future.delayed(const Duration(milliseconds: 500));
    }
    onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rarity = achievement.rarity;

    return GestureDetector(
      onTap: onTap,
      child: Dismissible(
        key: ValueKey(achievement),
        direction: DismissDirection.up,
        onDismissed: (_) => onDismiss?.call(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                rarity.color,
                rarity.color.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: rarity.color.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon with glow
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  achievement.iconData ?? Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
                .shimmer(
                  duration: 1500.ms,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              const SizedBox(width: 12),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'ACHIEVEMENT UNLOCKED',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      achievement.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // XP badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${rarity.xpReward} XP',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ).animate()
          .fadeIn(duration: 300.ms)
          .slideY(begin: -1, end: 0, curve: Curves.easeOutBack)
          .then(delay: 3000.ms)
          .fadeOut(duration: 300.ms)
          .slideY(begin: 0, end: -1),
      ),
    );
  }
}
