import 'package:flutter/material.dart';
import 'game_models.dart';

/// Categories for organizing achievements
enum AchievementCategory {
  beginner('Getting Started', Icons.star_outline_rounded),
  puzzleMaster('Puzzle Master', Icons.emoji_events_rounded),
  streak('Streaks', Icons.local_fire_department_rounded),
  speed('Speed Demon', Icons.bolt_rounded),
  explorer('Explorer', Icons.explore_rounded),
  social('Social', Icons.people_rounded),
  collector('Collector', Icons.collections_rounded),
  special('Special', Icons.auto_awesome_rounded);

  final String displayName;
  final IconData icon;

  const AchievementCategory(this.displayName, this.icon);
}

/// Rarity tiers for achievements
enum AchievementRarity {
  common(Color(0xFF9E9E9E), 'Common', 10),
  uncommon(Color(0xFF4CAF50), 'Uncommon', 25),
  rare(Color(0xFF2196F3), 'Rare', 50),
  epic(Color(0xFF9C27B0), 'Epic', 100),
  legendary(Color(0xFFFF9800), 'Legendary', 250);

  final Color color;
  final String displayName;
  final int xpReward;

  const AchievementRarity(this.color, this.displayName, this.xpReward);
}

/// Definition of all achievements in the game
enum AchievementType {
  // Beginner achievements
  firstPuzzle(
    'First Steps',
    'Complete your first puzzle',
    AchievementCategory.beginner,
    AchievementRarity.common,
    iconData: Icons.play_circle_outline_rounded,
  ),
  firstPerfect(
    'Flawless',
    'Complete a puzzle with no mistakes',
    AchievementCategory.beginner,
    AchievementRarity.common,
    iconData: Icons.check_circle_outline_rounded,
  ),
  firstFavorite(
    'Playing Favorites',
    'Add a game to your favorites',
    AchievementCategory.beginner,
    AchievementRarity.common,
    iconData: Icons.favorite_outline_rounded,
  ),

  // Puzzle completion achievements
  complete10(
    'Getting Warmed Up',
    'Complete 10 puzzles',
    AchievementCategory.puzzleMaster,
    AchievementRarity.common,
    targetCount: 10,
    iconData: Icons.grid_3x3_rounded,
  ),
  complete50(
    'Puzzle Enthusiast',
    'Complete 50 puzzles',
    AchievementCategory.puzzleMaster,
    AchievementRarity.uncommon,
    targetCount: 50,
    iconData: Icons.grid_4x4_rounded,
  ),
  complete100(
    'Century Club',
    'Complete 100 puzzles',
    AchievementCategory.puzzleMaster,
    AchievementRarity.rare,
    targetCount: 100,
    iconData: Icons.workspace_premium_rounded,
  ),
  complete500(
    'Puzzle Master',
    'Complete 500 puzzles',
    AchievementCategory.puzzleMaster,
    AchievementRarity.epic,
    targetCount: 500,
    iconData: Icons.military_tech_rounded,
  ),
  complete1000(
    'Puzzle Legend',
    'Complete 1000 puzzles',
    AchievementCategory.puzzleMaster,
    AchievementRarity.legendary,
    targetCount: 1000,
    iconData: Icons.emoji_events_rounded,
  ),

  // Streak achievements
  streak3(
    'Hat Trick',
    'Maintain a 3-day streak',
    AchievementCategory.streak,
    AchievementRarity.common,
    targetCount: 3,
    iconData: Icons.local_fire_department_rounded,
  ),
  streak7(
    'Week Warrior',
    'Maintain a 7-day streak',
    AchievementCategory.streak,
    AchievementRarity.uncommon,
    targetCount: 7,
    iconData: Icons.local_fire_department_rounded,
  ),
  streak30(
    'Monthly Master',
    'Maintain a 30-day streak',
    AchievementCategory.streak,
    AchievementRarity.rare,
    targetCount: 30,
    iconData: Icons.local_fire_department_rounded,
  ),
  streak100(
    'Unstoppable',
    'Maintain a 100-day streak',
    AchievementCategory.streak,
    AchievementRarity.epic,
    targetCount: 100,
    iconData: Icons.local_fire_department_rounded,
  ),
  streak365(
    'Year of Puzzles',
    'Maintain a 365-day streak',
    AchievementCategory.streak,
    AchievementRarity.legendary,
    targetCount: 365,
    iconData: Icons.local_fire_department_rounded,
  ),

  // Speed achievements
  speedDemon(
    'Speed Demon',
    'Complete a puzzle in under 1 minute',
    AchievementCategory.speed,
    AchievementRarity.uncommon,
    iconData: Icons.bolt_rounded,
  ),
  lightningFast(
    'Lightning Fast',
    'Complete a puzzle in under 30 seconds',
    AchievementCategory.speed,
    AchievementRarity.rare,
    iconData: Icons.flash_on_rounded,
  ),
  beatTarget10(
    'Target Practice',
    'Beat the target time on 10 puzzles',
    AchievementCategory.speed,
    AchievementRarity.uncommon,
    targetCount: 10,
    iconData: Icons.timer_rounded,
  ),
  beatTarget50(
    'Time Crusher',
    'Beat the target time on 50 puzzles',
    AchievementCategory.speed,
    AchievementRarity.rare,
    targetCount: 50,
    iconData: Icons.timer_off_rounded,
  ),

  // Explorer achievements (try different game types)
  tryAllGames(
    'Jack of All Trades',
    'Try every puzzle type at least once',
    AchievementCategory.explorer,
    AchievementRarity.uncommon,
    iconData: Icons.explore_rounded,
  ),
  masterAllGames(
    'Renaissance Puzzler',
    'Complete 10 puzzles of each type',
    AchievementCategory.explorer,
    AchievementRarity.epic,
    iconData: Icons.stars_rounded,
  ),

