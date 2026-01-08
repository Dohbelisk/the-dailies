import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Background message handler - must be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('NotificationService: Background message received: ${message.messageId}');
  }
}

/// Service for handling push notifications via Firebase Cloud Messaging.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  RemoteMessage? _initialMessage;

  bool get isInitialized => _initialized;
  RemoteMessage? get initialMessage => _initialMessage;

  /// Android notification channel for high importance notifications.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'the_dailies_channel',
    'The Dailies',
    description: 'Notifications for The Dailies puzzle game',
    importance: Importance.high,
    playSound: true,
  );

  /// Initialize the notification service.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Register background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Create Android notification channel
      if (Platform.isAndroid) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_channel);
      }

      // Check if app was opened from a notification
      _initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (_initialMessage != null && kDebugMode) {
        print('NotificationService: App opened from notification: ${_initialMessage!.messageId}');
      }

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      _initialized = true;

      // Clear badge when app opens
      await clearBadge();

      if (kDebugMode) {
        print('NotificationService: Initialized');
      }
    } catch (e) {
      debugPrint('NotificationService: Error initializing - $e');
    }
  }

  /// Initialize flutter_local_notifications.
  Future<void> _initializeLocalNotifications() async {
    const initSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );
  }

  /// Handle foreground message - show a local notification.
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      print('NotificationService: Foreground message received: ${message.messageId}');
      print('  Title: ${message.notification?.title}');
      print('  Body: ${message.notification?.body}');
    }

    final notification = message.notification;
    final android = message.notification?.android;

    // Show local notification for foreground messages
    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  /// Handle notification tap when app is in background.
  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      print('NotificationService: Notification tapped: ${message.messageId}');
    }
    _processNotificationData(message.data);
  }

  /// Handle local notification tap.
  void _onLocalNotificationTap(NotificationResponse response) {
    if (kDebugMode) {
      print('NotificationService: Local notification tapped: ${response.payload}');
    }
    // Parse payload and handle navigation if needed
  }

  /// Process notification data for navigation or actions.
  void _processNotificationData(Map<String, dynamic> data) {
    // Handle deep linking or navigation based on notification data
    final type = data['type'];
    final puzzleId = data['puzzle_id'];

    if (kDebugMode) {
      print('NotificationService: Processing data - type: $type, puzzleId: $puzzleId');
    }

    // TODO: Implement navigation based on notification type
    // For example:
    // - 'new_puzzle': Navigate to today's puzzles
    // - 'challenge': Navigate to challenges screen
    // - 'friend_request': Navigate to friends screen
  }

  /// Subscribe to a notification topic.
  Future<void> subscribeToTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      if (kDebugMode) {
        print('NotificationService: Subscribed to topic: $topic');
      }
    } catch (e) {
      debugPrint('NotificationService: Error subscribing to topic - $e');
    }
  }

  /// Unsubscribe from a notification topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        print('NotificationService: Unsubscribed from topic: $topic');
      }
    } catch (e) {
      debugPrint('NotificationService: Error unsubscribing from topic - $e');
    }
  }

  /// Get the current notification permission status.
  Future<bool> hasPermission() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Request notification permission (primarily for iOS).
  Future<bool> requestPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      debugPrint('NotificationService: Error requesting permission - $e');
      return false;
    }
  }

  /// Clear the initial message after processing.
  void clearInitialMessage() {
    _initialMessage = null;
  }

  /// Method channel for iOS badge management
  static const MethodChannel _badgeChannel = MethodChannel('com.dohbelisk.thedailies/badge');

  /// Clear the app badge count (iOS only).
  /// Call this when the app is opened to remove the badge.
  Future<void> clearBadge() async {
    if (!Platform.isIOS) return;

    try {
      await _badgeChannel.invokeMethod('clearBadge');
      if (kDebugMode) {
        print('NotificationService: Badge cleared');
      }
    } catch (e) {
      // Method channel not implemented yet - that's okay
      debugPrint('NotificationService: Badge clearing not available - $e');
    }
  }

  /// Set the app badge count (iOS only).
  Future<void> setBadge(int count) async {
    if (!Platform.isIOS) return;

    try {
      await _badgeChannel.invokeMethod('setBadge', {'count': count});
      if (kDebugMode) {
        print('NotificationService: Badge set to $count');
      }
    } catch (e) {
      debugPrint('NotificationService: Badge setting not available - $e');
    }
  }
}
