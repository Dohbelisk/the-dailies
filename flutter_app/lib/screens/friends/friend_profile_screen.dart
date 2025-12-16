import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/friend_models.dart';
import '../../services/friends_service.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/animated_background.dart';
import '../challenges/create_challenge_dialog.dart';
import '../challenges/challenges_screen.dart';

class FriendProfileScreen extends StatefulWidget {
  final Friend friend;

  const FriendProfileScreen({super.key, required this.friend});

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  late Future<FriendStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    final friendsService = Provider.of<FriendsService>(context, listen: false);
    setState(() {
      _statsFuture = friendsService.getFriendStats(widget.friend.user.id);
    });
  }

  Future<void> _removeFriend() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Friend'),
        content: Text('Are you sure you want to remove ${widget.friend.user.username} from your friends?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final friendsService = Provider.of<FriendsService>(context, listen: false);
        await friendsService.removeFriend(widget.friend.user.id);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Friend removed')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove friend: $e')),
          );
        }
      }
    }
  }

  Future<void> _showChallengeDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CreateChallengeDialog(
        opponentId: widget.friend.user.id,
        opponentUsername: widget.friend.user.username,
      ),
    );

    if (result == true) {
      _loadStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final dateFormat = DateFormat('MMMM d, yyyy');

    return Scaffold(
      body: Stack(
        children: [
          AnimatedBackground(isDark: themeProvider.isDarkMode),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_rounded),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Spacer(),
                            PopupMenuButton(
                              icon: const Icon(Icons.more_vert_rounded),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'remove',
                                  child: Row(
                                    children: [
                                      Icon(Icons.person_remove_rounded, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Remove Friend', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'remove') {
                                  _removeFriend();
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // Profile Avatar
                        CircleAvatar(
                          radius: 56,
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                          child: Text(
                            widget.friend.user.username.isNotEmpty
                                ? widget.friend.user.username[0].toUpperCase()
                                : '?',
                            style: theme.textTheme.displayMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ).animate()
                          .fadeIn(duration: 600.ms)
                          .scale(begin: const Offset(0.5, 0.5)),
                        const SizedBox(height: 16),
                        Text(
                          widget.friend.user.username,
                          style: theme.textTheme.headlineMedium,
                        ).animate()
                          .fadeIn(delay: 100.ms, duration: 600.ms)
                          .slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 8),
                        Text(
                          'Friends since ${dateFormat.format(widget.friend.friendsSince)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onBackground.withOpacity(0.6),
                          ),
                        ).animate()
                          .fadeIn(delay: 200.ms, duration: 600.ms),
                      ],
                    ),
                  ),
                ),
                // Stats
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: FutureBuilder<FriendStats>(
                      future: _statsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(48),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final stats = snapshot.data ?? FriendStats(wins: 0, losses: 0, ties: 0, totalChallenges: 0);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            Text(
                              'Challenge Stats',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    'Wins',
                                    stats.wins.toString(),
                                    Icons.emoji_events_rounded,
                                    Colors.green,
                                    0,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    'Losses',
                                    stats.losses.toString(),
                                    Icons.trending_down_rounded,
                                    Colors.red,
                                    1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    'Ties',
                                    stats.ties.toString(),
                                    Icons.horizontal_rule_rounded,
                                    Colors.orange,
                                    2,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    'Total',
                                    stats.totalChallenges.toString(),
                                    Icons.bar_chart_rounded,
                                    theme.colorScheme.primary,
                                    3,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                // Challenge Buttons
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showChallengeDialog(),
                          icon: const Icon(Icons.sports_esports_rounded),
                          label: const Text('Send Challenge'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        ).animate()
                          .fadeIn(delay: 400.ms, duration: 600.ms)
                          .slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ChallengesScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.history_rounded),
                          label: const Text('View All Challenges'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        ).animate()
                          .fadeIn(delay: 500.ms, duration: 600.ms)
                          .slideY(begin: 0.2, end: 0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, int index) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(delay: Duration(milliseconds: 300 + index * 100), duration: 600.ms)
      .slideY(begin: 0.2, end: 0);
  }
}
