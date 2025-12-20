import 'dart:convert';

enum GameType { sudoku, killerSudoku, crossword, wordSearch, wordForge, nonogram, numberTarget }

extension GameTypeExtension on GameType {
  String get displayName {
    switch (this) {
      case GameType.sudoku:
        return 'Sudoku';
      case GameType.killerSudoku:
        return 'Killer Sudoku';
      case GameType.crossword:
        return 'Crossword';
      case GameType.wordSearch:
        return 'Word Search';
      case GameType.wordForge:
        return 'Word Forge';
      case GameType.nonogram:
        return 'Nonogram';
      case GameType.numberTarget:
        return 'Number Target';
    }
  }

  String get icon {
    switch (this) {
      case GameType.sudoku:
        return '🔢';
      case GameType.killerSudoku:
        return '🧮';
      case GameType.crossword:
        return '📝';
      case GameType.wordSearch:
        return '🔍';
      case GameType.wordForge:
        return '⚒️';
      case GameType.nonogram:
        return '🖼️';
      case GameType.numberTarget:
        return '🎯';
    }
  }

  String get apiValue => name;
}

enum Difficulty { easy, medium, hard, expert }

extension DifficultyExtension on Difficulty {
  String get displayName => name[0].toUpperCase() + name.substring(1);
  String get apiValue => name;

  int get stars {
    switch (this) {
      case Difficulty.easy:
        return 1;
      case Difficulty.medium:
        return 2;
      case Difficulty.hard:
        return 3;
      case Difficulty.expert:
        return 4;
    }
  }
}

class DailyPuzzle {
  final String id;
  final GameType gameType;
  final Difficulty difficulty;
  final DateTime date;
  final dynamic puzzleData;
  final dynamic solution;
  final int? targetTime; // in seconds
  final bool isCompleted;
  final int? completionTime;
  final int? score;

  DailyPuzzle({
    required this.id,
    required this.gameType,
    required this.difficulty,
    required this.date,
    required this.puzzleData,
    this.solution,
    this.targetTime,
    this.isCompleted = false,
    this.completionTime,
    this.score,
  });

  factory DailyPuzzle.fromJson(Map<String, dynamic> json) {
    return DailyPuzzle(
      id: json['id'] ?? json['_id'] ?? '',
      gameType: GameType.values.firstWhere(
        (e) => e.name == json['gameType'],
        orElse: () => GameType.sudoku,
      ),
      difficulty: Difficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => Difficulty.medium,
      ),
      date: DateTime.parse(json['date']),
      puzzleData: json['puzzleData'],
      solution: json['solution'],
      targetTime: json['targetTime'],
      isCompleted: json['isCompleted'] ?? false,
      completionTime: json['completionTime'],
      score: json['score'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gameType': gameType.name,
      'difficulty': difficulty.name,
      'date': date.toIso8601String(),
      'puzzleData': puzzleData,
      'solution': solution,
      'targetTime': targetTime,
      'isCompleted': isCompleted,
      'completionTime': completionTime,
      'score': score,
    };
  }

  DailyPuzzle copyWith({
    String? id,
    GameType? gameType,
    Difficulty? difficulty,
    DateTime? date,
    dynamic puzzleData,
    dynamic solution,
    int? targetTime,
    bool? isCompleted,
    int? completionTime,
    int? score,
  }) {
    return DailyPuzzle(
      id: id ?? this.id,
      gameType: gameType ?? this.gameType,
      difficulty: difficulty ?? this.difficulty,
      date: date ?? this.date,
      puzzleData: puzzleData ?? this.puzzleData,
      solution: solution ?? this.solution,
      targetTime: targetTime ?? this.targetTime,
      isCompleted: isCompleted ?? this.isCompleted,
      completionTime: completionTime ?? this.completionTime,
      score: score ?? this.score,
    );
  }
}

// Sudoku specific models
class SudokuPuzzle {
  final List<List<int?>> grid; // 9x9 grid, null for empty cells
  final List<List<int?>> initialGrid; // Original puzzle state
  final List<List<int>> solution;
  final List<List<Set<int>>> notes; // Pencil marks

  SudokuPuzzle({
    required this.grid,
    required this.initialGrid,
    required this.solution,
    List<List<Set<int>>>? notes,
  }) : notes = notes ?? List.generate(9, (_) => List.generate(9, (_) => <int>{}));

