import 'package:flutter/material.dart';
import '../models/game_models.dart';

class GameProvider extends ChangeNotifier {
  DailyPuzzle? _currentPuzzle;
  int _elapsedSeconds = 0;
  bool _isPlaying = false;
  int _mistakes = 0;
  int _hintsUsed = 0;
  
  // Sudoku specific state
  int? _selectedRow;
  int? _selectedCol;
  bool _notesMode = false;
  SudokuPuzzle? _sudokuPuzzle;
  KillerSudokuPuzzle? _killerSudokuPuzzle;
  
  // Crossword specific state
  CrosswordPuzzle? _crosswordPuzzle;
  CrosswordClue? _selectedClue;
  
  // Word Search specific state
  WordSearchPuzzle? _wordSearchPuzzle;
  List<List<int>>? _currentSelection;

  // Word Forge specific state
  WordForgePuzzle? _wordForgePuzzle;
  String _currentWord = '';

  // Nonogram specific state
  NonogramPuzzle? _nonogramPuzzle;
  bool _nonogramMarkMode = false; // false = fill, true = mark X

  // Number Target specific state
  NumberTargetPuzzle? _numberTargetPuzzle;
  String _currentExpression = '';

  // Getters
  DailyPuzzle? get currentPuzzle => _currentPuzzle;
  int get elapsedSeconds => _elapsedSeconds;
  bool get isPlaying => _isPlaying;
  int get mistakes => _mistakes;
  int get hintsUsed => _hintsUsed;
  
  int? get selectedRow => _selectedRow;
  int? get selectedCol => _selectedCol;
  bool get notesMode => _notesMode;
  SudokuPuzzle? get sudokuPuzzle => _sudokuPuzzle;
  KillerSudokuPuzzle? get killerSudokuPuzzle => _killerSudokuPuzzle;
  
  CrosswordPuzzle? get crosswordPuzzle => _crosswordPuzzle;
  CrosswordClue? get selectedClue => _selectedClue;
  
  WordSearchPuzzle? get wordSearchPuzzle => _wordSearchPuzzle;
  List<List<int>>? get currentSelection => _currentSelection;

  WordForgePuzzle? get wordForgePuzzle => _wordForgePuzzle;
  String get currentWord => _currentWord;

  NonogramPuzzle? get nonogramPuzzle => _nonogramPuzzle;
  bool get nonogramMarkMode => _nonogramMarkMode;

  NumberTargetPuzzle? get numberTargetPuzzle => _numberTargetPuzzle;
  String get currentExpression => _currentExpression;

  void loadPuzzle(DailyPuzzle puzzle) {
    _currentPuzzle = puzzle;
    _elapsedSeconds = 0;
    _mistakes = 0;
    _hintsUsed = 0;
    _isPlaying = true;
    _selectedRow = null;
    _selectedCol = null;
    _notesMode = false;
    _currentSelection = null;
    _currentWord = '';
    _currentExpression = '';
    _nonogramMarkMode = false;

    // Clear all puzzle-specific state
    _sudokuPuzzle = null;
    _killerSudokuPuzzle = null;
    _crosswordPuzzle = null;
    _wordSearchPuzzle = null;
    _wordForgePuzzle = null;
    _nonogramPuzzle = null;
    _numberTargetPuzzle = null;

    // Merge puzzleData with solution for models that need it
    final puzzleDataWithSolution = {
      ...(puzzle.puzzleData as Map<String, dynamic>),
      if (puzzle.solution != null) 'solution': puzzle.solution,
    };

    switch (puzzle.gameType) {
      case GameType.sudoku:
        _sudokuPuzzle = SudokuPuzzle.fromJson(puzzleDataWithSolution);
        break;
      case GameType.killerSudoku:
        _killerSudokuPuzzle = KillerSudokuPuzzle.fromJson(puzzleDataWithSolution);
        break;
      case GameType.crossword:
        _crosswordPuzzle = CrosswordPuzzle.fromJson(puzzle.puzzleData as Map<String, dynamic>);
        break;
      case GameType.wordSearch:
        _wordSearchPuzzle = WordSearchPuzzle.fromJson(puzzle.puzzleData as Map<String, dynamic>);
        break;
      case GameType.wordForge:
        _wordForgePuzzle = WordForgePuzzle.fromJson(puzzleDataWithSolution);
        break;
      case GameType.nonogram:
        _nonogramPuzzle = NonogramPuzzle.fromJson(puzzleDataWithSolution);
        break;
      case GameType.numberTarget:
        _numberTargetPuzzle = NumberTargetPuzzle.fromJson(puzzleDataWithSolution);
        break;
    }

    notifyListeners();
  }

