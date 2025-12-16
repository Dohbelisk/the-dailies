import 'game_models.dart';

enum FeedbackType {
  bugReport('bug_report', 'Bug Report'),
  newGameSuggestion('new_game_suggestion', 'New Game Suggestion'),
  puzzleSuggestion('puzzle_suggestion', 'Puzzle Suggestion'),
  puzzleMistake('puzzle_mistake', 'Puzzle Mistake'),
  general('general', 'General Feedback');

  final String apiValue;
  final String displayName;

  const FeedbackType(this.apiValue, this.displayName);

  static FeedbackType fromApiValue(String value) {
    return FeedbackType.values.firstWhere(
      (type) => type.apiValue == value,
      orElse: () => FeedbackType.general,
    );
  }
}

class FeedbackSubmission {
  final FeedbackType type;
  final String message;
  final String? email;
  final String? puzzleId;
  final GameType? gameType;
  final Difficulty? difficulty;
  final DateTime? puzzleDate;
  final String? deviceInfo;

  FeedbackSubmission({
    required this.type,
    required this.message,
    this.email,
    this.puzzleId,
    this.gameType,
    this.difficulty,
    this.puzzleDate,
    this.deviceInfo,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'type': type.apiValue,
      'message': message,
    };

    if (email != null && email!.isNotEmpty) {
      json['email'] = email;
    }

    if (puzzleId != null) {
      json['puzzleId'] = puzzleId;
    }

    if (gameType != null) {
      json['gameType'] = gameType!.apiValue;
    }

    if (difficulty != null) {
      json['difficulty'] = difficulty!.apiValue;
    }

    if (puzzleDate != null) {
      json['puzzleDate'] = puzzleDate!.toIso8601String();
    }

    if (deviceInfo != null) {
      json['deviceInfo'] = deviceInfo;
    }

    return json;
  }
}