  factory SudokuPuzzle.fromJson(Map<String, dynamic> json) {
    // Handle grid - can be direct array or nested in 'grid' property
    final gridData = (json['grid'] is List) ? json['grid'] as List : [];

    // Handle solution - can be direct array, nested in 'grid' property, or null
    List solutionData;
    if (json['solution'] is List) {
      solutionData = json['solution'] as List;
    } else if (json['solution'] is Map && json['solution']['grid'] != null) {
      solutionData = json['solution']['grid'] as List;
    } else {
      // Fallback to empty grid if no solution provided
      solutionData = gridData;
    }

    final grid = gridData.map<List<int?>>((row) {
      return (row as List).map<int?>((cell) => cell == 0 ? null : cell as int).toList();
    }).toList();

    final solution = solutionData.map<List<int>>((row) {
      return (row as List).map<int>((cell) => cell as int).toList();
    }).toList();

    return SudokuPuzzle(
      grid: grid,
      initialGrid: grid.map((row) => List<int?>.from(row)).toList(),
      solution: solution,
    );
  }

  bool get isComplete {
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (grid[i][j] != solution[i][j]) return false;
      }
    }
    return true;
  }

  bool isValidPlacement(int row, int col, int value) {
    // Check row
    for (int i = 0; i < 9; i++) {
      if (i != col && grid[row][i] == value) return false;
    }
    
    // Check column
    for (int i = 0; i < 9; i++) {
      if (i != row && grid[i][col] == value) return false;
    }
    
    // Check 3x3 box
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (int i = boxRow; i < boxRow + 3; i++) {
      for (int j = boxCol; j < boxCol + 3; j++) {
        if (i != row && j != col && grid[i][j] == value) return false;
      }
    }
    
    return true;
  }
}

// Killer Sudoku specific models
class KillerCage {
  final int sum;
  final List<List<int>> cells; // List of [row, col] pairs

  KillerCage({required this.sum, required this.cells});

  factory KillerCage.fromJson(Map<String, dynamic> json) {
    return KillerCage(
      sum: json['sum'] as int,
      cells: (json['cells'] as List).map<List<int>>((cell) {
        return (cell as List).map<int>((c) => c as int).toList();
      }).toList(),
    );
  }

  /// Returns the top-left cell of the cage (min row, then min col)
  List<int> get topLeftCell {
    var topLeft = cells.first;
    for (final cell in cells) {
      if (cell[0] < topLeft[0] || (cell[0] == topLeft[0] && cell[1] < topLeft[1])) {
        topLeft = cell;
      }
    }
    return topLeft;
  }
}

class KillerSudokuPuzzle extends SudokuPuzzle {
  final List<KillerCage> cages;

  KillerSudokuPuzzle({
    required super.grid,
    required super.initialGrid,
    required super.solution,
    required this.cages,
    super.notes,
  });

  factory KillerSudokuPuzzle.fromJson(Map<String, dynamic> json) {
    final basePuzzle = SudokuPuzzle.fromJson(json);
    final cagesData = json['cages'] as List;
    
    return KillerSudokuPuzzle(
      grid: basePuzzle.grid,
      initialGrid: basePuzzle.initialGrid,
      solution: basePuzzle.solution,
      cages: cagesData.map((c) => KillerCage.fromJson(c)).toList(),
    );
  }

  List<int>? getCageForCell(int row, int col) {
    for (int i = 0; i < cages.length; i++) {
      for (final cell in cages[i].cells) {
        if (cell[0] == row && cell[1] == col) {
          return [i, cages[i].sum];
        }
      }
    }
    return null;
  }
}

// Crossword specific models
class CrosswordClue {
  final int number;
  final String direction; // 'across' or 'down'
  final String clue;
  final String answer;
  final int startRow;
  final int startCol;

  CrosswordClue({
    required this.number,
    required this.direction,
    required this.clue,
    required this.answer,
    required this.startRow,
    required this.startCol,
  });

  factory CrosswordClue.fromJson(Map<String, dynamic> json) {
    return CrosswordClue(
      number: json['number'] as int,
      direction: json['direction'] as String,
      clue: json['clue'] as String,
      answer: json['answer'] as String,
      startRow: json['startRow'] as int,
      startCol: json['startCol'] as int,
    );
  }

  int get length => answer.length;
}

class CrosswordPuzzle {
  final int rows;
  final int cols;
  final List<List<String?>> grid; // null for black cells
  final List<List<String?>> userGrid;
  final List<CrosswordClue> clues;
  final List<List<int?>> cellNumbers;

  CrosswordPuzzle({
    required this.rows,
    required this.cols,
    required this.grid,
    required this.userGrid,
    required this.clues,
    required this.cellNumbers,
  });

