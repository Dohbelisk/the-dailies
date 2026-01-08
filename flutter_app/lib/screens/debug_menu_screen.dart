import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/remote_config_service.dart';
import '../services/firebase_service.dart';
import '../services/game_state_service.dart';
import '../services/api_service.dart';
import '../config/environment.dart';
import '../models/game_models.dart';
import '../widgets/mobius_grid.dart';

/// Hidden debug menu for developers and testers
class DebugMenuScreen extends StatefulWidget {
  const DebugMenuScreen({super.key});

  @override
  State<DebugMenuScreen> createState() => _DebugMenuScreenState();
}

class _DebugMenuScreenState extends State<DebugMenuScreen> {
  final RemoteConfigService _configService = RemoteConfigService();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Menu'),
        backgroundColor: theme.colorScheme.errorContainer,
        foregroundColor: theme.colorScheme.onErrorContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshConfig,
            tooltip: 'Refresh Config',
          ),
        ],
      ),
      body: _isRefreshing
          ? const Center(child: CircularProgressIndicator())
          : ListenableBuilder(
              listenable: _configService,
              builder: (context, _) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSuperAccountSection(theme),
                    const SizedBox(height: 24),
                    _buildVersionSection(theme),
                    const SizedBox(height: 24),
                    _buildFirebaseSection(theme),
                    const SizedBox(height: 24),
                    _buildEnvironmentSection(theme),
                    const SizedBox(height: 24),
                    _buildFeatureFlagsSection(theme),
                    const SizedBox(height: 24),
                    _buildInDevGamesSection(theme),
                    const SizedBox(height: 24),
                    _buildActionsSection(theme),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildSuperAccountSection(ThemeData theme) {
    return _buildSection(
      theme,
      title: 'Super Account',
      icon: Icons.star,
      children: [
        // Super Account Toggle
        SwitchListTile(
          title: const Text('Enable Super Account'),
          subtitle: Text(
            _configService.isSuperAccount
                ? 'Unlimited tokens, future puzzles, reset access'
                : 'Normal account mode',
          ),
          value: _configService.isSuperAccount,
          activeTrackColor: Colors.amber.withValues(alpha: 0.5),
          onChanged: (value) async {
            await _configService.setSuperAccount(value);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(value
                      ? '⭐ Super Account enabled!'
                      : 'Super Account disabled'),
                ),
              );
            }
          },
        ),
        const Divider(),
        // Super Account Features (only enabled when super account is on)
        if (_configService.isSuperAccount) ...[
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Reset All Progress'),
            subtitle: const Text('Clear all game states and completions'),
            onTap: _resetAllProgress,
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month, color: Colors.blue),
            title: const Text('Test Tomorrow\'s Puzzles'),
            subtitle: const Text('Preview puzzles for the next day'),
            onTap: () => _testFuturePuzzles(1),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today, color: Colors.purple),
            title: const Text('Test Custom Date'),
            subtitle: const Text('Pick any date to test puzzles'),
            onTap: _testCustomDatePuzzles,
          ),
        ] else
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Enable Super Account to access reset progress, future puzzle testing, and unlimited tokens.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVersionSection(ThemeData theme) {
    final config = _configService.appConfig;
    final status = _configService.checkVersionStatus();

    Color statusColor;
    String statusText;
    switch (status) {
      case VersionStatus.upToDate:
        statusColor = Colors.green;
        statusText = 'Up to Date';
        break;
      case VersionStatus.updateAvailable:
        statusColor = Colors.orange;
        statusText = 'Update Available';
        break;
      case VersionStatus.forceUpdate:
        statusColor = Colors.red;
        statusText = 'Force Update Required';
        break;
    }

    return _buildSection(
      theme,
      title: 'Version Info',
      icon: Icons.info_outline,
      children: [
        _buildInfoRow('Current Version', _configService.currentVersion),
        _buildInfoRow('Build Number', _configService.buildNumber),
        _buildInfoRow('Full Version', _configService.fullVersion),
        const Divider(),
        _buildInfoRow('Latest Version', config.latestVersion),
        _buildInfoRow('Min Version', config.minVersion),
        _buildInfoRow(
          'Status',
          statusText,
          valueColor: statusColor,
        ),
        if (config.maintenanceMode)
          _buildInfoRow(
            'Maintenance Mode',
            'ENABLED',
            valueColor: Colors.red,
          ),
      ],
    );
  }

  Widget _buildFirebaseSection(ThemeData theme) {
    final lastFetch = _configService.lastFetch;
    final fcmToken = _firebaseService.fcmToken;

    return _buildSection(
      theme,
      title: 'Firebase',
      icon: Icons.cloud,
      children: [
        _buildInfoRow(
          'Firebase Core',
          _firebaseService.isInitialized ? 'Initialized' : 'Not Initialized',
          valueColor: _firebaseService.isInitialized ? Colors.green : Colors.red,
        ),
        _buildInfoRow(
          'Crashlytics',
          _firebaseService.crashlyticsEnabled ? 'Enabled' : 'Disabled',
          valueColor: _firebaseService.crashlyticsEnabled ? Colors.green : Colors.orange,
        ),
        _buildInfoRow(
          'Remote Config',
          _configService.isInitialized ? 'Initialized' : 'Not Initialized',
          valueColor: _configService.isInitialized ? Colors.green : Colors.red,
        ),
        if (lastFetch != null)
          _buildInfoRow(
            'Last Fetch',
            '${lastFetch.hour}:${lastFetch.minute.toString().padLeft(2, '0')}',
          ),
        const Divider(),
        _buildInfoRow(
          'FCM Token',
          fcmToken != null ? '${fcmToken.substring(0, 20)}...' : 'Not Available',
          copyable: fcmToken != null,
        ),
        if (fcmToken != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyToClipboard(fcmToken),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy Full FCM Token'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Use this token to send test notifications from the backend or Firebase Console.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEnvironmentSection(ThemeData theme) {
    return _buildSection(
      theme,
      title: 'Environment',
      icon: Icons.settings,
      children: [
        _buildInfoRow('Environment', Environment.environment),
        _buildInfoRow('API URL', Environment.apiUrl, copyable: true),
        _buildInfoRow('Is Production', Environment.isProduction.toString()),
      ],
    );
  }

  Widget _buildFeatureFlagsSection(ThemeData theme) {
    final allStatuses = _configService.allFeatureStatuses..sort((a, b) => a.key.compareTo(b.key));

    return _buildSection(
      theme,
      title: 'Feature Flags',
      icon: Icons.flag,
      trailing: TextButton(
        onPressed: _clearAllOverrides,
        child: const Text('Clear Overrides'),
      ),
      children: [
        if (allStatuses.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No feature flags loaded'),
          )
        else
          ...allStatuses.map((status) => _buildFlagRow(status, theme)),
      ],
    );
  }

  Widget _buildFlagRow(FeatureStatus status, ThemeData theme) {
    final displayName = status.key.replaceFirst('feature_', '');

    // Determine colors based on status
    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;

    if (status.hasOverride) {
      statusColor = theme.colorScheme.tertiary;
      statusBgColor = theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3);
      statusIcon = status.enabled ? Icons.check : Icons.close;
    } else if (status.isVersionLocked) {
      statusColor = Colors.orange;
      statusBgColor = Colors.orange.withValues(alpha: 0.1);
      statusIcon = Icons.lock;
    } else if (status.enabled) {
      statusColor = Colors.green;
      statusBgColor = Colors.green.withValues(alpha: 0.1);
      statusIcon = Icons.check;
    } else {
      statusColor = Colors.red;
      statusBgColor = Colors.red.withValues(alpha: 0.1);
      statusIcon = Icons.close;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: statusBgColor,
        borderRadius: BorderRadius.circular(8),
        border: status.hasOverride
            ? Border.all(color: theme.colorScheme.tertiary, width: 2)
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status.reason,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: statusColor,
                  ),
                ),
                if (status.minVersion.isNotEmpty && status.minVersion != '0.0.0' && !status.hasOverride)
                  Text(
                    'Min version: ${status.minVersion}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
          // Three-state toggle: null (use server), true, false
          PopupMenuButton<bool?>(
            initialValue: status.override,
            onSelected: (value) => _setFlagOverride(status.key, value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: null,
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud,
                      size: 18,
                      color: !status.hasOverride ? theme.colorScheme.primary : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        status.minVersion.isEmpty || status.minVersion == '0.0.0'
                            ? 'Use Server (disabled)'
                            : 'Use Server (v${status.minVersion}+)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: true,
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 18,
                      color: status.override == true ? Colors.green : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Force Enable'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: false,
                child: Row(
                  children: [
                    Icon(
                      Icons.cancel,
                      size: 18,
                      color: status.override == false ? Colors.red : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Force Disable'),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: statusColor,
                  width: status.hasOverride ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 16, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    status.enabled ? 'ON' : 'OFF',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (status.hasOverride) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.edit,
                      size: 12,
                      color: theme.colorScheme.tertiary,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInDevGamesSection(ThemeData theme) {
    return _buildSection(
      theme,
      title: 'In-Development Games',
      icon: Icons.science,
      children: [
        ListTile(
          leading: const Icon(Icons.all_inclusive, color: Colors.deepPurple),
          title: const Text('Möbius'),
          subtitle: const Text('Impossible geometry puzzle prototype'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: const Text(
              'WIP',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MobiusTestScreen()),
            );
          },
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'These games are under development and not yet available to users. '
            'Use this section to test new puzzle types before release.',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsSection(ThemeData theme) {
    return _buildSection(
      theme,
      title: 'Debug Actions',
      icon: Icons.build,
      children: [
        ListTile(
          leading: const Icon(Icons.refresh),
          title: const Text('Refresh Config'),
          subtitle: const Text('Fetch latest config from server'),
          onTap: _refreshConfig,
        ),
        ListTile(
          leading: const Icon(Icons.delete_sweep),
          title: const Text('Clear All Overrides'),
          subtitle: const Text('Reset all feature flags to server values'),
          onTap: _clearAllOverrides,
        ),
        ListTile(
          leading: const Icon(Icons.bug_report),
          title: const Text('Trigger Force Update Dialog'),
          subtitle: const Text('Test the force update flow'),
          onTap: () => _testVersionDialog(VersionStatus.forceUpdate),
        ),
        ListTile(
          leading: const Icon(Icons.update),
          title: const Text('Trigger Update Available Dialog'),
          subtitle: const Text('Test the update available flow'),
          onTap: () => _testVersionDialog(VersionStatus.updateAvailable),
        ),
        ListTile(
          leading: const Icon(Icons.copy),
          title: const Text('Copy Debug Info'),
          subtitle: const Text('Copy diagnostic info to clipboard'),
          onTap: _copyDebugInfo,
        ),
      ],
    );
  }

  Widget _buildSection(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor, bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: copyable ? () => _copyToClipboard(value) : null,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: valueColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (copyable)
                    Icon(Icons.copy, size: 14, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetAllProgress() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Progress'),
        content: const Text(
          'This will clear all your game progress, including:\n\n'
          '• All in-progress games\n'
          '• All completion records\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final cleared = await GameStateService.clearAllProgress();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cleared $cleared saved game states')),
        );
      }
    }
  }

  Future<void> _testFuturePuzzles(int daysAhead) async {
    final targetDate = DateTime.now().add(Duration(days: daysAhead));
    await _showPuzzlesForDate(targetDate);
  }

  Future<void> _testCustomDatePuzzles() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select a date to test puzzles',
    );

    if (selectedDate != null) {
      await _showPuzzlesForDate(selectedDate);
    }
  }

  Future<void> _showPuzzlesForDate(DateTime date) async {
    setState(() => _isRefreshing = true);

    final apiService = ApiService();
    final puzzles = await apiService.getPuzzlesForDate(date);

    setState(() => _isRefreshing = false);

    if (!mounted) return;

    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Puzzles for $dateStr'),
        content: SizedBox(
          width: double.maxFinite,
          child: puzzles.isEmpty
              ? const Text('No puzzles found for this date.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: puzzles.length,
                  itemBuilder: (context, index) {
                    final puzzle = puzzles[index];
                    return ListTile(
                      leading: Icon(
                        _getGameTypeIcon(puzzle.gameType),
                        color: puzzle.isActive ? Colors.green : Colors.grey,
                      ),
                      title: Text(puzzle.gameType.displayName),
                      subtitle: Text(
                        '${puzzle.difficulty.displayName} • ${puzzle.isActive ? "Active" : "Inactive"}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () {
                          Navigator.pop(context);
                          _launchPuzzle(puzzle);
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  IconData _getGameTypeIcon(GameType gameType) {
    switch (gameType) {
      case GameType.sudoku:
        return Icons.grid_3x3;
      case GameType.killerSudoku:
        return Icons.grid_4x4;
      case GameType.crossword:
        return Icons.abc;
      case GameType.wordSearch:
        return Icons.search;
      case GameType.wordForge:
        return Icons.hexagon;
      case GameType.nonogram:
        return Icons.apps;
      case GameType.numberTarget:
        return Icons.calculate;
      case GameType.ballSort:
        return Icons.science;
      case GameType.pipes:
        return Icons.linear_scale;
      case GameType.lightsOut:
        return Icons.lightbulb;
      case GameType.wordLadder:
        return Icons.stairs;
      case GameType.connections:
        return Icons.group_work;
      case GameType.mathora:
        return Icons.functions;
      case GameType.mobius:
        return Icons.all_inclusive;
    }
  }

  void _launchPuzzle(DailyPuzzle puzzle) {
    Navigator.pushNamed(
      context,
      '/game',
      arguments: puzzle,
    );
  }

  Future<void> _refreshConfig() async {
    setState(() => _isRefreshing = true);
    await _configService.refreshConfig();
    setState(() => _isRefreshing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Config refreshed')),
      );
    }
  }

  Future<void> _setFlagOverride(String key, bool? value) async {
    await _configService.setFlagOverride(key, value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value == null
              ? 'Using server value for $key'
              : 'Override set for $key: $value'),
        ),
      );
    }
  }

  Future<void> _clearAllOverrides() async {
    await _configService.clearAllOverrides();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All overrides cleared')),
      );
    }
  }

  void _testVersionDialog(VersionStatus status) {
    final config = _configService.appConfig;

    showDialog(
      context: context,
      barrierDismissible: status != VersionStatus.forceUpdate,
      builder: (context) {
        if (status == VersionStatus.forceUpdate) {
          return AlertDialog(
            title: const Text('Test: Force Update'),
            content: const Text('This is a test of the force update dialog. In production, this would not be dismissable.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close Test'),
              ),
            ],
          );
        } else {
          return AlertDialog(
            title: const Text('Test: Update Available'),
            content: Text('Current: ${_configService.currentVersion}\nLatest: ${config.latestVersion}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Later'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Update'),
              ),
            ],
          );
        }
      },
    );
  }

  Future<void> _copyDebugInfo() async {
    final config = _configService.appConfig;
    final statuses = _configService.allFeatureStatuses;

    final info = '''
Debug Info - The Dailies
========================
Version: ${_configService.fullVersion}
Environment: ${Environment.environment}
API URL: ${Environment.apiUrl}

Firebase:
- Core Initialized: ${_firebaseService.isInitialized}
- Crashlytics: ${_firebaseService.crashlyticsEnabled ? 'Enabled' : 'Disabled'}
- Remote Config: ${_configService.isInitialized ? 'Initialized' : 'Not Initialized'}
- FCM Token: ${_firebaseService.fcmToken ?? 'N/A'}

Remote Config:
- Latest Version: ${config.latestVersion}
- Min Version: ${config.minVersion}
- Maintenance Mode: ${config.maintenanceMode}

Feature Flags (version-based):
${statuses.map((s) => '- ${s.key}: ${s.enabled ? "ON" : "OFF"} (${s.reason})').join('\n')}

Overrides:
${statuses.where((s) => s.hasOverride).map((s) => '- ${s.key}: ${s.override}').join('\n')}
''';

    await Clipboard.setData(ClipboardData(text: info));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debug info copied to clipboard')),
      );
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied: $text')),
    );
  }
}
