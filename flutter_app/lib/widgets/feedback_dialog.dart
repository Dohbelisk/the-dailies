import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/game_models.dart';
import '../models/feedback_models.dart';
import '../services/api_service.dart';

class FeedbackDialog extends StatefulWidget {
  /// Optional puzzle context for in-game submissions
  final String? puzzleId;
  final GameType? gameType;
  final Difficulty? difficulty;
  final DateTime? puzzleDate;

  /// Pre-select feedback type (useful for specific buttons like "Report Issue")
  final FeedbackType? initialType;

  const FeedbackDialog({
    super.key,
    this.puzzleId,
    this.gameType,
    this.difficulty,
    this.puzzleDate,
    this.initialType,
  });

  /// Static show method for convenience
  static Future<bool?> show(
    BuildContext context, {
    String? puzzleId,
    GameType? gameType,
    Difficulty? difficulty,
    DateTime? puzzleDate,
    FeedbackType? initialType,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => FeedbackDialog(
        puzzleId: puzzleId,
        gameType: gameType,
        difficulty: difficulty,
        puzzleDate: puzzleDate,
        initialType: initialType,
      ),
    );
  }

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  late FeedbackType _selectedType;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  bool get _hasGameContext => widget.puzzleId != null;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? FeedbackType.general;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  List<FeedbackType> get _availableTypes {
    // Only show puzzle-related types when there's game context
    if (_hasGameContext) {
      return FeedbackType.values;
    }
    return FeedbackType.values
        .where((type) => type != FeedbackType.puzzleMistake)
        .toList();
  }

  IconData _getTypeIcon(FeedbackType type) {
    switch (type) {
      case FeedbackType.bugReport:
        return Icons.bug_report_outlined;
      case FeedbackType.newGameSuggestion:
        return Icons.lightbulb_outline;
      case FeedbackType.puzzleSuggestion:
        return Icons.extension_outlined;
      case FeedbackType.puzzleMistake:
        return Icons.error_outline;
      case FeedbackType.general:
        return Icons.chat_bubble_outline;
    }
  }

  Future<String> _getDeviceInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceInfo = DeviceInfoPlugin();

      String platform = Platform.operatingSystem;
      String osVersion = Platform.operatingSystemVersion;
      String appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return '${androidInfo.model} | Android ${androidInfo.version.release} | App v$appVersion';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return '${iosInfo.model} | iOS ${iosInfo.systemVersion} | App v$appVersion';
      }

      return '$platform $osVersion | App v$appVersion';
    } catch (e) {
      return 'Unknown device';
    }
  }

  Future<void> _submitFeedback() async {
    if (_messageController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a message';
      });
      return;
    }

    if (_emailController.text.isNotEmpty &&
        !_isValidEmail(_emailController.text)) {
      setState(() {
        _errorMessage = 'Please enter a valid email address';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final deviceInfo = await _getDeviceInfo();
      final apiService = context.read<ApiService>();

      final feedback = FeedbackSubmission(
        type: _selectedType,
        message: _messageController.text.trim(),
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        puzzleId: widget.puzzleId,
        gameType: widget.gameType,
        difficulty: widget.difficulty,
        puzzleDate: widget.puzzleDate,
        deviceInfo: deviceInfo,
      );

      final success = await apiService.submitFeedback(feedback);

      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thank you for your feedback!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            _errorMessage = 'Failed to submit feedback. Please try again.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.feedback_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Send Feedback',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Feedback Type Selection
              Text(
                'What type of feedback?',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableTypes.map((type) {
                  final isSelected = type == _selectedType;
                  return ChoiceChip(
                    selected: isSelected,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getTypeIcon(type),
                          size: 18,
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                        ),
                        const SizedBox(width: 8),
                        Text(type.displayName),
                      ],
                    ),
                    selectedColor: theme.colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedType = type;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Message Input
              Text(
                'Your message',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _messageController,
                maxLines: 5,
                maxLength: 2000,
                decoration: InputDecoration(
                  hintText: _getPlaceholderText(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
              ),
              const SizedBox(height: 16),

              // Email Input (Optional)
              Text(
                'Email (optional)',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Provide your email if you\'d like us to follow up',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'your@email.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),

              // Game Context Info (if available)
              if (_hasGameContext) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.videogame_asset_outlined,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Feedback about:',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              '${widget.gameType?.displayName ?? 'Puzzle'} - ${widget.difficulty?.displayName ?? ''}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Error Message
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitFeedback,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Submit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPlaceholderText() {
    switch (_selectedType) {
      case FeedbackType.bugReport:
        return 'Describe the bug and how to reproduce it...';
      case FeedbackType.newGameSuggestion:
        return 'What type of game would you like to see?';
      case FeedbackType.puzzleSuggestion:
        return 'Describe your puzzle idea...';
      case FeedbackType.puzzleMistake:
        return 'What\'s wrong with this puzzle? (wrong clue, incorrect solution, etc.)';
      case FeedbackType.general:
        return 'Share your thoughts, ideas, or feedback...';
    }
  }
}
