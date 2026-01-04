import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App configuration from Firebase Remote Config
class RemoteAppConfig {
  final String latestVersion;
  final String minVersion;
  final String updateUrlIos;
  final String updateUrlAndroid;
  final String updateMessage;
  final String forceUpdateMessage;
  final bool maintenanceMode;
  final String maintenanceMessage;

  RemoteAppConfig({
    required this.latestVersion,
    required this.minVersion,
    this.updateUrlIos = '',
    this.updateUrlAndroid = '',
    this.updateMessage = 'A new version is available.',
    this.forceUpdateMessage = 'Please update to continue.',
    this.maintenanceMode = false,
    this.maintenanceMessage = '',
  });

  /// Get the update URL for the current platform
  String get updateUrl {
    if (Platform.isIOS) return updateUrlIos;
    if (Platform.isAndroid) return updateUrlAndroid;
    return '';
  }

  factory RemoteAppConfig.defaults() {
    return RemoteAppConfig(
      latestVersion: '1.0.0',
      minVersion: '1.0.0',
    );
  }
}

/// Version check result
enum VersionStatus {
  upToDate,
  updateAvailable,
  forceUpdate,
}

/// Feature flag status with version information
class FeatureStatus {
  final String key;
  final bool enabled;
  final String minVersion;
  final String currentVersion;
  final bool hasOverride;
  final bool? override;
  final String reason;

  FeatureStatus({
    required this.key,
    required this.enabled,
    required this.minVersion,
    required this.currentVersion,
    required this.hasOverride,
    this.override,
    required this.reason,
  });

  /// Whether the feature is disabled due to version requirements (not override)
  bool get isVersionLocked =>
      !enabled && !hasOverride && minVersion.isNotEmpty && minVersion != '0.0.0';
}

/// Service for managing app configuration and feature flags via Firebase Remote Config.
class RemoteConfigService extends ChangeNotifier {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  static const String _flagOverridesKey = 'feature_flag_overrides';
  static const String _superAccountKey = 'super_account_enabled';

  FirebaseRemoteConfig? _remoteConfig;
  RemoteAppConfig? _appConfig;
  Map<String, bool> _flagOverrides = {};
  String _currentVersion = '1.0.0';
  String _buildNumber = '1';
  bool _initialized = false;
  DateTime? _lastFetch;
  bool _isSuperAccount = false;

  // Getters
  RemoteAppConfig get appConfig => _appConfig ?? RemoteAppConfig.defaults();
  String get currentVersion => _currentVersion;
  String get buildNumber => _buildNumber;
  String get fullVersion => '$_currentVersion+$_buildNumber';
  bool get isInitialized => _initialized;
  DateTime? get lastFetch => _lastFetch;

  /// Super account status - grants unlimited tokens, future puzzle access, etc.
  bool get isSuperAccount => _isSuperAccount;

