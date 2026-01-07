import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../firebase_options.dart';
import 'consent_service.dart';

/// Core Firebase service for initialization and crash reporting.
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _initialized = false;
  bool _crashlyticsEnabled = false;
  String? _fcmToken;

  bool get isInitialized => _initialized;
  bool get crashlyticsEnabled => _crashlyticsEnabled;
  String? get fcmToken => _fcmToken;

  /// Initialize Firebase Core. Must be called before any other Firebase services.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      debugPrint('FirebaseService: Attempting to initialize Firebase...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
      debugPrint('FirebaseService: Firebase Core initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('FirebaseService: ERROR initializing Firebase - $e');
      debugPrint('FirebaseService: Stack trace - $stackTrace');
      // Still mark as attempted so we don't retry infinitely
    }
  }

  /// Initialize Crashlytics. Respects user consent for analytics.
  Future<void> initializeCrashlytics() async {
    if (!_initialized) {
      debugPrint('FirebaseService: Firebase not initialized, skipping Crashlytics');
      return;
    }

    final consentService = ConsentService();
    final hasConsent = consentService.analyticsConsent;

    try {
      // Enable/disable crash collection based on consent
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(hasConsent);
      _crashlyticsEnabled = hasConsent;

      if (hasConsent) {
        // Pass all uncaught errors to Crashlytics
        FlutterError.onError = (errorDetails) {
          FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
        };

        // Pass all uncaught asynchronous errors to Crashlytics
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      }

      if (kDebugMode) {
        print('FirebaseService: Crashlytics ${hasConsent ? "enabled" : "disabled"} (consent: $hasConsent)');
      }
    } catch (e) {
      debugPrint('FirebaseService: Error initializing Crashlytics - $e');
    }
  }

  /// Initialize Firebase Cloud Messaging and get FCM token.
  Future<void> initializeFCM() async {
    if (!_initialized) {
      debugPrint('FirebaseService: Firebase not initialized, skipping FCM');
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;

      // Request permission (iOS only, Android auto-grants)
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (kDebugMode) {
        print('FirebaseService: FCM permission status: ${settings.authorizationStatus}');
      }

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get FCM token
        _fcmToken = await messaging.getToken();

        if (kDebugMode) {
          print('FirebaseService: FCM token: $_fcmToken');
        }

        // Listen for token refresh
        messaging.onTokenRefresh.listen((token) {
          _fcmToken = token;
          if (kDebugMode) {
            print('FirebaseService: FCM token refreshed: $token');
          }
        });
      }
    } catch (e) {
      debugPrint('FirebaseService: Error initializing FCM - $e');
    }
  }

  /// Log a non-fatal error to Crashlytics.
  void logError(dynamic exception, StackTrace? stack, {String? reason}) {
    if (!_crashlyticsEnabled) return;

    try {
      FirebaseCrashlytics.instance.recordError(
        exception,
        stack,
        reason: reason,
        fatal: false,
      );
    } catch (e) {
      debugPrint('FirebaseService: Error logging to Crashlytics - $e');
    }
  }

  /// Log a custom message to Crashlytics.
  void log(String message) {
    if (!_crashlyticsEnabled) return;

    try {
      FirebaseCrashlytics.instance.log(message);
    } catch (e) {
      debugPrint('FirebaseService: Error logging message - $e');
    }
  }

  /// Set a custom key-value pair for crash reports.
  void setCustomKey(String key, dynamic value) {
    if (!_crashlyticsEnabled) return;

    try {
      FirebaseCrashlytics.instance.setCustomKey(key, value);
    } catch (e) {
      debugPrint('FirebaseService: Error setting custom key - $e');
    }
  }

  /// Set the user ID for crash reports.
  void setUserId(String userId) {
    if (!_crashlyticsEnabled) return;

    try {
      FirebaseCrashlytics.instance.setUserIdentifier(userId);
    } catch (e) {
      debugPrint('FirebaseService: Error setting user ID - $e');
    }
  }

  /// Log an analytics event.
  Future<void> logAnalyticsEvent(String name, {Map<String, Object>? parameters}) async {
    if (!_initialized) return;

    final consentService = ConsentService();
    if (!consentService.analyticsConsent) return;

    try {
      await FirebaseAnalytics.instance.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      debugPrint('FirebaseService: Error logging analytics event - $e');
    }
  }

  /// Subscribe to an FCM topic.
  Future<void> subscribeToTopic(String topic) async {
    if (!_initialized) return;

    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      if (kDebugMode) {
        print('FirebaseService: Subscribed to topic: $topic');
      }
    } catch (e) {
      debugPrint('FirebaseService: Error subscribing to topic - $e');
    }
  }

  /// Unsubscribe from an FCM topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    if (!_initialized) return;

    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        print('FirebaseService: Unsubscribed from topic: $topic');
      }
    } catch (e) {
      debugPrint('FirebaseService: Error unsubscribing from topic - $e');
    }
  }

  /// Get the platform string for logging.
  String get platform {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }
}
