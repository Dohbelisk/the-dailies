import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: December 2025',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              theme,
              'Introduction',
              'Welcome to The Dailies. We respect your privacy and are committed to protecting your personal data. This privacy policy explains how we collect, use, and safeguard your information when you use our mobile application.',
            ),
            _buildSection(
              theme,
              'Information We Collect',
              '''We collect the following types of information:

• Account Information: When you create an account, we collect your email address, username, and password (stored securely using encryption).

• Game Data: We store your puzzle progress, scores, completion times, and statistics to provide game functionality and track your achievements.

• Device Information: We may collect device identifiers and technical information to improve app performance and provide support.

• Usage Data: We collect information about how you interact with the app, including puzzles played, features used, and time spent in the app.''',
            ),
            _buildSection(
              theme,
              'How We Use Your Information',
              '''We use your information to:

• Provide and maintain The Dailies service
• Save your game progress and statistics
• Enable social features like the friends system
• Send important notifications about your account
• Improve our app and develop new features
• Detect and prevent fraud or abuse''',
            ),
            _buildSection(
              theme,
              'Advertising',
              '''The Dailies uses Google AdMob to display advertisements. AdMob may collect and use data to provide personalized ads based on your interests. This data may include:

• Device identifiers
• IP address
• General location (country/region)
• App usage information

You can opt out of personalized advertising in the app settings. If you opt out, you will still see ads, but they will not be personalized to your interests.

Premium users do not see any advertisements.''',
            ),
            _buildSection(
              theme,
              'Data Storage and Security',
              '''Your data is stored securely on our servers. We implement appropriate technical and organizational measures to protect your personal data against unauthorized access, alteration, disclosure, or destruction.

Account passwords are encrypted using industry-standard bcrypt hashing and are never stored in plain text.''',
            ),
            _buildSection(
              theme,
              'Data Retention',
              '''We retain your personal data for as long as your account is active. If you delete your account, we will delete your personal data within 30 days, except where we are required to retain it for legal purposes.

Game statistics may be retained in anonymized form for analytics purposes.''',
            ),
            _buildSection(
              theme,
              'Your Rights (GDPR)',
              '''If you are located in the European Economic Area (EEA), you have the following rights:

• Right to Access: Request a copy of your personal data
• Right to Rectification: Request correction of inaccurate data
• Right to Erasure: Request deletion of your personal data
• Right to Restrict Processing: Request limitation of data processing
• Right to Data Portability: Receive your data in a portable format
• Right to Object: Object to processing of your personal data
• Right to Withdraw Consent: Withdraw consent at any time

To exercise these rights, please contact us at privacy@thedailies.app.''',
            ),
            _buildSection(
              theme,
              'Children\'s Privacy',
              'The Dailies is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us.',
            ),
            _buildSection(
              theme,
              'Third-Party Services',
              '''We use the following third-party services:

• Google AdMob: For displaying advertisements
• Google Play Services / Apple App Store: For in-app purchases
• MongoDB Atlas: For secure data storage

These services have their own privacy policies governing their use of your data.''',
            ),
            _buildSection(
              theme,
              'Changes to This Policy',
              'We may update this privacy policy from time to time. We will notify you of any changes by posting the new policy in the app and updating the "Last updated" date. You are advised to review this policy periodically.',
            ),
            _buildSection(
              theme,
              'Contact Us',
              '''If you have any questions about this Privacy Policy, please contact us:

Email: privacy@thedailies.app

The Dailies
[Your Company Address]
[City, State/Country, Postal Code]''',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
