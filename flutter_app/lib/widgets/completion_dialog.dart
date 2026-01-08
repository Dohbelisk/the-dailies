import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/game_models.dart';
import 'feedback_dialog.dart';

class CompletionDialog extends StatelessWidget {
  final DailyPuzzle puzzle;
  final int time;
  final int score;
  final int mistakes;
  final int hintsUsed;
  final bool isChallenge;

  const CompletionDialog({
    super.key,
    required this.puzzle,
    required this.time,
    required this.score,
    required this.mistakes,
    required this.hintsUsed,
    this.isChallenge = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minutes = time ~/ 60;
    final seconds = time % 60;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Trophy icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.amber.shade300,
                    Colors.orange.shade400,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 44,
                color: Colors.white,
              ),
            ).animate()
              .scale(begin: const Offset(0, 0), duration: 500.ms, curve: Curves.elasticOut)
              .then()
              .shimmer(duration: 1000.ms),

            const SizedBox(height: 24),

            // Title
            Text(
              isChallenge ? 'Challenge Complete!' : 'Puzzle Complete!',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isChallenge) ...[
                  Icon(
                    Icons.sports_esports_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  puzzle.gameType.displayName,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 300.ms),

            if (isChallenge)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Result submitted! Check challenges for results.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ).animate().fadeIn(delay: 350.ms),

            const SizedBox(height: 24),

            // Score
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'SCORE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$score',
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.8, 0.8)),

            const SizedBox(height: 24),

            // Stats row
            // Only show mistakes for games where it's relevant
            Builder(
              builder: (context) {
                final showMistakes = _shouldShowMistakes(puzzle.gameType);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStat(
                      context,
                      icon: Icons.timer_outlined,
                      label: 'Time',
                      value: '${minutes}m ${seconds}s',
                    ),
                    if (showMistakes)
                      _buildStat(
                        context,
                        icon: Icons.close_rounded,
                        label: 'Mistakes',
                        value: '$mistakes',
                        isNegative: mistakes > 0,
                      ),
                    _buildStat(
                      context,
                      icon: Icons.lightbulb_outline_rounded,
                      label: 'Hints',
                      value: '$hintsUsed',
                    ),
                  ],
                );
              },
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 32),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: theme.colorScheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Home'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Share functionality
                      _shareResult(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.share_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Share'),
                      ],
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 16),

            // Report Issue link
            TextButton.icon(
              icon: Icon(
                Icons.flag_outlined,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              label: Text(
                'Report an Issue',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              onPressed: () {
                Navigator.pop(context); // Close completion dialog
                FeedbackDialog.show(
                  context,
                  puzzleId: puzzle.id,
                  gameType: puzzle.gameType,
                  difficulty: puzzle.difficulty,
                  puzzleDate: puzzle.date,
                );
              },
            ).animate().fadeIn(delay: 700.ms),
          ],
        ),
      ),
    );
  }

  /// Determines if mistakes should be shown for a given game type.
  /// Some games don't track mistakes (e.g., Pipes, Lights Out, Ball Sort)
  /// because there's no concept of a "wrong" move.
  bool _shouldShowMistakes(GameType gameType) {
    switch (gameType) {
      case GameType.sudoku:
      case GameType.killerSudoku:
      case GameType.crossword:
      case GameType.wordForge:
      case GameType.numberTarget:
      case GameType.connections:
      case GameType.mathora:
        return true; // These games track mistakes
      case GameType.pipes:
      case GameType.lightsOut:
      case GameType.ballSort:
      case GameType.wordSearch:
      case GameType.wordLadder:
      case GameType.nonogram:
      case GameType.mobius:
      case GameType.slidingPuzzle:
      case GameType.memoryMatch:
      case GameType.game2048:
      case GameType.simon:
      case GameType.towerOfHanoi:
      case GameType.minesweeper:
      case GameType.sokoban:
        return false; // These games don't have a mistake concept
    }
  }

  Widget _buildStat(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isNegative = false,
  }) {
    final theme = Theme.of(context);
    final color = isNegative ? theme.colorScheme.error : theme.colorScheme.onSurface;

    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: color.withValues(alpha: 0.6),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  void _shareResult(BuildContext context) {
    final minutes = time ~/ 60;
    final seconds = time % 60;
    
    final shareText = '''
🧩 The Dailies - ${puzzle.gameType.displayName}
⭐ Score: $score
⏱️ Time: ${minutes}m ${seconds}s
🔥 Play today's puzzles!
''';

    // In a real app, use share_plus package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share: $shareText'),
        action: SnackBarAction(
          label: 'Copy',
          onPressed: () {
            // Copy to clipboard
          },
        ),
      ),
    );
  }
}
