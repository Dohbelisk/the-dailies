import 'package:flutter/material.dart';
import '../../../widgets/admin/admin_number_pad.dart';
import '../../../widgets/admin/admin_validation_status.dart';

/// Editor for Killer Sudoku puzzles
class AdminKillerSudokuEditor extends StatefulWidget {
  final Map<String, dynamic>? initialPuzzleData;
  final Map<String, dynamic>? initialSolution;
  final void Function(Map<String, dynamic> puzzleData, Map<String, dynamic> solution, bool isValid) onChange;

  const AdminKillerSudokuEditor({
    super.key,
    this.initialPuzzleData,
    this.initialSolution,
    required this.onChange,
  });

  @override
  State<AdminKillerSudokuEditor> createState() => _AdminKillerSudokuEditorState();
}

class _AdminKillerSudokuEditorState extends State<AdminKillerSudokuEditor> {
  late List<List<int>> _grid;
  late List<List<int>> _solution;
  late List<_Cage> _cages;
  int? _selectedRow;
  int? _selectedCol;
  bool _isDrawingCage = false;
  List<List<int>> _currentCageCells = [];
  bool _isValid = false;
  List<String> _errors = [];

  static const List<Color> _cageColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
    Colors.indigo,
    Colors.cyan,
    Colors.lime,
    Colors.brown,
  ];

  @override
  void initState() {
    super.initState();
    final data = widget.initialPuzzleData ?? {};
    final solutionData = widget.initialSolution ?? {};

    // Parse grid (preset numbers)
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

    // Parse cages
    final cagesData = data['cages'] as List<dynamic>?;
    if (cagesData != null) {
      _cages = cagesData.asMap().entries.map((entry) {
        final index = entry.key;
        final cage = entry.value as Map<String, dynamic>;
        final cells = (cage['cells'] as List<dynamic>).map((c) {
          final cell = c as List<dynamic>;
          return [cell[0] as int, cell[1] as int];
        }).toList();
        return _Cage(
          sum: cage['sum'] as int,
          cells: cells,
          colorIndex: index % _cageColors.length,
        );
      }).toList();
    } else {
      _cages = [];
    }

    _validate();
  }

  void _validate() {
    final errors = <String>[];

    // Check cages cover all cells
    final coveredCells = <String>{};
    for (final cage in _cages) {
      for (final cell in cage.cells) {
        final key = '${cell[0]},${cell[1]}';
        if (coveredCells.contains(key)) {
          errors.add('Cell at row ${cell[0] + 1}, col ${cell[1] + 1} is in multiple cages');
        }
        coveredCells.add(key);
      }
    }

    if (coveredCells.length < 81) {
      errors.add('${81 - coveredCells.length} cells are not in any cage');
    }

    // Check cage sums are valid
    for (int i = 0; i < _cages.length; i++) {
      final cage = _cages[i];
      if (cage.sum < 1 || cage.sum > 45) {
        errors.add('Cage ${i + 1} has invalid sum ${cage.sum}');
      }
      if (cage.cells.isEmpty) {
        errors.add('Cage ${i + 1} has no cells');
      }
    }

    setState(() {
      _errors = errors.take(5).toList();
      _isValid = errors.isEmpty;
    });

    _notifyChange();
  }

  void _notifyChange() {
    widget.onChange(
      {
        'grid': _grid,
        'cages': _cages.map((c) => {
          'sum': c.sum,
          'cells': c.cells,
        }).toList(),
      },
      {'grid': _solution},
      _isValid,
    );
  }

  void _onCellTap(int row, int col) {
    if (_isDrawingCage) {
      // Add/remove cell from current cage
      final cellExists = _currentCageCells.any((c) => c[0] == row && c[1] == col);
      setState(() {
        if (cellExists) {
          _currentCageCells.removeWhere((c) => c[0] == row && c[1] == col);
        } else {
          _currentCageCells.add([row, col]);
        }
      });
    } else {
      setState(() {
        _selectedRow = row;
        _selectedCol = col;
      });
    }
  }

  void _onNumberTap(int number) {
    if (_selectedRow != null && _selectedCol != null && !_isDrawingCage) {
      setState(() {
        _grid[_selectedRow!][_selectedCol!] = number;
      });
      _validate();
    }
  }

  void _onClear() {
    if (_selectedRow != null && _selectedCol != null && !_isDrawingCage) {
      setState(() {
        _grid[_selectedRow!][_selectedCol!] = 0;
      });
      _validate();
    }
  }

  void _startDrawingCage() {
    setState(() {
      _isDrawingCage = true;
      _currentCageCells = [];
    });
  }

  void _finishCage() {
    if (_currentCageCells.isNotEmpty) {
      // Show dialog to enter sum
      _showSumDialog();
    } else {
      setState(() {
        _isDrawingCage = false;
      });
    }
  }

  void _showSumDialog() {
    int sum = 0;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Cage Sum'),
        content: TextField(
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Sum',
            hintText: '1-45',
          ),
          onChanged: (value) {
            sum = int.tryParse(value) ?? 0;
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isDrawingCage = false;
                _currentCageCells = [];
              });
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _cages.add(_Cage(
                  sum: sum,
                  cells: _currentCageCells,
                  colorIndex: _cages.length % _cageColors.length,
                ));
                _isDrawingCage = false;
                _currentCageCells = [];
              });
              _validate();
            },
            child: const Text('Add Cage'),
          ),
        ],
      ),
    );
  }

  void _removeCage(int index) {
    setState(() {
      _cages.removeAt(index);
    });
    _validate();
  }

  int? _getCageIndex(int row, int col) {
    for (int i = 0; i < _cages.length; i++) {
      for (final cell in _cages[i].cells) {
        if (cell[0] == row && cell[1] == col) {
          return i;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode indicator
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isDrawingCage
                ? Colors.orange.withValues(alpha: 0.1)
                : Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                _isDrawingCage ? Icons.draw : Icons.edit,
                color: _isDrawingCage ? Colors.orange : Colors.blue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isDrawingCage
                      ? 'Cage mode: Tap cells to add to cage (${_currentCageCells.length} cells)'
                      : 'Number mode: Tap cell then number to set preset',
                ),
              ),
              TextButton(
                onPressed: _isDrawingCage ? _finishCage : _startDrawingCage,
                child: Text(_isDrawingCage ? 'Finish Cage' : 'Draw Cage'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Grid
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
                    final isInCurrentCage = _currentCageCells.any((c) => c[0] == row && c[1] == col);
                    final cageIndex = _getCageIndex(row, col);
                    final value = _grid[row][col];

                    Color? cellColor;
                    if (isInCurrentCage) {
                      cellColor = Colors.orange.withValues(alpha: 0.3);
                    } else if (cageIndex != null) {
                      cellColor = _cageColors[_cages[cageIndex].colorIndex].withValues(alpha: 0.15);
                    }

                    // Check if this is the top-left cell of a cage (to show sum)
                    String? cageSum;
                    if (cageIndex != null) {
                      final cage = _cages[cageIndex];
                      final topLeft = cage.cells.reduce((a, b) {
                        if (a[0] < b[0] || (a[0] == b[0] && a[1] < b[1])) return a;
                        return b;
                      });
                      if (topLeft[0] == row && topLeft[1] == col) {
                        cageSum = '${cage.sum}';
                      }
                    }

                    return GestureDetector(
                      onTap: () => _onCellTap(row, col),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary.withValues(alpha: 0.2)
                              : cellColor,
                          border: Border(
                            right: BorderSide(
                              color: (col + 1) % 3 == 0 && col != 8
                                  ? theme.dividerColor
                                  : theme.dividerColor.withValues(alpha: 0.3),
                              width: (col + 1) % 3 == 0 && col != 8 ? 2 : 0.5,
                            ),
                            bottom: BorderSide(
                              color: (row + 1) % 3 == 0 && row != 8
                                  ? theme.dividerColor
                                  : theme.dividerColor.withValues(alpha: 0.3),
                              width: (row + 1) % 3 == 0 && row != 8 ? 2 : 0.5,
                            ),
                          ),
                        ),
                        child: Stack(
                          children: [
                            if (cageSum != null)
                              Positioned(
                                top: 1,
                                left: 2,
                                child: Text(
                                  cageSum,
                                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ),
                            Center(
                              child: Text(
                                value != 0 ? '$value' : '',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: value != 0 ? theme.colorScheme.primary : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Number pad (only when not drawing cage)
        if (!_isDrawingCage) ...[
          Text(
            'Preset Numbers',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          AdminNumberPad(
            onNumberTap: _onNumberTap,
            onClear: _onClear,
          ),
        ],
        const SizedBox(height: 16),

        // Cage list
        Text(
          'Cages (${_cages.length})',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (_cages.isEmpty)
          const Text('No cages defined. Click "Draw Cage" to start.',
              style: TextStyle(color: Colors.grey))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _cages.asMap().entries.map((entry) {
              final index = entry.key;
              final cage = entry.value;
              return Chip(
                avatar: CircleAvatar(
                  backgroundColor: _cageColors[cage.colorIndex],
                  radius: 10,
                ),
                label: Text('${cage.sum} (${cage.cells.length} cells)'),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => _removeCage(index),
              );
            }).toList(),
          ),
        const SizedBox(height: 24),

        // Validation status
        AdminValidationStatus(
          isValid: _isValid,
          errors: _errors,
          successMessage: 'Killer Sudoku with ${_cages.length} cages',
        ),
      ],
    );
  }
}

class _Cage {
  final int sum;
  final List<List<int>> cells;
  final int colorIndex;

  _Cage({required this.sum, required this.cells, required this.colorIndex});
}
