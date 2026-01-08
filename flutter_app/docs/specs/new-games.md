# New Games Specification for The Dailies

*Generated: 2026-01-09*
*Status: Ready for Implementation*

## Overview

This specification defines 10 new puzzle games to be added to The Dailies app. Each game follows the existing patterns established by the 14 current games (Sudoku, Killer Sudoku, Crossword, Word Search, Word Forge, Nonogram, Number Target, Ball Sort, Pipes, Lights Out, Word Ladder, Connections, Mathora, Möbius).

## Architecture Pattern

Each new game requires:
1. **Model** in `lib/models/game_models.dart` - Game state, puzzle data, validation logic
2. **Widget** in `lib/widgets/{game}_grid.dart` - UI rendering, user interaction
3. **GameType enum** entry with displayName and icon
4. **Debug menu** entry in "In-Development Games" section

### Existing Patterns to Follow
- Use `CustomPainter` for complex visual rendering
- Use `GestureDetector` for touch interactions
- Support undo/reset functionality
- Include sample levels for testing via static factory methods
- Follow theme colors from `Theme.of(context)`
- Add haptic feedback via `HapticFeedback`

---

## Game 1: Sliding Puzzle (15-Puzzle)

### Concept
Classic sliding tile puzzle. Arrange numbered tiles 1-15 in order by sliding them into the empty space.

### Model: `SlidingPuzzle`
```dart
class SlidingPuzzle {
  final int size; // 3x3, 4x4, or 5x5
  List<int?> tiles; // null = empty space
  final List<int?> solution;
  int moveCount;
  List<int> moveHistory; // indices of moved tiles
}
```

### Mechanics
- Tap a tile adjacent to empty space to slide it
- Win when tiles match solution order
- Track minimum possible moves for scoring

### Difficulty Scaling
- Easy: 3x3 (8-puzzle)
- Medium: 4x4 (15-puzzle)
- Hard: 5x5 (24-puzzle)

### Visual Style
- Rounded square tiles with numbers
- Smooth slide animation (150ms)
- Highlight moveable tiles on hover/touch

---

## Game 2: Minesweeper

### Concept
Classic logic puzzle. Reveal all safe cells without hitting mines. Numbers indicate adjacent mine count.

### Model: `MinesweeperPuzzle`
```dart
class MinesweeperPuzzle {
  final int rows, cols;
  final int mineCount;
  final List<List<bool>> mines; // true = mine
  final List<List<int>> adjacentCounts; // pre-calculated
  List<List<CellState>> revealed; // hidden, revealed, flagged
  bool isGameOver;
  bool isWon;
}
enum CellState { hidden, revealed, flagged }
```

### Mechanics
- Tap to reveal cell
- Long-press to flag/unflag
- Auto-reveal adjacent empty cells (flood fill)
- First tap is always safe (relocate mine if needed)

### Difficulty Scaling
- Easy: 9x9, 10 mines
- Medium: 16x16, 40 mines
- Hard: 16x30, 99 mines

### Visual Style
- Grid cells with beveled 3D effect
- Numbers colored by count (1=blue, 2=green, 3=red, etc.)
- Flag icon for flagged cells
- Mine icon with explosion animation on game over

---

## Game 3: 2048

### Concept
Slide numbered tiles on a grid. Matching numbers merge and double. Reach 2048 to win.

### Model: `TwentyFortyEightPuzzle`
```dart
class TwentyFortyEightPuzzle {
  final int size; // typically 4x4
  List<List<int>> grid; // 0 = empty, powers of 2
  int score;
  int highestTile;
  bool isGameOver;
  bool hasWon;
  List<List<List<int>>> moveHistory;
}
```

### Mechanics
- Swipe in 4 directions to slide all tiles
- Matching adjacent tiles merge (2+2=4, 4+4=8, etc.)
- New tile (2 or 4) spawns after each move
- Win at 2048, can continue playing
- Game over when no moves possible

### Difficulty Scaling
- Easy: 4x4, win at 512
- Medium: 4x4, win at 2048
- Hard: 5x5, win at 4096