  factory CrosswordPuzzle.fromJson(Map<String, dynamic> json) {
    final rows = json['rows'] as int;
    final cols = json['cols'] as int;
    final gridData = json['grid'] as List;
    final cluesData = json['clues'] as List;
    
    final grid = gridData.map<List<String?>>((row) {
      return (row as List).map<String?>((cell) {
        return cell == '#' ? null : cell as String;
      }).toList();
    }).toList();
    
    final userGrid = grid.map<List<String?>>((row) {
      return row.map<String?>((cell) => cell == null ? null : '').toList();
    }).toList();
    
    // Filter out clues with null positions (invalid data from generator)
    final validCluesData = cluesData.where((c) =>
      c['startRow'] != null && c['startCol'] != null && c['number'] != null
    ).toList();
    final clues = validCluesData.map((c) => CrosswordClue.fromJson(c)).toList();

    // Calculate cell numbers
    final cellNumbers = List.generate(rows, (_) => List<int?>.filled(cols, null));
    for (final clue in clues) {
      if (clue.startRow < rows && clue.startCol < cols) {
        cellNumbers[clue.startRow][clue.startCol] = clue.number;
      }
    }

    return CrosswordPuzzle(
      rows: rows,
      cols: cols,
      grid: grid,
      userGrid: userGrid,
      clues: clues,
      cellNumbers: cellNumbers,
    );
  }

  bool get isComplete {
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        if (grid[i][j] != null && userGrid[i][j]?.toUpperCase() != grid[i][j]?.toUpperCase()) {
          return false;
        }
      }
    }
    return true;
  }

  List<CrosswordClue> get acrossClues =>
      clues.where((c) => c.direction == 'across').toList()..sort((a, b) => a.number.compareTo(b.number));

  List<CrosswordClue> get downClues =>
      clues.where((c) => c.direction == 'down').toList()..sort((a, b) => a.number.compareTo(b.number));
}

// Word Search specific models
class WordSearchWord {
  final String word;
  final int startRow;
  final int startCol;
  final int endRow;
  final int endCol;
  bool found;

  WordSearchWord({
    required this.word,
    required this.startRow,
    required this.startCol,
    required this.endRow,
    required this.endCol,
    this.found = false,
  });

  factory WordSearchWord.fromJson(Map<String, dynamic> json) {
    return WordSearchWord(
      word: json['word'] as String,
      startRow: json['startRow'] as int,
      startCol: json['startCol'] as int,
      endRow: json['endRow'] as int,
      endCol: json['endCol'] as int,
      found: json['found'] ?? false,
    );
  }

  List<List<int>> get cellPositions {
    final positions = <List<int>>[];
    final rowDir = (endRow - startRow).sign;
    final colDir = (endCol - startCol).sign;
    var row = startRow;
    var col = startCol;
    
    while (true) {
      positions.add([row, col]);
      if (row == endRow && col == endCol) break;
      row += rowDir;
      col += colDir;
    }
    
    return positions;
  }
}

class WordSearchPuzzle {
  final int rows;
  final int cols;
  final List<List<String>> grid;
  final List<WordSearchWord> words;
  final String? theme;

  WordSearchPuzzle({
    required this.rows,
    required this.cols,
    required this.grid,
    required this.words,
    this.theme,
  });

  factory WordSearchPuzzle.fromJson(Map<String, dynamic> json) {
    final rows = json['rows'] as int;
    final cols = json['cols'] as int;
    final gridData = json['grid'] as List;
    final wordsData = json['words'] as List;
    
    final grid = gridData.map<List<String>>((row) {
      return (row as List).map<String>((cell) => cell as String).toList();
    }).toList();

    return WordSearchPuzzle(
      rows: rows,
      cols: cols,
      grid: grid,
      words: wordsData.map((w) => WordSearchWord.fromJson(w)).toList(),
      theme: json['theme'] as String?,
    );
  }

  bool get isComplete => words.every((w) => w.found);

  int get foundCount => words.where((w) => w.found).length;
}

// User stats model
class UserStats {
  final int totalGamesPlayed;
  final int totalGamesWon;
  final int currentStreak;
  final int longestStreak;
  final Map<String, int> gameTypeCounts;
  final int averageTime;

  UserStats({
    required this.totalGamesPlayed,
    required this.totalGamesWon,
    required this.currentStreak,
    required this.longestStreak,
    required this.gameTypeCounts,
    required this.averageTime,
  });

