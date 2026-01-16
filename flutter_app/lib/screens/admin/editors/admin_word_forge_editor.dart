import 'package:flutter/material.dart';
import '../../../widgets/admin/admin_validation_status.dart';

/// Editor for Word Forge puzzles
class AdminWordForgeEditor extends StatefulWidget {
  final Map<String, dynamic>? initialPuzzleData;
  final Map<String, dynamic>? initialSolution;
  final void Function(Map<String, dynamic> puzzleData, Map<String, dynamic> solution, bool isValid) onChange;

  const AdminWordForgeEditor({
    super.key,
    this.initialPuzzleData,
    this.initialSolution,
    required this.onChange,
  });

  @override
  State<AdminWordForgeEditor> createState() => _AdminWordForgeEditorState();
}

class _AdminWordForgeEditorState extends State<AdminWordForgeEditor> {
  late List<String> _letters;
  late String _centerLetter;
  late TextEditingController _wordsController;
  bool _isValid = false;
  List<String> _errors = [];

  @override
  void initState() {
    super.initState();
    final data = widget.initialPuzzleData ?? {};
    final solution = widget.initialSolution ?? {};

    // Get letters
    final lettersData = data['letters'] as List<dynamic>?;
    if (lettersData != null && lettersData.length == 7) {
      _letters = lettersData.map((l) => (l as String).toUpperCase()).toList();
    } else {
      _letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];
    }

    // Center letter is index 0 or specified
    _centerLetter = data['centerLetter'] as String? ?? _letters[0];

    // Get words from solution or puzzleData
    final words = solution['words'] as List<dynamic>? ??
        solution['allWords'] as List<dynamic>? ??
        data['words'] as List<dynamic>? ??
        data['targetWords'] as List<dynamic>? ??
        [];
    _wordsController = TextEditingController(
      text: words.map((w) => (w as String).toUpperCase()).join(', '),
    );