  void tick() {
    if (_isPlaying) {
      _elapsedSeconds++;
      notifyListeners();
    }
  }

  void pause() {
    _isPlaying = false;
    notifyListeners();
  }

  void resume() {
    _isPlaying = true;
    notifyListeners();
  }

  // Sudoku methods
  void selectCell(int row, int col) {
    _selectedRow = row;
    _selectedCol = col;
    notifyListeners();
  }

  void clearSelection() {
    _selectedRow = null;
    _selectedCol = null;
    notifyListeners();
  }

  void toggleNotesMode() {
    _notesMode = !_notesMode;
    notifyListeners();
  }

  /// Enter a number in the selected cell
  /// Returns: true if valid, false if invalid, null if notes mode or no action taken
  bool? enterNumber(int number) {
    if (_selectedRow == null || _selectedCol == null) return null;

    final puzzle = _sudokuPuzzle ?? _killerSudokuPuzzle;
    if (puzzle == null) return null;

    // Can't modify initial cells
    if (puzzle.initialGrid[_selectedRow!][_selectedCol!] != null) return null;

    if (_notesMode) {
      final notes = puzzle.notes[_selectedRow!][_selectedCol!];
      if (notes.contains(number)) {
        notes.remove(number);
      } else {
        notes.add(number);
      }
      notifyListeners();
      return null; // Notes mode, no right/wrong
    } else {
      // Check if valid
      final isValid = puzzle.isValidPlacement(_selectedRow!, _selectedCol!, number);
      if (!isValid) {
        _mistakes++;
      }
      puzzle.grid[_selectedRow!][_selectedCol!] = number;
      puzzle.notes[_selectedRow!][_selectedCol!].clear();
      notifyListeners();
      return isValid;
    }
  }

  void clearCell() {
    if (_selectedRow == null || _selectedCol == null) return;
    
    final puzzle = _sudokuPuzzle ?? _killerSudokuPuzzle;
    if (puzzle == null) return;
    
    if (puzzle.initialGrid[_selectedRow!][_selectedCol!] != null) return;
    
    puzzle.grid[_selectedRow!][_selectedCol!] = null;
    puzzle.notes[_selectedRow!][_selectedCol!].clear();
    notifyListeners();
  }

  void useHint() {
    if (_selectedRow == null || _selectedCol == null) return;
    
    final puzzle = _sudokuPuzzle ?? _killerSudokuPuzzle;
    if (puzzle == null) return;
    
    if (puzzle.initialGrid[_selectedRow!][_selectedCol!] != null) return;
    
    puzzle.grid[_selectedRow!][_selectedCol!] = puzzle.solution[_selectedRow!][_selectedCol!];
    puzzle.notes[_selectedRow!][_selectedCol!].clear();
    _hintsUsed++;
    notifyListeners();
  }

  bool checkSudokuComplete() {
    final puzzle = _sudokuPuzzle ?? _killerSudokuPuzzle;
    if (puzzle == null) return false;
    
    if (puzzle.isComplete) {
      _isPlaying = false;
      notifyListeners();
      return true;
    }
    return false;
  }

  // Crossword methods
  void selectClue(CrosswordClue clue) {
    _selectedClue = clue;
    // Move to the first empty cell in the clue, or the start if all filled
    _moveToFirstEmptyInClue(clue);
    notifyListeners();
  }

  /// Select a cell in the crossword grid
  /// If the cell belongs to multiple clues (intersection), tapping again toggles direction
  void selectCrosswordCell(int row, int col) {
    if (_crosswordPuzzle == null) return;

    // Can't select black cells
    if (_crosswordPuzzle!.grid[row][col] == null) return;

    // Find clues that contain this cell
    final cluesAtCell = _getCluesAtCell(row, col);

    if (cluesAtCell.isEmpty) return;

    // If tapping the same cell, toggle between across/down
    if (_selectedRow == row && _selectedCol == col && cluesAtCell.length > 1) {
      // Find current direction and switch
      final currentDirection = _selectedClue?.direction;
      final otherClue = cluesAtCell.firstWhere(
        (c) => c.direction != currentDirection,
        orElse: () => cluesAtCell.first,
      );
      _selectedClue = otherClue;
    } else {
      // New cell - prefer across, or use whatever is available
      _selectedClue = cluesAtCell.firstWhere(
        (c) => c.direction == 'across',
        orElse: () => cluesAtCell.first,
      );
    }

    _selectedRow = row;
    _selectedCol = col;
    notifyListeners();
  }

