enum GameType { sudoku, killerSudoku, crossword, wordSearch, wordForge, nonogram, numberTarget, ballSort, pipes, lightsOut, wordLadder, connections, mathora, mobius, slidingPuzzle, memoryMatch, game2048, simon, towerOfHanoi, minesweeper, sokoban, kakuro, hitori, tangram }

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
      case GameType.mobius:
        return 'Möbius';
      case GameType.slidingPuzzle:
        return 'Sliding Puzzle';
      case GameType.memoryMatch:
        return 'Memory Match';
      case GameType.game2048:
        return '2048';
      case GameType.simon:
        return 'Simon';
      case GameType.towerOfHanoi:
        return 'Tower of Hanoi';
      case GameType.minesweeper:
        return 'Minesweeper';
      case GameType.sokoban:
        return 'Sokoban';
      case GameType.kakuro:
        return 'Kakuro';
      case GameType.hitori:
        return 'Hitori';
      case GameType.tangram:
        return 'Tangram';
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
      case GameType.mobius:
        return '♾️';
      case GameType.slidingPuzzle:
        return '🧩';
      case GameType.memoryMatch:
        return '🃏';
      case GameType.game2048:
        return '🔢';
      case GameType.simon:
        return '🎵';
      case GameType.towerOfHanoi:
        return '🗼';
      case GameType.minesweeper:
        return '💣';
      case GameType.sokoban:
        return '📦';
      case GameType.kakuro:
        return '➕';
      case GameType.hitori:
        return '⬛';
      case GameType.tangram:
        return '🔺';
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
  final bool isActive;

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
    this.isActive = true,
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
      isActive: json['isActive'] ?? true,
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
      'isActive': isActive,
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

  /// Checks if the value at a cell matches the solution
  /// Returns true if the value is correct according to the solution
  bool isCorrectValue(int row, int col, int value) {
    if (row < 0 || row >= 9 || col < 0 || col >= 9) return false;
    if (solution.isEmpty || solution.length != 9) return true; // No solution to check against
    return solution[row][col] == value;
  }

  /// Checks if a cell has an error (either conflicts with Sudoku rules OR doesn't match solution)
  bool hasError(int row, int col) {
    final value = grid[row][col];
    if (value == null) return false;

    // Check if it doesn't match the solution (primary check)
    if (!isCorrectValue(row, col, value)) return true;

    // Also check Sudoku rule violations (shouldn't happen if solution check works, but good for safety)
    return !isValidPlacement(row, col, value);
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

  @override
  bool isValidPlacement(int row, int col, int value) {
    // First check standard Sudoku rules
    if (!super.isValidPlacement(row, col, value)) {
      return false;
    }

    // Find the cage this cell belongs to
    KillerCage? cage;
    for (final c in cages) {
      for (final cell in c.cells) {
        if (cell[0] == row && cell[1] == col) {
          cage = c;
          break;
        }
      }
      if (cage != null) break;
    }

    if (cage == null) return true; // No cage found, allow placement

    // Check for duplicate values in the same cage
    for (final cell in cage.cells) {
      if (cell[0] == row && cell[1] == col) continue; // Skip current cell
      final cellValue = grid[cell[0]][cell[1]];
      if (cellValue == value) {
        return false; // Duplicate in cage
      }
    }

    // Calculate current sum of filled cells in the cage
    int currentSum = 0;
    int filledCount = 0;
    for (final cell in cage.cells) {
      final cellValue = (cell[0] == row && cell[1] == col)
          ? value
          : grid[cell[0]][cell[1]];
      if (cellValue != null) {
        currentSum += cellValue;
        filledCount++;
      }
    }

    // If sum already exceeds target, invalid
    if (currentSum > cage.sum) {
      return false;
    }

    // If all cells are filled, sum must equal target exactly
    if (filledCount == cage.cells.length && currentSum != cage.sum) {
      return false;
    }

    return true;
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

  /// Returns true if all non-black cells have been filled (regardless of correctness)
  bool get isFilled {
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        if (grid[i][j] != null && (userGrid[i][j] == null || userGrid[i][j]!.isEmpty)) {
          return false;
        }
      }
    }
    return true;
  }

  /// Returns true if the board is completely filled but has errors
  bool get isFilledButIncorrect => isFilled && !isComplete;

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

// Word Forge word entry with clue
class WordForgeWord {
  final String word;
  final String clue;
  final bool isPangram;

  WordForgeWord({
    required this.word,
    required this.clue,
    required this.isPangram,
  });

  factory WordForgeWord.fromJson(Map<String, dynamic> json) {
    return WordForgeWord(
      word: (json['word'] as String).toUpperCase(),
      clue: json['clue'] as String? ?? '',
      isPangram: json['isPangram'] as bool? ?? false,
    );
  }
}

// Word Forge specific models
class WordForgePuzzle {
  final List<String> letters; // 7 letters
  final String centerLetter; // Must be in every word
  final List<WordForgeWord> words; // All valid words with clues (from backend)
  Set<String> validWords; // Set of valid words for quick lookup
  Set<String> pangrams; // Words using all 7 letters
  final Set<String> foundWords; // Words the user has found
  int _maxScore; // Calculated from validWords

  // Hint tracking
  bool hasUsedPangramHint = false;
  Set<String> revealedWords = {}; // Words revealed via hints (shown with clues)

  // Public getter for maxScore
  int get maxScore => _maxScore;

  WordForgePuzzle({
    required this.letters,
    required this.centerLetter,
    required this.words,
    Set<String>? validWords,
    Set<String>? pangrams,
    Set<String>? foundWords,
    int maxScore = 0,
  })  : validWords = validWords ?? {},
        pangrams = pangrams ?? {},
        foundWords = foundWords ?? {},
        _maxScore = maxScore;

  factory WordForgePuzzle.fromJson(Map<String, dynamic> json) {
    final puzzleData = json;
    final solution = json['solution'] ?? {};

    // Parse words from backend (new format) or use empty list (legacy)
    List<WordForgeWord> wordsList = [];
    if (puzzleData['words'] != null) {
      wordsList = (puzzleData['words'] as List)
          .map((w) => WordForgeWord.fromJson(w as Map<String, dynamic>))
          .toList();
    }

    // Build validWords and pangrams sets from the words list
    final validWordsSet = wordsList.map((w) => w.word).toSet();
    final pangramsSet = wordsList.where((w) => w.isPangram).map((w) => w.word).toSet();

    // Get maxScore from solution if available
    int maxScore = solution['maxScore'] as int? ?? 0;

    final puzzle = WordForgePuzzle(
      letters: List<String>.from(puzzleData['letters'] ?? []),
      centerLetter: puzzleData['centerLetter'] ?? '',
      words: wordsList,
      validWords: validWordsSet,
      pangrams: pangramsSet,
      maxScore: maxScore,
    );

    // If maxScore not provided, calculate it
    if (maxScore == 0 && wordsList.isNotEmpty) {
      puzzle._maxScore = puzzle._calculateMaxScore();
    }

    return puzzle;
  }

  /// Initialize valid words and pangrams from dictionary (legacy support)
  void initializeFromDictionary(List<String> dictionaryWords, List<String> dictionaryPangrams) {
    validWords = dictionaryWords.map((w) => w.toUpperCase()).toSet();
    pangrams = dictionaryPangrams.map((w) => w.toUpperCase()).toSet();
    _maxScore = _calculateMaxScore();
  }

