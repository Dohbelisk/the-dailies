import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_models.dart';

/// Service for managing favorite game types
class FavoritesService {
  static const String _favoritesKey = 'favorite_games';

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
}
