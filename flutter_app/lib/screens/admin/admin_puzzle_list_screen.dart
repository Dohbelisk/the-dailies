import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/game_models.dart';
import 'admin_puzzle_edit_screen.dart';

/// Admin screen to list and manage puzzles for different dates
class AdminPuzzleListScreen extends StatefulWidget {
  const AdminPuzzleListScreen({super.key});

  @override
  State<AdminPuzzleListScreen> createState() => _AdminPuzzleListScreenState();
}

class _AdminPuzzleListScreenState extends State<AdminPuzzleListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService(authService: AuthService());

  DateTime _customDate = DateTime.now().add(const Duration(days: 2));
  bool _isLoadingToday = false;
  bool _isLoadingTomorrow = false;
  bool _isLoadingCustom = false;

  List<DailyPuzzle> _todayPuzzles = [];
  List<DailyPuzzle> _tomorrowPuzzles = [];
  List<DailyPuzzle> _customPuzzles = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTodayPuzzles();
    _loadTomorrowPuzzles();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTodayPuzzles() async {
    setState(() => _isLoadingToday = true);
    try {
      final puzzles = await _apiService.getPuzzlesForDate(DateTime.now());
      setState(() => _todayPuzzles = puzzles);
    } finally {
      setState(() => _isLoadingToday = false);
    }
  }

  Future<void> _loadTomorrowPuzzles() async {
    setState(() => _isLoadingTomorrow = true);
    try {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final puzzles = await _apiService.getPuzzlesForDate(tomorrow);
      setState(() => _tomorrowPuzzles = puzzles);
    } finally {
      setState(() => _isLoadingTomorrow = false);
    }
  }

  Future<void> _loadCustomPuzzles() async {
    setState(() => _isLoadingCustom = true);
    try {
      final puzzles = await _apiService.getPuzzlesForDate(_customDate);
      setState(() => _customPuzzles = puzzles);
    } finally {
      setState(() => _isLoadingCustom = false);
    }
  }

  Future<void> _selectCustomDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _customDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select a date to view puzzles',
    );

    if (selectedDate != null) {
      setState(() => _customDate = selectedDate);
      _loadCustomPuzzles();
    }
  }

  void _openPuzzleEditor(DailyPuzzle puzzle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminPuzzleEditScreen(puzzle: puzzle),
      ),
    ).then((_) {
      // Refresh the list when returning from editor
      final currentTab = _tabController.index;
      if (currentTab == 0) {
        _loadTodayPuzzles();
      } else if (currentTab == 1) {
        _loadTomorrowPuzzles();
      } else {
        _loadCustomPuzzles();
      }
    });
  }

  IconData _getGameTypeIcon(GameType gameType) {
    switch (gameType) {
      case GameType.sudoku:
        return Icons.grid_3x3;
      case GameType.killerSudoku:
        return Icons.grid_4x4;
      case GameType.crossword:
        return Icons.abc;
      case GameType.wordSearch:
        return Icons.search;
      case GameType.wordForge:
        return Icons.hexagon;
      case GameType.nonogram:
        return Icons.apps;
      case GameType.numberTarget:
        return Icons.calculate;
      case GameType.ballSort:
        return Icons.science;
      case GameType.pipes:
        return Icons.linear_scale;
      case GameType.lightsOut:
        return Icons.lightbulb;
      case GameType.wordLadder:
        return Icons.stairs;
      case GameType.connections:
        return Icons.group_work;
      case GameType.mathora:
        return Icons.functions;
    }
  }

  Color _getDifficultyColor(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return Colors.green;
      case Difficulty.medium:
        return Colors.orange;
      case Difficulty.hard:
        return Colors.red;
      case Difficulty.expert:
        return Colors.purple;
    }
  }

  Widget _buildPuzzleList(List<DailyPuzzle> puzzles, bool isLoading, VoidCallback onRefresh) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (puzzles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No puzzles found for this date'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: puzzles.length,
        itemBuilder: (context, index) {
          final puzzle = puzzles[index];
          return _buildPuzzleCard(puzzle);
        },
      ),
    );
  }

  Widget _buildPuzzleCard(DailyPuzzle puzzle) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openPuzzleEditor(puzzle),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Game type icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getGameTypeIcon(puzzle.gameType),
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              // Puzzle info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      puzzle.gameType.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Difficulty badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(puzzle.difficulty).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            puzzle.difficulty.displayName,
                            style: TextStyle(
                              color: _getDifficultyColor(puzzle.difficulty),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: puzzle.isActive
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            puzzle.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: puzzle.isActive ? Colors.green : Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Edit arrow
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Puzzles'),
        backgroundColor: theme.colorScheme.errorContainer,
        foregroundColor: theme.colorScheme.onErrorContainer,
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.onErrorContainer,
          unselectedLabelColor: theme.colorScheme.onErrorContainer.withValues(alpha: 0.6),
          indicatorColor: theme.colorScheme.onErrorContainer,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Tomorrow'),
            Tab(text: 'Custom'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Today tab
          _buildPuzzleList(_todayPuzzles, _isLoadingToday, _loadTodayPuzzles),
          // Tomorrow tab
          _buildPuzzleList(_tomorrowPuzzles, _isLoadingTomorrow, _loadTomorrowPuzzles),
          // Custom date tab
          Column(
            children: [
              // Date picker header
              Container(
                padding: const EdgeInsets.all(16),
                color: theme.colorScheme.surface,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatDate(_customDate),
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _selectCustomDate,
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: const Text('Change Date'),
                    ),
                  ],
                ),
              ),
              // Puzzle list
              Expanded(
                child: _buildPuzzleList(_customPuzzles, _isLoadingCustom, _loadCustomPuzzles),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