  int _calculateMaxScore() {
    int score = 0;
    for (final word in validWords) {
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

  /// Get clue for a word
  String? getClueForWord(String word) {
    final upperWord = word.toUpperCase();
    try {
      return words.firstWhere((w) => w.word == upperWord).clue;
    } catch (e) {
      return null;
    }
  }

  /// Get unfound words starting with a two-letter prefix
  List<WordForgeWord> getUnfoundWordsWithPrefix(String prefix) {
    final upperPrefix = prefix.toUpperCase();
    return words.where((w) =>
      w.word.startsWith(upperPrefix) &&
      !foundWords.contains(w.word) &&
      !revealedWords.contains(w.word)
    ).toList();
  }

  /// Reveal a random word with the given prefix (costs a hint)
  /// Returns the revealed word with clue, or null if none available
  WordForgeWord? revealWordWithPrefix(String prefix) {
    final available = getUnfoundWordsWithPrefix(prefix);
    if (available.isEmpty) return null;

    // Shuffle and pick one
    available.shuffle();
    final revealed = available.first;
    revealedWords.add(revealed.word);
    return revealed;
  }

  // Spelling Bee style levels - complete at "Genius" (70%)
  static const List<Map<String, dynamic>> levels = [
    {'name': 'Beginner', 'percent': 0},
    {'name': 'Good Start', 'percent': 2},
    {'name': 'Moving Up', 'percent': 5},
    {'name': 'Good', 'percent': 8},
    {'name': 'Solid', 'percent': 15},
    {'name': 'Nice', 'percent': 25},
    {'name': 'Great', 'percent': 40},
    {'name': 'Amazing', 'percent': 50},
    {'name': 'Genius', 'percent': 70},
    {'name': 'Queen Bee', 'percent': 100},
  ];

  // Target score is "Genius" level (70% of max)
  int get targetScore => (maxScore * 0.7).ceil();

  // Complete when reaching Genius level
  bool get isComplete => currentScore >= targetScore;

  // Progress as percentage (0-100)
  double get progressPercent => maxScore > 0 ? (currentScore / maxScore * 100).clamp(0, 100) : 0;

  // Current level name
  String get currentLevel {
    final percent = progressPercent;
    String level = 'Beginner';
    for (final l in levels) {
      if (percent >= l['percent']) {
        level = l['name'];
      }
    }
    return level;
  }

  // Next level info
  Map<String, dynamic>? get nextLevel {
    final percent = progressPercent;
    for (final l in levels) {
      if (percent < l['percent']) {
        return l;
      }
    }
    return null;
  }

  // Points needed for next level
  int get pointsToNextLevel {
    final next = nextLevel;
    if (next == null) return 0;
    final targetPoints = (maxScore * next['percent'] / 100).ceil();
    return targetPoints - currentScore;
  }

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
/// Represents a single target with its difficulty level
class NumberTarget {
  final int target;
  final String difficulty; // 'easy', 'medium', 'hard'
  final String? solution;
  bool completed;

  NumberTarget({
    required this.target,
    required this.difficulty,
    this.solution,
    this.completed = false,
  });

  factory NumberTarget.fromJson(Map<String, dynamic> json) {
    return NumberTarget(
      target: json['target'] as int,
      difficulty: json['difficulty'] as String? ?? 'medium',
      solution: json['expression'] as String?,
    );
  }
}

class NumberTargetPuzzle {
  final List<int> numbers; // 4 numbers to use
  final int target; // Main target (for backwards compatibility)
  final List<NumberTarget> targets; // 3 targets with increasing difficulty
  final String solution; // One valid expression
  final List<String> alternates; // Alternative solutions
  String userExpression; // User's current expression
  final List<bool> usedNumbers; // Track which numbers are used

  NumberTargetPuzzle({
    required this.numbers,
    required this.target,
    required this.solution,
    this.targets = const [],
    this.alternates = const [],
    this.userExpression = '',
    List<bool>? usedNumbers,
  }) : usedNumbers = usedNumbers ?? List.filled(4, false);

  factory NumberTargetPuzzle.fromJson(Map<String, dynamic> json) {
    final puzzleData = json;
    final solutionData = json['solution'] ?? json;

    // Parse multiple targets if available
    List<NumberTarget> targets = [];
    if (puzzleData['targets'] != null) {
      final targetsList = puzzleData['targets'] as List;
      final solutionsList = solutionData['targetSolutions'] as List? ?? [];

      for (int i = 0; i < targetsList.length; i++) {
        final targetData = targetsList[i] as Map<String, dynamic>;
        String? solution;
        if (i < solutionsList.length) {
          solution = (solutionsList[i] as Map<String, dynamic>)['expression'] as String?;
        }
        targets.add(NumberTarget(
          target: targetData['target'] as int,
          difficulty: targetData['difficulty'] as String? ?? 'medium',
          solution: solution,
        ));
      }
    }

    return NumberTargetPuzzle(
      numbers: List<int>.from(puzzleData['numbers'] ?? []),
      target: puzzleData['target'] as int,
      targets: targets,
      solution: solutionData['expression'] ?? '',
      alternates: List<String>.from(solutionData['alternates'] ?? []),
    );
  }

  /// Check if all 3 targets have been completed
  bool get allTargetsComplete {
    if (targets.isEmpty) return isComplete;
    return targets.every((t) => t.completed);
  }

  /// Get the count of completed targets
  int get completedTargetCount => targets.where((t) => t.completed).length;

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
  final int ballCount; // Number of balls moved (for multi-ball moves)

  BallSortMove({required this.from, required this.to, this.ballCount = 1});

  factory BallSortMove.fromJson(Map<String, dynamic> json) {
    return BallSortMove(
      from: json['from'] as int,
      to: json['to'] as int,
      ballCount: json['ballCount'] as int? ?? 1,
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

  /// Count consecutive same-color balls from the top of a tube
  int getConsecutiveTopBalls(int tubeIndex) {
    if (tubeIndex < 0 || tubeIndex >= currentState.length) return 0;
    final tube = currentState[tubeIndex];
    if (tube.isEmpty) return 0;

    final topColor = tube.last;
    int count = 0;
    for (int i = tube.length - 1; i >= 0; i--) {
      if (tube[i] == topColor) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  bool canMoveTo(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) return false;
    if (fromIndex < 0 || fromIndex >= currentState.length) return false;
    if (toIndex < 0 || toIndex >= currentState.length) return false;

    final fromTube = currentState[fromIndex];
    final toTube = currentState[toIndex];

    // Can't move from empty tube
    if (fromTube.isEmpty) return false;

    final availableSpace = tubeCapacity - toTube.length;

    // Need at least 1 space (we'll move as many as fit)
    if (availableSpace <= 0) return false;

    // Can move to empty tube
    if (toTube.isEmpty) {
      return true;
    }

    // Can move if destination top ball matches
    return toTube.last == fromTube.last;
  }

  bool moveBall(int fromIndex, int toIndex) {
    if (!canMoveTo(fromIndex, toIndex)) return false;

    final fromTube = currentState[fromIndex];
    final toTube = currentState[toIndex];

    // Count how many consecutive balls we can move
    final consecutiveBalls = getConsecutiveTopBalls(fromIndex);
    final availableSpace = tubeCapacity - toTube.length;

    // Move as many balls as possible (limited by space and consecutive count)
    final ballsToMove = consecutiveBalls < availableSpace ? consecutiveBalls : availableSpace;

    // Move the balls
    for (int i = 0; i < ballsToMove; i++) {
      final ball = fromTube.removeLast();
      toTube.add(ball);
    }

    moveHistory.add(BallSortMove(from: fromIndex, to: toIndex, ballCount: ballsToMove));
    moveCount++;
    return true;
  }

  bool undoMove() {
    if (moveHistory.isEmpty) return false;

    final lastMove = moveHistory.removeLast();
    // Move all balls back
    for (int i = 0; i < lastMove.ballCount; i++) {
      final ball = currentState[lastMove.to].removeLast();
      currentState[lastMove.from].add(ball);
    }
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
          // Handle both formats: {"row": x, "col": y} or [x, y]
          if (cell is Map) {
            return [cell['row'] as int, cell['col'] as int];
          } else {
            return (cell as List).map<int>((c) => c as int).toList();
          }
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

    // Check if all cells are filled
    int totalCells = rows * cols;
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
            // Handle both Map format {"row": x, "col": y} and List format [row, col]
            if (move is Map) {
              return [move['row'] as int, move['col'] as int];
            } else {
              return (move as List).map<int>((c) => c as int).toList();
            }
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

  // User state - bidirectional paths
  List<String> pathFromStart; // Path building from start word
  List<String> pathFromTarget; // Path building from target word

  WordLadderPuzzle({
    required this.startWord,
    required this.targetWord,
    required this.wordLength,
    required this.solutionPath,
    required this.minSteps,
    List<String>? pathFromStart,
    List<String>? pathFromTarget,
  }) : pathFromStart = pathFromStart ?? [startWord],
       pathFromTarget = pathFromTarget ?? [targetWord];

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

  /// Check which path(s) a word can be added to
  /// Returns: 'start', 'target', 'both', or 'none'
  String canAddWordTo(String word) {
    if (word.length != wordLength) return 'none';
    final upperWord = word.toUpperCase();

    final canAddToStart = differsByOneLetter(pathFromStart.last, upperWord);
    final canAddToTarget = differsByOneLetter(pathFromTarget.last, upperWord);

    if (canAddToStart && canAddToTarget) return 'both';
    if (canAddToStart) return 'start';
    if (canAddToTarget) return 'target';
    return 'none';
  }

  /// Check if a word can be added to either path
  bool canAddWord(String word) {
    return canAddWordTo(word) != 'none';
  }

  /// Add a word to the appropriate path
  /// Returns which path it was added to: 'start', 'target', or 'none'
  String addWord(String word) {
    final upperWord = word.toUpperCase();
    final addTo = canAddWordTo(upperWord);

    if (addTo == 'none') return 'none';

    // Prefer adding to start path, or to the shorter path if both valid
    if (addTo == 'start' || (addTo == 'both' && pathFromStart.length <= pathFromTarget.length)) {
      pathFromStart.add(upperWord);
      return 'start';
    } else {
      pathFromTarget.add(upperWord);
      return 'target';
    }
  }

  /// Remove the last word from a path (undo)
  /// Removes from whichever path was modified last (the longer non-initial path)
  bool undoLastWord() {
    // Can't remove if both paths only have their initial word
    if (pathFromStart.length <= 1 && pathFromTarget.length <= 1) return false;

    // Remove from the path that has more words added
    if (pathFromStart.length > pathFromTarget.length) {
      pathFromStart.removeLast();
    } else if (pathFromTarget.length > 1) {
      pathFromTarget.removeLast();
    } else {
      pathFromStart.removeLast();
    }
    return true;
  }

  /// Check if puzzle is complete (paths meet)
  bool get isComplete {
    // Complete when the ends of both paths differ by one letter or are the same
    final startEnd = pathFromStart.last.toUpperCase();
    final targetEnd = pathFromTarget.last.toUpperCase();
    return startEnd == targetEnd || differsByOneLetter(startEnd, targetEnd);
  }

  /// Get current step count (total words added minus the 2 starting words)
  int get currentSteps => pathFromStart.length + pathFromTarget.length - 2;

  /// Get the combined path for display (merged from both directions)
  List<String> get displayPath {
    if (!isComplete) {
      // Not complete - show both paths separately
      // This shouldn't really be called for display in incomplete state
      return [...pathFromStart];
    }
    // Merge paths: start path + reversed target path (excluding duplicate)
    final result = [...pathFromStart];
    // Check if paths share the meeting word
    if (pathFromStart.last.toUpperCase() == pathFromTarget.last.toUpperCase()) {
      // Same word - don't duplicate
      for (int i = pathFromTarget.length - 2; i >= 0; i--) {
        result.add(pathFromTarget[i]);
      }
    } else {
      // Different words that differ by one letter
      for (int i = pathFromTarget.length - 1; i >= 0; i--) {
        result.add(pathFromTarget[i]);
      }
    }
    return result;
  }

  /// Reset to start
  void reset() {
    pathFromStart = [startWord];
    pathFromTarget = [targetWord];
  }

  // Legacy getter for compatibility
  List<String> get currentPath => pathFromStart;
  set currentPath(List<String> value) => pathFromStart = value;
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
  bool wasLost; // Track if game ended in a loss
  static const int maxMistakes = 4;

  ConnectionsPuzzle({
    required this.words,
    required this.categories,
    Set<String>? selectedWords,
    List<ConnectionsCategory>? foundCategories,
    this.mistakesRemaining = maxMistakes,
    this.wasLost = false,
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

  /// Check if player won (completed without losing)
  bool get wasWon => isComplete && !wasLost;

  /// Clear selection
  void clearSelection() {
    selectedWords.clear();
  }

  /// Shuffle the remaining words
  void shuffleWords() {
    words.shuffle();
  }

  /// Reset the puzzle
  void reset() {
    selectedWords.clear();
    foundCategories.clear();
    mistakesRemaining = maxMistakes;
    wasLost = false;
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

// ======================================
// MÖBIUS PUZZLE MODEL
// ======================================

/// Direction for swipe input
enum SwipeDirection { up, down, left, right }

/// A node in the isometric puzzle structure
class MobiusNode {
  final int id;
  final double x; // Isometric X position
  final double y; // Isometric Y position (height)
  final double z; // Isometric Z position

  MobiusNode({
    required this.id,
    required this.x,
    required this.y,
    required this.z,
  });

  factory MobiusNode.fromJson(Map<String, dynamic> json) {
    return MobiusNode(
      id: json['id'] as int,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      z: (json['z'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'x': x, 'y': y, 'z': z};
}

/// An edge connecting two nodes with a swipe direction
class MobiusEdge {
  final int fromNode;
  final int toNode;
  final SwipeDirection direction;

  MobiusEdge({
    required this.fromNode,
    required this.toNode,
    required this.direction,
  });

  factory MobiusEdge.fromJson(Map<String, dynamic> json) {
    return MobiusEdge(
      fromNode: json['from'] as int,
      toNode: json['to'] as int,
      direction: SwipeDirection.values.firstWhere(
        (d) => d.name == json['direction'],
        orElse: () => SwipeDirection.right,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'from': fromNode,
    'to': toNode,
    'direction': direction.name,
  };
}

/// The complete Möbius puzzle
class MobiusPuzzle {
  final List<MobiusNode> nodes;
  final List<MobiusEdge> edges;
  final int startNodeId;
  final int goalNodeId;

  // Game state
  int currentNodeId;
  int moveCount;
  List<int> moveHistory;

  MobiusPuzzle({
    required this.nodes,
    required this.edges,
    required this.startNodeId,
    required this.goalNodeId,
    int? currentNodeId,
    this.moveCount = 0,
    List<int>? moveHistory,
  }) : currentNodeId = currentNodeId ?? startNodeId,
       moveHistory = moveHistory ?? [];

  factory MobiusPuzzle.fromJson(Map<String, dynamic> json) {
    final puzzleData = json;

    final nodes = (puzzleData['nodes'] as List)
        .map((n) => MobiusNode.fromJson(n as Map<String, dynamic>))
        .toList();

    final edges = (puzzleData['edges'] as List)
        .map((e) => MobiusEdge.fromJson(e as Map<String, dynamic>))
        .toList();

    return MobiusPuzzle(
      nodes: nodes,
      edges: edges,
      startNodeId: puzzleData['startNode'] as int,
      goalNodeId: puzzleData['goalNode'] as int,
    );
  }

  /// Get node by ID
  MobiusNode? getNode(int id) {
    try {
      return nodes.firstWhere((n) => n.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get current node
  MobiusNode? get currentNode => getNode(currentNodeId);

  /// Get goal node
  MobiusNode? get goalNode => getNode(goalNodeId);

  /// Get all edges from current node
  List<MobiusEdge> get availableEdges {
    return edges.where((e) => e.fromNode == currentNodeId).toList();
  }

  /// Try to move in a direction
  /// Returns the target node ID if successful, null otherwise
  int? tryMove(SwipeDirection direction) {
    final edge = edges.firstWhere(
      (e) => e.fromNode == currentNodeId && e.direction == direction,
      orElse: () => MobiusEdge(fromNode: -1, toNode: -1, direction: direction),
    );

    if (edge.fromNode == -1) return null;

    moveHistory.add(currentNodeId);
    currentNodeId = edge.toNode;
    moveCount++;
    return edge.toNode;
  }

  /// Undo last move
  bool undoMove() {
    if (moveHistory.isEmpty) return false;
    currentNodeId = moveHistory.removeLast();
    moveCount--;
    return true;
  }

  /// Check if puzzle is complete
  bool get isComplete => currentNodeId == goalNodeId;

  /// Reset to start
  void reset() {
    currentNodeId = startNodeId;
    moveCount = 0;
    moveHistory.clear();
  }

  // ======================================
  // SAMPLE LEVELS FOR PROTOTYPING
  // ======================================

  /// Simple tutorial level - straight path
  static MobiusPuzzle sampleLevel1() {
    return MobiusPuzzle(
      nodes: [
        MobiusNode(id: 0, x: 0, y: 0, z: 0),
        MobiusNode(id: 1, x: 1, y: 0, z: 0),
        MobiusNode(id: 2, x: 2, y: 0, z: 0),
        MobiusNode(id: 3, x: 2, y: 0, z: 1),
      ],
      edges: [
        MobiusEdge(fromNode: 0, toNode: 1, direction: SwipeDirection.right),
        MobiusEdge(fromNode: 1, toNode: 0, direction: SwipeDirection.left),
        MobiusEdge(fromNode: 1, toNode: 2, direction: SwipeDirection.right),
        MobiusEdge(fromNode: 2, toNode: 1, direction: SwipeDirection.left),
        MobiusEdge(fromNode: 2, toNode: 3, direction: SwipeDirection.down),
        MobiusEdge(fromNode: 3, toNode: 2, direction: SwipeDirection.up),
      ],
      startNodeId: 0,
      goalNodeId: 3,
    );
  }

  /// Impossible staircase - Penrose style
  static MobiusPuzzle sampleLevel2() {
    return MobiusPuzzle(
      nodes: [
        // Bottom level
        MobiusNode(id: 0, x: 0, y: 0, z: 0),
        MobiusNode(id: 1, x: 1, y: 0, z: 0),
        MobiusNode(id: 2, x: 2, y: 0, z: 0),
        // Rising stairs
        MobiusNode(id: 3, x: 2, y: 1, z: 1),
        MobiusNode(id: 4, x: 2, y: 2, z: 2),
        // Top level (appears to connect back impossibly)
        MobiusNode(id: 5, x: 1, y: 2, z: 2),
        MobiusNode(id: 6, x: 0, y: 2, z: 2),
        // "Impossible" connection back to start level
        MobiusNode(id: 7, x: 0, y: 0, z: 1), // Goal - visually at height but connects down
      ],
      edges: [
        // Horizontal path
        MobiusEdge(fromNode: 0, toNode: 1, direction: SwipeDirection.right),
        MobiusEdge(fromNode: 1, toNode: 0, direction: SwipeDirection.left),
        MobiusEdge(fromNode: 1, toNode: 2, direction: SwipeDirection.right),
        MobiusEdge(fromNode: 2, toNode: 1, direction: SwipeDirection.left),
        // Ascending
        MobiusEdge(fromNode: 2, toNode: 3, direction: SwipeDirection.up),
        MobiusEdge(fromNode: 3, toNode: 2, direction: SwipeDirection.down),
        MobiusEdge(fromNode: 3, toNode: 4, direction: SwipeDirection.up),
        MobiusEdge(fromNode: 4, toNode: 3, direction: SwipeDirection.down),
        // Top path
        MobiusEdge(fromNode: 4, toNode: 5, direction: SwipeDirection.left),
        MobiusEdge(fromNode: 5, toNode: 4, direction: SwipeDirection.right),
        MobiusEdge(fromNode: 5, toNode: 6, direction: SwipeDirection.left),
        MobiusEdge(fromNode: 6, toNode: 5, direction: SwipeDirection.right),
        // Impossible descent
        MobiusEdge(fromNode: 6, toNode: 7, direction: SwipeDirection.down),
        MobiusEdge(fromNode: 7, toNode: 6, direction: SwipeDirection.up),
      ],
      startNodeId: 0,
      goalNodeId: 7,
    );
  }

  /// Complex with multiple paths
  static MobiusPuzzle sampleLevel3() {
    return MobiusPuzzle(
      nodes: [
        // Center structure
        MobiusNode(id: 0, x: 1, y: 0, z: 1), // Start - center bottom
        MobiusNode(id: 1, x: 0, y: 0, z: 1), // Left
        MobiusNode(id: 2, x: 2, y: 0, z: 1), // Right
        MobiusNode(id: 3, x: 1, y: 1, z: 0), // Back elevated
        MobiusNode(id: 4, x: 1, y: 1, z: 2), // Front elevated
        MobiusNode(id: 5, x: 0, y: 2, z: 0), // Back left top
        MobiusNode(id: 6, x: 2, y: 2, z: 2), // Front right top
        MobiusNode(id: 7, x: 1, y: 3, z: 1), // Goal - top center
      ],
      edges: [
        // From start
        MobiusEdge(fromNode: 0, toNode: 1, direction: SwipeDirection.left),
        MobiusEdge(fromNode: 0, toNode: 2, direction: SwipeDirection.right),
        MobiusEdge(fromNode: 0, toNode: 3, direction: SwipeDirection.up),
        MobiusEdge(fromNode: 0, toNode: 4, direction: SwipeDirection.down),
        // Back paths
        MobiusEdge(fromNode: 1, toNode: 0, direction: SwipeDirection.right),
        MobiusEdge(fromNode: 1, toNode: 5, direction: SwipeDirection.up),
        MobiusEdge(fromNode: 2, toNode: 0, direction: SwipeDirection.left),
        MobiusEdge(fromNode: 2, toNode: 6, direction: SwipeDirection.up),
        // Elevated paths
        MobiusEdge(fromNode: 3, toNode: 0, direction: SwipeDirection.down),
        MobiusEdge(fromNode: 3, toNode: 5, direction: SwipeDirection.left),
        MobiusEdge(fromNode: 4, toNode: 0, direction: SwipeDirection.up),
        MobiusEdge(fromNode: 4, toNode: 6, direction: SwipeDirection.right),
        // Top paths
        MobiusEdge(fromNode: 5, toNode: 1, direction: SwipeDirection.down),
        MobiusEdge(fromNode: 5, toNode: 3, direction: SwipeDirection.right),
        MobiusEdge(fromNode: 5, toNode: 7, direction: SwipeDirection.up),
        MobiusEdge(fromNode: 6, toNode: 2, direction: SwipeDirection.down),
        MobiusEdge(fromNode: 6, toNode: 4, direction: SwipeDirection.left),
        MobiusEdge(fromNode: 6, toNode: 7, direction: SwipeDirection.up),
        // Goal
        MobiusEdge(fromNode: 7, toNode: 5, direction: SwipeDirection.left),
        MobiusEdge(fromNode: 7, toNode: 6, direction: SwipeDirection.right),
      ],
      startNodeId: 0,
      goalNodeId: 7,
    );
  }
}

// ======================================
// SLIDING PUZZLE MODEL
// ======================================

/// Classic sliding tile puzzle (15-puzzle, 8-puzzle, etc.)
class SlidingPuzzle {
  final int size; // 3x3, 4x4, or 5x5
  List<int?> tiles; // null = empty space, 1-based numbers
  final List<int?> solution; // Target configuration
  int moveCount;
  List<int> moveHistory; // Indices of tiles that were moved

  SlidingPuzzle({
    required this.size,
    required this.tiles,
    required this.solution,
    this.moveCount = 0,
    List<int>? moveHistory,
  }) : moveHistory = moveHistory ?? [];

  /// Get the index of the empty space
  int get emptyIndex => tiles.indexOf(null);

  /// Get row and column from index
  int getRow(int index) => index ~/ size;
  int getCol(int index) => index % size;

  /// Get index from row and column
  int getIndex(int row, int col) => row * size + col;

  /// Check if a tile at the given index can be moved
  bool canMove(int index) {
    if (index < 0 || index >= tiles.length) return false;
    if (tiles[index] == null) return false; // Can't move empty space

    final emptyIdx = emptyIndex;
    final tileRow = getRow(index);
    final tileCol = getCol(index);
    final emptyRow = getRow(emptyIdx);
    final emptyCol = getCol(emptyIdx);

    // Can move if adjacent (not diagonal) to empty space
    final rowDiff = (tileRow - emptyRow).abs();
    final colDiff = (tileCol - emptyCol).abs();

    return (rowDiff == 1 && colDiff == 0) || (rowDiff == 0 && colDiff == 1);
  }

  /// Move the tile at the given index into the empty space
  bool moveTile(int index) {
    if (!canMove(index)) return false;

    final emptyIdx = emptyIndex;
    tiles[emptyIdx] = tiles[index];
    tiles[index] = null;
    moveCount++;
    moveHistory.add(index);
    return true;
  }

  /// Undo the last move
  bool undoMove() {
    if (moveHistory.isEmpty) return false;

    // Find where the tile that was last moved is now (the current empty space)
    // and move it back to where it came from
    final lastMovedFromIndex = moveHistory.removeLast();
    final emptyIdx = emptyIndex;

    tiles[lastMovedFromIndex] = tiles[emptyIdx];
    tiles[emptyIdx] = null;
    moveCount--;
    return true;
  }

  /// Check if puzzle is solved
  bool get isComplete {
    for (int i = 0; i < tiles.length; i++) {
      if (tiles[i] != solution[i]) return false;
    }
    return true;
  }

  /// Reset to initial scrambled state
  void reset() {
    // Reverse all moves
    while (moveHistory.isNotEmpty) {
      undoMove();
    }
    moveCount = 0;
  }

  /// Get all indices that can currently be moved
  List<int> get movableTiles {
    final result = <int>[];
    for (int i = 0; i < tiles.length; i++) {
      if (canMove(i)) result.add(i);
    }
    return result;
  }

  // ======================================
  // SAMPLE LEVELS
  // ======================================

  /// 3x3 (8-puzzle) - Easy
  static SlidingPuzzle sampleLevel1() {
    // Solution: 1,2,3,4,5,6,7,8,null
    final solution = <int?>[1, 2, 3, 4, 5, 6, 7, 8, null];
    // Scrambled (solvable)
    final tiles = <int?>[1, 2, 3, 4, 5, null, 7, 8, 6];
    return SlidingPuzzle(size: 3, tiles: tiles, solution: solution);
  }

  /// 4x4 (15-puzzle) - Medium
  static SlidingPuzzle sampleLevel2() {
    // Solution: 1-15, null
    final solution = <int?>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, null];
    // Scrambled (solvable)
    final tiles = <int?>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, null, 13, 14, 15, 12];
    return SlidingPuzzle(size: 4, tiles: tiles, solution: solution);
  }

  /// 5x5 (24-puzzle) - Hard
  static SlidingPuzzle sampleLevel3() {
    // Solution: 1-24, null
    final solution = <int?>[
      1, 2, 3, 4, 5,
      6, 7, 8, 9, 10,
      11, 12, 13, 14, 15,
      16, 17, 18, 19, 20,
      21, 22, 23, 24, null
    ];
    // Scrambled (solvable)
    final tiles = <int?>[
      1, 2, 3, 4, 5,
      6, 7, 8, 9, 10,
      11, 12, 13, 14, 15,
      16, 17, 18, 19, null,
      21, 22, 23, 24, 20
    ];
    return SlidingPuzzle(size: 5, tiles: tiles, solution: solution);
  }
}

// ======================================
// MEMORY MATCH PUZZLE MODEL
// ======================================

/// Classic card matching memory game
class MemoryMatchPuzzle {
  final int rows;
  final int cols;
  final List<String> cardValues; // Symbols/emojis for pairs
  List<List<String>> board; // The shuffled board
  List<List<bool>> revealed; // Which cards are face up
  List<List<bool>> matched; // Which cards have been matched
  int? firstFlipRow;
  int? firstFlipCol;
  int? secondFlipRow;
  int? secondFlipCol;
  int pairsFound;
  int flipCount;
  int moveCount; // A "move" is completing a pair attempt

  MemoryMatchPuzzle({
    required this.rows,
    required this.cols,
    required this.cardValues,
    required this.board,
    List<List<bool>>? revealed,
    List<List<bool>>? matched,
    this.firstFlipRow,
    this.firstFlipCol,
    this.secondFlipRow,
    this.secondFlipCol,
    this.pairsFound = 0,
    this.flipCount = 0,
    this.moveCount = 0,
  })  : revealed = revealed ?? List.generate(rows, (_) => List.filled(cols, false)),
        matched = matched ?? List.generate(rows, (_) => List.filled(cols, false));

  /// Total number of pairs in the puzzle
  int get totalPairs => (rows * cols) ~/ 2;

  /// Check if puzzle is complete
  bool get isComplete => pairsFound >= totalPairs;

  /// Check if we're waiting for second flip
  bool get waitingForSecondFlip => firstFlipRow != null && secondFlipRow == null;

  /// Check if we're showing two unmatched cards
  bool get showingPair => firstFlipRow != null && secondFlipRow != null;

  /// Flip a card at the given position
  /// Returns: 'first' if first card flipped, 'second' if second card flipped,
  /// 'match' if pair matched, 'nomatch' if pair didn't match, 'invalid' if can't flip
  String flipCard(int row, int col) {
    // Can't flip if already revealed or matched
    if (revealed[row][col] || matched[row][col]) return 'invalid';

    // Can't flip if showing unmatched pair (need to hide them first)
    if (showingPair) return 'invalid';

    flipCount++;
    revealed[row][col] = true;

    if (firstFlipRow == null) {
      // First card of pair
      firstFlipRow = row;
      firstFlipCol = col;
      return 'first';
    } else {
      // Second card of pair
      secondFlipRow = row;
      secondFlipCol = col;
      moveCount++;

      // Check for match
      if (board[firstFlipRow!][firstFlipCol!] == board[row][col]) {
        matched[firstFlipRow!][firstFlipCol!] = true;
        matched[row][col] = true;
        pairsFound++;
        // Reset selection
        firstFlipRow = null;
        firstFlipCol = null;
        secondFlipRow = null;
        secondFlipCol = null;
        return 'match';
      } else {
        return 'nomatch';
      }
    }
  }

  /// Hide the unmatched pair (call after delay)
  void hideUnmatchedPair() {
    if (firstFlipRow != null && secondFlipRow != null) {
      revealed[firstFlipRow!][firstFlipCol!] = false;
      revealed[secondFlipRow!][secondFlipCol!] = false;
      firstFlipRow = null;
      firstFlipCol = null;
      secondFlipRow = null;
      secondFlipCol = null;
    }
  }

  /// Reset the puzzle
  void reset() {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        revealed[r][c] = false;
        matched[r][c] = false;
      }
    }
    firstFlipRow = null;
    firstFlipCol = null;
    secondFlipRow = null;
    secondFlipCol = null;
    pairsFound = 0;
    flipCount = 0;
    moveCount = 0;
  }

  // ======================================
  // SAMPLE LEVELS
  // ======================================

  static final List<String> _emojis = [
    '🍎', '🍊', '🍋', '🍇', '🍓', '🍒', '🥝', '🍑',
    '🌸', '🌺', '🌻', '🌹', '🌷', '💐', '🌼', '🪻',
  ];

  /// Create a shuffled board with pairs
  static List<List<String>> _createBoard(int rows, int cols, List<String> symbols) {
    final pairs = <String>[];
    final pairCount = (rows * cols) ~/ 2;

    for (int i = 0; i < pairCount; i++) {
      pairs.add(symbols[i % symbols.length]);
      pairs.add(symbols[i % symbols.length]);
    }
    pairs.shuffle();

    final board = <List<String>>[];
    int index = 0;
    for (int r = 0; r < rows; r++) {
      final row = <String>[];
      for (int c = 0; c < cols; c++) {
        row.add(pairs[index++]);
      }
      board.add(row);
    }
    return board;
  }

  /// 3x4 (6 pairs) - Easy
  static MemoryMatchPuzzle sampleLevel1() {
    final board = _createBoard(3, 4, _emojis);
    return MemoryMatchPuzzle(
      rows: 3,
      cols: 4,
      cardValues: _emojis.take(6).toList(),
      board: board,
    );
  }

  /// 4x4 (8 pairs) - Medium
  static MemoryMatchPuzzle sampleLevel2() {
    final board = _createBoard(4, 4, _emojis);
    return MemoryMatchPuzzle(
      rows: 4,
      cols: 4,
      cardValues: _emojis.take(8).toList(),
      board: board,
    );
  }

  /// 4x5 (10 pairs) - Hard
  static MemoryMatchPuzzle sampleLevel3() {
    final board = _createBoard(4, 5, _emojis);
    return MemoryMatchPuzzle(
      rows: 4,
      cols: 5,
      cardValues: _emojis.take(10).toList(),
      board: board,
    );
  }
}

// ======================================
// 2048 PUZZLE MODEL
// ======================================

/// Classic 2048 sliding tile game
class Game2048Puzzle {
  static const int gridSize = 4;

  List<List<int>> board; // 0 = empty, other values are powers of 2
  int score;
  int bestTile;
  int moveCount;
  bool isGameOver;
  bool hasWon;

  Game2048Puzzle({
    List<List<int>>? board,
    this.score = 0,
    this.bestTile = 0,
    this.moveCount = 0,
    this.isGameOver = false,
    this.hasWon = false,
  }) : board = board ?? List.generate(gridSize, (_) => List.filled(gridSize, 0));

  /// Check if the board has any empty cells
  bool get hasEmptyCell {
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (board[r][c] == 0) return true;
      }
    }
    return false;
  }

  /// Check if any moves are possible
  bool get canMove {
    if (hasEmptyCell) return true;

    // Check for possible merges
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        final val = board[r][c];
        if (r > 0 && board[r - 1][c] == val) return true;
        if (r < gridSize - 1 && board[r + 1][c] == val) return true;
        if (c > 0 && board[r][c - 1] == val) return true;
        if (c < gridSize - 1 && board[r][c + 1] == val) return true;
      }
    }
    return false;
  }

  /// Add a random tile (2 or 4) to an empty cell
  void addRandomTile() {
    final emptyCells = <(int, int)>[];
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (board[r][c] == 0) emptyCells.add((r, c));
      }
    }

    if (emptyCells.isEmpty) return;

    emptyCells.shuffle();
    final (row, col) = emptyCells.first;
    // 90% chance for 2, 10% chance for 4
    board[row][col] = (DateTime.now().millisecond % 10 == 0) ? 4 : 2;
  }

  /// Slide and merge tiles in a direction
  /// Returns true if any tile moved
  bool move(SwipeDirection direction) {
    bool moved = false;
    final oldBoard = board.map((row) => row.toList()).toList();

    switch (direction) {
      case SwipeDirection.up:
        for (int c = 0; c < gridSize; c++) {
          moved = _slideColumn(c, -1) || moved;
        }
        break;
      case SwipeDirection.down:
        for (int c = 0; c < gridSize; c++) {
          moved = _slideColumn(c, 1) || moved;
        }
        break;
      case SwipeDirection.left:
        for (int r = 0; r < gridSize; r++) {
          moved = _slideRow(r, -1) || moved;
        }
        break;
      case SwipeDirection.right:
        for (int r = 0; r < gridSize; r++) {
          moved = _slideRow(r, 1) || moved;
        }
        break;
    }

    // Check if board actually changed
    bool boardChanged = false;
    for (int r = 0; r < gridSize && !boardChanged; r++) {
      for (int c = 0; c < gridSize && !boardChanged; c++) {
        if (board[r][c] != oldBoard[r][c]) boardChanged = true;
      }
    }

    if (boardChanged) {
      moveCount++;
      addRandomTile();

      // Update best tile
      for (int r = 0; r < gridSize; r++) {
        for (int c = 0; c < gridSize; c++) {
          if (board[r][c] > bestTile) bestTile = board[r][c];
        }
      }

      // Check for win
      if (bestTile >= 2048 && !hasWon) {
        hasWon = true;
      }

      // Check for game over
      if (!canMove) {
        isGameOver = true;
      }
    }

    return boardChanged;
  }

  /// Slide a row in direction (-1 = left, 1 = right)
  bool _slideRow(int row, int direction) {
    final line = board[row].toList();
    final newLine = _slideLine(line, direction);
    board[row] = newLine;
    return !_listsEqual(line, newLine);
  }

  /// Slide a column in direction (-1 = up, 1 = down)
  bool _slideColumn(int col, int direction) {
    final line = <int>[];
    for (int r = 0; r < gridSize; r++) {
      line.add(board[r][col]);
    }
    final newLine = _slideLine(line, direction);
    for (int r = 0; r < gridSize; r++) {
      board[r][col] = newLine[r];
    }
    return !_listsEqual(line, newLine);
  }

  /// Slide and merge a line in direction (-1 = toward start, 1 = toward end)
  List<int> _slideLine(List<int> line, int direction) {
    // Remove zeros and collect non-zero values
    final nonZero = line.where((v) => v != 0).toList();
    if (nonZero.isEmpty) return List.filled(gridSize, 0);

    // If moving toward end, reverse
    if (direction == 1) {
      nonZero.reversed.toList();
    }

    // Work from the target end
    final result = <int>[];
    int i = direction == -1 ? 0 : nonZero.length - 1;
    final step = direction == -1 ? 1 : -1;
    final end = direction == -1 ? nonZero.length : -1;

    while (i != end) {
      final current = nonZero[i];
      final nextI = i + step;

      if (nextI != end && nonZero[nextI] == current) {
        // Merge
        final merged = current * 2;
        result.add(merged);
        score += merged;
        i = nextI + step; // Skip the merged tile
      } else {
        result.add(current);
        i = nextI;
      }
    }

    // Pad with zeros
    while (result.length < gridSize) {
      result.add(0);
    }

    // If moving toward end, reverse back
    if (direction == 1) {
      return result.reversed.toList();
    }
    return result;
  }

  bool _listsEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Reset to initial state
  void reset() {
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        board[r][c] = 0;
      }
    }
    score = 0;
    bestTile = 0;
    moveCount = 0;
    isGameOver = false;
    hasWon = false;
    addRandomTile();
    addRandomTile();
  }

  /// Check if complete (reached 2048)
  bool get isComplete => hasWon;

  // ======================================
  // SAMPLE LEVELS
  // ======================================

  /// Fresh game - Easy start
  static Game2048Puzzle sampleLevel1() {
    final puzzle = Game2048Puzzle();
    puzzle.addRandomTile();
    puzzle.addRandomTile();
    return puzzle;
  }

  /// Pre-started game - Medium
  static Game2048Puzzle sampleLevel2() {
    final puzzle = Game2048Puzzle(
      board: [
        [2, 4, 8, 2],
        [0, 2, 4, 0],
        [0, 0, 2, 0],
        [0, 0, 0, 0],
      ],
      score: 32,
      bestTile: 8,
    );
    return puzzle;
  }

  /// Advanced game - Hard
  static Game2048Puzzle sampleLevel3() {
    final puzzle = Game2048Puzzle(
      board: [
        [64, 32, 16, 8],
        [32, 16, 8, 4],
        [16, 8, 4, 2],
        [4, 2, 0, 0],
      ],
      score: 512,
      bestTile: 64,
    );
    return puzzle;
  }
}

// ======================================
// SIMON PUZZLE MODEL
// ======================================

/// Color indices for Simon game
enum SimonColor { red, blue, green, yellow }

/// Classic Simon memory game
class SimonPuzzle {
  List<SimonColor> sequence;
  int currentIndex; // Current position in player's input
  int level; // Current level (sequence length)
  int highScore;
  bool isPlayerTurn;
  bool isGameOver;
  int targetLevel; // Win condition

  SimonPuzzle({
    List<SimonColor>? sequence,
    this.currentIndex = 0,
    this.level = 0,
    this.highScore = 0,
    this.isPlayerTurn = false,
    this.isGameOver = false,
    this.targetLevel = 10,
  }) : sequence = sequence ?? [];

  /// Start a new game
  void startNewGame() {
    sequence.clear();
    currentIndex = 0;
    level = 0;
    isPlayerTurn = false;
    isGameOver = false;
    addToSequence();
  }

  /// Add a random color to the sequence
  void addToSequence() {
    final colors = SimonColor.values;
    sequence.add(colors[DateTime.now().millisecondsSinceEpoch % colors.length]);
    level = sequence.length;
    currentIndex = 0;
    isPlayerTurn = false; // Sequence will be shown first
  }

  /// Begin player's turn (called after sequence is shown)
  void beginPlayerTurn() {
    isPlayerTurn = true;
    currentIndex = 0;
  }

  /// Process player input
  /// Returns: 'correct' if matches sequence, 'wrong' if doesn't match,
  /// 'complete' if finished current sequence, 'win' if reached target
  String processInput(SimonColor color) {
    if (!isPlayerTurn || isGameOver) return 'invalid';

    if (color != sequence[currentIndex]) {
      isGameOver = true;
      if (level > highScore) highScore = level;
      return 'wrong';
    }

    currentIndex++;

    if (currentIndex >= sequence.length) {
      // Completed current sequence
      if (level >= targetLevel) {
        if (level > highScore) highScore = level;
        return 'win';
      }
      isPlayerTurn = false;
      return 'complete';
    }

    return 'correct';
  }

  /// Check if the game is complete (won)
  bool get isComplete => level >= targetLevel && !isGameOver;

  /// Reset to initial state
  void reset() {
    sequence.clear();
    currentIndex = 0;
    level = 0;
    isPlayerTurn = false;
    isGameOver = false;
  }

  // ======================================
  // SAMPLE LEVELS
  // ======================================

  /// Easy - reach level 5
  static SimonPuzzle sampleLevel1() {
    return SimonPuzzle(targetLevel: 5);
  }

  /// Medium - reach level 10
  static SimonPuzzle sampleLevel2() {
    return SimonPuzzle(targetLevel: 10);
  }

  /// Hard - reach level 15
  static SimonPuzzle sampleLevel3() {
    return SimonPuzzle(targetLevel: 15);
  }
}

// ======================================
// TOWER OF HANOI PUZZLE MODEL
// ======================================

/// Classic Tower of Hanoi puzzle
class TowerOfHanoiPuzzle {
  final int diskCount;
  List<List<int>> pegs; // 3 pegs, each with list of disk sizes (larger = bigger)
  int moveCount;
  int? selectedPeg; // Currently selected source peg
  int optimalMoves; // Minimum moves required (2^n - 1)

  TowerOfHanoiPuzzle({
    required this.diskCount,
    List<List<int>>? pegs,
    this.moveCount = 0,
    this.selectedPeg,
  })  : pegs = pegs ?? [List.generate(diskCount, (i) => diskCount - i), [], []],
        optimalMoves = (1 << diskCount) - 1; // 2^n - 1

  /// Check if a move from source to target is valid
  bool canMove(int fromPeg, int toPeg) {
    if (fromPeg < 0 || fromPeg >= 3 || toPeg < 0 || toPeg >= 3) return false;
    if (fromPeg == toPeg) return false;
    if (pegs[fromPeg].isEmpty) return false;

    final diskToMove = pegs[fromPeg].last;
    if (pegs[toPeg].isEmpty) return true;
    return diskToMove < pegs[toPeg].last;
  }

  /// Move top disk from source to target
  bool moveDisk(int fromPeg, int toPeg) {
    if (!canMove(fromPeg, toPeg)) return false;

    final disk = pegs[fromPeg].removeLast();
    pegs[toPeg].add(disk);
    moveCount++;
    return true;
  }

  /// Select a peg (for UI)
  void selectPeg(int pegIndex) {
    if (selectedPeg == null) {
      // First selection - select if peg has disks
      if (pegs[pegIndex].isNotEmpty) {
        selectedPeg = pegIndex;
      }
    } else {
      // Second selection - try to move
      if (pegIndex == selectedPeg) {
        // Deselect
        selectedPeg = null;
      } else if (canMove(selectedPeg!, pegIndex)) {
        moveDisk(selectedPeg!, pegIndex);
        selectedPeg = null;
      } else {
        // Invalid move - try selecting new peg
        if (pegs[pegIndex].isNotEmpty) {
          selectedPeg = pegIndex;
        }
      }
    }
  }

  /// Check if puzzle is solved (all disks on last peg)
  bool get isComplete {
    return pegs[0].isEmpty && pegs[1].isEmpty && pegs[2].length == diskCount;
  }

  /// Reset puzzle
  void reset() {
    pegs[0] = List.generate(diskCount, (i) => diskCount - i);
    pegs[1] = [];
    pegs[2] = [];
    moveCount = 0;
    selectedPeg = null;
  }

  /// Get efficiency rating (optimal / actual moves)
  double get efficiency {
    if (moveCount == 0) return 1.0;
    return optimalMoves / moveCount;
  }

  // ======================================
  // SAMPLE LEVELS
  // ======================================

  /// Easy - 3 disks
  static TowerOfHanoiPuzzle sampleLevel1() {
    return TowerOfHanoiPuzzle(diskCount: 3);
  }

  /// Medium - 4 disks
  static TowerOfHanoiPuzzle sampleLevel2() {
    return TowerOfHanoiPuzzle(diskCount: 4);
  }

  /// Hard - 5 disks
  static TowerOfHanoiPuzzle sampleLevel3() {
    return TowerOfHanoiPuzzle(diskCount: 5);
  }
}

// ============================================================================
// MINESWEEPER PUZZLE
// ============================================================================

/// Cell state for Minesweeper
enum MinesweeperCellState { hidden, revealed, flagged }

/// Minesweeper puzzle - reveal all safe cells without hitting mines
class MinesweeperPuzzle {
  final int rows;
  final int cols;
  final int mineCount;

  // Mine locations - true means mine
  late List<List<bool>> mines;

  // Pre-calculated adjacent mine counts
  late List<List<int>> adjacentCounts;

  // Current cell states
  late List<List<MinesweeperCellState>> cellStates;

  // Game state
  bool isGameOver = false;
  bool isWon = false;
  bool isFirstTap = true;
  int revealedCount = 0;
  int flagCount = 0;

  MinesweeperPuzzle({
    required this.rows,
    required this.cols,
    required this.mineCount,
    List<List<bool>>? initialMines,
  }) {
    cellStates = List.generate(rows, (_) =>
      List.generate(cols, (_) => MinesweeperCellState.hidden));

    if (initialMines != null) {
      mines = initialMines;
      isFirstTap = false;
      _calculateAdjacentCounts();
    } else {
      mines = List.generate(rows, (_) => List.generate(cols, (_) => false));
      adjacentCounts = List.generate(rows, (_) => List.generate(cols, (_) => 0));
    }
  }

  /// Generate mines, avoiding the first tapped cell and its neighbors
  void _generateMines(int safeRow, int safeCol) {
    final random = DateTime.now().millisecondsSinceEpoch;
    final rng = _SimpleRandom(random);

    // Create list of all valid positions (excluding safe zone)
    final validPositions = <(int, int)>[];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        // Exclude the safe cell and its neighbors
        if ((r - safeRow).abs() <= 1 && (c - safeCol).abs() <= 1) continue;
        validPositions.add((r, c));
      }
    }

    // Shuffle and pick first mineCount positions
    for (int i = validPositions.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final temp = validPositions[i];
      validPositions[i] = validPositions[j];
      validPositions[j] = temp;
    }

    for (int i = 0; i < mineCount && i < validPositions.length; i++) {
      final pos = validPositions[i];
      mines[pos.$1][pos.$2] = true;
    }

    _calculateAdjacentCounts();
  }

  void _calculateAdjacentCounts() {
    adjacentCounts = List.generate(rows, (r) => List.generate(cols, (c) {
      if (mines[r][c]) return -1; // Mine cell
      int count = 0;
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          if (dr == 0 && dc == 0) continue;
          final nr = r + dr;
          final nc = c + dc;
          if (nr >= 0 && nr < rows && nc >= 0 && nc < cols && mines[nr][nc]) {
            count++;
          }
        }
      }
      return count;
    }));
  }

  /// Reveal a cell - returns true if game should continue
  bool reveal(int row, int col) {
    if (isGameOver || isWon) return false;
    if (cellStates[row][col] != MinesweeperCellState.hidden) return true;

    // First tap - generate mines avoiding this cell
    if (isFirstTap) {
      _generateMines(row, col);
      isFirstTap = false;
    }

    // Hit a mine - game over
    if (mines[row][col]) {
      isGameOver = true;
      // Reveal all mines
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          if (mines[r][c]) {
            cellStates[r][c] = MinesweeperCellState.revealed;
          }
        }
      }
      return false;
    }

    // Flood fill reveal for empty cells
    _floodReveal(row, col);

    // Check win condition
    _checkWin();

    return true;
  }

  void _floodReveal(int row, int col) {
    if (row < 0 || row >= rows || col < 0 || col >= cols) return;
    if (cellStates[row][col] != MinesweeperCellState.hidden) return;
    if (mines[row][col]) return;

    cellStates[row][col] = MinesweeperCellState.revealed;
    revealedCount++;

    // If empty cell (no adjacent mines), reveal neighbors
    if (adjacentCounts[row][col] == 0) {
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          if (dr == 0 && dc == 0) continue;
          _floodReveal(row + dr, col + dc);
        }
      }
    }
  }

  /// Toggle flag on a cell
  void toggleFlag(int row, int col) {
    if (isGameOver || isWon) return;
    if (cellStates[row][col] == MinesweeperCellState.revealed) return;

    if (cellStates[row][col] == MinesweeperCellState.flagged) {
      cellStates[row][col] = MinesweeperCellState.hidden;
      flagCount--;
    } else {
      cellStates[row][col] = MinesweeperCellState.flagged;
      flagCount++;
    }
  }

  void _checkWin() {
    // Win when all non-mine cells are revealed
    final safeCells = rows * cols - mineCount;
    if (revealedCount >= safeCells) {
      isWon = true;
      // Auto-flag remaining mines
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          if (mines[r][c] && cellStates[r][c] == MinesweeperCellState.hidden) {
            cellStates[r][c] = MinesweeperCellState.flagged;
            flagCount++;
          }
        }
      }
    }
  }

  /// Reset the puzzle
  void reset() {
    cellStates = List.generate(rows, (_) =>
      List.generate(cols, (_) => MinesweeperCellState.hidden));
    mines = List.generate(rows, (_) => List.generate(cols, (_) => false));
    adjacentCounts = List.generate(rows, (_) => List.generate(cols, (_) => 0));
    isGameOver = false;
    isWon = false;
    isFirstTap = true;
    revealedCount = 0;
    flagCount = 0;
  }

  /// Remaining unflagged mines
  int get remainingMines => mineCount - flagCount;

  // ======================================
  // SAMPLE LEVELS
  // ======================================

  /// Easy - 9x9, 10 mines
  static MinesweeperPuzzle sampleLevel1() {
    return MinesweeperPuzzle(rows: 9, cols: 9, mineCount: 10);
  }

  /// Medium - 12x12, 25 mines
  static MinesweeperPuzzle sampleLevel2() {
    return MinesweeperPuzzle(rows: 12, cols: 12, mineCount: 25);
  }

  /// Hard - 16x16, 40 mines
  static MinesweeperPuzzle sampleLevel3() {
    return MinesweeperPuzzle(rows: 16, cols: 16, mineCount: 40);
  }
}

