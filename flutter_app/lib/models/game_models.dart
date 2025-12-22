import 'dart:convert';

enum GameType { sudoku, killerSudoku, crossword, wordSearch, wordForge, nonogram, numberTarget, ballSort, pipes, lightsOut, wordLadder, connections, mathora }

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
      case GameType.ballSort:
        return 'Ball Sort';
      case GameType.pipes:
        return 'Pipes';
      case GameType.lightsOut:
        return 'Lights Out';
      case GameType.wordLadder:
        return 'Word Ladder';
      case GameType.connections:
        return 'Connections';
      case GameType.mathora:
        return 'Mathora';
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
      case GameType.ballSort:
        return '🔴';
      case GameType.pipes:
        return '🔗';
      case GameType.lightsOut:
        return '💡';
      case GameType.wordLadder:
        return '🪜';
      case GameType.connections:
        return '🔗';
      case GameType.mathora:
        return '🧮';
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

  /// Returns a set of numbers (1-9) that have all 9 instances placed on the grid
  Set<int> get completedNumbers {
    final counts = <int, int>{};
    for (int i = 1; i <= 9; i++) {
      counts[i] = 0;
    }

    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        final value = grid[row][col];
        if (value != null && value >= 1 && value <= 9) {
          counts[value] = counts[value]! + 1;
        }
      }
    }

    return counts.entries
        .where((e) => e.value >= 9)
        .map((e) => e.key)
        .toSet();
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

// Ball Sort specific models
class BallSortMove {
  final int from;
  final int to;

  BallSortMove({required this.from, required this.to});

  factory BallSortMove.fromJson(Map<String, dynamic> json) {
    return BallSortMove(
      from: json['from'] as int,
      to: json['to'] as int,
    );
  }

  Map<String, dynamic> toJson() => {'from': from, 'to': to};
}

class BallSortPuzzle {
  final int tubeCount;
  final int colorCount;
  final int tubeCapacity;
  final List<List<String>> initialState;
  List<List<String>> currentState;
  final int minMoves;
  int moveCount;
  final List<BallSortMove> moveHistory;

  BallSortPuzzle({
    required this.tubeCount,
    required this.colorCount,
    required this.tubeCapacity,
    required this.initialState,
    List<List<String>>? currentState,
    required this.minMoves,
    this.moveCount = 0,
    List<BallSortMove>? moveHistory,
  })  : currentState = currentState ?? initialState.map((t) => List<String>.from(t)).toList(),
        moveHistory = moveHistory ?? [];

  factory BallSortPuzzle.fromJson(Map<String, dynamic> json) {
    final puzzleData = json;
    final solutionData = json['solution'] ?? json;

    final initialState = (puzzleData['initialState'] as List).map<List<String>>((tube) {
      return (tube as List).map<String>((ball) => ball as String).toList();
    }).toList();

    return BallSortPuzzle(
      tubeCount: puzzleData['tubes'] as int,
      colorCount: puzzleData['colors'] as int,
      tubeCapacity: puzzleData['tubeCapacity'] as int,
      initialState: initialState,
      minMoves: solutionData['minMoves'] as int? ?? 0,
    );
  }

  bool get isComplete {
    for (final tube in currentState) {
      if (tube.isEmpty) continue;
      if (tube.length != tubeCapacity) return false;
      final firstColor = tube.first;
      if (!tube.every((ball) => ball == firstColor)) return false;
    }
    // Count filled tubes - should equal colorCount
    final filledTubes = currentState.where((t) => t.length == tubeCapacity).length;
    return filledTubes == colorCount;
  }

  String? getTopBall(int tubeIndex) {
    if (tubeIndex < 0 || tubeIndex >= currentState.length) return null;
    final tube = currentState[tubeIndex];
    return tube.isEmpty ? null : tube.last;
  }

  bool canMoveTo(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) return false;
    if (fromIndex < 0 || fromIndex >= currentState.length) return false;
    if (toIndex < 0 || toIndex >= currentState.length) return false;

