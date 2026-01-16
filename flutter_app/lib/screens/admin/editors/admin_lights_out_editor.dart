import 'package:flutter/material.dart';
import '../../../widgets/admin/admin_validation_status.dart';

/// Editor for Lights Out puzzles
class AdminLightsOutEditor extends StatefulWidget {
  final Map<String, dynamic>? initialPuzzleData;
  final Map<String, dynamic>? initialSolution;
  final void Function(Map<String, dynamic> puzzleData, Map<String, dynamic> solution, bool isValid) onChange;

  const AdminLightsOutEditor({
    super.key,
    this.initialPuzzleData,
    this.initialSolution,
    required this.onChange,
  });

  @override
  State<AdminLightsOutEditor> createState() => _AdminLightsOutEditorState();
}

class _AdminLightsOutEditorState extends State<AdminLightsOutEditor> {
  late int _rows;
  late int _cols;
  late List<List<bool>> _grid;
  bool _isValid = false;
  List<String> _errors = [];

  @override
  void initState() {
    super.initState();
    final data = widget.initialPuzzleData ?? {};
    _rows = data['rows'] as int? ?? 5;
    _cols = data['cols'] as int? ?? 5;

    // Parse grid
    final gridData = data['grid'] as List<dynamic>?;
    if (gridData != null) {
      _grid = gridData.map((row) {
        final rowList = row as List<dynamic>;
        return rowList.map((cell) => cell as bool).toList();
      }).toList();
    } else {
      _grid = List.generate(_rows, (_) => List.generate(_cols, (_) => false));
    }

    _validate();
  }

  void _validate() {
    final errors = <String>[];

    // Check grid dimensions
    if (_rows < 3 || _rows > 7) {
      errors.add('Rows must be between 3 and 7');
    }
    if (_cols < 3 || _cols > 7) {
      errors.add('Columns must be between 3 and 7');
    }

    // Check there are some lights on
    int lightsOn = 0;
    for (final row in _grid) {
      for (final cell in row) {
        if (cell) lightsOn++;
      }
    }
    if (lightsOn == 0) {
      errors.add('At least one light must be on');
    }

    setState(() {
      _errors = errors;
      _isValid = errors.isEmpty;
    });

    _notifyChange();
  }

  void _notifyChange() {
    widget.onChange(
      {
        'rows': _rows,
        'cols': _cols,
        'grid': _grid,
      },
      {}, // Solution can be computed
      _isValid,
    );
  }

  void _toggleCell(int row, int col) {
    setState(() {
      _grid[row][col] = !_grid[row][col];
    });
    _validate();
  }

  void _resizeGrid(int newRows, int newCols) {
    setState(() {
      _rows = newRows;
      _cols = newCols;
      _grid = List.generate(newRows, (r) {
        return List.generate(newCols, (c) {
          if (r < _grid.length && c < _grid[r].length) {
            return _grid[r][c];
          }
          return false;
        });
      });
    });
    _validate();
  }

  void _clearAll() {
    setState(() {
      _grid = List.generate(_rows, (_) => List.generate(_cols, (_) => false));
    });
    _validate();
  }

  void _randomize() {
    setState(() {
      _grid = List.generate(_rows, (_) => List.generate(_cols, (_) =>
        DateTime.now().microsecond % 2 == 0
      ));
    });
    _validate();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Size selector
        Text(
          'Grid Size',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final size in [3, 4, 5, 6, 7])
              ChoiceChip(
                label: Text('${size}x$size'),
                selected: _rows == size && _cols == size,
                onSelected: (selected) {
                  if (selected) _resizeGrid(size, size);
                },
              ),
          ],
        ),
        const SizedBox(height: 24),

        // Grid editor
        Text(
          'Grid (tap to toggle lights)',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_rows, (row) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_cols, (col) {
                  final isOn = _grid[row][col];
                  return GestureDetector(
                    onTap: () => _toggleCell(row, col),
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isOn ? Colors.yellow : Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: isOn
                            ? [
                                BoxShadow(
                                  color: Colors.yellow.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                      child: Icon(
                        isOn ? Icons.lightbulb : Icons.lightbulb_outline,
                        color: isOn ? Colors.orange : Colors.grey,
                        size: 24,
                      ),
                    ),
                  );
                }),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),

        // Actions
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _clearAll,
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('Clear All'),
            ),
            OutlinedButton.icon(
              onPressed: _randomize,
              icon: const Icon(Icons.shuffle, size: 18),
              label: const Text('Randomize'),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Stats
        Text(
          'Lights on: ${_grid.expand((r) => r).where((c) => c).length} / ${_rows * _cols}',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // Validation status
        AdminValidationStatus(
          isValid: _isValid,
          errors: _errors,
          successMessage: '${_rows}x$_cols grid with ${_grid.expand((r) => r).where((c) => c).length} lights on',
        ),
      ],
    );
  }
}
