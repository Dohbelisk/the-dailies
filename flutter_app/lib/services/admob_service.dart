import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/environment.dart';
import 'consent_service.dart';

class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  // Ad unit IDs from environment configuration
  // Set via --dart-define for production builds
  static String get _rewardedAdUnitId => Platform.isAndroid
      ? Environment.admobRewardedIdAndroid
      : Environment.admobRewardedIdIos;

  RewardedAd? _rewardedAd;
  final ConsentService _consentService = ConsentService();

  bool _isInitialized = false;
  bool _isPremiumUser = false;

  // Track ad performance (rewarded ads only)
  int _rewardedImpressionsCount = 0;

  bool get isInitialized => _isInitialized;
  bool get isPremiumUser => _isPremiumUser;

  /// Get the appropriate AdRequest based on user consent
  AdRequest _getAdRequest() {
    // If user has consented to personalized ads, use default request
    // Otherwise, request non-personalized ads
    if (_consentService.personalizedAdsConsent) {
      return const AdRequest();
    } else {
      // Request non-personalized ads using extras
      return const AdRequest(
        extras: {'npa': '1'}, // npa = non-personalized ads
      );
    }
  }

  // Test device IDs - add your devices here for testing
  // These devices will receive test ads instead of production ads
  static const List<String> _testDeviceIds = [
    '19B2DE06B1B773E16D5E4985BE11A2C7', // Samsung SM N970U1
    // Add more test device IDs as needed
  ];

  // Initialize AdMob
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();

      // Configure test devices (only affects debug builds in practice)
      // Production ads may show "No fill" for 24-48 hours after creating new ad units
      if (!Environment.isProduction) {
        MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(testDeviceIds: _testDeviceIds),
        );
        print('Test devices configured: $_testDeviceIds');
      }

      await _loadPremiumStatus();
      await _consentService.initialize();
      _isInitialized = true;
      print('AdMob initialized successfully (rewarded ads only)');
      print('Personalized ads: ${_consentService.personalizedAdsConsent}');
    } catch (e) {
      print('AdMob initialization failed: $e');
    }
  }

  // Load premium status from storage
  Future<void> _loadPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremiumUser = prefs.getBool('is_premium') ?? false;
  }

  // Set premium status
  Future<void> setPremiumStatus(bool isPremium) async {
    _isPremiumUser = isPremium;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', isPremium);

    // Dispose rewarded ad if user became premium (they won't need it)
    if (isPremium) {
      _rewardedAd?.dispose();
      _rewardedAd = null;
    }
  }

  // ==================== REWARDED VIDEO ADS (VOLUNTARY ONLY) ====================

  Future<bool> loadAndShowRewardedAd({
    required Function(int reward) onRewarded,
  }) async {
    if (!_isInitialized || _isPremiumUser) {
      // Premium users get reward without ad
      onRewarded(3);
      return true;
    }

    bool rewarded = false;

    await RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: _getAdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) async {
          print('Rewarded ad loaded');
          _rewardedAd = ad;

          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              print('Rewarded ad dismissed');
              ad.dispose();
              _rewardedAd = null;
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('Rewarded ad failed to show: $error');
              ad.dispose();
              _rewardedAd = null;
            },
            onAdShowedFullScreenContent: (ad) {
              print('Rewarded ad showed');
              _rewardedImpressionsCount++;
            },
          );

          // Show the ad
          await _rewardedAd!.show(
            onUserEarnedReward: (ad, reward) {
              print('User earned reward: ${reward.amount}');
              rewarded = true;
              onRewarded(reward.amount.toInt());
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('Rewarded ad failed to load: $error');
          _rewardedAd = null;
        },
      ),
    );

    // Wait a bit for ad to load and show
    await Future.delayed(const Duration(seconds: 3));

    return rewarded;
  }

  // ==================== ANALYTICS ====================

  Map<String, int> getAdStats() {
    return {
      'rewardedImpressions': _rewardedImpressionsCount,
    };
  }

  // ==================== CLEANUP ====================

  void dispose() {
    _rewardedAd?.dispose();
  }
}