  /// Get all clues that contain a specific cell
  List<CrosswordClue> _getCluesAtCell(int row, int col) {
    if (_crosswordPuzzle == null) return [];

    return _crosswordPuzzle!.clues.where((clue) {
      if (clue.direction == 'across') {
        return row == clue.startRow &&
            col >= clue.startCol &&
            col < clue.startCol + clue.length;
      } else {
        return col == clue.startCol &&
            row >= clue.startRow &&
            row < clue.startRow + clue.length;
      }
    }).toList();
  }

  /// Move cursor to first empty cell in the given clue
  void _moveToFirstEmptyInClue(CrosswordClue clue) {
    if (_crosswordPuzzle == null) return;

    for (int i = 0; i < clue.length; i++) {
      final r = clue.direction == 'across' ? clue.startRow : clue.startRow + i;
      final c = clue.direction == 'across' ? clue.startCol + i : clue.startCol;

      final userValue = _crosswordPuzzle!.userGrid[r][c];
      if (userValue == null || userValue.isEmpty) {
        _selectedRow = r;
        _selectedCol = c;
        return;
      }
    }

    // All filled, go to start
    _selectedRow = clue.startRow;
    _selectedCol = clue.startCol;
  }

  /// Check if a clue is completely filled (all cells have letters)
  bool _isClueComplete(CrosswordClue clue) {
    if (_crosswordPuzzle == null) return false;

    for (int i = 0; i < clue.length; i++) {
      final r = clue.direction == 'across' ? clue.startRow : clue.startRow + i;
      final c = clue.direction == 'across' ? clue.startCol + i : clue.startCol;

      final userValue = _crosswordPuzzle!.userGrid[r][c];
      if (userValue == null || userValue.isEmpty) {
        return false;
      }
    }
    return true;
  }

  /// Find the next incomplete clue after the current one
  CrosswordClue? _findNextIncompleteClue() {
    if (_crosswordPuzzle == null || _selectedClue == null) return null;

    final allClues = _crosswordPuzzle!.clues;
    final currentIndex = allClues.indexOf(_selectedClue!);

    // Search from after current clue to the end
    for (int i = currentIndex + 1; i < allClues.length; i++) {
      if (!_isClueComplete(allClues[i])) {
        return allClues[i];
      }
    }

    // Wrap around: search from start to current clue
    for (int i = 0; i < currentIndex; i++) {
      if (!_isClueComplete(allClues[i])) {
        return allClues[i];
      }
    }

    // All clues are complete
    return null;
  }

  /// Find next empty cell in current clue direction
  void _moveToNextEmptyInClue() {
    if (_crosswordPuzzle == null || _selectedClue == null ||
        _selectedRow == null || _selectedCol == null) return;

    final clue = _selectedClue!;

    // Get current position index within the clue
    int currentIndex;
    if (clue.direction == 'across') {
      currentIndex = _selectedCol! - clue.startCol;
    } else {
      currentIndex = _selectedRow! - clue.startRow;
    }

    // Search from current position to end of word
    for (int i = currentIndex + 1; i < clue.length; i++) {
      final r = clue.direction == 'across' ? clue.startRow : clue.startRow + i;
      final c = clue.direction == 'across' ? clue.startCol + i : clue.startCol;

      final userValue = _crosswordPuzzle!.userGrid[r][c];
      if (userValue == null || userValue.isEmpty) {
        _selectedRow = r;
        _selectedCol = c;
        return;
      }
    }

    // Current word is complete - move to next incomplete word
    final nextClue = _findNextIncompleteClue();
    if (nextClue != null) {
      _selectedClue = nextClue;
      _moveToFirstEmptyInClue(nextClue);
      return;
    }

    // All words complete - stay at end of current word
    if (clue.direction == 'across') {
      _selectedCol = clue.startCol + clue.length - 1;
    } else {
      _selectedRow = clue.startRow + clue.length - 1;
    }
  }

  void enterLetter(String letter) {
    if (_crosswordPuzzle == null || _selectedRow == null || _selectedCol == null) return;

    if (_crosswordPuzzle!.grid[_selectedRow!][_selectedCol!] == null) return;

    _crosswordPuzzle!.userGrid[_selectedRow!][_selectedCol!] = letter.toUpperCase();

    // Move to next empty cell in the word
    if (_selectedClue != null) {
      _moveToNextEmptyInClue();
    }

    notifyListeners();
  }

