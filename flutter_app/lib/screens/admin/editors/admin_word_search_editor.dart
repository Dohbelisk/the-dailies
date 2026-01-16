import 'package:flutter/material.dart';
import '../../../widgets/admin/admin_validation_status.dart';

/// Editor for Word Search puzzles
class AdminWordSearchEditor extends StatefulWidget {
  final Map<String, dynamic>? initialPuzzleData;
  final Map<String, dynamic>? initialSolution;
  final void Function(Map<String, dynamic> puzzleData, Map<String, dynamic> solution, bool isValid) onChange;

  const AdminWordSearchEditor({
    super.key,
    this.initialPuzzleData,
    this.initialSolution,
    required this.onChange,
  });

  @override
  State<AdminWordSearchEditor> createState() => _AdminWordSearchEditorState();
}

class _AdminWordSearchEditorState extends State<AdminWordSearchEditor> {
  late int _rows;
  late int _cols;
  late List<List<String>> _grid;
  late List<_WordPlacement> _words;
  late String _theme;
  late TextEditingController _themeController;
  bool _isValid = false;
  List<String> _errors = [];

  @override
  void initState() {
    super.initState();
    final data = widget.initialPuzzleData ?? {};

    _rows = data['rows'] as int? ?? 10;
    _cols = data['cols'] as int? ?? 10;
    _theme = data['theme'] as String? ?? '';
    _themeController = TextEditingController(text: _theme);

    // Parse grid
    final gridData = data['grid'] as List<dynamic>?;
    if (gridData != null) {
      _grid = gridData.map((row) {
        return (row as List<dynamic>).map((cell) => cell as String).toList();
      }).toList();
    } else {
      _grid = List.generate(_rows, (_) => List.generate(_cols, (_) => ''));
    }

    // Parse words
    final wordsData = data['words'] as List<dynamic>?;
    if (wordsData != null) {
      _words = wordsData.map((w) {
        final word = w as Map<String, dynamic>;
        return _WordPlacement(
          word: word['word'] as String,
          startRow: word['startRow'] as int,
          startCol: word['startCol'] as int,
          endRow: word['endRow'] as int,
          endCol: word['endCol'] as int,
        );
      }).toList();
    } else {
      _words = [];
    }

    _validate();
  }

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
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

    // Check theme
    if (_theme.trim().isEmpty) {
      errors.add('Theme is required');
    }

    // Check words
    if (_words.isEmpty) {
      errors.add('Add at least one word');
    }

    // Check word validity
    for (int i = 0; i < _words.length; i++) {
      final word = _words[i];
      if (word.word.trim().isEmpty) {
        errors.add('Word ${i + 1} is empty');
      }
      if (word.word.length < 3) {
        errors.add('Word "${word.word}" is too short (min 3 letters)');
      }
      // Check bounds
      if (word.startRow < 0 || word.startRow >= _rows ||
          word.endRow < 0 || word.endRow >= _rows ||
          word.startCol < 0 || word.startCol >= _cols ||
          word.endCol < 0 || word.endCol >= _cols) {
        errors.add('Word "${word.word}" is out of bounds');
      }
    }

