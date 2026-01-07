import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement_models.dart';
import '../models/game_models.dart';

/// Service for tracking and managing user achievements.
class AchievementsService extends ChangeNotifier {
  static final AchievementsService _instance = AchievementsService._internal();
  factory AchievementsService() => _instance;
  AchievementsService._internal();

  static const String _progressKey = 'achievement_progress';
  static const String _statsKey = 'achievement_stats';

  bool _initialized = false;
  Map<AchievementType, AchievementProgress> _progress = {};
  AchievementStats _stats = AchievementStats();

  bool get isInitialized => _initialized;
  List<AchievementProgress> get allProgress => _progress.values.toList();
  AchievementStats get stats => _stats;

  /// Initialize the service and load saved progress.
  Future<void> initialize() async {
    if (_initialized) return;

    await _loadProgress();
    await _loadStats();
    _initialized = true;

    if (kDebugMode) {
      print('AchievementsService: Initialized with ${_progress.length} achievements');
    }
  }

  /// Load progress from SharedPreferences.
  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_progressKey);

    if (json != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(json);
        _progress = {};
        for (final entry in data.entries) {
          final progress = AchievementProgress.fromJson(entry.value);
          _progress[progress.type] = progress;
        }
      } catch (e) {
        debugPrint('AchievementsService: Error loading progress - $e');
      }
    }

    // Initialize any missing achievements with empty progress
    for (final type in AchievementType.values) {
      _progress.putIfAbsent(type, () => AchievementProgress(type: type));
    }
  }

  /// Save progress to SharedPreferences.
  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> data = {};
    for (final entry in _progress.entries) {
      data[entry.key.name] = entry.value.toJson();
    }
    await prefs.setString(_progressKey, jsonEncode(data));
  }

  /// Load stats from SharedPreferences.
  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_statsKey);

    if (json != null) {
      try {
        _stats = AchievementStats.fromJson(jsonDecode(json));
      } catch (e) {
        debugPrint('AchievementsService: Error loading stats - $e');
      }
    }
  }

  /// Save stats to SharedPreferences.
  Future<void> _saveStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statsKey, jsonEncode(_stats.toJson()));
  }

  /// Get progress for a specific achievement.
  AchievementProgress getProgress(AchievementType type) {
    return _progress[type] ?? AchievementProgress(type: type);
  }

  /// Get all unlocked achievements.
  List<AchievementProgress> getUnlockedAchievements() {
    return _progress.values.where((p) => p.isUnlocked).toList()
      ..sort((a, b) => (b.unlockedAt ?? DateTime(0))
          .compareTo(a.unlockedAt ?? DateTime(0)));
  }

  /// Get achievements by category.
  List<AchievementProgress> getByCategory(AchievementCategory category) {
    return _progress.values
        .where((p) => p.type.category == category)
        .toList();
  }

  /// Get newly unlocked achievements (not yet viewed).
  List<AchievementProgress> getNewAchievements() {
    return _progress.values.where((p) => p.isNew).toList();
  }

  /// Mark achievements as viewed.
  Future<void> markAchievementsAsViewed() async {
    bool changed = false;
    for (final type in _progress.keys.toList()) {
      if (_progress[type]?.isNew == true) {
        _progress[type] = _progress[type]!.copyWith(isNew: false);
        changed = true;
      }
    }
    if (changed) {
      await _saveProgress();
      notifyListeners();
    }
  }

  /// Get the summary of achievement progress.
  AchievementsSummary getSummary() {
    final unlocked = _progress.values.where((p) => p.isUnlocked).toList();
    final totalXp = unlocked.fold<int>(
      0,
      (sum, p) => sum + p.type.rarity.xpReward,
    );
    final newCount = _progress.values.where((p) => p.isNew).length;
    final recentUnlocks = unlocked
      ..sort((a, b) => (b.unlockedAt ?? DateTime(0))
          .compareTo(a.unlockedAt ?? DateTime(0)));

    return AchievementsSummary(
      totalUnlocked: unlocked.length,
      totalAchievements: AchievementType.values.length,
      totalXp: totalXp,
      newUnlockedCount: newCount,
      recentUnlocks: recentUnlocks.take(5).toList(),
    );
  }

  // ============================================================
  // Achievement Checking Methods
  // ============================================================

  /// Called when a puzzle is completed.
  Future<List<AchievementType>> onPuzzleCompleted({
    required GameType gameType,
    required int score,
    required int timeSeconds,
    required int mistakes,
    required int targetTime,
    required bool isPerfect,
  }) async {
    final unlocked = <AchievementType>[];

    // Update stats
    _stats = _stats.copyWith(
      totalPuzzlesCompleted: _stats.totalPuzzlesCompleted + 1,
      puzzlesByType: Map.from(_stats.puzzlesByType)
        ..update(gameType.name, (v) => v + 1, ifAbsent: () => 1),
    );

    // Track if target time was beat
    if (timeSeconds < targetTime) {
      _stats = _stats.copyWith(
        targetTimesBeat: _stats.targetTimesBeat + 1,
      );
    }

    // Track perfect puzzles
    if (isPerfect) {
      _stats = _stats.copyWith(
        perfectPuzzles: _stats.perfectPuzzles + 1,
        currentPerfectStreak: _stats.currentPerfectStreak + 1,
      );
    } else {
      _stats = _stats.copyWith(currentPerfectStreak: 0);
    }

    await _saveStats();

    // Check first puzzle
    if (_stats.totalPuzzlesCompleted == 1) {
      if (await _unlock(AchievementType.firstPuzzle)) {
        unlocked.add(AchievementType.firstPuzzle);
      }
    }

    // Check first perfect
    if (isPerfect && !getProgress(AchievementType.firstPerfect).isUnlocked) {
      if (await _unlock(AchievementType.firstPerfect)) {
        unlocked.add(AchievementType.firstPerfect);
      }
    }

    // Check completion milestones
    for (final milestone in [
      (10, AchievementType.complete10),
      (50, AchievementType.complete50),
      (100, AchievementType.complete100),
      (500, AchievementType.complete500),
      (1000, AchievementType.complete1000),
    ]) {
      if (await _updateProgress(milestone.$2, _stats.totalPuzzlesCompleted)) {
        unlocked.add(milestone.$2);
      }
    }

    // Check speed achievements
    if (timeSeconds < 60) {
      if (await _unlock(AchievementType.speedDemon)) {
        unlocked.add(AchievementType.speedDemon);
      }
    }
    if (timeSeconds < 30) {
      if (await _unlock(AchievementType.lightningFast)) {
        unlocked.add(AchievementType.lightningFast);
      }
    }

    // Check target time achievements
    for (final milestone in [
      (10, AchievementType.beatTarget10),
      (50, AchievementType.beatTarget50),
    ]) {
      if (await _updateProgress(milestone.$2, _stats.targetTimesBeat)) {
        unlocked.add(milestone.$2);
      }
    }

    // Check perfect score
    if (score >= 10000) {
      if (await _unlock(AchievementType.perfectScore)) {
        unlocked.add(AchievementType.perfectScore);
      }
    }

    // Check perfect streak
    if (await _updateProgress(
        AchievementType.perfectStreak5, _stats.currentPerfectStreak)) {
      unlocked.add(AchievementType.perfectStreak5);
    }

    // Check game-specific achievements
    final gameCount = _stats.puzzlesByType[gameType.name] ?? 0;
    final gameAchievements = {
      GameType.sudoku: AchievementType.sudokuMaster,
      GameType.crossword: AchievementType.crosswordKing,
      GameType.nonogram: AchievementType.nonogramArtist,
    };
    if (gameAchievements.containsKey(gameType)) {
      if (await _updateProgress(gameAchievements[gameType]!, gameCount)) {
        unlocked.add(gameAchievements[gameType]!);
      }
    }

    // Check explorer achievements
    final uniqueGamesPlayed = _stats.puzzlesByType.keys.length;
    if (uniqueGamesPlayed >= GameType.values.length) {
      if (await _unlock(AchievementType.tryAllGames)) {
        unlocked.add(AchievementType.tryAllGames);
      }
    }

    // Check time-based achievements
    final now = DateTime.now();
    if (now.hour < 6) {
      if (await _unlock(AchievementType.earlyBird)) {
        unlocked.add(AchievementType.earlyBird);
      }
    }
    if (now.hour >= 0 && now.hour < 4) {
      if (await _unlock(AchievementType.nightOwl)) {
        unlocked.add(AchievementType.nightOwl);
      }
    }

    notifyListeners();
    return unlocked;
  }

  /// Called when a streak is updated.
  Future<List<AchievementType>> onStreakUpdated(int streakDays) async {
    final unlocked = <AchievementType>[];

    for (final milestone in [
      (3, AchievementType.streak3),
      (7, AchievementType.streak7),
      (30, AchievementType.streak30),
      (100, AchievementType.streak100),
      (365, AchievementType.streak365),
    ]) {
      if (await _updateProgress(milestone.$2, streakDays)) {
        unlocked.add(milestone.$2);
      }
    }

    if (unlocked.isNotEmpty) {
      notifyListeners();
    }
    return unlocked;
  }

  /// Called when all daily puzzles are completed.
  Future<List<AchievementType>> onDailySweep() async {
    final unlocked = <AchievementType>[];

    if (await _unlock(AchievementType.dailySweep)) {
      unlocked.add(AchievementType.dailySweep);
    }

    // Update consecutive daily sweep count
    _stats = _stats.copyWith(
      consecutiveDailySweeps: _stats.consecutiveDailySweeps + 1,
    );
    await _saveStats();

    if (await _updateProgress(
        AchievementType.dailySweep7, _stats.consecutiveDailySweeps)) {
      unlocked.add(AchievementType.dailySweep7);
    }

    if (unlocked.isNotEmpty) {
      notifyListeners();
    }
    return unlocked;
  }

  /// Called when a pangram is found in Word Forge.
  Future<List<AchievementType>> onPangramFound() async {
    final unlocked = <AchievementType>[];

    _stats = _stats.copyWith(pangramsFound: _stats.pangramsFound + 1);
    await _saveStats();

    if (await _updateProgress(
        AchievementType.wordForgeMaster, _stats.pangramsFound)) {
      unlocked.add(AchievementType.wordForgeMaster);
    }

    if (unlocked.isNotEmpty) {
      notifyListeners();
    }
    return unlocked;
  }

  /// Called when a favorite is added.
  Future<List<AchievementType>> onFavoriteAdded() async {
    final unlocked = <AchievementType>[];

    if (await _unlock(AchievementType.firstFavorite)) {
      unlocked.add(AchievementType.firstFavorite);
    }

    if (unlocked.isNotEmpty) {
      notifyListeners();
    }
    return unlocked;
  }

  /// Called when a friend is added.
  Future<List<AchievementType>> onFriendAdded() async {
    final unlocked = <AchievementType>[];

    if (await _unlock(AchievementType.firstFriend)) {
      unlocked.add(AchievementType.firstFriend);
    }

    if (unlocked.isNotEmpty) {
      notifyListeners();
    }
    return unlocked;
  }

  /// Called when a challenge is sent.
  Future<List<AchievementType>> onChallengeSent() async {
    final unlocked = <AchievementType>[];

    if (await _unlock(AchievementType.firstChallenge)) {
      unlocked.add(AchievementType.firstChallenge);
    }

    if (unlocked.isNotEmpty) {
      notifyListeners();
    }
    return unlocked;
  }

  /// Called when a challenge is won.
  Future<List<AchievementType>> onChallengeWon() async {
    final unlocked = <AchievementType>[];

    _stats = _stats.copyWith(challengesWon: _stats.challengesWon + 1);
    await _saveStats();

    if (await _updateProgress(
        AchievementType.winChallenge10, _stats.challengesWon)) {
      unlocked.add(AchievementType.winChallenge10);
    }

    if (unlocked.isNotEmpty) {
      notifyListeners();
    }
    return unlocked;
  }

  // ============================================================
  // Internal Helpers
  // ============================================================

  /// Unlock an achievement if not already unlocked.
  Future<bool> _unlock(AchievementType type) async {
    final current = _progress[type] ?? AchievementProgress(type: type);
    if (current.isUnlocked) return false;

    _progress[type] = current.copyWith(
      isUnlocked: true,
      unlockedAt: DateTime.now(),
      isNew: true,
      currentProgress: type.targetCount ?? 1,
    );

    await _saveProgress();

    if (kDebugMode) {
      print('AchievementsService: Unlocked achievement: ${type.title}');
    }

    return true;
  }

  /// Update progress on a countable achievement.
  Future<bool> _updateProgress(AchievementType type, int newProgress) async {
    final current = _progress[type] ?? AchievementProgress(type: type);
    if (current.isUnlocked) return false;

    final target = type.targetCount ?? 1;
    final shouldUnlock = newProgress >= target;

    _progress[type] = current.copyWith(
      currentProgress: newProgress,
      isUnlocked: shouldUnlock,
      unlockedAt: shouldUnlock ? DateTime.now() : null,
      isNew: shouldUnlock,
    );

    await _saveProgress();

    if (shouldUnlock && kDebugMode) {
      print('AchievementsService: Unlocked achievement: ${type.title}');
    }

    return shouldUnlock;
  }

  /// Reset all achievements (for testing).
  Future<void> resetAll() async {
    _progress = {};
    _stats = AchievementStats();
    for (final type in AchievementType.values) {
      _progress[type] = AchievementProgress(type: type);
    }
    await _saveProgress();
    await _saveStats();
    notifyListeners();
  }
}