    final fromTube = currentState[fromIndex];
    final toTube = currentState[toIndex];

    // Can't move from empty tube
    if (fromTube.isEmpty) return false;

    // Can't move to full tube
    if (toTube.length >= tubeCapacity) return false;

    final ballToMove = fromTube.last;

    // Can move to empty tube (unless source is all same color - pointless move)
    if (toTube.isEmpty) {
      // Allow moving to empty even if source is all same color
      // (User might want to rearrange)
      return true;
    }

    // Can move if destination top ball matches
    return toTube.last == ballToMove;
  }

  bool moveBall(int fromIndex, int toIndex) {
    if (!canMoveTo(fromIndex, toIndex)) return false;

    final ball = currentState[fromIndex].removeLast();
    currentState[toIndex].add(ball);
    moveHistory.add(BallSortMove(from: fromIndex, to: toIndex));
    moveCount++;
    return true;
  }

  bool undoMove() {
    if (moveHistory.isEmpty) return false;

    final lastMove = moveHistory.removeLast();
    final ball = currentState[lastMove.to].removeLast();
    currentState[lastMove.from].add(ball);
    moveCount--;
    return true;
  }

  void reset() {
    currentState = initialState.map((t) => List<String>.from(t)).toList();
    moveHistory.clear();
    moveCount = 0;
  }

  /// Returns true if the tube contains only one color (or is empty)
  bool isTubeSorted(int tubeIndex) {
    if (tubeIndex < 0 || tubeIndex >= currentState.length) return false;
    final tube = currentState[tubeIndex];
    if (tube.isEmpty) return true;
    final firstColor = tube.first;
    return tube.every((ball) => ball == firstColor);
  }

  /// Returns true if the tube is completely sorted (full with one color)
  bool isTubeComplete(int tubeIndex) {
    if (tubeIndex < 0 || tubeIndex >= currentState.length) return false;
    final tube = currentState[tubeIndex];
    if (tube.length != tubeCapacity) return false;
    final firstColor = tube.first;
    return tube.every((ball) => ball == firstColor);
  }
}

// Pipes (Flow Free) specific models
class PipesEndpoint {
  final String color;
  final int row;
  final int col;

  PipesEndpoint({required this.color, required this.row, required this.col});

  factory PipesEndpoint.fromJson(Map<String, dynamic> json) {
    return PipesEndpoint(
      color: json['color'] as String,
      row: json['row'] as int,
      col: json['col'] as int,
    );
  }
}

class PipesPuzzle {
  final int rows;
  final int cols;
  final List<PipesEndpoint> endpoints;
  final List<List<int>> bridges; // [row, col] positions for bridge tiles
  final Map<String, List<List<int>>> solutionPaths; // color -> path cells

  // User state
  Map<String, List<List<int>>> currentPaths; // color -> path cells user has drawn
  String? selectedColor; // Currently drawing this color

  PipesPuzzle({
    required this.rows,
    required this.cols,
    required this.endpoints,
    required this.bridges,
    required this.solutionPaths,
    Map<String, List<List<int>>>? currentPaths,
    this.selectedColor,
  }) : currentPaths = currentPaths ?? {};

  factory PipesPuzzle.fromJson(Map<String, dynamic> json) {
    final puzzleData = json;
    final solutionData = json['solution'] ?? {};

    final endpoints = (puzzleData['endpoints'] as List)
        .map<PipesEndpoint>((e) => PipesEndpoint.fromJson(e))
        .toList();

    final bridges = puzzleData['bridges'] != null
        ? (puzzleData['bridges'] as List).map<List<int>>((b) {
            return (b as List).map<int>((c) => c as int).toList();
          }).toList()
        : <List<int>>[];

    final solutionPaths = <String, List<List<int>>>{};
    if (solutionData['paths'] != null) {
      (solutionData['paths'] as Map<String, dynamic>).forEach((color, path) {
        solutionPaths[color] = (path as List).map<List<int>>((cell) {
          return (cell as List).map<int>((c) => c as int).toList();
        }).toList();
      });
    }

    return PipesPuzzle(
      rows: puzzleData['rows'] as int,
      cols: puzzleData['cols'] as int,
      endpoints: endpoints,
      bridges: bridges,
      solutionPaths: solutionPaths,
    );
  }

