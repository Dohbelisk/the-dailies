# Puzzle Generators

Backend generators located in `backend/src/utils/puzzle-generators.ts`.

## Generator Algorithms

### SudokuGenerator
- Backtracking algorithm for valid 9x9 grids
- Cells removed based on difficulty: easy=30, medium=40, hard=50, expert=55

### KillerSudokuGenerator
- Extends Sudoku solver with cage generation
- Flood-fill algorithm for cages
- Cage sizes: easy 2-3, medium 2-4, hard 2-5, expert 2-6

### CrosswordGenerator
- Places words via letter intersections
- Auto-numbers clues left-to-right, top-to-bottom

### WordSearchGenerator
- Places words in 8 directions (including diagonals)
- Fills remaining cells with random A-Z

### WordForgeGenerator
- Selects 7 unique letters with good word coverage
- Designates center letter (must be in all valid words)
- Validates words against Dictionary module (~370k words)
- Identifies pangrams (words using all 7 letters)

### NonogramGenerator
- Generates random pixel art patterns
- Calculates row/column clues automatically
- Grid sizes: easy 5x5, medium 10x10, hard 12x12, expert 15x15

### NumberTargetGenerator
- Generates 4 random numbers and a target
- Verifies at least one valid solution exists
- Target ranges: easy 10, medium 24, hard 100, expert 50-500

### BallSortGenerator
- Creates tube puzzles with colored balls
- Ensures solvability with empty tubes

### PipesGenerator
- Places color endpoints on grid
- Validates paths don't cross

### LightsOutGenerator
- Creates solvable light toggle puzzles
- Random initial states

### WordLadderGenerator
- Selects start/target words of same length
- Validates path exists through dictionary

### ConnectionsGenerator
- Groups words into themed categories
- Assigns difficulty levels 1-4

### MathoraGenerator
- Generates starting number and target number
- Creates operations grid (+, -, ×, ÷) with difficulty-based move limits
- Guarantees solvable puzzles with known solution path
- Easy: 3 moves, Medium: 4 moves, Hard: 5 moves, Expert: 6 moves

## Target Times (seconds)

| Difficulty | Sudoku | Killer | Crossword | Word Search | Word Forge | Nonogram | Number Target | Mathora |
|------------|--------|--------|-----------|-------------|------------|----------|---------------|---------|
| Easy       | 300    | 450    | 360       | 180         | 300        | 180      | 120           | 60      |
| Medium     | 600    | 900    | 600       | 300         | 600        | 360      | 180           | 90      |
| Hard       | 900    | 1200   | 900       | 420         | 900        | 600      | 300           | 120     |
| Expert     | 1200   | 1800   | 1200      | 600         | 1200       | 900      | 420           | 180     |

## API Endpoints

```
POST /api/generate/sudoku          # Generate Sudoku
POST /api/generate/killer-sudoku   # Generate Killer Sudoku
POST /api/generate/crossword       # Generate Crossword
POST /api/generate/word-search     # Generate Word Search
POST /api/generate/word-forge      # Generate Word Forge
POST /api/generate/nonogram        # Generate Nonogram
POST /api/generate/number-target   # Generate Number Target
POST /api/generate/week            # Generate full week (all puzzle types)
```

## Validation Endpoints

```
POST /api/validate/sudoku              # Validate Sudoku puzzle
POST /api/validate/sudoku/solve        # Solve Sudoku puzzle
POST /api/validate/killer-sudoku       # Validate Killer Sudoku cages
POST /api/validate/killer-sudoku/solve # Solve Killer Sudoku puzzle
```
