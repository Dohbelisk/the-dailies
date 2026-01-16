import 'package:flutter/material.dart';

/// Reusable number pad widget for admin editors
class AdminNumberPad extends StatelessWidget {
  final void Function(int number) onNumberTap;
  final VoidCallback? onClear;
  final int? selectedNumber;
  final int maxNumber;

  const AdminNumberPad({
    super.key,
    required this.onNumberTap,
    this.onClear,
    this.selectedNumber,
    this.maxNumber = 9,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (int i = 1; i <= maxNumber; i++)
          SizedBox(
            width: 48,
            height: 48,
            child: ElevatedButton(
              onPressed: () => onNumberTap(i),
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedNumber == i
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
                foregroundColor: selectedNumber == i
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: selectedNumber == i
                        ? theme.colorScheme.primary
                        : theme.dividerColor,
                  ),
                ),
              ),
              child: Text(
                '$i',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        if (onClear != null)
          SizedBox(
            width: 48,
            height: 48,
            child: ElevatedButton(
              onPressed: onClear,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.1),
                foregroundColor: Colors.red,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.red),
                ),
              ),
              child: const Icon(Icons.clear),
            ),
          ),
      ],
    );
  }
}