  /// Get all unique colors in the puzzle
  Set<String> get colors => endpoints.map((e) => e.color).toSet();

  /// Get endpoints for a specific color
  List<PipesEndpoint> getEndpointsForColor(String color) {
    return endpoints.where((e) => e.color == color).toList();
  }

  /// Check if a cell is an endpoint
  PipesEndpoint? getEndpointAt(int row, int col) {
    try {
      return endpoints.firstWhere((e) => e.row == row && e.col == col);
    } catch (e) {
      return null;
    }
  }

  /// Check if a cell is a bridge
  bool isBridge(int row, int col) {
    return bridges.any((b) => b[0] == row && b[1] == col);
  }

  /// Check if all cells are filled with paths
  bool get allCellsFilled {
    final filledCells = <String>{};

    for (final path in currentPaths.values) {
      for (final cell in path) {
        filledCells.add('${cell[0]},${cell[1]}');
      }
    }

    // Bridges can have 2 paths, so we count them specially
    int totalCells = rows * cols;
    int bridgeCount = bridges.length;

    // Each bridge allows one extra path through it
    return filledCells.length >= totalCells;
  }

  /// Check if all color pairs are connected
  bool get allPairsConnected {
    for (final color in colors) {
      final colorEndpoints = getEndpointsForColor(color);
      if (colorEndpoints.length != 2) continue;

      final path = currentPaths[color];
      if (path == null || path.length < 2) return false;

      // Check if path connects both endpoints
      final start = path.first;
      final end = path.last;
      final ep1 = colorEndpoints[0];
      final ep2 = colorEndpoints[1];

      final startsAtEndpoint = (start[0] == ep1.row && start[1] == ep1.col) ||
                               (start[0] == ep2.row && start[1] == ep2.col);
      final endsAtEndpoint = (end[0] == ep1.row && end[1] == ep1.col) ||
                             (end[0] == ep2.row && end[1] == ep2.col);

      if (!startsAtEndpoint || !endsAtEndpoint) return false;
    }
    return true;
  }

  bool get isComplete => allCellsFilled && allPairsConnected;

  /// Clear path for a specific color
  void clearPath(String color) {
    currentPaths.remove(color);
  }

  /// Add cell to current path
  void addToPath(String color, int row, int col) {
    currentPaths[color] ??= [];
    currentPaths[color]!.add([row, col]);
  }

  /// Reset all paths
  void reset() {
    currentPaths.clear();
    selectedColor = null;
  }
}

// Lights Out specific models
class LightsOutPuzzle {
  final int rows;
  final int cols;
  final List<List<bool>> initialState; // true = on, false = off
  List<List<bool>> currentState;
  final List<List<int>> solutionMoves; // Optimal solution moves [row, col]
  final int minMoves;
  int moveCount;

  LightsOutPuzzle({
    required this.rows,
    required this.cols,
    required this.initialState,
    List<List<bool>>? currentState,
    required this.solutionMoves,
    required this.minMoves,
    this.moveCount = 0,
  }) : currentState = currentState ??
         initialState.map((row) => List<bool>.from(row)).toList();

  factory LightsOutPuzzle.fromJson(Map<String, dynamic> json) {
    final puzzleData = json;
    final solutionData = json['solution'] ?? {};

    final initialState = (puzzleData['initialState'] as List).map<List<bool>>((row) {
      return (row as List).map<bool>((cell) => cell as bool).toList();
    }).toList();

    final solutionMoves = solutionData['moves'] != null
        ? (solutionData['moves'] as List).map<List<int>>((move) {
            return (move as List).map<int>((c) => c as int).toList();
          }).toList()
        : <List<int>>[];

    return LightsOutPuzzle(
      rows: puzzleData['rows'] as int,
      cols: puzzleData['cols'] as int,
      initialState: initialState,
      solutionMoves: solutionMoves,
      minMoves: solutionData['minMoves'] as int? ?? 0,
    );
  }

