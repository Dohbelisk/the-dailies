import 'package:flutter/material.dart';
import '../models/game_models.dart';

class MathoraGrid extends StatelessWidget {
  final MathoraPuzzle puzzle;
  final Function(MathoraOperation) onOperationTap;
  final VoidCallback onUndo;
  final VoidCallback onReset;

  const MathoraGrid({
    super.key,
    required this.puzzle,
    required this.onOperationTap,
    required this.onUndo,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Moves left indicator
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: puzzle.isSolved
                  ? [Colors.green.shade600, Colors.green.shade400]
                  : puzzle.isFailed
                      ? [Colors.red.shade600, Colors.red.shade400]
                      : [Colors.green.shade700, Colors.green.shade500],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Moves Left',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${puzzle.movesLeft}',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Current and Target displays
        Row(
          children: [
            // Current value
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey.shade800
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Current:',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${puzzle.currentValue}',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: puzzle.isSolved
                            ? Colors.green
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Target value
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Target:',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${puzzle.targetNumber}',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Progress/History display
        if (puzzle.appliedOperations.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey.shade900
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                puzzle.progressString,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Operations grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.0,
            ),
            itemCount: puzzle.operations.length,
            itemBuilder: (context, index) {
              final operation = puzzle.operations[index];
              return _OperationButton(
                operation: operation,
                onTap: puzzle.isGameOver
                    ? null
                    : () => onOperationTap(operation),
                theme: theme,
                isDark: isDark,
              );
            },
          ),
        ),

        // Action buttons
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Reset button
            OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(width: 16),
            // Undo button
            FilledButton.icon(
              onPressed: puzzle.appliedOperations.isEmpty ? null : onUndo,
              icon: const Icon(Icons.undo),
              label: const Text('Undo'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),

        // Win/Lose message
        if (puzzle.isSolved) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.celebration, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Congratulations! You reached ${puzzle.targetNumber}!',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ] else if (puzzle.isFailed) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red, width: 2),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.close, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      'Out of moves! Target was ${puzzle.targetNumber}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap Reset to try again',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.red.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _OperationButton extends StatelessWidget {
  final MathoraOperation operation;
  final VoidCallback? onTap;
  final ThemeData theme;
  final bool isDark;

  const _OperationButton({
    required this.operation,
    required this.onTap,
    required this.theme,
    required this.isDark,
  });

  Color _getOperationColor() {
    switch (operation.type) {
      case 'add':
        return Colors.blue.shade400;
      case 'subtract':
        return Colors.orange.shade400;
      case 'multiply':
        return Colors.purple.shade300; // Brighter purple for better contrast
      case 'divide':
        return Colors.teal.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getOperationColor();

    return Material(
      color: isDark
          ? Colors.grey.shade800
          : Colors.grey.shade200,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.5),
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            operation.display,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: onTap == null
                  ? theme.colorScheme.onSurface.withOpacity(0.3)
                  : color,
            ),
          ),
        ),
      ),
    );
  }
}
