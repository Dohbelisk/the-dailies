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
    _selectedRow = clue.startRow;
    _selectedCol = clue.startCol;
    notifyListeners();
  }

  void enterLetter(String letter) {
    if (_crosswordPuzzle == null || _selectedRow == null || _selectedCol == null) return;
    
    if (_crosswordPuzzle!.grid[_selectedRow!][_selectedCol!] == null) return;
    
    _crosswordPuzzle!.userGrid[_selectedRow!][_selectedCol!] = letter.toUpperCase();
    
    // Move to next cell
    if (_selectedClue != null) {
      if (_selectedClue!.direction == 'across') {
        if (_selectedCol! < _crosswordPuzzle!.cols - 1 &&
            _crosswordPuzzle!.grid[_selectedRow!][_selectedCol! + 1] != null) {
          _selectedCol = _selectedCol! + 1;
        }
      } else {
        if (_selectedRow! < _crosswordPuzzle!.rows - 1 &&
            _crosswordPuzzle!.grid[_selectedRow! + 1][_selectedCol!] != null) {
          _selectedRow = _selectedRow! + 1;
        }
      }
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
    notifyListeners();
  }
}
