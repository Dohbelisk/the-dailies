import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_models.dart';

class AuthService extends ChangeNotifier {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _usernameKey = 'username';

  String? _token;
  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isInitialized = false;

  String? get token => _token;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _isInitialized;

  // Initialize auth service - load token from storage
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_tokenKey);

      if (_token != null) {
        // Load user data from storage
        final userId = prefs.getString(_userIdKey);
        final email = prefs.getString(_userEmailKey);
        final username = prefs.getString(_usernameKey);

        if (userId != null && email != null) {
          _currentUser = User(
            id: userId,
            email: email,
            username: username ?? '',
            role: 'user',
          );
          _isAuthenticated = true;
        }
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error initializing auth service: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Login with email and password
  Future<LoginResult> login(String email, String password) async {
    try {
      // This will be called through ApiService
      // For now, we'll return a placeholder
      // The actual implementation will be in ApiService
      return LoginResult(
        success: false,
        error: 'Login method should be called through ApiService',
      );
    } catch (e) {
      return LoginResult(
        success: false,
        error: 'Login failed: $e',
      );
    }
  }

  // Register new user
  Future<RegisterResult> register(
    String email,
    String password,
    String username,
  ) async {
    try {
      // This will be called through ApiService
      return RegisterResult(
        success: false,
        error: 'Register method should be called through ApiService',
      );
    } catch (e) {
      return RegisterResult(
        success: false,
        error: 'Registration failed: $e',
      );
    }
  }

  // Set authenticated user after successful login/register
  Future<void> setAuthenticatedUser(String token, User user) async {
    _token = token;
    _currentUser = user;
    _isAuthenticated = true;

    // Save to storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userIdKey, user.id);
    await prefs.setString(_userEmailKey, user.email);
    if (user.username.isNotEmpty) {
      await prefs.setString(_usernameKey, user.username);
    }

    notifyListeners();
  }

  // Logout
  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    _isAuthenticated = false;

    // Clear storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_usernameKey);

    notifyListeners();
  }

  // Migrate anonymous user data after registration/login
  Future<void> migrateAnonymousData(String deviceId) async {
    if (!_isAuthenticated || _token == null) {
      print('Cannot migrate: user not authenticated');
      return;
    }

    try {
      // This will be implemented when we add the migration endpoint
      print('Migrating data for device: $deviceId');
      // TODO: Call API endpoint to migrate scores
      // await apiService.migrateDeviceScores(deviceId);
    } catch (e) {
      print('Error migrating anonymous data: $e');
    }
  }

  // Check if token is valid (basic check)
  bool hasValidToken() {
    return _token != null && _token!.isNotEmpty;
  }

  // Get current user (fetch from backend if needed)
  Future<User?> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }

    if (!hasValidToken()) {
      return null;
    }

    try {
      // This will be implemented when we update ApiService
      // For now, return the cached user
      return _currentUser;
    } catch (e) {
      print('Error fetching current user: $e');
      return null;
    }
  }
}