/// Simple random number generator
class _SimpleRandom {
  int _seed;

  _SimpleRandom(this._seed);

  int nextInt(int max) {
    _seed = (_seed * 1103515245 + 12345) & 0x7FFFFFFF;
    return _seed % max;
  }
}

// ============================================================================
// SOKOBAN PUZZLE
// ============================================================================

/// Cell types for Sokoban map
enum SokobanCell { floor, wall, target }

/// A move in Sokoban
class SokobanMove {
  final int playerFromRow;
  final int playerFromCol;
  final int playerToRow;
  final int playerToCol;
  final int? boxFromRow;
  final int? boxFromCol;
  final int? boxToRow;
  final int? boxToCol;

  SokobanMove({
    required this.playerFromRow,
    required this.playerFromCol,
    required this.playerToRow,
    required this.playerToCol,
    this.boxFromRow,
    this.boxFromCol,
    this.boxToRow,
    this.boxToCol,
  });

  bool get pushedBox => boxFromRow != null;
}

/// Sokoban puzzle - push boxes to target positions
class SokobanPuzzle {
  final int rows;
  final int cols;
  final List<List<SokobanCell>> map;
  final List<(int, int)> targetPositions;

  // Mutable state
  int playerRow;
  int playerCol;
  List<(int, int)> boxPositions;
  int moveCount;
  int pushCount;
  List<SokobanMove> moveHistory;

