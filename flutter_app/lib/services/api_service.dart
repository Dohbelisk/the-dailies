import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import '../models/game_models.dart';
import '../models/user_models.dart';
import '../models/feedback_models.dart';
import 'auth_service.dart';

class ApiService {
  final AuthService? authService;

  // API URL from environment configuration
  static String get baseUrl => Environment.apiUrl;

  ApiService({this.authService});

  // Get headers with auth token if available
  Map<String, String> _getHeaders() {
    final headers = {'Content-Type': 'application/json'};

    if (authService != null && authService!.token != null) {
      headers['Authorization'] = 'Bearer ${authService!.token}';
    }

    return headers;
  }
  
  Future<List<DailyPuzzle>> getTodaysPuzzles() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/puzzles/today'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => DailyPuzzle.fromJson(json)).toList();
      }
      throw Exception('Failed to load puzzles');
    } catch (e) {
      // Return mock data for development
      return _getMockPuzzles();
    }
  }

  Future<DailyPuzzle?> getPuzzle(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/puzzles/$id'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return DailyPuzzle.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<DailyPuzzle>> getPuzzlesByType(GameType type) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/puzzles/type/${type.apiValue}'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => DailyPuzzle.fromJson(json)).toList();
      }
      throw Exception('Failed to load puzzles');
    } catch (e) {
      return [];
    }
  }

  Future<DailyPuzzle?> getPuzzleByTypeAndDate(GameType type, DateTime date) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final response = await http.get(
        Uri.parse('$baseUrl/puzzles/type/${type.apiValue}/date/$dateStr'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return DailyPuzzle.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      // Return mock data for the specific type
      final puzzles = _getMockPuzzles();
      return puzzles.firstWhere(
        (p) => p.gameType == type,
        orElse: () => puzzles.first,
      );
    }
  }

  Future<bool> submitScore(String puzzleId, int time, int score) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/scores'),
        headers: _getHeaders(),
        body: json.encode({
          'puzzleId': puzzleId,
          'time': time,
          'score': score,
        }),
      );
      
      return response.statusCode == 201;
    } catch (e) {
      return true; // Offline mode - assume success
    }
  }

  Future<UserStats> getUserStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/stats'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return UserStats.fromJson(json.decode(response.body));
      }
      return UserStats.empty();
    } catch (e) {
      return UserStats.empty();
    }
  }

  // ==================== AUTHENTICATION ENDPOINTS ====================

  Future<LoginResult> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final user = User.fromJson(data['user']);
        final token = data['token'] ?? data['access_token'];

        // Set authenticated user in AuthService
        if (authService != null) {
          await authService!.setAuthenticatedUser(token, user);
        }

        return LoginResult.success(user, token);
      } else {
        final data = json.decode(response.body);
        return LoginResult.failure(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      return LoginResult.failure('Login failed: $e');
    }
  }

  Future<RegisterResult> register(
    String email,
    String password,
    String username,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'username': username,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final user = User.fromJson(data['user']);
        final token = data['token'] ?? data['access_token'];

        // Set authenticated user in AuthService
        if (authService != null) {
          await authService!.setAuthenticatedUser(token, user);
        }

        return RegisterResult.success(user, token);
      } else {
        final data = json.decode(response.body);
        return RegisterResult.failure(data['message'] ?? 'Registration failed');
      }
    } catch (e) {
      return RegisterResult.failure('Registration failed: $e');
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error fetching current user: $e');
      return null;
    }
  }

  Future<DailyPuzzle?> getPuzzleByDate(GameType type, String dateStr) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/puzzles/type/${type.apiValue}/date/$dateStr'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return DailyPuzzle.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Error fetching puzzle by date: $e');
      return null;
    }
  }

  // ==================== FEEDBACK ENDPOINTS ====================

  Future<bool> submitFeedback(FeedbackSubmission feedback) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/feedback'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(feedback.toJson()),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error submitting feedback: $e');
      return false;
    }
  }

  // Mock data for development/offline mode
  List<DailyPuzzle> _getMockPuzzles() {
    final today = DateTime.now();
    
    return [
      DailyPuzzle(
        id: 'sudoku-${today.toIso8601String().split('T')[0]}',
        gameType: GameType.sudoku,
        difficulty: Difficulty.medium,
        date: today,
        targetTime: 600,
        puzzleData: {
          'grid': [
            [5, 3, 0, 0, 7, 0, 0, 0, 0],
            [6, 0, 0, 1, 9, 5, 0, 0, 0],
            [0, 9, 8, 0, 0, 0, 0, 6, 0],
            [8, 0, 0, 0, 6, 0, 0, 0, 3],
            [4, 0, 0, 8, 0, 3, 0, 0, 1],
            [7, 0, 0, 0, 2, 0, 0, 0, 6],
            [0, 6, 0, 0, 0, 0, 2, 8, 0],
            [0, 0, 0, 4, 1, 9, 0, 0, 5],
            [0, 0, 0, 0, 8, 0, 0, 7, 9],
          ],
          'solution': [
            [5, 3, 4, 6, 7, 8, 9, 1, 2],
            [6, 7, 2, 1, 9, 5, 3, 4, 8],
            [1, 9, 8, 3, 4, 2, 5, 6, 7],
            [8, 5, 9, 7, 6, 1, 4, 2, 3],
            [4, 2, 6, 8, 5, 3, 7, 9, 1],
            [7, 1, 3, 9, 2, 4, 8, 5, 6],
            [9, 6, 1, 5, 3, 7, 2, 8, 4],
            [2, 8, 7, 4, 1, 9, 6, 3, 5],
            [3, 4, 5, 2, 8, 6, 1, 7, 9],
          ],
        },
      ),
      DailyPuzzle(
        id: 'killer-${today.toIso8601String().split('T')[0]}',
        gameType: GameType.killerSudoku,
        difficulty: Difficulty.hard,
        date: today,
        targetTime: 900,
        puzzleData: {
          'grid': [
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
          ],
          'solution': [
            [5, 3, 4, 6, 7, 8, 9, 1, 2],
            [6, 7, 2, 1, 9, 5, 3, 4, 8],
            [1, 9, 8, 3, 4, 2, 5, 6, 7],
            [8, 5, 9, 7, 6, 1, 4, 2, 3],
            [4, 2, 6, 8, 5, 3, 7, 9, 1],
            [7, 1, 3, 9, 2, 4, 8, 5, 6],
            [9, 6, 1, 5, 3, 7, 2, 8, 4],
            [2, 8, 7, 4, 1, 9, 6, 3, 5],
            [3, 4, 5, 2, 8, 6, 1, 7, 9],
          ],
          'cages': [
            {'sum': 8, 'cells': [[0, 0], [0, 1]]},
            {'sum': 10, 'cells': [[0, 2], [1, 2]]},
            {'sum': 13, 'cells': [[0, 3], [0, 4]]},
            {'sum': 17, 'cells': [[0, 5], [0, 6], [0, 7]]},
            {'sum': 2, 'cells': [[0, 8]]},
            {'sum': 13, 'cells': [[1, 0], [2, 0]]},
            {'sum': 16, 'cells': [[1, 1], [2, 1]]},
            {'sum': 10, 'cells': [[1, 3], [1, 4]]},
            {'sum': 8, 'cells': [[1, 5], [1, 6]]},
            {'sum': 12, 'cells': [[1, 7], [1, 8]]},
            {'sum': 11, 'cells': [[2, 2], [2, 3]]},
            {'sum': 6, 'cells': [[2, 4], [2, 5]]},
            {'sum': 11, 'cells': [[2, 6], [2, 7]]},
            {'sum': 7, 'cells': [[2, 8], [3, 8]]},
          ],
        },
      ),
      DailyPuzzle(
        id: 'crossword-${today.toIso8601String().split('T')[0]}',
        gameType: GameType.crossword,
        difficulty: Difficulty.medium,
        date: today,
        targetTime: 480,
        puzzleData: {
          'rows': 10,
          'cols': 10,
          'grid': [
            ['F', 'L', 'U', 'T', 'T', 'E', 'R', '#', '#', '#'],
            ['L', '#', 'N', '#', 'E', '#', 'E', 'C', 'H', 'O'],
            ['A', 'P', 'I', '#', 'C', 'O', 'D', 'E', '#', 'N'],
            ['S', '#', 'T', 'E', 'H', '#', '#', 'L', '#', 'E'],
            ['H', 'E', 'Y', '#', '#', 'A', 'P', 'L', '#', '#'],
            ['#', '#', '#', 'D', 'A', 'R', 'T', '#', '#', '#'],
            ['#', '#', '#', 'A', '#', 'T', '#', '#', '#', '#'],
            ['#', '#', '#', 'T', 'E', 'S', 'T', '#', '#', '#'],
            ['#', '#', '#', 'A', '#', '#', '#', '#', '#', '#'],
            ['#', '#', '#', '#', '#', '#', '#', '#', '#', '#'],
          ],
          'clues': [
            {'number': 1, 'direction': 'across', 'clue': 'Google\'s UI toolkit for mobile apps', 'answer': 'FLUTTER', 'startRow': 0, 'startCol': 0},
            {'number': 5, 'direction': 'across', 'clue': 'Sound reflection', 'answer': 'ECHO', 'startRow': 1, 'startCol': 6},
            {'number': 6, 'direction': 'across', 'clue': 'Application Programming Interface', 'answer': 'API', 'startRow': 2, 'startCol': 0},
            {'number': 7, 'direction': 'across', 'clue': 'What developers write', 'answer': 'CODE', 'startRow': 2, 'startCol': 4},
            {'number': 8, 'direction': 'across', 'clue': 'Casual greeting', 'answer': 'HEY', 'startRow': 4, 'startCol': 0},
            {'number': 9, 'direction': 'across', 'clue': 'Flutter\'s programming language', 'answer': 'DART', 'startRow': 5, 'startCol': 3},
            {'number': 10, 'direction': 'across', 'clue': 'Quality assurance check', 'answer': 'TEST', 'startRow': 7, 'startCol': 3},
            {'number': 1, 'direction': 'down', 'clue': 'Quick, sudden movement', 'answer': 'FLASH', 'startRow': 0, 'startCol': 0},
            {'number': 2, 'direction': 'down', 'clue': 'Operating system core', 'answer': 'UNITY', 'startRow': 0, 'startCol': 2},
            {'number': 3, 'direction': 'down', 'clue': 'Short for technology', 'answer': 'TECH', 'startRow': 0, 'startCol': 4},
            {'number': 4, 'direction': 'down', 'clue': 'Mobile device screen renderings', 'answer': 'CELL', 'startRow': 1, 'startCol': 7},
            {'number': 5, 'direction': 'down', 'clue': 'A single item', 'answer': 'ONE', 'startRow': 1, 'startCol': 9},
            {'number': 9, 'direction': 'down', 'clue': 'Information collection', 'answer': 'DATA', 'startRow': 5, 'startCol': 3},
            {'number': 11, 'direction': 'down', 'clue': 'Creative or visual ability', 'answer': 'ART', 'startRow': 5, 'startCol': 5},
          ],
        },
      ),
      DailyPuzzle(
        id: 'wordsearch-${today.toIso8601String().split('T')[0]}',
        gameType: GameType.wordSearch,
        difficulty: Difficulty.easy,
        date: today,
        targetTime: 300,
        puzzleData: {
          'rows': 10,
          'cols': 10,
          'theme': 'Programming',
          'grid': [
            ['F', 'L', 'U', 'T', 'T', 'E', 'R', 'X', 'P', 'Q'],
            ['A', 'P', 'I', 'K', 'O', 'T', 'L', 'I', 'N', 'Z'],
            ['D', 'A', 'R', 'T', 'B', 'Y', 'T', 'E', 'S', 'W'],
            ['K', 'R', 'E', 'A', 'C', 'T', 'V', 'U', 'I', 'D'],
            ['C', 'O', 'D', 'E', 'N', 'O', 'D', 'E', 'F', 'G'],
            ['S', 'W', 'I', 'F', 'T', 'P', 'R', 'O', 'G', 'H'],
            ['J', 'A', 'V', 'A', 'M', 'N', 'O', 'P', 'Q', 'R'],
            ['R', 'U', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
            ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'],
            ['K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T'],
          ],
          'words': [
            {'word': 'FLUTTER', 'startRow': 0, 'startCol': 0, 'endRow': 0, 'endCol': 6},
            {'word': 'DART', 'startRow': 2, 'startCol': 0, 'endRow': 2, 'endCol': 3},
            {'word': 'API', 'startRow': 1, 'startCol': 0, 'endRow': 1, 'endCol': 2},
            {'word': 'KOTLIN', 'startRow': 1, 'startCol': 3, 'endRow': 1, 'endCol': 8},
            {'word': 'REACT', 'startRow': 3, 'startCol': 1, 'endRow': 3, 'endCol': 5},
            {'word': 'CODE', 'startRow': 4, 'startCol': 0, 'endRow': 4, 'endCol': 3},
            {'word': 'NODE', 'startRow': 4, 'startCol': 4, 'endRow': 4, 'endCol': 7},
            {'word': 'SWIFT', 'startRow': 5, 'startCol': 0, 'endRow': 5, 'endCol': 4},
            {'word': 'JAVA', 'startRow': 6, 'startCol': 0, 'endRow': 6, 'endCol': 3},
            {'word': 'RUST', 'startRow': 7, 'startCol': 0, 'endRow': 7, 'endCol': 3},
          ],
        },
      ),
    ];
  }
}
