class User {
  final String id;
  final String email;
  final String username;
  final String role;
  final String? friendCode;

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.role,
    this.friendCode,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      role: json['role'] ?? 'user',
      friendCode: json['friendCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'role': role,
      'friendCode': friendCode,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? username,
    String? role,
    String? friendCode,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      role: role ?? this.role,
      friendCode: friendCode ?? this.friendCode,
    );
  }
}

class LoginResult {
  final bool success;
  final User? user;
  final String? token;
  final String? error;

  LoginResult({
    required this.success,
    this.user,
    this.token,
    this.error,
  });

  factory LoginResult.success(User user, String token) {
    return LoginResult(
      success: true,
      user: user,
      token: token,
    );
  }

  factory LoginResult.failure(String error) {
    return LoginResult(
      success: false,
      error: error,
    );
  }
}

class RegisterResult {
  final bool success;
  final User? user;
  final String? token;
  final String? error;

  RegisterResult({
    required this.success,
    this.user,
    this.token,
    this.error,
  });

  factory RegisterResult.success(User user, String token) {
    return RegisterResult(
      success: true,
      user: user,
      token: token,
    );
  }

  factory RegisterResult.failure(String error) {
    return RegisterResult(
      success: false,
      error: error,
    );
  }
}
