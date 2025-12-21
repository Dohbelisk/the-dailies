import 'package:flutter/material.dart';

class NumberPad extends StatefulWidget {
  final bool notesMode;
  final Function(int) onNumberTap;
  final VoidCallback onClearTap;
  final VoidCallback onNotesTap;
  final VoidCallback onHintTap;
  /// Set of numbers (1-9) that have all 9 instances placed and should be disabled
  final Set<int> completedNumbers;
  /// Whether to show calculator toggle button (for Killer Sudoku)
  final bool showCalculator;

  const NumberPad({
    super.key,
    required this.notesMode,
    required this.onNumberTap,
    required this.onClearTap,
    required this.onNotesTap,
    required this.onHintTap,
    this.completedNumbers = const {},
    this.showCalculator = false,
  });

  @override
  State<NumberPad> createState() => _NumberPadState();
}

class _NumberPadState extends State<NumberPad> {
  bool _calculatorMode = false;
  final List<int> _calcNumbers = [];
  int _calcTotal = 0;

  void _addToCalculator(int number) {
    setState(() {
      _calcNumbers.add(number);
      _calcTotal = _calcNumbers.fold(0, (sum, n) => sum + n);
    });
  }

  void _undoCalculator() {
    if (_calcNumbers.isNotEmpty) {
      setState(() {
        _calcNumbers.removeLast();
        _calcTotal = _calcNumbers.fold(0, (sum, n) => sum + n);
      });
    }
  }

  void _clearCalculator() {
    setState(() {
      _calcNumbers.clear();
      _calcTotal = 0;
    });
  }

  void _toggleCalculatorMode() {
    setState(() {
      _calculatorMode = !_calculatorMode;
      if (!_calculatorMode) {
        _calcNumbers.clear();
        _calcTotal = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Calculator display (when in calculator mode)
          if (_calculatorMode) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.secondary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calculate_rounded,
                    size: 18,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _calcNumbers.isEmpty
                          ? 'Tap numbers to add'
                          : _calcNumbers.join(' + '),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _calcNumbers.isEmpty
                            ? theme.colorScheme.onSecondaryContainer.withOpacity(0.5)
                            : theme.colorScheme.onSecondaryContainer,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '= $_calcTotal',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Number buttons - 2 rows
          // First row: 1-5
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final number = index + 1;
              final isDisabled = !_calculatorMode && !widget.notesMode && widget.completedNumbers.contains(number);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _buildNumberButton(context, number, isDisabled),
              );
            }),
          ),

          const SizedBox(height: 12),

          // Second row: 6-9
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final number = index + 6;
              final isDisabled = !_calculatorMode && !widget.notesMode && widget.completedNumbers.contains(number);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _buildNumberButton(context, number, isDisabled),
              );
            }),
          ),

          const SizedBox(height: 16),

          // Action buttons - different based on mode
          if (_calculatorMode)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  context,
                  icon: Icons.backspace_rounded,
                  label: 'Undo',
                  onTap: _undoCalculator,
                  color: theme.colorScheme.error,
                ),
                _buildActionButton(
                  context,
                  icon: Icons.refresh_rounded,
                  label: 'Clear',
                  onTap: _clearCalculator,
                  color: theme.colorScheme.secondary,
                ),
                _buildActionButton(
                  context,
                  icon: Icons.close_rounded,
                  label: 'Done',
                  onTap: _toggleCalculatorMode,
                  isActive: true,
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  context,
                  icon: Icons.backspace_outlined,
                  label: 'Clear',
                  onTap: widget.onClearTap,
                ),
                _buildActionButton(
                  context,
                  icon: widget.notesMode ? Icons.edit : Icons.edit_outlined,
                  label: 'Notes',
                  isActive: widget.notesMode,
                  onTap: widget.onNotesTap,
                ),
                _buildActionButton(
                  context,
                  icon: Icons.lightbulb_outline_rounded,
                  label: 'Hint',
                  onTap: widget.onHintTap,
                ),
                if (widget.showCalculator)
                  _buildActionButton(
                    context,
                    icon: Icons.calculate_outlined,
                    label: 'Sum',
                    onTap: _toggleCalculatorMode,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(BuildContext context, int number, bool isDisabled) {
    final theme = Theme.of(context);

    final accentColor = _calculatorMode ? theme.colorScheme.secondary : theme.colorScheme.primary;
    final buttonColor = isDisabled
        ? theme.colorScheme.onSurface.withOpacity(0.1)
        : theme.colorScheme.surface;
    final borderColor = isDisabled
        ? theme.colorScheme.onSurface.withOpacity(0.1)
        : accentColor.withOpacity(0.3);
    final textColor = isDisabled
        ? theme.colorScheme.onSurface.withOpacity(0.3)
        : accentColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled
            ? null
            : () {
                if (_calculatorMode) {
                  _addToCalculator(number);
                } else {
                  widget.onNumberTap(number);
                }
              },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 56,
          height: 64,
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: 1.5,
            ),
            boxShadow: isDisabled
                ? null
                : [
                    BoxShadow(
                      color: accentColor.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textColor,
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
    Color? color,
  }) {
    final theme = Theme.of(context);
    final buttonColor = color ?? theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive || color != null
                ? buttonColor.withOpacity(0.2)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive || color != null
                  ? buttonColor
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
                color: isActive || color != null
                    ? buttonColor
                    : theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive || color != null ? FontWeight.bold : FontWeight.normal,
                  color: isActive || color != null
                      ? buttonColor
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