  SokobanPuzzle({
    required this.rows,
    required this.cols,
    required this.map,
    required this.targetPositions,
    required this.playerRow,
    required this.playerCol,
    required List<(int, int)> boxPositions,
  })  : boxPositions = List.from(boxPositions),
        moveCount = 0,
        pushCount = 0,
        moveHistory = [];

  /// Check if a position is walkable (floor or target, not occupied by box)
  bool isWalkable(int row, int col) {
    if (row < 0 || row >= rows || col < 0 || col >= cols) return false;
    if (map[row][col] == SokobanCell.wall) return false;
    return !boxPositions.contains((row, col));
  }

  /// Check if a box can be pushed to a position
  bool canPushBox(int boxRow, int boxCol, int toRow, int toCol) {
    if (toRow < 0 || toRow >= rows || toCol < 0 || toCol >= cols) return false;
    if (map[toRow][toCol] == SokobanCell.wall) return false;
    return !boxPositions.contains((toRow, toCol));
  }

  /// Try to move the player in a direction
  /// Returns true if move was successful
  bool move(int dRow, int dCol) {
    final newRow = playerRow + dRow;
    final newCol = playerCol + dCol;

    // Check bounds
    if (newRow < 0 || newRow >= rows || newCol < 0 || newCol >= cols) {
      return false;
    }

    // Check for wall
    if (map[newRow][newCol] == SokobanCell.wall) {
      return false;
    }

    // Check for box
    final boxIndex = boxPositions.indexWhere((b) => b.$1 == newRow && b.$2 == newCol);
    if (boxIndex >= 0) {
      // Try to push the box
      final boxNewRow = newRow + dRow;
      final boxNewCol = newCol + dCol;

      if (!canPushBox(newRow, newCol, boxNewRow, boxNewCol)) {
        return false;
      }

      // Push the box
      final move = SokobanMove(
        playerFromRow: playerRow,
        playerFromCol: playerCol,
        playerToRow: newRow,
        playerToCol: newCol,
        boxFromRow: newRow,
        boxFromCol: newCol,
        boxToRow: boxNewRow,
        boxToCol: boxNewCol,
      );
      moveHistory.add(move);

      boxPositions[boxIndex] = (boxNewRow, boxNewCol);
      playerRow = newRow;
      playerCol = newCol;
      moveCount++;
      pushCount++;
      return true;
    }

    // Simple move (no box)
    final move = SokobanMove(
      playerFromRow: playerRow,
      playerFromCol: playerCol,
      playerToRow: newRow,
      playerToCol: newCol,
    );
    moveHistory.add(move);

    playerRow = newRow;
    playerCol = newCol;
    moveCount++;
    return true;
  }

