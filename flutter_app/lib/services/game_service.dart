import '../models/game_models.dart';
import 'api_service.dart';

class GameService {
  final ApiService _apiService;

  GameService(this._apiService);

  Future<List<DailyPuzzle>> getTodaysPuzzles() {
    return _apiService.getTodaysPuzzles();
  }

  Future<List<DailyPuzzle>> getPuzzlesForDate(DateTime date) {
    return _apiService.getPuzzlesForDate(date);
  }

  Future<DailyPuzzle?> getPuzzleByTypeAndDate(GameType type, DateTime date) {
    return _apiService.getPuzzleByTypeAndDate(type, date);
  }

  // Get puzzle by type and date string (YYYY-MM-DD format)
  Future<DailyPuzzle?> getPuzzleByDate(GameType type, String dateStr) async {
    try {
      final date = DateTime.parse(dateStr);
      return await getPuzzleByTypeAndDate(type, date);
    } catch (e) {
      print('Error parsing date $dateStr: $e');
      return null;
    }
  }

  Future<bool> submitScore(String puzzleId, int time, int score) {
    return _apiService.submitScore(puzzleId, time, score);
  }

  Future<UserStats> getUserStats() {
    return _apiService.getUserStats();
  }

  // Parse puzzle data into specific puzzle types
  SudokuPuzzle parseSudokuPuzzle(DailyPuzzle puzzle) {
    return SudokuPuzzle.fromJson(puzzle.puzzleData as Map<String, dynamic>);
  }

  KillerSudokuPuzzle parseKillerSudokuPuzzle(DailyPuzzle puzzle) {
    return KillerSudokuPuzzle.fromJson(puzzle.puzzleData as Map<String, dynamic>);
  }

  CrosswordPuzzle parseCrosswordPuzzle(DailyPuzzle puzzle) {
    return CrosswordPuzzle.fromJson(puzzle.puzzleData as Map<String, dynamic>);
  }

  WordSearchPuzzle parseWordSearchPuzzle(DailyPuzzle puzzle) {
    return WordSearchPuzzle.fromJson(puzzle.puzzleData as Map<String, dynamic>);
  }
}
