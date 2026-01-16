import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/game_models.dart';
import 'editors/admin_json_editor.dart';
import 'editors/admin_sudoku_editor.dart';
import 'editors/admin_killer_sudoku_editor.dart';
import 'editors/admin_crossword_editor.dart';
import 'editors/admin_word_search_editor.dart';
import 'editors/admin_word_forge_editor.dart';
import 'editors/admin_nonogram_editor.dart';
import 'editors/admin_number_target_editor.dart';
import 'editors/admin_ball_sort_editor.dart';
import 'editors/admin_pipes_editor.dart';
import 'editors/admin_lights_out_editor.dart';
import 'editors/admin_word_ladder_editor.dart';
import 'editors/admin_connections_editor.dart';
import 'editors/admin_mathora_editor.dart';

/// Callback type for editor changes
typedef EditorOnChange = void Function(
  Map<String, dynamic> puzzleData,
  Map<String, dynamic> solution,
  bool isValid,
);

/// Admin screen to edit a specific puzzle
class AdminPuzzleEditScreen extends StatefulWidget {
  final DailyPuzzle puzzle;

  const AdminPuzzleEditScreen({super.key, required this.puzzle});

  @override
  State<AdminPuzzleEditScreen> createState() => _AdminPuzzleEditScreenState();
}

class _AdminPuzzleEditScreenState extends State<AdminPuzzleEditScreen> {
  final ApiService _apiService = ApiService(authService: AuthService());

  bool _isJsonMode = false;
  bool _isSaving = false;
  bool _isValid = true;
  bool _hasChanges = false;

  late Map<String, dynamic> _puzzleData;
  late Map<String, dynamic> _solution;
  late Difficulty _difficulty;
  late int _targetTime;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _puzzleData = Map<String, dynamic>.from(widget.puzzle.puzzleData);
    _solution = widget.puzzle.solution != null
        ? Map<String, dynamic>.from(widget.puzzle.solution!)
        : {};
    _difficulty = widget.puzzle.difficulty;
    _targetTime = widget.puzzle.targetTime ?? 300;
    _isActive = widget.puzzle.isActive;
  }

  void _onEditorChange(Map<String, dynamic> puzzleData, Map<String, dynamic> solution, bool isValid) {
    setState(() {
      _puzzleData = puzzleData;
      _solution = solution;
      _isValid = isValid;
      _hasChanges = true;
    });
  }

  Future<void> _savePuzzle() async {
    if (!_isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix validation errors before saving'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updateData = {
        'puzzleData': _puzzleData,
        'solution': _solution,
        'difficulty': _difficulty.apiValue,
        'targetTime': _targetTime,
        'isActive': _isActive,
      };

      final result = await _apiService.updatePuzzle(widget.puzzle.id, updateData);

      if (result != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Puzzle saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() => _hasChanges = false);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save puzzle'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildVisualEditor() {
    switch (widget.puzzle.gameType) {
      case GameType.sudoku:
        return AdminSudokuEditor(
          initialPuzzleData: _puzzleData,
          initialSolution: _solution,
          onChange: _onEditorChange,
        );
      case GameType.killerSudoku:
        return AdminKillerSudokuEditor(
          initialPuzzleData: _puzzleData,
          initialSolution: _solution,
          onChange: _onEditorChange,
        );
      case GameType.crossword:
        return AdminCrosswordEditor(
          initialPuzzleData: _puzzleData,
          initialSolution: _solution,
          onChange: _onEditorChange,
        );
      case GameType.wordSearch:
        return AdminWordSearchEditor(
          initialPuzzleData: _puzzleData,
          initialSolution: _solution,
          onChange: _onEditorChange,
        );
      case GameType.wordForge:
        return AdminWordForgeEditor(
          initialPuzzleData: _puzzleData,
          initialSolution: _solution,
          onChange: _onEditorChange,
        );
      case GameType.nonogram:
        return AdminNonogramEditor(
          initialPuzzleData: _puzzleData,
          initialSolution: _solution,
          onChange: _onEditorChange,
        );
      case GameType.numberTarget:
        return AdminNumberTargetEditor(
          initialPuzzleData: _puzzleData,
          initialSolution: _solution,
          onChange: _onEditorChange,
        );
      case GameType.ballSort:
        return AdminBallSortEditor(
          initialPuzzleData: _puzzleData,
          initialSolution: _solution,
          onChange: _onEditorChange,
        );
      case GameType.pipes:
        return AdminPipesEditor(
          initialPuzzleData: _puzzleData,
          initialSolution: _solution,
          onChange: _onEditorChange,
        );
      case GameType.lightsOut:
        return AdminLightsOutEditor(
          initialPuzzleData: _puzzleData,
          initialSolution: _solution,
          onChange: _onEditorChange,
        );
      case GameType.wordLadder:
        return AdminWordLadderEditor(
          initialPuzzleData: _puzzleData,
          initialSolution: _solution,
          onChange: _onEditorChange,
        );
      case GameType.connections:
        return AdminConnectionsEditor(
          initialPuzzleData: _puzzleData,
          initialSolution: _solution,
          onChange: _onEditorChange,
        );
      case GameType.mathora:
        return AdminMathoraEditor(
          initialPuzzleData: _puzzleData,
          initialSolution: _solution,
          onChange: _onEditorChange,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.puzzle.gameType.displayName),
        backgroundColor: theme.colorScheme.errorContainer,
        foregroundColor: theme.colorScheme.onErrorContainer,
        actions: [
          // JSON/Visual toggle
          IconButton(
            icon: Icon(_isJsonMode ? Icons.view_module : Icons.code),
            tooltip: _isJsonMode ? 'Switch to Visual' : 'Switch to JSON',
            onPressed: () => setState(() => _isJsonMode = !_isJsonMode),
          ),
          // Save button
          if (_hasChanges)
            _isSaving
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.save),
                    tooltip: 'Save',
                    onPressed: _savePuzzle,
                  ),
        ],
      ),
      body: Column(
        children: [
          // Metadata section
          _buildMetadataSection(theme),
          const Divider(height: 1),
          // Editor section
          Expanded(
            child: _isJsonMode
                ? AdminJsonEditor(
                    puzzleData: _puzzleData,
                    solution: _solution,
                    onChange: _onEditorChange,
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildVisualEditor(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Difficulty selector
          Row(
            children: [
              const Text('Difficulty: '),
              const SizedBox(width: 8),
              SegmentedButton<Difficulty>(
                segments: Difficulty.values.map((d) => ButtonSegment(
                  value: d,
                  label: Text(d.displayName),
                )).toList(),
                selected: {_difficulty},
                onSelectionChanged: (selection) {
                  setState(() {
                    _difficulty = selection.first;
                    _hasChanges = true;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Target time and active status
          Row(
            children: [
              // Target time
              Expanded(
                child: Row(
                  children: [
                    const Text('Target Time: '),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      child: TextFormField(
                        initialValue: _targetTime.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(),
                          suffixText: 's',
                        ),
                        onChanged: (value) {
                          final parsed = int.tryParse(value);
                          if (parsed != null) {
                            setState(() {
                              _targetTime = parsed;
                              _hasChanges = true;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Active toggle
              Row(
                children: [
                  const Text('Active: '),
                  Switch(
                    value: _isActive,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value;
                        _hasChanges = true;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          // Validation status
          if (!_isValid)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Puzzle data has validation errors',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