  /// Undo the last move
  bool undo() {
    if (moveHistory.isEmpty) return false;

    final lastMove = moveHistory.removeLast();

    // Move player back
    playerRow = lastMove.playerFromRow;
    playerCol = lastMove.playerFromCol;
    moveCount--;

    // Move box back if it was pushed
    if (lastMove.pushedBox) {
      final boxIndex = boxPositions.indexWhere(
        (b) => b.$1 == lastMove.boxToRow && b.$2 == lastMove.boxToCol
      );
      if (boxIndex >= 0) {
        boxPositions[boxIndex] = (lastMove.boxFromRow!, lastMove.boxFromCol!);
      }
      pushCount--;
    }

    return true;
  }

  /// Check if a box is on a target
  bool isBoxOnTarget(int row, int col) {
    return targetPositions.contains((row, col));
  }

  /// Check if puzzle is solved (all boxes on targets)
  bool get isComplete {
    for (final target in targetPositions) {
      if (!boxPositions.contains(target)) {
        return false;
      }
    }
    return true;
  }

  /// Reset to initial state
  void reset(List<(int, int)> initialBoxPositions, int initialPlayerRow, int initialPlayerCol) {
    boxPositions = List.from(initialBoxPositions);
    playerRow = initialPlayerRow;
    playerCol = initialPlayerCol;
    moveCount = 0;
    pushCount = 0;
    moveHistory.clear();
  }

