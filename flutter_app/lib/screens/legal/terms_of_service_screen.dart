import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: December 2025',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              theme,
              '1. Acceptance of Terms',
              'By downloading, installing, or using The Dailies ("the App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, do not use the App.',
            ),
            _buildSection(
              theme,
              '2. Description of Service',
              '''The Dailies is a mobile application that provides daily puzzle games including Sudoku, Killer Sudoku, Crossword, and Word Search puzzles. The service includes:

• Free daily puzzles
• Archive access to past puzzles (token-based or premium)
• Optional premium upgrade for ad-free experience
• Social features including friends and statistics''',
            ),
            _buildSection(
              theme,
              '3. User Accounts',
              '''To access certain features, you may create an account. You agree to:

• Provide accurate and complete information
• Maintain the security of your password
• Notify us immediately of any unauthorized access
• Accept responsibility for all activities under your account

We reserve the right to suspend or terminate accounts that violate these Terms.''',
            ),
            _buildSection(
              theme,
              '4. User Conduct',
              '''You agree not to:

• Use the App for any illegal purpose
• Attempt to gain unauthorized access to our systems
• Interfere with or disrupt the App or servers
• Use automated scripts or bots to interact with the App
• Exploit bugs or glitches for unfair advantage
• Harass, abuse, or harm other users
• Impersonate any person or entity
• Share your account credentials with others''',
            ),
            _buildSection(
              theme,
              '5. Intellectual Property',
              '''All content in the App, including but not limited to puzzles, graphics, text, logos, and software, is the property of The Dailies or its licensors and is protected by copyright and other intellectual property laws.

You may not copy, modify, distribute, sell, or lease any part of our App or included content without our express written permission.''',
            ),
            _buildSection(
              theme,
              '6. In-App Purchases',
              '''The App offers optional in-app purchases:

• Premium Upgrade: A one-time purchase that removes advertisements and provides unlimited access to features

All purchases are processed through the Apple App Store or Google Play Store. Refunds are subject to the respective store's refund policy.

Prices are subject to change. We will provide notice of price changes within the App.''',
            ),
            _buildSection(
              theme,
              '7. Advertisements',
              '''The free version of the App displays advertisements provided by third-party ad networks. By using the free version, you agree to view these advertisements.

You may remove advertisements by purchasing the Premium Upgrade.

We are not responsible for the content of third-party advertisements.''',
            ),
            _buildSection(
              theme,
              '8. Virtual Currency (Tokens)',
              '''The App uses virtual tokens for accessing archive puzzles:

• Tokens have no real-world monetary value
• Tokens cannot be exchanged for cash
• Tokens are non-transferable between accounts
• We reserve the right to modify the token system

Token balances may be reset or modified if we detect abuse or fraudulent activity.''',
            ),
            _buildSection(
              theme,
              '9. Privacy',
              'Your use of the App is also governed by our Privacy Policy, which is incorporated into these Terms by reference. Please review our Privacy Policy to understand our practices.',
            ),
            _buildSection(
              theme,
              '10. Disclaimers',
              '''THE APP IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED.

We do not guarantee that:
• The App will be available at all times
• The App will be error-free
• Puzzles will be free of errors
• Your data will never be lost

We are not liable for any damages arising from your use of the App.''',
            ),
            _buildSection(
              theme,
              '11. Limitation of Liability',
              '''TO THE MAXIMUM EXTENT PERMITTED BY LAW, THE DAILIES SHALL NOT BE LIABLE FOR:

• Any indirect, incidental, special, or consequential damages
• Loss of data, profits, or goodwill
• Service interruptions or errors
• Actions of third parties

Our total liability shall not exceed the amount you paid for the App in the past 12 months.''',
            ),
            _buildSection(
              theme,
              '12. Indemnification',
              'You agree to indemnify and hold harmless The Dailies, its affiliates, and their respective officers, directors, employees, and agents from any claims, damages, or expenses arising from your use of the App or violation of these Terms.',
            ),
            _buildSection(
              theme,
              '13. Modifications to Service',
              '''We reserve the right to:

• Modify or discontinue any feature of the App
• Change puzzle content or difficulty
• Update these Terms at any time
• Suspend or terminate your access

Continued use of the App after changes constitutes acceptance of the modified Terms.''',
            ),
            _buildSection(
              theme,
              '14. Termination',
              '''We may terminate or suspend your access to the App immediately, without prior notice, for any reason, including:

• Violation of these Terms
• Fraudulent or illegal activity
• Extended periods of inactivity
• At our sole discretion

Upon termination, your right to use the App ceases immediately.''',
            ),
            _buildSection(
              theme,
              '15. Governing Law',
              'These Terms shall be governed by and construed in accordance with the laws of [Your Jurisdiction], without regard to its conflict of law provisions.',
            ),
            _buildSection(
              theme,
              '16. Dispute Resolution',
              'Any disputes arising from these Terms or your use of the App shall be resolved through binding arbitration in accordance with the rules of [Arbitration Organization], except where prohibited by law.',
            ),
            _buildSection(
              theme,
              '17. Severability',
              'If any provision of these Terms is found to be unenforceable, the remaining provisions shall continue in full force and effect.',
            ),
            _buildSection(
              theme,
              '18. Contact Information',
              '''If you have any questions about these Terms, please contact us:

Email: legal@thedailies.app

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
