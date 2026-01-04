import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/game_models.dart';
import '../services/game_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late Future<UserStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    final gameService = Provider.of<GameService>(context, listen: false);
    _statsFuture = gameService.getUserStats();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        centerTitle: true,
      ),
      body: FutureBuilder<UserStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = snapshot.data ?? UserStats.empty();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main stats cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.games_rounded,
                        label: 'Games Played',
                        value: '${stats.totalGamesPlayed}',
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.emoji_events_rounded,
                        label: 'Games Won',
                        value: '${stats.totalGamesWon}',
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 16),

                // Streak cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.local_fire_department_rounded,
                        label: 'Current Streak',
                        value: '${stats.currentStreak}',
                        color: Colors.orange,
                        suffix: 'days',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.whatshot_rounded,
                        label: 'Best Streak',
                        value: '${stats.longestStreak}',
                        color: Colors.red,
                        suffix: 'days',
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 100.ms, duration: 500.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 16),

                // Average time
                _buildStatCard(
                  context,
                  icon: Icons.timer_rounded,
                  label: 'Average Time',
                  value: _formatTime(stats.averageTime),
                  color: theme.colorScheme.secondary,
                  fullWidth: true,
                ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 32),

                // Game type breakdown
                Text(
                  'Games by Type',
                  style: theme.textTheme.headlineMedium,
                ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

                const SizedBox(height: 16),

                ...GameType.values.map((type) {
                  final count = stats.gameTypeCounts[type.name] ?? 0;
                  final percentage = stats.totalGamesPlayed > 0
                      ? (count / stats.totalGamesPlayed * 100).round()
                      : 0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildGameTypeRow(
                      context,
                      type: type,
                      count: count,
                      percentage: percentage,
                    ),
                  );
                }).toList().animate(interval: 100.ms).fadeIn(delay: 400.ms).slideX(begin: 0.1, end: 0),

                const SizedBox(height: 32),

                // Win rate
                Center(
                  child: _buildWinRateCircle(
                    context,
                    stats.totalGamesPlayed > 0
                        ? (stats.totalGamesWon / stats.totalGamesPlayed * 100).round()
                        : 0,
                  ),
                ).animate().fadeIn(delay: 600.ms, duration: 500.ms).scale(begin: const Offset(0.8, 0.8)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? suffix,
    bool fullWidth = false,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: fullWidth ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: fullWidth ? MainAxisSize.min : MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    suffix,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameTypeRow(
    BuildContext context, {
    required GameType type,
    required int count,
    required int percentage,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Text(type.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$count',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$percentage%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWinRateCircle(BuildContext context, int percentage) {
    final theme = Theme.of(context);

    return Column(
      children: [
        SizedBox(
          width: 150,
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 12,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$percentage%',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    'Win Rate',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}m ${secs}s';
  }
}