  // ======================================
  // SAMPLE LEVELS
  // ======================================

  /// Easy - small map, 1 box
  static SokobanPuzzle sampleLevel1() {
    // Simple 5x5 level
    // # = wall, . = floor, T = target, P = player start, B = box
    // #####
    // #P.B#
    // #...#
    // #.T.#
    // #####
    final map = [
      [SokobanCell.wall, SokobanCell.wall, SokobanCell.wall, SokobanCell.wall, SokobanCell.wall],
      [SokobanCell.wall, SokobanCell.floor, SokobanCell.floor, SokobanCell.floor, SokobanCell.wall],
      [SokobanCell.wall, SokobanCell.floor, SokobanCell.floor, SokobanCell.floor, SokobanCell.wall],
      [SokobanCell.wall, SokobanCell.floor, SokobanCell.target, SokobanCell.floor, SokobanCell.wall],
      [SokobanCell.wall, SokobanCell.wall, SokobanCell.wall, SokobanCell.wall, SokobanCell.wall],
    ];
    return SokobanPuzzle(
      rows: 5,
      cols: 5,
      map: map,
      targetPositions: [(3, 2)],
      playerRow: 1,
      playerCol: 1,
      boxPositions: [(1, 3)],
    );
  }

  /// Medium - 2 boxes
  static SokobanPuzzle sampleLevel2() {
    // 6x6 level with 2 boxes
    // ######
    // #P...#
    // #.B..#
    // #..B.#
    // #TT..#
    // ######
    final map = [
      [SokobanCell.wall, SokobanCell.wall, SokobanCell.wall, SokobanCell.wall, SokobanCell.wall, SokobanCell.wall],
      [SokobanCell.wall, SokobanCell.floor, SokobanCell.floor, SokobanCell.floor, SokobanCell.floor, SokobanCell.wall],
      [SokobanCell.wall, SokobanCell.floor, SokobanCell.floor, SokobanCell.floor, SokobanCell.floor, SokobanCell.wall],
      [SokobanCell.wall, SokobanCell.floor, SokobanCell.floor, SokobanCell.floor, SokobanCell.floor, SokobanCell.wall],
      [SokobanCell.wall, SokobanCell.target, SokobanCell.target, SokobanCell.floor, SokobanCell.floor, SokobanCell.wall],
      [SokobanCell.wall, SokobanCell.wall, SokobanCell.wall, SokobanCell.wall, SokobanCell.wall, SokobanCell.wall],
    ];
    return SokobanPuzzle(
      rows: 6,
      cols: 6,
      map: map,
      targetPositions: [(4, 1), (4, 2)],
      playerRow: 1,
      playerCol: 1,
      boxPositions: [(2, 2), (3, 3)],
    );
  }

  /// Hard - 3 boxes, more complex layout
  static SokobanPuzzle sampleLevel3() {
    // 7x7 level with 3 boxes
    // #######
    // #.....#
    // #.P...#
    // #.B.B.#
    // #..B..#
    // #TTT..#
    // #######
    final map = [
      [SokobanCell.wall, SokobanCell.wall, SokobanCell.wall, SokobanCell.wall, SokobanCell.wall, SokobanCell.wall, SokobanCell.wall],
      [SokobanCell.wall, SokobanCell.floor, SokobanCell.floor, SokobanCell.floor, SokobanCell.floor, SokobanCell.floor, SokobanCell.wall],
      [SokobanCell.wall, SokobanCell.floor, SokobanCell.floor, SokobanCell.floor, SokobanCell.floor, SokobanCell.floor, SokobanCell.wall],
      [SokobanCell.wall, SokobanCell.floor, SokobanCell.floor, SokobanCell.floor, SokobanCell.floor, SokobanCell.floor, SokobanCell.wall],
      [SokobanCell.wall, SokobanCell.floor, SokobanCell.floor, SokobanCell.floor, SokobanCell.floor, SokobanCell.floor, SokobanCell.wall],
      [SokobanCell.wall, SokobanCell.target, SokobanCell.target, SokobanCell.target, SokobanCell.floor, SokobanCell.floor, SokobanCell.wall],
      [SokobanCell.wall, SokobanCell.wall, SokobanCell.wall, SokobanCell.wall, SokobanCell.wall, SokobanCell.wall, SokobanCell.wall],
    ];
    return SokobanPuzzle(
      rows: 7,
      cols: 7,
      map: map,
      targetPositions: [(5, 1), (5, 2), (5, 3)],
      playerRow: 2,
      playerCol: 2,
      boxPositions: [(3, 2), (3, 4), (4, 3)],
    );
  }
}

// ============================================================================
// KAKURO PUZZLE
// ============================================================================

/// Cell type for Kakuro grid
enum KakuroCellType { blocked, clue, entry }

/// A clue cell in Kakuro (shows sums for across/down)
class KakuroClue {
  final int? acrossSum; // Sum for horizontal run (null if no clue)
  final int? downSum; // Sum for vertical run (null if no clue)

  const KakuroClue({this.acrossSum, this.downSum});
}

