# Agent Instructions

## Project Location

```
/Users/steedles/Development/puzzle-daily/flutter_app
```

## Build & Verify Commands

```bash
# Navigate to project
cd /Users/steedles/Development/puzzle-daily/flutter_app

# Get dependencies (run once)
flutter pub get

# Analyze code - MUST PASS
flutter analyze

# Run tests (optional but recommended)
flutter test
```

## Key Files

### Models
- `lib/models/game_models.dart` - All game models and GameType enum

### Widgets
- `lib/widgets/` - Game grid widgets
- Reference: `lib/widgets/mobius_grid.dart` - Example pattern to follow

### Debug Menu
- `lib/screens/debug_menu_screen.dart` - Add new games to `_buildInDevGamesSection()`

### Specification
- `docs/specs/new-games.md` - Complete game specifications

## Workflow

1. Read the spec for the next game
2. Add model to `game_models.dart`
3. Create widget in `lib/widgets/`
4. Add to debug menu
5. Run `flutter analyze` - fix any issues
6. Mark tasks complete in `@fix_plan.md`
7. Commit changes
8. Move to next game

## Commit Pattern

After each game is complete:
```bash
git add -A
git commit -m "Add {GameName} puzzle prototype"
```

## Completion

When all 10 games are done and pass analysis:
```
<promise>ALL GAMES COMPLETE</promise>
```
