import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';

import '../models/game_models.dart';
import '../providers/game_provider.dart';
import '../services/game_service.dart';
import '../services/admob_service.dart';
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
import '../widgets/number_pad.dart';
import '../widgets/keyboard_input.dart';
import '../widgets/game_timer.dart';
import '../widgets/completion_dialog.dart';
import '../widgets/feedback_dialog.dart';
import '../models/feedback_models.dart';

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
  final AdMobService _adMobService = AdMobService();
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () async {
              await _saveAndExit();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isChallenge) ...[
                      Icon(
                        Icons.sports_esports_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      _puzzle!.gameType.displayName,
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _puzzle!.difficulty.stars,
                    (index) => Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Consumer<GameProvider>(
            builder: (context, gameProvider, _) {
              return Row(
                children: [
                  GameTimer(seconds: gameProvider.elapsedSeconds),
                  IconButton(
                    icon: Icon(
                      _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    ),
                    onPressed: _togglePause,
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
            color: theme.colorScheme.primary.withOpacity(0.5),
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
                color: theme.colorScheme.primary.withOpacity(0.1),
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
        Icon(icon, size: 20, color: color ?? theme.colorScheme.onSurface.withOpacity(0.6)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
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
        color: theme.colorScheme.primary.withOpacity(0.1),
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
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
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
          selectedTileColor: theme.colorScheme.primary.withOpacity(0.1),
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
                ? theme.colorScheme.primary.withOpacity(0.2)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: word.found
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.2),
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
            onCellTap: (row, col) {
              gameProvider.toggleNonogramCell(row, col);
              _audioService.playTap();
            },
            onToggleMarkMode: () {
              gameProvider.toggleNonogramMarkMode();
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
              onTokenTap: (token) {
                gameProvider.addToNumberTargetExpression(token);
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
            onInputChanged: (value) {
              gameProvider.setWordLadderInput(value);
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
            onWordTap: (word) {
              gameProvider.toggleConnectionsWord(word);
              _audioService.playTap();
            },
            onSubmit: () {
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
              }
            },
            onClear: () {
              gameProvider.clearConnectionsSelection();
              _audioService.playTap();
            },
            onReset: () {
              gameProvider.resetConnectionsPuzzle();
              _audioService.playTap();
            },
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
      },
    );
  }
}
