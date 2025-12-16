import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/challenge_models.dart';
import '../models/game_models.dart';
import '../services/auth_service.dart';

class ChallengeService {
  final String baseUrl;
  final AuthService authService;

  ChallengeService({
    required this.baseUrl,
    required this.authService,
  });

  Map<String, String> _getHeaders() {
    final headers = {'Content-Type': 'application/json'};

    if (authService.token != null) {
      headers['Authorization'] = 'Bearer ${authService.token}';
    }

    return headers;
  }

  /// Create a new challenge
  Future<Challenge> createChallenge({
    required String opponentId,
    required GameType gameType,
    required Difficulty difficulty,
    String? message,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/challenges'),
      headers: _getHeaders(),
      body: json.encode({
        'opponentId': opponentId,
        'gameType': gameType.apiValue,
        'difficulty': difficulty.apiValue,
        if (message != null) 'message': message,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Challenge.fromJson(json.decode(response.body));
    }

    final errorData = json.decode(response.body);
    throw Exception(errorData['message'] ?? 'Failed to create challenge');
  }

  /// Get all challenges for current user, optionally filtered by status
  Future<List<Challenge>> getChallenges({ChallengeStatus? status}) async {
    var url = '$baseUrl/challenges';
    if (status != null) {
      url += '?status=${status.value}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Challenge.fromJson(json)).toList();
    }

    throw Exception('Failed to load challenges: ${response.body}');
  }

  /// Get pending challenges (received)
  Future<List<Challenge>> getPendingChallenges() async {
    final response = await http.get(
      Uri.parse('$baseUrl/challenges/pending'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Challenge.fromJson(json)).toList();
    }

    throw Exception('Failed to load pending challenges: ${response.body}');
  }

  /// Get active challenges (accepted, in progress)
  Future<List<Challenge>> getActiveChallenges() async {
    final response = await http.get(
      Uri.parse('$baseUrl/challenges/active'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Challenge.fromJson(json)).toList();
    }

    throw Exception('Failed to load active challenges: ${response.body}');
  }

  /// Get a specific challenge by ID
  Future<Challenge> getChallenge(String challengeId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/challenges/$challengeId'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return Challenge.fromJson(json.decode(response.body));
    }

    throw Exception('Failed to load challenge: ${response.body}');
  }

  /// Accept a challenge
  Future<Challenge> acceptChallenge(String challengeId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/challenges/$challengeId/accept'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Challenge.fromJson(json.decode(response.body));
    }

    final errorData = json.decode(response.body);
    throw Exception(errorData['message'] ?? 'Failed to accept challenge');
  }

  /// Decline a challenge
  Future<Challenge> declineChallenge(String challengeId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/challenges/$challengeId/decline'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Challenge.fromJson(json.decode(response.body));
    }

    final errorData = json.decode(response.body);
    throw Exception(errorData['message'] ?? 'Failed to decline challenge');
  }

  /// Cancel a challenge (challenger only)
  Future<Challenge> cancelChallenge(String challengeId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/challenges/$challengeId/cancel'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Challenge.fromJson(json.decode(response.body));
    }

    final errorData = json.decode(response.body);
    throw Exception(errorData['message'] ?? 'Failed to cancel challenge');
  }

  /// Submit challenge result after completing the puzzle
  Future<Challenge> submitResult({
    required String challengeId,
    required int score,
    required int time,
    required int mistakes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/challenges/submit'),
      headers: _getHeaders(),
      body: json.encode({
        'challengeId': challengeId,
        'score': score,
        'time': time,
        'mistakes': mistakes,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Challenge.fromJson(json.decode(response.body));
    }

    final errorData = json.decode(response.body);
    throw Exception(errorData['message'] ?? 'Failed to submit result');
  }

  /// Get challenge statistics for current user
  Future<ChallengeStats> getStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/challenges/stats'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return ChallengeStats.fromJson(json.decode(response.body));
    }

    // Return empty stats if endpoint fails
    return ChallengeStats.empty();
  }

  /// Get challenge statistics between current user and a friend
  Future<ChallengeStats> getStatsWith(String friendId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/challenges/stats/$friendId'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return ChallengeStats.fromJson(json.decode(response.body));
    }

    // Return empty stats if endpoint fails
    return ChallengeStats.empty();
  }
}
