import 'package:flutter/material.dart';
import '../../../widgets/admin/admin_number_pad.dart';
import '../../../widgets/admin/admin_validation_status.dart';

/// Editor for Sudoku puzzles
class AdminSudokuEditor extends StatefulWidget {
  final Map<String, dynamic>? initialPuzzleData;
  final Map<String, dynamic>? initialSolution;
  final void Function(Map<String, dynamic> puzzleData, Map<String, dynamic> solution, bool isValid) onChange;

  const AdminSudokuEditor({
    super.key,
    this.initialPuzzleData,
    this.initialSolution,
    required this.onChange,
  });

  @override
  State<AdminSudokuEditor> createState() => _AdminSudokuEditorState();
}

class _AdminSudokuEditorState extends State<AdminSudokuEditor> {
  late List<List<int>> _grid;
  late List<List<int>> _solution;
  int? _selectedRow;
  int? _selectedCol;
  bool _isValid = false;
  List<String> _errors = [];

  @override
  void initState() {
    super.initState();
    final data = widget.initialPuzzleData ?? {};
    final solutionData = widget.initialSolution ?? {};

    // Parse grid
    final gridData = data['grid'] as List<dynamic>?;
    if (gridData != null) {
      _grid = gridData.map((row) {
        return (row as List<dynamic>).map((cell) => cell as int).toList();
      }).toList();
    } else {
      _grid = List.generate(9, (_) => List.generate(9, (_) => 0));
    }

    // Parse solution
    final solGrid = solutionData['grid'] as List<dynamic>? ?? data['solution'] as List<dynamic>?;
    if (solGrid != null) {
      _solution = solGrid.map((row) {
        return (row as List<dynamic>).map((cell) => cell as int).toList();
      }).toList();
    } else {
      _solution = List.generate(9, (_) => List.generate(9, (_) => 0));
    }

    _validate();
  }

  void _validate() {
    final errors = <String>[];

    // Check grid has 9x9 cells
    if (_grid.length != 9 || _grid.any((row) => row.length != 9)) {
      errors.add('Grid must be 9x9');
    }

    // Count given cells
    int givenCount = 0;
    for (final row in _grid) {
      for (final cell in row) {
        if (cell != 0) givenCount++;
      }
    }
    if (givenCount < 17) {
      errors.add('Need at least 17 given numbers (have $givenCount)');
    }

    // Check for invalid values
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final val = _grid[r][c];
        if (val < 0 || val > 9) {
          errors.add('Invalid value at row ${r + 1}, col ${c + 1}');
        }
      }
    }

    // Basic row/column/box validation
    for (int i = 0; i < 9; i++) {
      // Check row
      final rowVals = <int>{};
      for (int c = 0; c < 9; c++) {
        final val = _grid[i][c];
        if (val != 0) {
          if (rowVals.contains(val)) {
            errors.add('Duplicate $val in row ${i + 1}');
            break;
          }
          rowVals.add(val);
        }
      }

      // Check column
      final colVals = <int>{};
      for (int r = 0; r < 9; r++) {
        final val = _grid[r][i];
        if (val != 0) {
          if (colVals.contains(val)) {
            errors.add('Duplicate $val in column ${i + 1}');
            break;
          }
          colVals.add(val);
        }
      }
    }

    // Check 3x3 boxes
    for (int boxRow = 0; boxRow < 3; boxRow++) {
      for (int boxCol = 0; boxCol < 3; boxCol++) {
        final boxVals = <int>{};
        for (int r = 0; r < 3; r++) {
          for (int c = 0; c < 3; c++) {
            final val = _grid[boxRow * 3 + r][boxCol * 3 + c];
            if (val != 0) {
              if (boxVals.contains(val)) {
                errors.add('Duplicate $val in box ${boxRow * 3 + boxCol + 1}');
                break;
              }
              boxVals.add(val);
            }
          }
        }
      }
    }

    setState(() {
      _errors = errors.take(5).toList(); // Limit to 5 errors
      _isValid = errors.isEmpty;
    });

    _notifyChange();
  }

  void _notifyChange() {
    widget.onChange(
      {'grid': _grid},
      {'grid': _solution},
      _isValid,
    );
  }

  void _onCellTap(int row, int col) {
    setState(() {
      _selectedRow = row;
      _selectedCol = col;
    });
  }

  void _onNumberTap(int number) {
    if (_selectedRow != null && _selectedCol != null) {
      setState(() {
        _grid[_selectedRow!][_selectedCol!] = number;
      });
      _validate();
    }
  }

  void _onClear() {
    if (_selectedRow != null && _selectedCol != null) {
      setState(() {
        _grid[_selectedRow!][_selectedCol!] = 0;
      });
      _validate();
    }
  }

  void _clearAll() {
    setState(() {
      _grid = List.generate(9, (_) => List.generate(9, (_) => 0));
      _selectedRow = null;
      _selectedCol = null;
    });
    _validate();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grid
        Text(
          'Puzzle Grid (tap cell, then number)',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Center(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(9, (row) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(9, (col) {
                    final isSelected = _selectedRow == row && _selectedCol == col;
                    final value = _grid[row][col];
                    final isGiven = value != 0;

                    return GestureDetector(
                      onTap: () => _onCellTap(row, col),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary.withValues(alpha: 0.2)
                              : (isGiven ? theme.colorScheme.surface : null),
                          border: Border(
                            right: BorderSide(
                              color: (col + 1) % 3 == 0 && col != 8
                                  ? theme.dividerColor
                                  : Colors.transparent,
                              width: 2,
                            ),
                            bottom: BorderSide(
                              color: (row + 1) % 3 == 0 && row != 8
                                  ? theme.dividerColor
                                  : Colors.transparent,
                              width: 2,
                            ),
                            left: BorderSide(
                              color: theme.dividerColor.withValues(alpha: 0.3),
                              width: 0.5,
                            ),
                            top: BorderSide(
                              color: theme.dividerColor.withValues(alpha: 0.3),
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            value != 0 ? '$value' : '',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isGiven
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Number pad
        Text(
          'Number Pad',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        AdminNumberPad(
          onNumberTap: _onNumberTap,
          onClear: _onClear,
        ),
        const SizedBox(height: 16),

        // Actions
        OutlinedButton.icon(
          onPressed: _clearAll,
          icon: const Icon(Icons.clear_all, size: 18),
          label: const Text('Clear All'),
        ),
        const SizedBox(height: 24),

        // Validation status
        AdminValidationStatus(
          isValid: _isValid,
          errors: _errors,
          successMessage: 'Valid Sudoku puzzle',
        ),
      ],
    );
  }
}