  /// Toggle a light and its neighbors
  void toggle(int row, int col) {
    if (row < 0 || row >= rows || col < 0 || col >= cols) return;

    // Toggle the cell
    currentState[row][col] = !currentState[row][col];

    // Toggle up
    if (row > 0) currentState[row - 1][col] = !currentState[row - 1][col];
    // Toggle down
    if (row < rows - 1) currentState[row + 1][col] = !currentState[row + 1][col];
    // Toggle left
    if (col > 0) currentState[row][col - 1] = !currentState[row][col - 1];
    // Toggle right
    if (col < cols - 1) currentState[row][col + 1] = !currentState[row][col + 1];

    moveCount++;
  }

  /// Check if all lights are off
  bool get isComplete {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (currentState[r][c]) return false;
      }
    }
    return true;
  }

  /// Count of lights currently on
  int get lightsOnCount {
    int count = 0;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (currentState[r][c]) count++;
      }
    }
    return count;
  }

  /// Reset to initial state
  void reset() {
    currentState = initialState.map((row) => List<bool>.from(row)).toList();
    moveCount = 0;
  }
}

// Word Ladder specific models
class WordLadderPuzzle {
  final String startWord;
  final String targetWord;
  final int wordLength;
  final List<String> solutionPath; // Optimal path from start to target
  final int minSteps;

  // User state
  List<String> currentPath; // User's current path

  WordLadderPuzzle({
    required this.startWord,
    required this.targetWord,
    required this.wordLength,
    required this.solutionPath,
    required this.minSteps,
    List<String>? currentPath,
  }) : currentPath = currentPath ?? [startWord];

  factory WordLadderPuzzle.fromJson(Map<String, dynamic> json) {
    final puzzleData = json;
    final solutionData = json['solution'] ?? {};

    return WordLadderPuzzle(
      startWord: puzzleData['startWord'] as String,
      targetWord: puzzleData['targetWord'] as String,
      wordLength: puzzleData['wordLength'] as int,
      solutionPath: List<String>.from(solutionData['path'] ?? []),
      minSteps: solutionData['minSteps'] as int? ?? 0,
    );
  }

  /// Check if a word differs by exactly one letter from another
  bool differsByOneLetter(String word1, String word2) {
    if (word1.length != word2.length) return false;
    int differences = 0;
    for (int i = 0; i < word1.length; i++) {
      if (word1[i].toUpperCase() != word2[i].toUpperCase()) {
        differences++;
        if (differences > 1) return false;
      }
    }
    return differences == 1;
  }

  /// Check if a word can be added to the current path
  bool canAddWord(String word) {
    if (word.length != wordLength) return false;
    if (currentPath.isEmpty) return true;
    return differsByOneLetter(currentPath.last, word);
  }

  /// Add a word to the path
  bool addWord(String word) {
    final upperWord = word.toUpperCase();
    if (!canAddWord(upperWord)) return false;
    currentPath.add(upperWord);
    return true;
  }

  /// Remove the last word from the path (undo)
  bool undoLastWord() {
    if (currentPath.length <= 1) return false; // Can't remove start word
    currentPath.removeLast();
    return true;
  }

  /// Check if puzzle is complete
  bool get isComplete {
    if (currentPath.isEmpty) return false;
    return currentPath.last.toUpperCase() == targetWord.toUpperCase();
  }

  /// Get current step count
  int get currentSteps => currentPath.length - 1;

  /// Reset to start
  void reset() {
    currentPath = [startWord];
  }
}

// Connections specific models
class ConnectionsCategory {
  final String name;
  final List<String> words;
  final int difficulty; // 1-4, 1=easiest (yellow), 4=hardest (purple)

