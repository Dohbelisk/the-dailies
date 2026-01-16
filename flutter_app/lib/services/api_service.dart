import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import '../models/game_models.dart';
import '../models/user_models.dart';
import '../models/feedback_models.dart';
import 'auth_service.dart';
import 'logging_service.dart';

class ApiService {
  final AuthService? authService;
  final LoggingService _log = LoggingService();

  // API URL from environment configuration
  static String get baseUrl => Environment.apiUrl;

  ApiService({this.authService});

  // Get headers with auth token and device ID
  Map<String, String> _getHeaders() {
    final headers = {'Content-Type': 'application/json'};

    if (authService != null && authService!.token != null) {
      headers['Authorization'] = 'Bearer ${authService!.token}';
    }

    if (authService != null && authService!.deviceId != null) {
      headers['x-device-id'] = authService!.deviceId!;
    }

    return headers;
  }

  /// Make a GET request with logging
  Future<http.Response> _get(String url, {Map<String, String>? headers}) async {
    final start = DateTime.now();
    final requestHeaders = headers ?? _getHeaders();

    _log.logApiRequest(method: 'GET', url: url, headers: requestHeaders);

    try {
      final response = await http.get(Uri.parse(url), headers: requestHeaders);
      final duration = DateTime.now().difference(start);

      _log.logApiResponse(
        method: 'GET',
        url: url,
        statusCode: response.statusCode,
        body: response.body,
        duration: duration,
      );

      return response;
    } catch (e, stack) {
      _log.logApiError(method: 'GET', url: url, exception: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Make a POST request with logging
  Future<http.Response> _post(String url, {Map<String, String>? headers, dynamic body}) async {
    final start = DateTime.now();
    final requestHeaders = headers ?? _getHeaders();

    _log.logApiRequest(method: 'POST', url: url, headers: requestHeaders, body: body);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: requestHeaders,
        body: body != null ? json.encode(body) : null,
      );
      final duration = DateTime.now().difference(start);

      _log.logApiResponse(
        method: 'POST',
        url: url,
        statusCode: response.statusCode,
        body: response.body,
        duration: duration,
      );

      return response;
    } catch (e, stack) {
      _log.logApiError(method: 'POST', url: url, exception: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Make a PATCH request with logging
  Future<http.Response> _patch(String url, {Map<String, String>? headers, dynamic body}) async {
    final start = DateTime.now();
    final requestHeaders = headers ?? _getHeaders();

    _log.logApiRequest(method: 'PATCH', url: url, headers: requestHeaders, body: body);

    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: requestHeaders,
        body: body != null ? json.encode(body) : null,
      );
      final duration = DateTime.now().difference(start);

      _log.logApiResponse(
        method: 'PATCH',
        url: url,
        statusCode: response.statusCode,
        body: response.body,
        duration: duration,
      );

      return response;
    } catch (e, stack) {
      _log.logApiError(method: 'PATCH', url: url, exception: e, stackTrace: stack);
      rethrow;
    }
  }
  
  Future<List<DailyPuzzle>> getTodaysPuzzles() async {
    try {
      final response = await _get('$baseUrl/puzzles/today');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => DailyPuzzle.fromJson(json)).toList();
      }
      _log.warning('Failed to load today\'s puzzles: ${response.statusCode}', tag: 'Puzzles');
      throw Exception('Failed to load puzzles');
    } catch (e) {
      _log.info('Using mock puzzles due to error: $e', tag: 'Puzzles');
      return _getMockPuzzles();
    }
  }

  Future<DailyPuzzle?> getPuzzle(String id) async {
    try {
      final response = await _get('$baseUrl/puzzles/$id');

      if (response.statusCode == 200) {
        return DailyPuzzle.fromJson(json.decode(response.body));
      }
      _log.warning('Puzzle not found: $id (status: ${response.statusCode})', tag: 'Puzzles');
      return null;
    } catch (e) {
      _log.error('Failed to get puzzle: $id', tag: 'Puzzles', exception: e);
      return null;
    }
  }