  void deleteLetter() {
    if (_crosswordPuzzle == null || _selectedRow == null || _selectedCol == null) return;
    
    _crosswordPuzzle!.userGrid[_selectedRow!][_selectedCol!] = '';
    
    // Move to previous cell
    if (_selectedClue != null) {
      if (_selectedClue!.direction == 'across') {
        if (_selectedCol! > 0 &&
            _crosswordPuzzle!.grid[_selectedRow!][_selectedCol! - 1] != null) {
          _selectedCol = _selectedCol! - 1;
        }
      } else {
        if (_selectedRow! > 0 &&
            _crosswordPuzzle!.grid[_selectedRow! - 1][_selectedCol!] != null) {
          _selectedRow = _selectedRow! - 1;
        }
      }
    }
    
    notifyListeners();
  }

  bool checkCrosswordComplete() {
    if (_crosswordPuzzle == null) return false;
    
    if (_crosswordPuzzle!.isComplete) {
      _isPlaying = false;
      notifyListeners();
      return true;
    }
    return false;
  }

  // Word Search methods
  void startWordSelection(int row, int col) {
    _currentSelection = [[row, col]];
    notifyListeners();
  }

  void extendWordSelection(int row, int col) {
    if (_currentSelection == null || _currentSelection!.isEmpty) return;
    
    final start = _currentSelection!.first;
    final positions = <List<int>>[];
    
    // Calculate direction
    final rowDir = (row - start[0]).sign;
    final colDir = (col - start[1]).sign;
    
    // Only allow straight lines or diagonals
    final rowDiff = (row - start[0]).abs();
    final colDiff = (col - start[1]).abs();
    
    if (rowDiff != colDiff && rowDiff != 0 && colDiff != 0) return;
    
    var currentRow = start[0];
    var currentCol = start[1];
    
    while (true) {
      positions.add([currentRow, currentCol]);
      if (currentRow == row && currentCol == col) break;
      currentRow += rowDir;
      currentCol += colDir;
    }
    
    _currentSelection = positions;
    notifyListeners();
  }

  /// End word selection and check if a word was found
  /// Returns true if a valid word was found, false otherwise
  bool endWordSelection() {
    if (_currentSelection == null || _wordSearchPuzzle == null) {
      _currentSelection = null;
      return false;
    }

    bool wordFound = false;

    // Check if it matches any word
    for (final word in _wordSearchPuzzle!.words) {
      if (!word.found) {
        final wordPositions = word.cellPositions;
        final reversedPositions = wordPositions.reversed.toList();

        bool matches = _listsEqual(_currentSelection!, wordPositions) ||
            _listsEqual(_currentSelection!, reversedPositions);

        if (matches) {
          word.found = true;
          wordFound = true;
          break;
        }
      }
    }

    _currentSelection = null;
    notifyListeners();
    return wordFound;
  }

