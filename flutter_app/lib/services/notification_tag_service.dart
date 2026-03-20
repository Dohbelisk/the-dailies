import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_models.dart';
import 'firebase_service.dart';
import 'auth_service.dart';
import 'api_service.dart';
import 'purchase_service.dart';
import 'remote_config_service.dart';

/// Manages FCM topic subscriptions as user tags for push notification targeting.
///
/// Each tag maps to an FCM topic. Tags are evaluated on app launch and after
/// key events (puzzle completion, subscription change). State is persisted
/// locally to avoid redundant subscribe/unsubscribe calls.
class NotificationTagService {
  static final NotificationTagService _instance = NotificationTagService._internal();
  factory NotificationTagService() => _instance;
  NotificationTagService._internal();

  static const String _activeTagsKey = 'notification_active_tags';
  static const String _lastEvalKey = 'notification_tags_last_eval';
  static const String _firstLaunchKey = 'notification_first_launch_date';

  final FirebaseService _firebase = FirebaseService();
  Set<String> _activeTags = {};
  bool _initialized = false;

  bool get isInitialized => _initialized;
  Set<String> get activeTags => Set.unmodifiable(_activeTags);

  /// Initialize the service and load persisted tag state.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Record first launch date if not set
      if (!prefs.containsKey(_firstLaunchKey)) {
        await prefs.setString(_firstLaunchKey, DateTime.now().toIso8601String());
      }

      // Load active tags from storage
      final stored = prefs.getStringList(_activeTagsKey);
      if (stored != null) {
        _activeTags = stored.toSet();
      }

      _initialized = true;

      if (kDebugMode) {
        print('NotificationTagService: Initialized with ${_activeTags.length} active tags');
      }
    } catch (e) {
      debugPrint('NotificationTagService: Error initializing - $e');
      _initialized = true;
    }
  }

  /// Evaluate and sync all tags based on current user state.
  /// Call this on app launch (after auth + stats are available) and after
  /// significant events like puzzle completion or subscription change.
  Future<void> evaluateAndSync() async {
    if (!_firebase.isInitialized) return;

    try {
      final desiredTags = await _computeDesiredTags();
      await _syncTags(desiredTags);

      if (kDebugMode) {
        print('NotificationTagService: Synced ${_activeTags.length} tags: $_activeTags');
      }
    } catch (e) {
      debugPrint('NotificationTagService: Error evaluating tags - $e');
    }
  }

  /// Compute what tags should be active based on current user state.
  Future<Set<String>> _computeDesiredTags() async {
    final tags = <String>{};
    final authService = AuthService();
    final purchaseService = PurchaseService();
    final configService = RemoteConfigService();

    // --- Platform tags ---
    if (Platform.isIOS) {
      tags.add('platform_ios');
    } else if (Platform.isAndroid) {
      tags.add('platform_android');
    }

    // --- Version tag ---
    final version = configService.currentVersion;
    tags.add('version_${version.replaceAll('.', '_')}');

    // --- All users get daily puzzles topic ---
    tags.add('daily_puzzles');

    // If not logged in, just return platform + version + daily_puzzles
    if (authService.currentUser == null) {
      tags.add('tier_free');
      return tags;
    }

    // --- Subscription tags ---
    if (purchaseService.isPremium) {
      tags.add('tier_premium');
    } else {
      tags.add('tier_free');
    }

    // --- Fetch stats for engagement + gameplay tags ---
    try {
      final apiService = ApiService(authService: authService);
      final stats = await apiService.getUserStats();

      _addEngagementTags(tags, stats);
      _addGameplayTags(tags, stats);
    } catch (e) {
      debugPrint('NotificationTagService: Error fetching stats for tags - $e');
    }

    // --- New user tag ---
    try {
      final prefs = await SharedPreferences.getInstance();
      final firstLaunchStr = prefs.getString(_firstLaunchKey);
      if (firstLaunchStr != null) {
        final firstLaunch = DateTime.parse(firstLaunchStr);
        final daysSinceInstall = DateTime.now().difference(firstLaunch).inDays;
        if (daysSinceInstall <= 7) {
          tags.add('new_user');
        }
      }
    } catch (_) {}

    // --- Play time tags (based on current hour) ---
    _addPlayTimeTags(tags);

    return tags;
  }

  /// Add engagement tags based on streak and activity.
  void _addEngagementTags(Set<String> tags, UserStats stats) {
    // Streak tags
    if (stats.currentStreak > 0) {
      tags.add('streak_active');
    } else if (stats.longestStreak > 0) {
      // Had a streak before but not active now
      tags.add('streak_broken');
    } else {
      tags.add('streak_never');
    }

    // Power user: 3+ games per day average (rough heuristic: 100+ total games)
    if (stats.totalGamesPlayed >= 100) {
      tags.add('power_user');
    }
  }

  /// Add gameplay tags based on puzzle completion history.
  void _addGameplayTags(Set<String> tags, UserStats stats) {
    // Per-game-type tags (played at least 3 times)
    String? favoriteType;
    int favoriteCount = 0;

    for (final entry in stats.gameTypeCounts.entries) {
      if (entry.value >= 3) {
        // Normalize game type to tag-friendly format
        final tagName = 'plays_${entry.key.toLowerCase().replaceAll(' ', '_')}';
        tags.add(tagName);
      }

      if (entry.value > favoriteCount) {
        favoriteCount = entry.value;
        favoriteType = entry.key;
      }
    }

    // Favorite game type
    if (favoriteType != null && favoriteCount >= 3) {
      tags.add('favorite_${favoriteType.toLowerCase().replaceAll(' ', '_')}');
    }

    // Milestone tags
    final total = stats.totalGamesPlayed;
    if (total >= 500) {
      tags.add('puzzles_completed_500');
    } else if (total >= 100) {
      tags.add('puzzles_completed_100');
    } else if (total >= 50) {
      tags.add('puzzles_completed_50');
    } else if (total >= 10) {
      tags.add('puzzles_completed_10');
    }
  }

  /// Add play time preference tag based on current hour.
  /// Over multiple sessions, the most recent session time gets tagged.
  void _addPlayTimeTags(Set<String> tags) {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      tags.add('plays_morning');
    } else if (hour >= 12 && hour < 17) {
      tags.add('plays_afternoon');
    } else if (hour >= 17 && hour < 21) {
      tags.add('plays_evening');
    } else {
      tags.add('plays_night');
    }
  }

  /// Sync desired tags with FCM topics, subscribing/unsubscribing as needed.
  Future<void> _syncTags(Set<String> desiredTags) async {
    final toSubscribe = desiredTags.difference(_activeTags);
    final toUnsubscribe = _activeTags.difference(desiredTags);

    // Subscribe to new tags
    for (final tag in toSubscribe) {
      await _firebase.subscribeToTopic(tag);
    }

    // Unsubscribe from removed tags
    for (final tag in toUnsubscribe) {
      await _firebase.unsubscribeFromTopic(tag);
    }

    // Persist new state
    _activeTags = desiredTags;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_activeTagsKey, _activeTags.toList());
      await prefs.setString(_lastEvalKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('NotificationTagService: Error persisting tags - $e');
    }
  }

  /// Force re-evaluation (e.g. after subscription purchase or puzzle completion).
  Future<void> refresh() async {
    await evaluateAndSync();
  }
}
