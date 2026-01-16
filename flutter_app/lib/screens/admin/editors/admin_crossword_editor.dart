import 'package:flutter/material.dart';
import '../../../widgets/admin/admin_validation_status.dart';

/// Editor for Crossword puzzles
class AdminCrosswordEditor extends StatefulWidget {
  final Map<String, dynamic>? initialPuzzleData;
  final Map<String, dynamic>? initialSolution;
  final void Function(Map<String, dynamic> puzzleData, Map<String, dynamic> solution, bool isValid) onChange;

  const AdminCrosswordEditor({
    super.key,
    this.initialPuzzleData,
    this.initialSolution,
    required this.onChange,
  });

  @override
  State<AdminCrosswordEditor> createState() => _AdminCrosswordEditorState();
}

class _AdminCrosswordEditorState extends State<AdminCrosswordEditor> {
  late int _rows;
  late int _cols;
  late List<List<String>> _grid;
  late List<_Clue> _clues;
  bool _isValid = false;
  List<String> _errors = [];

  @override
  void initState() {
    super.initState();
    final data = widget.initialPuzzleData ?? {};

    _rows = data['rows'] as int? ?? 10;
    _cols = data['cols'] as int? ?? 10;

    // Parse grid
    final gridData = data['grid'] as List<dynamic>?;
    if (gridData != null) {
      _grid = gridData.map((row) {
        return (row as List<dynamic>).map((cell) => cell as String).toList();
      }).toList();
    } else {
      _grid = List.generate(_rows, (_) => List.generate(_cols, (_) => '#'));
    }

    // Parse clues
    final cluesData = data['clues'] as List<dynamic>?;
    if (cluesData != null) {
      _clues = cluesData.map((c) {
        final clue = c as Map<String, dynamic>;
        return _Clue(
          number: clue['number'] as int,
          direction: clue['direction'] as String,
          clue: clue['clue'] as String,
          answer: clue['answer'] as String,
          startRow: clue['startRow'] as int,
          startCol: clue['startCol'] as int,
        );
      }).toList();
    } else {
      _clues = [];
    }

    _validate();
  }

  void _validate() {
    final errors = <String>[];

    // Check grid dimensions
    if (_rows < 5 || _rows > 20) {
      errors.add('Rows must be between 5 and 20');
    }
    if (_cols < 5 || _cols > 20) {
      errors.add('Columns must be between 5 and 20');
    }

    // Check clues
    if (_clues.isEmpty) {
      errors.add('Add at least one clue');
    }

    // Check clue validity
    for (int i = 0; i < _clues.length; i++) {
      final clue = _clues[i];
      if (clue.clue.trim().isEmpty) {
        errors.add('Clue ${i + 1} has no text');
      }
      if (clue.answer.trim().isEmpty) {
        errors.add('Clue ${i + 1} has no answer');
      }
      if (clue.startRow < 0 || clue.startRow >= _rows) {
        errors.add('Clue ${i + 1} has invalid start row');
      }
      if (clue.startCol < 0 || clue.startCol >= _cols) {
        errors.add('Clue ${i + 1} has invalid start column');
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
        'rows': _rows,
        'cols': _cols,
        'grid': _grid,
        'clues': _clues.map((c) => {
          'number': c.number,
          'direction': c.direction,
          'clue': c.clue,
          'answer': c.answer,
          'startRow': c.startRow,
          'startCol': c.startCol,
        }).toList(),
      },
      {},
      _isValid,
    );
  }