  bool _listsEqual(List<List<int>> a, List<List<int>> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i][0] != b[i][0] || a[i][1] != b[i][1]) return false;
    }
    return true;
  }

  bool checkWordSearchComplete() {
    if (_wordSearchPuzzle == null) return false;

    if (_wordSearchPuzzle!.isComplete) {
      _isPlaying = false;
      notifyListeners();
      return true;
    }
    return false;
  }

  // Word Forge methods
  void addWordForgeLetter(String letter) {
    _currentWord += letter.toUpperCase();
    notifyListeners();
  }

  void removeWordForgeLetter() {
    if (_currentWord.isNotEmpty) {
      _currentWord = _currentWord.substring(0, _currentWord.length - 1);
      notifyListeners();
    }
  }

  void clearWordForgeWord() {
    _currentWord = '';
    notifyListeners();
  }

  /// Submit the current word. Returns a result object with success status and message.
  WordForgeSubmitResult submitWordForgeWord() {
    if (_wordForgePuzzle == null || _currentWord.isEmpty) {
      return WordForgeSubmitResult(success: false, message: 'Enter a word');
    }

    final word = _currentWord.toUpperCase();

    // Check minimum length
    if (word.length < 4) {
      _currentWord = '';
      notifyListeners();
      return WordForgeSubmitResult(success: false, message: 'Too short');
    }

    // Check if center letter is used
    if (!word.contains(_wordForgePuzzle!.centerLetter)) {
      _currentWord = '';
      notifyListeners();
      return WordForgeSubmitResult(
          success: false, message: 'Missing center letter');
    }

    // Check if only valid letters are used
    for (final char in word.split('')) {
      if (!_wordForgePuzzle!.letters.contains(char)) {
        _currentWord = '';
        notifyListeners();
        return WordForgeSubmitResult(success: false, message: 'Invalid letter');
      }
    }

    // Check if already found
    if (_wordForgePuzzle!.foundWords.contains(word)) {
      _currentWord = '';
      notifyListeners();
      return WordForgeSubmitResult(success: false, message: 'Already found');
    }

    // Check if valid word
    if (!_wordForgePuzzle!.isValidWord(word)) {
      _mistakes++;
      _currentWord = '';
      notifyListeners();
      return WordForgeSubmitResult(success: false, message: 'Not in word list');
    }

    // Valid word!
    _wordForgePuzzle!.foundWords.add(word);
    final isPangram = _wordForgePuzzle!.isPangram(word);
    final points = _wordForgePuzzle!.scoreWord(word);
    _currentWord = '';
    notifyListeners();

    if (isPangram) {
      return WordForgeSubmitResult(
          success: true, message: 'Pangram! +$points', isPangram: true);
    }
    return WordForgeSubmitResult(success: true, message: '+$points');
  }

  void shuffleWordForgeLetters() {
    if (_wordForgePuzzle == null) return;
    _wordForgePuzzle!.shuffleOuterLetters();
    notifyListeners();
  }

  bool checkWordForgeComplete() {
    if (_wordForgePuzzle == null) return false;

    if (_wordForgePuzzle!.isComplete) {
      _isPlaying = false;
      notifyListeners();
      return true;
    }
    return false;
  }

  int getWordForgeScore() {
    return _wordForgePuzzle?.currentScore ?? 0;
  }

  int getWordForgeMaxScore() {
    return _wordForgePuzzle?.maxScore ?? 0;
  }

  // Nonogram methods
  void toggleNonogramMarkMode() {
    _nonogramMarkMode = !_nonogramMarkMode;
    notifyListeners();
  }

  /// Toggle a cell in the nonogram grid.
  /// In fill mode: empty -> filled -> empty
  /// In mark mode: empty -> marked (X) -> empty
  void toggleNonogramCell(int row, int col) {
    if (_nonogramPuzzle == null) return;

    final currentState = _nonogramPuzzle!.userGrid[row][col];

    if (_nonogramMarkMode) {
      // Mark mode: toggle between empty (0) and marked (-1)
      if (currentState == -1) {
        _nonogramPuzzle!.userGrid[row][col] = 0;
      } else {
        _nonogramPuzzle!.userGrid[row][col] = -1;
      }
    } else {
      // Fill mode: toggle between empty (0) and filled (1)
      if (currentState == 1) {
        _nonogramPuzzle!.userGrid[row][col] = 0;
      } else if (currentState == 0) {
        _nonogramPuzzle!.userGrid[row][col] = 1;
      } else {
        // Was marked, now fill
        _nonogramPuzzle!.userGrid[row][col] = 1;
      }
    }

    notifyListeners();
  }

  /// Clear a nonogram cell (set to empty)
  void clearNonogramCell(int row, int col) {
    if (_nonogramPuzzle == null) return;
    _nonogramPuzzle!.userGrid[row][col] = 0;
    notifyListeners();
  }

  bool checkNonogramComplete() {
    if (_nonogramPuzzle == null) return false;

    if (_nonogramPuzzle!.isComplete) {
      _isPlaying = false;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Use hint for nonogram - reveal a random incorrect/empty cell
  void useNonogramHint() {
    if (_nonogramPuzzle == null) return;

    // Find all cells that are wrong or empty but should be filled
    final wrongCells = <List<int>>[];
    for (int r = 0; r < _nonogramPuzzle!.rows; r++) {
      for (int c = 0; c < _nonogramPuzzle!.cols; c++) {
        final userVal = _nonogramPuzzle!.userGrid[r][c];
        final solutionVal = _nonogramPuzzle!.solution[r][c];
        // If solution is 1 (filled) but user doesn't have it filled
        if (solutionVal == 1 && userVal != 1) {
          wrongCells.add([r, c]);
        }
      }
    }

    if (wrongCells.isEmpty) return;

    // Pick a random cell and reveal it
    wrongCells.shuffle();
    final cell = wrongCells.first;
    _nonogramPuzzle!.userGrid[cell[0]][cell[1]] = 1;
    _hintsUsed++;
    notifyListeners();
  }

  // Number Target methods
  void addToNumberTargetExpression(String token) {
    _currentExpression += token;
    notifyListeners();
  }

  void clearNumberTargetExpression() {
    _currentExpression = '';
    notifyListeners();
  }

  void backspaceNumberTargetExpression() {
    if (_currentExpression.isNotEmpty) {
      // Remove last character or last number (if multi-digit)
      // Simple approach: just remove last character
      _currentExpression =
          _currentExpression.substring(0, _currentExpression.length - 1);
      notifyListeners();
    }
  }

  /// Evaluate the current expression and check if it equals the target.
  /// Returns a result object with success status and evaluated value.
  NumberTargetResult evaluateNumberTargetExpression() {
    if (_numberTargetPuzzle == null || _currentExpression.isEmpty) {
      return NumberTargetResult(success: false, message: 'Enter an expression');
    }

    try {
      final result = _numberTargetPuzzle!.evaluateExpression(_currentExpression);
      if (result.isNaN) {
        return NumberTargetResult(success: false, message: 'Invalid expression');
      }

      final target = _numberTargetPuzzle!.target;
      final intResult = result.round();
      if ((result - target).abs() < 0.0001) {
        _numberTargetPuzzle!.userExpression = _currentExpression;
        _isPlaying = false;
        notifyListeners();
        return NumberTargetResult(
            success: true, message: 'Correct!', value: intResult);
      } else {
        _mistakes++;
        notifyListeners();
        return NumberTargetResult(
            success: false,
            message: '= $intResult (target: $target)',
            value: intResult);
      }
    } catch (e) {
      return NumberTargetResult(success: false, message: 'Invalid expression');
    }
  }

  bool checkNumberTargetComplete() {
    if (_numberTargetPuzzle == null) return false;

    if (_numberTargetPuzzle!.isComplete) {
      _isPlaying = false;
      notifyListeners();
      return true;
    }
    return false;
  }

  int calculateScore() {
    if (_currentPuzzle == null) return 0;
    
    final baseScore = 1000;
    final targetTime = _currentPuzzle!.targetTime ?? 600;
    
    // Time bonus/penalty
    double timeMultiplier = 1.0;
    if (_elapsedSeconds < targetTime) {
      timeMultiplier = 1.0 + (targetTime - _elapsedSeconds) / targetTime;
    } else {
      timeMultiplier = 1.0 - ((_elapsedSeconds - targetTime) / targetTime).clamp(0.0, 0.5);
    }
    
    // Mistake penalty
    final mistakePenalty = _mistakes * 50;
    
    // Hint penalty
    final hintPenalty = _hintsUsed * 100;
    
    // Difficulty multiplier
    double difficultyMultiplier = 1.0;
    switch (_currentPuzzle!.difficulty) {
      case Difficulty.easy:
        difficultyMultiplier = 1.0;
        break;
      case Difficulty.medium:
        difficultyMultiplier = 1.5;
        break;
      case Difficulty.hard:
        difficultyMultiplier = 2.0;
        break;
      case Difficulty.expert:
        difficultyMultiplier = 3.0;
        break;
    }
    
    final score = ((baseScore * timeMultiplier * difficultyMultiplier) - mistakePenalty - hintPenalty).round();
    return score.clamp(0, 10000);
  }

  void reset() {
    _currentPuzzle = null;
    _elapsedSeconds = 0;
    _isPlaying = false;
    _mistakes = 0;
    _hintsUsed = 0;
    _selectedRow = null;
    _selectedCol = null;
    _notesMode = false;
    _sudokuPuzzle = null;
    _killerSudokuPuzzle = null;
    _crosswordPuzzle = null;
    _selectedClue = null;
    _wordSearchPuzzle = null;
    _currentSelection = null;
    _wordForgePuzzle = null;
    _currentWord = '';
    _nonogramPuzzle = null;
    _nonogramMarkMode = false;
    _numberTargetPuzzle = null;
    _currentExpression = '';
    notifyListeners();
  }
}

/// Result object for Word Forge word submission
class WordForgeSubmitResult {
  final bool success;
  final String message;
  final bool isPangram;

  WordForgeSubmitResult({
    required this.success,
    required this.message,
    this.isPangram = false,
  });
}

/// Result object for Number Target expression evaluation
class NumberTargetResult {
  final bool success;
  final String message;
  final int? value;

  NumberTargetResult({
    required this.success,
    required this.message,
    this.value,
  });
}