  ConnectionsCategory({
    required this.name,
    required this.words,
    required this.difficulty,
  });

  factory ConnectionsCategory.fromJson(Map<String, dynamic> json) {
    return ConnectionsCategory(
      name: json['name'] as String,
      words: List<String>.from(json['words'] as List),
      difficulty: json['difficulty'] as int,
    );
  }
}

class ConnectionsPuzzle {
  final List<String> words; // 16 words, shuffled
  final List<ConnectionsCategory> categories; // 4 categories

  // User state
  Set<String> selectedWords; // Currently selected words
  List<ConnectionsCategory> foundCategories; // Successfully found categories
  int mistakesRemaining;
  static const int maxMistakes = 4;

  ConnectionsPuzzle({
    required this.words,
    required this.categories,
    Set<String>? selectedWords,
    List<ConnectionsCategory>? foundCategories,
    this.mistakesRemaining = maxMistakes,
  })  : selectedWords = selectedWords ?? {},
        foundCategories = foundCategories ?? [];

  factory ConnectionsPuzzle.fromJson(Map<String, dynamic> json) {
    final puzzleData = json;

    final categories = (puzzleData['categories'] as List)
        .map<ConnectionsCategory>((c) => ConnectionsCategory.fromJson(c))
        .toList();

    return ConnectionsPuzzle(
      words: List<String>.from(puzzleData['words'] as List),
      categories: categories,
    );
  }

  /// Get words that haven't been found yet
  List<String> get remainingWords {
    final foundWords = <String>{};
    for (final cat in foundCategories) {
      foundWords.addAll(cat.words);
    }
    return words.where((w) => !foundWords.contains(w)).toList();
  }

  /// Toggle word selection
  void toggleWord(String word) {
    if (selectedWords.contains(word)) {
      selectedWords.remove(word);
    } else if (selectedWords.length < 4) {
      selectedWords.add(word);
    }
  }

  /// Check if selected words form a valid category
  ConnectionsCategory? checkSelection() {
    if (selectedWords.length != 4) return null;

    for (final category in categories) {
      if (foundCategories.contains(category)) continue;

      final categoryWords = Set<String>.from(category.words);
      if (categoryWords.containsAll(selectedWords) &&
          selectedWords.containsAll(categoryWords)) {
        return category;
      }
    }
    return null;
  }

  /// Submit the current selection
  /// Returns: the category if correct, null if wrong
  ConnectionsCategory? submitSelection() {
    final category = checkSelection();
    if (category != null) {
      foundCategories.add(category);
      selectedWords.clear();
      // Sort found categories by difficulty
      foundCategories.sort((a, b) => a.difficulty.compareTo(b.difficulty));
    } else {
      mistakesRemaining--;
      selectedWords.clear();
    }
    return category;
  }

  /// Check how many words match any category
  int get matchCount {
    if (selectedWords.length != 4) return 0;

    int bestMatch = 0;
    for (final category in categories) {
      if (foundCategories.contains(category)) continue;

      int matches = 0;
      for (final word in selectedWords) {
        if (category.words.contains(word)) matches++;
      }
      if (matches > bestMatch) bestMatch = matches;
    }
    return bestMatch;
  }

  /// Check if game is over (won or lost)
  bool get isGameOver => isComplete || mistakesRemaining <= 0;

  /// Check if puzzle is complete (all categories found)
  bool get isComplete => foundCategories.length == 4;

  /// Clear selection
  void clearSelection() {
    selectedWords.clear();
  }

  /// Reset the puzzle
  void reset() {
    selectedWords.clear();
    foundCategories.clear();
    mistakesRemaining = maxMistakes;
  }

  /// Get color for a difficulty level
  static String getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1: return 'yellow';
      case 2: return 'green';
      case 3: return 'blue';
      case 4: return 'purple';
      default: return 'gray';
    }
  }
}

// ======================================
// MATHORA PUZZLE MODEL
// ======================================

