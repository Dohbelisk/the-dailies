import 'package:flutter/material.dart';

class GameTimer extends StatelessWidget {
  final int seconds;

  const GameTimer({super.key, required this.seconds});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 12,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 3),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
