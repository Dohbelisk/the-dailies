# Puzzle Generators

Backend generators located in `backend/src/utils/puzzle-generators.ts`.

Puzzles can also be generated via Claude Code skills (see `.claude/skills/`) which create puzzle JSON files in the local vault at `.puzzle-vault/{DATE}/` and optionally push to production via the API.

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
- Places words in 8 directions (horizontal, vertical, 4 diagonals + reverse)
- Fills remaining cells with random A-Z
- Supports optional theme field
- Grid sizes: 5x5 to 15x15 (default 12x12)

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
- Generates 6 numbers and 5 difficulty-tiered targets (extraEasy, easy, medium, hard, expert)
- Each target has a valid solution expression using a subset of the 6 numbers
- Number ranges scale with difficulty (easy 1-9, medium 1-15, hard 1-25, expert 1-50)

### BallSortGenerator
- Creates tube puzzles with colored balls
- Ensures solvability with empty tubes

### PipesGenerator
- Backtracking algorithm generates full-grid paths (20 attempts, snake pattern fallback)
- Grid sizes: easy 5x5, medium 6x6, hard 7x7, expert 8x8 (admin supports up to 12x12)
- 20 supported colors, minimum 3-cell path length per color
- Also generated via Claude Code skill using MITM numberlink algorithm (`~/.claude/scripts/generate_pipes.py`)

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
POST /api/generate/ball-sort       # Generate Ball Sort
POST /api/generate/pipes           # Generate Pipes
POST /api/generate/lights-out      # Generate Lights Out
POST /api/generate/word-ladder     # Generate Word Ladder
POST /api/generate/connections     # Generate Connections
POST /api/generate/mathora         # Generate Mathora
POST /api/generate/week            # Generate full week (all puzzle types)
```

## Claude Code Skills (Local Generation)

Puzzles can also be generated locally via skills, saved to `.puzzle-vault/{DATE}/`, and pushed to production:

| Skill | Command |
|-------|---------|
| `/generate-sudoku` | Generates with Python uniqueness solver |
| `/generate-killer-sudoku` | Generates with Python uniqueness solver |
| `/generate-crossword` | Uses Python AC-3 constraint solver + AI clues |
| `/generate-word-search` | AI-designed themed grids |
| `/generate-word-forge` | AI-curated word lists with clues |
| `/generate-nonogram` | AI-designed pixel art patterns |
| `/generate-number-target` | Multi-tier targets with expressions |
| `/generate-ball-sort` | Scrambled tube puzzles with solution |
| `/generate-pipes` | MITM numberlink algorithm (Python script) |
| `/generate-lights-out` | Backwards generation from solved state |
| `/generate-word-ladder` | AI-verified word chains |
| `/generate-connections` | AI-designed categories with red herrings |
| `/generate-mathora` | Forward-designed operation chains |
| `/push-puzzles` | Push all vault puzzles for a date to production |

## Validation Endpoints

```
POST /api/validate/sudoku              # Validate Sudoku puzzle
POST /api/validate/sudoku/solve        # Solve Sudoku puzzle
POST /api/validate/killer-sudoku       # Validate Killer Sudoku cages
POST /api/validate/killer-sudoku/solve # Solve Killer Sudoku puzzle
```
