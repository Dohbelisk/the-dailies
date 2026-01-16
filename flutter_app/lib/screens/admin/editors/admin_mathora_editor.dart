import 'package:flutter/material.dart';
import '../../../widgets/admin/admin_validation_status.dart';

/// Editor for Mathora puzzles
class AdminMathoraEditor extends StatefulWidget {
  final Map<String, dynamic>? initialPuzzleData;
  final Map<String, dynamic>? initialSolution;
  final void Function(Map<String, dynamic> puzzleData, Map<String, dynamic> solution, bool isValid) onChange;

  const AdminMathoraEditor({
    super.key,
    this.initialPuzzleData,
    this.initialSolution,
    required this.onChange,
  });

  @override
  State<AdminMathoraEditor> createState() => _AdminMathoraEditorState();
}

class _AdminMathoraEditorState extends State<AdminMathoraEditor> {
  late int _startNumber;
  late int _targetNumber;
  late int _moves;
  late List<_Operation> _operations;
  bool _isValid = false;
  List<String> _errors = [];

  @override
  void initState() {
    super.initState();
    final data = widget.initialPuzzleData ?? {};

    _startNumber = data['startNumber'] as int? ?? 1;
    _targetNumber = data['targetNumber'] as int? ?? 100;
    _moves = data['moves'] as int? ?? 3;

    // Parse operations
    final opsData = data['operations'] as List<dynamic>?;
    if (opsData != null) {
      _operations = opsData.map((op) {
        final map = op as Map<String, dynamic>;
        return _Operation(
          type: map['type'] as String,
          value: map['value'] as int,
          display: map['display'] as String,
        );
      }).toList();
    } else {
      _operations = [
        _Operation(type: 'add', value: 10, display: '+10'),
        _Operation(type: 'multiply', value: 2, display: 'x2'),
        _Operation(type: 'subtract', value: 5, display: '-5'),
      ];
    }

    _validate();
  }

  void _validate() {
    final errors = <String>[];

    // Check start number
    if (_startNumber < 1 || _startNumber > 1000) {
      errors.add('Start number must be between 1 and 1000');
    }

    // Check target number
    if (_targetNumber < 1 || _targetNumber > 10000) {
      errors.add('Target number must be between 1 and 10000');
    }

    // Check moves
    if (_moves < 1 || _moves > 10) {
      errors.add('Moves must be between 1 and 10');
    }

    // Check operations
    if (_operations.isEmpty) {
      errors.add('At least one operation is required');
    }
    if (_operations.length > 12) {
      errors.add('Maximum 12 operations allowed');
    }

    // Validate each operation
    for (int i = 0; i < _operations.length; i++) {
      final op = _operations[i];
      if (op.value == 0 && op.type == 'divide') {
        errors.add('Operation ${i + 1}: Cannot divide by 0');
      }
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
        'startNumber': _startNumber,
        'targetNumber': _targetNumber,
        'moves': _moves,
        'operations': _operations.map((op) => {
          'type': op.type,
          'value': op.value,
          'display': op.display,
        }).toList(),
      },
      {}, // Solution is computed at play time
      _isValid,
    );
  }

  void _addOperation() {
    setState(() {
      _operations.add(_Operation(type: 'add', value: 1, display: '+1'));
    });
    _validate();
  }

  void _removeOperation(int index) {
    setState(() {
      _operations.removeAt(index);
    });
    _validate();
  }

  void _updateOperation(int index, _Operation op) {
    setState(() {
      _operations[index] = op;
    });
    _validate();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Basic settings
        Row(
          children: [
            // Start number
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Start', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextFormField(
                    initialValue: _startNumber.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null) {
                        _startNumber = parsed;
                        _validate();
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.arrow_forward),
            const SizedBox(width: 16),
            // Target number
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Target', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextFormField(
                    initialValue: _targetNumber.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null) {
                        _targetNumber = parsed;
                        _validate();
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Moves
            SizedBox(
              width: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Moves', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextFormField(
                    initialValue: _moves.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null) {
                        _moves = parsed;
                        _validate();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Operations
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Operations',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: _addOperation,
              tooltip: 'Add operation',
            ),
          ],
        ),
        const SizedBox(height: 8),

        ...List.generate(_operations.length, (index) {
          return _buildOperationRow(index, _operations[index]);
        }),

        // Quick add buttons
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickAddButton('+10', 'add', 10),
            _buildQuickAddButton('+50', 'add', 50),
            _buildQuickAddButton('x2', 'multiply', 2),
            _buildQuickAddButton('x5', 'multiply', 5),
            _buildQuickAddButton('-5', 'subtract', 5),
            _buildQuickAddButton('/2', 'divide', 2),
          ],
        ),
        const SizedBox(height: 24),

        // Validation status
        AdminValidationStatus(
          isValid: _isValid,
          errors: _errors,
          successMessage: 'Start: $_startNumber → Target: $_targetNumber in $_moves moves',
        ),
      ],
    );
  }

  Widget _buildOperationRow(int index, _Operation op) {
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
          // Type dropdown
          DropdownButton<String>(
            value: op.type,
            items: const [
              DropdownMenuItem(value: 'add', child: Text('+')),
              DropdownMenuItem(value: 'subtract', child: Text('-')),
              DropdownMenuItem(value: 'multiply', child: Text('x')),
              DropdownMenuItem(value: 'divide', child: Text('/')),
            ],
            onChanged: (value) {
              if (value != null) {
                final symbol = {'add': '+', 'subtract': '-', 'multiply': 'x', 'divide': '/'}[value]!;
                _updateOperation(index, _Operation(
                  type: value,
                  value: op.value,
                  display: '$symbol${op.value}',
                ));
              }
            },
          ),
          const SizedBox(width: 8),
          // Value input
          SizedBox(
            width: 80,
            child: TextFormField(
              initialValue: op.value.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) {
                final parsed = int.tryParse(value);
                if (parsed != null) {
                  final symbol = {'add': '+', 'subtract': '-', 'multiply': 'x', 'divide': '/'}[op.type]!;
                  _updateOperation(index, _Operation(
                    type: op.type,
                    value: parsed,
                    display: '$symbol$parsed',
                  ));
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          // Preview
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              op.display,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Spacer(),
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete, size: 20),
            color: Colors.red,
            onPressed: () => _removeOperation(index),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddButton(String label, String type, int value) {
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _operations.add(_Operation(type: type, value: value, display: label));
        });
        _validate();
      },
      child: Text(label),
    );
  }
}

class _Operation {
  final String type;
  final int value;
  final String display;

  _Operation({required this.type, required this.value, required this.display});
}
