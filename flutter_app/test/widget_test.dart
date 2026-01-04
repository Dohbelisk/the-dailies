// Unit tests for The Dailies app
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_daily/models/game_models.dart';
import 'package:puzzle_daily/providers/game_provider.dart';

void main() {
  group('GameType enum', () {
    test('displayName returns correct names', () {
      expect(GameType.sudoku.displayName, 'Sudoku');
      expect(GameType.killerSudoku.displayName, 'Killer Sudoku');
      expect(GameType.crossword.displayName, 'Crossword');
      expect(GameType.wordSearch.displayName, 'Word Search');
      expect(GameType.wordForge.displayName, 'Word Forge');
      expect(GameType.nonogram.displayName, 'Nonogram');
      expect(GameType.numberTarget.displayName, 'Number Target');
      expect(GameType.ballSort.displayName, 'Ball Sort');
      expect(GameType.pipes.displayName, 'Pipes');
      expect(GameType.lightsOut.displayName, 'Lights Out');
      expect(GameType.wordLadder.displayName, 'Word Ladder');
      expect(GameType.connections.displayName, 'Connections');
      expect(GameType.mathora.displayName, 'Mathora');
    });

    test('all 13 game types are defined', () {
      expect(GameType.values.length, 13);
    });
  });

  group('Difficulty enum', () {
    test('displayName returns capitalized names', () {
      expect(Difficulty.easy.displayName, 'Easy');
      expect(Difficulty.medium.displayName, 'Medium');
      expect(Difficulty.hard.displayName, 'Hard');
      expect(Difficulty.expert.displayName, 'Expert');
    });

    test('stars returns correct values', () {
      expect(Difficulty.easy.stars, 1);
      expect(Difficulty.medium.stars, 2);
      expect(Difficulty.hard.stars, 3);
      expect(Difficulty.expert.stars, 4);
    });
  });

  group('DailyPuzzle', () {
    test('fromJson parses puzzle correctly', () {
      final json = {
        'id': 'test-123',
        'gameType': 'sudoku',
        'difficulty': 'medium',
        'date': '2025-01-01T00:00:00.000Z',
        'puzzleData': {'grid': []},
        'targetTime': 600,
        'isActive': true,
      };

      final puzzle = DailyPuzzle.fromJson(json);

      expect(puzzle.id, 'test-123');
      expect(puzzle.gameType, GameType.sudoku);
      expect(puzzle.difficulty, Difficulty.medium);
      expect(puzzle.targetTime, 600);
      expect(puzzle.isActive, true);
    });

    test('toJson serializes correctly', () {
      final puzzle = DailyPuzzle(
        id: 'test-123',
        gameType: GameType.sudoku,
        difficulty: Difficulty.medium,
        date: DateTime.parse('2025-01-01T00:00:00.000Z'),
        puzzleData: {'grid': []},
        targetTime: 600,
        isActive: true,
      );

      final json = puzzle.toJson();

      expect(json['id'], 'test-123');
      expect(json['gameType'], 'sudoku');
      expect(json['difficulty'], 'medium');
      expect(json['targetTime'], 600);
    });

    test('copyWith creates modified copy', () {
      final puzzle = DailyPuzzle(
        id: 'test-123',
        gameType: GameType.sudoku,
        difficulty: Difficulty.medium,
        date: DateTime.parse('2025-01-01T00:00:00.000Z'),
        puzzleData: {'grid': []},
        targetTime: 600,
        isActive: true,
      );

      final modified = puzzle.copyWith(difficulty: Difficulty.hard);

      expect(modified.difficulty, Difficulty.hard);
      expect(modified.id, 'test-123'); // Unchanged
      expect(modified.gameType, GameType.sudoku); // Unchanged
    });
  });

  group('SudokuPuzzle', () {
    test('fromJson parses puzzle correctly', () {
      final json = {
        'grid': [
          [5, 3, 0, 0, 7, 0, 0, 0, 0],
          [6, 0, 0, 1, 9, 5, 0, 0, 0],
          [0, 9, 8, 0, 0, 0, 0, 6, 0],
          [8, 0, 0, 0, 6, 0, 0, 0, 3],
          [4, 0, 0, 8, 0, 3, 0, 0, 1],
          [7, 0, 0, 0, 2, 0, 0, 0, 6],
          [0, 6, 0, 0, 0, 0, 2, 8, 0],
          [0, 0, 0, 4, 1, 9, 0, 0, 5],
          [0, 0, 0, 0, 8, 0, 0, 7, 9],
        ],
        'solution': [
          [5, 3, 4, 6, 7, 8, 9, 1, 2],
          [6, 7, 2, 1, 9, 5, 3, 4, 8],
          [1, 9, 8, 3, 4, 2, 5, 6, 7],
          [8, 5, 9, 7, 6, 1, 4, 2, 3],
          [4, 2, 6, 8, 5, 3, 7, 9, 1],
          [7, 1, 3, 9, 2, 4, 8, 5, 6],
          [9, 6, 1, 5, 3, 7, 2, 8, 4],
          [2, 8, 7, 4, 1, 9, 6, 3, 5],
          [3, 4, 5, 2, 8, 6, 1, 7, 9],
        ],
      };

      final puzzle = SudokuPuzzle.fromJson(json);

      expect(puzzle.grid[0][0], 5);
      expect(puzzle.grid[0][2], null); // 0 becomes null
      expect(puzzle.solution[0][0], 5);
      expect(puzzle.solution[0][2], 4);
    });

    test('isValidPlacement validates row constraints', () {
      final puzzle = SudokuPuzzle(
        grid: List.generate(9, (_) => List.filled(9, null)),
        initialGrid: List.generate(9, (_) => List.filled(9, null)),
        solution: List.generate(9, (_) => List.generate(9, (i) => i + 1)),
      );

      puzzle.grid[0][0] = 5;

      // Same number in same row should be invalid
      expect(puzzle.isValidPlacement(0, 1, 5), false);

      // Different number should be valid
      expect(puzzle.isValidPlacement(0, 1, 3), true);
    });

    test('isValidPlacement validates column constraints', () {
      final puzzle = SudokuPuzzle(
        grid: List.generate(9, (_) => List.filled(9, null)),
        initialGrid: List.generate(9, (_) => List.filled(9, null)),
        solution: List.generate(9, (_) => List.generate(9, (i) => i + 1)),
      );

      puzzle.grid[0][0] = 5;

      // Same number in same column should be invalid
      expect(puzzle.isValidPlacement(1, 0, 5), false);

      // Different number should be valid
      expect(puzzle.isValidPlacement(1, 0, 3), true);
    });

    test('isValidPlacement validates box constraints', () {
      final puzzle = SudokuPuzzle(
        grid: List.generate(9, (_) => List.filled(9, null)),
        initialGrid: List.generate(9, (_) => List.filled(9, null)),
        solution: List.generate(9, (_) => List.generate(9, (i) => i + 1)),
      );

      puzzle.grid[0][0] = 5;

      // Same number in same 3x3 box should be invalid
      expect(puzzle.isValidPlacement(1, 1, 5), false);

      // Same number outside box should be valid
      expect(puzzle.isValidPlacement(3, 3, 5), true);
    });

    test('isComplete returns true when puzzle matches solution', () {
      final solution = [
        [5, 3, 4, 6, 7, 8, 9, 1, 2],
        [6, 7, 2, 1, 9, 5, 3, 4, 8],
        [1, 9, 8, 3, 4, 2, 5, 6, 7],
        [8, 5, 9, 7, 6, 1, 4, 2, 3],
        [4, 2, 6, 8, 5, 3, 7, 9, 1],
        [7, 1, 3, 9, 2, 4, 8, 5, 6],
        [9, 6, 1, 5, 3, 7, 2, 8, 4],
        [2, 8, 7, 4, 1, 9, 6, 3, 5],
        [3, 4, 5, 2, 8, 6, 1, 7, 9],
      ];

      final puzzle = SudokuPuzzle(
        grid: solution.map((row) => row.map<int?>((v) => v).toList()).toList(),
        initialGrid: List.generate(9, (_) => List.filled(9, null)),
        solution: solution,
      );

      expect(puzzle.isComplete, true);
    });

    test('completedNumbers returns set of fully placed numbers', () {
      final puzzle = SudokuPuzzle(
        grid: List.generate(9, (_) => List.filled(9, null)),
        initialGrid: List.generate(9, (_) => List.filled(9, null)),
        solution: List.generate(9, (_) => List.generate(9, (i) => i + 1)),
      );

      // Place 9 fives
      for (int i = 0; i < 9; i++) {
        puzzle.grid[i][0] = 5;
      }

      expect(puzzle.completedNumbers.contains(5), true);
      expect(puzzle.completedNumbers.contains(3), false);
    });
  });

  group('GameProvider', () {
    test('initial state is correct', () {
      final provider = GameProvider();

      expect(provider.currentPuzzle, isNull);
      expect(provider.elapsedSeconds, 0);
      expect(provider.isPlaying, false);
      expect(provider.mistakes, 0);
      expect(provider.hintsUsed, 0);
      expect(provider.selectedRow, isNull);
      expect(provider.selectedCol, isNull);
      expect(provider.notesMode, false);
    });

    test('tick increments elapsed seconds when playing', () {
      final provider = GameProvider();
      final puzzle = DailyPuzzle(
        id: 'test',
        gameType: GameType.sudoku,
        difficulty: Difficulty.easy,
        date: DateTime.now(),
        puzzleData: {
          'grid': List.generate(9, (_) => List.filled(9, 0)),
          'solution': List.generate(9, (_) => List.filled(9, 1)),
        },
      );

      // Load puzzle to set isPlaying to true
      provider.loadPuzzle(puzzle, restoreSavedState: false);

      expect(provider.elapsedSeconds, 0);

      provider.tick();
      expect(provider.elapsedSeconds, 1);

      provider.tick();
      expect(provider.elapsedSeconds, 2);
    });

    test('tick does not increment when paused', () {
      final provider = GameProvider();
      final puzzle = DailyPuzzle(
        id: 'test',
        gameType: GameType.sudoku,
        difficulty: Difficulty.easy,
        date: DateTime.now(),
        puzzleData: {
          'grid': List.generate(9, (_) => List.filled(9, 0)),
          'solution': List.generate(9, (_) => List.filled(9, 1)),
        },
      );

      provider.loadPuzzle(puzzle, restoreSavedState: false);
      provider.pause();

      provider.tick();
      expect(provider.elapsedSeconds, 0);
    });

    test('selectCell updates selection', () {
      final provider = GameProvider();

      provider.selectCell(3, 5);

      expect(provider.selectedRow, 3);
      expect(provider.selectedCol, 5);
    });

    test('clearSelection resets selection', () {
      final provider = GameProvider();

      provider.selectCell(3, 5);
      provider.clearSelection();

      expect(provider.selectedRow, isNull);
      expect(provider.selectedCol, isNull);
    });

    test('toggleNotesMode toggles notes mode', () {
      final provider = GameProvider();

      expect(provider.notesMode, false);

      provider.toggleNotesMode();
      expect(provider.notesMode, true);

      provider.toggleNotesMode();
      expect(provider.notesMode, false);
    });

    test('reset clears all state', () {
      final provider = GameProvider();
      final puzzle = DailyPuzzle(
        id: 'test',
        gameType: GameType.sudoku,
        difficulty: Difficulty.easy,
        date: DateTime.now(),
        puzzleData: {
          'grid': List.generate(9, (_) => List.filled(9, 0)),
          'solution': List.generate(9, (_) => List.filled(9, 1)),
        },
      );

      provider.loadPuzzle(puzzle, restoreSavedState: false);
      provider.selectCell(3, 5);
      provider.tick();
      provider.toggleNotesMode();

      provider.reset();

      expect(provider.currentPuzzle, isNull);
      expect(provider.elapsedSeconds, 0);
      expect(provider.isPlaying, false);
      expect(provider.selectedRow, isNull);
      expect(provider.selectedCol, isNull);
      expect(provider.notesMode, false);
    });

    test('calculateScore returns valid score', () {
      final provider = GameProvider();
      final puzzle = DailyPuzzle(
        id: 'test',
        gameType: GameType.sudoku,
        difficulty: Difficulty.medium,
        date: DateTime.now(),
        puzzleData: {
          'grid': List.generate(9, (_) => List.filled(9, 0)),
          'solution': List.generate(9, (_) => List.filled(9, 1)),
        },
        targetTime: 600,
      );

      provider.loadPuzzle(puzzle, restoreSavedState: false);

      final score = provider.calculateScore();

      expect(score, greaterThanOrEqualTo(0));
      expect(score, lessThanOrEqualTo(10000));
    });
  });

  group('Word Forge Provider', () {
    test('addWordForgeLetter builds word', () {
      final provider = GameProvider();

      expect(provider.currentWord, isEmpty);

      provider.addWordForgeLetter('W');
      expect(provider.currentWord, 'W');

      provider.addWordForgeLetter('O');
      expect(provider.currentWord, 'WO');

      provider.addWordForgeLetter('R');
      expect(provider.currentWord, 'WOR');

      provider.addWordForgeLetter('D');
      expect(provider.currentWord, 'WORD');
    });

    test('removeWordForgeLetter removes last letter', () {
      final provider = GameProvider();

      provider.addWordForgeLetter('W');
      provider.addWordForgeLetter('O');
      provider.addWordForgeLetter('R');
      provider.addWordForgeLetter('D');

      provider.removeWordForgeLetter();
      expect(provider.currentWord, 'WOR');

      provider.removeWordForgeLetter();
      expect(provider.currentWord, 'WO');
    });

    test('clearWordForgeWord clears all letters', () {
      final provider = GameProvider();

      provider.addWordForgeLetter('W');
      provider.addWordForgeLetter('O');
      provider.addWordForgeLetter('R');
      provider.addWordForgeLetter('D');

      provider.clearWordForgeWord();
      expect(provider.currentWord, isEmpty);
    });

    test('removeWordForgeLetter does nothing on empty word', () {
      final provider = GameProvider();

      provider.removeWordForgeLetter();
      expect(provider.currentWord, isEmpty);
    });
  });

  group('Word Ladder Provider', () {
    test('setWordLadderInput updates input', () {
      final provider = GameProvider();

      expect(provider.wordLadderInput, isEmpty);

      provider.setWordLadderInput('COLD');
      expect(provider.wordLadderInput, 'COLD');
    });

    test('addWordLadderLetter builds input', () {
      final provider = GameProvider();
      final puzzle = DailyPuzzle(
        id: 'test',
        gameType: GameType.wordLadder,
        difficulty: Difficulty.easy,
        date: DateTime.now(),
        puzzleData: {
          'startWord': 'COLD',
          'targetWord': 'WARM',
          'wordLength': 4,
        },
      );

      provider.loadPuzzle(puzzle, restoreSavedState: false);

      provider.addWordLadderLetter('C');
      provider.addWordLadderLetter('O');
      provider.addWordLadderLetter('R');
      provider.addWordLadderLetter('D');

      expect(provider.wordLadderInput, 'CORD');
    });

    test('deleteWordLadderLetter removes last letter', () {
      final provider = GameProvider();

      provider.setWordLadderInput('CORD');

      provider.deleteWordLadderLetter();
      expect(provider.wordLadderInput, 'COR');
    });

    test('clearWordLadderInput clears input', () {
      final provider = GameProvider();

      provider.setWordLadderInput('CORD');

      provider.clearWordLadderInput();
      expect(provider.wordLadderInput, isEmpty);
    });
  });
}
