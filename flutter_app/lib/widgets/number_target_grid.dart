import 'package:flutter/material.dart';
import '../models/game_models.dart';

class NumberTargetGrid extends StatelessWidget {
  final NumberTargetPuzzle puzzle;
  final String currentExpression;
  final Function(String token, {int? numberIndex}) onTokenTap;
  final VoidCallback onClear;
  final VoidCallback onBackspace;
  final String? resultMessage;
  final bool? lastResultSuccess;
  final Set<int> usedNumberIndices;
  final int? runningTotal;

  const NumberTargetGrid({
    super.key,
    required this.puzzle,
    required this.currentExpression,
    required this.onTokenTap,
    required this.onClear,
    required this.onBackspace,
    this.resultMessage,
    this.lastResultSuccess,
    this.usedNumberIndices = const {},
    this.runningTotal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMultipleTargets = puzzle.targets.isNotEmpty;

    return Column(
      children: [
        // Target display - show 3 targets if available, otherwise single target
        if (hasMultipleTargets)
          _buildMultipleTargets(theme)
        else
          _buildSingleTarget(theme),
        const SizedBox(height: 24),

        // Expression display with running total
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              // Expression with running total inline
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
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
                  ),
                  // Show running total inline if available
                  if (runningTotal != null && resultMessage == null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '= $runningTotal',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ],
              ),
              if (resultMessage != null) ...[
                const SizedBox(height: 4),
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
        const SizedBox(height: 16),

        // Numbers row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: puzzle.numbers.asMap().entries.map((entry) {
            final isUsed = usedNumberIndices.contains(entry.key);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _NumberButton(
                number: entry.value,
                onTap: isUsed ? null : () => onTokenTap('${entry.value}', numberIndex: entry.key),
                theme: theme,
                isDisabled: isUsed,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Operators - all in one row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _OperatorButton(operator: '+', onTap: () => onTokenTap('+'), theme: theme),
            const SizedBox(width: 8),
            _OperatorButton(operator: '-', onTap: () => onTokenTap('-'), theme: theme),
            const SizedBox(width: 8),
            _OperatorButton(operator: '×', onTap: () => onTokenTap('×'), theme: theme),
            const SizedBox(width: 8),
            _OperatorButton(operator: '÷', onTap: () => onTokenTap('÷'), theme: theme),
            const SizedBox(width: 8),
            _OperatorButton(operator: '(', onTap: () => onTokenTap('('), theme: theme),
            const SizedBox(width: 8),
            _OperatorButton(operator: ')', onTap: () => onTokenTap(')'), theme: theme),
          ],
        ),
        const SizedBox(height: 16),

        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Clear button with icon
            OutlinedButton.icon(
              onPressed: onClear,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('Clear'),
            ),
            const SizedBox(width: 12),
            // Backspace button
            OutlinedButton.icon(
              onPressed: onBackspace,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.backspace_outlined, size: 18),
              label: const Text('Undo'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSingleTarget(ThemeData theme) {
    return Container(
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
    );
  }

  Widget _buildMultipleTargets(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: puzzle.targets.map((target) {
        return _TargetCard(
          target: target,
          theme: theme,
        );
      }).toList(),
    );
  }
}

class _TargetCard extends StatelessWidget {
  final NumberTarget target;
  final ThemeData theme;

  const _TargetCard({
    required this.target,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    // Color scheme based on difficulty
    final (Color bgColor, Color fgColor, String label) = switch (target.difficulty) {
      'easy' => (
        theme.colorScheme.tertiaryContainer,
        theme.colorScheme.onTertiaryContainer,
        'EASY',
      ),
      'medium' => (
        theme.colorScheme.primaryContainer,
        theme.colorScheme.onPrimaryContainer,
        'MEDIUM',
      ),
      'hard' => (
        theme.colorScheme.errorContainer,
        theme.colorScheme.onErrorContainer,
        'HARD',
      ),
      _ => (
        theme.colorScheme.primaryContainer,
        theme.colorScheme.onPrimaryContainer,
        'TARGET',
      ),
    };

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        decoration: BoxDecoration(
          color: target.completed
              ? Colors.green.withValues(alpha: 0.2)
              : bgColor,
          borderRadius: BorderRadius.circular(12),
          border: target.completed
              ? Border.all(color: Colors.green, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: (target.completed ? Colors.green : bgColor).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: target.completed ? Colors.green : fgColor.withValues(alpha: 0.7),
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (target.completed)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                if (target.completed)
                  const SizedBox(width: 4),
                Text(
                  '${target.target}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: target.completed ? Colors.green : fgColor,
                    fontWeight: FontWeight.bold,
                    decoration: target.completed ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