class MathoraOperation {
  final String type; // 'add', 'subtract', 'multiply', 'divide'
  final int value;
  final String display;

  MathoraOperation({
    required this.type,
    required this.value,
    required this.display,
  });

  factory MathoraOperation.fromJson(Map<String, dynamic> json) {
    return MathoraOperation(
      type: json['type'] as String,
      value: json['value'] as int,
      display: json['display'] as String,
    );
  }

  /// Apply this operation to a value
  int apply(int currentValue) {
    switch (type) {
      case 'add':
        return currentValue + value;
      case 'subtract':
        return currentValue - value;
      case 'multiply':
        return currentValue * value;
      case 'divide':
        if (currentValue % value != 0) {
          return currentValue; // Don't allow non-integer division
        }
        return currentValue ~/ value;
      default:
        return currentValue;
    }
  }
}

class MathoraPuzzle {
  final int startNumber;
  final int targetNumber;
  final int maxMoves;
  final List<MathoraOperation> operations;
  final List<MathoraOperation> solutionSteps;

  // Game state
  int currentValue;
  List<MathoraOperation> appliedOperations = [];
  int movesLeft;

  MathoraPuzzle({
    required this.startNumber,
    required this.targetNumber,
    required this.maxMoves,
    required this.operations,
    required this.solutionSteps,
  }) : currentValue = startNumber,
       movesLeft = maxMoves;

  factory MathoraPuzzle.fromJson(Map<String, dynamic> puzzleData, Map<String, dynamic>? solution) {
    final operationsList = (puzzleData['operations'] as List)
        .map((op) => MathoraOperation.fromJson(op as Map<String, dynamic>))
        .toList();

    List<MathoraOperation> solutionSteps = [];
    if (solution != null && solution['steps'] != null) {
      solutionSteps = (solution['steps'] as List)
          .map((op) => MathoraOperation.fromJson(op as Map<String, dynamic>))
          .toList();
    }

    return MathoraPuzzle(
      startNumber: puzzleData['startNumber'] as int,
      targetNumber: puzzleData['targetNumber'] as int,
      maxMoves: puzzleData['moves'] as int,
      operations: operationsList,
      solutionSteps: solutionSteps,
    );
  }

  /// Apply an operation
  bool applyOperation(MathoraOperation operation) {
    if (movesLeft <= 0) return false;

    // Check if operation would result in invalid value
    final newValue = operation.apply(currentValue);
    if (operation.type == 'divide' && currentValue % operation.value != 0) {
      return false; // Can't divide evenly
    }
    if (newValue <= 0) {
      return false; // Don't allow zero or negative
    }

    currentValue = newValue;
    appliedOperations.add(operation);
    movesLeft--;
    return true;
  }

  /// Undo the last operation
  void undoLastOperation() {
    if (appliedOperations.isEmpty) return;

    appliedOperations.removeLast();
    movesLeft++;

    // Recalculate current value from scratch
    currentValue = startNumber;
    for (final op in appliedOperations) {
      currentValue = op.apply(currentValue);
    }
  }

  /// Check if puzzle is solved
  bool get isSolved => currentValue == targetNumber;

  /// Check if game is over (no moves left or solved)
  bool get isGameOver => movesLeft <= 0 || isSolved;

  /// Check if we've failed (no moves left and not solved)
  bool get isFailed => movesLeft <= 0 && !isSolved;

  /// Reset the puzzle
  void reset() {
    currentValue = startNumber;
    appliedOperations.clear();
    movesLeft = maxMoves;
  }

  /// Get progress as a string showing applied operations
  String get progressString {
    if (appliedOperations.isEmpty) return startNumber.toString();

    StringBuffer sb = StringBuffer();
    sb.write(startNumber);
    int value = startNumber;
    for (final op in appliedOperations) {
      sb.write(' ${op.display} ');
      value = op.apply(value);
      sb.write('= $value');
    }
    return sb.toString();
  }
}
