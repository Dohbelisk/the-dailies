import 'package:flutter/material.dart';
import '../../../widgets/admin/admin_color_picker.dart';
import '../../../widgets/admin/admin_validation_status.dart';

/// Editor for Pipes puzzles
class AdminPipesEditor extends StatefulWidget {
  final Map<String, dynamic>? initialPuzzleData;
  final Map<String, dynamic>? initialSolution;
  final void Function(Map<String, dynamic> puzzleData, Map<String, dynamic> solution, bool isValid) onChange;

  const AdminPipesEditor({
    super.key,
    this.initialPuzzleData,
    this.initialSolution,
    required this.onChange,
  });

  @override
  State<AdminPipesEditor> createState() => _AdminPipesEditorState();
}

class _AdminPipesEditorState extends State<AdminPipesEditor> {
  late int _rows;
  late int _cols;
  late List<_Endpoint> _endpoints;
  String? _selectedColor;
  bool _isValid = false;
  List<String> _errors = [];

  static const List<String> _availableColors = [
    'red', 'blue', 'green', 'yellow', 'orange', 'purple', 'maroon', 'cyan', 'pink', 'lime',
    'teal', 'coral', 'navy', 'gold', 'crimson', 'olive', 'indigo', 'salmon', 'violet', 'tan',
  ];

  @override
  void initState() {
    super.initState();
    final data = widget.initialPuzzleData ?? {};

    _rows = data['rows'] as int? ?? 5;
    _cols = data['cols'] as int? ?? 5;

    // Parse endpoints
    final endpointsData = data['endpoints'] as List<dynamic>?;
    if (endpointsData != null) {
      _endpoints = endpointsData.map((e) {
        final map = e as Map<String, dynamic>;
        return _Endpoint(
          color: map['color'] as String,
          row: map['row'] as int,
          col: map['col'] as int,
        );
      }).toList();
    } else {
      _endpoints = [];
    }

    _validate();
  }

  static const Map<String, Color> _colorMap = {
    'red': Color(0xFFE53935),
    'blue': Color(0xFF1E88E5),
    'green': Color(0xFF43A047),
    'yellow': Color(0xFFFDD835),
    'orange': Color(0xFFFB8C00),
    'purple': Color(0xFF8E24AA),
    'maroon': Color(0xFF880E4F),
    'cyan': Color(0xFF00ACC1),
    'pink': Color(0xFFEC407A),
    'lime': Color(0xFFC0CA33),
    'teal': Color(0xFF00897B),
    'coral': Color(0xFFFF7043),
    'navy': Color(0xFF283593),
    'gold': Color(0xFFFFB300),
    'crimson': Color(0xFFB71C1C),
    'olive': Color(0xFF827717),
    'indigo': Color(0xFF5C6BC0),
    'salmon': Color(0xFFE57373),
    'violet': Color(0xFF7B1FA2),
    'tan': Color(0xFFD7CCC8),
  };

  Color _getColorValue(String name) {
    return _colorMap[name.toLowerCase()] ?? Colors.grey;
  }

