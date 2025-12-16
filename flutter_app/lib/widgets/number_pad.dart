import 'package:flutter/material.dart';

class NumberPad extends StatelessWidget {
  final bool notesMode;
  final Function(int) onNumberTap;
  final VoidCallback onClearTap;
  final VoidCallback onNotesTap;
  final VoidCallback onHintTap;

  const NumberPad({
    super.key,
    required this.notesMode,
    required this.onNumberTap,
    required this.onClearTap,
    required this.onNotesTap,
    required this.onHintTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Number buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(9, (index) {
              final number = index + 1;
              return _buildNumberButton(context, number);
            }),
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                context,
                icon: Icons.undo_rounded,
                label: 'Undo',
                onTap: () {},
              ),
              _buildActionButton(
                context,
                icon: Icons.backspace_outlined,
                label: 'Clear',
                onTap: onClearTap,
              ),
              _buildActionButton(
                context,
                icon: notesMode ? Icons.edit : Icons.edit_outlined,
                label: 'Notes',
                isActive: notesMode,
                onTap: onNotesTap,
              ),
              _buildActionButton(
                context,
                icon: Icons.lightbulb_outline_rounded,
                label: 'Hint',
                onTap: onHintTap,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(BuildContext context, int number) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onNumberTap(number),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 36,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primary.withOpacity(0.2)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
