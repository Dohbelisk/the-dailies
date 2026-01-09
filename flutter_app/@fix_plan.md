# Fix Plan: New Games Implementation

## High Priority - Game Implementations

### Game 1: Sliding Puzzle
- [ ] Add SlidingPuzzle model to game_models.dart
- [ ] Add slidingPuzzle to GameType enum with displayName and icon
- [ ] Create sliding_puzzle_grid.dart widget
- [ ] Add SlidingPuzzleTestScreen
- [ ] Add sample levels (3x3, 4x4, 5x5)
- [ ] Add debug menu entry
- [ ] Verify: flutter analyze passes

### Game 2: Memory Match
- [ ] Add MemoryMatchPuzzle model to game_models.dart
- [ ] Add memoryMatch to GameType enum with displayName and icon
- [ ] Create memory_match_grid.dart widget with card flip animation
- [ ] Add MemoryMatchTestScreen
- [ ] Add sample levels (3x4, 4x4, 4x5)
- [ ] Add debug menu entry
- [ ] Verify: flutter analyze passes

### Game 3: 2048
- [ ] Add TwentyFortyEightPuzzle model to game_models.dart
- [ ] Add twentyFortyEight to GameType enum with displayName and icon
- [ ] Create twenty_forty_eight_grid.dart widget with merge animations
- [ ] Add TwentyFortyEightTestScreen
- [ ] Add sample starting configurations
- [ ] Add debug menu entry
- [ ] Verify: flutter analyze passes

### Game 4: Simon
- [ ] Add SimonPuzzle model to game_models.dart
- [ ] Add simon to GameType enum with displayName and icon
- [ ] Create simon_grid.dart widget with pattern display
- [ ] Add SimonTestScreen
- [ ] Add difficulty settings
- [ ] Add debug menu entry
- [ ] Verify: flutter analyze passes

### Game 5: Tower of Hanoi
- [ ] Add HanoiPuzzle model to game_models.dart
- [ ] Add hanoi to GameType enum with displayName and icon
- [ ] Create hanoi_grid.dart widget with disc animations
- [ ] Add HanoiTestScreen
- [ ] Add sample levels (3, 4, 5, 6 discs)
- [ ] Add debug menu entry
- [ ] Verify: flutter analyze passes

### Game 6: Minesweeper
- [ ] Add MinesweeperPuzzle model to game_models.dart
- [ ] Add minesweeper to GameType enum with displayName and icon
- [ ] Create minesweeper_grid.dart widget with reveal/flag logic
- [ ] Add MinesweeperTestScreen
- [ ] Add sample levels (easy, medium, hard)
- [ ] Add debug menu entry
- [ ] Verify: flutter analyze passes

### Game 7: Sokoban
- [ ] Add SokobanPuzzle model to game_models.dart
- [ ] Add sokoban to GameType enum with displayName and icon
- [ ] Create sokoban_grid.dart widget with push mechanics
- [ ] Add SokobanTestScreen
- [ ] Add sample levels (3-4 classic puzzles)
- [ ] Add debug menu entry
- [ ] Verify: flutter analyze passes

### Game 8: Kakuro
- [ ] Add KakuroPuzzle model to game_models.dart
- [ ] Add kakuro to GameType enum with displayName and icon
- [ ] Create kakuro_grid.dart widget with clue cells
- [ ] Add KakuroTestScreen
- [ ] Add sample levels (6x6, 9x9)
- [ ] Add debug menu entry
- [ ] Verify: flutter analyze passes

### Game 9: Hitori
- [ ] Add HitoriPuzzle model to game_models.dart
- [ ] Add hitori to GameType enum with displayName and icon
- [ ] Create hitori_grid.dart widget with shading
- [ ] Add HitoriTestScreen
- [ ] Add sample levels (5x5, 7x7)
- [ ] Add debug menu entry
- [ ] Verify: flutter analyze passes

### Game 10: Tangram
- [ ] Add TangramPuzzle model to game_models.dart
- [ ] Add tangram to GameType enum with displayName and icon
- [ ] Create tangram_grid.dart widget with drag/rotate/flip
- [ ] Add TangramTestScreen
- [ ] Add sample silhouettes
- [ ] Add debug menu entry
- [ ] Verify: flutter analyze passes

## Final Verification

- [ ] All 10 games added to GameType enum
- [ ] All 10 games have working test screens
- [ ] All 10 games accessible from debug menu
- [ ] flutter analyze passes with no errors
- [ ] Each game has at least 3 sample levels

## Notes

- Reference existing code: `lib/widgets/mobius_grid.dart` for pattern
- Reference spec: `docs/specs/new-games.md` for detailed requirements
- Commit after each game is complete