/// Kakuro puzzle - fill grid so runs sum to clues, no repeated digits
class KakuroPuzzle {
  final int rows;
  final int cols;

  // Grid layout: each cell is either blocked, a clue cell, or an entry cell
  final List<List<KakuroCellType>> cellTypes;

  // Clue data for clue cells (row, col) -> KakuroClue
  final Map<(int, int), KakuroClue> clues;

  // Current entries (0 = empty, 1-9 = filled)
  List<List<int>> entries;

  // Solution for validation
  final List<List<int>> solution;

  KakuroPuzzle({
    required this.rows,
    required this.cols,
    required this.cellTypes,
    required this.clues,
    required this.solution,
    List<List<int>>? entries,
  }) : entries = entries ?? List.generate(rows, (_) => List.generate(cols, (_) => 0));

  /// Check if a cell is an entry cell
  bool isEntryCell(int row, int col) {
    if (row < 0 || row >= rows || col < 0 || col >= cols) return false;
    return cellTypes[row][col] == KakuroCellType.entry;
  }

  /// Set a value in an entry cell
  void setEntry(int row, int col, int value) {
    if (!isEntryCell(row, col)) return;
    if (value < 0 || value > 9) return;
    entries[row][col] = value;
  }

  /// Clear an entry cell
  void clearEntry(int row, int col) {
    if (!isEntryCell(row, col)) return;
    entries[row][col] = 0;
  }

  /// Get all cells in the horizontal run containing (row, col)
  List<(int, int)> getHorizontalRun(int row, int col) {
    if (!isEntryCell(row, col)) return [];

    final cells = <(int, int)>[];

    // Find start of run (move left until we hit a non-entry cell)
    int startCol = col;
    while (startCol > 0 && isEntryCell(row, startCol - 1)) {
      startCol--;
    }

    // Collect all cells in run
    int c = startCol;
    while (c < cols && isEntryCell(row, c)) {
      cells.add((row, c));
      c++;
    }

    return cells;
  }

  /// Get all cells in the vertical run containing (row, col)
  List<(int, int)> getVerticalRun(int row, int col) {
    if (!isEntryCell(row, col)) return [];

    final cells = <(int, int)>[];

    // Find start of run (move up until we hit a non-entry cell)
    int startRow = row;
    while (startRow > 0 && isEntryCell(startRow - 1, col)) {
      startRow--;
    }

    // Collect all cells in run
    int r = startRow;
    while (r < rows && isEntryCell(r, col)) {
      cells.add((r, col));
      r++;
    }

    return cells;
  }

  /// Check if there are duplicate values in a run
  bool hasDuplicatesInRun(List<(int, int)> cells) {
    final values = <int>{};
    for (final cell in cells) {
      final value = entries[cell.$1][cell.$2];
      if (value != 0) {
        if (values.contains(value)) return true;
        values.add(value);
      }
    }
    return false;
  }

  /// Get the sum of values in a run (excluding empty cells)
  int getRunSum(List<(int, int)> cells) {
    int sum = 0;
    for (final cell in cells) {
      sum += entries[cell.$1][cell.$2];
    }
    return sum;
  }

  /// Check if a run is complete (all cells filled, correct sum, no duplicates)
  bool isRunComplete(List<(int, int)> cells, int targetSum) {
    if (cells.any((cell) => entries[cell.$1][cell.$2] == 0)) return false;
    if (hasDuplicatesInRun(cells)) return false;
    return getRunSum(cells) == targetSum;
  }

  /// Check if the puzzle is complete and correct
  bool get isComplete {
    // Check that all entries match solution
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (isEntryCell(r, c)) {
          if (entries[r][c] != solution[r][c]) return false;
        }
      }
    }
    return true;
  }

  /// Check if a cell has an error (duplicate in run or wrong value)
  bool hasError(int row, int col) {
    if (!isEntryCell(row, col)) return false;
    if (entries[row][col] == 0) return false;

    // Check for duplicates in horizontal run
    final hRun = getHorizontalRun(row, col);
    if (hasDuplicatesInRun(hRun)) return true;

    // Check for duplicates in vertical run
    final vRun = getVerticalRun(row, col);
    if (hasDuplicatesInRun(vRun)) return true;

    return false;
  }

  /// Reset all entries
  void reset() {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        entries[r][c] = 0;
      }
    }
  }

  // ======================================
  // SAMPLE LEVELS
  // ======================================

  /// Easy - small 4x4 puzzle
  static KakuroPuzzle sampleLevel1() {
    // Simple 4x4 Kakuro
    // B = blocked, C = clue, E = entry
    // Layout:
    // B  C  C  B
    // C  E  E  B
    // C  E  E  B
    // B  B  B  B
    final cellTypes = [
      [KakuroCellType.blocked, KakuroCellType.clue, KakuroCellType.clue, KakuroCellType.blocked],
      [KakuroCellType.clue, KakuroCellType.entry, KakuroCellType.entry, KakuroCellType.blocked],
      [KakuroCellType.clue, KakuroCellType.entry, KakuroCellType.entry, KakuroCellType.blocked],
      [KakuroCellType.blocked, KakuroCellType.blocked, KakuroCellType.blocked, KakuroCellType.blocked],
    ];

    final clues = <(int, int), KakuroClue>{
      (0, 1): const KakuroClue(downSum: 4), // 1+3
      (0, 2): const KakuroClue(downSum: 6), // 2+4
      (1, 0): const KakuroClue(acrossSum: 3), // 1+2
      (2, 0): const KakuroClue(acrossSum: 7), // 3+4
    };

    final solution = [
      [0, 0, 0, 0],
      [0, 1, 2, 0],
      [0, 3, 4, 0],
      [0, 0, 0, 0],
    ];

    return KakuroPuzzle(
      rows: 4,
      cols: 4,
      cellTypes: cellTypes,
      clues: clues,
      solution: solution,
    );
  }

  /// Medium - 5x5 puzzle
  static KakuroPuzzle sampleLevel2() {
    final cellTypes = [
      [KakuroCellType.blocked, KakuroCellType.clue, KakuroCellType.clue, KakuroCellType.clue, KakuroCellType.blocked],
      [KakuroCellType.clue, KakuroCellType.entry, KakuroCellType.entry, KakuroCellType.entry, KakuroCellType.blocked],
      [KakuroCellType.clue, KakuroCellType.entry, KakuroCellType.entry, KakuroCellType.entry, KakuroCellType.clue],
      [KakuroCellType.blocked, KakuroCellType.clue, KakuroCellType.entry, KakuroCellType.entry, KakuroCellType.entry],
      [KakuroCellType.blocked, KakuroCellType.blocked, KakuroCellType.blocked, KakuroCellType.blocked, KakuroCellType.blocked],
    ];

    final clues = <(int, int), KakuroClue>{
      (0, 1): const KakuroClue(downSum: 4), // 1+3
      (0, 2): const KakuroClue(downSum: 11), // 2+4+5
      (0, 3): const KakuroClue(downSum: 10), // 6+4
      (1, 0): const KakuroClue(acrossSum: 9), // 1+2+6
      (2, 0): const KakuroClue(acrossSum: 12), // 3+4+5
      (2, 4): const KakuroClue(downSum: 11), // 4+7
      (3, 1): const KakuroClue(acrossSum: 16), // 5+4+7
    };

    final solution = [
      [0, 0, 0, 0, 0],
      [0, 1, 2, 6, 0],
      [0, 3, 4, 5, 0],
      [0, 0, 5, 4, 7],
      [0, 0, 0, 0, 0],
    ];

    return KakuroPuzzle(
      rows: 5,
      cols: 5,
      cellTypes: cellTypes,
      clues: clues,
      solution: solution,
    );
  }

  /// Hard - 6x6 puzzle
  static KakuroPuzzle sampleLevel3() {
    final cellTypes = [
      [KakuroCellType.blocked, KakuroCellType.clue, KakuroCellType.clue, KakuroCellType.blocked, KakuroCellType.clue, KakuroCellType.clue],
      [KakuroCellType.clue, KakuroCellType.entry, KakuroCellType.entry, KakuroCellType.clue, KakuroCellType.entry, KakuroCellType.entry],
      [KakuroCellType.clue, KakuroCellType.entry, KakuroCellType.entry, KakuroCellType.entry, KakuroCellType.entry, KakuroCellType.entry],
      [KakuroCellType.blocked, KakuroCellType.clue, KakuroCellType.entry, KakuroCellType.entry, KakuroCellType.entry, KakuroCellType.blocked],
      [KakuroCellType.clue, KakuroCellType.entry, KakuroCellType.entry, KakuroCellType.blocked, KakuroCellType.blocked, KakuroCellType.blocked],
      [KakuroCellType.clue, KakuroCellType.entry, KakuroCellType.entry, KakuroCellType.blocked, KakuroCellType.blocked, KakuroCellType.blocked],
    ];

    final clues = <(int, int), KakuroClue>{
      (0, 1): const KakuroClue(downSum: 11), // 2+3+6
      (0, 2): const KakuroClue(downSum: 17), // 1+4+5+7
      (0, 4): const KakuroClue(downSum: 4), // 1+3
      (0, 5): const KakuroClue(downSum: 10), // 2+8
      (1, 0): const KakuroClue(acrossSum: 3), // 2+1
      (1, 3): const KakuroClue(acrossSum: 3, downSum: 12), // across: 1+2, down: 5+7
      (2, 0): const KakuroClue(acrossSum: 23), // 3+4+5+3+8
      (3, 1): const KakuroClue(acrossSum: 19), // 6+5+7+1
      (4, 0): const KakuroClue(acrossSum: 10), // 2+8
      (5, 0): const KakuroClue(acrossSum: 13), // 6+7
    };

    final solution = [
      [0, 0, 0, 0, 0, 0],
      [0, 2, 1, 0, 1, 2],
      [0, 3, 4, 5, 3, 8],
      [0, 0, 5, 7, 1, 0],
      [0, 2, 8, 0, 0, 0],
      [0, 6, 7, 0, 0, 0],
    ];

    return KakuroPuzzle(
      rows: 6,
      cols: 6,
      cellTypes: cellTypes,
      clues: clues,
      solution: solution,
    );
  }
}

// =============================================================================
// HITORI PUZZLE MODEL
// =============================================================================

/// Hitori puzzle - shade cells so no number repeats in rows/columns
/// Rules:
/// 1. Shade cells so no number appears more than once in any row or column
/// 2. Shaded cells cannot be adjacent (horizontally or vertically)
/// 3. Unshaded cells must all be connected orthogonally
class HitoriPuzzle {
  final int size;
  final List<List<int>> numbers;
  final List<List<bool>> shaded;
  final List<List<bool>> solution; // Which cells should be shaded

  HitoriPuzzle({
    required this.size,
    required this.numbers,
    List<List<bool>>? shaded,
    required this.solution,
  }) : shaded = shaded ?? List.generate(size, (_) => List.filled(size, false));

  /// Toggle shading of a cell
  void toggleShade(int row, int col) {
    shaded[row][col] = !shaded[row][col];
  }

  /// Check if a cell is shaded
  bool isShaded(int row, int col) => shaded[row][col];

