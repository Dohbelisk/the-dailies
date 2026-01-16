import 'package:flutter/material.dart';
import 'dart:convert';

/// JSON editor for puzzle data - fallback for all puzzle types
class AdminJsonEditor extends StatefulWidget {
  final Map<String, dynamic> puzzleData;
  final Map<String, dynamic> solution;
  final void Function(Map<String, dynamic> puzzleData, Map<String, dynamic> solution, bool isValid) onChange;

  const AdminJsonEditor({
    super.key,
    required this.puzzleData,
    required this.solution,
    required this.onChange,
  });

  @override
  State<AdminJsonEditor> createState() => _AdminJsonEditorState();
}

class _AdminJsonEditorState extends State<AdminJsonEditor> {
  late TextEditingController _puzzleDataController;
  late TextEditingController _solutionController;
  String? _puzzleDataError;
  String? _solutionError;

  @override
  void initState() {
    super.initState();
    _puzzleDataController = TextEditingController(
      text: const JsonEncoder.withIndent('  ').convert(widget.puzzleData),
    );
    _solutionController = TextEditingController(
      text: const JsonEncoder.withIndent('  ').convert(widget.solution),
    );
  }

  @override
  void dispose() {
    _puzzleDataController.dispose();
    _solutionController.dispose();
    super.dispose();
  }

  void _validateAndNotify() {
    Map<String, dynamic>? parsedPuzzleData;
    Map<String, dynamic>? parsedSolution;
    String? puzzleDataError;
    String? solutionError;

    // Parse puzzle data
    try {
      parsedPuzzleData = json.decode(_puzzleDataController.text) as Map<String, dynamic>;
    } catch (e) {
      puzzleDataError = 'Invalid JSON: $e';
    }

    // Parse solution
    try {
      parsedSolution = json.decode(_solutionController.text) as Map<String, dynamic>;
    } catch (e) {
      solutionError = 'Invalid JSON: $e';
    }

    setState(() {
      _puzzleDataError = puzzleDataError;
      _solutionError = solutionError;
    });

    // Notify parent
    final isValid = puzzleDataError == null && solutionError == null;
    widget.onChange(
      parsedPuzzleData ?? widget.puzzleData,
      parsedSolution ?? widget.solution,
      isValid,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Puzzle Data section
          Text(
            'Puzzle Data',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _puzzleDataError != null ? Colors.red : theme.dividerColor,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _puzzleDataController,
                maxLines: null,
                expands: true,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(12),
                  border: InputBorder.none,
                  errorText: _puzzleDataError,
                ),
                onChanged: (_) => _validateAndNotify(),
              ),
            ),
          ),
          if (_puzzleDataError != null) ...[
            const SizedBox(height: 4),
            Text(
              _puzzleDataError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),

          // Solution section
          Text(
            'Solution',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _solutionError != null ? Colors.red : theme.dividerColor,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _solutionController,
                maxLines: null,
                expands: true,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(12),
                  border: InputBorder.none,
                  errorText: _solutionError,
                ),
                onChanged: (_) => _validateAndNotify(),
              ),
            ),
          ),
          if (_solutionError != null) ...[
            const SizedBox(height: 4),
            Text(
              _solutionError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