/// Internal stats for tracking achievement-related metrics.
class AchievementStats {
  final int totalPuzzlesCompleted;
  final Map<String, int> puzzlesByType;
  final int targetTimesBeat;
  final int perfectPuzzles;
  final int currentPerfectStreak;
  final int consecutiveDailySweeps;
  final int pangramsFound;
  final int challengesWon;

  const AchievementStats({
    this.totalPuzzlesCompleted = 0,
    this.puzzlesByType = const {},
    this.targetTimesBeat = 0,
    this.perfectPuzzles = 0,
    this.currentPerfectStreak = 0,
    this.consecutiveDailySweeps = 0,
    this.pangramsFound = 0,
    this.challengesWon = 0,
  });

  AchievementStats copyWith({
    int? totalPuzzlesCompleted,
    Map<String, int>? puzzlesByType,
    int? targetTimesBeat,
    int? perfectPuzzles,
    int? currentPerfectStreak,
    int? consecutiveDailySweeps,
    int? pangramsFound,
    int? challengesWon,
  }) {
    return AchievementStats(
      totalPuzzlesCompleted:
          totalPuzzlesCompleted ?? this.totalPuzzlesCompleted,
      puzzlesByType: puzzlesByType ?? this.puzzlesByType,
      targetTimesBeat: targetTimesBeat ?? this.targetTimesBeat,
      perfectPuzzles: perfectPuzzles ?? this.perfectPuzzles,
      currentPerfectStreak: currentPerfectStreak ?? this.currentPerfectStreak,
      consecutiveDailySweeps:
          consecutiveDailySweeps ?? this.consecutiveDailySweeps,
      pangramsFound: pangramsFound ?? this.pangramsFound,
      challengesWon: challengesWon ?? this.challengesWon,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalPuzzlesCompleted': totalPuzzlesCompleted,
        'puzzlesByType': puzzlesByType,
        'targetTimesBeat': targetTimesBeat,
        'perfectPuzzles': perfectPuzzles,
        'currentPerfectStreak': currentPerfectStreak,
        'consecutiveDailySweeps': consecutiveDailySweeps,
        'pangramsFound': pangramsFound,
        'challengesWon': challengesWon,
      };

  factory AchievementStats.fromJson(Map<String, dynamic> json) {
    return AchievementStats(
      totalPuzzlesCompleted: json['totalPuzzlesCompleted'] ?? 0,
      puzzlesByType: Map<String, int>.from(json['puzzlesByType'] ?? {}),
      targetTimesBeat: json['targetTimesBeat'] ?? 0,
      perfectPuzzles: json['perfectPuzzles'] ?? 0,
      currentPerfectStreak: json['currentPerfectStreak'] ?? 0,
      consecutiveDailySweeps: json['consecutiveDailySweeps'] ?? 0,
      pangramsFound: json['pangramsFound'] ?? 0,
      challengesWon: json['challengesWon'] ?? 0,
    );
  }
}
