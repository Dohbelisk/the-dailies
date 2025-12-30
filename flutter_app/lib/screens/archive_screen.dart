import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/game_models.dart';
import '../services/game_service.dart';
import '../services/token_service.dart';
import '../widgets/token_balance_widget.dart';
import '../widgets/puzzle_card.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  final TokenService _tokenService = TokenService();
  DateTime _selectedDate = DateTime.now().subtract(const Duration(days: 1));
  List<DailyPuzzle>? _puzzles;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPuzzlesForDate(_selectedDate);
  }

  Future<void> _loadPuzzlesForDate(DateTime date) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final gameService = Provider.of<GameService>(context, listen: false);
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      // Fetch puzzles for all game types for the selected date
      final puzzlesList = <DailyPuzzle>[];

      for (final gameType in GameType.values) {
        try {
          final puzzle = await gameService.getPuzzleByDate(gameType, dateStr);
          if (puzzle != null) {
            puzzlesList.add(puzzle);
          }
        } catch (e) {
          print('Failed to load ${gameType.displayName} for $dateStr: $e');
        }
      }

      setState(() {
        _puzzles = puzzlesList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load puzzles: $e';
        _isLoading = false;
      });
    }
  }

  void _changeDate(int days) {
    final newDate = _selectedDate.add(Duration(days: days));
    final today = DateTime.now();

    // Can't go into the future or today (archive is for past dates)
    if (newDate.isAfter(today.subtract(const Duration(days: 1)))) {
      return;
    }

    setState(() {
      _selectedDate = newDate;
    });
    _loadPuzzlesForDate(newDate);
  }

  void _showGetTokensDialog() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.toll_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Get Tokens'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You need tokens to play archive puzzles!',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            _buildTokenOption(
              context,
              icon: Icons.play_circle_outline,
              title: 'Watch Video',
              subtitle: const Text('Get 5 tokens'),
              color: Colors.green,
              onTap: () async {
                Navigator.pop(context);
                await _watchVideoForTokens();
              },
            ),
            const SizedBox(height: 12),
            _buildTokenOption(
              context,
              icon: Icons.calendar_today,
              title: 'Daily Free Token',
              subtitle: FutureBuilder<String>(
                future: _tokenService.getNextDailyTokenTime(),
                builder: (context, snapshot) {
                  return Text(snapshot.data ?? 'Loading...');
                },
              ),
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildTokenOption(
              context,
              icon: Icons.workspace_premium,
              title: 'Go Premium',
              subtitle: const Text('Unlimited access to all puzzles'),
              color: Colors.amber,
              onTap: () {
                Navigator.pop(context);
                // Navigate to settings screen for premium purchase
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle is Text)
                      subtitle
                    else
                      subtitle,
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _watchVideoForTokens() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    bool success = await _tokenService.watchAdForTokens();

    if (mounted) Navigator.pop(context);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('You got 5 tokens! (${_tokenService.availableTokens} total)'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      setState(() {}); // Refresh to update token count
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Failed to load ad. Please try again.'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openPuzzle(DailyPuzzle puzzle) async {
    final theme = Theme.of(context);
    final cost = TokenService.getTokenCost(puzzle.difficulty.name);
    final canAccess = _tokenService.canAccessPuzzle(
      puzzle.difficulty.name,
      isTodaysPuzzle: false,
    );

    if (!canAccess) {
      // Show dialog explaining tokens needed
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.lock_outline, color: theme.colorScheme.error),
              const SizedBox(width: 12),
              const Text('Tokens Required'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This ${puzzle.difficulty.name} puzzle costs $cost token${cost > 1 ? 's' : ''}.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'You have ${_tokenService.availableTokens} token${_tokenService.availableTokens != 1 ? 's' : ''}.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.toll_rounded),
              label: const Text('Get Tokens'),
              onPressed: () {
                Navigator.pop(context);
                _showGetTokensDialog();
              },
            ),
          ],
        ),
      );
      return;
    }

    // Spend tokens if not premium
    if (!_tokenService.isPremium) {
      bool spent = await _tokenService.spendTokens(puzzle.difficulty.name);
      if (!spent) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to spend tokens'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      setState(() {}); // Refresh to update token count
    }

    // Open the puzzle
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GameScreen(puzzle: puzzle),
        ),
      ).then((_) => setState(() {})); // Refresh when returning
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Puzzle Archive'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: TokenBalanceWidget(
                onTap: _showGetTokensDialog,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Date selector
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surface,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeDate(-1),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        dateFormat.format(_selectedDate),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        '${DateTime.now().difference(_selectedDate).inDays} days ago',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.chevron_right,
                    color: _selectedDate.isAfter(
                      DateTime.now().subtract(const Duration(days: 2)),
                    )
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                        : null,
                  ),
                  onPressed: () => _changeDate(1),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),

          // Token cost info
          if (!_tokenService.isPremium)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Easy: 1 token • Medium: 2 tokens • Hard: 3 tokens',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

          // Puzzles grid
          Expanded(
            child: _buildPuzzlesContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildPuzzlesContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadPuzzlesForDate(_selectedDate),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_puzzles == null || _puzzles!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No puzzles found for this date',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _puzzles!.length,
      itemBuilder: (context, index) {
        final puzzle = _puzzles![index];
        final cost = TokenService.getTokenCost(puzzle.difficulty.name);
        final canAccess = _tokenService.canAccessPuzzle(
          puzzle.difficulty.name,
          isTodaysPuzzle: false,
        );

        return Stack(
          children: [
            PuzzleCard(
              puzzle: puzzle,
              onTap: () => _openPuzzle(puzzle),
              isLocked: !canAccess,
            ),
            if (!_tokenService.isPremium && !canAccess)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.toll_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '$cost',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ).animate().fadeIn(
              delay: Duration(milliseconds: 300 + index * 100),
              duration: 500.ms,
            ).slideY(begin: 0.2, end: 0);
      },
    );
  }
}
