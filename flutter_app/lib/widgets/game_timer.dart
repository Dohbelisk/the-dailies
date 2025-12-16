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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 16,
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
