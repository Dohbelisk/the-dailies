import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_models.dart';

/// Service for persisting game state to local storage
class GameStateService {
  static const String _stateKeyPrefix = 'game_state_';
  static const String _completedKeyPrefix = 'completed_';

  /// Generate a unique key for a puzzle based on game type and date
  /// Normalizes to local date to avoid timezone mismatches
  static String _getPuzzleKey(GameType gameType, DateTime date) {
    // Convert to local and strip time to ensure consistent keys
    final localDate = date.toLocal();
    final dateStr = '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';
    return '${gameType.name}_$dateStr';
  }

  /// Save game state for a specific puzzle
  static Future<void> saveGameState({
    required GameType gameType,
    required DateTime puzzleDate,
    required Map<String, dynamic> state,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_stateKeyPrefix${_getPuzzleKey(gameType, puzzleDate)}';
    await prefs.setString(key, jsonEncode(state));
  }

  /// Load game state for a specific puzzle
  static Future<Map<String, dynamic>?> loadGameState({
    required GameType gameType,
    required DateTime puzzleDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_stateKeyPrefix${_getPuzzleKey(gameType, puzzleDate)}';
    final stateJson = prefs.getString(key);
    if (stateJson != null) {
      return jsonDecode(stateJson) as Map<String, dynamic>;
    }
    return null;
  }

  /// Clear game state for a specific puzzle
  static Future<void> clearGameState({
    required GameType gameType,
    required DateTime puzzleDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_stateKeyPrefix${_getPuzzleKey(gameType, puzzleDate)}';
    await prefs.remove(key);
  }

  /// Mark a puzzle as completed
  static Future<void> markCompleted({
    required GameType gameType,
    required DateTime puzzleDate,
    required int elapsedSeconds,
    required int score,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_completedKeyPrefix${_getPuzzleKey(gameType, puzzleDate)}';
    await prefs.setString(key, jsonEncode({
      'completedAt': DateTime.now().toIso8601String(),
      'elapsedSeconds': elapsedSeconds,
      'score': score,
    }));

    // Clear the game state since it's completed
    await clearGameState(gameType: gameType, puzzleDate: puzzleDate);
  }

  /// Check if a puzzle is completed
  static Future<Map<String, dynamic>?> getCompletionStatus({
    required GameType gameType,
    required DateTime puzzleDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_completedKeyPrefix${_getPuzzleKey(gameType, puzzleDate)}';
    final completionJson = prefs.getString(key);
    if (completionJson != null) {
      return jsonDecode(completionJson) as Map<String, dynamic>;
    }
    return null;
  }

  /// Check if there's saved state for a puzzle (in progress)
  static Future<bool> hasInProgressState({
    required GameType gameType,
    required DateTime puzzleDate,
  }) async {
    final state = await loadGameState(gameType: gameType, puzzleDate: puzzleDate);
    return state != null;
  }

  /// Get all completion statuses for a specific date (for home screen)
  static Future<Map<GameType, Map<String, dynamic>>> getCompletionsForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final completions = <GameType, Map<String, dynamic>>{};

    for (final gameType in GameType.values) {
      final key = '$_completedKeyPrefix${_getPuzzleKey(gameType, date)}';
      final completionJson = prefs.getString(key);
      if (completionJson != null) {
        completions[gameType] = jsonDecode(completionJson) as Map<String, dynamic>;
      }
    }

    return completions;
  }

  /// Get in-progress status for all puzzles on a date (for home screen)
  static Future<Map<GameType, bool>> getInProgressForDate(DateTime date) async {
    final inProgress = <GameType, bool>{};

    for (final gameType in GameType.values) {
      inProgress[gameType] = await hasInProgressState(
        gameType: gameType,
        puzzleDate: date,
      );
    }

    return inProgress;
  }
}
