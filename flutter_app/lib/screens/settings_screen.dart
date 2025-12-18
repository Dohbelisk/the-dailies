import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../services/audio_service.dart';
import '../services/purchase_service.dart';
import '../services/consent_service.dart';
import '../services/config_service.dart';
import '../widgets/feedback_dialog.dart';
import 'legal/privacy_policy_screen.dart';
import 'legal/terms_of_service_screen.dart';
import 'debug_menu_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Gameplay settings (stored locally for now)
  bool _showTimer = true;
  bool _highlightErrors = true;
  bool _autoRemoveNotes = true;

  // Services
  final PurchaseService _purchaseService = PurchaseService();
  final AudioService _audioService = AudioService();
  final ConsentService _consentService = ConsentService();
  final ConfigService _configService = ConfigService();

  // Debug menu unlock
  int _versionTapCount = 0;
  static const int _tapsToUnlock = 7;

  // Purchase state
  bool _isPremium = false;
  bool _isLoading = false;

  // Audio state (loaded from AudioService)
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _vibrationEnabled = true;
  double _masterVolume = 0.8;
  double _effectsVolume = 0.8;
  double _musicVolume = 0.5;

  // Privacy consent state
  bool _personalizedAdsConsent = false;
  bool _analyticsConsent = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    // Load premium status
    _isPremium = _purchaseService.isPremium;

    // Load audio settings
    _soundEnabled = _audioService.soundEnabled;
    _musicEnabled = _audioService.musicEnabled;
    _vibrationEnabled = _audioService.vibrationEnabled;
    _masterVolume = _audioService.masterVolume;
    _effectsVolume = _audioService.effectsVolume;
    _musicVolume = _audioService.musicVolume;

    // Load consent settings
    await _consentService.initialize();
    if (mounted) {
      setState(() {
        _personalizedAdsConsent = _consentService.personalizedAdsConsent;
        _analyticsConsent = _consentService.analyticsConsent;
      });
    }

    // Set up callbacks for purchase events
    _purchaseService.onPurchaseSuccess = () {
      setState(() {
        _isPremium = true;
        _isLoading = false;
      });
      _showSuccessSnackBar('Premium unlocked! Enjoy unlimited access.');
    };

    _purchaseService.onPurchaseError = (error) {
      setState(() => _isLoading = false);
      _showErrorSnackBar(error);
    };

    _purchaseService.onRestoreSuccess = () {
      setState(() {
        _isPremium = _purchaseService.isPremium;
        _isLoading = false;
      });
      if (_isPremium) {
        _showSuccessSnackBar('Premium restored successfully!');
      } else {
        _showErrorSnackBar('No previous purchase found');
      }
    };
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _onVersionTap() {
    // Check if debug menu is enabled via feature flag
    if (!_configService.isFeatureEnabled('debug_menu_enabled')) {
      return;
    }

    setState(() {
      _versionTapCount++;
    });

    if (_versionTapCount >= _tapsToUnlock) {
      // Reset counter and open debug menu
      setState(() {
        _versionTapCount = 0;
      });

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DebugMenuScreen()),
      );
    } else if (_versionTapCount >= 4) {
      // Show hint after 4 taps
      final remaining = _tapsToUnlock - _versionTapCount;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$remaining more taps to unlock debug menu'),
          duration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  Future<void> _handlePurchase() async {
    setState(() => _isLoading = true);
    await _purchaseService.purchasePremium();
  }

  Future<void> _handleRestore() async {
    setState(() => _isLoading = true);
    await _purchaseService.restorePurchases();
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isPremium = _purchaseService.isPremium;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Premium section
          _buildPremiumSection(context, theme),

          const SizedBox(height: 24),

          // Appearance section
          _buildSectionHeader(context, 'Appearance'),
          _buildSettingTile(
            context,
            icon: Icons.dark_mode_rounded,
            title: 'Dark Mode',
            subtitle: 'Use dark theme',
            trailing: Switch(
              value: themeProvider.isDarkMode,
              onChanged: (_) => themeProvider.toggleTheme(),
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0),

          const SizedBox(height: 24),

          // Audio section
          _buildSectionHeader(context, 'Audio'),
          _buildAudioSection(context, theme),

          const SizedBox(height: 24),

          // Gameplay section
          _buildSectionHeader(context, 'Gameplay'),
          _buildSettingTile(
            context,
            icon: Icons.timer_rounded,
            title: 'Show Timer',
            subtitle: 'Display elapsed time during puzzle',
            trailing: Switch(
              value: _showTimer,
              onChanged: (value) => setState(() => _showTimer = value),
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideX(begin: 0.1, end: 0),
          _buildSettingTile(
            context,
            icon: Icons.highlight_rounded,
            title: 'Highlight Errors',
            subtitle: 'Show incorrect entries in Sudoku',
            trailing: Switch(
              value: _highlightErrors,
              onChanged: (value) => setState(() => _highlightErrors = value),
            ),
          ).animate().fadeIn(delay: 250.ms, duration: 400.ms).slideX(begin: 0.1, end: 0),
          _buildSettingTile(
            context,
            icon: Icons.auto_fix_high_rounded,
            title: 'Auto Remove Notes',
            subtitle: 'Remove notes when placing numbers',
            trailing: Switch(
              value: _autoRemoveNotes,
              onChanged: (value) => setState(() => _autoRemoveNotes = value),
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideX(begin: 0.1, end: 0),

          const SizedBox(height: 24),

          // Privacy section
          _buildSectionHeader(context, 'Privacy'),
          _buildPrivacySection(context, theme),

          const SizedBox(height: 24),

          // About section
          _buildSectionHeader(context, 'About'),
          _buildSettingTile(
            context,
            icon: Icons.info_outline_rounded,
            title: 'Version',
            subtitle: _configService.isInitialized
                ? _configService.fullVersion
                : '1.0.0',
            onTap: _onVersionTap,
          ).animate().fadeIn(delay: 450.ms, duration: 400.ms).slideX(begin: 0.1, end: 0),
          _buildSettingTile(
            context,
            icon: Icons.star_outline_rounded,
            title: 'Rate App',
            subtitle: 'Leave a review on the store',
            onTap: () {
              // Open app store review
            },
          ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideX(begin: 0.1, end: 0),
          _buildSettingTile(
            context,
            icon: Icons.mail_outline_rounded,
            title: 'Contact Us',
            subtitle: 'Send feedback or report issues',
            onTap: () {
              FeedbackDialog.show(context);
            },
          ).animate().fadeIn(delay: 550.ms, duration: 400.ms).slideX(begin: 0.1, end: 0),

          const SizedBox(height: 32),

          // Reset button
          Center(
            child: TextButton.icon(
              icon: Icon(
                Icons.refresh_rounded,
                color: theme.colorScheme.error,
              ),
              label: Text(
                'Reset All Progress',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onPressed: () => _showResetDialog(context),
            ),
          ).animate().fadeIn(delay: 650.ms, duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildAudioSection(BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          // Master Volume
          _buildVolumeSlider(
            context,
            theme,
            icon: Icons.volume_up_rounded,
            title: 'Master Volume',
            value: _masterVolume,
            onChanged: (value) async {
              setState(() => _masterVolume = value);
              await _audioService.setMasterVolume(value);
            },
          ),
          Divider(height: 1, color: theme.colorScheme.onSurface.withOpacity(0.1)),

          // Sound Effects Toggle + Volume
          _buildToggleWithVolume(
            context,
            theme,
            icon: Icons.music_note_rounded,
            title: 'Sound Effects',
            enabled: _soundEnabled,
            volume: _effectsVolume,
            onToggle: (value) async {
              setState(() => _soundEnabled = value);
              await _audioService.setSoundEnabled(value);
              if (value) {
                // Play a test sound
                await _audioService.playTap();
              }
            },
            onVolumeChanged: (value) async {
              setState(() => _effectsVolume = value);
              await _audioService.setEffectsVolume(value);
            },
          ),
          Divider(height: 1, color: theme.colorScheme.onSurface.withOpacity(0.1)),

          // Music Toggle + Volume
          _buildToggleWithVolume(
            context,
            theme,
            icon: Icons.library_music_rounded,
            title: 'Music',
            enabled: _musicEnabled,
            volume: _musicVolume,
            onToggle: (value) async {
              setState(() => _musicEnabled = value);
              await _audioService.setMusicEnabled(value);
            },
            onVolumeChanged: (value) async {
              setState(() => _musicVolume = value);
              await _audioService.setMusicVolume(value);
            },
          ),
          Divider(height: 1, color: theme.colorScheme.onSurface.withOpacity(0.1)),

          // Vibration Toggle
          ListTile(
            leading: Icon(
              Icons.vibration_rounded,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            title: Text(
              'Vibration',
              style: theme.textTheme.titleMedium,
            ),
            subtitle: Text(
              'Haptic feedback on interactions',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            trailing: Switch(
              value: _vibrationEnabled,
              onChanged: (value) async {
                setState(() => _vibrationEnabled = value);
                await _audioService.setVibrationEnabled(value);
                if (value) {
                  // Test vibration
                  await _audioService.mediumHaptic();
                }
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildPrivacySection(BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          // Personalized Ads Toggle
          ListTile(
            leading: Icon(
              Icons.ads_click_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            title: Text(
              'Personalized Ads',
              style: theme.textTheme.titleMedium,
            ),
            subtitle: Text(
              'See ads relevant to your interests',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            trailing: Switch(
              value: _personalizedAdsConsent,
              onChanged: (value) async {
                setState(() => _personalizedAdsConsent = value);
                await _consentService.setPersonalizedAdsConsent(value);
              },
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),

          // Analytics Toggle
          ListTile(
            leading: Icon(
              Icons.analytics_outlined,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            title: Text(
              'Usage Analytics',
              style: theme.textTheme.titleMedium,
            ),
            subtitle: Text(
              'Help us improve the app',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            trailing: Switch(
              value: _analyticsConsent,
              onChanged: (value) async {
                setState(() => _analyticsConsent = value);
                await _consentService.setAnalyticsConsent(value);
              },
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),

          // Privacy Policy
          ListTile(
            leading: Icon(
              Icons.privacy_tip_outlined,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            title: Text(
              'Privacy Policy',
              style: theme.textTheme.titleMedium,
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),

          // Terms of Service
          ListTile(
            leading: Icon(
              Icons.description_outlined,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            title: Text(
              'Terms of Service',
              style: theme.textTheme.titleMedium,
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 350.ms, duration: 400.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildVolumeSlider(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      '${(value * 100).round()}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  ),
                  child: Slider(
                    value: value,
                    onChanged: onChanged,
                    activeColor: theme.colorScheme.primary,
                    inactiveColor: theme.colorScheme.onSurface.withOpacity(0.2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleWithVolume(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String title,
    required bool enabled,
    required double volume,
    required ValueChanged<bool> onToggle,
    required ValueChanged<double> onVolumeChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: enabled
                    ? theme.colorScheme.onSurface.withOpacity(0.7)
                    : theme.colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: enabled
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
              Switch(
                value: enabled,
                onChanged: onToggle,
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const SizedBox(width: 40), // Align with icon
                Icon(
                  Icons.volume_down_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    ),
                    child: Slider(
                      value: volume,
                      onChanged: onVolumeChanged,
                      activeColor: theme.colorScheme.primary.withOpacity(0.8),
                      inactiveColor: theme.colorScheme.onSurface.withOpacity(0.15),
                    ),
                  ),
                ),
                Icon(
                  Icons.volume_up_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${(volume * 100).round()}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPremiumSection(BuildContext context, ThemeData theme) {
    if (_isPremium) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFD700).withOpacity(0.2),
              const Color(0xFFFFA500).withOpacity(0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFFD700).withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_rounded,
                color: Color(0xFFFFD700),
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Premium Active',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFFD700),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Unlimited hints, archive access & more',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Upgrade to Premium',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _purchaseService.premiumPriceString,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPremiumFeature(theme, Icons.lightbulb_outline, 'Unlimited hints'),
          _buildPremiumFeature(theme, Icons.history, 'Unlimited archive access'),
          _buildPremiumFeature(theme, Icons.refresh, 'Unlimited retries'),
          _buildPremiumFeature(theme, Icons.block, 'No ads ever'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handlePurchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Unlock Premium',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: _isLoading ? null : _handleRestore,
              child: Text(
                'Restore Purchase',
                style: TextStyle(
                  color: theme.colorScheme.primary.withOpacity(0.8),
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              'One-time purchase. No subscriptions.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildPremiumFeature(ThemeData theme, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: theme.colorScheme.onSurface.withOpacity(0.7),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              )
            : null,
        trailing: trailing ??
            (onTap != null
                ? Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  )
                : null),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Progress'),
        content: const Text(
          'Are you sure you want to reset all your progress? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Progress has been reset'),
                ),
              );
            },
            child: Text(
              'Reset',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
