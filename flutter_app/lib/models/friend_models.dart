class Friend {
  final String id;
  final FriendUser user;
  final DateTime friendsSince;

  Friend({
    required this.id,
    required this.user,
    required this.friendsSince,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] ?? '',
      user: FriendUser.fromJson(json['user'] ?? {}),
      friendsSince: json['friendsSince'] != null
          ? DateTime.parse(json['friendsSince'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'friendsSince': friendsSince.toIso8601String(),
    };
  }
}

class FriendUser {
  final String id;
  final String email;
  final String username;
  final String? friendCode;

  FriendUser({
    required this.id,
    required this.email,
    required this.username,
    this.friendCode,
  });

  factory FriendUser.fromJson(Map<String, dynamic> json) {
    return FriendUser(
      id: json['_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      friendCode: json['friendCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'friendCode': friendCode,
    };
  }
}

class FriendRequest {
  final String id;
  final FriendUser sender;
  final DateTime createdAt;

  FriendRequest({
    required this.id,
    required this.sender,
    required this.createdAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] ?? '',
      sender: FriendUser.fromJson(json['sender'] ?? {}),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class SentFriendRequest {
  final String id;
  final FriendUser receiver;
  final DateTime createdAt;

  SentFriendRequest({
    required this.id,
    required this.receiver,
    required this.createdAt,
  });

  factory SentFriendRequest.fromJson(Map<String, dynamic> json) {
    return SentFriendRequest(
      id: json['id'] ?? '',
      receiver: FriendUser.fromJson(json['receiver'] ?? {}),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'receiver': receiver.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class FriendStats {
  final int wins;
  final int losses;
  final int ties;
  final int totalChallenges;

  FriendStats({
    required this.wins,
    required this.losses,
    required this.ties,
    required this.totalChallenges,
  });

  factory FriendStats.fromJson(Map<String, dynamic> json) {
    return FriendStats(
      wins: json['wins'] ?? 0,
      losses: json['losses'] ?? 0,
      ties: json['ties'] ?? 0,
      totalChallenges: json['totalChallenges'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wins': wins,
      'losses': losses,
      'ties': ties,
      'totalChallenges': totalChallenges,
    };
  }
}