  Future<List<DailyPuzzle>> getPuzzlesByType(GameType type) async {
    try {
      final response = await _get('$baseUrl/puzzles/type/${type.apiValue}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => DailyPuzzle.fromJson(json)).toList();
      }
      _log.warning('Failed to load puzzles by type ${type.apiValue}: ${response.statusCode}', tag: 'Puzzles');
      throw Exception('Failed to load puzzles');
    } catch (e) {
      _log.error('Error loading puzzles by type: ${type.apiValue}', tag: 'Puzzles', exception: e);
      return [];
    }
  }

  Future<DailyPuzzle?> getPuzzleByTypeAndDate(GameType type, DateTime date) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final response = await _get('$baseUrl/puzzles/type/${type.apiValue}/date/$dateStr');

      if (response.statusCode == 200) {
        return DailyPuzzle.fromJson(json.decode(response.body));
      }
      _log.debug('Puzzle not found for ${type.apiValue} on $dateStr', tag: 'Puzzles');
      return null;
    } catch (e) {
      _log.info('Using mock puzzle for ${type.apiValue} due to error', tag: 'Puzzles');
      final puzzles = _getMockPuzzles();
      return puzzles.firstWhere(
        (p) => p.gameType == type,
        orElse: () => puzzles.first,
      );
    }
  }

  /// Fetch all puzzles for a specific date (used by super accounts for testing future puzzles)
  Future<List<DailyPuzzle>> getPuzzlesForDate(DateTime date) async {
    final puzzles = <DailyPuzzle>[];

    // Fetch puzzles for each game type
    for (final gameType in GameType.values) {
      final puzzle = await getPuzzleByTypeAndDate(gameType, date);
      if (puzzle != null) {
        puzzles.add(puzzle);
      }
    }

    return puzzles;
  }

  Future<bool> submitScore(String puzzleId, int time, int score) async {
    try {
      _log.info('Submitting score', tag: 'Scores', data: {
        'puzzleId': puzzleId,
        'time': time,
        'score': score,
      });

      final response = await _post('$baseUrl/scores', body: {
        'puzzleId': puzzleId,
        'time': time,
        'score': score,
      });

      if (response.statusCode == 201) {
        _log.info('Score submitted successfully', tag: 'Scores');
        return true;
      }
      _log.warning('Score submit failed: ${response.statusCode}', tag: 'Scores');
      return false;
    } catch (e) {
      _log.warning('Score submit error (offline mode)', tag: 'Scores');
      return true; // Offline mode - assume success
    }
  }

  Future<UserStats> getUserStats() async {
    try {
      final response = await _get('$baseUrl/scores/stats');

      if (response.statusCode == 200) {
        _log.debug('Stats fetched successfully', tag: 'Stats');
        return UserStats.fromJson(json.decode(response.body));
      }
      _log.warning('Failed to fetch stats: ${response.statusCode}', tag: 'Stats');
      return UserStats.empty();
    } catch (e) {
      _log.error('Stats fetch error', tag: 'Stats', exception: e);
      return UserStats.empty();
    }
  }

  // ==================== AUTHENTICATION ENDPOINTS ====================

  Future<LoginResult> login(String email, String password) async {
    try {
      _log.info('Login attempt', tag: 'Auth', data: {'email': email});

      final response = await _post(
        '$baseUrl/auth/login',
        headers: {'Content-Type': 'application/json'},
        body: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final user = User.fromJson(data['user']);
        final token = data['token'] ?? data['access_token'];

        if (authService != null) {
          await authService!.setAuthenticatedUser(token, user);
        }

        _log.info('Login successful', tag: 'Auth', data: {'userId': user.id});
        _log.setUserContext(userId: user.id, email: user.email, isAnonymous: false);

        return LoginResult.success(user, token);
      } else {
        final data = json.decode(response.body);
        final message = data['message'] ?? 'Login failed';
        _log.warning('Login failed: $message', tag: 'Auth');
        return LoginResult.failure(message);
      }
    } catch (e) {
      _log.error('Login error', tag: 'Auth', exception: e);
      return LoginResult.failure('Login failed: $e');
    }
  }

  Future<RegisterResult> register(
    String email,
    String password,
    String username,
  ) async {
    try {
      _log.info('Registration attempt', tag: 'Auth', data: {'email': email, 'username': username});

      final response = await _post(
        '$baseUrl/auth/register',
        headers: {'Content-Type': 'application/json'},
        body: {'email': email, 'password': password, 'username': username},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final user = User.fromJson(data['user']);
        final token = data['token'] ?? data['access_token'];

        if (authService != null) {
          await authService!.setAuthenticatedUser(token, user);
        }

        _log.info('Registration successful', tag: 'Auth', data: {'userId': user.id});
        _log.setUserContext(userId: user.id, email: user.email, isAnonymous: false);

        return RegisterResult.success(user, token);
      } else {
        final data = json.decode(response.body);
        final message = data['message'] ?? 'Registration failed';
        _log.warning('Registration failed: $message', tag: 'Auth');
        return RegisterResult.failure(message);
      }
    } catch (e) {
      _log.error('Registration error', tag: 'Auth', exception: e);
      return RegisterResult.failure('Registration failed: $e');
    }
  }

  Future<LoginResult> googleSignIn(String idToken) async {
    try {
      _log.info('Google Sign-In attempt', tag: 'Auth');

      final response = await _post(
        '$baseUrl/auth/google',
        headers: {'Content-Type': 'application/json'},
        body: {'idToken': idToken},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final user = User.fromJson(data['user']);
        final token = data['token'] ?? data['access_token'];

        if (authService != null) {
          await authService!.setAuthenticatedUser(token, user);
        }

        _log.info('Google Sign-In successful', tag: 'Auth', data: {'userId': user.id});
        _log.setUserContext(userId: user.id, email: user.email, isAnonymous: false);

        return LoginResult.success(user, token);
      } else {
        final data = json.decode(response.body);
        final message = data['message'] ?? 'Google Sign-In failed';
        _log.warning('Google Sign-In failed: $message', tag: 'Auth');
        return LoginResult.failure(message);
      }
    } catch (e) {
      _log.error('Google Sign-In error', tag: 'Auth', exception: e);
      return LoginResult.failure('Google Sign-In failed: $e');
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final response = await _get('$baseUrl/auth/me');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final user = User.fromJson(data);
        _log.debug('Current user fetched', tag: 'Auth', data: {'userId': user.id});
        return user;
      }
      _log.debug('No current user (status: ${response.statusCode})', tag: 'Auth');
      return null;
    } catch (e) {
      _log.error('Error fetching current user', tag: 'Auth', exception: e);
      return null;
    }
  }

  Future<DailyPuzzle?> getPuzzleByDate(GameType type, String dateStr) async {
    try {
      final response = await _get('$baseUrl/puzzles/type/${type.apiValue}/date/$dateStr');

      if (response.statusCode == 200) {
        return DailyPuzzle.fromJson(json.decode(response.body));
      }
      _log.debug('Puzzle not found for ${type.apiValue} on $dateStr', tag: 'Puzzles');
      return null;
    } catch (e) {
      _log.error('Error fetching puzzle by date', tag: 'Puzzles', exception: e);
      return null;
    }
  }

  // ==================== ADMIN ENDPOINTS ====================

  /// Update a puzzle (admin operation)
  Future<DailyPuzzle?> updatePuzzle(String id, Map<String, dynamic> data) async {
    try {
      _log.info('Updating puzzle', tag: 'Admin', data: {'id': id});

      final response = await _patch('$baseUrl/puzzles/$id', body: data);

      if (response.statusCode == 200) {
        _log.info('Puzzle updated successfully', tag: 'Admin');
        return DailyPuzzle.fromJson(json.decode(response.body));
      }
      _log.warning('Failed to update puzzle: ${response.statusCode}', tag: 'Admin');
      return null;
    } catch (e) {
      _log.error('Error updating puzzle', tag: 'Admin', exception: e);
      return null;
    }
  }

  // ==================== FEEDBACK ENDPOINTS ====================

  Future<bool> submitFeedback(FeedbackSubmission feedback) async {
    try {
      _log.info('Submitting feedback', tag: 'Feedback', data: {'type': feedback.type});

      final response = await _post(
        '$baseUrl/feedback',
        headers: {'Content-Type': 'application/json'},
        body: feedback.toJson(),
      );

      if (response.statusCode == 201) {
        _log.info('Feedback submitted successfully', tag: 'Feedback');
        return true;
      }
      _log.warning('Feedback submission failed: ${response.statusCode}', tag: 'Feedback');
      return false;
    } catch (e) {
      _log.error('Error submitting feedback', tag: 'Feedback', exception: e);
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
      DailyPuzzle(
        id: 'wordforge-${today.toIso8601String().split('T')[0]}',
        gameType: GameType.wordForge,
        difficulty: Difficulty.medium,
        date: today,
        targetTime: 300,
        puzzleData: {
          'letters': ['A', 'P', 'L', 'E', 'S', 'T', 'R'],
          'targetWords': ['APPLE', 'PLATE', 'STAPLE', 'TALES', 'STEAL', 'PASTE'],
          'minWordLength': 4,
        },
        solution: {
          'words': ['APPLE', 'PLATE', 'STAPLE', 'TALES', 'STEAL', 'PASTE'],
        },
      ),
      DailyPuzzle(
        id: 'nonogram-${today.toIso8601String().split('T')[0]}',
        gameType: GameType.nonogram,
        difficulty: Difficulty.medium,
        date: today,
        targetTime: 600,
        puzzleData: {
          'rows': 5,
          'cols': 5,
          'rowClues': [[1, 1], [5], [1, 1], [5], [1, 1]],
          'colClues': [[1, 1], [5], [1, 1], [5], [1, 1]],
        },
        solution: {
          'grid': [
            [true, false, false, false, true],
            [true, true, true, true, true],
            [true, false, false, false, true],
            [true, true, true, true, true],
            [true, false, false, false, true],
          ],
        },
      ),
      DailyPuzzle(
        id: 'numbertarget-${today.toIso8601String().split('T')[0]}',
        gameType: GameType.numberTarget,
        difficulty: Difficulty.medium,
        date: today,
        targetTime: 180,
        puzzleData: {
          'numbers': [25, 50, 75, 100, 3, 6],
          'target': 952,
        },
        solution: {
          'steps': ['100 + 3 = 103', '103 * 9 = 927', '927 + 25 = 952'],
        },
      ),
      DailyPuzzle(
        id: 'ballsort-${today.toIso8601String().split('T')[0]}',
        gameType: GameType.ballSort,
        difficulty: Difficulty.easy,
        date: today,
        targetTime: 180,
        puzzleData: {
          'tubes': [
            ['red', 'blue', 'green', 'red'],
            ['green', 'red', 'blue', 'green'],
            ['blue', 'green', 'red', 'blue'],
            [],
            [],
          ],
          'tubeCapacity': 4,
        },
        solution: {
          'tubes': [
            ['red', 'red', 'red', 'red'],
            ['green', 'green', 'green', 'green'],
            ['blue', 'blue', 'blue', 'blue'],
            [],
            [],
          ],
        },
      ),
      DailyPuzzle(
        id: 'pipes-${today.toIso8601String().split('T')[0]}',
        gameType: GameType.pipes,
        difficulty: Difficulty.medium,
        date: today,
        targetTime: 240,
        puzzleData: {
          'rows': 5,
          'cols': 5,
          'endpoints': [
            {'color': 'red', 'row': 0, 'col': 0},
            {'color': 'red', 'row': 4, 'col': 4},
            {'color': 'blue', 'row': 0, 'col': 4},
            {'color': 'blue', 'row': 4, 'col': 0},
            {'color': 'green', 'row': 2, 'col': 0},
            {'color': 'green', 'row': 2, 'col': 4},
          ],
          'bridges': [],
        },
        solution: {
          'paths': {
            'red': [[0, 0], [1, 0], [1, 1], [2, 1], [3, 1], [3, 2], [3, 3], [4, 3], [4, 4]],
            'blue': [[0, 4], [0, 3], [1, 3], [1, 4], [2, 4], [3, 4], [4, 4], [4, 0]],
            'green': [[2, 0], [2, 1], [2, 2], [2, 3], [2, 4]],
          },
        },
      ),
      DailyPuzzle(
        id: 'lightsout-${today.toIso8601String().split('T')[0]}',
        gameType: GameType.lightsOut,
        difficulty: Difficulty.easy,
        date: today,
        targetTime: 120,
        puzzleData: {
          'rows': 5,
          'cols': 5,
          'grid': [
            [true, false, true, false, true],
            [false, true, false, true, false],
            [true, false, true, false, true],
            [false, true, false, true, false],
            [true, false, true, false, true],
          ],
        },
        solution: {
          'moves': [[0, 0], [0, 2], [0, 4], [2, 0], [2, 2], [2, 4], [4, 0], [4, 2], [4, 4]],
        },
      ),
      DailyPuzzle(
        id: 'wordladder-${today.toIso8601String().split('T')[0]}',
        gameType: GameType.wordLadder,
        difficulty: Difficulty.medium,
        date: today,
        targetTime: 300,
        puzzleData: {
          'startWord': 'COLD',
          'targetWord': 'WARM',
          'wordLength': 4,
        },
        solution: {
          'path': ['COLD', 'CORD', 'CARD', 'WARD', 'WARM'],
        },
      ),
      DailyPuzzle(
        id: 'connections-${today.toIso8601String().split('T')[0]}',
        gameType: GameType.connections,
        difficulty: Difficulty.hard,
        date: today,
        targetTime: 300,
        puzzleData: {
          'words': [
            'APPLE', 'BANANA', 'CHERRY', 'DATE',
            'RED', 'BLUE', 'GREEN', 'YELLOW',
            'DOG', 'CAT', 'BIRD', 'FISH',
            'CAR', 'BIKE', 'TRAIN', 'PLANE'
          ],
          'groups': [
            {'name': 'Fruits', 'words': ['APPLE', 'BANANA', 'CHERRY', 'DATE'], 'difficulty': 1},
            {'name': 'Colors', 'words': ['RED', 'BLUE', 'GREEN', 'YELLOW'], 'difficulty': 2},
            {'name': 'Pets', 'words': ['DOG', 'CAT', 'BIRD', 'FISH'], 'difficulty': 3},
            {'name': 'Transport', 'words': ['CAR', 'BIKE', 'TRAIN', 'PLANE'], 'difficulty': 4},
          ],
        },
        solution: {
          'groups': [
            {'name': 'Fruits', 'words': ['APPLE', 'BANANA', 'CHERRY', 'DATE']},
            {'name': 'Colors', 'words': ['RED', 'BLUE', 'GREEN', 'YELLOW']},
            {'name': 'Pets', 'words': ['DOG', 'CAT', 'BIRD', 'FISH']},
            {'name': 'Transport', 'words': ['CAR', 'BIKE', 'TRAIN', 'PLANE']},
          ],
        },
      ),
      DailyPuzzle(
        id: 'mathora-${today.toIso8601String().split('T')[0]}',
        gameType: GameType.mathora,
        difficulty: Difficulty.medium,
        date: today,
        targetTime: 90,
        puzzleData: {
          'startNumber': 8,
          'targetNumber': 200,
          'moves': 3,
          'operations': [
            {'type': 'add', 'value': 50, 'display': '+50'},
            {'type': 'multiply', 'value': 10, 'display': '×10'},
            {'type': 'subtract', 'value': 5, 'display': '-5'},
            {'type': 'divide', 'value': 2, 'display': '÷2'},
            {'type': 'add', 'value': 100, 'display': '+100'},
            {'type': 'add', 'value': 20, 'display': '+20'},
            {'type': 'multiply', 'value': 5, 'display': '×5'},
            {'type': 'subtract', 'value': 10, 'display': '-10'},
            {'type': 'divide', 'value': 4, 'display': '÷4'},
          ],
        },
        solution: {
          'steps': [
            {'type': 'multiply', 'value': 10, 'display': '×10'},
            {'type': 'add', 'value': 100, 'display': '+100'},
            {'type': 'add', 'value': 20, 'display': '+20'},
          ],
        },
      ),
    ];
  }
}
