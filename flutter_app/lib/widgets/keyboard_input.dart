import 'package:flutter/material.dart';

class KeyboardInput extends StatelessWidget {
  final Function(String) onLetterTap;
  final VoidCallback onDeleteTap;

  const KeyboardInput({
    super.key,
    required this.onLetterTap,
    required this.onDeleteTap,
  });

  static const _row1 = ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'];
  static const _row2 = ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'];
  static const _row3 = ['Z', 'X', 'C', 'V', 'B', 'N', 'M'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        children: [
          _buildRow(context, _row1),
          const SizedBox(height: 6),
          _buildRow(context, _row2),
          const SizedBox(height: 6),
          _buildRow(context, _row3, includeDelete: true),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, List<String> letters, {bool includeDelete = false}) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...letters.map((letter) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: _buildKey(context, letter),
        )),
        if (includeDelete) ...[
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onDeleteTap,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 56,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  Icons.backspace_outlined,
                  size: 20,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildKey(BuildContext context, String letter) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onLetterTap(letter),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              letter,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
