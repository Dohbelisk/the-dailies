import mongoose from 'mongoose';

// External puzzle generators (npm packages)
import { generate as generateSudokuPuzzle, solve as solveSudoku } from 'sudoku-core';
import { generateKillerSudoku } from 'killer-sudoku-generator';
import { generate as generateWordSearchPuzzle } from '@sbj42/word-search-generator';

// Crossword generator (npm package)
// eslint-disable-next-line @typescript-eslint/no-var-requires
const clg = require('crossword-layout-generator');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/the-dailies';

// Puzzle Schema
const puzzleSchema = new mongoose.Schema({
  gameType: { type: String, required: true, enum: ['sudoku', 'killerSudoku', 'crossword', 'wordSearch'] },
  difficulty: { type: String, required: true, enum: ['easy', 'medium', 'hard', 'expert'] },
  date: { type: Date, required: true },
  puzzleData: { type: Object, required: true },
  solution: Object,
  targetTime: Number,
  isActive: { type: Boolean, default: true },
  title: String,
  description: String,
}, { timestamps: true });

const Puzzle = mongoose.model('Puzzle', puzzleSchema);

// Word lists for crosswords and word searches
const programmingWords = [
  { word: 'FLUTTER', clue: 'Google\'s cross-platform UI toolkit' },
  { word: 'DART', clue: 'Programming language for Flutter' },
  { word: 'WIDGET', clue: 'UI building block in Flutter' },
  { word: 'REACT', clue: 'Facebook\'s JavaScript library' },
  { word: 'TYPESCRIPT', clue: 'JavaScript with types' },
  { word: 'PYTHON', clue: 'Snake-named programming language' },
  { word: 'JAVA', clue: 'Coffee-themed programming language' },
  { word: 'KOTLIN', clue: 'Modern Android development language' },
  { word: 'SWIFT', clue: 'Apple\'s programming language' },
  { word: 'RUST', clue: 'Memory-safe systems language' },
  { word: 'CODE', clue: 'What programmers write' },
  { word: 'DEBUG', clue: 'Find and fix errors' },
];

const natureWords = [
  { word: 'MOUNTAIN', clue: 'Tall natural elevation' },
  { word: 'RIVER', clue: 'Flowing body of water' },
  { word: 'FOREST', clue: 'Large area with many trees' },
  { word: 'OCEAN', clue: 'Vast body of salt water' },
  { word: 'DESERT', clue: 'Dry, sandy region' },
  { word: 'VALLEY', clue: 'Low area between hills' },
  { word: 'ISLAND', clue: 'Land surrounded by water' },
  { word: 'VOLCANO', clue: 'Mountain that can erupt' },
  { word: 'CANYON', clue: 'Deep gorge carved by rivers' },
  { word: 'GLACIER', clue: 'Slow-moving mass of ice' },
  { word: 'LAKE', clue: 'Body of fresh water' },
  { word: 'CAVE', clue: 'Natural underground chamber' },
];

const animalWords = [
  { word: 'ELEPHANT', clue: 'Large mammal with trunk' },
  { word: 'DOLPHIN', clue: 'Intelligent marine mammal' },
  { word: 'PENGUIN', clue: 'Flightless bird of Antarctica' },
  { word: 'GIRAFFE', clue: 'Tallest living animal' },
  { word: 'TIGER', clue: 'Striped big cat' },
  { word: 'KANGAROO', clue: 'Australian hopping mammal' },
  { word: 'OCTOPUS', clue: 'Eight-armed sea creature' },
  { word: 'BUTTERFLY', clue: 'Colorful winged insect' },
  { word: 'EAGLE', clue: 'Large bird of prey' },
  { word: 'PARROT', clue: 'Colorful talking bird' },
  { word: 'SHARK', clue: 'Ocean predator with fins' },
  { word: 'ZEBRA', clue: 'Striped African horse' },
];

