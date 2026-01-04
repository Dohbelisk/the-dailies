import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../services/game_state_service.dart';
import '../services/dictionary_service.dart';

class GameProvider extends ChangeNotifier {
  DateTime? _currentPuzzleDate;
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
  List<List<List<int>>> _nonogramUndoHistory = []; // Stack of grid states for undo

  // Number Target specific state
  NumberTargetPuzzle? _numberTargetPuzzle;
  String _currentExpression = '';

  // Ball Sort specific state
  BallSortPuzzle? _ballSortPuzzle;
  int? _selectedTube;
  int _undosRemaining = 5;

  // Pipes specific state
  PipesPuzzle? _pipesPuzzle;

  // Lights Out specific state
  LightsOutPuzzle? _lightsOutPuzzle;

  // Word Ladder specific state
  WordLadderPuzzle? _wordLadderPuzzle;
  String _wordLadderInput = '';

  // Connections specific state
  ConnectionsPuzzle? _connectionsPuzzle;

  // Mathora specific state
  MathoraPuzzle? _mathoraPuzzle;

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
  bool get canUndoNonogram => _nonogramUndoHistory.isNotEmpty;

  NumberTargetPuzzle? get numberTargetPuzzle => _numberTargetPuzzle;
  String get currentExpression => _currentExpression;

  BallSortPuzzle? get ballSortPuzzle => _ballSortPuzzle;
  int? get selectedTube => _selectedTube;
  int get undosRemaining => _undosRemaining;

  PipesPuzzle? get pipesPuzzle => _pipesPuzzle;

  LightsOutPuzzle? get lightsOutPuzzle => _lightsOutPuzzle;

  WordLadderPuzzle? get wordLadderPuzzle => _wordLadderPuzzle;
  String get wordLadderInput => _wordLadderInput;

  ConnectionsPuzzle? get connectionsPuzzle => _connectionsPuzzle;
  MathoraPuzzle? get mathoraPuzzle => _mathoraPuzzle;

  /// Serialize current game state to a map for persistence
  Map<String, dynamic> _serializeState() {
    final state = <String, dynamic>{
      'elapsedSeconds': _elapsedSeconds,
      'mistakes': _mistakes,
      'hintsUsed': _hintsUsed,
      'selectedRow': _selectedRow,
      'selectedCol': _selectedCol,
      'notesMode': _notesMode,
    };

    // Serialize puzzle-specific state
    if (_sudokuPuzzle != null) {
      state['sudokuGrid'] = _sudokuPuzzle!.grid.map((row) => row.toList()).toList();
      state['sudokuNotes'] = _sudokuPuzzle!.notes.map((row) =>
        row.map((set) => set.toList()).toList()
      ).toList();
    }

    if (_killerSudokuPuzzle != null) {
      state['killerSudokuGrid'] = _killerSudokuPuzzle!.grid.map((row) => row.toList()).toList();
      state['killerSudokuNotes'] = _killerSudokuPuzzle!.notes.map((row) =>
        row.map((set) => set.toList()).toList()
      ).toList();
    }

    if (_crosswordPuzzle != null) {
      state['crosswordUserGrid'] = _crosswordPuzzle!.userGrid.map((row) => row.toList()).toList();
      if (_selectedClue != null) {
        state['selectedClueNumber'] = _selectedClue!.number;
        state['selectedClueDirection'] = _selectedClue!.direction;
      }
    }

    if (_wordSearchPuzzle != null) {
      state['foundWordIndices'] = _wordSearchPuzzle!.words
          .asMap()
          .entries
          .where((e) => e.value.found)
          .map((e) => e.key)
          .toList();
    }

    if (_wordForgePuzzle != null) {
      state['wordForgeFoundWords'] = _wordForgePuzzle!.foundWords.toList();
      state['currentWord'] = _currentWord;
    }

    if (_nonogramPuzzle != null) {
      state['nonogramUserGrid'] = _nonogramPuzzle!.userGrid.map((row) => row.toList()).toList();
      state['nonogramMarkMode'] = _nonogramMarkMode;
    }

    if (_numberTargetPuzzle != null) {
      state['numberTargetExpression'] = _currentExpression;
      state['numberTargetUserExpression'] = _numberTargetPuzzle!.userExpression;
    }

    if (_ballSortPuzzle != null) {
      state['ballSortCurrentState'] = _ballSortPuzzle!.currentState.map((t) => t.toList()).toList();
      state['ballSortMoveCount'] = _ballSortPuzzle!.moveCount;
      state['ballSortMoveHistory'] = _ballSortPuzzle!.moveHistory.map((m) => m.toJson()).toList();
      state['ballSortUndosRemaining'] = _undosRemaining;
    }

    if (_pipesPuzzle != null) {
      state['pipesCurrentPaths'] = _pipesPuzzle!.currentPaths.map(
        (color, path) => MapEntry(color, path.map((cell) => cell.toList()).toList())
      );
      state['pipesSelectedColor'] = _pipesPuzzle!.selectedColor;
    }

    if (_lightsOutPuzzle != null) {
      state['lightsOutCurrentState'] = _lightsOutPuzzle!.currentState.map((row) => row.toList()).toList();
      state['lightsOutMoveCount'] = _lightsOutPuzzle!.moveCount;
    }

    if (_wordLadderPuzzle != null) {
      state['wordLadderPathFromStart'] = _wordLadderPuzzle!.pathFromStart.toList();
      state['wordLadderPathFromTarget'] = _wordLadderPuzzle!.pathFromTarget.toList();
      state['wordLadderInput'] = _wordLadderInput;
    }

    if (_connectionsPuzzle != null) {
      state['connectionsSelectedWords'] = _connectionsPuzzle!.selectedWords.toList();
      state['connectionsFoundCategories'] = _connectionsPuzzle!.foundCategories.map(
        (c) => {'name': c.name, 'words': c.words, 'difficulty': c.difficulty}
      ).toList();
      state['connectionsMistakesRemaining'] = _connectionsPuzzle!.mistakesRemaining;
    }

    return state;
  }

