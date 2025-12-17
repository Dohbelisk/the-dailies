import 'dart:convert';

enum GameType { sudoku, killerSudoku, crossword, wordSearch }

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
    
    final clues = cluesData.map((c) => CrosswordClue.fromJson(c)).toList();
    
    // Calculate cell numbers
    final cellNumbers = List.generate(rows, (_) => List<int?>.filled(cols, null));
    for (final clue in clues) {
      cellNumbers[clue.startRow][clue.startCol] = clue.number;
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