### Visual Style
- Tiles colored by value (warm gradient from 2 to 2048+)
- Smooth merge animations
- Pop animation for new tiles
- Score display prominent

---

## Game 4: Kakuro (Cross Sums)

### Concept
Like crossword with numbers. Fill grid so each run sums to its clue, using digits 1-9 without repetition.

### Model: `KakuroPuzzle`
```dart
class KakuroClue {
  final int sum;
  final int length;
  final bool isAcross;
  final int row, col;
}
class KakuroPuzzle {
  final int rows, cols;
  final List<List<int?>> grid; // null = blocked, 0 = empty, 1-9 = filled
  final List<KakuroClue> clues;
  final List<List<int>> solution;
}
```

### Mechanics
- Tap cell, enter digit 1-9
- Each horizontal/vertical run must sum to clue
- No repeated digits in same run
- Validate against solution

### Difficulty Scaling
- Easy: 6x6, simple sums
- Medium: 9x9, complex overlapping
- Hard: 12x12, tricky combinations

### Visual Style
- Black cells with diagonal split showing clues
- White cells for entry
- Number pad input
- Highlight conflicting cells

---

## Game 5: Memory Match

### Concept
Classic card matching. Flip pairs of cards to find matches. Remember positions.

### Model: `MemoryMatchPuzzle`
```dart
class MemoryMatchPuzzle {
  final int rows, cols;
  final List<String> cardValues; // emoji or symbols
  final List<List<String>> board; // shuffled pairs
  List<List<bool>> revealed;
  List<int>? firstFlip; // [row, col]
  List<int>? secondFlip;
  int pairsFound;
  int flipCount;
}
```

### Mechanics
- Tap to flip card
- Two cards flipped at once
- If match, stay revealed
- If no match, flip back after 1 second delay
- Win when all pairs found

### Difficulty Scaling
- Easy: 3x4 (6 pairs)
- Medium: 4x4 (8 pairs)
- Hard: 4x5 (10 pairs)
- Expert: 5x6 (15 pairs)

### Visual Style
- Card flip animation (3D transform)
- Themed card backs
- Icons/emojis on card fronts
- Matched pairs slightly dimmed

---

## Game 6: Tower of Hanoi

### Concept
Move stack of discs from first peg to last, one at a time, never placing larger on smaller.

### Model: `HanoiPuzzle`
```dart
class HanoiPuzzle {
  final int discCount;
  List<List<int>> pegs; // 3 pegs, each is list of disc sizes
  int moveCount;
  final int optimalMoves; // 2^n - 1
  List<HanoiMove> moveHistory;
}
class HanoiMove {
  final int fromPeg, toPeg, discSize;
}
```

### Mechanics
- Tap source peg to select top disc
- Tap destination peg to move
- Cannot place larger disc on smaller
- Win when all discs on third peg

### Difficulty Scaling
- Easy: 3 discs (7 moves optimal)
- Medium: 4 discs (15 moves optimal)
- Hard: 5 discs (31 moves optimal)
- Expert: 6 discs (63 moves optimal)

### Visual Style
- 3 vertical pegs
- Colorful discs (rainbow gradient by size)
- Smooth disc movement animation
- Show optimal move count for reference

---

## Game 7: Tangram

### Concept
Arrange 7 geometric pieces to form a target silhouette.

### Model: `TangramPuzzle`
```dart
class TangramPiece {
  final String id;
  final List<Offset> vertices; // polygon shape
  Offset position;
  double rotation; // 0, 45, 90, 135, 180, 225, 270, 315
  bool isFlipped;
}
class TangramPuzzle {
  final List<TangramPiece> pieces;
  final Path targetSilhouette;
  final String targetName; // "Cat", "House", etc.
}
```

### Mechanics
- Drag pieces to position
- Tap to rotate 45 degrees
- Double-tap to flip
- Pieces snap to grid
- Win when all pieces fit in silhouette

### Difficulty Scaling
- Easy: Simple shapes (square, triangle)
- Medium: Animals, objects
- Hard: Abstract patterns

### Visual Style
- Pieces in distinct colors
- Target silhouette as gray outline
- Snap feedback animation
- Pieces slightly overlap visually when placed