  /// Set super account status
  Future<void> setSuperAccount(bool value) async {
    _isSuperAccount = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_superAccountKey, value);
    } catch (e) {
      debugPrint('RemoteConfigService: Error saving super account status - $e');
    }
    notifyListeners();
  }

  /// Initialize the remote config service.
  Future<void> initialize() async {
    if (_initialized) return;

    // Get current app version
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    } catch (e) {
      debugPrint('RemoteConfigService: Error getting package info - $e');
    }

    // Load flag overrides and super account status from local storage
    await _loadFlagOverrides();
    await _loadSuperAccountStatus();

    // Initialize Firebase Remote Config
    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      // Set default values
      // Feature flags use version strings - empty or "0.0.0" means disabled,
      // any other version means enabled for app versions >= that value
      await _remoteConfig!.setDefaults({
        'app_latest_version': '1.0.0',
        'app_min_version': '1.0.0',
        'update_url_ios': '',
        'update_url_android': '',
        'update_message': 'A new version is available.',
        'force_update_message': 'Please update to continue.',
        'maintenance_mode': false,
        'maintenance_message': 'We are currently undergoing maintenance. Please try again later.',
        // Version-based feature flags (min app version required, empty = disabled)
        'feature_debug_menu': '',  // Disabled by default
        'feature_challenges': '1.0.0',  // Enabled for all versions
        'feature_friends': '1.0.0',  // Enabled for all versions
        'feature_display_inactive_games': '',  // Disabled by default - shows inactive games when enabled
      });

      // Configure settings
      await _remoteConfig!.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: kDebugMode
            ? const Duration(minutes: 1)
            : const Duration(hours: 1),
      ));

      // Fetch and activate
      await refreshConfig();

      _initialized = true;

      if (kDebugMode) {
        print('RemoteConfigService: Initialized');
        print('  Current version: $_currentVersion+$_buildNumber');
        print('  Latest version: ${appConfig.latestVersion}');
        print('  Min version: ${appConfig.minVersion}');
        print('  Maintenance: ${appConfig.maintenanceMode}');
      }
    } catch (e) {
      debugPrint('RemoteConfigService: Error initializing - $e');
      // Use defaults if Remote Config fails
      _appConfig = RemoteAppConfig.defaults();
      _initialized = true;
    }

    notifyListeners();
  }

  /// Refresh configuration from Firebase Remote Config.
  Future<void> refreshConfig() async {
    if (_remoteConfig == null) return;

    try {
      await _remoteConfig!.fetchAndActivate();
      _lastFetch = DateTime.now();
      _parseConfig();

      if (kDebugMode) {
        print('RemoteConfigService: Config refreshed at $_lastFetch');
      }
    } catch (e) {
      debugPrint('RemoteConfigService: Error fetching config - $e');
      // Keep using cached/default values
    }
  }

  /// Parse the Remote Config values into our app config.
  void _parseConfig() {
    if (_remoteConfig == null) return;

    _appConfig = RemoteAppConfig(
      latestVersion: _remoteConfig!.getString('app_latest_version'),
      minVersion: _remoteConfig!.getString('app_min_version'),
      updateUrlIos: _remoteConfig!.getString('update_url_ios'),
      updateUrlAndroid: _remoteConfig!.getString('update_url_android'),
      updateMessage: _remoteConfig!.getString('update_message'),
      forceUpdateMessage: _remoteConfig!.getString('force_update_message'),
      maintenanceMode: _remoteConfig!.getBool('maintenance_mode'),
      maintenanceMessage: _remoteConfig!.getString('maintenance_message'),
    );

    notifyListeners();
  }

  /// Check if a feature is enabled for the current app version.
  /// Features use version-based flags - the value is the minimum app version required.
  /// Empty string or "0.0.0" means disabled, any other version means enabled for that version+.
  bool isFeatureEnabled(String key) {
    // Check local overrides first (for debug menu)
    if (_flagOverrides.containsKey(key)) {
      return _flagOverrides[key]!;
    }

    // Get the minimum version required for this feature
    final minVersion = getFeatureMinVersion(key);

    // Empty or "0.0.0" means disabled
    if (minVersion.isEmpty || minVersion == '0.0.0') {
      return false;
    }

    // Check if current app version meets the minimum requirement
    return _compareVersions(_currentVersion, minVersion) >= 0;
  }

  /// Get the minimum app version required for a feature.
  /// Returns empty string if the feature is disabled.
  String getFeatureMinVersion(String key) {
    // Normalize key to use feature_ prefix
    final configKey = key.startsWith('feature_') ? key : 'feature_$key';

    if (_remoteConfig != null) {
      try {
        return _remoteConfig!.getString(configKey);
      } catch (e) {
        debugPrint('RemoteConfigService: Error getting feature version $configKey - $e');
      }
    }

    return '';
  }

  /// Get feature status details including min version and whether it's enabled.
  FeatureStatus getFeatureStatus(String key) {
    final configKey = key.startsWith('feature_') ? key : 'feature_$key';
    final minVersion = getFeatureMinVersion(key);
    final hasOverride = _flagOverrides.containsKey(configKey);
    final override = _flagOverrides[configKey];

    bool enabled;
    String reason;

    if (hasOverride) {
      enabled = override!;
      reason = 'Override: ${override ? "forced on" : "forced off"}';
    } else if (minVersion.isEmpty || minVersion == '0.0.0') {
      enabled = false;
      reason = 'Disabled';
    } else {
      final meetsVersion = _compareVersions(_currentVersion, minVersion) >= 0;
      enabled = meetsVersion;
      reason = meetsVersion
          ? 'Enabled (v$minVersion+)'
          : 'Requires v$minVersion (you have v$_currentVersion)';
    }

    return FeatureStatus(
      key: configKey,
      enabled: enabled,
      minVersion: minVersion,
      currentVersion: _currentVersion,
      hasOverride: hasOverride,
      override: override,
      reason: reason,
    );
  }

  /// Get a string value from Remote Config.
  String getString(String key, {String defaultValue = ''}) {
    if (_remoteConfig != null) {
      try {
        return _remoteConfig!.getString(key);
      } catch (e) {
        debugPrint('RemoteConfigService: Error getting string $key - $e');
      }
    }
    return defaultValue;
  }

  /// Get an int value from Remote Config.
  int getInt(String key, {int defaultValue = 0}) {
    if (_remoteConfig != null) {
      try {
        return _remoteConfig!.getInt(key);
      } catch (e) {
        debugPrint('RemoteConfigService: Error getting int $key - $e');
      }
    }
    return defaultValue;
  }

  /// Set a local override for a feature flag (debug menu).
  Future<void> setFlagOverride(String key, bool? value) async {
    if (value == null) {
      _flagOverrides.remove(key);
    } else {
      _flagOverrides[key] = value;
    }
    await _saveFlagOverrides();
    notifyListeners();
  }

  /// Clear all flag overrides.
  Future<void> clearAllOverrides() async {
    _flagOverrides.clear();
    await _saveFlagOverrides();
    notifyListeners();
  }

  /// Get override status for a flag.
  bool? getFlagOverride(String key) {
    return _flagOverrides.containsKey(key) ? _flagOverrides[key] : null;
  }

  /// Check if a flag has an override.
  bool hasFlagOverride(String key) {
    return _flagOverrides.containsKey(key);
  }

  /// Get all known feature flag keys.
  Set<String> get allFlagKeys {
    final keys = <String>{
      'feature_debug_menu',
      'feature_challenges',
      'feature_friends',
      'feature_display_inactive_games',
    };
    keys.addAll(_flagOverrides.keys);
    return keys;
  }

  /// Get all feature statuses with version information.
  List<FeatureStatus> get allFeatureStatuses {
    return allFlagKeys.map((key) => getFeatureStatus(key)).toList();
  }

  /// Get all feature flags with their current values (for backward compatibility).
  Map<String, bool> get featureFlags {
    final flags = <String, bool>{};
    for (final key in allFlagKeys) {
      flags[key] = isFeatureEnabled(key);
    }
    return flags;
  }

  /// Check version status.
  VersionStatus checkVersionStatus() {
    final config = _appConfig ?? RemoteAppConfig.defaults();

    final minComparison = _compareVersions(_currentVersion, config.minVersion);
    if (minComparison < 0) {
      return VersionStatus.forceUpdate;
    }

    final latestComparison = _compareVersions(_currentVersion, config.latestVersion);
    if (latestComparison < 0) {
      return VersionStatus.updateAvailable;
    }

    return VersionStatus.upToDate;
  }

  /// Compare two semantic version strings.
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

  Future<void> _loadFlagOverrides() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final overridesJson = prefs.getString(_flagOverridesKey);
      if (overridesJson != null) {
        final decoded = overridesJson.split(',');
        for (final item in decoded) {
          if (item.contains(':')) {
            final parts = item.split(':');
            if (parts.length == 2) {
              _flagOverrides[parts[0]] = parts[1] == 'true';
            }
          }
        }
      }
    } catch (e) {
      debugPrint('RemoteConfigService: Error loading overrides - $e');
    }
  }

  Future<void> _loadSuperAccountStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isSuperAccount = prefs.getBool(_superAccountKey) ?? false;
    } catch (e) {
      debugPrint('RemoteConfigService: Error loading super account status - $e');
    }
  }

  Future<void> _saveFlagOverrides() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = _flagOverrides.entries
          .map((e) => '${e.key}:${e.value}')
          .join(',');
      await prefs.setString(_flagOverridesKey, encoded);
    } catch (e) {
      debugPrint('RemoteConfigService: Error saving overrides - $e');
    }
  }
}
