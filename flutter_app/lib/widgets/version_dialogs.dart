import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/config_service.dart';

/// Dismissable dialog shown when an update is available
class UpdateAvailableDialog extends StatelessWidget {
  final AppConfig config;
  final String currentVersion;
  final VoidCallback? onDismiss;

  const UpdateAvailableDialog({
    super.key,
    required this.config,
    required this.currentVersion,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.system_update, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          const Text('Update Available'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            config.updateMessage.isNotEmpty
                ? config.updateMessage
                : 'A new version of the app is available.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current', style: theme.textTheme.labelSmall),
                    Text('v$currentVersion', style: theme.textTheme.titleMedium),
                  ],
                ),
                Icon(Icons.arrow_forward, color: theme.colorScheme.primary),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Latest', style: theme.textTheme.labelSmall),
                    Text(
                      'v${config.latestVersion}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDismiss?.call();
          },
          child: const Text('Later'),
        ),
        FilledButton.icon(
          onPressed: () => _openStore(context),
          icon: const Icon(Icons.download),
          label: const Text('Update'),
        ),
      ],
    );
  }

  Future<void> _openStore(BuildContext context) async {
    if (config.updateUrl.isNotEmpty) {
      final uri = Uri.parse(config.updateUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

/// Non-dismissable dialog shown when force update is required
class ForceUpdateDialog extends StatelessWidget {
  final AppConfig config;
  final String currentVersion;

  const ForceUpdateDialog({
    super.key,
    required this.config,
    required this.currentVersion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false, // Prevent back button dismiss
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            const Text('Update Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              config.forceUpdateMessage.isNotEmpty
                  ? config.forceUpdateMessage
                  : 'This version is no longer supported. Please update to continue using the app.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.onErrorContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your version: v$currentVersion',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                        Text(
                          'Minimum required: v${config.minVersion}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton.icon(
            onPressed: () => _openStore(context),
            icon: const Icon(Icons.download),
            label: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _openStore(BuildContext context) async {
    if (config.updateUrl.isNotEmpty) {
      final uri = Uri.parse(config.updateUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }
}

/// Maintenance mode dialog
class MaintenanceDialog extends StatelessWidget {
  final AppConfig config;

  const MaintenanceDialog({
    super.key,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.construction, color: theme.colorScheme.tertiary),
            const SizedBox(width: 12),
            const Text('Maintenance'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.engineering, size: 64),
            const SizedBox(height: 16),
            Text(
              config.maintenanceMessage.isNotEmpty
                  ? config.maintenanceMessage
                  : 'We are currently performing maintenance. Please try again later.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Refresh to check if maintenance is over
              ConfigService().refreshConfig();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// Helper function to show version check dialogs
Future<void> showVersionCheckDialog(BuildContext context) async {
  final configService = ConfigService();
  final status = configService.checkVersionStatus();
  final config = configService.appConfig;

  // Check maintenance mode first
  if (config.maintenanceMode) {
    if (context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => MaintenanceDialog(config: config),
      );
    }
    return;
  }

  switch (status) {
    case VersionStatus.forceUpdate:
      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => ForceUpdateDialog(
            config: config,
            currentVersion: configService.currentVersion,
          ),
        );
      }
      break;

    case VersionStatus.updateAvailable:
      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: true,
          builder: (_) => UpdateAvailableDialog(
            config: config,
            currentVersion: configService.currentVersion,
          ),
        );
      }
      break;

    case VersionStatus.upToDate:
      // No dialog needed
      break;
  }
}
