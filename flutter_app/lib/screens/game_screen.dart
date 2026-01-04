import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';

import '../models/game_models.dart';
import '../providers/game_provider.dart';
import '../services/game_service.dart';
import '../services/hint_service.dart';
import '../services/audio_service.dart';
import '../services/challenge_service.dart';
import '../services/api_service.dart';
import '../services/game_state_service.dart';
import '../widgets/sudoku_grid.dart';
import '../widgets/killer_sudoku_grid.dart';
import '../widgets/crossword_grid.dart';
import '../widgets/word_search_grid.dart';
import '../widgets/word_forge_grid.dart';
import '../widgets/nonogram_grid.dart';
import '../widgets/number_target_grid.dart';
import '../widgets/ball_sort_grid.dart';
import '../widgets/pipes_grid.dart';
import '../widgets/lights_out_grid.dart';
import '../widgets/word_ladder_grid.dart';
import '../widgets/connections_grid.dart';
import '../widgets/mathora_grid.dart';
import '../widgets/number_pad.dart';
import '../widgets/keyboard_input.dart';
import '../widgets/game_timer.dart';
import '../widgets/completion_dialog.dart';
import '../widgets/feedback_dialog.dart';
import '../models/feedback_models.dart';
import 'settings_screen.dart';

class GameScreen extends StatefulWidget {
  final DailyPuzzle? puzzle;
  final String? puzzleId;
  final String? challengeId;

  const GameScreen({
    super.key,
    this.puzzle,
    this.puzzleId,
    this.challengeId,
  }) : assert(puzzle != null || puzzleId != null, 'Either puzzle or puzzleId must be provided');

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  Timer? _timer;
  bool _isPaused = false;
  final HintService _hintService = HintService();
  final AudioService _audioService = AudioService();

  DailyPuzzle? _puzzle;
  bool _isLoading = true;
  String? _loadError;

  // Crossword clue list controllers
  TabController? _cluesTabController;
  final ScrollController _acrossScrollController = ScrollController();
  final ScrollController _downScrollController = ScrollController();
  CrosswordClue? _previousSelectedClue;

