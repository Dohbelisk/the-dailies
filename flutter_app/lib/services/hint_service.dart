import 'package:shared_preferences/shared_preferences.dart';
import 'admob_service.dart';

class HintService {
  static final HintService _instance = HintService._internal();
  factory HintService() => _instance;
  HintService._internal();

  static const int _freeHintsPerDay = 3;
  static const int _rewardedHintsAmount = 3;
  static const String _hintsCountKey = 'hints_count';
  static const String _lastResetDateKey = 'hints_last_reset_date';

  int _availableHints = _freeHintsPerDay;
  final AdMobService _adMobService = AdMobService();

  int get availableHints => _availableHints;
  bool get hasHints => _availableHints > 0 || _adMobService.isPremiumUser;
  bool get isPremium => _adMobService.isPremiumUser;

  // Initialize and load hint count from storage
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
    final lastResetDate = prefs.getString(_lastResetDateKey);

    // Reset hints if it's a new day
    if (lastResetDate != today) {
      _availableHints = _freeHintsPerDay;
      await prefs.setString(_lastResetDateKey, today);
      await prefs.setInt(_hintsCountKey, _availableHints);
    } else {
      _availableHints = prefs.getInt(_hintsCountKey) ?? _freeHintsPerDay;
    }
  }

  // Use a hint (returns true if successful)
  Future<bool> useHint() async {
    // Premium users have unlimited hints
    if (_adMobService.isPremiumUser) {
      return true;
    }

    if (_availableHints > 0) {
      _availableHints--;
      await _saveHintCount();
      return true;
    }

    return false;
  }

  // Watch a rewarded video ad to get more hints
  Future<bool> watchAdForHints() async {
    bool success = await _adMobService.loadAndShowRewardedAd(
      onRewarded: (reward) async {
        _availableHints += _rewardedHintsAmount;
        await _saveHintCount();
      },
    );

    return success;
  }

  // Add hints manually (for rewards, purchases, etc.)
  Future<void> addHints(int count) async {
    _availableHints += count;
    await _saveHintCount();
  }

  // Save hint count to storage
  Future<void> _saveHintCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hintsCountKey, _availableHints);
  }

  // Reset hints (for testing)
  Future<void> resetHints() async {
    _availableHints = _freeHintsPerDay;
    await _saveHintCount();
  }
}
