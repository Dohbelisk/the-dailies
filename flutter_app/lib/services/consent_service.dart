import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages user consent for GDPR compliance.
///
/// Tracks consent for:
/// - Personalized advertising
/// - Analytics/usage data collection
/// - Terms of service acceptance
class ConsentService extends ChangeNotifier {
  static final ConsentService _instance = ConsentService._internal();
  factory ConsentService() => _instance;
  ConsentService._internal();

  // SharedPreferences keys
  static const String _consentShownKey = 'consent_dialog_shown';
  static const String _personalizedAdsKey = 'consent_personalized_ads';
  static const String _analyticsKey = 'consent_analytics';
  static const String _termsAcceptedKey = 'consent_terms_accepted';
  static const String _consentDateKey = 'consent_date';
  static const String _consentVersionKey = 'consent_version';

  // Current consent version - increment when terms change significantly
  static const int currentConsentVersion = 1;

  bool _isInitialized = false;
  bool _consentDialogShown = false;
  bool _personalizedAdsConsent = false;
  bool _analyticsConsent = false;
  bool _termsAccepted = false;
  DateTime? _consentDate;
  int _consentVersion = 0;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get consentDialogShown => _consentDialogShown;
  bool get personalizedAdsConsent => _personalizedAdsConsent;
  bool get analyticsConsent => _analyticsConsent;
  bool get termsAccepted => _termsAccepted;
  DateTime? get consentDate => _consentDate;

  /// Whether we need to show the consent dialog
  /// Returns true if never shown or if consent version has changed
  bool get needsConsent {
    if (!_consentDialogShown) return true;
    if (_consentVersion < currentConsentVersion) return true;
    return false;
  }

  /// Whether we have minimum required consent to use the app
  bool get hasRequiredConsent => _termsAccepted;

  /// Initialize the consent service
  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();

    _consentDialogShown = prefs.getBool(_consentShownKey) ?? false;
    _personalizedAdsConsent = prefs.getBool(_personalizedAdsKey) ?? false;
    _analyticsConsent = prefs.getBool(_analyticsKey) ?? false;
    _termsAccepted = prefs.getBool(_termsAcceptedKey) ?? false;
    _consentVersion = prefs.getInt(_consentVersionKey) ?? 0;

    final consentDateStr = prefs.getString(_consentDateKey);
    if (consentDateStr != null) {
      _consentDate = DateTime.tryParse(consentDateStr);
    }

    _isInitialized = true;

    if (kDebugMode) {
      print('ConsentService initialized:');
      print('  Dialog shown: $_consentDialogShown');
      print('  Personalized ads: $_personalizedAdsConsent');
      print('  Analytics: $_analyticsConsent');
      print('  Terms accepted: $_termsAccepted');
      print('  Version: $_consentVersion (current: $currentConsentVersion)');
      print('  Needs consent: $needsConsent');
    }

    notifyListeners();
  }

  /// Save all consent choices
  Future<void> saveConsent({
    required bool personalizedAds,
    required bool analytics,
    required bool termsAccepted,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    _personalizedAdsConsent = personalizedAds;
    _analyticsConsent = analytics;
    _termsAccepted = termsAccepted;
    _consentDialogShown = true;
    _consentDate = DateTime.now();
    _consentVersion = currentConsentVersion;

    await prefs.setBool(_consentShownKey, true);
    await prefs.setBool(_personalizedAdsKey, personalizedAds);
    await prefs.setBool(_analyticsKey, analytics);
    await prefs.setBool(_termsAcceptedKey, termsAccepted);
    await prefs.setString(_consentDateKey, _consentDate!.toIso8601String());
    await prefs.setInt(_consentVersionKey, currentConsentVersion);

    if (kDebugMode) {
      print('Consent saved:');
      print('  Personalized ads: $personalizedAds');
      print('  Analytics: $analytics');
      print('  Terms accepted: $termsAccepted');
    }

    notifyListeners();
  }

  /// Update personalized ads consent only
  Future<void> setPersonalizedAdsConsent(bool consent) async {
    final prefs = await SharedPreferences.getInstance();
    _personalizedAdsConsent = consent;
    await prefs.setBool(_personalizedAdsKey, consent);
    notifyListeners();
  }

  /// Update analytics consent only
  Future<void> setAnalyticsConsent(bool consent) async {
    final prefs = await SharedPreferences.getInstance();
    _analyticsConsent = consent;
    await prefs.setBool(_analyticsKey, consent);
    notifyListeners();
  }

  /// Reset all consent (for testing or when user wants to reconsider)
  Future<void> resetConsent() async {
    final prefs = await SharedPreferences.getInstance();

    _consentDialogShown = false;
    _personalizedAdsConsent = false;
    _analyticsConsent = false;
    _termsAccepted = false;
    _consentDate = null;
    _consentVersion = 0;

    await prefs.remove(_consentShownKey);
    await prefs.remove(_personalizedAdsKey);
    await prefs.remove(_analyticsKey);
    await prefs.remove(_termsAcceptedKey);
    await prefs.remove(_consentDateKey);
    await prefs.remove(_consentVersionKey);

    notifyListeners();
  }

  /// Get a summary of consent status for display
  String getConsentSummary() {
    if (!_consentDialogShown) {
      return 'No consent recorded';
    }

    final parts = <String>[];
    parts.add('Terms: ${_termsAccepted ? "Accepted" : "Not accepted"}');
    parts.add('Personalized ads: ${_personalizedAdsConsent ? "Yes" : "No"}');
    parts.add('Analytics: ${_analyticsConsent ? "Yes" : "No"}');

    if (_consentDate != null) {
      parts.add('Date: ${_consentDate!.toString().split(' ')[0]}');
    }

    return parts.join('\n');
  }
}
