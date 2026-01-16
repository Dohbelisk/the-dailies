import 'package:flutter/material.dart';
import '../../../widgets/admin/admin_validation_status.dart';

/// Editor for Number Target puzzles
class AdminNumberTargetEditor extends StatefulWidget {
  final Map<String, dynamic>? initialPuzzleData;
  final Map<String, dynamic>? initialSolution;
  final void Function(Map<String, dynamic> puzzleData, Map<String, dynamic> solution, bool isValid) onChange;

  const AdminNumberTargetEditor({
    super.key,
    this.initialPuzzleData,
    this.initialSolution,
    required this.onChange,
  });

  @override
  State<AdminNumberTargetEditor> createState() => _AdminNumberTargetEditorState();
}

class _AdminNumberTargetEditorState extends State<AdminNumberTargetEditor> {
  late List<int> _numbers;
  late int _target;
  bool _isValid = false;
  List<String> _errors = [];

  @override
  void initState() {
    super.initState();
    final data = widget.initialPuzzleData ?? {};
    final numbersList = data['numbers'] as List<dynamic>? ?? [25, 50, 75, 100, 3, 6];
    _numbers = numbersList.map((n) => n as int).toList();
    // Ensure we have exactly 6 numbers
    while (_numbers.length < 6) {
      _numbers.add(1);
    }
    _target = data['target'] as int? ?? 100;
    _validate();
  }

  void _validate() {
    final errors = <String>[];

    // Check numbers
    if (_numbers.length != 6) {
      errors.add('Must have exactly 6 numbers');
    }
    for (int i = 0; i < _numbers.length; i++) {
      if (_numbers[i] < 1 || _numbers[i] > 100) {
        errors.add('Number ${i + 1} must be between 1 and 100');
      }
    }

    // Check target
    if (_target < 100 || _target > 999) {
      errors.add('Target must be between 100 and 999');
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
        'numbers': _numbers,
        'target': _target,
      },
      {}, // Number Target doesn't store solution in the same way
      _isValid,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Target number
        Text(
          'Target Number',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 120,
          child: TextFormField(
            initialValue: _target.toString(),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '100-999',
            ),
            onChanged: (value) {
              final parsed = int.tryParse(value);
              if (parsed != null) {
                _target = parsed;
                _validate();
              }
            },
          ),
        ),
        const SizedBox(height: 24),

        // Numbers
        Text(
          'Available Numbers (6)',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 80,
              child: TextFormField(
                initialValue: _numbers[index].toString(),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Num ${index + 1}',
                ),
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  if (parsed != null) {
                    _numbers[index] = parsed;
                    _validate();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 16),

        // Quick presets
        Text(
          'Quick Presets',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPresetButton('Standard', [25, 50, 75, 100, 3, 6]),
            _buildPresetButton('Small', [1, 2, 3, 4, 5, 6]),
            _buildPresetButton('Large', [25, 50, 75, 100, 7, 8]),
          ],
        ),
        const SizedBox(height: 24),

        // Validation status
        AdminValidationStatus(
          isValid: _isValid,
          errors: _errors,
          successMessage: 'Target: $_target with numbers ${_numbers.join(", ")}',
        ),
      ],
    );
  }

  Widget _buildPresetButton(String label, List<int> preset) {
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _numbers = List.from(preset);
        });
        _validate();
      },
      child: Text(label),
    );
  }
}