  bool get isChallenge => widget.challengeId != null;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePuzzle();
    });
  }

  Future<void> _initializePuzzle() async {
    if (widget.puzzle != null) {
      // Puzzle provided directly
      _puzzle = widget.puzzle;
      _loadPuzzleIntoProvider();
    } else if (widget.puzzleId != null) {
      // Need to fetch puzzle by ID
      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        final puzzle = await apiService.getPuzzle(widget.puzzleId!);
        if (puzzle != null) {
          _puzzle = puzzle;
          _loadPuzzleIntoProvider();
        } else {
          setState(() {
            _loadError = 'Puzzle not found';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _loadError = 'Failed to load puzzle: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadPuzzleIntoProvider() async {
    // Check if there's saved state for this puzzle
    final hasSavedState = await GameStateService.hasInProgressState(
      gameType: _puzzle!.gameType,
      puzzleDate: _puzzle!.date,
    );

    if (hasSavedState && mounted) {
      // Show dialog asking to continue or restart
      final shouldContinue = await _showContinueOrRestartDialog();
      if (!mounted) return;

      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      if (shouldContinue) {
        // Load with saved state
        await gameProvider.loadPuzzle(_puzzle!, restoreSavedState: true);
      } else {
        // Clear saved state and start fresh
        await GameStateService.clearGameState(
          gameType: _puzzle!.gameType,
          puzzleDate: _puzzle!.date,
        );
        await gameProvider.loadPuzzle(_puzzle!, restoreSavedState: false);
      }
    } else {
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      await gameProvider.loadPuzzle(_puzzle!);
    }

    setState(() {
      _isLoading = false;
    });
    _startTimer();
  }

  Future<bool> _showContinueOrRestartDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.play_circle_outline_rounded,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              const Text('Continue Game?'),
            ],
          ),
          content: const Text(
            'You have a game in progress. Would you like to continue where you left off or start a new game?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Start New',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
    return result ?? true; // Default to continue if dialog dismissed
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confettiController.dispose();
    _cluesTabController?.dispose();
    _acrossScrollController.dispose();
    _downScrollController.dispose();
    super.dispose();
  }

  Future<void> _saveAndExit() async {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    if (gameProvider.isPlaying) {
      await gameProvider.saveState();
    }
    gameProvider.reset();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused && mounted) {
        final gameProvider = Provider.of<GameProvider>(context, listen: false);
        gameProvider.tick();
        _checkCompletion();
      }
    });
  }

  Future<void> _checkCompletion() async {
    if (_puzzle == null) return;

    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    bool isComplete = false;

    switch (_puzzle!.gameType) {
      case GameType.sudoku:
      case GameType.killerSudoku:
        isComplete = await gameProvider.checkSudokuComplete();
        break;
      case GameType.crossword:
        isComplete = await gameProvider.checkCrosswordComplete();
        break;
      case GameType.wordSearch:
        isComplete = await gameProvider.checkWordSearchComplete();
        break;
      case GameType.wordForge:
        isComplete = await gameProvider.checkWordForgeComplete();
        break;
      case GameType.nonogram:
        isComplete = await gameProvider.checkNonogramComplete();
        break;
      case GameType.numberTarget:
        isComplete = await gameProvider.checkNumberTargetComplete();
        break;
      case GameType.ballSort:
        isComplete = await gameProvider.checkBallSortComplete();
        break;
      case GameType.pipes:
        isComplete = await gameProvider.checkPipesComplete();
        break;
      case GameType.lightsOut:
        isComplete = await gameProvider.checkLightsOutComplete();
        break;
      case GameType.wordLadder:
        isComplete = await gameProvider.checkWordLadderComplete();
        break;
      case GameType.connections:
        isComplete = await gameProvider.checkConnectionsComplete();
        break;
      case GameType.mathora:
        isComplete = await gameProvider.checkMathoraComplete();
        break;
    }

    if (isComplete) {
      _timer?.cancel();
      _confettiController.play();
      _audioService.playComplete();
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    if (_puzzle == null) return;

    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final score = gameProvider.calculateScore();

    // Submit score to regular endpoint
    final gameService = Provider.of<GameService>(context, listen: false);
    gameService.submitScore(
      _puzzle!.id,
      gameProvider.elapsedSeconds,
      score,
    );

    // If this is a challenge, also submit to challenge endpoint
    if (isChallenge) {
      _submitChallengeResult(score, gameProvider.elapsedSeconds, gameProvider.mistakes);
    }

    // Show completion dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CompletionDialog(
        puzzle: _puzzle!,
        time: gameProvider.elapsedSeconds,
        score: score,
        mistakes: gameProvider.mistakes,
        hintsUsed: gameProvider.hintsUsed,
        isChallenge: isChallenge,
      ),
    );
  }

  Future<void> _submitChallengeResult(int score, int time, int mistakes) async {
    try {
      final challengeService = Provider.of<ChallengeService>(context, listen: false);
      await challengeService.submitResult(
        challengeId: widget.challengeId!,
        score: score,
        time: time,
        mistakes: mistakes,
      );
    } catch (e) {
      // Silently fail - the user already sees their completion
      debugPrint('Failed to submit challenge result: $e');
    }
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    if (_isPaused) {
      gameProvider.pause();
    } else {
      gameProvider.resume();
    }
  }

  void _showGameInstructions(BuildContext context) {
    final theme = Theme.of(context);
    final instructions = _getGameInstructions(_puzzle!.gameType);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.help_outline_rounded,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'How to Play ${_puzzle!.gameType.displayName}',
                style: theme.textTheme.titleLarge,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                instructions.objective,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ...instructions.steps.map((step) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${instructions.steps.indexOf(step) + 1}',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        step,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )),
              if (instructions.tips != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          instructions.tips!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  _GameInstructions _getGameInstructions(GameType gameType) {
    switch (gameType) {
      case GameType.sudoku:
        return _GameInstructions(
          objective: 'Fill the 9×9 grid so that each row, column, and 3×3 box contains the numbers 1-9.',
          steps: [
            'Tap a cell to select it',
            'Use the number pad to enter a number',
            'Use notes mode to add pencil marks for possible numbers',
            'Numbers turn red if they conflict with existing numbers',
            'Complete the grid without mistakes to finish',
          ],
          tips: 'Look for cells where only one number is possible. Start with rows, columns, or boxes that are nearly complete.',
        );
      case GameType.killerSudoku:
        return _GameInstructions(
          objective: 'Fill the grid like Sudoku, but also ensure numbers in each colored cage add up to the cage total.',
          steps: [
            'Each cage (colored region) shows a target sum',
            'Numbers in a cage must add up to that sum',
            'No number can repeat within a cage',
            'Standard Sudoku rules also apply (1-9 in rows, columns, boxes)',
            'Use the calculator button to check cage combinations',
          ],
          tips: 'Small cages are great starting points. A 2-cell cage with sum 3 can only be 1+2.',
        );
      case GameType.crossword:
        return _GameInstructions(
          objective: 'Fill in the white squares with letters to form words based on the clues.',
          steps: [
            'Tap a cell to select it and see the clue',
            'Use the keyboard to type letters',
            'Tap a filled cell again to switch between across and down',
            'Select clues from the list below to jump to that word',
            'Complete all words to finish the puzzle',
          ],
          tips: 'Start with clues you know for certain. Intersecting letters will help solve other words.',
        );
      case GameType.wordSearch:
        return _GameInstructions(
          objective: 'Find all the hidden words in the letter grid.',
          steps: [
            'Words can be horizontal, vertical, or diagonal',
            'Words can read forwards or backwards',
            'Drag your finger across letters to select a word',
            'Found words are crossed off the list below',
            'Find all words to complete the puzzle',
          ],
          tips: 'Look for uncommon letters like Q, Z, X, or J first – they\'re easier to spot.',
        );
      case GameType.wordForge:
        return _GameInstructions(
          objective: 'Create as many words as possible using the 7 letters. Every word must include the center letter.',
          steps: [
            'Tap letters to build a word (4+ letters required)',
            'The center letter (highlighted) must be in every word',
            'Tap Submit to check your word',
            'Pangrams use all 7 letters and score bonus points',
            'Reach Genius level (70% of max score) to complete',
          ],
          tips: 'Try adding common prefixes (UN-, RE-) and suffixes (-ING, -ED, -ER) to find more words.',
        );
      case GameType.nonogram:
        return _GameInstructions(
          objective: 'Reveal the hidden picture by filling in cells according to the number clues.',
          steps: [
            'Numbers on the left show consecutive filled cells in each row',
            'Numbers on top show consecutive filled cells in each column',
            'Tap a cell to fill it in',
            'Use mark mode (X) to mark cells you know are empty',
            'Complete the pattern to reveal the picture',
          ],
          tips: 'Start with rows or columns where the numbers add up close to the total. Look for overlaps.',
        );
      case GameType.numberTarget:
        return _GameInstructions(
          objective: 'Use the given numbers and operations to reach the target number.',
          steps: [
            'Tap numbers and operators to build an expression',
            'Each number can only be used once',
            'Use +, -, ×, ÷ operations',
            'Tap = to check your answer',
            'Reach the exact target to win',
          ],
          tips: 'You don\'t have to use all numbers. Sometimes a simpler solution works best.',
        );
      case GameType.ballSort:
        return _GameInstructions(
          objective: 'Sort the colored balls so each tube contains balls of only one color.',
          steps: [
            'Tap a tube to pick up the top ball',
            'Tap another tube to drop it there',
            'You can only place a ball on the same color or in an empty tube',
            'Use empty tubes to temporarily hold balls',
            'Fill each tube with one color to complete',
          ],
          tips: 'Plan ahead! Getting a single color started in one tube makes the rest easier.',
        );
      case GameType.pipes:
        return _GameInstructions(
          objective: 'Connect matching colored endpoints by drawing pipes between them.',
          steps: [
            'Tap and drag from an endpoint to draw a pipe',
            'Connect both endpoints of the same color',
            'Pipes cannot cross each other',
            'Fill every cell with a pipe to complete',
            'Clear a path by drawing over it again',
          ],
          tips: 'Start with endpoints that are close together or in corners – they have fewer possible paths.',
        );
      case GameType.lightsOut:
        return _GameInstructions(
          objective: 'Turn off all the lights on the board.',
          steps: [
            'Tap a cell to toggle it and its neighbors',
            'Toggling affects the cell above, below, left, and right',
            'Turn all lights off (dark) to win',
            'The puzzle is always solvable',
            'Use Reset to start over if needed',
          ],
          tips: 'Work systematically from top to bottom. The solution often involves specific patterns.',
        );
      case GameType.wordLadder:
        return _GameInstructions(
          objective: 'Transform the starting word into the target word, changing one letter at a time.',
          steps: [
            'Each step must be a valid English word',
            'You can only change one letter per step',
            'Type a word and tap Submit to add it to the ladder',
            'Reach the target word to complete the puzzle',
            'Use Undo to remove the last word if stuck',
          ],
          tips: 'Think about which letters need to change and plan intermediate words that make those transitions easier.',
        );
      case GameType.connections:
        return _GameInstructions(
          objective: 'Group 16 words into 4 categories of 4 related words each.',
          steps: [
            'Tap words to select them (select exactly 4)',
            'Tap Submit to check if they form a valid group',
            'Correct groups are revealed with their category name',
            'You have 4 mistakes allowed',
            'Find all 4 groups to complete the puzzle',
          ],
          tips: 'Look for word associations like synonyms, categories, or wordplay. The yellow group is easiest, purple is hardest.',
        );
      case GameType.mathora:
        return _GameInstructions(
          objective: 'Apply math operations to reach the target number within the move limit.',
          steps: [
            'Start with the given number',
            'Tap operation buttons to apply them (+, -, ×, ÷)',
            'Reach the exact target number',
            'You have a limited number of moves',
            'Use Undo to try different operation sequences',
          ],
          tips: 'Sometimes you need to go away from the target before getting closer. Think about what operations are available.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Show loading state
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                isChallenge ? 'Loading challenge...' : 'Loading puzzle...',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    // Show error state
    if (_loadError != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _loadError!,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _saveAndExit();
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.background,
                    theme.colorScheme.surface,
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: _isPaused
                        ? _buildPausedOverlay(context)
                        : _buildGameContent(context),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                particleDrag: 0.05,
                emissionFrequency: 0.05,
                numberOfParticles: 30,
                gravity: 0.1,
                shouldLoop: false,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                  Colors.amber,
                  Colors.pink,
                  Colors.purple,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      child: Row(
        children: [
          // Left buttons - compact constraints for small screens
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: const EdgeInsets.all(6),
            onPressed: () async {
              await _saveAndExit();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, size: 20),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: const EdgeInsets.all(6),
            tooltip: 'How to Play',
            onPressed: () => _showGameInstructions(context),
          ),
          // Center - title with flexible sizing
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isChallenge) ...[
                      Icon(
                        Icons.sports_esports_rounded,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 2),
                    ],
                    Flexible(
                      child: Text(
                        _puzzle!.gameType.displayName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    _puzzle!.difficulty.stars,
                    (index) => Icon(
                      Icons.star_rounded,
                      size: 10,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Right side - timer and buttons with very compact sizing
          Consumer<GameProvider>(
            builder: (context, gameProvider, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GameTimer(seconds: gameProvider.elapsedSeconds),
                  IconButton(
                    icon: Icon(
                      _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      size: 20,
                    ),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: const EdgeInsets.all(4),
                    onPressed: _togglePause,
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_rounded, size: 20),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: const EdgeInsets.all(4),
                    tooltip: 'Settings',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildPausedOverlay(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pause_circle_filled_rounded,
            size: 80,
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text('Paused', style: theme.textTheme.headlineLarge),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Resume'),
            onPressed: _togglePause,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Restart Game'),
            onPressed: _showRestartConfirmation,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            icon: const Icon(Icons.flag_outlined, size: 18),
            label: const Text('Report Issue'),
            onPressed: () {
              FeedbackDialog.show(
                context,
                puzzleId: _puzzle?.id,
                gameType: _puzzle?.gameType,
                difficulty: _puzzle?.difficulty,
                puzzleDate: _puzzle?.date,
                initialType: FeedbackType.puzzleMistake,
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showRestartConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.refresh_rounded,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 12),
              const Text('Restart Game?'),
            ],
          ),
          content: const Text(
            'Are you sure you want to restart? All your progress on this puzzle will be lost.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              child: const Text('Restart'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await _restartGame();
    }
  }

  Future<void> _restartGame() async {
    if (_puzzle == null) return;

    // Clear saved state
    await GameStateService.clearGameState(
      gameType: _puzzle!.gameType,
      puzzleDate: _puzzle!.date,
    );

    // Reload puzzle fresh
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    await gameProvider.loadPuzzle(_puzzle!, restoreSavedState: false);

    // Resume game
    setState(() {
      _isPaused = false;
    });
    gameProvider.resume();
  }

  Widget _buildGameContent(BuildContext context) {
    if (_puzzle == null) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_puzzle!.gameType) {
      case GameType.sudoku:
        return _buildSudokuContent(context);
      case GameType.killerSudoku:
        return _buildKillerSudokuContent(context);
      case GameType.crossword:
        return _buildCrosswordContent(context);
      case GameType.wordSearch:
        return _buildWordSearchContent(context);
      case GameType.wordForge:
        return _buildWordForgeContent(context);
      case GameType.nonogram:
        return _buildNonogramContent(context);
      case GameType.numberTarget:
        return _buildNumberTargetContent(context);
      case GameType.ballSort:
        return _buildBallSortContent(context);
      case GameType.pipes:
        return _buildPipesContent(context);
      case GameType.lightsOut:
        return _buildLightsOutContent(context);
      case GameType.wordLadder:
        return _buildWordLadderContent(context);
      case GameType.connections:
        return _buildConnectionsContent(context);
      case GameType.mathora:
        return _buildMathoraContent(context);
    }
  }

  Widget _buildSudokuContent(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        if (gameProvider.sudokuPuzzle == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            _buildSudokuInfoBar(context, gameProvider),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SudokuGrid(
                    puzzle: gameProvider.sudokuPuzzle!,
                    selectedRow: gameProvider.selectedRow,
                    selectedCol: gameProvider.selectedCol,
                    onCellTap: (row, col) {
                      gameProvider.selectCell(row, col);
                      _audioService.playTap();
                    },
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms).scale(begin: const Offset(0.95, 0.95)),
            ),
            NumberPad(
              notesMode: gameProvider.notesMode,
              completedNumbers: gameProvider.sudokuPuzzle!.completedNumbers,
              onNumberTap: (number) {
                final wasCorrect = gameProvider.enterNumber(number);
                if (gameProvider.notesMode) {
                  _audioService.playNoteToggle();
                } else if (wasCorrect == true) {
                  _audioService.playSuccess();
                } else if (wasCorrect == false) {
                  _audioService.playError();
                } else {
                  _audioService.playNumberPlaced();
                }
              },
              onClearTap: () {
                gameProvider.clearCell();
                _audioService.playTap();
              },
              onNotesTap: () {
                gameProvider.toggleNotesMode();
                _audioService.playTap();
              },
              onHintTap: () => _handleHintTap(gameProvider),
            ).animate().fadeIn(delay: 400.ms, duration: 500.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Future<void> _handleHintTap(GameProvider gameProvider) async {
    // Check if hint is available
    bool canUseHint = await _hintService.useHint();

    if (canUseHint) {
      gameProvider.useHint();
      _audioService.playHint();
      setState(() {}); // Refresh to update hint count display
    } else {
      // No hints available, offer rewarded video ad
      _showGetHintsDialog();
    }
  }

  void _showGetHintsDialog() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lightbulb_outline_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Out of Hints'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You\'ve used all your free hints for today!',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.play_circle_outline, color: theme.colorScheme.primary, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Watch a short video to get 3 more hints!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Now'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.video_library_rounded),
            label: const Text('Watch Video'),
            onPressed: () async {
              Navigator.pop(context);
              await _watchVideoForHints();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _watchVideoForHints() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    bool success = await _hintService.watchAdForHints();

    // Close loading indicator
    if (mounted) Navigator.pop(context);

    if (success) {
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('You got 3 more hints! (${_hintService.availableHints} available)'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      setState(() {}); // Refresh to update hint count
    } else {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Failed to load ad. Please try again.'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildKillerSudokuContent(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        if (gameProvider.killerSudokuPuzzle == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            _buildSudokuInfoBar(context, gameProvider),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: KillerSudokuGrid(
                    puzzle: gameProvider.killerSudokuPuzzle!,
                    selectedRow: gameProvider.selectedRow,
                    selectedCol: gameProvider.selectedCol,
                    onCellTap: (row, col) {
                      gameProvider.selectCell(row, col);
                      _audioService.playTap();
                    },
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms).scale(begin: const Offset(0.95, 0.95)),
            ),
            NumberPad(
              notesMode: gameProvider.notesMode,
              completedNumbers: gameProvider.killerSudokuPuzzle!.completedNumbers,
              showCalculator: true,
              onNumberTap: (number) {
                final wasCorrect = gameProvider.enterNumber(number);
                if (gameProvider.notesMode) {
                  _audioService.playNoteToggle();
                } else if (wasCorrect == true) {
                  _audioService.playSuccess();
                } else if (wasCorrect == false) {
                  _audioService.playError();
                } else {
                  _audioService.playNumberPlaced();
                }
              },
              onClearTap: () {
                gameProvider.clearCell();
                _audioService.playTap();
              },
              onNotesTap: () {
                gameProvider.toggleNotesMode();
                _audioService.playTap();
              },
              onHintTap: () => _handleHintTap(gameProvider),
            ).animate().fadeIn(delay: 400.ms, duration: 500.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildSudokuInfoBar(BuildContext context, GameProvider gameProvider) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildInfoItem(
            context,
            icon: Icons.close_rounded,
            label: 'Mistakes',
            value: '${gameProvider.mistakes}',
            color: gameProvider.mistakes > 0 ? theme.colorScheme.error : null,
          ),
          _buildInfoItem(
            context,
            icon: Icons.lightbulb_outline_rounded,
            label: 'Available',
            value: _hintService.isPremium ? '∞' : '${_hintService.availableHints}',
            color: theme.colorScheme.primary,
          ),
          _buildInfoItem(
            context,
            icon: Icons.help_outline_rounded,
            label: 'Used',
            value: '${gameProvider.hintsUsed}',
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms);
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? theme.colorScheme.onSurface.withValues(alpha: 0.6)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            Text(value, style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  /// Scroll to the selected clue in the clue list and switch tabs if needed
  void _scrollToSelectedClue(CrosswordClue clue, CrosswordPuzzle puzzle) {
    // Ensure tab controller is initialized
    if (_cluesTabController == null) return;

    // Switch to the correct tab
    final isAcross = clue.direction == 'across';
    final targetTabIndex = isAcross ? 0 : 1;

    if (_cluesTabController!.index != targetTabIndex) {
      _cluesTabController!.animateTo(targetTabIndex);
    }

    // Find the index of this clue in the appropriate list
    final clueList = isAcross ? puzzle.acrossClues : puzzle.downClues;
    final clueIndex = clueList.indexWhere((c) => c.number == clue.number);

    if (clueIndex == -1) return;

    // Scroll to the clue (approximate height per item ~48-56 pixels for dense ListTile)
    final scrollController = isAcross ? _acrossScrollController : _downScrollController;
    const itemHeight = 52.0;
    final targetOffset = (clueIndex * itemHeight).clamp(
      0.0,
      scrollController.hasClients ? scrollController.position.maxScrollExtent : double.infinity,
    );

    // Only scroll if controller is attached
    if (scrollController.hasClients) {
      scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildCrosswordContent(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        if (gameProvider.crosswordPuzzle == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final puzzle = gameProvider.crosswordPuzzle!;
        final selectedClue = gameProvider.selectedClue;

        // Initialize tab controller if needed
        _cluesTabController ??= TabController(length: 2, vsync: this);

        // Detect clue change and scroll to it
        if (selectedClue != null && selectedClue != _previousSelectedClue) {
          _previousSelectedClue = selectedClue;
          // Schedule scroll after build completes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToSelectedClue(selectedClue, puzzle);
          });
        }

        return Column(
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CrosswordGrid(
                  puzzle: puzzle,
                  selectedRow: gameProvider.selectedRow,
                  selectedCol: gameProvider.selectedCol,
                  selectedClue: selectedClue,
                  onCellTap: (row, col) => gameProvider.selectCrosswordCell(row, col),
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
            ),
            if (selectedClue != null)
              _buildClueDisplay(context, selectedClue),
            Expanded(
              flex: 2,
              child: _buildCluesList(context, gameProvider),
            ),
            KeyboardInput(
              onLetterTap: (letter) {
                gameProvider.enterLetter(letter);
                _audioService.playTap();
              },
              onDeleteTap: () {
                gameProvider.deleteLetter();
                _audioService.playTap();
              },
            ).animate().fadeIn(delay: 400.ms, duration: 500.ms).slideY(begin: 0.2, end: 0),
          ],
        );
      },
    );
  }

  Widget _buildClueDisplay(BuildContext context, CrosswordClue clue) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${clue.number}${clue.direction == 'across' ? 'A' : 'D'}',
              style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(clue.clue, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildCluesList(BuildContext context, GameProvider gameProvider) {
    final theme = Theme.of(context);
    final puzzle = gameProvider.crosswordPuzzle!;

    return Column(
      children: [
        TabBar(
          controller: _cluesTabController,
          tabs: const [Tab(text: 'ACROSS'), Tab(text: 'DOWN')],
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          indicatorColor: theme.colorScheme.primary,
        ),
        Expanded(
          child: TabBarView(
            controller: _cluesTabController,
            children: [
              _buildCluesListView(context, puzzle.acrossClues, gameProvider, _acrossScrollController),
              _buildCluesListView(context, puzzle.downClues, gameProvider, _downScrollController),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCluesListView(
    BuildContext context,
    List<CrosswordClue> clues,
    GameProvider gameProvider,
    ScrollController scrollController,
  ) {
    final theme = Theme.of(context);

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: clues.length,
      itemBuilder: (context, index) {
        final clue = clues[index];
        final isSelected = gameProvider.selectedClue?.number == clue.number &&
            gameProvider.selectedClue?.direction == clue.direction;

        return ListTile(
          dense: true,
          selected: isSelected,
          selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          leading: Text(
            '${clue.number}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isSelected ? theme.colorScheme.primary : null,
            ),
          ),
          title: Text(clue.clue, style: theme.textTheme.bodyMedium),
          onTap: () => gameProvider.selectClue(clue),
        );
      },
    );
  }

  Widget _buildWordSearchContent(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        if (gameProvider.wordSearchPuzzle == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final puzzle = gameProvider.wordSearchPuzzle!;

        return Column(
          children: [
            // Theme and progress
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (puzzle.theme != null)
                    Text(
                      'Theme: ${puzzle.theme}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  Text(
                    '${puzzle.foundCount}/${puzzle.words.length} found',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
            
            // Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: WordSearchGrid(
                  puzzle: puzzle,
                  currentSelection: gameProvider.currentSelection,
                  onSelectionStart: (row, col) {
                    gameProvider.startWordSelection(row, col);
                    _audioService.playTap();
                  },
                  onSelectionUpdate: gameProvider.extendWordSelection,
                  onSelectionEnd: () {
                    final found = gameProvider.endWordSelection();
                    if (found) {
                      _audioService.playWordFound();
                    }
                    return found;
                  },
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
            ),
            
            // Word list
            Container(
              height: 120,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildWordList(context, puzzle),
            ).animate().fadeIn(delay: 400.ms, duration: 500.ms).slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildWordList(BuildContext context, WordSearchPuzzle puzzle) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: puzzle.words.map((word) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: word.found
                ? theme.colorScheme.primary.withValues(alpha: 0.2)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: word.found
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            word.word,
            style: theme.textTheme.bodyMedium?.copyWith(
              decoration: word.found ? TextDecoration.lineThrough : null,
              color: word.found
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
              fontWeight: word.found ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }

  // Word Forge state for result messages
  String? _wordForgeMessage;
  bool? _wordForgeSuccess;

  Widget _buildWordForgeContent(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        if (gameProvider.wordForgePuzzle == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final puzzle = gameProvider.wordForgePuzzle!;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                WordForgeGrid(
                  puzzle: puzzle,
                  currentWord: gameProvider.currentWord,
                  onLetterTap: (letter) {
                    gameProvider.addWordForgeLetter(letter);
                    _audioService.playTap();
                  },
                  onDelete: () {
                    gameProvider.removeWordForgeLetter();
                    _audioService.playTap();
                  },
                  onShuffle: () {
                    gameProvider.shuffleWordForgeLetters();
                    _audioService.playTap();
                  },
                  onSubmit: () {
                    final result = gameProvider.submitWordForgeWord();
                    setState(() {
                      _wordForgeMessage = result.message;
                      _wordForgeSuccess = result.success;
                    });
                    if (result.success) {
                      _audioService.playWordFound();
                      if (result.isPangram) {
                        _confettiController.play();
                      }
                    } else {
                      _audioService.playError();
                    }
                    // Clear message after delay
                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted) {
                        setState(() {
                          _wordForgeMessage = null;
                          _wordForgeSuccess = null;
                        });
                      }
                    });
                  },
                  onShowHints: () => _showWordForgeHints(context, gameProvider),
                ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
                if (_wordForgeMessage != null) ...[
                  const SizedBox(height: 16),
                  _buildMessageBanner(context, _wordForgeMessage!, _wordForgeSuccess!),
                ],
                const SizedBox(height: 24),
                // Found words list
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Found Words (${puzzle.foundWords.length}/${puzzle.validWords.length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      WordForgeWordList(puzzle: puzzle),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageBanner(BuildContext context, String message, bool success) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: success ? Colors.green.shade100 : theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            success ? Icons.check_circle : Icons.error,
            color: success ? Colors.green.shade700 : theme.colorScheme.error,
          ),
          const SizedBox(width: 12),
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: success ? Colors.green.shade700 : theme.colorScheme.onErrorContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).scale(begin: const Offset(0.9, 0.9));
  }

  // Stored pangram hint for display after use
  Map<String, dynamic>? _storedPangramHint;

  void _showWordForgeHints(BuildContext context, GameProvider gameProvider) {
    // Check if puzzle has backend words (new format with clues)
    final hasBackendWords = gameProvider.wordForgePuzzle?.words.isNotEmpty ?? false;

    // Get hints data
    final hasUnfoundPangrams = gameProvider.getUnfoundPangramCount() > 0;
    final pangramHintUsed = gameProvider.wordForgePuzzle?.hasUsedPangramHint ?? false;
    final wordHint = gameProvider.getWordForgeWordHint();

    // Get or update stored pangram hint
    if (pangramHintUsed && _storedPangramHint == null) {
      // Hint was used but we don't have the data - try to get it again
      _storedPangramHint = gameProvider.getWordForgePangramHint();
    } else if (!pangramHintUsed) {
      // Haven't used hint yet, get fresh one
      _storedPangramHint = gameProvider.getWordForgePangramHint();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            // Get fresh data for the sheet
            final currentTwoLetterHints = gameProvider.getWordForgeTwoLetterHints();
            final currentRevealedWords = gameProvider.getRevealedWordForgeWords();

            return WordForgeHintsSheet(
              twoLetterHints: currentTwoLetterHints,
              hasUnfoundPangrams: hasUnfoundPangrams,
              pangramHintUsed: gameProvider.wordForgePuzzle?.hasUsedPangramHint ?? false,
              pangramHint: _storedPangramHint,
              wordHint: wordHint,
              revealedWords: currentRevealedWords,
              onRevealWithPrefix: hasBackendWords ? (prefix) {
                final revealed = gameProvider.revealWordForgeWordWithPrefix(prefix);
                if (revealed != null) {
                  _audioService.playHint();
                  // Show a snackbar with the revealed word and clue
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${revealed.word} - ${revealed.clue}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: revealed.isPangram ? Colors.amber.shade700 : null,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                  // Update the sheet to show new revealed word
                  setSheetState(() {});
                  setState(() {});
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No more words with that prefix!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } : null,
              onUsePangramHint: () {
                // Store the hint before using it
                _storedPangramHint = gameProvider.getWordForgePangramHint();
                gameProvider.useWordForgePangramHint();
                _audioService.playHint();
                // Update the sheet to show the revealed hint
                setSheetState(() {});
                setState(() {});
              },
              onRevealWord: (word) {
                gameProvider.useWordForgeWordReveal(word);
                _audioService.playHint();
                setState(() {});
              },
            );
          },
        );
      },
    );
  }

  Widget _buildNonogramContent(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        if (gameProvider.nonogramPuzzle == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: NonogramGrid(
            puzzle: gameProvider.nonogramPuzzle!,
            markMode: gameProvider.nonogramMarkMode,
            canUndo: gameProvider.canUndoNonogram,
            onCellTap: (row, col) {
              gameProvider.toggleNonogramCell(row, col);
              _audioService.playTap();
            },
            onSetCellState: (row, col, state) {
              gameProvider.setNonogramCellStateSilent(row, col, state);
            },
            onToggleMarkMode: () {
              gameProvider.toggleNonogramMarkMode();
              _audioService.playTap();
            },
            onSaveStateForUndo: () {
              gameProvider.saveNonogramStateForUndo();
            },
            onUndo: () {
              gameProvider.undoNonogram();
              _audioService.playTap();
            },
            onDragEnd: () {
              gameProvider.notifyNonogramChanged();
              _audioService.playTap();
            },
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
      },
    );
  }

  // Number Target state for result messages
  String? _numberTargetMessage;
  bool? _numberTargetSuccess;

  Widget _buildNumberTargetContent(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        if (gameProvider.numberTargetPuzzle == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: NumberTargetGrid(
              puzzle: gameProvider.numberTargetPuzzle!,
              currentExpression: gameProvider.currentExpression,
              resultMessage: _numberTargetMessage,
              lastResultSuccess: _numberTargetSuccess,
              usedNumberIndices: gameProvider.usedNumberIndices,
              onTokenTap: (token, {int? numberIndex}) {
                gameProvider.addToNumberTargetExpression(token, numberIndex: numberIndex);
                _audioService.playTap();
              },
              onClear: () {
                gameProvider.clearNumberTargetExpression();
                setState(() {
                  _numberTargetMessage = null;
                  _numberTargetSuccess = null;
                });
                _audioService.playTap();
              },
              onBackspace: () {
                gameProvider.backspaceNumberTargetExpression();
                _audioService.playTap();
              },
              onSubmit: () {
                final result = gameProvider.evaluateNumberTargetExpression();
                setState(() {
                  _numberTargetMessage = result.message;
                  _numberTargetSuccess = result.success;
                });
                if (result.success) {
                  _audioService.playComplete();
                  _confettiController.play();
                } else {
                  _audioService.playError();
                }
              },
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
        );
      },
    );
  }

  Widget _buildBallSortContent(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        if (gameProvider.ballSortPuzzle == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: BallSortGrid(
            puzzle: gameProvider.ballSortPuzzle!,
            selectedTube: gameProvider.selectedTube,
            undosRemaining: gameProvider.undosRemaining,
            onTubeTap: (tubeIndex) {
              gameProvider.selectBallSortTube(tubeIndex);
              _audioService.playTap();
            },
            onUndo: () {
              if (gameProvider.undoBallSortMove()) {
                _audioService.playTap();
              }
            },
            onReset: () {
              gameProvider.resetBallSortPuzzle();
              _audioService.playTap();
            },
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
      },
    );
  }

  Widget _buildPipesContent(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        if (gameProvider.pipesPuzzle == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: PipesGrid(
            puzzle: gameProvider.pipesPuzzle!,
            onPathStart: (color, row, col) {
              gameProvider.startPipesPath(color, row, col);
              _audioService.playTap();
            },
            onPathContinue: (color) {
              gameProvider.continuePipesPath(color);
              _audioService.playTap();
            },
            onPathExtend: (row, col) {
              gameProvider.extendPipesPath(row, col);
            },
            onPathEnd: () {
              gameProvider.endPipesPath();
            },
            onReset: () {
              gameProvider.resetPipesPuzzle();
              _audioService.playTap();
            },
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
      },
    );
  }

  Widget _buildLightsOutContent(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        if (gameProvider.lightsOutPuzzle == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: LightsOutGrid(
            puzzle: gameProvider.lightsOutPuzzle!,
            onCellTap: (row, col) {
              gameProvider.toggleLightsOutCell(row, col);
              _audioService.playTap();
            },
            onReset: () {
              gameProvider.resetLightsOutPuzzle();
              _audioService.playTap();
            },
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
      },
    );
  }

  // Word Ladder state for result messages
  String? _wordLadderMessage;
  bool? _wordLadderSuccess;

  Widget _buildWordLadderContent(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        if (gameProvider.wordLadderPuzzle == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: WordLadderGrid(
            puzzle: gameProvider.wordLadderPuzzle!,
            currentInput: gameProvider.wordLadderInput,
            message: _wordLadderMessage,
            messageSuccess: _wordLadderSuccess,
            onLetterTap: (letter) {
              gameProvider.addWordLadderLetter(letter);
              _audioService.playTap();
              // Clear message when typing
              if (_wordLadderMessage != null) {
                setState(() {
                  _wordLadderMessage = null;
                  _wordLadderSuccess = null;
                });
              }
            },
            onDeleteTap: () {
              gameProvider.deleteWordLadderLetter();
              _audioService.playTap();
            },
            onSubmit: () {
              final result = gameProvider.submitWordLadderWord();
              setState(() {
                _wordLadderMessage = result.message;
                _wordLadderSuccess = result.success;
              });
              if (result.success) {
                _audioService.playWordFound();
                if (result.isComplete) {
                  _confettiController.play();
                }
              } else {
                _audioService.playError();
              }
            },
            onUndo: () {
              gameProvider.undoWordLadderWord();
              _audioService.playTap();
            },
            onReset: () {
              gameProvider.resetWordLadderPuzzle();
              _audioService.playTap();
            },
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
      },
    );
  }

  // Connections state for result messages
  String? _connectionsMessage;
  bool? _connectionsSuccess;

  Widget _buildConnectionsContent(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        if (gameProvider.connectionsPuzzle == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: ConnectionsGrid(
            puzzle: gameProvider.connectionsPuzzle!,
            message: _connectionsMessage,
            messageSuccess: _connectionsSuccess,
            onWordTap: (word) {
              gameProvider.toggleConnectionsWord(word);
              _audioService.playTap();
              // Clear message when selecting
              if (_connectionsMessage != null) {
                setState(() {
                  _connectionsMessage = null;
                  _connectionsSuccess = null;
                });
              }
            },
            onSubmit: () async {
              final result = gameProvider.submitConnectionsSelection();
              setState(() {
                _connectionsMessage = result.message;
                _connectionsSuccess = result.success;
              });
              if (result.success) {
                _audioService.playWordFound();
                if (gameProvider.connectionsPuzzle!.isComplete) {
                  _confettiController.play();
                }
              } else {
                _audioService.playError();
                // If game over, auto-reveal remaining categories then show dialog
                if (result.isGameOver) {
                  await gameProvider.autoRevealConnectionsCategories();
                  // Wait 2 seconds then show game over dialog
                  await Future.delayed(const Duration(seconds: 2));
                  if (mounted) {
                    _showConnectionsGameOverDialog();
                  }
                }
              }
            },
            onClear: () {
              gameProvider.clearConnectionsSelection();
              _audioService.playTap();
            },
            onShuffle: () {
              gameProvider.shuffleConnectionsWords();
              _audioService.playTap();
            },
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
      },
    );
  }

  void _showConnectionsGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.sentiment_dissatisfied, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 12),
            const Text('Game Over'),
          ],
        ),
        content: const Text('You ran out of mistakes! Better luck next time.'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to home
            },
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  Widget _buildMathoraContent(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        if (gameProvider.mathoraPuzzle == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: MathoraGrid(
            puzzle: gameProvider.mathoraPuzzle!,
            onOperationTap: (operation) {
              final result = gameProvider.applyMathoraOperation(operation);
              _audioService.playTap();
              if (result.isSolved) {
                _checkCompletion();
              } else if (!result.success) {
                _audioService.playError();
              }
            },
            onUndo: () {
              gameProvider.undoMathoraOperation();
              _audioService.playTap();
            },
            onReset: () {
              gameProvider.resetMathoraPuzzle();
              _audioService.playTap();
            },
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
      },
    );
  }
}

/// Helper class for game instructions
class _GameInstructions {
  final String objective;
  final List<String> steps;
  final String? tips;

  const _GameInstructions({
    required this.objective,
    required this.steps,
    this.tips,
  });
}
