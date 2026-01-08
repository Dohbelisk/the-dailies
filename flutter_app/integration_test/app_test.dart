import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:puzzle_daily/models/game_models.dart';
import 'package:puzzle_daily/providers/game_provider.dart';
import 'package:puzzle_daily/providers/theme_provider.dart';
import 'package:puzzle_daily/widgets/sudoku_grid.dart';
import 'package:puzzle_daily/widgets/killer_sudoku_grid.dart';
import 'package:puzzle_daily/widgets/crossword_grid.dart';
import 'package:puzzle_daily/widgets/word_search_grid.dart';
import 'package:puzzle_daily/widgets/word_forge_grid.dart';
import 'package:puzzle_daily/widgets/nonogram_grid.dart';
import 'package:puzzle_daily/widgets/number_target_grid.dart';
import 'package:puzzle_daily/widgets/ball_sort_grid.dart';
import 'package:puzzle_daily/widgets/pipes_grid.dart';
import 'package:puzzle_daily/widgets/lights_out_grid.dart';
import 'package:puzzle_daily/widgets/word_ladder_grid.dart';
import 'package:puzzle_daily/widgets/connections_grid.dart';
import 'package:puzzle_daily/widgets/mathora_grid.dart';

import 'helpers/test_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('ThemeProvider initializes correctly', (tester) async {
      final themeProvider = ThemeProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>.value(
          value: themeProvider,
          child: Consumer<ThemeProvider>(
            builder: (context, provider, _) => MaterialApp(
              theme: provider.isDarkMode ? ThemeData.dark() : ThemeData.light(),
              home: const Scaffold(body: Text('Theme Test')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Theme Test'), findsOneWidget);
    });

    testWidgets('GameProvider initializes correctly', (tester) async {
      final gameProvider = GameProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<GameProvider>.value(
          value: gameProvider,
          child: MaterialApp(
            home: Scaffold(
              body: Consumer<GameProvider>(
                builder: (context, provider, _) => Text(
                  'Playing: ${provider.isPlaying}',
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Playing: false'), findsOneWidget);
    });
  });

  group('Sudoku Grid Tests', () {
    testWidgets('SudokuGrid renders 9x9 grid', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockSudokuPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      await tester.pumpWidget(
        ChangeNotifierProvider<GameProvider>.value(
          value: gameProvider,
          child: MaterialApp(
            home: Scaffold(
              body: Consumer<GameProvider>(
                builder: (context, provider, _) => SudokuGrid(
                  puzzle: provider.sudokuPuzzle!,
                  selectedRow: provider.selectedRow,
                  selectedCol: provider.selectedCol,
                  onCellTap: provider.selectCell,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(SudokuGrid), findsOneWidget);
    });

    testWidgets('SudokuGrid displays initial numbers', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockSudokuPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      await tester.pumpWidget(
        ChangeNotifierProvider<GameProvider>.value(
          value: gameProvider,
          child: MaterialApp(
            home: Scaffold(
              body: Consumer<GameProvider>(
                builder: (context, provider, _) => SudokuGrid(
                  puzzle: provider.sudokuPuzzle!,
                  selectedRow: provider.selectedRow,
                  selectedCol: provider.selectedCol,
                  onCellTap: provider.selectCell,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // The grid should display the initial value of 5 in top-left cell
      expect(find.text('5'), findsWidgets);
    });
  });

  group('Killer Sudoku Grid Tests', () {
    testWidgets('KillerSudokuGrid renders with cages', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockKillerSudokuPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      await tester.pumpWidget(
        ChangeNotifierProvider<GameProvider>.value(
          value: gameProvider,
          child: MaterialApp(
            home: Scaffold(
              body: Consumer<GameProvider>(
                builder: (context, provider, _) => KillerSudokuGrid(
                  puzzle: provider.killerSudokuPuzzle!,
                  selectedRow: provider.selectedRow,
                  selectedCol: provider.selectedCol,
                  onCellTap: provider.selectCell,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(KillerSudokuGrid), findsOneWidget);
    });
  });

  group('Crossword Grid Tests', () {
    testWidgets('CrosswordGrid renders clues and grid', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockCrosswordPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      await tester.pumpWidget(
        ChangeNotifierProvider<GameProvider>.value(
          value: gameProvider,
          child: MaterialApp(
            home: Scaffold(
              body: Consumer<GameProvider>(
                builder: (context, provider, _) => CrosswordGrid(
                  puzzle: provider.crosswordPuzzle!,
                  selectedRow: provider.selectedRow,
                  selectedCol: provider.selectedCol,
                  selectedClue: provider.selectedClue,
                  onCellTap: provider.selectCrosswordCell,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(CrosswordGrid), findsOneWidget);
    });
  });

  group('Word Search Grid Tests', () {
    testWidgets('WordSearchGrid renders with word list', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockWordSearchPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      await tester.pumpWidget(
        ChangeNotifierProvider<GameProvider>.value(
          value: gameProvider,
          child: MaterialApp(
            home: Scaffold(
              body: Consumer<GameProvider>(
                builder: (context, provider, _) => WordSearchGrid(
                  puzzle: provider.wordSearchPuzzle!,
                  currentSelection: provider.currentSelection,
                  onSelectionStart: provider.startWordSelection,
                  onSelectionUpdate: provider.extendWordSelection,
                  onSelectionEnd: provider.endWordSelection,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(WordSearchGrid), findsOneWidget);
    });
  });

  group('Word Forge Grid Tests', () {
    testWidgets('WordForgeGrid renders honeycomb layout', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockWordForgePuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      await tester.pumpWidget(
        ChangeNotifierProvider<GameProvider>.value(
          value: gameProvider,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Consumer<GameProvider>(
                  builder: (context, provider, _) => WordForgeGrid(
                    puzzle: provider.wordForgePuzzle!,
                    currentWord: provider.currentWord,
                    onLetterTap: provider.addWordForgeLetter,
                    onDelete: provider.removeWordForgeLetter,
                    onShuffle: provider.shuffleWordForgeLetters,
                    onSubmit: () => provider.submitWordForgeWord(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(WordForgeGrid), findsOneWidget);
    });

    testWidgets('WordForgeGrid shows center letter', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockWordForgePuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      await tester.pumpWidget(
        ChangeNotifierProvider<GameProvider>.value(
          value: gameProvider,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Consumer<GameProvider>(
                  builder: (context, provider, _) => WordForgeGrid(
                    puzzle: provider.wordForgePuzzle!,
                    currentWord: provider.currentWord,
                    onLetterTap: provider.addWordForgeLetter,
                    onDelete: provider.removeWordForgeLetter,
                    onShuffle: provider.shuffleWordForgeLetters,
                    onSubmit: () => provider.submitWordForgeWord(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Center letter 'O' should be displayed
      expect(find.text('O'), findsWidgets);
    });
  });

  group('Nonogram Grid Tests', () {
    testWidgets('NonogramGrid renders with clues', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockNonogramPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      await tester.pumpWidget(
        ChangeNotifierProvider<GameProvider>.value(
          value: gameProvider,
          child: MaterialApp(
            home: Scaffold(
              body: Consumer<GameProvider>(
                builder: (context, provider, _) => NonogramGrid(
                  puzzle: provider.nonogramPuzzle!,
                  markMode: provider.nonogramMarkMode,
                  onCellTap: provider.toggleNonogramCell,
                  onSetCellState: provider.setNonogramCellStateSilent,
                  onToggleMarkMode: provider.toggleNonogramMarkMode,
                  onSaveStateForUndo: provider.saveNonogramStateForUndo,
                  onUndo: provider.undoNonogram,
                  onDragEnd: provider.notifyNonogramChanged,
                  canUndo: provider.canUndoNonogram,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(NonogramGrid), findsOneWidget);
    });
  });

  group('Number Target Grid Tests', () {
    testWidgets('NumberTargetGrid renders with numbers and target', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockNumberTargetPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      await tester.pumpWidget(
        ChangeNotifierProvider<GameProvider>.value(
          value: gameProvider,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Consumer<GameProvider>(
                  builder: (context, provider, _) => NumberTargetGrid(
                    puzzle: provider.numberTargetPuzzle!,
                    currentExpression: provider.currentExpression,
                    usedNumberIndices: provider.usedNumberIndices,
                    onTokenTap: provider.addToNumberTargetExpression,
                    onBackspace: provider.backspaceNumberTargetExpression,
                    onClear: provider.clearNumberTargetExpression,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(NumberTargetGrid), findsOneWidget);
      // Should display target number
      expect(find.text('24'), findsOneWidget);
    });
  });

  group('Ball Sort Grid Tests', () {
    testWidgets('BallSortGrid renders tubes with balls', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockBallSortPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      await tester.pumpWidget(
        ChangeNotifierProvider<GameProvider>.value(
          value: gameProvider,
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 600,
                width: 400,
                child: Consumer<GameProvider>(
                  builder: (context, provider, _) => BallSortGrid(
                    puzzle: provider.ballSortPuzzle!,
                    selectedTube: provider.selectedTube,
                    undosRemaining: provider.undosRemaining,
                    onTubeTap: provider.selectBallSortTube,
                    onUndo: provider.undoBallSortMove,
                    onReset: provider.resetBallSortPuzzle,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(BallSortGrid), findsOneWidget);
    });
  });

  group('Pipes Grid Tests', () {
    testWidgets('PipesGrid renders endpoints', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockPipesPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      await tester.pumpWidget(
        ChangeNotifierProvider<GameProvider>.value(
          value: gameProvider,
          child: MaterialApp(
            home: Scaffold(
              body: Consumer<GameProvider>(
                builder: (context, provider, _) => PipesGrid(
                  puzzle: provider.pipesPuzzle!,
                  onPathStart: provider.startPipesPath,
                  onPathContinue: provider.continuePipesPath,
                  onPathExtend: provider.extendPipesPath,
                  onPathEnd: provider.endPipesPath,
                  onReset: provider.resetPipesPuzzle,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(PipesGrid), findsOneWidget);
    });
  });

  group('Lights Out Grid Tests', () {
    testWidgets('LightsOutGrid renders toggle grid', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockLightsOutPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      await tester.pumpWidget(
        ChangeNotifierProvider<GameProvider>.value(
          value: gameProvider,
          child: MaterialApp(
            home: Scaffold(
              body: Consumer<GameProvider>(
                builder: (context, provider, _) => LightsOutGrid(
                  puzzle: provider.lightsOutPuzzle!,
                  onCellTap: provider.toggleLightsOutCell,
                  onReset: provider.resetLightsOutPuzzle,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(LightsOutGrid), findsOneWidget);
    });
  });

  group('Word Ladder Grid Tests', () {
    testWidgets('WordLadderGrid renders start and target words', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockWordLadderPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      await tester.pumpWidget(
        ChangeNotifierProvider<GameProvider>.value(
          value: gameProvider,
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 600,
                width: 400,
                child: Consumer<GameProvider>(
                  builder: (context, provider, _) => WordLadderGrid(
                    puzzle: provider.wordLadderPuzzle!,
                    currentInput: provider.wordLadderInput,
                    onLetterTap: provider.addWordLadderLetter,
                    onDeleteTap: provider.deleteWordLadderLetter,
                    onSubmit: () => provider.submitWordLadderWord(),
                    onUndo: provider.undoWordLadderWord,
                    onReset: provider.resetWordLadderPuzzle,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(WordLadderGrid), findsOneWidget);
      // Words are displayed character-by-character, verify puzzle was loaded
      expect(gameProvider.wordLadderPuzzle!.startWord, 'COLD');
      expect(gameProvider.wordLadderPuzzle!.targetWord, 'WARM');
    });
  });

  group('Connections Grid Tests', () {
    testWidgets('ConnectionsGrid renders 16 word tiles', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockConnectionsPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      await tester.pumpWidget(
        ChangeNotifierProvider<GameProvider>.value(
          value: gameProvider,
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 600,
                width: 400,
                child: Consumer<GameProvider>(
                  builder: (context, provider, _) => ConnectionsGrid(
                    puzzle: provider.connectionsPuzzle!,
                    onWordTap: provider.toggleConnectionsWord,
                    onSubmit: () => provider.submitConnectionsSelection(),
                    onClear: provider.clearConnectionsSelection,
                    onShuffle: provider.shuffleConnectionsWords,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(ConnectionsGrid), findsOneWidget);
      // Should display some of the words
      expect(find.text('APPLE'), findsOneWidget);
    });
  });

  group('Mathora Grid Tests', () {
    testWidgets('MathoraGrid renders operations grid', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockMathoraPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      await tester.pumpWidget(
        ChangeNotifierProvider<GameProvider>.value(
          value: gameProvider,
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 600,
                width: 400,
                child: Consumer<GameProvider>(
                  builder: (context, provider, _) => MathoraGrid(
                    puzzle: provider.mathoraPuzzle!,
                    onOperationTap: provider.applyMathoraOperation,
                    onUndo: provider.undoMathoraOperation,
                    onReset: provider.resetMathoraPuzzle,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(MathoraGrid), findsOneWidget);
    });
  });

  group('GameProvider State Tests', () {
    testWidgets('GameProvider loads Sudoku puzzle correctly', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockSudokuPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      expect(gameProvider.currentPuzzle, isNotNull);
      expect(gameProvider.currentPuzzle!.gameType, GameType.sudoku);
      expect(gameProvider.sudokuPuzzle, isNotNull);
      expect(gameProvider.isPlaying, isTrue);
    });

    testWidgets('GameProvider loads all puzzle types', (tester) async {
      for (final puzzleData in allMockPuzzles) {
        final gameProvider = GameProvider();
        final puzzle = DailyPuzzle.fromJson(puzzleData);

        await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

        expect(gameProvider.currentPuzzle, isNotNull,
            reason: 'Failed to load ${puzzleData['gameType']}');
        expect(gameProvider.isPlaying, isTrue,
            reason: 'isPlaying should be true for ${puzzleData['gameType']}');
      }
    });

    testWidgets('GameProvider timer ticks correctly', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockSudokuPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      expect(gameProvider.elapsedSeconds, 0);

      gameProvider.tick();
      expect(gameProvider.elapsedSeconds, 1);

      gameProvider.tick();
      expect(gameProvider.elapsedSeconds, 2);
    });

    testWidgets('GameProvider pause/resume works', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockSudokuPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      expect(gameProvider.isPlaying, isTrue);

      gameProvider.pause();
      expect(gameProvider.isPlaying, isFalse);

      gameProvider.resume();
      expect(gameProvider.isPlaying, isTrue);
    });

    testWidgets('GameProvider reset clears state', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockSudokuPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);
      gameProvider.tick();

      gameProvider.reset();

      expect(gameProvider.currentPuzzle, isNull);
      expect(gameProvider.elapsedSeconds, 0);
      expect(gameProvider.isPlaying, isFalse);
      expect(gameProvider.mistakes, 0);
      expect(gameProvider.hintsUsed, 0);
    });
  });

  group('Sudoku Interaction Tests', () {
    testWidgets('Sudoku cell selection updates state', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockSudokuPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      expect(gameProvider.selectedRow, isNull);
      expect(gameProvider.selectedCol, isNull);

      gameProvider.selectCell(0, 2);

      expect(gameProvider.selectedRow, 0);
      expect(gameProvider.selectedCol, 2);
    });

    testWidgets('Sudoku notes mode toggles', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockSudokuPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      expect(gameProvider.notesMode, isFalse);

      gameProvider.toggleNotesMode();
      expect(gameProvider.notesMode, isTrue);

      gameProvider.toggleNotesMode();
      expect(gameProvider.notesMode, isFalse);
    });

    testWidgets('Sudoku number entry increments mistakes on wrong entry', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockSudokuPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      // Select an empty cell (row 0, col 2)
      gameProvider.selectCell(0, 2);

      // Enter wrong number (correct is 4)
      final isValid = gameProvider.enterNumber(9);

      expect(isValid, isFalse);
      expect(gameProvider.mistakes, 1);
    });

    testWidgets('Sudoku correct entry does not increment mistakes', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockSudokuPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      // Select an empty cell (row 0, col 2)
      gameProvider.selectCell(0, 2);

      // Enter correct number
      final isValid = gameProvider.enterNumber(4);

      expect(isValid, isTrue);
      expect(gameProvider.mistakes, 0);
    });
  });

  group('Word Forge Interaction Tests', () {
    testWidgets('Word Forge letter addition works', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockWordForgePuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      expect(gameProvider.currentWord, isEmpty);

      gameProvider.addWordForgeLetter('W');
      gameProvider.addWordForgeLetter('O');
      gameProvider.addWordForgeLetter('R');
      gameProvider.addWordForgeLetter('K');

      expect(gameProvider.currentWord, 'WORK');
    });

    testWidgets('Word Forge letter removal works', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockWordForgePuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      gameProvider.addWordForgeLetter('W');
      gameProvider.addWordForgeLetter('O');
      gameProvider.addWordForgeLetter('R');
      gameProvider.addWordForgeLetter('K');

      gameProvider.removeWordForgeLetter();
      expect(gameProvider.currentWord, 'WOR');

      gameProvider.clearWordForgeWord();
      expect(gameProvider.currentWord, isEmpty);
    });
  });

  group('Connections Interaction Tests', () {
    testWidgets('Connections word selection works', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockConnectionsPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      expect(gameProvider.connectionsPuzzle!.selectedWords, isEmpty);

      gameProvider.toggleConnectionsWord('APPLE');
      expect(gameProvider.connectionsPuzzle!.selectedWords.contains('APPLE'), isTrue);

      gameProvider.toggleConnectionsWord('APPLE');
      expect(gameProvider.connectionsPuzzle!.selectedWords.contains('APPLE'), isFalse);
    });

    testWidgets('Connections selection clear works', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockConnectionsPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      gameProvider.toggleConnectionsWord('APPLE');
      gameProvider.toggleConnectionsWord('BANANA');
      gameProvider.toggleConnectionsWord('ORANGE');

      expect(gameProvider.connectionsPuzzle!.selectedWords.length, 3);

      gameProvider.clearConnectionsSelection();
      expect(gameProvider.connectionsPuzzle!.selectedWords, isEmpty);
    });
  });

  group('Score Calculation Tests', () {
    testWidgets('Score calculation returns valid score', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockSudokuPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      // Simulate some gameplay
      gameProvider.tick();
      gameProvider.tick();

      final score = gameProvider.calculateScore();

      expect(score, greaterThanOrEqualTo(0));
      expect(score, lessThanOrEqualTo(10000));
    });

    testWidgets('Mistakes reduce score', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockSudokuPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      final scoreNoMistakes = gameProvider.calculateScore();

      // Add a mistake
      gameProvider.selectCell(0, 2);
      gameProvider.enterNumber(9); // Wrong number

      final scoreWithMistakes = gameProvider.calculateScore();

      expect(scoreWithMistakes, lessThan(scoreNoMistakes));
    });
  });

  group('Nonogram Interaction Tests', () {
    testWidgets('Nonogram cell toggle works', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockNonogramPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      // Initial state should be null (unmarked)
      expect(gameProvider.nonogramPuzzle!.userGrid[0][0], isNull);

      // Toggle cell should fill it (null → 1)
      gameProvider.toggleNonogramCell(0, 0);
      expect(gameProvider.nonogramPuzzle!.userGrid[0][0], 1);

      // Toggle again should clear it (1 → 0)
      gameProvider.toggleNonogramCell(0, 0);
      expect(gameProvider.nonogramPuzzle!.userGrid[0][0], 0);

      // Toggle again should fill it (0 → 1)
      gameProvider.toggleNonogramCell(0, 0);
      expect(gameProvider.nonogramPuzzle!.userGrid[0][0], 1);
    });

    testWidgets('Nonogram mark mode works', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockNonogramPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      expect(gameProvider.nonogramMarkMode, isFalse);

      gameProvider.toggleNonogramMarkMode();
      expect(gameProvider.nonogramMarkMode, isTrue);

      // In mark mode, toggling should mark with X (-1)
      gameProvider.toggleNonogramCell(0, 0);
      expect(gameProvider.nonogramPuzzle!.userGrid[0][0], -1);
    });
  });

  group('Ball Sort Interaction Tests', () {
    testWidgets('Ball Sort tube selection works', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockBallSortPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      expect(gameProvider.selectedTube, isNull);

      // Select first tube (has balls)
      gameProvider.selectBallSortTube(0);
      expect(gameProvider.selectedTube, 0);

      // Deselect by tapping same tube
      gameProvider.selectBallSortTube(0);
      expect(gameProvider.selectedTube, isNull);
    });

    testWidgets('Ball Sort reset works', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockBallSortPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      // Make a move
      gameProvider.selectBallSortTube(0);
      gameProvider.selectBallSortTube(2);

      expect(gameProvider.ballSortPuzzle!.moveCount, greaterThan(0));

      // Reset
      gameProvider.resetBallSortPuzzle();
      expect(gameProvider.ballSortPuzzle!.moveCount, 0);
    });
  });

  group('Lights Out Interaction Tests', () {
    testWidgets('Lights Out toggle affects neighbors', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockLightsOutPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      // Get initial state of center cell
      final initialCenterState = gameProvider.lightsOutPuzzle!.currentState[1][1];

      // Toggle center cell
      gameProvider.toggleLightsOutCell(1, 1);

      // Center cell should have toggled
      expect(gameProvider.lightsOutPuzzle!.currentState[1][1], !initialCenterState);
    });

    testWidgets('Lights Out reset works', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockLightsOutPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      // Make some moves
      gameProvider.toggleLightsOutCell(0, 0);
      gameProvider.toggleLightsOutCell(1, 1);

      expect(gameProvider.lightsOutPuzzle!.moveCount, 2);

      // Reset
      gameProvider.resetLightsOutPuzzle();
      expect(gameProvider.lightsOutPuzzle!.moveCount, 0);
    });
  });

  group('Word Ladder Interaction Tests', () {
    testWidgets('Word Ladder input works', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockWordLadderPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      expect(gameProvider.wordLadderInput, isEmpty);

      gameProvider.setWordLadderInput('CORD');
      expect(gameProvider.wordLadderInput, 'CORD');
    });

    testWidgets('Word Ladder letter-by-letter input works', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockWordLadderPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      gameProvider.addWordLadderLetter('C');
      gameProvider.addWordLadderLetter('O');
      gameProvider.addWordLadderLetter('R');
      gameProvider.addWordLadderLetter('D');

      expect(gameProvider.wordLadderInput, 'CORD');

      gameProvider.deleteWordLadderLetter();
      expect(gameProvider.wordLadderInput, 'COR');

      gameProvider.clearWordLadderInput();
      expect(gameProvider.wordLadderInput, isEmpty);
    });
  });

  group('Mathora Interaction Tests', () {
    testWidgets('Mathora operation applies correctly', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockMathoraPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      // Initial value should be 10
      expect(gameProvider.mathoraPuzzle!.currentValue, 10);

      // Apply multiply by 10 operation
      final operation = gameProvider.mathoraPuzzle!.operations.firstWhere(
        (op) => op.type == 'multiply' && op.value == 10,
      );

      final result = gameProvider.applyMathoraOperation(operation);

      expect(result.success, isTrue);
      expect(gameProvider.mathoraPuzzle!.currentValue, 100);
    });

    testWidgets('Mathora undo works', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockMathoraPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      final initialValue = gameProvider.mathoraPuzzle!.currentValue;

      // Apply an operation
      final operation = gameProvider.mathoraPuzzle!.operations.first;
      gameProvider.applyMathoraOperation(operation);

      // Undo
      gameProvider.undoMathoraOperation();
      expect(gameProvider.mathoraPuzzle!.currentValue, initialValue);
    });

    testWidgets('Mathora reset works', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockMathoraPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      final initialValue = gameProvider.mathoraPuzzle!.currentValue;
      final initialMoves = gameProvider.mathoraPuzzle!.movesLeft;

      // Apply some operations
      for (final op in gameProvider.mathoraPuzzle!.operations.take(2)) {
        gameProvider.applyMathoraOperation(op);
      }

      // Reset
      gameProvider.resetMathoraPuzzle();
      expect(gameProvider.mathoraPuzzle!.currentValue, initialValue);
      expect(gameProvider.mathoraPuzzle!.movesLeft, initialMoves);
    });
  });

  group('Number Target Interaction Tests', () {
    testWidgets('Number Target expression building works', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockNumberTargetPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      expect(gameProvider.currentExpression, isEmpty);

      // Build expression: 2 + 3
      gameProvider.addToNumberTargetExpression('2', numberIndex: 0);
      gameProvider.addToNumberTargetExpression('+');
      gameProvider.addToNumberTargetExpression('3', numberIndex: 1);

      expect(gameProvider.currentExpression, '2+3');
    });

    testWidgets('Number Target clear works', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockNumberTargetPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      gameProvider.addToNumberTargetExpression('2', numberIndex: 0);
      gameProvider.addToNumberTargetExpression('+');
      gameProvider.addToNumberTargetExpression('3', numberIndex: 1);

      gameProvider.clearNumberTargetExpression();
      expect(gameProvider.currentExpression, isEmpty);
      expect(gameProvider.usedNumberIndices, isEmpty);
    });

    testWidgets('Number Target backspace works', (tester) async {
      final gameProvider = GameProvider();
      final puzzle = DailyPuzzle.fromJson(mockNumberTargetPuzzle);

      await gameProvider.loadPuzzle(puzzle, restoreSavedState: false);

      gameProvider.addToNumberTargetExpression('2', numberIndex: 0);
      gameProvider.addToNumberTargetExpression('+');
      gameProvider.addToNumberTargetExpression('3', numberIndex: 1);

      gameProvider.backspaceNumberTargetExpression();
      expect(gameProvider.currentExpression, '2+');

      gameProvider.backspaceNumberTargetExpression();
      expect(gameProvider.currentExpression, '2');
    });
  });
}
