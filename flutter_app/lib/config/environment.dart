/// Environment configuration for the app.
///
/// Values are set at compile time using --dart-define flags.
///
/// Development (default):
///   flutter run
///
/// Production:
///   flutter run --dart-define=ENV=production --dart-define=API_URL=https://api.thedailies.app
///   flutter build apk --dart-define=ENV=production --dart-define=API_URL=https://api.thedailies.app
///
/// Staging:
///   flutter run --dart-define=ENV=staging --dart-define=API_URL=https://staging-api.thedailies.app
class Environment {
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );

  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  // AdMob configuration - Production IDs (The Dailies)
  // Android App ID: ca-app-pub-8802406857539177~9781366025
  // iOS App ID: ca-app-pub-8802406857539177~1338633755
  static const String admobAppIdAndroid = String.fromEnvironment(
    'ADMOB_APP_ID_ANDROID',
    defaultValue: 'ca-app-pub-8802406857539177~9781366025',
  );

  static const String admobAppIdIos = String.fromEnvironment(
    'ADMOB_APP_ID_IOS',
    defaultValue: 'ca-app-pub-8802406857539177~1338633755',
  );

  // Rewarded ads only (for hints and tokens)
  static const String admobRewardedIdAndroid = String.fromEnvironment(
    'ADMOB_REWARDED_ID_ANDROID',
    defaultValue: 'ca-app-pub-8802406857539177/2178208171', // Rewarded_android
  );

  static const String admobRewardedIdIos = String.fromEnvironment(
    'ADMOB_REWARDED_ID_IOS',
    defaultValue: 'ca-app-pub-8802406857539177/5572380471', // Dailies_iOS_Reward
  );

  // IAP Product IDs
  static const String iapPremiumProductId = String.fromEnvironment(
    'IAP_PREMIUM_PRODUCT_ID',
    defaultValue: 'premium_upgrade',
  );

  // Helper getters
  static bool get isDevelopment => environment == 'development';
  static bool get isStaging => environment == 'staging';
  static bool get isProduction => environment == 'production';

  // Debug logging
  static void printConfig() {
    if (!isProduction) {
      print('=== Environment Configuration ===');
      print('Environment: $environment');
      print('API URL: $apiUrl');
      print('AdMob App ID (Android): $admobAppIdAndroid');
      print('AdMob App ID (iOS): $admobAppIdIos');
      print('================================');
    }
  }
}
