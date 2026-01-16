import 'package:flutter/material.dart';
import '../../../widgets/admin/admin_validation_status.dart';

/// Editor for Nonogram puzzles
class AdminNonogramEditor extends StatefulWidget {
  final Map<String, dynamic>? initialPuzzleData;
  final Map<String, dynamic>? initialSolution;
  final void Function(Map<String, dynamic> puzzleData, Map<String, dynamic> solution, bool isValid) onChange;

  const AdminNonogramEditor({
    super.key,
    this.initialPuzzleData,
    this.initialSolution,
    required this.onChange,
  });

  @override
  State<AdminNonogramEditor> createState() => _AdminNonogramEditorState();
}

class _AdminNonogramEditorState extends State<AdminNonogramEditor> {
  late int _rows;
  late int _cols;
  late List<List<int>> _grid; // 0 = empty, 1 = filled
  bool _isValid = false;
  List<String> _errors = [];

  @override
  void initState() {
    super.initState();
    final data = widget.initialPuzzleData ?? {};
    final solution = widget.initialSolution ?? {};

    _rows = data['rows'] as int? ?? 5;
    _cols = data['cols'] as int? ?? 5;

    // Try to get grid from solution
    final gridData = solution['grid'] as List<dynamic>?;
    if (gridData != null) {
      _grid = gridData.map((row) {
        return (row as List<dynamic>).map((cell) {
          if (cell is bool) return cell ? 1 : 0;
          if (cell is int) return cell;
          return 0;
        }).toList();
      }).toList();
      _rows = _grid.length;
      _cols = _grid.isNotEmpty ? _grid[0].length : 5;
    } else {
      _grid = List.generate(_rows, (_) => List.generate(_cols, (_) => 0));
    }

    _validate();
  }

  void _validate() {
    final errors = <String>[];

    // Check dimensions
    if (_rows < 5 || _rows > 15) {
      errors.add('Rows must be between 5 and 15');
    }
    if (_cols < 5 || _cols > 15) {
      errors.add('Columns must be between 5 and 15');
    }

    // Check there are some filled cells
    int filledCount = 0;
    for (final row in _grid) {
      for (final cell in row) {
        if (cell == 1) filledCount++;
      }
    }
    if (filledCount == 0) {
      errors.add('Draw a pattern first (click cells to fill)');
    } else if (filledCount < _rows * _cols * 0.1) {
      errors.add('Pattern too simple. Add more filled cells.');
    }

    setState(() {
      _errors = errors;
      _isValid = errors.isEmpty;
    });

    _notifyChange();
  }

  void _notifyChange() {
    // Generate clues from grid
    final rowClues = _generateRowClues();
    final colClues = _generateColClues();

    widget.onChange(
      {
        'rows': _rows,
        'cols': _cols,
        'rowClues': rowClues,
        'colClues': colClues,
      },
      {
        'grid': _grid,
      },
      _isValid,
    );
  }

  List<List<int>> _generateRowClues() {
    final clues = <List<int>>[];
    for (int r = 0; r < _rows; r++) {
      final clue = <int>[];
      int count = 0;
      for (int c = 0; c < _cols; c++) {
        if (_grid[r][c] == 1) {
          count++;
        } else if (count > 0) {
          clue.add(count);
          count = 0;
        }
      }
      if (count > 0) clue.add(count);
      clues.add(clue.isEmpty ? [0] : clue);
    }
    return clues;
  }

  List<List<int>> _generateColClues() {
    final clues = <List<int>>[];
    for (int c = 0; c < _cols; c++) {
      final clue = <int>[];
      int count = 0;
      for (int r = 0; r < _rows; r++) {
        if (_grid[r][c] == 1) {
          count++;
        } else if (count > 0) {
          clue.add(count);
          count = 0;
        }
      }
      if (count > 0) clue.add(count);
      clues.add(clue.isEmpty ? [0] : clue);
    }
    return clues;
  }

  void _toggleCell(int row, int col) {
    setState(() {
      _grid[row][col] = _grid[row][col] == 1 ? 0 : 1;
    });
    _validate();
  }

  void _resizeGrid(int newSize) {
    setState(() {
      _rows = newSize;
      _cols = newSize;
      _grid = List.generate(newSize, (r) {
        return List.generate(newSize, (c) {
          if (r < _grid.length && c < _grid[r].length) {
            return _grid[r][c];
          }
          return 0;
        });
      });
    });
    _validate();
  }

  void _clearAll() {
    setState(() {
      _grid = List.generate(_rows, (_) => List.generate(_cols, (_) => 0));
    });
    _validate();
  }

  void _randomPattern() {
    setState(() {
      _grid = List.generate(_rows, (_) =>
          List.generate(_cols, (_) => DateTime.now().microsecondsSinceEpoch % 3 == 0 ? 1 : 0));
    });
    _validate();
  }

  void _diamondPattern() {
    setState(() {
      final centerR = _rows ~/ 2;
      final centerC = _cols ~/ 2;
      _grid = List.generate(_rows, (r) =>
          List.generate(_cols, (c) {
            final distR = (r - centerR).abs();
            final distC = (c - centerC).abs();
            return (distR + distC <= centerR.clamp(0, centerC)) ? 1 : 0;
          }));
    });
    _validate();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rowClues = _generateRowClues();
    final colClues = _generateColClues();

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
            for (final size in [5, 8, 10, 12, 15])
              ChoiceChip(
                label: Text('${size}x$size'),
                selected: _rows == size,
                onSelected: (selected) {
                  if (selected) _resizeGrid(size);
                },
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Instructions
        Text(
          'Click cells to toggle filled/empty. Clues are auto-generated.',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // Grid with clues
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column clues
              Row(
                children: [
                  SizedBox(width: 60), // Space for row clues
                  ...List.generate(_cols, (c) {
                    return Container(
                      width: 28,
                      alignment: Alignment.bottomCenter,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: colClues[c].map((n) => Text(
                          '$n',
                          style: const TextStyle(fontSize: 10),
                        )).toList(),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 4),
              // Grid rows with row clues
              ...List.generate(_rows, (r) {
                return Row(
                  children: [
                    // Row clues
                    Container(
                      width: 60,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        rowClues[r].join(' '),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                    // Grid cells
                    ...List.generate(_cols, (c) {
                      final isFilled = _grid[r][c] == 1;
                      return GestureDetector(
                        onTap: () => _toggleCell(r, c),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isFilled ? Colors.grey[800] : Colors.white,
                            border: Border.all(
                              color: Colors.grey,
                              width: 0.5,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Stats
        Text(
          'Filled: ${_grid.expand((r) => r).where((c) => c == 1).length} / ${_rows * _cols}',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // Actions
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _randomPattern,
              icon: const Icon(Icons.shuffle, size: 18),
              label: const Text('Random'),
            ),
            OutlinedButton.icon(
              onPressed: _diamondPattern,
              icon: const Icon(Icons.diamond, size: 18),
              label: const Text('Diamond'),
            ),
            OutlinedButton.icon(
              onPressed: _clearAll,
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Validation status
        AdminValidationStatus(
          isValid: _isValid,
          errors: _errors,
          successMessage: '${_rows}x$_cols nonogram ready',
        ),
      ],
    );
  }
}
