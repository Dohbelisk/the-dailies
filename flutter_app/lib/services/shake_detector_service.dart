import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Service that detects device shakes using the accelerometer.
///
/// Usage:
/// ```dart
/// final detector = ShakeDetectorService();
/// detector.onShake = () {
///   // Handle shake
/// };
/// detector.start();
/// // Later...
/// detector.stop();
/// ```
class ShakeDetectorService {
  static final ShakeDetectorService _instance = ShakeDetectorService._internal();
  factory ShakeDetectorService() => _instance;
  ShakeDetectorService._internal();

  /// Callback when shake is detected
  VoidCallback? onShake;

  /// Minimum acceleration force to consider as a shake (in m/s^2)
  /// Default gravity is ~9.8, so we want noticeable movement above that
  /// Lowered to 8.0 for easier activation on different devices
  double shakeThreshold = 8.0;

  /// Minimum time between shake detections (prevents rapid-fire triggers)
  Duration shakeCooldown = const Duration(seconds: 2);

  /// Number of shake movements required to trigger
  /// Only need 2 shakes for easier activation
  int shakeCountThreshold = 2;

  /// Time window in which shakeCountThreshold shakes must occur
  /// 1.5 seconds for more forgiving timing
  Duration shakeTimeWindow = const Duration(milliseconds: 1500);

  StreamSubscription<AccelerometerEvent>? _subscription;
  DateTime? _lastShakeTime;
  final List<DateTime> _shakeTimes = [];

  /// Enable or disable shake detection temporarily
  bool isEnabled = true;

  /// Whether shake detection is currently active
  bool get isListening => _subscription != null;

  /// Start listening for shake events
  void start() {
    if (_subscription != null) return;

    _subscription = accelerometerEventStream().listen(_onAccelerometerEvent);
  }

  /// Stop listening for shake events
  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _shakeTimes.clear();
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    if (!isEnabled || onShake == null) return;

    // Calculate the magnitude of acceleration (excluding gravity is complex,
    // so we use total magnitude and a higher threshold)
    final magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    // Subtract approximate gravity to get "excess" acceleration
    // Gravity is ~9.8 m/s^2
    final excessAcceleration = (magnitude - 9.8).abs();

    if (excessAcceleration > shakeThreshold) {
      final now = DateTime.now();

      // Check cooldown
      if (_lastShakeTime != null &&
          now.difference(_lastShakeTime!) < shakeCooldown) {
        return;
      }

      // Add this shake to the list
      _shakeTimes.add(now);

      // Remove old shakes outside the time window
      _shakeTimes.removeWhere(
        (time) => now.difference(time) > shakeTimeWindow,
      );

      // Check if we have enough shakes in the window
      if (_shakeTimes.length >= shakeCountThreshold) {
        _lastShakeTime = now;
        _shakeTimes.clear();
        onShake?.call();
      }
    }
  }

  /// Dispose the service
  void dispose() {
    stop();
    onShake = null;
  }
}
