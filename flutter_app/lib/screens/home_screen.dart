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
import '../widgets/animated_background.dart';
import '../widgets/token_balance_widget.dart';
import '../widgets/consent_dialog.dart';
import '../widgets/hero_puzzle_card.dart';
import '../widgets/daily_stats_banner.dart';
import '../widgets/vibrant_puzzle_card.dart';
import 'game_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';
import 'archive_screen.dart';
import 'auth/login_screen.dart';
import 'friends/friends_screen.dart';
import 'challenges/challenges_screen.dart';
import 'achievements_screen.dart';

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
  bool _showFavoritesOnly = false;
  Map<GameType, int> _playCounts = {}; // Track play counts for "most played"
  DateTime? _overrideDate; // Super user date override

  /// Returns the effective date for puzzles (override or today)
  DateTime get _effectiveDate => _overrideDate ?? DateTime.now();

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
    // Use override date if set (super user feature), otherwise get today's puzzles
    if (_overrideDate != null) {
      _puzzlesFuture = gameService.getPuzzlesForDate(_overrideDate!);
    } else {
      _puzzlesFuture = gameService.getTodaysPuzzles();
    }
    _loadPuzzleStatuses();
    _loadFavorites();
    _loadPlayCounts();
  }

  Future<void> _loadPlayCounts() async {
    final playCounts = await FavoritesService.getPlayCounts();
    if (mounted) {
      setState(() {
        _playCounts = playCounts;
      });
    }
  }

  Future<void> _loadPuzzleStatuses() async {
    final date = _effectiveDate;
    final completions = await GameStateService.getCompletionsForDate(date);
    final inProgress = await GameStateService.getInProgressForDate(date);
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

  /// Show date picker for super users to override the displayed date
  Future<void> _showDatePicker() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _overrideDate ?? now,
      firstDate: DateTime(2024, 1, 1),
      lastDate: now.add(const Duration(days: 7)), // Allow up to 7 days in future
      helpText: 'Select date to view puzzles',
    );

    if (picked != null && mounted) {
      setState(() {
        _overrideDate = picked;
        _loadPuzzles();
      });
    }
  }

  /// Clear the date override and return to today
  void _clearDateOverride() {
    setState(() {
      _overrideDate = null;
      _loadPuzzles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final displayDate = _effectiveDate;
    final dateFormat = DateFormat('EEEE, MMMM d');
    final isSuperUser = RemoteConfigService().isSuperAccount;

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
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top bar - Date and actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Date display with optional picker for super users
                                  if (isSuperUser)
                                    GestureDetector(
                                      onTap: _showDatePicker,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            dateFormat.format(displayDate),
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: _overrideDate != null
                                                  ? Colors.amber
                                                  : null,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.calendar_today,
                                            size: 16,
                                            color: _overrideDate != null
                                                ? Colors.amber
                                                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                          ),
                                          if (_overrideDate != null) ...[
                                            const SizedBox(width: 4),
                                            GestureDetector(
                                              onTap: _clearDateOverride,
                                              child: const Icon(
                                                Icons.close,
                                                size: 16,
                                                color: Colors.amber,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    )
                                  else
                                    Text(
                                      dateFormat.format(displayDate),
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: 2),
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
                            ),
                            // Settings, theme, and refresh icons
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (RemoteConfigService().isSuperAccount)
                                  IconButton(
                                    icon: const Icon(Icons.refresh_rounded, size: 22),
                                    tooltip: 'Refresh puzzles',
                                    onPressed: () {
                                      setState(() {
                                        _loadPuzzles();
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Refreshing puzzles...'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                  ).animate(controller: _headerController)
                                    .fadeIn(delay: 50.ms, duration: 400.ms)
                                    .scale(begin: const Offset(0.5, 0.5)),
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
                        const SizedBox(height: 12),
                        // Action chips row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
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
                              const SizedBox(width: 8),
                              _buildActionChip(
                                icon: Icons.emoji_events_rounded,
                                label: 'Badges',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AchievementsScreen(),
                                  ),
                                ),
                                theme: theme,
                              ).animate(controller: _headerController)
                                .fadeIn(delay: 400.ms, duration: 400.ms)
                                .slideX(begin: -0.1, end: 0),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Puzzles content
                FutureBuilder<List<DailyPuzzle>>(
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

                    var allPuzzles = snapshot.data ?? [];
                    // Filter out inactive puzzles unless feature flag is enabled
                    final showInactive = RemoteConfigService().isFeatureEnabled('display_inactive_games');
                    if (!showInactive) {
                      allPuzzles = allPuzzles.where((p) => p.isActive).toList();
                    }

                    if (allPuzzles.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(48),
                          child: Center(
                            child: Text(
                              'No puzzles available today',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                        ),
                      );
                    }

                    // Determine hero puzzle
                    final heroPuzzle = _getHeroPuzzle(allPuzzles);

                    // Filter puzzles based on favorites toggle
                    List<DailyPuzzle> displayPuzzles;
                    if (_showFavoritesOnly && _favorites.isNotEmpty) {
                      displayPuzzles = allPuzzles
                          .where((p) => _favorites.contains(p.gameType))
                          .toList();
                    } else {
                      displayPuzzles = allPuzzles;
                    }

                    // Remove hero from grid (it's shown separately)
                    final gridPuzzles = displayPuzzles
                        .where((p) => p.gameType != heroPuzzle.gameType)
                        .toList();

                    // Calculate completed count
                    final completedCount = allPuzzles
                        .where((p) => _completions.containsKey(p.gameType))
                        .length;

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverMainAxisGroup(
                        slivers: [
                          // Daily Stats Banner
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 20, bottom: 16),
                              child: DailyStatsBanner(
                                completedCount: completedCount,
                                totalCount: allPuzzles.length,
                                streakDays: 0, // TODO: Get actual streak
                              ).animate()
                                .fadeIn(delay: 300.ms, duration: 500.ms)
                                .slideY(begin: 0.1, end: 0),
                            ),
                          ),

                          // Hero Puzzle Card
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: HeroPuzzleCard(
                                puzzle: heroPuzzle,
                                onTap: () => _openPuzzle(context, heroPuzzle),
                                isCompleted: _completions.containsKey(heroPuzzle.gameType),
                                isInProgress: _inProgress[heroPuzzle.gameType] ?? false,
                                completionTime: _completions[heroPuzzle.gameType]?['elapsedSeconds'] as int?,
                                completionScore: _completions[heroPuzzle.gameType]?['score'] as int?,
                              ),
                            ),
                          ),

                          // Filter tabs (All / Favorites)
                          if (_favorites.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildFilterTabs(theme),
                              ),
                            ),

                          // Section title
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Text(
                                    _showFavoritesOnly ? 'Favorites' : 'More Puzzles',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_showFavoritesOnly) ...[
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.favorite_rounded,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                  ],
                                ],
                              ).animate()
                                .fadeIn(delay: 500.ms, duration: 400.ms),
                            ),
                          ),

                          // Magazine-style grid
                          _buildMagazineGrid(gridPuzzles, theme),
                        ],
                      ),
                    );
                  },
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

  /// Determine which puzzle to feature as hero
  DailyPuzzle _getHeroPuzzle(List<DailyPuzzle> puzzles) {
    if (puzzles.isEmpty) {
      throw StateError('No puzzles available');
    }

    // If showing favorites only and favorites exist
    if (_showFavoritesOnly && _favorites.isNotEmpty) {
      final favoritePuzzles = puzzles
          .where((p) => _favorites.contains(p.gameType))
          .toList();
      if (favoritePuzzles.isNotEmpty) {
        // Use most played favorite as hero
        final mostPlayed = FavoritesService.getMostPlayed(favoritePuzzles, _playCounts);
        return favoritePuzzles.firstWhere(
          (p) => p.gameType == mostPlayed,
          orElse: () => favoritePuzzles.first,
        );
      }
    }

    // Default: rotate hero based on day of year
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return puzzles[dayOfYear % puzzles.length];
  }

  Widget _buildFilterTabs(ThemeData theme) {
    return Row(
      children: [
        _buildFilterTab(
          label: 'All',
          isSelected: !_showFavoritesOnly,
          onTap: () => setState(() => _showFavoritesOnly = false),
          theme: theme,
        ),
        const SizedBox(width: 8),
        _buildFilterTab(
          label: 'Favorites',
          isSelected: _showFavoritesOnly,
          onTap: () => setState(() => _showFavoritesOnly = true),
          theme: theme,
          icon: Icons.favorite_rounded,
        ),
      ],
    ).animate()
      .fadeIn(delay: 450.ms, duration: 400.ms);
  }

  Widget _buildFilterTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build magazine-style masonry grid with varied card sizes
  Widget _buildMagazineGrid(List<DailyPuzzle> puzzles, ThemeData theme) {
    if (puzzles.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    // Create magazine layout: alternating large/small cards
    final List<Widget> rows = [];
    int index = 0;

    while (index < puzzles.length) {
      if (index % 3 == 0 && index + 2 < puzzles.length) {
        // Row with one large card on left, two small on right
        rows.add(_buildMagazineRow(
          puzzles: [puzzles[index], puzzles[index + 1], puzzles[index + 2]],
          largeOnLeft: true,
          startIndex: index,
        ));
        index += 3;
      } else if (index % 3 == 0 && index + 1 < puzzles.length) {
        // Two equal cards
        rows.add(_buildTwoCardRow(
          puzzles: [puzzles[index], puzzles[index + 1]],
          startIndex: index,
        ));
        index += 2;
      } else if (index < puzzles.length) {
        // Single card (full width)
        rows.add(_buildSingleCardRow(
          puzzle: puzzles[index],
          startIndex: index,
        ));
        index += 1;
      }
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, rowIndex) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: rows[rowIndex],
        ),
        childCount: rows.length,
      ),
    );
  }

  Widget _buildMagazineRow({
    required List<DailyPuzzle> puzzles,
    required bool largeOnLeft,
    required int startIndex,
  }) {
    final largePuzzle = puzzles[0];
    final smallPuzzles = puzzles.sublist(1);

    return SizedBox(
      height: 220,
      child: Row(
        children: [
          // Large card
          Expanded(
            flex: 3,
            child: _buildVibrantCard(largePuzzle, startIndex, isLarge: true),
          ),
          const SizedBox(width: 12),
          // Two small cards stacked
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: _buildVibrantCard(smallPuzzles[0], startIndex + 1, isLarge: false),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _buildVibrantCard(smallPuzzles[1], startIndex + 2, isLarge: false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTwoCardRow({
    required List<DailyPuzzle> puzzles,
    required int startIndex,
  }) {
    return SizedBox(
      height: 140,
      child: Row(
        children: [
          Expanded(
            child: _buildVibrantCard(puzzles[0], startIndex, isLarge: false),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildVibrantCard(puzzles[1], startIndex + 1, isLarge: false),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleCardRow({
    required DailyPuzzle puzzle,
    required int startIndex,
  }) {
    return SizedBox(
      height: 120,
      child: _buildVibrantCard(puzzle, startIndex, isLarge: false),
    );
  }

  Widget _buildVibrantCard(DailyPuzzle puzzle, int index, {required bool isLarge}) {
    final completionData = _completions[puzzle.gameType];
    final isCompleted = completionData != null;
    final isInProgress = _inProgress[puzzle.gameType] ?? false;
    final isFavorite = _favorites.contains(puzzle.gameType);

    return VibrantPuzzleCard(
      puzzle: puzzle,
      onTap: () => _openPuzzle(context, puzzle),
      isCompleted: isCompleted,
      isInProgress: isInProgress && !isCompleted,
      isFavorite: isFavorite,
      onFavoriteToggle: () => _toggleFavorite(puzzle.gameType),
      completionTime: completionData?['elapsedSeconds'] as int?,
      completionScore: completionData?['score'] as int?,
      isLarge: isLarge,
    ).animate()
      .fadeIn(
        delay: Duration(milliseconds: 500 + index * 80),
        duration: 500.ms,
      )
      .slideY(begin: 0.15, end: 0);
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
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
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
    // Track play count for "most played" feature
    FavoritesService.incrementPlayCount(puzzle.gameType);

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
      _loadPlayCounts();
    });
  }
}
