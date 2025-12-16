import 'game_models.dart';

enum ChallengeStatus {
  pending,
  accepted,
  declined,
  completed,
  expired,
  cancelled,
}

extension ChallengeStatusExtension on ChallengeStatus {
  String get value {
    switch (this) {
      case ChallengeStatus.pending:
        return 'pending';
      case ChallengeStatus.accepted:
        return 'accepted';
      case ChallengeStatus.declined:
        return 'declined';
      case ChallengeStatus.completed:
        return 'completed';
      case ChallengeStatus.expired:
        return 'expired';
      case ChallengeStatus.cancelled:
        return 'cancelled';
    }
  }

  static ChallengeStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return ChallengeStatus.pending;
      case 'accepted':
        return ChallengeStatus.accepted;
      case 'declined':
        return ChallengeStatus.declined;
      case 'completed':
        return ChallengeStatus.completed;
      case 'expired':
        return ChallengeStatus.expired;
      case 'cancelled':
        return ChallengeStatus.cancelled;
      default:
        return ChallengeStatus.pending;
    }
  }
}

class Challenge {
  final String id;
  final String challengerId;
  final String challengerUsername;
  final String opponentId;
  final String opponentUsername;
  final String puzzleId;
  final GameType gameType;
  final Difficulty difficulty;
  final ChallengeStatus status;
  final int? challengerScore;
  final int? challengerTime;
  final bool challengerCompleted;
  final int? opponentScore;
  final int? opponentTime;
  final bool opponentCompleted;
  final String? winnerId;
  final String? winnerUsername;
  final String? message;
  final DateTime expiresAt;
  final DateTime createdAt;

  Challenge({
    required this.id,
    required this.challengerId,
    required this.challengerUsername,
    required this.opponentId,
    required this.opponentUsername,
    required this.puzzleId,
    required this.gameType,
    required this.difficulty,
    required this.status,
    this.challengerScore,
    this.challengerTime,
    this.challengerCompleted = false,
    this.opponentScore,
    this.opponentTime,
    this.opponentCompleted = false,
    this.winnerId,
    this.winnerUsername,
    this.message,
    required this.expiresAt,
    required this.createdAt,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] ?? '',
      challengerId: json['challengerId'] ?? '',
      challengerUsername: json['challengerUsername'] ?? 'Unknown',
      opponentId: json['opponentId'] ?? '',
      opponentUsername: json['opponentUsername'] ?? 'Unknown',
      puzzleId: json['puzzleId'] ?? '',
      gameType: GameType.values.firstWhere(
        (e) => e.apiValue == json['gameType'],
        orElse: () => GameType.sudoku,
      ),
      difficulty: Difficulty.values.firstWhere(
        (e) => e.apiValue == json['difficulty'],
        orElse: () => Difficulty.medium,
      ),
      status: ChallengeStatusExtension.fromString(json['status'] ?? 'pending'),
      challengerScore: json['challengerScore'],
      challengerTime: json['challengerTime'],
      challengerCompleted: json['challengerCompleted'] ?? false,
      opponentScore: json['opponentScore'],
      opponentTime: json['opponentTime'],
      opponentCompleted: json['opponentCompleted'] ?? false,
      winnerId: json['winnerId'],
      winnerUsername: json['winnerUsername'],
      message: json['message'],
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : DateTime.now().add(const Duration(hours: 24)),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'challengerId': challengerId,
      'challengerUsername': challengerUsername,
      'opponentId': opponentId,
      'opponentUsername': opponentUsername,
      'puzzleId': puzzleId,
      'gameType': gameType.apiValue,
      'difficulty': difficulty.apiValue,
      'status': status.value,
      'challengerScore': challengerScore,
      'challengerTime': challengerTime,
      'challengerCompleted': challengerCompleted,
      'opponentScore': opponentScore,
      'opponentTime': opponentTime,
      'opponentCompleted': opponentCompleted,
      'winnerId': winnerId,
      'winnerUsername': winnerUsername,
      'message': message,
      'expiresAt': expiresAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Check if this user is the challenger
  bool isChallenger(String userId) => challengerId == userId;

  /// Check if this user is the opponent
  bool isOpponent(String userId) => opponentId == userId;

  /// Check if this user has completed the challenge
  bool hasUserCompleted(String userId) {
    if (isChallenger(userId)) return challengerCompleted;
    if (isOpponent(userId)) return opponentCompleted;
    return false;
  }

  /// Check if this user won the challenge
  bool didUserWin(String userId) => winnerId == userId;

  /// Check if the challenge is a tie
  bool get isTie => status == ChallengeStatus.completed && winnerId == null;

  /// Check if the challenge can be played
  bool get canPlay => status == ChallengeStatus.accepted;

  /// Check if the challenge is waiting for acceptance
  bool get isPending => status == ChallengeStatus.pending;

  /// Get the opponent's name for a user
  String getOpponentName(String userId) {
    if (isChallenger(userId)) return opponentUsername;
    return challengerUsername;
  }

  /// Get time remaining until expiry
  Duration get timeRemaining {
    final now = DateTime.now();
    if (expiresAt.isBefore(now)) return Duration.zero;
    return expiresAt.difference(now);
  }
}

class ChallengeStats {
  final int totalChallenges;
  final int wins;
  final int losses;
  final int ties;
  final int pending;
  final int winRate;

  ChallengeStats({
    required this.totalChallenges,
    required this.wins,
    required this.losses,
    required this.ties,
    required this.pending,
    required this.winRate,
  });

  factory ChallengeStats.fromJson(Map<String, dynamic> json) {
    return ChallengeStats(
      totalChallenges: json['totalChallenges'] ?? 0,
      wins: json['wins'] ?? 0,
      losses: json['losses'] ?? 0,
      ties: json['ties'] ?? 0,
      pending: json['pending'] ?? 0,
      winRate: json['winRate'] ?? 0,
    );
  }

  factory ChallengeStats.empty() {
    return ChallengeStats(
      totalChallenges: 0,
      wins: 0,
      losses: 0,
      ties: 0,
      pending: 0,
      winRate: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalChallenges': totalChallenges,
      'wins': wins,
      'losses': losses,
      'ties': ties,
      'pending': pending,
      'winRate': winRate,
    };
  }
}

class CreateChallengeRequest {
  final String opponentId;
  final GameType gameType;
  final Difficulty difficulty;
  final String? message;

  CreateChallengeRequest({
    required this.opponentId,
    required this.gameType,
    required this.difficulty,
    this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      'opponentId': opponentId,
      'gameType': gameType.apiValue,
      'difficulty': difficulty.apiValue,
      if (message != null) 'message': message,
    };
  }
}

class SubmitChallengeResultRequest {
  final String challengeId;
  final int score;
  final int time;
  final int mistakes;

  SubmitChallengeResultRequest({
    required this.challengeId,
    required this.score,
    required this.time,
    required this.mistakes,
  });

  Map<String, dynamic> toJson() {
    return {
      'challengeId': challengeId,
      'score': score,
      'time': time,
      'mistakes': mistakes,
    };
  }
}