    // Check grid is filled
    for (int r = 0; r < _rows; r++) {
      for (int c = 0; c < _cols; c++) {
        if (_grid[r][c].isEmpty) {
          errors.add('Grid has empty cells');
          break;
        }
      }
      if (errors.isNotEmpty && errors.last == 'Grid has empty cells') break;
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
        'theme': _theme,
        'grid': _grid,
        'words': _words.map((w) => {
          'word': w.word,
          'startRow': w.startRow,
          'startCol': w.startCol,
          'endRow': w.endRow,
          'endCol': w.endCol,
        }).toList(),
      },
      {},
      _isValid,
    );
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
          return '';
        });
      });
    });
    _validate();
  }

  void _addWord() {
    setState(() {
      _words.add(_WordPlacement(
        word: '',
        startRow: 0,
        startCol: 0,
        endRow: 0,
        endCol: 0,
      ));
    });
  }

  void _removeWord(int index) {
    setState(() {
      _words.removeAt(index);
    });
    _validate();
  }

  void _updateWord(int index, _WordPlacement word) {
    setState(() {
      _words[index] = word;
    });
    _validate();
  }

  void _fillRandomLetters() {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    setState(() {
      for (int r = 0; r < _rows; r++) {
        for (int c = 0; c < _cols; c++) {
          if (_grid[r][c].isEmpty) {
            _grid[r][c] = letters[DateTime.now().microsecondsSinceEpoch % 26];
          }
        }
      }
    });
    _validate();
  }

  void _clearGrid() {
    setState(() {
      _grid = List.generate(_rows, (_) => List.generate(_cols, (_) => ''));
    });
    _validate();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Theme
        TextFormField(
          controller: _themeController,
          decoration: const InputDecoration(
            labelText: 'Theme',
            hintText: 'e.g., Animals, Countries, etc.',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            _theme = value;
            _validate();
          },
        ),
        const SizedBox(height: 16),

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
                  return Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: cell.isEmpty ? Colors.grey[200] : Colors.white,
                      border: Border.all(color: Colors.grey, width: 0.5),
                    ),
                    child: Center(
                      child: Text(
                        cell,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  );
                }),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),

        // Grid actions
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _fillRandomLetters,
              icon: const Icon(Icons.shuffle, size: 18),
              label: const Text('Fill Random'),
            ),
            OutlinedButton.icon(
              onPressed: _clearGrid,
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('Clear Grid'),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Words section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Words (${_words.length})',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: _addWord,
              tooltip: 'Add word',
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_words.isEmpty)
          const Text('No words. Click + to add words.', style: TextStyle(color: Colors.grey))
        else
          ...List.generate(_words.length, (index) {
            return _buildWordEditor(index, _words[index]);
          }),

        const SizedBox(height: 24),

        // Validation status
        AdminValidationStatus(
          isValid: _isValid,
          errors: _errors,
          successMessage: '${_rows}x$_cols word search with ${_words.length} words',
        ),
      ],
    );
  }

  Widget _buildWordEditor(int index, _WordPlacement word) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: word.word,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Word',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _updateWord(index, _WordPlacement(
                  word: value.toUpperCase(),
                  startRow: word.startRow,
                  startCol: word.startCol,
                  endRow: word.endRow,
                  endCol: word.endCol,
                ));
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: TextFormField(
              initialValue: word.startRow.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'SR',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                final parsed = int.tryParse(value) ?? 0;
                _updateWord(index, _WordPlacement(
                  word: word.word,
                  startRow: parsed,
                  startCol: word.startCol,
                  endRow: word.endRow,
                  endCol: word.endCol,
                ));
              },
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 50,
            child: TextFormField(
              initialValue: word.startCol.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'SC',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                final parsed = int.tryParse(value) ?? 0;
                _updateWord(index, _WordPlacement(
                  word: word.word,
                  startRow: word.startRow,
                  startCol: parsed,
                  endRow: word.endRow,
                  endCol: word.endCol,
                ));
              },
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 50,
            child: TextFormField(
              initialValue: word.endRow.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'ER',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                final parsed = int.tryParse(value) ?? 0;
                _updateWord(index, _WordPlacement(
                  word: word.word,
                  startRow: word.startRow,
                  startCol: word.startCol,
                  endRow: parsed,
                  endCol: word.endCol,
                ));
              },
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 50,
            child: TextFormField(
              initialValue: word.endCol.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'EC',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                final parsed = int.tryParse(value) ?? 0;
                _updateWord(index, _WordPlacement(
                  word: word.word,
                  startRow: word.startRow,
                  startCol: word.startCol,
                  endRow: word.endRow,
                  endCol: parsed,
                ));
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20),
            color: Colors.red,
            onPressed: () => _removeWord(index),
          ),
        ],
      ),
    );
  }
}

class _WordPlacement {
  final String word;
  final int startRow;
  final int startCol;
  final int endRow;
  final int endCol;

  _WordPlacement({
    required this.word,
    required this.startRow,
    required this.startCol,
    required this.endRow,
    required this.endCol,
  });
}
