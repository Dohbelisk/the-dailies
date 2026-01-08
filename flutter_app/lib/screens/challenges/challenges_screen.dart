import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/challenge_models.dart';
import '../../models/game_models.dart';
import '../../services/challenge_service.dart';
import '../../services/auth_service.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/animated_background.dart';
import '../game_screen.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Challenge>> _pendingFuture;
  late Future<List<Challenge>> _activeFuture;
  late Future<List<Challenge>> _completedFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    final challengeService =
        Provider.of<ChallengeService>(context, listen: false);
    setState(() {
      _pendingFuture = challengeService.getPendingChallenges();
      _activeFuture = challengeService.getActiveChallenges();
      _completedFuture =
          challengeService.getChallenges(status: ChallengeStatus.completed);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          AnimatedBackground(isDark: themeProvider.isDarkMode),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Challenges',
                              style: theme.textTheme.displaySmall,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded),
                            onPressed: _loadData,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Tabs
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          labelColor: theme.colorScheme.onPrimary,
                          unselectedLabelColor:
                              theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          dividerColor: Colors.transparent,
                          tabs: const [
                            Tab(text: 'Pending'),
                            Tab(text: 'Active'),
                            Tab(text: 'History'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPendingTab(),
                      _buildActiveTab(),
                      _buildHistoryTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    return FutureBuilder<List<Challenge>>(
      future: _pendingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorWidget('Failed to load pending challenges');
        }

        final challenges = snapshot.data ?? [];

        if (challenges.isEmpty) {
          return _buildEmptyWidget(
            Icons.inbox_outlined,
            'No pending challenges',
            'When someone challenges you, it will appear here',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: challenges.length,
          itemBuilder: (context, index) {
            return _buildPendingChallengeCard(challenges[index], index);
          },
        );
      },
    );
  }

  Widget _buildActiveTab() {
    return FutureBuilder<List<Challenge>>(
      future: _activeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorWidget('Failed to load active challenges');
        }

        final challenges = snapshot.data ?? [];

        if (challenges.isEmpty) {
          return _buildEmptyWidget(
            Icons.sports_esports_outlined,
            'No active challenges',
            'Accept a challenge or send one to a friend',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: challenges.length,
          itemBuilder: (context, index) {
            return _buildActiveChallengeCard(challenges[index], index);
          },
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return FutureBuilder<List<Challenge>>(
      future: _completedFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorWidget('Failed to load challenge history');
        }

        final challenges = snapshot.data ?? [];

        if (challenges.isEmpty) {
          return _buildEmptyWidget(
            Icons.history_outlined,
            'No completed challenges',
            'Complete a challenge to see your history',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: challenges.length,
          itemBuilder: (context, index) {
            return _buildCompletedChallengeCard(challenges[index], index);
          },
        );
      },
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Theme.of(context).colorScheme.onBackground.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onBackground.withValues(alpha: 0.6),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingChallengeCard(Challenge challenge, int index) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                  child: Text(
                    challenge.challengerUsername.isNotEmpty
                        ? challenge.challengerUsername[0].toUpperCase()
                        : '?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.challengerUsername,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        'challenged you!',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildGameTypeBadge(challenge.gameType),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  'Expires in ${_formatDuration(challenge.timeRemaining)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
                _buildDifficultyChip(challenge.difficulty),
              ],
            ),
            if (challenge.message != null && challenge.message!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.message_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        challenge.message!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _declineChallenge(challenge.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptChallenge(challenge.id),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 100 * index), duration: 400.ms)
        .slideX(begin: 0.2, end: 0);
  }

  Widget _buildActiveChallengeCard(Challenge challenge, int index) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.id ?? '';
    final isChallenger = challenge.isChallenger(currentUserId);
    final hasCompleted = challenge.hasUserCompleted(currentUserId);
    final opponentName = challenge.getOpponentName(currentUserId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: hasCompleted
            ? null
            : () => _playChallenge(challenge),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                    child: Text(
                      opponentName.isNotEmpty
                          ? opponentName[0].toUpperCase()
                          : '?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'vs $opponentName',
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          isChallenger ? 'You challenged them' : 'They challenged you',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildGameTypeBadge(challenge.gameType),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildDifficultyChip(challenge.difficulty),
                  const Spacer(),
                  if (hasCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_rounded,
                              size: 16, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            'Waiting for opponent',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () => _playChallenge(challenge),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text('Play'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 100 * index), duration: 400.ms)
        .slideX(begin: 0.2, end: 0);
  }

  Widget _buildCompletedChallengeCard(Challenge challenge, int index) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.id ?? '';
    final didWin = challenge.didUserWin(currentUserId);
    final isTie = challenge.isTie;
    final opponentName = challenge.getOpponentName(currentUserId);
    final dateFormat = DateFormat('MMM d, yyyy');

    Color resultColor;
    String resultText;
    IconData resultIcon;

    if (isTie) {
      resultColor = Colors.orange;
      resultText = 'Tie';
      resultIcon = Icons.horizontal_rule_rounded;
    } else if (didWin) {
      resultColor = Colors.green;
      resultText = 'Won';
      resultIcon = Icons.emoji_events_rounded;
    } else {
      resultColor = Colors.red;
      resultText = 'Lost';
      resultIcon = Icons.trending_down_rounded;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: resultColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(resultIcon, color: resultColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'vs $opponentName',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildGameTypeBadge(challenge.gameType, small: true),
                      const SizedBox(width: 8),
                      Text(
                        dateFormat.format(challenge.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: resultColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                resultText,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: resultColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 100 * index), duration: 400.ms)
        .slideX(begin: 0.2, end: 0);
  }

  Widget _buildGameTypeBadge(GameType gameType, {bool small = false}) {
    final theme = Theme.of(context);
    IconData icon;
    String label;

    switch (gameType) {
      case GameType.sudoku:
        icon = Icons.grid_on_rounded;
        label = 'Sudoku';
        break;
      case GameType.killerSudoku:
        icon = Icons.grid_4x4_rounded;
        label = 'Killer';
        break;
      case GameType.crossword:
        icon = Icons.abc_rounded;
        label = 'Crossword';
        break;
      case GameType.wordSearch:
        icon = Icons.search_rounded;
        label = 'Word Search';
        break;
      case GameType.wordForge:
        icon = Icons.text_fields_rounded;
        label = 'Word Forge';
        break;
      case GameType.nonogram:
        icon = Icons.grid_view_rounded;
        label = 'Nonogram';
        break;
      case GameType.numberTarget:
        icon = Icons.calculate_rounded;
        label = 'Number Target';
        break;
      case GameType.ballSort:
        icon = Icons.sports_baseball_rounded;
        label = 'Ball Sort';
        break;
      case GameType.pipes:
        icon = Icons.plumbing_rounded;
        label = 'Pipes';
        break;
      case GameType.lightsOut:
        icon = Icons.lightbulb_rounded;
        label = 'Lights Out';
        break;
      case GameType.wordLadder:
        icon = Icons.stairs_rounded;
        label = 'Word Ladder';
        break;
      case GameType.connections:
        icon = Icons.hub_rounded;
        label = 'Connections';
        break;
      case GameType.mathora:
        icon = Icons.calculate_outlined;
        label = 'Mathora';
        break;
      case GameType.mobius:
        icon = Icons.all_inclusive;
        label = 'Mobius';
        break;
      case GameType.slidingPuzzle:
        icon = Icons.grid_view_rounded;
        label = 'Sliding';
        break;
      case GameType.memoryMatch:
        icon = Icons.flip_rounded;
        label = 'Memory';
        break;
      case GameType.game2048:
        icon = Icons.grid_4x4_rounded;
        label = '2048';
        break;
      case GameType.simon:
        icon = Icons.music_note_rounded;
        label = 'Simon';
        break;
    }

    if (small) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyChip(Difficulty difficulty) {
    Color color;
    switch (difficulty) {
      case Difficulty.easy:
        color = Colors.green;
        break;
      case Difficulty.medium:
        color = Colors.orange;
        break;
      case Difficulty.hard:
        color = Colors.red;
        break;
      case Difficulty.expert:
        color = Colors.purple;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        difficulty.displayName,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return 'Less than 1m';
    }
  }

  Future<void> _acceptChallenge(String challengeId) async {
    try {
      final challengeService =
          Provider.of<ChallengeService>(context, listen: false);
      await challengeService.acceptChallenge(challengeId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Challenge accepted!')),
        );
        _loadData();
        // Switch to active tab
        _tabController.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept challenge: $e')),
        );
      }
    }
  }

  Future<void> _declineChallenge(String challengeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Challenge'),
        content: const Text('Are you sure you want to decline this challenge?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final challengeService =
            Provider.of<ChallengeService>(context, listen: false);
        await challengeService.declineChallenge(challengeId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Challenge declined')),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to decline challenge: $e')),
          );
        }
      }
    }
  }

  void _playChallenge(Challenge challenge) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          puzzleId: challenge.puzzleId,
          challengeId: challenge.id,
        ),
      ),
    ).then((_) => _loadData());
  }
}
