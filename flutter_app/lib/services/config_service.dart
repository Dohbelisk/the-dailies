import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../config/environment.dart';

/// App configuration from the server
class AppConfig {
  final String latestVersion;
  final String minVersion;
  final String updateUrl;
  final String updateMessage;
  final String forceUpdateMessage;
  final bool maintenanceMode;
  final String maintenanceMessage;

  AppConfig({
    required this.latestVersion,
    required this.minVersion,
    this.updateUrl = '',
    this.updateMessage = 'A new version is available.',
    this.forceUpdateMessage = 'Please update to continue.',
    this.maintenanceMode = false,
    this.maintenanceMessage = '',
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      latestVersion: json['latestVersion'] ?? '1.0.0',
      minVersion: json['minVersion'] ?? '1.0.0',
      updateUrl: json['updateUrl'] ?? '',
      updateMessage: json['updateMessage'] ?? 'A new version is available.',
      forceUpdateMessage: json['forceUpdateMessage'] ?? 'Please update to continue.',
      maintenanceMode: json['maintenanceMode'] ?? false,
      maintenanceMessage: json['maintenanceMessage'] ?? '',
    );
  }

  /// Default config when offline
  factory AppConfig.defaults() {
    return AppConfig(
      latestVersion: '1.0.0',
      minVersion: '1.0.0',
    );
  }
}

/// Version check result
enum VersionStatus {
  upToDate,       // Current version >= latest
  updateAvailable, // Current version < latest but >= min
  forceUpdate,     // Current version < min
}

/// Service for managing app configuration, feature flags, and versioning
class ConfigService extends ChangeNotifier {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  static const String _flagOverridesKey = 'feature_flag_overrides';
  static const String _cachedFlagsKey = 'cached_feature_flags';
  static const String _cachedConfigKey = 'cached_app_config';

  AppConfig? _appConfig;
  Map<String, bool> _featureFlags = {};
  Map<String, bool> _flagOverrides = {};
  String _currentVersion = '1.0.0';
  String _buildNumber = '1';
  bool _initialized = false;

  // Getters
  AppConfig get appConfig => _appConfig ?? AppConfig.defaults();
  Map<String, bool> get featureFlags => {..._featureFlags, ..._flagOverrides};
  String get currentVersion => _currentVersion;
  String get buildNumber => _buildNumber;
  String get fullVersion => '$_currentVersion+$_buildNumber';
  bool get isInitialized => _initialized;

  /// Initialize the config service
  Future<void> initialize() async {
    if (_initialized) return;

    // Get current app version
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    } catch (e) {
      debugPrint('Error getting package info: $e');
    }

    // Load cached data and overrides
    await _loadCachedData();
    await _loadFlagOverrides();

    // Fetch fresh data from server
    await refreshConfig();

    _initialized = true;
    notifyListeners();
  }

  /// Refresh configuration from server
  Future<void> refreshConfig() async {
    await Future.wait([
      _fetchAppConfig(),
      _fetchFeatureFlags(),
    ]);
    notifyListeners();
  }

  /// Fetch app config from server
  Future<void> _fetchAppConfig() async {
    try {
      final response = await http.get(
        Uri.parse('${Environment.apiUrl}/config'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _appConfig = AppConfig.fromJson(data);
        await _cacheAppConfig(data);
      }
    } catch (e) {
      debugPrint('Error fetching app config: $e');
      // Use cached config if available
    }
  }

  /// Fetch feature flags from server
  Future<void> _fetchFeatureFlags() async {
    try {
      final uri = Uri.parse('${Environment.apiUrl}/config/feature-flags').replace(
        queryParameters: {'appVersion': _currentVersion},
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['flags'] != null) {
          _featureFlags = Map<String, bool>.from(data['flags']);
          await _cacheFeatureFlags(_featureFlags);
        }
      }
    } catch (e) {
      debugPrint('Error fetching feature flags: $e');
      // Use cached flags if available
    }
  }

  /// Check if a feature is enabled
  bool isFeatureEnabled(String key) {
    // Check overrides first
    if (_flagOverrides.containsKey(key)) {
      return _flagOverrides[key]!;
    }
    // Then check server flags
    return _featureFlags[key] ?? false;
  }

  /// Set a local override for a feature flag (debug menu)
  Future<void> setFlagOverride(String key, bool? value) async {
    if (value == null) {
      _flagOverrides.remove(key);
    } else {
      _flagOverrides[key] = value;
    }
    await _saveFlagOverrides();
    notifyListeners();
  }

  /// Clear all flag overrides
  Future<void> clearAllOverrides() async {
    _flagOverrides.clear();
    await _saveFlagOverrides();
    notifyListeners();
  }

  /// Get override status for a flag
  bool? getFlagOverride(String key) {
    return _flagOverrides.containsKey(key) ? _flagOverrides[key] : null;
  }

  /// Check if a flag has an override
  bool hasFlagOverride(String key) {
    return _flagOverrides.containsKey(key);
  }

  /// Get all flag keys (from server + any overrides)
  Set<String> get allFlagKeys {
    return {..._featureFlags.keys, ..._flagOverrides.keys};
  }

  /// Check version status
  VersionStatus checkVersionStatus() {
    if (_appConfig == null) return VersionStatus.upToDate;

    final comparison = _compareVersions(_currentVersion, _appConfig!.minVersion);
    if (comparison < 0) {
      return VersionStatus.forceUpdate;
    }

    final latestComparison = _compareVersions(_currentVersion, _appConfig!.latestVersion);
    if (latestComparison < 0) {
      return VersionStatus.updateAvailable;
    }

    return VersionStatus.upToDate;
  }

  /// Compare two semantic version strings
  /// Returns: -1 if v1 < v2, 0 if equal, 1 if v1 > v2
  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final parts2 = v2.split('.').map((p) => int.tryParse(p) ?? 0).toList();

    final maxLength = parts1.length > parts2.length ? parts1.length : parts2.length;

    for (int i = 0; i < maxLength; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;

      if (p1 < p2) return -1;
      if (p1 > p2) return 1;
    }

    return 0;
  }

  // ============ Persistence ============

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load cached config
    final cachedConfig = prefs.getString(_cachedConfigKey);
    if (cachedConfig != null) {
      try {
        _appConfig = AppConfig.fromJson(json.decode(cachedConfig));
      } catch (e) {
        debugPrint('Error loading cached config: $e');
      }
    }

    // Load cached flags
    final cachedFlags = prefs.getString(_cachedFlagsKey);
    if (cachedFlags != null) {
      try {
        _featureFlags = Map<String, bool>.from(json.decode(cachedFlags));
      } catch (e) {
        debugPrint('Error loading cached flags: $e');
      }
    }
  }

  Future<void> _cacheAppConfig(Map<String, dynamic> config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedConfigKey, json.encode(config));
  }

  Future<void> _cacheFeatureFlags(Map<String, bool> flags) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedFlagsKey, json.encode(flags));
  }

  Future<void> _loadFlagOverrides() async {
    final prefs = await SharedPreferences.getInstance();
    final overrides = prefs.getString(_flagOverridesKey);
    if (overrides != null) {
      try {
        _flagOverrides = Map<String, bool>.from(json.decode(overrides));
      } catch (e) {
        debugPrint('Error loading flag overrides: $e');
      }
    }
  }

  Future<void> _saveFlagOverrides() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_flagOverridesKey, json.encode(_flagOverrides));
  }
}