  // Game-specific achievements
  sudokuMaster(
    'Sudoku Sensei',
    'Complete 50 Sudoku puzzles',
    AchievementCategory.collector,
    AchievementRarity.rare,
    targetCount: 50,
    gameType: GameType.sudoku,
    iconData: Icons.grid_3x3_rounded,
  ),
  crosswordKing(
    'Wordsmith',
    'Complete 50 Crossword puzzles',
    AchievementCategory.collector,
    AchievementRarity.rare,
    targetCount: 50,
    gameType: GameType.crossword,
    iconData: Icons.abc_rounded,
  ),
  wordForgeMaster(
    'Word Forge Master',
    'Find 100 pangrams in Word Forge',
    AchievementCategory.collector,
    AchievementRarity.epic,
    targetCount: 100,
    gameType: GameType.wordForge,
    iconData: Icons.hexagon_rounded,
  ),
  nonogramArtist(
    'Pixel Artist',
    'Complete 50 Nonogram puzzles',
    AchievementCategory.collector,
    AchievementRarity.rare,
    targetCount: 50,
    gameType: GameType.nonogram,
    iconData: Icons.grid_view_rounded,
  ),

  // Daily achievements
  dailySweep(
    'Daily Sweep',
    'Complete all puzzles in a single day',
    AchievementCategory.special,
    AchievementRarity.uncommon,
    iconData: Icons.today_rounded,
  ),
  dailySweep7(
    'Weekly Warrior',
    'Complete all daily puzzles for 7 days straight',
    AchievementCategory.special,
    AchievementRarity.rare,
    targetCount: 7,
    iconData: Icons.date_range_rounded,
  ),
  earlyBird(
    'Early Bird',
    'Complete a puzzle before 6 AM',
    AchievementCategory.special,
    AchievementRarity.uncommon,
    iconData: Icons.wb_sunny_rounded,
  ),
  nightOwl(
    'Night Owl',
    'Complete a puzzle after midnight',
    AchievementCategory.special,
    AchievementRarity.uncommon,
    iconData: Icons.nightlight_rounded,
  ),

  // Perfect score achievements
  perfectScore(
    'Perfect Score',
    'Achieve a score of 10,000 on any puzzle',
    AchievementCategory.special,
    AchievementRarity.rare,
    iconData: Icons.star_rounded,
  ),
  perfectStreak5(
    'Perfection Streak',
    'Get 5 perfect puzzles in a row',
    AchievementCategory.special,
    AchievementRarity.epic,
    targetCount: 5,
    iconData: Icons.auto_awesome_rounded,
  ),

  // Social achievements (placeholders for future)
  firstFriend(
    'Social Butterfly',
    'Add your first friend',
    AchievementCategory.social,
    AchievementRarity.common,
    iconData: Icons.person_add_rounded,
  ),
  firstChallenge(
    'Challenger',
    'Send your first challenge',
    AchievementCategory.social,
    AchievementRarity.common,
    iconData: Icons.sports_kabaddi_rounded,
  ),
  winChallenge10(
    'Champion',
    'Win 10 challenges',
    AchievementCategory.social,
    AchievementRarity.rare,
    targetCount: 10,
    iconData: Icons.emoji_events_rounded,
  );

  final String title;
  final String description;
  final AchievementCategory category;
  final AchievementRarity rarity;
  final int? targetCount;
  final GameType? gameType;
  final IconData? iconData;

  const AchievementType(
    this.title,
    this.description,
    this.category,
    this.rarity, {
    this.targetCount,
    this.gameType,
    this.iconData,
  });
}

/// Represents the user's progress on a specific achievement
class AchievementProgress {
  final AchievementType type;
  final int currentProgress;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final bool isNew; // Newly unlocked, not yet viewed

  const AchievementProgress({
    required this.type,
    this.currentProgress = 0,
    this.isUnlocked = false,
    this.unlockedAt,
    this.isNew = false,
  });

  int get targetCount => type.targetCount ?? 1;
  double get progressPercent =>
      targetCount > 0 ? (currentProgress / targetCount).clamp(0.0, 1.0) : 0.0;

  AchievementProgress copyWith({
    int? currentProgress,
    bool? isUnlocked,
    DateTime? unlockedAt,
    bool? isNew,
  }) {
    return AchievementProgress(
      type: type,
      currentProgress: currentProgress ?? this.currentProgress,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isNew: isNew ?? this.isNew,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'currentProgress': currentProgress,
        'isUnlocked': isUnlocked,
        'unlockedAt': unlockedAt?.toIso8601String(),
        'isNew': isNew,
      };

  factory AchievementProgress.fromJson(Map<String, dynamic> json) {
    return AchievementProgress(
      type: AchievementType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => AchievementType.firstPuzzle,
      ),
      currentProgress: json['currentProgress'] ?? 0,
      isUnlocked: json['isUnlocked'] ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'])
          : null,
      isNew: json['isNew'] ?? false,
    );
  }
}

/// Summary of user's overall achievement progress
class AchievementsSummary {
  final int totalUnlocked;
  final int totalAchievements;
  final int totalXp;
  final int newUnlockedCount;
  final List<AchievementProgress> recentUnlocks;

  const AchievementsSummary({
    required this.totalUnlocked,
    required this.totalAchievements,
    required this.totalXp,
    required this.newUnlockedCount,
    required this.recentUnlocks,
  });

  double get completionPercent =>
      totalAchievements > 0 ? totalUnlocked / totalAchievements : 0.0;
}
