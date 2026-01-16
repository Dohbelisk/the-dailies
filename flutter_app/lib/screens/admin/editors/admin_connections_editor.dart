import 'package:flutter/material.dart';
import '../../../widgets/admin/admin_validation_status.dart';

/// Editor for Connections puzzles
class AdminConnectionsEditor extends StatefulWidget {
  final Map<String, dynamic>? initialPuzzleData;
  final Map<String, dynamic>? initialSolution;
  final void Function(Map<String, dynamic> puzzleData, Map<String, dynamic> solution, bool isValid) onChange;

  const AdminConnectionsEditor({
    super.key,
    this.initialPuzzleData,
    this.initialSolution,
    required this.onChange,
  });

  @override
  State<AdminConnectionsEditor> createState() => _AdminConnectionsEditorState();
}

class _AdminConnectionsEditorState extends State<AdminConnectionsEditor> {
  late List<_ConnectionGroup> _groups;
  bool _isValid = false;
  List<String> _errors = [];

  static const List<Color> _groupColors = [
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
  ];

  @override
  void initState() {
    super.initState();
    final data = widget.initialPuzzleData ?? {};
    final groupsData = data['groups'] as List<dynamic>?;

    if (groupsData != null) {
      _groups = groupsData.asMap().entries.map((entry) {
        final index = entry.key;
        final group = entry.value as Map<String, dynamic>;
        final words = (group['words'] as List<dynamic>).cast<String>();
        return _ConnectionGroup(
          name: group['name'] as String? ?? 'Group ${index + 1}',
          words: words,
          difficulty: group['difficulty'] as int? ?? (index + 1),
        );
      }).toList();
    } else {
      _groups = List.generate(4, (i) => _ConnectionGroup(
        name: '',
        words: ['', '', '', ''],
        difficulty: i + 1,
      ));
    }

    _validate();
  }

  void _validate() {
    final errors = <String>[];

    // Check we have 4 groups
    if (_groups.length != 4) {
      errors.add('Must have exactly 4 groups');
    }

    // Check each group
    final allWords = <String>{};
    for (int i = 0; i < _groups.length; i++) {
      final group = _groups[i];

      if (group.name.trim().isEmpty) {
        errors.add('Group ${i + 1} needs a category name');
      }

      if (group.words.length != 4) {
        errors.add('Group ${i + 1} must have exactly 4 words');
      }

      for (int j = 0; j < group.words.length; j++) {
        final word = group.words[j].trim();
        if (word.isEmpty) {
          errors.add('Group ${i + 1}, word ${j + 1} is empty');
        } else if (allWords.contains(word.toUpperCase())) {
          errors.add('Duplicate word: $word');
        } else {
          allWords.add(word.toUpperCase());
        }
      }
    }

    // Check total words
    if (allWords.length != 16) {
      errors.add('Must have exactly 16 unique words (found ${allWords.length})');
    }

    setState(() {
      _errors = errors;
      _isValid = errors.isEmpty;
    });

    _notifyChange();
  }

  void _notifyChange() {
    // Collect all words in shuffled order
    final allWords = _groups
        .expand((g) => g.words.map((w) => w.trim().toUpperCase()))
        .where((w) => w.isNotEmpty)
        .toList();

    widget.onChange(
      {
        'words': allWords,
        'groups': _groups.map((g) => {
          'name': g.name.trim(),
          'words': g.words.map((w) => w.trim().toUpperCase()).toList(),
          'difficulty': g.difficulty,
        }).toList(),
      },
      {
        'groups': _groups.map((g) => {
          'name': g.name.trim(),
          'words': g.words.map((w) => w.trim().toUpperCase()).toList(),
        }).toList(),
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
        Text(
          'Connection Groups',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          '4 groups, 4 words each. Difficulty 1 = easiest, 4 = hardest',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // Groups
        ...List.generate(4, (index) => _buildGroupEditor(index)),

        const SizedBox(height: 24),

        // Validation status
        AdminValidationStatus(
          isValid: _isValid,
          errors: _errors,
          successMessage: '4 groups with 16 unique words',
        ),
      ],
    );
  }

  Widget _buildGroupEditor(int index) {
    final group = _groups[index];
    final color = _groupColors[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group header
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: group.name,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(),
                    hintText: 'Category name',
                  ),
                  onChanged: (value) {
                    _groups[index] = _ConnectionGroup(
                      name: value,
                      words: group.words,
                      difficulty: group.difficulty,
                    );
                    _validate();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Words
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(4, (wordIndex) {
              return SizedBox(
                width: 140,
                child: TextFormField(
                  initialValue: group.words[wordIndex],
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: const OutlineInputBorder(),
                    hintText: 'Word ${wordIndex + 1}',
                  ),
                  onChanged: (value) {
                    final newWords = List<String>.from(group.words);
                    newWords[wordIndex] = value;
                    _groups[index] = _ConnectionGroup(
                      name: group.name,
                      words: newWords,
                      difficulty: group.difficulty,
                    );
                    _validate();
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ConnectionGroup {
  final String name;
  final List<String> words;
  final int difficulty;

  _ConnectionGroup({
    required this.name,
    required this.words,
    required this.difficulty,
  });
}