const foodWords = [
  { word: 'PIZZA', clue: 'Italian flatbread dish' },
  { word: 'SUSHI', clue: 'Japanese rice dish' },
  { word: 'BURGER', clue: 'Sandwich with patty' },
  { word: 'PASTA', clue: 'Italian noodle dish' },
  { word: 'SALAD', clue: 'Mixed vegetable dish' },
  { word: 'TACOS', clue: 'Mexican folded tortilla' },
  { word: 'CURRY', clue: 'Spiced dish from India' },
  { word: 'STEAK', clue: 'Cut of beef' },
  { word: 'RAMEN', clue: 'Japanese noodle soup' },
  { word: 'WAFFLE', clue: 'Grid-patterned breakfast item' },
  { word: 'BREAD', clue: 'Baked dough staple' },
  { word: 'CHEESE', clue: 'Dairy product from milk' },
];

const themes = [
  { name: 'Programming', words: programmingWords },
  { name: 'Nature', words: natureWords },
  { name: 'Animals', words: animalWords },
  { name: 'Food', words: foodWords },
];

const difficulties: ('easy' | 'medium' | 'hard' | 'expert')[] = ['easy', 'medium', 'hard', 'expert'];

const targetTimes = {
  sudoku: { easy: 300, medium: 600, hard: 900, expert: 1200 },
  killerSudoku: { easy: 600, medium: 900, hard: 1200, expert: 1800 },
  crossword: { easy: 300, medium: 600, hard: 900, expert: 1200 },
  wordSearch: { easy: 180, medium: 300, hard: 480, expert: 600 },
};

// Helper: Convert flat array to 9x9 grid
function flatTo9x9(flat: (number | null)[]): number[][] {
  const grid: number[][] = [];
  for (let i = 0; i < 9; i++) {
    grid.push(flat.slice(i * 9, (i + 1) * 9).map(n => n ?? 0));
  }
  return grid;
}

// Helper: Convert string to 9x9 grid
function stringTo9x9(str: string): number[][] {
  const grid: number[][] = [];
  for (let i = 0; i < 9; i++) {
    const row: number[] = [];
    for (let j = 0; j < 9; j++) {
      const char = str[i * 9 + j];
      row.push(char === '-' ? 0 : parseInt(char));
    }
    grid.push(row);
  }
  return grid;
}

// Generate Sudoku using sudoku-core
function createSudoku(difficulty: 'easy' | 'medium' | 'hard' | 'expert'): { grid: number[][], solution: number[][] } {
  const puzzle = generateSudokuPuzzle(difficulty);
  const solved = solveSudoku(puzzle);

  return {
    grid: flatTo9x9(puzzle),
    solution: flatTo9x9(solved.board),
  };
}

// Generate Killer Sudoku using killer-sudoku-generator
function createKillerSudoku(): { grid: number[][], solution: number[][], cages: Array<{ sum: number; cells: number[][] }> } {
  const result = generateKillerSudoku();

  // Convert areas to our cage format
  const cages = result.areas.map((area: { cells: number[][]; sum: number }) => ({
    sum: area.sum,
    cells: area.cells, // Already in [row, col] format
  }));

  return {
    grid: stringTo9x9(result.puzzle),
    solution: stringTo9x9(result.solution),
    cages,
  };
}

// Generate Word Search using @sbj42/word-search-generator
function createWordSearch(words: string[], theme: string, rows = 12, cols = 12): {
  rows: number;
  cols: number;
  grid: string[][];
  words: Array<{ word: string; startRow: number; startCol: number; endRow: number; endCol: number }>;
  theme: string;
} {
  const puzzle = generateWordSearchPuzzle({
    words,
    width: cols,
    height: rows,
    diagonals: true,
    minLength: 3,
  });

  // Convert grid format
  const grid: string[][] = [];
  for (let r = 0; r < puzzle.height; r++) {
    const row: string[] = [];
    for (let c = 0; c < puzzle.width; c++) {
      row.push(puzzle.get(c, r));
    }
    grid.push(row);
  }

  // Find word positions in the grid
  const wordPositions = puzzle.words.map((word: string) => {
    // Search for word in grid
    const positions = findWordInGrid(grid, word);
    return positions || { word, startRow: 0, startCol: 0, endRow: 0, endCol: 0 };
  });

  return {
    rows: puzzle.height,
    cols: puzzle.width,
    grid,
    words: wordPositions,
    theme,
  };
}

