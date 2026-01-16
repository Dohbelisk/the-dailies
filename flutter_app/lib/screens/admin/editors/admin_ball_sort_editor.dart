import 'package:flutter/material.dart';
import '../../../widgets/admin/admin_color_picker.dart';
import '../../../widgets/admin/admin_validation_status.dart';

/// Editor for Ball Sort puzzles
class AdminBallSortEditor extends StatefulWidget {
  final Map<String, dynamic>? initialPuzzleData;
  final Map<String, dynamic>? initialSolution;
  final void Function(Map<String, dynamic> puzzleData, Map<String, dynamic> solution, bool isValid) onChange;

  const AdminBallSortEditor({
    super.key,
    this.initialPuzzleData,
    this.initialSolution,
    required this.onChange,
  });

  @override
  State<AdminBallSortEditor> createState() => _AdminBallSortEditorState();
}

class _AdminBallSortEditorState extends State<AdminBallSortEditor> {
  late List<List<String>> _tubes;
  late int _tubeCapacity;
  String? _selectedColor;
  bool _isValid = false;
  List<String> _errors = [];

  static const List<String> _availableColors = [
    'red', 'blue', 'green', 'yellow', 'purple', 'orange', 'pink', 'cyan'
  ];

  @override
  void initState() {
    super.initState();
    final data = widget.initialPuzzleData ?? {};

    _tubeCapacity = data['tubeCapacity'] as int? ?? 4;

    // Parse initial state
    final initialState = data['initialState'] as List<dynamic>? ?? data['tubes'] as List<dynamic>?;
    if (initialState != null) {
      _tubes = initialState.map((tube) {
        return (tube as List<dynamic>).map((ball) => ball as String).toList();
      }).toList();
    } else {
      // Default: 5 tubes, 3 with mixed balls, 2 empty
      _tubes = [
        ['red', 'blue', 'green', 'red'],
        ['green', 'red', 'blue', 'green'],
        ['blue', 'green', 'red', 'blue'],
        [],
        [],
      ];
    }

    _validate();
  }

  Color _getColorValue(String name) {
    switch (name.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'purple':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      case 'pink':
        return Colors.pink;
      case 'cyan':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  void _validate() {
    final errors = <String>[];

    // Check we have at least 3 tubes
    if (_tubes.length < 3) {
      errors.add('Need at least 3 tubes');
    }

    // Check tube capacity
    for (int i = 0; i < _tubes.length; i++) {
      if (_tubes[i].length > _tubeCapacity) {
        errors.add('Tube ${i + 1} exceeds capacity');
      }
    }

    // Count balls per color
    final colorCounts = <String, int>{};
    for (final tube in _tubes) {
      for (final ball in tube) {
        colorCounts[ball] = (colorCounts[ball] ?? 0) + 1;
      }
    }

    // Check each color has exactly tubeCapacity balls
    for (final entry in colorCounts.entries) {
      if (entry.value != _tubeCapacity) {
        errors.add('${entry.key} has ${entry.value} balls (need $_tubeCapacity)');
      }
    }

    // Check there are at least 2 empty tubes (or enough space)
    int emptyTubes = _tubes.where((t) => t.isEmpty).length;
    if (emptyTubes < 2) {
      errors.add('Need at least 2 empty tubes');
    }

    setState(() {
      _errors = errors;
      _isValid = errors.isEmpty;
    });

    _notifyChange();
  }

  void _notifyChange() {
    // Generate solution (all same color in each tube)
    final colorCounts = <String, int>{};
    for (final tube in _tubes) {
      for (final ball in tube) {
        colorCounts[ball] = (colorCounts[ball] ?? 0) + 1;
      }
    }

    final solutionTubes = <List<String>>[];
    for (final color in colorCounts.keys) {
      solutionTubes.add(List.filled(_tubeCapacity, color));
    }
    // Add empty tubes
    while (solutionTubes.length < _tubes.length) {
      solutionTubes.add([]);
    }

    widget.onChange(
      {
        'tubes': _tubes,
        'initialState': _tubes,
        'tubeCapacity': _tubeCapacity,
      },
      {
        'tubes': solutionTubes,
      },
      _isValid,
    );
  }

  void _addTube() {
    setState(() {
      _tubes.add([]);
    });
    _validate();
  }

  void _removeTube(int index) {
    if (_tubes.length > 3) {
      setState(() {
        _tubes.removeAt(index);
      });
      _validate();
    }
  }

  void _addBallToTube(int tubeIndex) {
    if (_selectedColor != null && _tubes[tubeIndex].length < _tubeCapacity) {
      setState(() {
        _tubes[tubeIndex].add(_selectedColor!);
      });
      _validate();
    }
  }

  void _removeBallFromTube(int tubeIndex) {
    if (_tubes[tubeIndex].isNotEmpty) {
      setState(() {
        _tubes[tubeIndex].removeLast();
      });
      _validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tube capacity
        Row(
          children: [
            const Text('Tube Capacity: ', style: TextStyle(fontWeight: FontWeight.w600)),
            DropdownButton<int>(
              value: _tubeCapacity,
              items: [3, 4, 5].map((c) => DropdownMenuItem(value: c, child: Text('$c'))).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _tubeCapacity = value);
                  _validate();
                }
              },
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _addTube,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Tube'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Color picker
        Text(
          'Select Color to Add',
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
        const SizedBox(height: 24),

        // Tubes
        Text(
          'Tubes (tap tube to add ball, long-press to remove)',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(_tubes.length, (index) {
              return _buildTube(index);
            }),
          ),
        ),
        const SizedBox(height: 24),

        // Stats
        Text(
          'Tubes: ${_tubes.length} | Colors: ${_tubes.expand((t) => t).toSet().length}',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // Validation status
        AdminValidationStatus(
          isValid: _isValid,
          errors: _errors,
          successMessage: 'Ball Sort puzzle ready',
        ),
      ],
    );
  }

  Widget _buildTube(int index) {
    final tube = _tubes[index];

    return GestureDetector(
      onTap: () => _addBallToTube(index),
      onLongPress: () => _removeBallFromTube(index),
      child: Container(
        width: 50,
        margin: const EdgeInsets.only(right: 8),
        child: Column(
          children: [
            // Remove button
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: _tubes.length > 3 ? () => _removeTube(index) : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            // Tube
            Container(
              height: _tubeCapacity * 36.0 + 16,
              width: 44,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 2),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ...tube.reversed.map((ball) {
                    return Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: _getColorValue(ball),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _getColorValue(ball).withValues(alpha: 0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 4),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text('${index + 1}', style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
