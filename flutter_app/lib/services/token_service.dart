import 'package:shared_preferences/shared_preferences.dart';
import 'admob_service.dart';
import 'remote_config_service.dart';

class TokenService {
  static final TokenService _instance = TokenService._internal();
  factory TokenService() => _instance;
  TokenService._internal();

  static const int _dailyFreeTokens = 1;
  static const int _rewardedVideoTokens = 5;
  static const String _tokensCountKey = 'tokens_count';
  static const String _lastDailyTokenDateKey = 'tokens_last_daily_date';

  int _availableTokens = 0;
  final AdMobService _adMobService = AdMobService();
  final RemoteConfigService _configService = RemoteConfigService();

  int get availableTokens => _availableTokens;
  bool get isPremium => _adMobService.isPremiumUser;
  bool get isSuperAccount => _configService.isSuperAccount;

  // Token costs by difficulty
  static int getTokenCost(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 1;
      case 'medium':
        return 2;
      case 'hard':
      case 'expert':
        return 3;
      default:
        return 1;
    }
  }

  // Initialize and load token count from storage
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
    final lastDailyTokenDate = prefs.getString(_lastDailyTokenDateKey);

    // Load current token count
    _availableTokens = prefs.getInt(_tokensCountKey) ?? 0;

    // Give daily free token if it's a new day
    if (lastDailyTokenDate != today) {
      _availableTokens += _dailyFreeTokens;
      await prefs.setString(_lastDailyTokenDateKey, today);
      await prefs.setInt(_tokensCountKey, _availableTokens);
      print('🎁 Daily free token awarded! Total: $_availableTokens');
    }
  }

  // Check if user can access a puzzle (premium, super account, or has tokens)
  bool canAccessPuzzle(String difficulty, {bool isTodaysPuzzle = false}) {
    // Today's puzzles are always free
    if (isTodaysPuzzle) return true;

    // Super accounts have unlimited access
    if (_configService.isSuperAccount) return true;

    // Premium users have unlimited access
    if (_adMobService.isPremiumUser) return true;

    // Check if user has enough tokens
    final cost = getTokenCost(difficulty);
    return _availableTokens >= cost;
  }

  // Spend tokens to unlock a puzzle (returns true if successful)
  Future<bool> spendTokens(String difficulty) async {
    // Super accounts don't spend tokens
    if (_configService.isSuperAccount) return true;

    // Premium users don't spend tokens
    if (_adMobService.isPremiumUser) return true;

    final cost = getTokenCost(difficulty);

    if (_availableTokens >= cost) {
      _availableTokens -= cost;
      await _saveTokenCount();
      print('💰 Spent $cost token(s). Remaining: $_availableTokens');
      return true;
    }

    return false;
  }

  // Watch a rewarded video ad to get more tokens
  Future<bool> watchAdForTokens() async {
    bool success = await _adMobService.loadAndShowRewardedAd(
      onRewarded: (reward) async {
        _availableTokens += _rewardedVideoTokens;
        await _saveTokenCount();
        print('🎁 Earned $_rewardedVideoTokens tokens! Total: $_availableTokens');
      },
    );

    return success;
  }

  // Add tokens manually (for rewards, purchases, etc.)
  Future<void> addTokens(int count) async {
    _availableTokens += count;
    await _saveTokenCount();
  }

  // Get info about next daily token
  Future<String> getNextDailyTokenTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDailyTokenDate = prefs.getString(_lastDailyTokenDateKey);

    if (lastDailyTokenDate == null) {
      return 'Available now!';
    }

    final today = DateTime.now().toIso8601String().split('T')[0];
    if (lastDailyTokenDate != today) {
      return 'Available now!';
    }

    // Calculate time until midnight
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final difference = tomorrow.difference(now);

    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;

    return 'Next token in ${hours}h ${minutes}m';
  }

  // Save token count to storage
  Future<void> _saveTokenCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tokensCountKey, _availableTokens);
  }

  // Reset tokens (for testing)
  Future<void> resetTokens() async {
    _availableTokens = 0;
    await _saveTokenCount();
  }

  // Get a summary of token info
  Map<String, dynamic> getTokenInfo() {
    return {
      'available': _availableTokens,
      'isPremium': _adMobService.isPremiumUser,
      'dailyFreeTokens': _dailyFreeTokens,
      'rewardedVideoTokens': _rewardedVideoTokens,
      'costs': {
        'easy': getTokenCost('easy'),
        'medium': getTokenCost('medium'),
        'hard': getTokenCost('hard'),
        'expert': getTokenCost('expert'),
      },
    };
  }
}