// Generate Crossword using crossword-layout-generator
function createCrossword(wordsWithClues: Array<{ word: string; clue: string }>, _targetRows = 13, _targetCols = 13): {
  rows: number;
  cols: number;
  grid: (string | null)[][];
  clues: Array<{
    number: number;
    direction: 'across' | 'down';
    clue: string;
    answer: string;
    startRow: number;
    startCol: number;
  }>;
} {
  // Convert to format expected by crossword-layout-generator
  const input = wordsWithClues.map(w => ({
    clue: w.clue,
    answer: w.word.toUpperCase(),
  }));

  const layout = clg.generateLayout(input);

  // Convert table to our grid format (they use '-' for empty, we use '#')
  const grid: (string | null)[][] = [];
  for (let row = 0; row < layout.rows; row++) {
    const gridRow: (string | null)[] = [];
    for (let col = 0; col < layout.cols; col++) {
      const cell = layout.table[row][col];
      gridRow.push(cell === '-' ? '#' : cell);
    }
    grid.push(gridRow);
  }

  // Convert result to our clue format
  const clues = layout.result.map((word: any) => ({
    number: word.position,
    direction: word.orientation === 'across' ? 'across' : 'down',
    clue: word.clue,
    answer: word.answer,
    startRow: word.starty - 1, // Convert from 1-indexed to 0-indexed
    startCol: word.startx - 1,
  }));

  // Sort clues by number then direction
  clues.sort((a: any, b: any) => {
    if (a.number !== b.number) return a.number - b.number;
    return a.direction === 'across' ? -1 : 1;
  });

  return {
    rows: layout.rows,
    cols: layout.cols,
    grid,
    clues,
  };
}

// Helper: Find word position in grid
function findWordInGrid(grid: string[][], word: string): { word: string; startRow: number; startCol: number; endRow: number; endCol: number } | null {
  const directions = [
    [0, 1], [1, 0], [1, 1], [-1, 1], // right, down, diagonal down-right, diagonal up-right
    [0, -1], [-1, 0], [-1, -1], [1, -1], // left, up, diagonal up-left, diagonal down-left
  ];

  for (let r = 0; r < grid.length; r++) {
    for (let c = 0; c < grid[0].length; c++) {
      if (grid[r][c] === word[0]) {
        for (const [dr, dc] of directions) {
          let found = true;
          for (let i = 0; i < word.length; i++) {
            const nr = r + dr * i;
            const nc = c + dc * i;
            if (nr < 0 || nr >= grid.length || nc < 0 || nc >= grid[0].length || grid[nr][nc] !== word[i]) {
              found = false;
              break;
            }
          }
          if (found) {
            return {
              word,
              startRow: r,
              startCol: c,
              endRow: r + dr * (word.length - 1),
              endCol: c + dc * (word.length - 1),
            };
          }
        }
      }
    }
  }
  return null;
}

