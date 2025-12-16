import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/friend_models.dart';
import '../services/auth_service.dart';

class FriendsService {
  final String baseUrl;
  final AuthService authService;

  FriendsService({
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

  Future<List<Friend>> getFriends() async {
    final response = await http.get(
      Uri.parse('$baseUrl/friends'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Friend.fromJson(json)).toList();
    }

    throw Exception('Failed to load friends: ${response.body}');
  }

  Future<List<FriendRequest>> getPendingRequests() async {
    final response = await http.get(
      Uri.parse('$baseUrl/friends/requests/pending'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => FriendRequest.fromJson(json)).toList();
    }

    throw Exception('Failed to load pending requests: ${response.body}');
  }

  Future<List<SentFriendRequest>> getSentRequests() async {
    final response = await http.get(
      Uri.parse('$baseUrl/friends/requests/sent'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => SentFriendRequest.fromJson(json)).toList();
    }

    throw Exception('Failed to load sent requests: ${response.body}');
  }

  Future<void> sendFriendRequestByCode(String friendCode) async {
    final response = await http.post(
      Uri.parse('$baseUrl/friends/request/code'),
      headers: _getHeaders(),
      body: json.encode({'friendCode': friendCode}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to send friend request');
    }
  }

  Future<List<FriendUser>> searchUsers(String username) async {
    final response = await http.get(
      Uri.parse('$baseUrl/friends/search?username=${Uri.encodeComponent(username)}'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => FriendUser.fromJson(json)).toList();
    }

    throw Exception('Failed to search users: ${response.body}');
  }

  Future<void> sendFriendRequestByUsername(String username) async {
    final response = await http.post(
      Uri.parse('$baseUrl/friends/request/username'),
      headers: _getHeaders(),
      body: json.encode({'username': username}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to send friend request');
    }
  }

  Future<void> acceptFriendRequest(String requestId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/friends/requests/$requestId/accept'),
      headers: _getHeaders(),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to accept friend request');
    }
  }

  Future<void> declineFriendRequest(String requestId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/friends/requests/$requestId/decline'),
      headers: _getHeaders(),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to decline friend request');
    }
  }

  Future<void> removeFriend(String friendId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/friends/$friendId'),
      headers: _getHeaders(),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to remove friend');
    }
  }

  Future<FriendStats> getFriendStats(String friendId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/challenges/stats/$friendId'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return FriendStats.fromJson(data);
    }

    // Return empty stats if endpoint not yet implemented
    return FriendStats(wins: 0, losses: 0, ties: 0, totalChallenges: 0);
  }
}