  void _toggleCell(int row, int col) {
    setState(() {
      if (_grid[row][col] == '#') {
        _grid[row][col] = '';
      } else {
        _grid[row][col] = '#';
      }
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
          return '#';
        });
      });
    });
    _validate();
  }

  void _addClue() {
    setState(() {
      _clues.add(_Clue(
        number: _clues.length + 1,
        direction: 'across',
        clue: '',
        answer: '',
        startRow: 0,
        startCol: 0,
      ));
    });
  }

  void _removeClue(int index) {
    setState(() {
      _clues.removeAt(index);
      // Renumber remaining clues
      for (int i = 0; i < _clues.length; i++) {
        _clues[i] = _Clue(
          number: i + 1,
          direction: _clues[i].direction,
          clue: _clues[i].clue,
          answer: _clues[i].answer,
          startRow: _clues[i].startRow,
          startCol: _clues[i].startCol,
        );
      }
    });
    _validate();
  }

  void _updateClue(int index, _Clue clue) {
    setState(() {
      _clues[index] = clue;
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
        Row(
          children: [
            DropdownButton<int>(
              value: _rows,
              items: List.generate(16, (i) => i + 5)
                  .map((r) => DropdownMenuItem(value: r, child: Text('$r rows')))
                  .toList(),
              onChanged: (value) {
                if (value != null) _resizeGrid(value, _cols);
              },
            ),
            const SizedBox(width: 16),
            DropdownButton<int>(
              value: _cols,
              items: List.generate(16, (i) => i + 5)
                  .map((c) => DropdownMenuItem(value: c, child: Text('$c cols')))
                  .toList(),
              onChanged: (value) {
                if (value != null) _resizeGrid(_rows, value);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Click cells to toggle blocked (#). Type letters to fill.',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // Grid
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(_rows, (row) {
              return Row(
                children: List.generate(_cols, (col) {
                  final cell = _grid[row][col];
                  final isBlocked = cell == '#';

                  return GestureDetector(
                    onTap: () => _toggleCell(row, col),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isBlocked ? Colors.black : Colors.white,
                        border: Border.all(color: Colors.grey, width: 0.5),
                      ),
                      child: isBlocked
                          ? null
                          : Center(
                              child: Text(
                                cell,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
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
        const SizedBox(height: 24),

        // Clues section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Clues (${_clues.length})',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: _addClue,
              tooltip: 'Add clue',
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_clues.isEmpty)
          const Text('No clues. Click + to add clues.', style: TextStyle(color: Colors.grey))
        else
          ...List.generate(_clues.length, (index) {
            return _buildClueEditor(index, _clues[index]);
          }),

        const SizedBox(height: 24),

        // Validation status
        AdminValidationStatus(
          isValid: _isValid,
          errors: _errors,
          successMessage: '${_rows}x$_cols crossword with ${_clues.length} clues',
        ),
      ],
    );
  }

  Widget _buildClueEditor(int index, _Clue clue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${clue.number}. ', style: const TextStyle(fontWeight: FontWeight.bold)),
              // Direction
              DropdownButton<String>(
                value: clue.direction,
                items: const [
                  DropdownMenuItem(value: 'across', child: Text('Across')),
                  DropdownMenuItem(value: 'down', child: Text('Down')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _updateClue(index, _Clue(
                      number: clue.number,
                      direction: value,
                      clue: clue.clue,
                      answer: clue.answer,
                      startRow: clue.startRow,
                      startCol: clue.startCol,
                    ));
                  }
                },
              ),
              const Spacer(),
              // Position
              Text('Row: '),
              SizedBox(
                width: 50,
                child: TextFormField(
                  initialValue: clue.startRow.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                  onChanged: (value) {
                    final parsed = int.tryParse(value) ?? 0;
                    _updateClue(index, _Clue(
                      number: clue.number,
                      direction: clue.direction,
                      clue: clue.clue,
                      answer: clue.answer,
                      startRow: parsed,
                      startCol: clue.startCol,
                    ));
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text('Col: '),
              SizedBox(
                width: 50,
                child: TextFormField(
                  initialValue: clue.startCol.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                  onChanged: (value) {
                    final parsed = int.tryParse(value) ?? 0;
                    _updateClue(index, _Clue(
                      number: clue.number,
                      direction: clue.direction,
                      clue: clue.clue,
                      answer: clue.answer,
                      startRow: clue.startRow,
                      startCol: parsed,
                    ));
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                color: Colors.red,
                onPressed: () => _removeClue(index),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Clue text
          TextFormField(
            initialValue: clue.clue,
            decoration: const InputDecoration(
              labelText: 'Clue',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _updateClue(index, _Clue(
                number: clue.number,
                direction: clue.direction,
                clue: value,
                answer: clue.answer,
                startRow: clue.startRow,
                startCol: clue.startCol,
              ));
            },
          ),
          const SizedBox(height: 8),
          // Answer
          TextFormField(
            initialValue: clue.answer,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Answer',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _updateClue(index, _Clue(
                number: clue.number,
                direction: clue.direction,
                clue: clue.clue,
                answer: value.toUpperCase(),
                startRow: clue.startRow,
                startCol: clue.startCol,
              ));
            },
          ),
        ],
      ),
    );
  }
}

class _Clue {
  final int number;
  final String direction;
  final String clue;
  final String answer;
  final int startRow;
  final int startCol;

  _Clue({
    required this.number,
    required this.direction,
    required this.clue,
    required this.answer,
    required this.startRow,
    required this.startCol,
  });
}
