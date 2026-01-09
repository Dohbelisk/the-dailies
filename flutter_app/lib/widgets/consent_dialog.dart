import 'package:flutter/material.dart';
import '../screens/legal/privacy_policy_screen.dart';
import '../screens/legal/terms_of_service_screen.dart';
import '../services/consent_service.dart';

/// GDPR-compliant consent dialog shown on first app launch.
///
/// Requests consent for:
/// - Terms of Service acceptance (required)
/// - Personalized advertising (optional)
/// - Analytics data collection (optional)
class ConsentDialog extends StatefulWidget {
  final VoidCallback onConsentGiven;

  const ConsentDialog({
    super.key,
    required this.onConsentGiven,
  });

  /// Show the consent dialog as a modal bottom sheet
  static Future<void> show(BuildContext context, {required VoidCallback onConsentGiven}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => ConsentDialog(onConsentGiven: onConsentGiven),
    );
  }

  @override
  State<ConsentDialog> createState() => _ConsentDialogState();
}

class _ConsentDialogState extends State<ConsentDialog> {
  bool _termsAccepted = false;
  bool _personalizedAds = true; // Default to true, but user can opt out
  bool _analytics = true; // Default to true, but user can opt out
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.privacy_tip_outlined,
                        size: 32,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your Privacy Matters',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Before you start playing, please review and accept our terms and choose your privacy preferences.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Terms of Service (Required)
                  _buildConsentCard(
                    theme,
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    subtitle: 'Required to use the app',
                    isRequired: true,
                    value: _termsAccepted,
                    onChanged: (value) => setState(() => _termsAccepted = value ?? false),
                    onTapDetails: () => _openTermsOfService(context),
                  ),
                  const SizedBox(height: 12),

                  // Personalized Ads (Optional)
                  _buildConsentCard(
                    theme,
                    icon: Icons.ads_click_outlined,
                    title: 'Personalized Ads',
                    subtitle: 'See ads relevant to your interests',
                    isRequired: false,
                    value: _personalizedAds,
                    onChanged: (value) => setState(() => _personalizedAds = value ?? false),
                    onTapDetails: null,
                  ),
                  const SizedBox(height: 12),

                  // Analytics (Optional)
                  _buildConsentCard(
                    theme,
                    icon: Icons.analytics_outlined,
                    title: 'Usage Analytics',
                    subtitle: 'Help us improve the app',
                    isRequired: false,
                    value: _analytics,
                    onChanged: (value) => setState(() => _analytics = value ?? false),
                    onTapDetails: null,
                  ),
                  const SizedBox(height: 24),

                  // Privacy Policy Link
                  Center(
                    child: TextButton.icon(
                      onPressed: () => _openPrivacyPolicy(context),
                      icon: Icon(
                        Icons.shield_outlined,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      label: Text(
                        'Read our Privacy Policy',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: _isLoading ? null : _acceptEssentialOnly,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        ),
                        child: const Text('Essentials'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (_termsAccepted && !_isLoading) ? _acceptAll : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Accept & Continue'),
                        ),
                      ),
                    ],
                  ),

                  if (!_termsAccepted)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Please accept the Terms of Service to continue',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentCard(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isRequired,
    required bool value,
    required ValueChanged<bool?> onChanged,
    VoidCallback? onTapDetails,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: isRequired ? onChanged : onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        title: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isRequired)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Required',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
              if (onTapDetails != null)
                TextButton(
                  onPressed: onTapDetails,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'View',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPrivacyPolicy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
    );
  }

  void _openTermsOfService(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
    );
  }

  Future<void> _acceptEssentialOnly() async {
    if (!_termsAccepted) {
      // Show a snackbar indicating terms must be accepted
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms of Service first'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    await ConsentService().saveConsent(
      personalizedAds: false,
      analytics: false,
      termsAccepted: true,
    );

    if (mounted) {
      Navigator.pop(context);
      widget.onConsentGiven();
    }
  }

  Future<void> _acceptAll() async {
    setState(() => _isLoading = true);

    await ConsentService().saveConsent(
      personalizedAds: _personalizedAds,
      analytics: _analytics,
      termsAccepted: _termsAccepted,
    );

    if (mounted) {
      Navigator.pop(context);
      widget.onConsentGiven();
    }
  }
}