---

## Game 8: Simon (Pattern Memory)

### Concept
Repeat an increasingly long sequence of colors/sounds.

### Model: `SimonPuzzle`
```dart
class SimonPuzzle {
  final List<int> sequence; // 0-3 representing 4 buttons
  int currentLength; // how many to show
  List<int> userInput;
  int highScore;
  bool isShowingPattern;
  bool isGameOver;
}
```

### Mechanics
- Watch pattern play (buttons light up in sequence)
- Repeat pattern by tapping buttons
- Correct = pattern extends by 1
- Wrong = game over
- Target: reach sequence length of 10/15/20

### Difficulty Scaling
- Easy: Slower playback, target 10
- Medium: Normal speed, target 15
- Hard: Faster playback, target 20

### Visual Style
- 4 colored quadrants (red, blue, green, yellow)
- Glow/pulse animation when active
- Sound feedback for each color
- Center shows current level

---

## Game 9: Sokoban (Box Pusher)

### Concept
Push boxes onto target positions. Can only push, not pull.

### Model: `SokobanPuzzle`
```dart
enum SokobanCell { floor, wall, target }
class SokobanPuzzle {
  final int rows, cols;
  final List<List<SokobanCell>> map;
  List<Offset> boxPositions;
  Offset playerPosition;
  final List<Offset> targetPositions;
  int pushCount;
  List<SokobanMove> moveHistory;
}
class SokobanMove {
  final Offset playerFrom, playerTo;
  final Offset? boxFrom, boxTo; // null if no push
}
```

### Mechanics
- Swipe to move player
- Push box if adjacent in move direction
- Cannot push into wall or another box
- Win when all boxes on targets

### Difficulty Scaling
- Easy: 1-2 boxes, small map
- Medium: 3-4 boxes
- Hard: 5+ boxes, complex layouts

### Visual Style
- Top-down grid view
- Player character (simple icon)
- Boxes as crates
- Targets as X marks or circles
- Box on target = highlighted green

---

## Game 10: Hitori (Number Logic)

### Concept
Shade cells to eliminate duplicates in each row/column. Shaded cells can't touch. Unshaded must connect.

### Model: `HitoriPuzzle`
```dart
class HitoriPuzzle {
  final int size;
  final List<List<int>> numbers; // given numbers 1-size
  List<List<bool>> shaded; // true = shaded
  final List<List<bool>> solution;
}
```

### Mechanics
- Tap to shade/unshade cell
- Rules:
  1. No duplicate numbers in any row/column (after shading)
  2. Shaded cells cannot be adjacent (orthogonally)
  3. All unshaded cells must form one connected group
- Win when valid and matches solution

### Difficulty Scaling
- Easy: 5x5
- Medium: 7x7
- Hard: 9x9

### Visual Style
- Grid with numbers
- Shaded cells in dark gray
- Error highlighting for rule violations
- Connected region visualization

---

## Implementation Order (Recommended)

1. **Sliding Puzzle** - Simple model, good intro
2. **Memory Match** - Card flip animation practice
3. **2048** - Swipe mechanics, merge animation
4. **Simon** - Pattern/timing, audio integration
5. **Tower of Hanoi** - Drag and drop, validation
6. **Minesweeper** - Complex reveal logic
7. **Sokoban** - Pathfinding, undo complexity
8. **Kakuro** - Number input, validation
9. **Hitori** - Graph connectivity check
10. **Tangram** - Complex geometry, rotation/flip

---

## Testing Requirements

Each game must include:
1. At least 3 sample levels via static factory methods
2. Unit tests for game logic (win condition, validation)
3. Widget tests for user interaction
4. Manual testing via Debug Menu "In-Development Games"

## Definition of Done

A game is complete when:
- [ ] Model class with full game logic
- [ ] Grid widget with visual rendering
- [ ] GameType enum entry
- [ ] Debug menu entry for testing
- [ ] 3+ sample levels
- [ ] Undo/reset functionality
- [ ] Haptic feedback
- [ ] No analyzer warnings
- [ ] Compiles without error

---

*This specification was created for autonomous implementation via RALPH.*
