import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/game_models.dart';
import '../services/game_service.dart';
import '../services/auth_service.dart';
import '../services/consent_service.dart';
import '../services/game_state_service.dart';
import '../services/favorites_service.dart';
import '../services/remote_config_service.dart';
import '../providers/theme_provider.dart';
import '../widgets/puzzle_card.dart';
import '../widgets/animated_background.dart';
import '../widgets/token_balance_widget.dart';
import '../widgets/consent_dialog.dart';
import 'game_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';
import 'archive_screen.dart';
import 'auth/login_screen.dart';
import 'friends/friends_screen.dart';
import 'challenges/challenges_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late Future<List<DailyPuzzle>> _puzzlesFuture;
  late AnimationController _headerController;
  bool _consentChecked = false;
  Map<GameType, Map<String, dynamic>> _completions = {};
  Map<GameType, bool> _inProgress = {};
  Set<GameType> _favorites = {};

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
    _loadPuzzles();
    _checkConsent();
  }

  Future<void> _checkConsent() async {
    // Wait for the widget to be fully built
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_consentChecked) return;
      _consentChecked = true;

      final consentService = ConsentService();
      await consentService.initialize();

      if (consentService.needsConsent && mounted) {
        ConsentDialog.show(
          context,
          onConsentGiven: () {
            // Consent has been given, app can continue normally
            setState(() {});
          },
        );
      }
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  void _loadPuzzles() {
    final gameService = Provider.of<GameService>(context, listen: false);
    _puzzlesFuture = gameService.getTodaysPuzzles();
    _loadPuzzleStatuses();
    _loadFavorites();
  }

  Future<void> _loadPuzzleStatuses() async {
    final today = DateTime.now();
    final completions = await GameStateService.getCompletionsForDate(today);
    final inProgress = await GameStateService.getInProgressForDate(today);
    if (mounted) {
      setState(() {
        _completions = completions;
        _inProgress = inProgress;
      });
    }
  }

  Future<void> _loadFavorites() async {
    final favorites = await FavoritesService.getFavorites();
    if (mounted) {
      setState(() {
        _favorites = favorites;
      });
    }
  }

  Future<void> _toggleFavorite(GameType gameType) async {
    final isFav = await FavoritesService.toggleFavorite(gameType);
    if (mounted) {
      setState(() {
        if (isFav) {
          _favorites.add(gameType);
        } else {
          _favorites.remove(gameType);
        }
      });
    }
  }

  void _handleFriendsPressed() {
    final authService = Provider.of<AuthService>(context, listen: false);

    if (!authService.isAuthenticated) {
      // Show login screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    } else {
      // Navigate to friends screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const FriendsScreen(),
        ),
      ).then((_) => setState(() {}));
    }
  }

  void _handleChallengesPressed() {
    final authService = Provider.of<AuthService>(context, listen: false);

    if (!authService.isAuthenticated) {
      // Show login screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    } else {
      // Navigate to challenges screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ChallengesScreen(),
        ),
      ).then((_) => setState(() {}));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final today = DateTime.now();
    final dateFormat = DateFormat('EEEE, MMMM d');

    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          AnimatedBackground(isDark: themeProvider.isDarkMode),

          // Content
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top bar - Date and token
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dateFormat.format(today),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TokenBalanceWidget(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ArchiveScreen(),
                                    ),
                                  ).then((_) => setState(() {})),
                                ),
                              ],
                            ).animate(controller: _headerController)
                              .fadeIn(duration: 600.ms)
                              .slideX(begin: -0.2, end: 0),
                            // Settings and theme only on top row
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    themeProvider.isDarkMode
                                        ? Icons.light_mode_rounded
                                        : Icons.dark_mode_rounded,
                                    size: 22,
                                  ),
                                  onPressed: () => themeProvider.toggleTheme(),
                                ).animate(controller: _headerController)
                                  .fadeIn(delay: 100.ms, duration: 400.ms)
                                  .scale(begin: const Offset(0.5, 0.5)),
                                IconButton(
                                  icon: const Icon(Icons.settings_rounded, size: 22),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SettingsScreen(),
                                    ),
                                  ),
                                ).animate(controller: _headerController)
                                  .fadeIn(delay: 150.ms, duration: 400.ms)
                                  .scale(begin: const Offset(0.5, 0.5)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Secondary action row
                        Row(
                          children: [
                            _buildActionChip(
                              icon: Icons.people_outline_rounded,
                              label: 'Friends',
                              onTap: _handleFriendsPressed,
                              theme: theme,
                            ).animate(controller: _headerController)
                              .fadeIn(delay: 200.ms, duration: 400.ms)
                              .slideX(begin: -0.1, end: 0),
                            const SizedBox(width: 8),
                            _buildActionChip(
                              icon: Icons.emoji_events_outlined,
                              label: 'Challenges',
                              onTap: _handleChallengesPressed,
                              theme: theme,
                            ).animate(controller: _headerController)
                              .fadeIn(delay: 250.ms, duration: 400.ms)
                              .slideX(begin: -0.1, end: 0),
                            const SizedBox(width: 8),
                            _buildActionChip(
                              icon: Icons.history_rounded,
                              label: 'Archive',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ArchiveScreen(),
                                ),
                              ).then((_) => setState(() {})),
                              theme: theme,
                            ).animate(controller: _headerController)
                              .fadeIn(delay: 300.ms, duration: 400.ms)
                              .slideX(begin: -0.1, end: 0),
                            const SizedBox(width: 8),
                            _buildActionChip(
                              icon: Icons.bar_chart_rounded,
                              label: 'Stats',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const StatsScreen(),
                                ),
                              ),
                              theme: theme,
                            ).animate(controller: _headerController)
                              .fadeIn(delay: 350.ms, duration: 400.ms)
                              .slideX(begin: -0.1, end: 0),
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        // Title
                        Text(
                          'Daily',
                          style: theme.textTheme.displayLarge?.copyWith(
                            height: 1.0,
                          ),
                        ).animate(controller: _headerController)
                          .fadeIn(delay: 100.ms, duration: 600.ms)
                          .slideY(begin: 0.3, end: 0),
                        Text(
                          'Puzzles',
                          style: theme.textTheme.displayLarge?.copyWith(
                            height: 1.0,
                            color: theme.colorScheme.primary,
                          ),
                        ).animate(controller: _headerController)
                          .fadeIn(delay: 200.ms, duration: 600.ms)
                          .slideY(begin: 0.3, end: 0),
                        const SizedBox(height: 8),
                        Text(
                          'Challenge yourself with new puzzles every day',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onBackground.withOpacity(0.6),
                          ),
                        ).animate(controller: _headerController)
                          .fadeIn(delay: 300.ms, duration: 600.ms),
                      ],
                    ),
                  ),
                ),

                // Puzzles grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: FutureBuilder<List<DailyPuzzle>>(
                    future: _puzzlesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(48),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return SliverToBoxAdapter(
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  size: 48,
                                  color: theme.colorScheme.error,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Failed to load puzzles',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _loadPuzzles();
                                    });
                                  },
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      var rawPuzzles = snapshot.data ?? [];
                      // Filter out inactive puzzles unless feature flag is enabled
                      final showInactive = RemoteConfigService().isFeatureEnabled('display_inactive_games');
                      if (!showInactive) {
                        rawPuzzles = rawPuzzles.where((p) => p.isActive).toList();
                      }
                      // Sort puzzles with favorites first
                      final puzzles = FavoritesService.sortByFavorites(rawPuzzles, _favorites);

                      return SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.1,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final puzzle = puzzles[index];
                            final isCompleted = _completions.containsKey(puzzle.gameType);
                            final isInProgress = _inProgress[puzzle.gameType] ?? false;
                            final isFavorite = _favorites.contains(puzzle.gameType);
                            return PuzzleCard(
                              puzzle: puzzle,
                              onTap: () => _openPuzzle(context, puzzle),
                              isCompleted: isCompleted,
                              isInProgress: isInProgress && !isCompleted,
                              isFavorite: isFavorite,
                              onFavoriteToggle: () => _toggleFavorite(puzzle.gameType),
                            ).animate()
                              .fadeIn(
                                delay: Duration(milliseconds: 400 + index * 100),
                                duration: 500.ms,
                              )
                              .slideY(begin: 0.2, end: 0);
                          },
                          childCount: puzzles.length,
                        ),
                      );
                    },
                  ),
                ),

                // Bottom spacing
                const SliverToBoxAdapter(
                  child: SizedBox(height: 32),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPuzzle(BuildContext context, DailyPuzzle puzzle) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return GameScreen(puzzle: puzzle);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    ).then((_) {
      // Reload puzzle statuses when returning from game
      _loadPuzzleStatuses();
    });
  }
}
