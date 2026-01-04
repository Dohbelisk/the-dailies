import 'package:flutter/material.dart';

import '../services/shake_detector_service.dart';
import '../models/feedback_models.dart';
import 'feedback_dialog.dart';

/// Wrapper widget that listens for device shakes and shows the bug report dialog.
///
/// Wrap this around your MaterialApp or top-level widget to enable
/// shake-to-report functionality throughout the app.
class ShakeFeedbackWrapper extends StatefulWidget {
  final Widget child;

  /// Whether shake detection is enabled
  final bool enabled;

  const ShakeFeedbackWrapper({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<ShakeFeedbackWrapper> createState() => _ShakeFeedbackWrapperState();
}

class _ShakeFeedbackWrapperState extends State<ShakeFeedbackWrapper>
    with WidgetsBindingObserver {
  final ShakeDetectorService _shakeDetector = ShakeDetectorService();
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupShakeDetector();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shakeDetector.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause shake detection when app is in background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _shakeDetector.isEnabled = false;
    } else if (state == AppLifecycleState.resumed) {
      _shakeDetector.isEnabled = widget.enabled;
    }
  }

  @override
  void didUpdateWidget(ShakeFeedbackWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      _shakeDetector.isEnabled = widget.enabled;
    }
  }

  void _setupShakeDetector() {
    _shakeDetector.onShake = _onShakeDetected;
    _shakeDetector.isEnabled = widget.enabled;
    _shakeDetector.start();
  }

  void _onShakeDetected() {
    // Prevent multiple dialogs
    if (_isDialogShowing) return;

    _showBugReportDialog();
  }

  Future<void> _showBugReportDialog() async {
    // Find the navigator context
    final navigatorContext = Navigator.of(context, rootNavigator: true).context;

    setState(() {
      _isDialogShowing = true;
    });

    try {
      await FeedbackDialog.show(
        navigatorContext,
        initialType: FeedbackType.bugReport,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDialogShowing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
