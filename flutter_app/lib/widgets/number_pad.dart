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
  final List<_CalcEntry> _calcEntries = [];
  int _calcTotal = 0;
  String _currentInput = '';
  bool _nextIsSubtract = false; // The operator for the NEXT number

  void _addDigitToInput(int digit) {
    setState(() {
      // Build multi-digit number (max 2 digits for practicality)
      if (_currentInput.length < 2) {
        _currentInput += digit.toString();
      }
    });
  }

  void _commitAndSetAdd() {
    setState(() {
      _commitCurrentInput();
      _nextIsSubtract = false;
    });
  }

  void _commitAndSetSubtract() {
    setState(() {
      _commitCurrentInput();
      _nextIsSubtract = true;
    });
  }

  void _commitCurrentInput() {
    if (_currentInput.isNotEmpty) {
      final number = int.parse(_currentInput);
      _calcEntries.add(_CalcEntry(number, _nextIsSubtract));
      _calcTotal += _nextIsSubtract ? -number : number;
      _currentInput = '';
    }
  }

  void _undoCalculator() {
    setState(() {
      if (_currentInput.isNotEmpty) {
        // Remove last digit from current input
        _currentInput = _currentInput.substring(0, _currentInput.length - 1);
      } else if (_calcEntries.isNotEmpty) {
        // Remove the pending operator first (go back to showing last number)
        // Then remove the last entry
        final removed = _calcEntries.removeLast();
        _calcTotal += removed.isSubtract ? removed.number : -removed.number;
        // Restore the operator from the removed entry for display consistency
        _nextIsSubtract = removed.isSubtract;
        _currentInput = removed.number.toString();
      }
    });
  }

  void _clearCalculator() {
    setState(() {
      _calcEntries.clear();
      _currentInput = '';
      _calcTotal = 0;
      _nextIsSubtract = false;
    });
  }

  void _toggleCalculatorMode() {
    setState(() {
      _calculatorMode = !_calculatorMode;
      if (!_calculatorMode) {
        _calcEntries.clear();
        _currentInput = '';
        _calcTotal = 0;
        _nextIsSubtract = false;
      }
    });
  }

  String _buildDisplayString() {
    if (_calcEntries.isEmpty && _currentInput.isEmpty) {
      return 'Enter number, then + or −';
    }

    final buffer = StringBuffer();

    // Show committed entries
    for (int i = 0; i < _calcEntries.length; i++) {
      final entry = _calcEntries[i];
      if (i == 0) {
        if (entry.isSubtract) buffer.write('−');
        buffer.write(entry.number);
      } else {
        buffer.write(entry.isSubtract ? ' − ' : ' + ');
        buffer.write(entry.number);
      }
    }

    // Show pending operator if we have entries and no current input
    if (_calcEntries.isNotEmpty && _currentInput.isEmpty) {
      buffer.write(_nextIsSubtract ? ' −' : ' +');
    }

    // Show current input
    if (_currentInput.isNotEmpty) {
      if (_calcEntries.isNotEmpty) {
        buffer.write(_nextIsSubtract ? ' − ' : ' + ');
      } else if (_nextIsSubtract) {
        buffer.write('−');
      }
      buffer.write(_currentInput);
    }

    return buffer.toString();
  }

  int _getDisplayTotal() {
    int total = _calcTotal;
    if (_currentInput.isNotEmpty) {
      final pending = int.parse(_currentInput);
      total += _nextIsSubtract ? -pending : pending;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate responsive button size based on available width
          // For 5 buttons with gaps, calculate optimal size
          final availableWidth = constraints.maxWidth;
          const buttonCount = 5;
          const gapCount = buttonCount - 1;
          const minGap = 6.0;

          // Calculate button size: (available - gaps) / buttons, capped at 56
          final buttonSize = ((availableWidth - (gapCount * minGap)) / buttonCount).clamp(40.0, 56.0);
          final buttonHeight = (buttonSize * 1.14).clamp(46.0, 64.0);
          final fontSize = (buttonSize * 0.5).clamp(20.0, 28.0);

          return Column(
            children: [
              // Calculator display (when in calculator mode)
              if (_calculatorMode) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.3),
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
                          _buildDisplayString(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: (_calcEntries.isEmpty && _currentInput.isEmpty)
                                ? theme.colorScheme.onSecondaryContainer.withValues(alpha: 0.5)
                                : theme.colorScheme.onSecondaryContainer,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '= ${_getDisplayTotal()}',
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
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  final number = index + 1;
                  final isDisabled = !_calculatorMode && !widget.notesMode && widget.completedNumbers.contains(number);
                  return _buildNumberButton(context, number, isDisabled, buttonSize, buttonHeight, fontSize);
                }),
              ),

              const SizedBox(height: 10),

              // Second row: 6-9 (and 0 in calculator mode)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ...List.generate(4, (index) {
                    final number = index + 6;
                    final isDisabled = !_calculatorMode && !widget.notesMode && widget.completedNumbers.contains(number);
                    return _buildNumberButton(context, number, isDisabled, buttonSize, buttonHeight, fontSize);
                  }),
                  // Show 0 button in calculator mode, otherwise empty space
                  if (_calculatorMode)
                    _buildNumberButton(context, 0, false, buttonSize, buttonHeight, fontSize)
                  else
                    SizedBox(width: buttonSize),
                ],
              ),

              const SizedBox(height: 14),

              // Action buttons - different based on mode
              if (_calculatorMode)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildOperatorButton(
                      context,
                      symbol: '+',
                      onTap: _currentInput.isNotEmpty ? _commitAndSetAdd : null,
                      color: _currentInput.isNotEmpty ? theme.colorScheme.primary : null,
                    ),
                    _buildOperatorButton(
                      context,
                      symbol: '−',
                      onTap: _currentInput.isNotEmpty ? _commitAndSetSubtract : null,
                      color: _currentInput.isNotEmpty ? theme.colorScheme.tertiary : null,
                    ),
                    _buildActionButton(
                      context,
                      icon: Icons.backspace_rounded,
                      label: 'Undo',
                      onTap: (_currentInput.isNotEmpty || _calcEntries.isNotEmpty) ? _undoCalculator : null,
                      color: (_currentInput.isNotEmpty || _calcEntries.isNotEmpty) ? theme.colorScheme.error : null,
                    ),
                    _buildActionButton(
                      context,
                      icon: Icons.refresh_rounded,
                      label: 'Clear',
                      onTap: (_currentInput.isNotEmpty || _calcEntries.isNotEmpty) ? _clearCalculator : null,
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
          );
        },
      ),
    );
  }

  Widget _buildNumberButton(BuildContext context, int number, bool isDisabled, double size, double height, double fontSize) {
    final theme = Theme.of(context);

    final accentColor = _calculatorMode ? theme.colorScheme.secondary : theme.colorScheme.primary;
    final buttonColor = isDisabled
        ? theme.colorScheme.onSurface.withValues(alpha: 0.1)
        : theme.colorScheme.surface;
    final borderColor = isDisabled
        ? theme.colorScheme.onSurface.withValues(alpha: 0.1)
        : accentColor.withValues(alpha: 0.3);
    final textColor = isDisabled
        ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
        : accentColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled
            ? null
            : () {
                if (_calculatorMode) {
                  // Build multi-digit numbers
                  _addDigitToInput(number);
                } else {
                  widget.onNumberTap(number);
                }
              },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: size,
          height: height,
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: 1.5,
            ),
            boxShadow: isDisabled
                ? null
                : [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: fontSize,
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
    VoidCallback? onTap,
    bool isActive = false,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final isEnabled = onTap != null;
    final buttonColor = color ?? theme.colorScheme.primary;
    final displayColor = isEnabled ? buttonColor : theme.colorScheme.onSurface.withValues(alpha: 0.3);

    return Flexible(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: (isActive || color != null) && isEnabled
                  ? displayColor.withValues(alpha: 0.2)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (isActive || color != null) && isEnabled
                    ? displayColor
                    : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: (isActive || color != null) && isEnabled
                      ? displayColor
                      : theme.colorScheme.onSurface.withValues(alpha: isEnabled ? 0.7 : 0.3),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: (isActive || color != null) && isEnabled ? FontWeight.bold : FontWeight.normal,
                    color: (isActive || color != null) && isEnabled
                        ? displayColor
                        : theme.colorScheme.onSurface.withValues(alpha: isEnabled ? 0.7 : 0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOperatorButton(
    BuildContext context, {
    required String symbol,
    VoidCallback? onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final isEnabled = onTap != null;
    final buttonColor = color ?? theme.colorScheme.primary;
    final displayColor = isEnabled ? buttonColor : theme.colorScheme.onSurface.withValues(alpha: 0.3);

    return Flexible(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isEnabled
                  ? displayColor.withValues(alpha: 0.2)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isEnabled
                    ? displayColor
                    : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Text(
              symbol,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: displayColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Represents a calculator entry with a number and operation type
class _CalcEntry {
  final int number;
  final bool isSubtract;

  _CalcEntry(this.number, this.isSubtract);
}