  void _validate() {
    final errors = <String>[];

    // Check grid size
    if (_rows < 3 || _rows > 15) {
      errors.add('Rows must be between 3 and 15');
    }
    if (_cols < 3 || _cols > 15) {
      errors.add('Columns must be between 3 and 15');
    }

    // Check endpoints come in pairs
    final colorCounts = <String, int>{};
    for (final endpoint in _endpoints) {
      colorCounts[endpoint.color] = (colorCounts[endpoint.color] ?? 0) + 1;
    }

    for (final entry in colorCounts.entries) {
      if (entry.value != 2) {
        errors.add('${entry.key} has ${entry.value} endpoints (need 2)');
      }
    }

    // Check we have at least one color
    if (colorCounts.isEmpty) {
      errors.add('Add at least one pair of endpoints');
    }

    // Check for duplicate positions
    final positions = <String>{};
    for (final endpoint in _endpoints) {
      final key = '${endpoint.row},${endpoint.col}';
      if (positions.contains(key)) {
        errors.add('Multiple endpoints at row ${endpoint.row + 1}, col ${endpoint.col + 1}');
      }
      positions.add(key);
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
        'endpoints': _endpoints.map((e) => {
          'color': e.color,
          'row': e.row,
          'col': e.col,
        }).toList(),
        'bridges': [],
      },
      {}, // Solution paths would be computed
      _isValid,
    );
  }

  void _toggleEndpoint(int row, int col) {
    if (_selectedColor == null) return;

    // Check if there's an endpoint here
    final existingIndex = _endpoints.indexWhere((e) => e.row == row && e.col == col);

    if (existingIndex >= 0) {
      // Remove existing endpoint
      setState(() {
        _endpoints.removeAt(existingIndex);
      });
    } else {
      // Add new endpoint
      setState(() {
        _endpoints.add(_Endpoint(color: _selectedColor!, row: row, col: col));
      });
    }
    _validate();
  }

  void _resizeGrid(int newRows, int newCols) {
    setState(() {
      _rows = newRows;
      _cols = newCols;
      // Remove endpoints that are outside new bounds
      _endpoints.removeWhere((e) => e.row >= newRows || e.col >= newCols);
    });
    _validate();
  }

  void _clearAll() {
    setState(() {
      _endpoints.clear();
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
        Row(
          children: [
            DropdownButton<int>(
              value: _rows,
              items: List.generate(13, (i) => i + 3).map((r) =>
                  DropdownMenuItem(value: r, child: Text('$r rows'))).toList(),
              onChanged: (value) {
                if (value != null) _resizeGrid(value, _cols);
              },
            ),
            const SizedBox(width: 16),
            DropdownButton<int>(
              value: _cols,
              items: List.generate(13, (i) => i + 3).map((c) =>
                  DropdownMenuItem(value: c, child: Text('$c cols'))).toList(),
              onChanged: (value) {
                if (value != null) _resizeGrid(_rows, value);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Color picker
        Text(
          'Select Color for Endpoints',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        AdminColorPicker(
          selectedColor: _selectedColor,
          colors: _availableColors,
          onColorSelect: (color) {
            setState(() => _selectedColor = color);
          },
        ),
        const SizedBox(height: 16),

        // Instructions
        Text(
          'Tap grid cells to place endpoint pairs',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 8),

        // Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final editorCellSize = (constraints.maxWidth / _cols).clamp(24.0, 40.0);
            final dotSize = (editorCellSize * 0.6).clamp(14.0, 24.0);
            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_rows, (row) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_cols, (col) {
                      final endpoint = _endpoints.firstWhere(
                        (e) => e.row == row && e.col == col,
                        orElse: () => _Endpoint(color: '', row: -1, col: -1),
                      );
                      final hasEndpoint = endpoint.row >= 0;

                      return GestureDetector(
                        onTap: () => _toggleEndpoint(row, col),
                        child: Container(
                          width: editorCellSize,
                          height: editorCellSize,
                          decoration: BoxDecoration(
                            color: hasEndpoint
                                ? _getColorValue(endpoint.color).withValues(alpha: 0.3)
                                : null,
                            border: Border.all(
                              color: theme.dividerColor.withValues(alpha: 0.5),
                            ),
                          ),
                          child: hasEndpoint
                              ? Center(
                                  child: Container(
                                    width: dotSize,
                                    height: dotSize,
                                    decoration: BoxDecoration(
                                      color: _getColorValue(endpoint.color),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      );
                    }),
                  );
                }),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Actions
        OutlinedButton.icon(
          onPressed: _clearAll,
          icon: const Icon(Icons.clear, size: 18),
          label: const Text('Clear All'),
        ),
        const SizedBox(height: 16),

        // Color counts
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableColors.map((color) {
            final count = _endpoints.where((e) => e.color == color).length;
            if (count == 0) return const SizedBox.shrink();
            return Chip(
              avatar: CircleAvatar(backgroundColor: _getColorValue(color), radius: 10),
              label: Text('$count/2'),
              backgroundColor: count == 2 ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Validation status
        AdminValidationStatus(
          isValid: _isValid,
          errors: _errors,
          successMessage: '${_rows}x$_cols pipes puzzle with ${_endpoints.length ~/ 2} colors',
        ),
      ],
    );
  }
}

class _Endpoint {
  final String color;
  final int row;
  final int col;

  _Endpoint({required this.color, required this.row, required this.col});
}