async function seedDateRange() {
  try {
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB');

    // Clear all existing puzzles (comment out to preserve existing)
    // console.log('\n🗑️  Clearing all existing puzzles...');
    // const deleteResult = await Puzzle.deleteMany({});
    // console.log(`✅ Deleted ${deleteResult.deletedCount} puzzles`);

    // Define date range: December 15, 2025 to December 25, 2025
    const startDate = new Date('2025-12-15');
    const endDate = new Date('2025-12-25');

    // Calculate number of days
    const daysDiff = Math.ceil((endDate.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24)) + 1;
    console.log(`\n📅 Generating puzzles from ${startDate.toDateString()} to ${endDate.toDateString()}`);
    console.log(`   Total days: ${daysDiff}`);
    console.log(`   Total puzzles to create: ${daysDiff * 4} (4 game types per day)\n`);
    console.log('Using npm packages: sudoku-core, killer-sudoku-generator, @sbj42/word-search-generator, crossword-layout-generator\n');

    let puzzlesCreated = 0;
    let currentDate = new Date(startDate);

    while (currentDate <= endDate) {
      const dateStr = currentDate.toISOString().split('T')[0];
      const dayOfMonth = currentDate.getDate();

      // Rotate difficulty based on day of month
      const difficultyIndex = (dayOfMonth - 1) % 4;
      const difficulty = difficulties[difficultyIndex];

      // Rotate themes for crossword and word search
      const themeIndex = (dayOfMonth - 1) % themes.length;
      const theme = themes[themeIndex];

      process.stdout.write(`Generating ${dateStr} (${difficulty})... `);
      let created = 0;

      // Generate Sudoku using sudoku-core
      try {
        const sudokuData = createSudoku(difficulty);
        await Puzzle.create({
          gameType: 'sudoku',
          difficulty,
          date: new Date(currentDate),
          puzzleData: { grid: sudokuData.grid },
          solution: { grid: sudokuData.solution },
          targetTime: targetTimes.sudoku[difficulty],
          title: `Daily Sudoku - ${dateStr}`,
          isActive: true,
        });
        puzzlesCreated++;
        created++;
      } catch (e) {
        console.error(`\n  Failed Sudoku: ${(e as Error).message}`);
      }

      // Generate Killer Sudoku using killer-sudoku-generator
      try {
        const killerData = createKillerSudoku();
        await Puzzle.create({
          gameType: 'killerSudoku',
          difficulty,
          date: new Date(currentDate),
          puzzleData: { grid: killerData.grid, cages: killerData.cages },
          solution: { grid: killerData.solution },
          targetTime: targetTimes.killerSudoku[difficulty],
          title: `Daily Killer Sudoku - ${dateStr}`,
          isActive: true,
        });
        puzzlesCreated++;
        created++;
      } catch (e) {
        console.error(`\n  Failed Killer Sudoku: ${(e as Error).message}`);
      }

      // Generate Crossword using crossword-layout-generator
      try {
        const crosswordData = createCrossword(theme.words.slice(0, 8), 13, 13);
        await Puzzle.create({
          gameType: 'crossword',
          difficulty,
          date: new Date(currentDate),
          puzzleData: {
            rows: crosswordData.rows,
            cols: crosswordData.cols,
            grid: crosswordData.grid,
            clues: crosswordData.clues,
          },
          targetTime: targetTimes.crossword[difficulty],
          title: `Daily Crossword - ${theme.name}`,
          isActive: true,
        });
        puzzlesCreated++;
        created++;
      } catch (e) {
        console.error(`\n  Failed Crossword: ${(e as Error).message}`);
      }

      // Generate Word Search using @sbj42/word-search-generator
      try {
        const wordList = theme.words.map(w => w.word);
        const wordSearchData = createWordSearch(wordList.slice(0, 10), theme.name, 12, 12);
        await Puzzle.create({
          gameType: 'wordSearch',
          difficulty,
          date: new Date(currentDate),
          puzzleData: {
            rows: wordSearchData.rows,
            cols: wordSearchData.cols,
            grid: wordSearchData.grid,
            words: wordSearchData.words,
            theme: wordSearchData.theme,
          },
          targetTime: targetTimes.wordSearch[difficulty],
          title: `Word Search - ${theme.name}`,
          isActive: true,
        });
        puzzlesCreated++;
        created++;
      } catch (e) {
        console.error(`\n  Failed Word Search: ${(e as Error).message}`);
      }

      console.log(`${created}/4 ✓`);

      // Move to next day
      currentDate.setDate(currentDate.getDate() + 1);
    }

    console.log(`\n🎉 Seed completed!`);
    console.log(`   Created ${puzzlesCreated} puzzles`);
    console.log(`   Date range: Nov 1, 2025 - Jan 1, 2026`);
    console.log(`\n📊 Breakdown:`);
    console.log(`   - Archive puzzles (past): Nov 1 - Dec 15`);
    console.log(`   - Today's puzzles: Dec 16`);
    console.log(`   - Future puzzles (locked): Dec 17 - Jan 1`);

    process.exit(0);
  } catch (error) {
    console.error('Seed failed:', error);
    process.exit(1);
  }
}

seedDateRange();