  factory UserStats.empty() {
    return UserStats(
      totalGamesPlayed: 0,
      totalGamesWon: 0,
      currentStreak: 0,
      longestStreak: 0,
      gameTypeCounts: {},
      averageTime: 0,
    );
  }

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalGamesPlayed: json['totalGamesPlayed'] ?? 0,
      totalGamesWon: json['totalGamesWon'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      gameTypeCounts: Map<String, int>.from(json['gameTypeCounts'] ?? {}),
      averageTime: json['averageTime'] ?? 0,
    );
  }
}

// Word Forge specific models
class WordForgePuzzle {
  final List<String> letters; // 7 letters
  final String centerLetter; // Must be in every word
  final Set<String> validWords; // All valid words
  final Set<String> pangrams; // Words using all 7 letters
  final Set<String> foundWords; // Words the user has found
  final int maxScore;

  WordForgePuzzle({
    required this.letters,
    required this.centerLetter,
    required this.validWords,
    required this.pangrams,
    Set<String>? foundWords,
    required this.maxScore,
  }) : foundWords = foundWords ?? {};

  factory WordForgePuzzle.fromJson(Map<String, dynamic> json) {
    final puzzleData = json;
    final solution = json['solution'] ?? json;

    return WordForgePuzzle(
      letters: List<String>.from(puzzleData['letters'] ?? []),
      centerLetter: puzzleData['centerLetter'] ?? '',
      validWords: Set<String>.from(puzzleData['validWords'] ?? solution['allWords'] ?? []),
      pangrams: Set<String>.from(puzzleData['pangrams'] ?? solution['pangrams'] ?? []),
      maxScore: solution['maxScore'] ?? 0,
    );
  }

  bool get isComplete => foundWords.length == validWords.length;

  int get currentScore {
    int score = 0;
    for (final word in foundWords) {
      if (word.length == 4) {
        score += 1;
      } else {
        score += word.length;
      }
      if (pangrams.contains(word)) {
        score += 7; // Pangram bonus
      }
    }
    return score;
  }

  bool isValidWord(String word) {
    final upperWord = word.toUpperCase();
    if (upperWord.length < 4) return false;
    if (!upperWord.contains(centerLetter)) return false;
    return validWords.contains(upperWord);
  }

  bool canFormWord(String word) {
    final upperWord = word.toUpperCase();
    final letterSet = Set<String>.from(letters);
    for (final char in upperWord.split('')) {
      if (!letterSet.contains(char)) return false;
    }
    return upperWord.contains(centerLetter);
  }

  bool isPangram(String word) {
    final upperWord = word.toUpperCase();
    return pangrams.contains(upperWord);
  }

  int scoreWord(String word) {
    final upperWord = word.toUpperCase();
    int score = 0;
    if (upperWord.length == 4) {
      score = 1;
    } else {
      score = upperWord.length;
    }
    if (pangrams.contains(upperWord)) {
      score += 7; // Pangram bonus
    }
    return score;
  }

  void shuffleOuterLetters() {
    // Get outer letters (all except center)
    final outerLetters = letters.where((l) => l != centerLetter).toList();
    outerLetters.shuffle();

    // Rebuild letters list with center letter staying in place
    int outerIndex = 0;
    for (int i = 0; i < letters.length; i++) {
      if (letters[i] != centerLetter) {
        letters[i] = outerLetters[outerIndex++];
      }
    }
  }
}

// Nonogram specific models
class NonogramPuzzle {
  final int rows;
  final int cols;
  final List<List<int>> rowClues; // Clues for each row
  final List<List<int>> colClues; // Clues for each column
  final List<List<int>> solution; // 1 = filled, 0 = empty
  final List<List<int?>> userGrid; // null = unmarked, 1 = filled, 0 = marked empty

  NonogramPuzzle({
    required this.rows,
    required this.cols,
    required this.rowClues,
    required this.colClues,
    required this.solution,
    List<List<int?>>? userGrid,
  }) : userGrid = userGrid ?? List.generate(rows, (_) => List<int?>.filled(cols, null));

  factory NonogramPuzzle.fromJson(Map<String, dynamic> json) {
    final puzzleData = json;
    final solutionData = json['solution'] ?? json;

    final rows = puzzleData['rows'] as int;
    final cols = puzzleData['cols'] as int;

    final rowClues = (puzzleData['rowClues'] as List).map<List<int>>((row) {
      return (row as List).map<int>((c) => c as int).toList();
    }).toList();

    final colClues = (puzzleData['colClues'] as List).map<List<int>>((col) {
      return (col as List).map<int>((c) => c as int).toList();
    }).toList();

    final solution = (solutionData['grid'] as List).map<List<int>>((row) {
      return (row as List).map<int>((c) => c as int).toList();
    }).toList();

    return NonogramPuzzle(
      rows: rows,
      cols: cols,
      rowClues: rowClues,
      colClues: colClues,
      solution: solution,
    );
  }