  /// Check if the current state has adjacent shaded cells (rule violation)
  bool hasAdjacentShaded() {
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        if (shaded[row][col]) {
          // Check right
          if (col + 1 < size && shaded[row][col + 1]) return true;
          // Check down
          if (row + 1 < size && shaded[row + 1][col]) return true;
        }
      }
    }
    return false;
  }

  /// Check if a specific cell has an adjacent shaded cell
  bool hasCellAdjacentShaded(int row, int col) {
    if (!shaded[row][col]) return false;

    // Check all four directions
    if (row > 0 && shaded[row - 1][col]) return true;
    if (row < size - 1 && shaded[row + 1][col]) return true;
    if (col > 0 && shaded[row][col - 1]) return true;
    if (col < size - 1 && shaded[row][col + 1]) return true;

    return false;
  }

  /// Check if unshaded cells are all connected
  bool areUnshadedConnected() {
    // Find first unshaded cell
    int startRow = -1, startCol = -1;
    for (int row = 0; row < size && startRow == -1; row++) {
      for (int col = 0; col < size; col++) {
        if (!shaded[row][col]) {
          startRow = row;
          startCol = col;
          break;
        }
      }
    }

    if (startRow == -1) return true; // All shaded (shouldn't happen)

    // BFS to find all connected unshaded cells
    final visited = List.generate(size, (_) => List.filled(size, false));
    final queue = <(int, int)>[(startRow, startCol)];
    visited[startRow][startCol] = true;
    int unshadedCount = 1;

    while (queue.isNotEmpty) {
      final (row, col) = queue.removeAt(0);

      // Check all four directions
      for (final (dr, dc) in [(0, 1), (0, -1), (1, 0), (-1, 0)]) {
        final newRow = row + dr;
        final newCol = col + dc;

        if (newRow >= 0 && newRow < size &&
            newCol >= 0 && newCol < size &&
            !visited[newRow][newCol] &&
            !shaded[newRow][newCol]) {
          visited[newRow][newCol] = true;
          queue.add((newRow, newCol));
          unshadedCount++;
        }
      }
    }

    // Count total unshaded cells
    int totalUnshaded = 0;
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        if (!shaded[row][col]) totalUnshaded++;
      }
    }

    return unshadedCount == totalUnshaded;
  }

  /// Check if there are duplicate numbers in any row/column among unshaded cells
  bool hasDuplicates() {
    // Check rows
    for (int row = 0; row < size; row++) {
      final seen = <int>{};
      for (int col = 0; col < size; col++) {
        if (!shaded[row][col]) {
          if (seen.contains(numbers[row][col])) return true;
          seen.add(numbers[row][col]);
        }
      }
    }

    // Check columns
    for (int col = 0; col < size; col++) {
      final seen = <int>{};
      for (int row = 0; row < size; row++) {
        if (!shaded[row][col]) {
          if (seen.contains(numbers[row][col])) return true;
          seen.add(numbers[row][col]);
        }
      }
    }

    return false;
  }

  /// Check if a specific cell causes a duplicate in its row or column
  bool cellCausesDuplicate(int checkRow, int checkCol) {
    if (shaded[checkRow][checkCol]) return false;

    final num = numbers[checkRow][checkCol];

    // Check row
    for (int col = 0; col < size; col++) {
      if (col != checkCol && !shaded[checkRow][col] && numbers[checkRow][col] == num) {
        return true;
      }
    }

    // Check column
    for (int row = 0; row < size; row++) {
      if (row != checkRow && !shaded[row][checkCol] && numbers[row][checkCol] == num) {
        return true;
      }
    }

    return false;
  }

  /// Check if the puzzle is complete and valid
  bool get isComplete {
    // No duplicates in rows/columns
    if (hasDuplicates()) return false;
    // No adjacent shaded cells
    if (hasAdjacentShaded()) return false;
    // Unshaded cells are connected
    if (!areUnshadedConnected()) return false;

    return true;
  }

  /// Reset puzzle to initial state
  void reset() {
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        shaded[row][col] = false;
      }
    }
  }

  /// Sample level 1: 5x5 Easy
  factory HitoriPuzzle.sampleLevel1() {
    final numbers = [
      [2, 5, 1, 3, 4],
      [1, 3, 4, 5, 2],
      [4, 1, 3, 2, 5],
      [3, 4, 2, 1, 3],
      [5, 2, 5, 4, 1],
    ];

    final solution = [
      [false, false, false, false, false],
      [false, false, false, false, false],
      [false, false, false, false, false],
      [false, false, false, false, true],
      [false, false, true, false, false],
    ];

    return HitoriPuzzle(
      size: 5,
      numbers: numbers,
      solution: solution,
    );
  }

  /// Sample level 2: 6x6 Medium
  factory HitoriPuzzle.sampleLevel2() {
    final numbers = [
      [3, 2, 1, 4, 5, 6],
      [6, 3, 2, 5, 4, 1],
      [1, 4, 5, 6, 2, 3],
      [2, 6, 4, 1, 3, 5],
      [4, 5, 3, 2, 6, 4],
      [5, 1, 6, 3, 4, 2],
    ];

    final solution = [
      [false, false, false, false, false, false],
      [false, false, false, false, false, false],
      [false, false, false, false, false, false],
      [false, false, false, false, false, false],
      [false, false, false, false, false, true],
      [false, false, false, false, true, false],
    ];

    return HitoriPuzzle(
      size: 6,
      numbers: numbers,
      solution: solution,
    );
  }

  /// Sample level 3: 6x6 with more shading needed
  factory HitoriPuzzle.sampleLevel3() {
    final numbers = [
      [1, 2, 3, 4, 5, 6],
      [2, 1, 4, 3, 6, 5],
      [3, 4, 1, 6, 2, 3],
      [4, 3, 6, 1, 4, 2],
      [5, 6, 2, 5, 3, 1],
      [6, 5, 5, 2, 1, 4],
    ];

    final solution = [
      [false, false, false, false, false, false],
      [false, false, false, false, false, false],
      [false, false, false, false, false, true],
      [false, false, false, false, true, false],
      [false, false, false, true, false, false],
      [false, false, true, false, false, false],
    ];

    return HitoriPuzzle(
      size: 6,
      numbers: numbers,
      solution: solution,
    );
  }
}

// =============================================================================
// TANGRAM PUZZLE MODEL
// =============================================================================

/// Type of tangram piece
enum TangramPieceType {
  largeTriangle1,
  largeTriangle2,
  mediumTriangle,
  smallTriangle1,
  smallTriangle2,
  square,
  parallelogram,
}

/// A tangram piece with position, rotation, and flip state
class TangramPiece {
  final TangramPieceType type;
  double x;
  double y;
  double rotation; // In degrees (0, 45, 90, 135, 180, 225, 270, 315)
  bool isFlipped; // For parallelogram

  TangramPiece({
    required this.type,
    this.x = 0,
    this.y = 0,
    this.rotation = 0,
    this.isFlipped = false,
  });

  /// Rotate piece by 45 degrees
  void rotate() {
    rotation = (rotation + 45) % 360;
  }

  /// Flip piece (only matters for parallelogram)
  void flip() {
    isFlipped = !isFlipped;
  }

  /// Get the color for this piece type
  int get colorValue {
    switch (type) {
      case TangramPieceType.largeTriangle1:
        return 0xFFE74C3C; // Red
      case TangramPieceType.largeTriangle2:
        return 0xFF3498DB; // Blue
      case TangramPieceType.mediumTriangle:
        return 0xFFF39C12; // Orange
      case TangramPieceType.smallTriangle1:
        return 0xFF2ECC71; // Green
      case TangramPieceType.smallTriangle2:
        return 0xFF9B59B6; // Purple
      case TangramPieceType.square:
        return 0xFF1ABC9C; // Teal
      case TangramPieceType.parallelogram:
        return 0xFFE91E63; // Pink
    }
  }

  /// Get relative size (unit = small triangle leg)
  double get scale {
    switch (type) {
      case TangramPieceType.largeTriangle1:
      case TangramPieceType.largeTriangle2:
        return 2.0;
      case TangramPieceType.mediumTriangle:
        return 1.414; // sqrt(2)
      case TangramPieceType.smallTriangle1:
      case TangramPieceType.smallTriangle2:
        return 1.0;
      case TangramPieceType.square:
        return 1.0;
      case TangramPieceType.parallelogram:
        return 1.0;
    }
  }

  TangramPiece copy() {
    return TangramPiece(
      type: type,
      x: x,
      y: y,
      rotation: rotation,
      isFlipped: isFlipped,
    );
  }
}

/// Target silhouette for a tangram puzzle
class TangramTarget {
  final String name;
  final List<List<double>> vertices; // Polygon vertices normalized to unit square

  const TangramTarget({
    required this.name,
    required this.vertices,
  });
}

/// Tangram puzzle - arrange pieces to form a shape
class TangramPuzzle {
  final String name;
  final TangramTarget target;
  final List<TangramPiece> pieces;
  TangramPiece? selectedPiece;

  TangramPuzzle({
    required this.name,
    required this.target,
    required this.pieces,
  });

  /// Select a piece
  void selectPiece(TangramPiece piece) {
    selectedPiece = piece;
  }

  /// Deselect current piece
  void deselectPiece() {
    selectedPiece = null;
  }

  /// Move piece to position
  void movePiece(TangramPiece piece, double x, double y) {
    piece.x = x;
    piece.y = y;
  }

  /// Rotate selected piece
  void rotateSelectedPiece() {
    selectedPiece?.rotate();
  }

  /// Flip selected piece
  void flipSelectedPiece() {
    selectedPiece?.flip();
  }

  /// Simplified completion check - all pieces inside target bounds
  bool get isComplete {
    // For prototype, just check if all pieces are positioned (moved from initial spot)
    for (final piece in pieces) {
      if (piece.x < 0.1 && piece.y < 0.1) {
        return false; // Piece hasn't been moved
      }
    }
    return true;
  }

  /// Reset all pieces to starting positions
  void reset() {
    double offsetY = 0;
    for (final piece in pieces) {
      piece.x = 0;
      piece.y = offsetY;
      piece.rotation = 0;
      piece.isFlipped = false;
      offsetY += 60;
    }
    selectedPiece = null;
  }

  /// Sample level 1: Square (easiest tangram)
  factory TangramPuzzle.sampleLevel1() {
    return TangramPuzzle(
      name: 'Square',
      target: const TangramTarget(
        name: 'Square',
        vertices: [
          [0, 0],
          [200, 0],
          [200, 200],
          [0, 200],
        ],
      ),
      pieces: _createDefaultPieces(),
    );
  }

  /// Sample level 2: House
  factory TangramPuzzle.sampleLevel2() {
    return TangramPuzzle(
      name: 'House',
      target: const TangramTarget(
        name: 'House',
        vertices: [
          [100, 0],
          [200, 80],
          [200, 200],
          [0, 200],
          [0, 80],
        ],
      ),
      pieces: _createDefaultPieces(),
    );
  }

  /// Sample level 3: Cat
  factory TangramPuzzle.sampleLevel3() {
    return TangramPuzzle(
      name: 'Cat',
      target: const TangramTarget(
        name: 'Cat',
        vertices: [
          [40, 0],
          [80, 40],
          [120, 0],
          [160, 40],
          [160, 120],
          [200, 200],
          [120, 180],
          [80, 200],
          [0, 200],
          [40, 120],
        ],
      ),
      pieces: _createDefaultPieces(),
    );
  }

  static List<TangramPiece> _createDefaultPieces() {
    return [
      TangramPiece(type: TangramPieceType.largeTriangle1, x: 0, y: 0),
      TangramPiece(type: TangramPieceType.largeTriangle2, x: 0, y: 70),
      TangramPiece(type: TangramPieceType.mediumTriangle, x: 0, y: 140),
      TangramPiece(type: TangramPieceType.smallTriangle1, x: 0, y: 210),
      TangramPiece(type: TangramPieceType.smallTriangle2, x: 0, y: 260),
      TangramPiece(type: TangramPieceType.square, x: 0, y: 310),
      TangramPiece(type: TangramPieceType.parallelogram, x: 0, y: 360),
    ];
  }
}
