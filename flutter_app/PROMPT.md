# RALPH Project: New Games for The Dailies

## Objective

Implement 10 new puzzle game prototypes for The Dailies Flutter app. Each game should follow the existing patterns established by current games (Sudoku, Möbius, etc.) and be accessible via the Debug Menu's "In-Development Games" section.

## Reference Specification

Read `docs/specs/new-games.md` for complete game specifications including:
- Game mechanics and rules
- Data models
- Visual style guidelines
- Difficulty scaling
- Implementation order

## Implementation Pattern

For each game, create:

1. **Model** in `lib/models/game_models.dart`:
   - Add to `GameType` enum with displayName and icon
   - Create puzzle class with game state and logic
   - Include static factory methods for sample levels

2. **Widget** in `lib/widgets/{game}_grid.dart`:
   - Create grid widget using `CustomPainter` for rendering
   - Handle user input via `GestureDetector`
   - Include test screen widget (like `MobiusTestScreen`)

3. **Debug Menu** in `lib/screens/debug_menu_screen.dart`:
   - Add entry in `_buildInDevGamesSection()`
   - Import the new widget

## Code Quality Requirements

- Run `flutter analyze` - no errors allowed
- Follow existing code style (see `lib/widgets/mobius_grid.dart` as reference)
- Use theme colors from `Theme.of(context)`
- Include haptic feedback via `HapticFeedback`
- Support undo/reset where applicable

## Verification Commands

```bash
cd /Users/steedles/Development/puzzle-daily/flutter_app
flutter analyze
flutter test
```

## Implementation Order

Follow the order in the spec:
1. Sliding Puzzle
2. Memory Match
3. 2048
4. Simon
5. Tower of Hanoi
6. Minesweeper
7. Sokoban
8. Kakuro
9. Hitori
10. Tangram

## Completion Signal

When a game is fully implemented (model + widget + debug menu entry + sample levels + passes analyze), mark it complete in @fix_plan.md and move to the next.

When all 10 games are implemented and pass analysis, output:
```
<promise>ALL GAMES COMPLETE</promise>
```