  /// Restore game state from a saved map
  void _restoreState(Map<String, dynamic> state) {
    _elapsedSeconds = state['elapsedSeconds'] ?? 0;
    _mistakes = state['mistakes'] ?? 0;
    _hintsUsed = state['hintsUsed'] ?? 0;
    _selectedRow = state['selectedRow'];
    _selectedCol = state['selectedCol'];
    _notesMode = state['notesMode'] ?? false;

    // Restore puzzle-specific state
    if (_sudokuPuzzle != null && state['sudokuGrid'] != null) {
      final grid = state['sudokuGrid'] as List;
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          _sudokuPuzzle!.grid[r][c] = grid[r][c];
        }
      }
      if (state['sudokuNotes'] != null) {
        final notes = state['sudokuNotes'] as List;
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            _sudokuPuzzle!.notes[r][c] = Set<int>.from((notes[r][c] as List).cast<int>());
          }
        }
      }
    }

    if (_killerSudokuPuzzle != null && state['killerSudokuGrid'] != null) {
      final grid = state['killerSudokuGrid'] as List;
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          _killerSudokuPuzzle!.grid[r][c] = grid[r][c];
        }
      }
      if (state['killerSudokuNotes'] != null) {
        final notes = state['killerSudokuNotes'] as List;
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            _killerSudokuPuzzle!.notes[r][c] = Set<int>.from((notes[r][c] as List).cast<int>());
          }
        }
      }
    }

    if (_crosswordPuzzle != null && state['crosswordUserGrid'] != null) {
      final grid = state['crosswordUserGrid'] as List;
      for (int r = 0; r < _crosswordPuzzle!.rows; r++) {
        for (int c = 0; c < _crosswordPuzzle!.cols; c++) {
          _crosswordPuzzle!.userGrid[r][c] = grid[r][c];
        }
      }
      // Restore selected clue
      if (state['selectedClueNumber'] != null && state['selectedClueDirection'] != null) {
        _selectedClue = _crosswordPuzzle!.clues.firstWhere(
          (c) => c.number == state['selectedClueNumber'] && c.direction == state['selectedClueDirection'],
          orElse: () => _crosswordPuzzle!.clues.first,
        );
      }
    }

    if (_wordSearchPuzzle != null && state['foundWordIndices'] != null) {
      final foundIndices = (state['foundWordIndices'] as List).cast<int>();
      for (final idx in foundIndices) {
        if (idx < _wordSearchPuzzle!.words.length) {
          _wordSearchPuzzle!.words[idx].found = true;
        }
      }
    }

    if (_wordForgePuzzle != null && state['wordForgeFoundWords'] != null) {
      final foundWords = (state['wordForgeFoundWords'] as List).cast<String>();
      _wordForgePuzzle!.foundWords.addAll(foundWords);
      _currentWord = state['currentWord'] ?? '';
    }

    if (_nonogramPuzzle != null && state['nonogramUserGrid'] != null) {
      final grid = state['nonogramUserGrid'] as List;
      for (int r = 0; r < _nonogramPuzzle!.rows; r++) {
        for (int c = 0; c < _nonogramPuzzle!.cols; c++) {
          _nonogramPuzzle!.userGrid[r][c] = grid[r][c];
        }
      }
      _nonogramMarkMode = state['nonogramMarkMode'] ?? false;
    }

    if (_numberTargetPuzzle != null) {
      _currentExpression = state['numberTargetExpression'] ?? '';
      _numberTargetPuzzle!.userExpression = state['numberTargetUserExpression'];
    }

    if (_ballSortPuzzle != null && state['ballSortCurrentState'] != null) {
      final savedState = state['ballSortCurrentState'] as List;
      _ballSortPuzzle!.currentState = savedState.map<List<String>>((tube) {
        return (tube as List).map<String>((ball) => ball as String).toList();
      }).toList();
      _ballSortPuzzle!.moveCount = state['ballSortMoveCount'] ?? 0;
      if (state['ballSortMoveHistory'] != null) {
        final history = state['ballSortMoveHistory'] as List;
        _ballSortPuzzle!.moveHistory.clear();
        _ballSortPuzzle!.moveHistory.addAll(
          history.map((m) => BallSortMove.fromJson(m as Map<String, dynamic>))
        );
      }
      _undosRemaining = state['ballSortUndosRemaining'] ?? 5;
    }

    if (_pipesPuzzle != null && state['pipesCurrentPaths'] != null) {
      final savedPaths = state['pipesCurrentPaths'] as Map<String, dynamic>;
      _pipesPuzzle!.currentPaths = savedPaths.map(
        (color, path) => MapEntry(
          color,
          (path as List).map<List<int>>((cell) =>
            (cell as List).map<int>((c) => c as int).toList()
          ).toList()
        )
      );
      _pipesPuzzle!.selectedColor = state['pipesSelectedColor'];
    }

    if (_lightsOutPuzzle != null && state['lightsOutCurrentState'] != null) {
      final savedState = state['lightsOutCurrentState'] as List;
      _lightsOutPuzzle!.currentState = savedState.map<List<bool>>((row) {
        return (row as List).map<bool>((cell) => cell as bool).toList();
      }).toList();
      _lightsOutPuzzle!.moveCount = state['lightsOutMoveCount'] ?? 0;
    }

    if (_wordLadderPuzzle != null) {
      if (state['wordLadderPathFromStart'] != null) {
        _wordLadderPuzzle!.pathFromStart = List<String>.from(state['wordLadderPathFromStart'] as List);
      }
      if (state['wordLadderPathFromTarget'] != null) {
        _wordLadderPuzzle!.pathFromTarget = List<String>.from(state['wordLadderPathFromTarget'] as List);
      }
      _wordLadderInput = state['wordLadderInput'] ?? '';
    }

    if (_connectionsPuzzle != null && state['connectionsSelectedWords'] != null) {
      _connectionsPuzzle!.selectedWords = Set<String>.from(state['connectionsSelectedWords'] as List);
      _connectionsPuzzle!.mistakesRemaining = state['connectionsMistakesRemaining'] ?? 4;
      if (state['connectionsFoundCategories'] != null) {
        final foundCats = state['connectionsFoundCategories'] as List;
        _connectionsPuzzle!.foundCategories = foundCats.map((c) =>
          ConnectionsCategory(
            name: c['name'] as String,
            words: List<String>.from(c['words'] as List),
            difficulty: c['difficulty'] as int,
          )
        ).toList();
      }
    }
  }

  /// Save current game state to persistent storage
  Future<void> saveState() async {
    if (_currentPuzzle == null || _currentPuzzleDate == null) return;

    await GameStateService.saveGameState(
      gameType: _currentPuzzle!.gameType,
      puzzleDate: _currentPuzzleDate!,
      state: _serializeState(),
    );
  }

  /// Load a puzzle and optionally restore saved state
  Future<void> loadPuzzle(DailyPuzzle puzzle, {bool restoreSavedState = true}) async {
    _currentPuzzle = puzzle;
    _currentPuzzleDate = puzzle.date;
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
    _selectedClue = null;
    _wordLadderInput = '';

    // Clear all puzzle-specific state
    _sudokuPuzzle = null;
    _killerSudokuPuzzle = null;
    _crosswordPuzzle = null;
    _wordSearchPuzzle = null;
    _wordForgePuzzle = null;
    _nonogramPuzzle = null;
    _numberTargetPuzzle = null;
    _ballSortPuzzle = null;
    _selectedTube = null;
    _undosRemaining = 5;
    _pipesPuzzle = null;
    _lightsOutPuzzle = null;
    _wordLadderPuzzle = null;
    _connectionsPuzzle = null;

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
        // Initialize valid words from dictionary
        await _initializeWordForgeDictionary();
        break;
      case GameType.nonogram:
        _nonogramPuzzle = NonogramPuzzle.fromJson(puzzleDataWithSolution);
        _nonogramUndoHistory.clear();
        break;
      case GameType.numberTarget:
        _numberTargetPuzzle = NumberTargetPuzzle.fromJson(puzzleDataWithSolution);
        break;
      case GameType.ballSort:
        _ballSortPuzzle = BallSortPuzzle.fromJson(puzzleDataWithSolution);
        break;
      case GameType.pipes:
        _pipesPuzzle = PipesPuzzle.fromJson(puzzleDataWithSolution);
        break;
      case GameType.lightsOut:
        _lightsOutPuzzle = LightsOutPuzzle.fromJson(puzzleDataWithSolution);
        break;
      case GameType.wordLadder:
        _wordLadderPuzzle = WordLadderPuzzle.fromJson(puzzleDataWithSolution);
        // Ensure dictionary is loaded for word validation
        await DictionaryService().load();
        break;
      case GameType.connections:
        _connectionsPuzzle = ConnectionsPuzzle.fromJson(puzzleDataWithSolution);
        break;
      case GameType.mathora:
        _mathoraPuzzle = MathoraPuzzle.fromJson(
          puzzleDataWithSolution,
          puzzle.solution as Map<String, dynamic>?,
        );
        break;
    }

    // Try to restore saved state if requested
    if (restoreSavedState && _currentPuzzleDate != null) {
      final savedState = await GameStateService.loadGameState(
        gameType: puzzle.gameType,
        puzzleDate: _currentPuzzleDate!,
      );
      if (savedState != null) {
        _restoreState(savedState);
      }
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

      // Remove this number from notes in related cells (same row, column, box, cage)
      _removeNoteFromRelatedCells(_selectedRow!, _selectedCol!, number, puzzle);

      notifyListeners();
      return isValid;
    }
  }

  /// Remove a number from notes in cells that see the given cell
  void _removeNoteFromRelatedCells(int row, int col, int number, SudokuPuzzle puzzle) {
    // Remove from same row
    for (int c = 0; c < 9; c++) {
      if (c != col) {
        puzzle.notes[row][c].remove(number);
      }
    }

    // Remove from same column
    for (int r = 0; r < 9; r++) {
      if (r != row) {
        puzzle.notes[r][col].remove(number);
      }
    }

    // Remove from same 3x3 box
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (int r = boxRow; r < boxRow + 3; r++) {
      for (int c = boxCol; c < boxCol + 3; c++) {
        if (r != row || c != col) {
          puzzle.notes[r][c].remove(number);
        }
      }
    }

    // For Killer Sudoku, also remove from same cage
    if (_killerSudokuPuzzle != null) {
      final cageInfo = _killerSudokuPuzzle!.getCageForCell(row, col);
      if (cageInfo != null) {
        final cage = _killerSudokuPuzzle!.cages[cageInfo[0]];
        for (final cell in cage.cells) {
          if (cell[0] != row || cell[1] != col) {
            puzzle.notes[cell[0]][cell[1]].remove(number);
          }
        }
      }
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

  Future<bool> checkSudokuComplete() async {
    final puzzle = _sudokuPuzzle ?? _killerSudokuPuzzle;
    if (puzzle == null) return false;

    if (puzzle.isComplete) {
      _isPlaying = false;
      await _markAsCompleted();
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

  Future<bool> checkCrosswordComplete() async {
    if (_crosswordPuzzle == null) return false;

    if (_crosswordPuzzle!.isComplete) {
      _isPlaying = false;
      await _markAsCompleted();
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

  Future<bool> checkWordSearchComplete() async {
    if (_wordSearchPuzzle == null) return false;

    if (_wordSearchPuzzle!.isComplete) {
      _isPlaying = false;
      await _markAsCompleted();
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

  Future<bool> checkWordForgeComplete() async {
    if (_wordForgePuzzle == null) return false;

    if (_wordForgePuzzle!.isComplete) {
      _isPlaying = false;
      await _markAsCompleted();
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

  /// Initialize Word Forge puzzle with valid words from dictionary (legacy fallback)
  Future<void> _initializeWordForgeDictionary() async {
    if (_wordForgePuzzle == null) return;

    // Skip if puzzle already has words from backend
    if (_wordForgePuzzle!.words.isNotEmpty) {
      print('Word Forge initialized from backend: ${_wordForgePuzzle!.words.length} valid words, ${_wordForgePuzzle!.pangrams.length} pangrams');
      return;
    }

    // Legacy fallback: load from local dictionary
    final dictionary = DictionaryService();
    await dictionary.load();

    if (!dictionary.isLoaded) {
      print('Warning: Dictionary not loaded, Word Forge may not work correctly');
      return;
    }

    final validWords = dictionary.findValidWords(
      _wordForgePuzzle!.letters,
      _wordForgePuzzle!.centerLetter,
    );
    final pangrams = dictionary.findPangrams(
      _wordForgePuzzle!.letters,
      _wordForgePuzzle!.centerLetter,
    );

    _wordForgePuzzle!.initializeFromDictionary(validWords, pangrams);
    print('Word Forge initialized from local dictionary: ${validWords.length} valid words, ${pangrams.length} pangrams');
  }

  /// Get two-letter hints grid (FREE hint)
  Map<String, int> getWordForgeTwoLetterHints() {
    if (_wordForgePuzzle == null) return {};

    // Use puzzle's words list (from backend)
    if (_wordForgePuzzle!.words.isNotEmpty) {
      final hints = <String, int>{};
      for (final wordEntry in _wordForgePuzzle!.words) {
        final word = wordEntry.word;
        if (word.length >= 2 && !_wordForgePuzzle!.foundWords.contains(word)) {
          final prefix = word.substring(0, 2);
          hints[prefix] = (hints[prefix] ?? 0) + 1;
        }
      }
      return hints;
    }

    // Legacy fallback: use dictionary service
    final dictionary = DictionaryService();
    if (!dictionary.isLoaded) return {};

    return dictionary.getTwoLetterHints(
      _wordForgePuzzle!.letters,
      _wordForgePuzzle!.centerLetter,
      _wordForgePuzzle!.foundWords,
    );
  }

  /// Reveal a word with the given two-letter prefix (costs a hint)
  /// Returns the revealed word with clue, or null if none available
  WordForgeWord? revealWordForgeWordWithPrefix(String prefix) {
    if (_wordForgePuzzle == null) return null;

    final revealed = _wordForgePuzzle!.revealWordWithPrefix(prefix);
    if (revealed != null) {
      _hintsUsed++;
      notifyListeners();
    }
    return revealed;
  }

  /// Get all revealed words (for display in hint panel)
  List<WordForgeWord> getRevealedWordForgeWords() {
    if (_wordForgePuzzle == null) return [];
    return _wordForgePuzzle!.words
        .where((w) => _wordForgePuzzle!.revealedWords.contains(w.word))
        .toList();
  }

  /// Get a pangram hint (first letter and length) - costs a hint
  /// Returns null if no unfound pangrams exist
  Map<String, dynamic>? getWordForgePangramHint() {
    if (_wordForgePuzzle == null) return null;
    if (_wordForgePuzzle!.hasUsedPangramHint) return null;

    // Check if user has found all pangrams
    final unfoundPangrams = _wordForgePuzzle!.pangrams
        .where((p) => !_wordForgePuzzle!.foundWords.contains(p))
        .toList();

    if (unfoundPangrams.isEmpty) return null;

    // Pick a random unfound pangram
    unfoundPangrams.shuffle();
    final pangram = unfoundPangrams.first;

    return {
      'firstLetter': pangram[0],
      'length': pangram.length,
    };
  }

  /// Use the pangram hint - marks it as used and increments hint count
  void useWordForgePangramHint() {
    if (_wordForgePuzzle == null) return;
    _wordForgePuzzle!.hasUsedPangramHint = true;
    _hintsUsed++;
    notifyListeners();
  }

  /// Get a random word hint (first letter and length) - costs a hint
  Map<String, dynamic>? getWordForgeWordHint() {
    if (_wordForgePuzzle == null) return null;

    final unfoundWords = _wordForgePuzzle!.validWords
        .where((w) => !_wordForgePuzzle!.foundWords.contains(w))
        .toList();

    if (unfoundWords.isEmpty) return null;

    // Pick a random unfound word
    unfoundWords.shuffle();
    final word = unfoundWords.first;

    return {
      'firstLetter': word[0],
      'length': word.length,
      'word': word, // For reveal feature
    };
  }

  /// Use a word hint (reveal) - costs a hint and reveals the word
  void useWordForgeWordReveal(String word) {
    if (_wordForgePuzzle == null) return;
    final upperWord = word.toUpperCase();
    if (_wordForgePuzzle!.validWords.contains(upperWord)) {
      _wordForgePuzzle!.foundWords.add(upperWord);
      _hintsUsed++;
      notifyListeners();
    }
  }

  /// Check if user has found any pangrams
  bool hasFoundPangram() {
    if (_wordForgePuzzle == null) return false;
    return _wordForgePuzzle!.foundWords
        .any((w) => _wordForgePuzzle!.pangrams.contains(w));
  }

  /// Get count of unfound pangrams
  int getUnfoundPangramCount() {
    if (_wordForgePuzzle == null) return 0;
    return _wordForgePuzzle!.pangrams
        .where((p) => !_wordForgePuzzle!.foundWords.contains(p))
        .length;
  }

  // Nonogram methods
  void toggleNonogramMarkMode() {
    _nonogramMarkMode = !_nonogramMarkMode;
    notifyListeners();
  }

  /// Save current nonogram state for undo (call before a tap or at drag start)
  void saveNonogramStateForUndo() {
    if (_nonogramPuzzle == null) return;

    // Deep copy the current grid state (convert null to 0 for storage)
    final gridCopy = _nonogramPuzzle!.userGrid
        .map((row) => row.map((cell) => cell ?? 0).toList())
        .toList();

    _nonogramUndoHistory.add(gridCopy);

    // Limit history to 50 entries to prevent memory issues
    if (_nonogramUndoHistory.length > 50) {
      _nonogramUndoHistory.removeAt(0);
    }
  }

  /// Undo the last nonogram action (restores previous grid state)
  void undoNonogram() {
    if (_nonogramPuzzle == null || _nonogramUndoHistory.isEmpty) return;

    final previousState = _nonogramUndoHistory.removeLast();

    // Restore the grid state
    for (int r = 0; r < _nonogramPuzzle!.rows; r++) {
      for (int c = 0; c < _nonogramPuzzle!.cols; c++) {
        _nonogramPuzzle!.userGrid[r][c] = previousState[r][c];
      }
    }

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
      } else if (currentState == 0) {
        _nonogramPuzzle!.userGrid[row][col] = -1;
      } else {
        // Was filled, toggle to marked
        _nonogramPuzzle!.userGrid[row][col] = -1;
      }
    } else {
      // Fill mode: toggle between empty (0) and filled (1)
      if (currentState == 1) {
        _nonogramPuzzle!.userGrid[row][col] = 0;
      } else if (currentState == 0) {
        _nonogramPuzzle!.userGrid[row][col] = 1;
      } else {
        // Was marked, toggle to filled
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

  /// Set a nonogram cell to a specific state
  /// State: 0 = empty, 1 = filled, -1 = marked
  void setNonogramCellState(int row, int col, int state) {
    if (_nonogramPuzzle == null) return;
    if (state < -1 || state > 1) return;
    _nonogramPuzzle!.userGrid[row][col] = state;
    notifyListeners();
  }

  /// Set a nonogram cell state without notifying listeners (for batch updates)
  void setNonogramCellStateSilent(int row, int col, int state) {
    if (_nonogramPuzzle == null) return;
    if (state < -1 || state > 1) return;
    _nonogramPuzzle!.userGrid[row][col] = state;
  }

  /// Notify listeners after batch updates
  void notifyNonogramChanged() {
    notifyListeners();
  }

  Future<bool> checkNonogramComplete() async {
    if (_nonogramPuzzle == null) return false;

    if (_nonogramPuzzle!.isComplete) {
      _isPlaying = false;
      await _markAsCompleted();
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
  Set<int> _usedNumberIndices = {};

  Set<int> get usedNumberIndices => _usedNumberIndices;

  bool _isOperator(String token) {
    return token == '+' || token == '-' || token == '×' || token == '÷';
  }

  String? _getLastToken() {
    if (_currentExpression.isEmpty) return null;
    // Parse from end to find last token
    final expr = _currentExpression;
    int i = expr.length - 1;

    // Check if last char is operator or parenthesis
    final lastChar = expr[i];
    if (_isOperator(lastChar) || lastChar == '(' || lastChar == ')') {
      return lastChar;
    }

    // Otherwise it's a number - find its start
    while (i > 0 && RegExp(r'\d').hasMatch(expr[i - 1])) {
      i--;
    }
    return expr.substring(i);
  }

  void addToNumberTargetExpression(String token, {int? numberIndex}) {
    // Validate the token can be added
    final lastToken = _getLastToken();

    if (_isOperator(token)) {
      // Can't start with an operator (except could allow '-' for negative, but let's keep it simple)
      if (_currentExpression.isEmpty) return;
      // Can't have operator after operator
      if (lastToken != null && _isOperator(lastToken)) return;
      // Can't have operator after opening parenthesis
      if (lastToken == '(') return;
    }

    // If it's a number, check if it's already used
    if (numberIndex != null) {
      if (_usedNumberIndices.contains(numberIndex)) return;
      // Can't add number right after another number (need operator between)
      if (lastToken != null && RegExp(r'^\d+$').hasMatch(lastToken)) return;
      // Can't add number right after closing parenthesis
      if (lastToken == ')') return;

      _usedNumberIndices.add(numberIndex);
    }

    // Opening parenthesis rules
    if (token == '(') {
      // Can't add after a number or closing paren without operator
      if (lastToken != null &&
          (RegExp(r'^\d+$').hasMatch(lastToken) || lastToken == ')')) return;
    }

    // Closing parenthesis rules
    if (token == ')') {
      // Can't close after operator or opening paren
      if (lastToken != null && (_isOperator(lastToken) || lastToken == '('))
        return;
      // Must have matching open paren
      final openCount = '('.allMatches(_currentExpression).length;
      final closeCount = ')'.allMatches(_currentExpression).length;
      if (closeCount >= openCount) return;
    }

    _currentExpression += token;
    notifyListeners();
  }

  void clearNumberTargetExpression() {
    _currentExpression = '';
    _usedNumberIndices.clear();
    notifyListeners();
  }

  void backspaceNumberTargetExpression() {
    if (_currentExpression.isEmpty) return;

    final lastToken = _getLastToken();
    if (lastToken == null) return;

    // Remove the last token
    _currentExpression = _currentExpression.substring(
        0, _currentExpression.length - lastToken.length);

    // If it was a number, find which index it was and mark as unused
    if (RegExp(r'^\d+$').hasMatch(lastToken)) {
      final number = int.parse(lastToken);
      // Find the index of this number in the puzzle numbers
      if (_numberTargetPuzzle != null) {
        for (int i = 0; i < _numberTargetPuzzle!.numbers.length; i++) {
          if (_numberTargetPuzzle!.numbers[i] == number &&
              _usedNumberIndices.contains(i)) {
            _usedNumberIndices.remove(i);
            break;
          }
        }
      }
    }

    notifyListeners();
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

  Future<bool> checkNumberTargetComplete() async {
    if (_numberTargetPuzzle == null) return false;

    if (_numberTargetPuzzle!.isComplete) {
      _isPlaying = false;
      await _markAsCompleted();
      notifyListeners();
      return true;
    }
    return false;
  }

  // Ball Sort methods
  void selectBallSortTube(int tubeIndex) {
    if (_ballSortPuzzle == null) return;

    if (_selectedTube == null) {
      // First selection - only allow if tube has balls
      if (_ballSortPuzzle!.currentState[tubeIndex].isNotEmpty) {
        _selectedTube = tubeIndex;
      }
    } else if (_selectedTube == tubeIndex) {
      // Deselect
      _selectedTube = null;
    } else {
      // Second selection - try to move
      if (_ballSortPuzzle!.canMoveTo(_selectedTube!, tubeIndex)) {
        _ballSortPuzzle!.moveBall(_selectedTube!, tubeIndex);
      }
      _selectedTube = null;
    }
    notifyListeners();
  }

  void clearBallSortSelection() {
    _selectedTube = null;
    notifyListeners();
  }

  bool undoBallSortMove() {
    if (_ballSortPuzzle == null) return false;
    if (_ballSortPuzzle!.moveHistory.isEmpty) return false;
    if (_undosRemaining <= 0) return false; // TODO: Check unlimited undo setting

    if (_ballSortPuzzle!.undoMove()) {
      _undosRemaining--;
      notifyListeners();
      return true;
    }
    return false;
  }

  void resetBallSortPuzzle() {
    if (_ballSortPuzzle == null) return;
    _ballSortPuzzle!.reset();
    _selectedTube = null;
    _undosRemaining = 5;
    notifyListeners();
  }

  Future<bool> checkBallSortComplete() async {
    if (_ballSortPuzzle == null) return false;

    if (_ballSortPuzzle!.isComplete) {
      _isPlaying = false;
      await _markAsCompleted();
      notifyListeners();
      return true;
    }
    return false;
  }

  // Pipes methods
  void startPipesPath(String color, int row, int col) {
    if (_pipesPuzzle == null) return;
    _pipesPuzzle!.selectedColor = color;
    _pipesPuzzle!.clearPath(color);
    _pipesPuzzle!.addToPath(color, row, col);
    notifyListeners();
  }

  void extendPipesPath(int row, int col) {
    if (_pipesPuzzle == null || _pipesPuzzle!.selectedColor == null) return;
    final color = _pipesPuzzle!.selectedColor!;
    final path = _pipesPuzzle!.currentPaths[color] ?? [];

    if (path.isEmpty) return;

    // Check if path has already reached the destination endpoint - don't extend further
    final endpoints = _pipesPuzzle!.getEndpointsForColor(color);
    if (endpoints.length == 2 && path.length >= 2) {
      final lastCell = path.last;
      final startEndpoint = endpoints.firstWhere(
        (e) => e.row == path.first[0] && e.col == path.first[1],
        orElse: () => endpoints.first,
      );
      final destEndpoint = endpoints.firstWhere(
        (e) => e != startEndpoint,
        orElse: () => endpoints.last,
      );

      // If we've reached the destination endpoint, don't allow extending
      if (lastCell[0] == destEndpoint.row && lastCell[1] == destEndpoint.col) {
        return;
      }
    }

    // Check if this is an adjacent cell
    final lastCell = path.last;
    final rowDiff = (row - lastCell[0]).abs();
    final colDiff = (col - lastCell[1]).abs();

    // Only allow adjacent cells (no diagonal)
    if ((rowDiff == 1 && colDiff == 0) || (rowDiff == 0 && colDiff == 1)) {
      // Check if this cell is already in the path (backtracking)
      final existingIdx = path.indexWhere((c) => c[0] == row && c[1] == col);
      if (existingIdx != -1) {
        // Remove everything after this point (backtracking)
        while (path.length > existingIdx + 1) {
          path.removeLast();
        }
        notifyListeners();
      } else {
        // Check if this cell contains an endpoint of a DIFFERENT color
        final endpointAtCell = _pipesPuzzle!.getEndpointAt(row, col);
        if (endpointAtCell != null && endpointAtCell.color != color) {
          // Can't go through another color's endpoint
          return;
        }

        // Check if this cell is occupied by another color's path
        for (final entry in _pipesPuzzle!.currentPaths.entries) {
          if (entry.key != color) {
            for (final cell in entry.value) {
              if (cell[0] == row && cell[1] == col) {
                // Can't go through another color's path
                return;
              }
            }
          }
        }

        // Add to path
        _pipesPuzzle!.addToPath(color, row, col);
        notifyListeners();
      }
    }
  }

  void continuePipesPath(String color) {
    if (_pipesPuzzle == null) return;
    // Just set the selected color without clearing the path
    // This allows continuing from where the path left off
    _pipesPuzzle!.selectedColor = color;
    notifyListeners();
  }

  void endPipesPath() {
    if (_pipesPuzzle == null) return;
    _pipesPuzzle!.selectedColor = null;
    notifyListeners();
  }

  void clearPipesPath(String color) {
    if (_pipesPuzzle == null) return;
    _pipesPuzzle!.clearPath(color);
    notifyListeners();
  }

  void resetPipesPuzzle() {
    if (_pipesPuzzle == null) return;
    _pipesPuzzle!.reset();
    notifyListeners();
  }

  Future<bool> checkPipesComplete() async {
    if (_pipesPuzzle == null) return false;

    if (_pipesPuzzle!.isComplete) {
      _isPlaying = false;
      await _markAsCompleted();
      notifyListeners();
      return true;
    }
    return false;
  }

  // Lights Out methods
  void toggleLightsOutCell(int row, int col) {
    if (_lightsOutPuzzle == null) return;
    _lightsOutPuzzle!.toggle(row, col);
    notifyListeners();
  }

  void resetLightsOutPuzzle() {
    if (_lightsOutPuzzle == null) return;
    _lightsOutPuzzle!.reset();
    notifyListeners();
  }

  Future<bool> checkLightsOutComplete() async {
    if (_lightsOutPuzzle == null) return false;

    if (_lightsOutPuzzle!.isComplete) {
      _isPlaying = false;
      await _markAsCompleted();
      notifyListeners();
      return true;
    }
    return false;
  }

  // Word Ladder methods
  void setWordLadderInput(String input) {
    _wordLadderInput = input.toUpperCase();
    notifyListeners();
  }

  void addWordLadderLetter(String letter) {
    if (_wordLadderPuzzle == null) return;
    if (_wordLadderInput.length < _wordLadderPuzzle!.wordLength) {
      _wordLadderInput += letter.toUpperCase();
      notifyListeners();
    }
  }

  void deleteWordLadderLetter() {
    if (_wordLadderInput.isNotEmpty) {
      _wordLadderInput = _wordLadderInput.substring(0, _wordLadderInput.length - 1);
      notifyListeners();
    }
  }

  void clearWordLadderInput() {
    _wordLadderInput = '';
    notifyListeners();
  }

  /// Submit the current word. Returns a result with success status and message.
  WordLadderSubmitResult submitWordLadderWord() {
    if (_wordLadderPuzzle == null || _wordLadderInput.isEmpty) {
      return WordLadderSubmitResult(success: false, message: 'Enter a word');
    }

    final word = _wordLadderInput.toUpperCase();

    // Check if it's a valid dictionary word
    final dictionary = DictionaryService();
    if (!dictionary.isValidWord(word)) {
      _wordLadderInput = '';
      notifyListeners();
      return WordLadderSubmitResult(
        success: false,
        message: 'Not a valid word'
      );
    }

    // Check if it differs by exactly one letter
    if (!_wordLadderPuzzle!.canAddWord(word)) {
      _wordLadderInput = '';
      notifyListeners();
      return WordLadderSubmitResult(
        success: false,
        message: 'Must differ by exactly one letter'
      );
    }

    // Add the word
    _wordLadderPuzzle!.addWord(word);
    _wordLadderInput = '';
    notifyListeners();

    // Check if reached target
    if (word == _wordLadderPuzzle!.targetWord) {
      return WordLadderSubmitResult(success: true, message: 'Complete!', isComplete: true);
    }

    return WordLadderSubmitResult(success: true, message: 'Added: $word');
  }

  void undoWordLadderWord() {
    if (_wordLadderPuzzle == null) return;
    _wordLadderPuzzle!.undoLastWord();
    notifyListeners();
  }

  void resetWordLadderPuzzle() {
    if (_wordLadderPuzzle == null) return;
    _wordLadderPuzzle!.reset();
    _wordLadderInput = '';
    notifyListeners();
  }

  Future<bool> checkWordLadderComplete() async {
    if (_wordLadderPuzzle == null) return false;

    if (_wordLadderPuzzle!.isComplete) {
      _isPlaying = false;
      await _markAsCompleted();
      notifyListeners();
      return true;
    }
    return false;
  }

  // Connections methods
  void toggleConnectionsWord(String word) {
    if (_connectionsPuzzle == null) return;
    _connectionsPuzzle!.toggleWord(word);
    notifyListeners();
  }

  void clearConnectionsSelection() {
    if (_connectionsPuzzle == null) return;
    _connectionsPuzzle!.clearSelection();
    notifyListeners();
  }

  /// Submit the current selection. Returns a result with the category if correct.
  ConnectionsSubmitResult submitConnectionsSelection() {
    if (_connectionsPuzzle == null) {
      return ConnectionsSubmitResult(success: false, message: 'No puzzle');
    }

    if (_connectionsPuzzle!.selectedWords.length != 4) {
      return ConnectionsSubmitResult(success: false, message: 'Select 4 words');
    }

    final category = _connectionsPuzzle!.submitSelection();
    notifyListeners();

    if (category != null) {
      return ConnectionsSubmitResult(
        success: true,
        message: category.name,
        category: category
      );
    } else {
      final remaining = _connectionsPuzzle!.mistakesRemaining;
      if (remaining <= 0) {
        return ConnectionsSubmitResult(
          success: false,
          message: 'Game Over',
          isGameOver: true
        );
      }
      return ConnectionsSubmitResult(
        success: false,
        message: 'Incorrect - $remaining mistakes left'
      );
    }
  }

  void resetConnectionsPuzzle() {
    if (_connectionsPuzzle == null) return;
    _connectionsPuzzle!.reset();
    notifyListeners();
  }

  void shuffleConnectionsWords() {
    if (_connectionsPuzzle == null) return;
    _connectionsPuzzle!.shuffleWords();
    notifyListeners();
  }

  /// Auto-reveal remaining categories one by one (for game over)
  Future<void> autoRevealConnectionsCategories() async {
    if (_connectionsPuzzle == null) return;

    // Mark as lost
    _connectionsPuzzle!.wasLost = true;

    // Get unfound categories sorted by difficulty
    final unfoundCategories = _connectionsPuzzle!.categories
        .where((c) => !_connectionsPuzzle!.foundCategories.contains(c))
        .toList()
      ..sort((a, b) => a.difficulty.compareTo(b.difficulty));

    // Reveal each category with animation
    for (final category in unfoundCategories) {
      // First, highlight the words one by one
      _connectionsPuzzle!.selectedWords.clear();
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 500));

      // Select each word with a small delay
      for (final word in category.words) {
        _connectionsPuzzle!.selectedWords.add(word);
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 250));
      }

      // Pause to show all 4 selected
      await Future.delayed(const Duration(milliseconds: 600));

      // Clear selection and reveal the category
      _connectionsPuzzle!.selectedWords.clear();
      _connectionsPuzzle!.foundCategories.add(category);
      // Sort by difficulty after adding
      _connectionsPuzzle!.foundCategories.sort((a, b) => a.difficulty.compareTo(b.difficulty));
      notifyListeners();

      // Pause before next category
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<bool> checkConnectionsComplete() async {
    if (_connectionsPuzzle == null) return false;

    // Only count as complete if player won (not lost)
    if (_connectionsPuzzle!.wasWon) {
      _isPlaying = false;
      await _markAsCompleted();
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Mark current puzzle as completed and save completion status
  Future<void> _markAsCompleted() async {
    if (_currentPuzzle == null || _currentPuzzleDate == null) return;

    final score = calculateScore();
    await GameStateService.markCompleted(
      gameType: _currentPuzzle!.gameType,
      puzzleDate: _currentPuzzleDate!,
      elapsedSeconds: _elapsedSeconds,
      score: score,
    );
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
    _ballSortPuzzle = null;
    _selectedTube = null;
    _undosRemaining = 5;
    _pipesPuzzle = null;
    _lightsOutPuzzle = null;
    _wordLadderPuzzle = null;
    _wordLadderInput = '';
    _connectionsPuzzle = null;
    _mathoraPuzzle = null;
    notifyListeners();
  }

  // ======================================
  // MATHORA METHODS
  // ======================================

  /// Apply an operation in Mathora puzzle
  MathoraOperationResult applyMathoraOperation(MathoraOperation operation) {
    if (_mathoraPuzzle == null) {
      return MathoraOperationResult(success: false, message: 'No puzzle');
    }

    final success = _mathoraPuzzle!.applyOperation(operation);
    notifyListeners();

    if (!success) {
      if (_mathoraPuzzle!.movesLeft <= 0) {
        return MathoraOperationResult(
          success: false,
          message: 'No moves left!',
        );
      }
      if (operation.type == 'divide') {
        return MathoraOperationResult(
          success: false,
          message: 'Cannot divide evenly',
        );
      }
      return MathoraOperationResult(
        success: false,
        message: 'Invalid operation',
      );
    }

    if (_mathoraPuzzle!.isSolved) {
      return MathoraOperationResult(
        success: true,
        message: 'Solved!',
        isSolved: true,
      );
    }

    return MathoraOperationResult(
      success: true,
      message: '${_mathoraPuzzle!.movesLeft} moves left',
    );
  }

  /// Undo the last operation in Mathora puzzle
  void undoMathoraOperation() {
    if (_mathoraPuzzle == null) return;
    _mathoraPuzzle!.undoLastOperation();
    notifyListeners();
  }

  /// Reset the Mathora puzzle
  void resetMathoraPuzzle() {
    if (_mathoraPuzzle == null) return;
    _mathoraPuzzle!.reset();
    notifyListeners();
  }

  /// Check if Mathora puzzle is complete
  Future<bool> checkMathoraComplete() async {
    if (_mathoraPuzzle == null) return false;

    if (_mathoraPuzzle!.isSolved) {
      _isPlaying = false;
      await _markAsCompleted();
      notifyListeners();
      return true;
    }
    return false;
  }
}

/// Result object for Mathora operation
class MathoraOperationResult {
  final bool success;
  final String message;
  final bool isSolved;

  MathoraOperationResult({
    required this.success,
    required this.message,
    this.isSolved = false,
  });
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

/// Result object for Word Ladder word submission
class WordLadderSubmitResult {
  final bool success;
  final String message;
  final bool isComplete;

  WordLadderSubmitResult({
    required this.success,
    required this.message,
    this.isComplete = false,
  });
}

/// Result object for Connections selection submission
class ConnectionsSubmitResult {
  final bool success;
  final String message;
  final ConnectionsCategory? category;
  final bool isGameOver;

  ConnectionsSubmitResult({
    required this.success,
    required this.message,
    this.category,
    this.isGameOver = false,
  });
}
