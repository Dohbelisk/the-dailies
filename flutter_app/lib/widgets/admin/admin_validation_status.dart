import 'package:flutter/material.dart';

/// Validation status widget for admin editors
class AdminValidationStatus extends StatelessWidget {
  final bool? isValid;
  final String? successMessage;
  final List<String>? errors;

  const AdminValidationStatus({
    super.key,
    this.isValid,
    this.successMessage,
    this.errors,
  });

  @override
  Widget build(BuildContext context) {
    if (isValid == null) {
      return const SizedBox.shrink();
    }

    if (isValid!) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Text(
              successMessage ?? 'Valid puzzle data',
              style: const TextStyle(color: Colors.green),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                'Validation errors',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (errors != null && errors!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...errors!.map((error) => Padding(
                  padding: const EdgeInsets.only(left: 28, top: 4),
                  child: Text(
                    '• $error',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