    _validate();
  }

  @override
  void dispose() {
    _wordsController.dispose();
    super.dispose();
  }

  void _validate() {
    final errors = <String>[];

    // Check letters
    if (_letters.length != 7) {
      errors.add('Must have exactly 7 letters');
    }
    final uniqueLetters = _letters.toSet();
    if (uniqueLetters.length != 7) {
      errors.add('All 7 letters must be unique');
    }

    // Check center letter
    if (!_letters.contains(_centerLetter)) {
      errors.add('Center letter must be one of the 7 letters');
    }

    // Parse and check words
    final wordsStr = _wordsController.text.trim();
    final words = wordsStr.isNotEmpty
        ? wordsStr.split(',').map((w) => w.trim().toUpperCase()).where((w) => w.isNotEmpty).toList()
        : <String>[];

    if (words.isEmpty) {
      errors.add('Add at least one valid word');
    }

    // Check each word
    for (final word in words) {
      if (word.length < 4) {
        errors.add('"$word" is too short (min 4 letters)');
        continue;
      }
      if (!word.contains(_centerLetter)) {
        errors.add('"$word" must contain center letter $_centerLetter');
        continue;
      }
      // Check all letters are from the available set
      for (final char in word.split('')) {
        if (!_letters.contains(char)) {
          errors.add('"$word" contains invalid letter "$char"');
          break;
        }
      }
    }

    setState(() {
      _errors = errors.take(5).toList();
      _isValid = errors.isEmpty;
    });

    _notifyChange();
  }

  void _notifyChange() {
    final wordsStr = _wordsController.text.trim();
    final words = wordsStr.isNotEmpty
        ? wordsStr.split(',').map((w) => w.trim().toUpperCase()).where((w) => w.isNotEmpty).toList()
        : <String>[];

    // Find pangrams (words using all 7 letters)
    final pangrams = words.where((word) {
      final wordLetters = word.split('').toSet();
      return _letters.every((l) => wordLetters.contains(l));
    }).toList();

    widget.onChange(
      {
        'letters': _letters,
        'centerLetter': _centerLetter,
        'minWordLength': 4,
      },
      {
        'words': words,
        'allWords': words,
        'pangrams': pangrams,
      },
      _isValid,
    );
  }

  void _setLetter(int index, String letter) {
    if (letter.isNotEmpty) {
      setState(() {
        _letters[index] = letter.toUpperCase()[0];
        if (index == 0) {
          _centerLetter = _letters[0];
        }
      });
      _validate();
    }
  }

  void _setCenterLetter(String letter) {
    if (_letters.contains(letter.toUpperCase())) {
      setState(() {
        _centerLetter = letter.toUpperCase();
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
        // Letters
        Text(
          '7 Letters',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(7, (index) {
            final isCenterLetter = _letters[index] == _centerLetter;
            return SizedBox(
              width: 56,
              child: Column(
                children: [
                  TextFormField(
                    initialValue: _letters[index],
                    maxLength: 1,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.characters,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isCenterLetter ? theme.colorScheme.primary : null,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: isCenterLetter,
                      fillColor: isCenterLetter ? theme.colorScheme.primary.withValues(alpha: 0.1) : null,
                    ),
                    onChanged: (value) => _setLetter(index, value),
                  ),
                  if (isCenterLetter)
                    const Text('Center', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 16),

        // Center letter selector
        Row(
          children: [
            const Text('Center Letter: '),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _centerLetter,
              items: _letters.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
              onChanged: (value) {
                if (value != null) _setCenterLetter(value);
              },
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Honeycomb preview
        Center(
          child: _buildHoneycomb(),
        ),
        const SizedBox(height: 24),

        // Words
        Text(
          'Valid Words (comma-separated)',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Each word must be 4+ letters and contain the center letter',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _wordsController,
          maxLines: 4,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'WORD, ANOTHER, PANGRAM, ...',
          ),
          onChanged: (_) => _validate(),
        ),
        const SizedBox(height: 16),

        // Word count
        Text(
          'Words: ${_wordsController.text.split(",").where((w) => w.trim().isNotEmpty).length}',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // Validation status
        AdminValidationStatus(
          isValid: _isValid,
          errors: _errors,
          successMessage: 'Word Forge puzzle ready',
        ),
      ],
    );
  }

  Widget _buildHoneycomb() {
    const hexSize = 44.0;

    // Get outer letters (excluding center)
    final outerLetters = <String>[];
    for (final letter in _letters) {
      if (letter != _centerLetter) {
        outerLetters.add(letter);
      }
    }
    while (outerLetters.length < 6) {
      outerLetters.add('?');
    }

    return SizedBox(
      width: hexSize * 4,
      height: hexSize * 3.5,
      child: Stack(
        children: [
          // Center hexagon
          Positioned(
            left: hexSize * 1.5,
            top: hexSize * 1.25,
            child: _buildHexagon(_centerLetter, hexSize, isCenter: true),
          ),
          // Outer hexagons
          for (int i = 0; i < 6; i++)
            Positioned(
              left: hexSize * 1.5 + hexSize * 1.1 * _hexOffsets[i][0],
              top: hexSize * 1.25 + hexSize * 1.1 * _hexOffsets[i][1],
              child: _buildHexagon(outerLetters[i], hexSize),
            ),
        ],
      ),
    );
  }

  static const _hexOffsets = [
    [0.0, -1.0], // top
    [0.87, -0.5], // top-right
    [0.87, 0.5], // bottom-right
    [0.0, 1.0], // bottom
    [-0.87, 0.5], // bottom-left
    [-0.87, -0.5], // top-left
  ];

  Widget _buildHexagon(String letter, double size, {bool isCenter = false}) {
    final theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isCenter
            ? theme.colorScheme.primary
            : theme.colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: isCenter ? theme.colorScheme.primary : theme.dividerColor,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: isCenter ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
