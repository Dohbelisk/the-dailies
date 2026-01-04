import 'package:flutter/material.dart';
import '../models/game_models.dart';

class NumberTargetGrid extends StatelessWidget {
  final NumberTargetPuzzle puzzle;
  final String currentExpression;
  final Function(String token, {int? numberIndex}) onTokenTap;
  final VoidCallback onClear;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;
  final String? resultMessage;
  final bool? lastResultSuccess;
  final Set<int> usedNumberIndices;

  const NumberTargetGrid({
    super.key,
    required this.puzzle,
    required this.currentExpression,
    required this.onTokenTap,
    required this.onClear,
    required this.onBackspace,
    required this.onSubmit,
    this.resultMessage,
    this.lastResultSuccess,
    this.usedNumberIndices = const {},
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Target display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'TARGET',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${puzzle.target}',
                style: theme.textTheme.displayLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Expression display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: lastResultSuccess == true
                  ? Colors.green
                  : lastResultSuccess == false
                      ? theme.colorScheme.error
                      : theme.colorScheme.outline.withValues(alpha: 0.3),
              width: lastResultSuccess != null ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                currentExpression.isEmpty ? 'Build your expression' : currentExpression,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: currentExpression.isEmpty
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
              if (resultMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  resultMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: lastResultSuccess == true
                        ? Colors.green.shade700
                        : theme.colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Numbers
        Text(
          'NUMBERS',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: puzzle.numbers.asMap().entries.map((entry) {
            final isUsed = usedNumberIndices.contains(entry.key);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _NumberButton(
                number: entry.value,
                onTap: isUsed ? null : () => onTokenTap('${entry.value}', numberIndex: entry.key),
                theme: theme,
                isDisabled: isUsed,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Operators
        Text(
          'OPERATORS',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _OperatorButton(operator: '+', onTap: () => onTokenTap('+'), theme: theme),
            const SizedBox(width: 12),
            _OperatorButton(operator: '-', onTap: () => onTokenTap('-'), theme: theme),
            const SizedBox(width: 12),
            _OperatorButton(operator: '×', onTap: () => onTokenTap('×'), theme: theme),
            const SizedBox(width: 12),
            _OperatorButton(operator: '÷', onTap: () => onTokenTap('÷'), theme: theme),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _OperatorButton(operator: '(', onTap: () => onTokenTap('('), theme: theme),
            const SizedBox(width: 12),
            _OperatorButton(operator: ')', onTap: () => onTokenTap(')'), theme: theme),
          ],
        ),
        const SizedBox(height: 24),

        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Clear button
            OutlinedButton(
              onPressed: onClear,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Clear'),
            ),
            const SizedBox(width: 12),
            // Backspace button
            OutlinedButton(
              onPressed: onBackspace,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Icon(Icons.backspace_outlined),
            ),
            const SizedBox(width: 12),
            // Submit button
            FilledButton(
              onPressed: currentExpression.isNotEmpty ? onSubmit : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Calculate'),
            ),
          ],
        ),
      ],
    );
  }
}

class _NumberButton extends StatelessWidget {
  final int number;
  final VoidCallback? onTap;
  final ThemeData theme;
  final bool isDisabled;

  const _NumberButton({
    required this.number,
    required this.onTap,
    required this.theme,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDisabled
          ? theme.colorScheme.surfaceContainerHighest
          : theme.colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDisabled
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                  : theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

class _OperatorButton extends StatelessWidget {
  final String operator;
  final VoidCallback onTap;
  final ThemeData theme;

  const _OperatorButton({
    required this.operator,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          child: Text(
            operator,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}