  bool get isComplete {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        // Only check filled cells - user must have marked them as filled
        if (solution[r][c] == 1 && userGrid[r][c] != 1) return false;
        // Also check that marked empty cells are correct
        if (solution[r][c] == 0 && userGrid[r][c] == 1) return false;
      }
    }
    return true;
  }

  int get filledCount {
    int count = 0;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (userGrid[r][c] == 1) count++;
      }
    }
    return count;
  }

  int get totalToFill {
    int count = 0;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (solution[r][c] == 1) count++;
      }
    }
    return count;
  }
}

// Number Target specific models
class NumberTargetPuzzle {
  final List<int> numbers; // 4 numbers to use
  final int target; // Target number to reach
  final String solution; // One valid expression
  final List<String> alternates; // Alternative solutions
  String userExpression; // User's current expression
  final List<bool> usedNumbers; // Track which numbers are used

  NumberTargetPuzzle({
    required this.numbers,
    required this.target,
    required this.solution,
    this.alternates = const [],
    this.userExpression = '',
    List<bool>? usedNumbers,
  }) : usedNumbers = usedNumbers ?? List.filled(4, false);

  factory NumberTargetPuzzle.fromJson(Map<String, dynamic> json) {
    final puzzleData = json;
    final solutionData = json['solution'] ?? json;

    return NumberTargetPuzzle(
      numbers: List<int>.from(puzzleData['numbers'] ?? []),
      target: puzzleData['target'] as int,
      solution: solutionData['expression'] ?? '',
      alternates: List<String>.from(solutionData['alternates'] ?? []),
    );
  }

  bool get isComplete {
    if (userExpression.isEmpty) return false;
    try {
      final result = evaluateExpression(userExpression);
      return (result - target).abs() < 0.0001;
    } catch (e) {
      return false;
    }
  }

  double evaluateExpression(String expr) {
    // Simple expression evaluator
    // This is a basic implementation - in production, use a proper parser
    try {
      // Replace × with * and ÷ with /
      expr = expr.replaceAll('×', '*').replaceAll('÷', '/');

      // Use Dart's built-in evaluation (simplified)
      // For safety, we manually parse the expression
      return _evaluate(expr);
    } catch (e) {
      return double.nan;
    }
  }

  double _evaluate(String expr) {
    expr = expr.trim();

    // Handle parentheses first
    while (expr.contains('(')) {
      final start = expr.lastIndexOf('(');
      final end = expr.indexOf(')', start);
      if (end == -1) throw FormatException('Mismatched parentheses');

      final inner = expr.substring(start + 1, end);
      final result = _evaluate(inner);
      expr = expr.substring(0, start) + result.toString() + expr.substring(end + 1);
    }

    // Handle + and - (left to right)
    var parts = _splitKeepDelimiters(expr, ['+', '-']);
    if (parts.length > 1) {
      double result = _evaluate(parts[0]);
      for (int i = 1; i < parts.length; i += 2) {
        final op = parts[i];
        final val = _evaluate(parts[i + 1]);
        if (op == '+') {
          result += val;
        } else {
          result -= val;
        }
      }
      return result;
    }

    // Handle * and /
    parts = _splitKeepDelimiters(expr, ['*', '/']);
    if (parts.length > 1) {
      double result = _evaluate(parts[0]);
      for (int i = 1; i < parts.length; i += 2) {
        final op = parts[i];
        final val = _evaluate(parts[i + 1]);
        if (op == '*') {
          result *= val;
        } else {
          if (val == 0) throw FormatException('Division by zero');
          result /= val;
        }
      }
      return result;
    }

    // It's a number
    return double.parse(expr);
  }

  List<String> _splitKeepDelimiters(String str, List<String> delimiters) {
    final result = <String>[];
    var current = '';

    for (int i = 0; i < str.length; i++) {
      final char = str[i];
      if (delimiters.contains(char) && current.isNotEmpty) {
        result.add(current);
        result.add(char);
        current = '';
      } else {
        current += char;
      }
    }

    if (current.isNotEmpty) {
      result.add(current);
    }

    return result;
  }
}
