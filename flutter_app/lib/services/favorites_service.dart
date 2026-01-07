import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_models.dart';

/// Service for managing favorite game types and play counts
class FavoritesService {
  static const String _favoritesKey = 'favorite_games';
  static const String _playCountsKey = 'game_play_counts';

  /// Get all favorite game types
  static Future<Set<GameType>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteNames = prefs.getStringList(_favoritesKey) ?? [];
    return favoriteNames
        .map((name) {
          try {
            return GameType.values.firstWhere((gt) => gt.name == name);
          } catch (_) {
            return null;
          }
        })
        .whereType<GameType>()
        .toSet();
  }

  /// Check if a game type is a favorite
  static Future<bool> isFavorite(GameType gameType) async {
    final favorites = await getFavorites();
    return favorites.contains(gameType);
  }

  /// Add a game type to favorites
  static Future<void> addFavorite(GameType gameType) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    favorites.add(gameType);
    await prefs.setStringList(
      _favoritesKey,
      favorites.map((gt) => gt.name).toList(),
    );
  }

  /// Remove a game type from favorites
  static Future<void> removeFavorite(GameType gameType) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    favorites.remove(gameType);
    await prefs.setStringList(
      _favoritesKey,
      favorites.map((gt) => gt.name).toList(),
    );
  }

  /// Toggle favorite status for a game type
  static Future<bool> toggleFavorite(GameType gameType) async {
    final isFav = await isFavorite(gameType);
    if (isFav) {
      await removeFavorite(gameType);
      return false;
    } else {
      await addFavorite(gameType);
      return true;
    }
  }

  /// Sort puzzles with favorites first
  static List<DailyPuzzle> sortByFavorites(
    List<DailyPuzzle> puzzles,
    Set<GameType> favorites,
  ) {
    if (favorites.isEmpty) return puzzles;

    final favoriteList = <DailyPuzzle>[];
    final otherList = <DailyPuzzle>[];

    for (final puzzle in puzzles) {
      if (favorites.contains(puzzle.gameType)) {
        favoriteList.add(puzzle);
      } else {
        otherList.add(puzzle);
      }
    }

    return [...favoriteList, ...otherList];
  }

  /// Get play counts for all games
  static Future<Map<GameType, int>> getPlayCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final countsJson = prefs.getString(_playCountsKey);
    if (countsJson == null) return {};

    final Map<GameType, int> counts = {};
    final parts = countsJson.split(',');
    for (final part in parts) {
      if (part.isEmpty) continue;
      final kv = part.split(':');
      if (kv.length == 2) {
        try {
          final gameType = GameType.values.firstWhere((gt) => gt.name == kv[0]);
          counts[gameType] = int.tryParse(kv[1]) ?? 0;
        } catch (_) {
          // Skip invalid entries
        }
      }
    }
    return counts;
  }

  /// Increment play count for a game type
  static Future<void> incrementPlayCount(GameType gameType) async {
    final prefs = await SharedPreferences.getInstance();
    final counts = await getPlayCounts();
    counts[gameType] = (counts[gameType] ?? 0) + 1;

    // Serialize to string
    final serialized = counts.entries
        .map((e) => '${e.key.name}:${e.value}')
        .join(',');
    await prefs.setString(_playCountsKey, serialized);
  }

  /// Get the most played game type from a list
  static GameType? getMostPlayed(
    List<DailyPuzzle> puzzles,
    Map<GameType, int> playCounts,
  ) {
    if (puzzles.isEmpty) return null;
    if (playCounts.isEmpty) return puzzles.first.gameType;

    GameType? mostPlayed;
    int maxCount = 0;

    for (final puzzle in puzzles) {
      final count = playCounts[puzzle.gameType] ?? 0;
      if (count > maxCount) {
        maxCount = count;
        mostPlayed = puzzle.gameType;
      }
    }

    return mostPlayed ?? puzzles.first.gameType;
  }
}
