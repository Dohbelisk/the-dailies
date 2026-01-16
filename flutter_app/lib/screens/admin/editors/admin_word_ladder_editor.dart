import 'package:flutter/material.dart';
import '../../../widgets/admin/admin_validation_status.dart';

/// Editor for Word Ladder puzzles
class AdminWordLadderEditor extends StatefulWidget {
  final Map<String, dynamic>? initialPuzzleData;
  final Map<String, dynamic>? initialSolution;
  final void Function(Map<String, dynamic> puzzleData, Map<String, dynamic> solution, bool isValid) onChange;

  const AdminWordLadderEditor({
    super.key,
    this.initialPuzzleData,
    this.initialSolution,
    required this.onChange,
  });

  @override
  State<AdminWordLadderEditor> createState() => _AdminWordLadderEditorState();
}

class _AdminWordLadderEditorState extends State<AdminWordLadderEditor> {
  late TextEditingController _startWordController;
  late TextEditingController _targetWordController;
  late TextEditingController _solutionPathController;
  bool _isValid = false;
  List<String> _errors = [];

  @override
  void initState() {
    super.initState();
    final data = widget.initialPuzzleData ?? {};
    final solution = widget.initialSolution ?? {};

    _startWordController = TextEditingController(text: data['startWord'] ?? '');
    _targetWordController = TextEditingController(text: data['targetWord'] ?? '');

    // Solution path
    final pathList = solution['path'] as List<dynamic>? ?? [];
    _solutionPathController = TextEditingController(
      text: pathList.join(', '),
    );

    _validate();
  }

  @override
  void dispose() {
    _startWordController.dispose();
    _targetWordController.dispose();
    _solutionPathController.dispose();
    super.dispose();
  }

  void _validate() {
    final errors = <String>[];
    final startWord = _startWordController.text.trim().toUpperCase();
    final targetWord = _targetWordController.text.trim().toUpperCase();

    // Check start word
    if (startWord.isEmpty) {
      errors.add('Start word is required');
    } else if (startWord.length < 3 || startWord.length > 5) {
      errors.add('Start word must be 3-5 letters');
    }

    // Check target word
    if (targetWord.isEmpty) {
      errors.add('Target word is required');
    } else if (targetWord.length < 3 || targetWord.length > 5) {
      errors.add('Target word must be 3-5 letters');
    }

    // Check word lengths match
    if (startWord.isNotEmpty && targetWord.isNotEmpty && startWord.length != targetWord.length) {
      errors.add('Start and target words must have the same length');
    }

    // Check words are different
    if (startWord.isNotEmpty && startWord == targetWord) {
      errors.add('Start and target words must be different');
    }

    setState(() {
      _errors = errors;
      _isValid = errors.isEmpty;
    });

    _notifyChange();
  }

  void _notifyChange() {
    final startWord = _startWordController.text.trim().toUpperCase();
    final targetWord = _targetWordController.text.trim().toUpperCase();

    // Parse solution path
    final pathStr = _solutionPathController.text.trim();
    final path = pathStr.isNotEmpty
        ? pathStr.split(',').map((s) => s.trim().toUpperCase()).where((s) => s.isNotEmpty).toList()
        : <String>[];

    widget.onChange(
      {
        'startWord': startWord,
        'targetWord': targetWord,
        'wordLength': startWord.length,
      },
      {
        'path': path,
      },
      _isValid,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Start Word
        Text(
          'Start Word',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 200,
          child: TextFormField(
            controller: _startWordController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'e.g., COLD',
            ),
            onChanged: (_) => _validate(),
          ),
        ),
        const SizedBox(height: 24),

        // Target Word
        Text(
          'Target Word',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 200,
          child: TextFormField(
            controller: _targetWordController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'e.g., WARM',
            ),
            onChanged: (_) => _validate(),
          ),
        ),
        const SizedBox(height: 24),

        // Solution Path
        Text(
          'Solution Path (comma-separated)',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Include all words from start to target',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _solutionPathController,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'e.g., COLD, CORD, CARD, WARD, WARM',
          ),
          onChanged: (_) => _notifyChange(),
        ),
        const SizedBox(height: 24),

        // Preview
        if (_startWordController.text.isNotEmpty && _targetWordController.text.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildWordBox(_startWordController.text.toUpperCase()),
                const SizedBox(width: 16),
                const Icon(Icons.arrow_forward),
                const SizedBox(width: 16),
                _buildWordBox(_targetWordController.text.toUpperCase()),
              ],
            ),
          ),
        const SizedBox(height: 24),

        // Validation status
        AdminValidationStatus(
          isValid: _isValid,
          errors: _errors,
          successMessage: 'Word ladder: ${_startWordController.text.toUpperCase()} → ${_targetWordController.text.toUpperCase()}',
        ),
      ],
    );
  }

  Widget _buildWordBox(String word) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Text(
        word,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 4,
        ),
      ),
    );
  }
}
