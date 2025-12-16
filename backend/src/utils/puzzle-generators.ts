/**
 * Puzzle Generator Utilities
 * 
 * These utilities help generate valid puzzles programmatically.
 * Can be used to auto-generate daily puzzles.
 */

// Sudoku Generator
export class SudokuGenerator {
  private grid: number[][] = [];
  
  generate(difficulty: 'easy' | 'medium' | 'hard' | 'expert'): { grid: number[][], solution: number[][] } {
    // Generate a complete valid Sudoku
    this.grid = Array(9).fill(null).map(() => Array(9).fill(0));
    this.fillGrid();
    
    const solution = this.grid.map(row => [...row]);
    
    // Remove numbers based on difficulty
    const cellsToRemove = {
      easy: 30,
      medium: 40,
      hard: 50,
      expert: 55,
    }[difficulty];
    
    this.removeNumbers(cellsToRemove);
    
    return {
      grid: this.grid,
      solution,
    };
  }
  
  private fillGrid(): boolean {
    const emptyCell = this.findEmptyCell();
    if (!emptyCell) return true;
    
    const [row, col] = emptyCell;
    const numbers = this.shuffle([1, 2, 3, 4, 5, 6, 7, 8, 9]);
    
    for (const num of numbers) {
      if (this.isValid(row, col, num)) {
        this.grid[row][col] = num;
        if (this.fillGrid()) return true;
        this.grid[row][col] = 0;
      }
    }
    
    return false;
  }
  
  private findEmptyCell(): [number, number] | null {
    for (let row = 0; row < 9; row++) {
      for (let col = 0; col < 9; col++) {
        if (this.grid[row][col] === 0) return [row, col];
      }
    }
    return null;
  }
  
  private isValid(row: number, col: number, num: number): boolean {
    // Check row
    if (this.grid[row].includes(num)) return false;
    
    // Check column
    for (let i = 0; i < 9; i++) {
      if (this.grid[i][col] === num) return false;
    }
    
    // Check 3x3 box
    const boxRow = Math.floor(row / 3) * 3;
    const boxCol = Math.floor(col / 3) * 3;
    for (let i = boxRow; i < boxRow + 3; i++) {
      for (let j = boxCol; j < boxCol + 3; j++) {
        if (this.grid[i][j] === num) return false;
      }
    }
    
    return true;
  }
  
  private removeNumbers(count: number): void {
    let removed = 0;
    const positions = this.shuffle(
      Array.from({ length: 81 }, (_, i) => [Math.floor(i / 9), i % 9])
    );
    
    for (const [row, col] of positions) {
      if (removed >= count) break;
      if (this.grid[row][col] !== 0) {
        this.grid[row][col] = 0;
        removed++;
      }
    }
  }
  
  private shuffle<T>(array: T[]): T[] {
    const result = [...array];
    for (let i = result.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [result[i], result[j]] = [result[j], result[i]];
    }
    return result;
  }
}

// Word Search Generator
export class WordSearchGenerator {
  private grid: string[][] = [];
  private rows: number;
  private cols: number;
  
  generate(
    words: string[],
    rows = 15,
    cols = 15,
    theme?: string
  ): {
    rows: number;
    cols: number;
    grid: string[][];
    words: Array<{
      word: string;
      startRow: number;
      startCol: number;
      endRow: number;
      endCol: number;
    }>;
    theme?: string;
  } {
    this.rows = rows;
    this.cols = cols;
    this.grid = Array(rows).fill(null).map(() => Array(cols).fill(''));
    
    const placedWords: Array<{
      word: string;
      startRow: number;
      startCol: number;
      endRow: number;
      endCol: number;
    }> = [];
    
    // Sort words by length (longer first)
    const sortedWords = [...words].sort((a, b) => b.length - a.length);
    
    // Directions: [rowDir, colDir]
    const directions = [
      [0, 1],   // right
      [1, 0],   // down
      [1, 1],   // diagonal down-right
      [-1, 1],  // diagonal up-right
      [0, -1],  // left
      [-1, 0],  // up
      [-1, -1], // diagonal up-left
      [1, -1],  // diagonal down-left
    ];
    
    for (const word of sortedWords) {
      const upperWord = word.toUpperCase();
      let placed = false;
      
      // Try random positions and directions
      const attempts = 100;
      for (let i = 0; i < attempts && !placed; i++) {
        const dir = directions[Math.floor(Math.random() * directions.length)];
        const startRow = Math.floor(Math.random() * rows);
        const startCol = Math.floor(Math.random() * cols);
        
        if (this.canPlaceWord(upperWord, startRow, startCol, dir[0], dir[1])) {
          this.placeWord(upperWord, startRow, startCol, dir[0], dir[1]);
          placedWords.push({
            word: upperWord,
            startRow,
            startCol,
            endRow: startRow + dir[0] * (upperWord.length - 1),
            endCol: startCol + dir[1] * (upperWord.length - 1),
          });
          placed = true;
        }
      }
    }
    
    // Fill remaining cells with random letters
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    for (let r = 0; r < rows; r++) {
      for (let c = 0; c < cols; c++) {
        if (this.grid[r][c] === '') {
          this.grid[r][c] = letters[Math.floor(Math.random() * letters.length)];
        }
      }
    }
    
    return {
      rows,
      cols,
      grid: this.grid,
      words: placedWords,
      theme,
    };
  }
  
  private canPlaceWord(
    word: string,
    startRow: number,
    startCol: number,
    rowDir: number,
    colDir: number
  ): boolean {
    const endRow = startRow + rowDir * (word.length - 1);
    const endCol = startCol + colDir * (word.length - 1);
    
    // Check bounds
    if (endRow < 0 || endRow >= this.rows) return false;
    if (endCol < 0 || endCol >= this.cols) return false;
    
    // Check each position
    for (let i = 0; i < word.length; i++) {
      const r = startRow + rowDir * i;
      const c = startCol + colDir * i;
      const existing = this.grid[r][c];
      
      if (existing !== '' && existing !== word[i]) {
        return false;
      }
    }
    
    return true;
  }
  
  private placeWord(
    word: string,
    startRow: number,
    startCol: number,
    rowDir: number,
    colDir: number
  ): void {
    for (let i = 0; i < word.length; i++) {
      const r = startRow + rowDir * i;
      const c = startCol + colDir * i;
      this.grid[r][c] = word[i];
    }
  }
}

// Killer Sudoku Generator
export class KillerSudokuGenerator {
  private grid: number[][] = [];
  private solution: number[][] = [];

  generate(difficulty: 'easy' | 'medium' | 'hard' | 'expert'): {
    grid: number[][];
    solution: number[][];
    cages: Array<{ sum: number; cells: number[][] }>;
  } {
    // First generate a complete Sudoku solution
    const sudokuGen = new SudokuGenerator();
    const sudoku = sudokuGen.generate('easy'); // We need the full solution
    this.solution = sudoku.solution;

    // Create empty grid
    this.grid = Array(9).fill(null).map(() => Array(9).fill(0));

    // Generate cages based on difficulty
    const cages = this.generateCages(difficulty);

    return {
      grid: this.grid,
      solution: this.solution,
      cages,
    };
  }

  private generateCages(difficulty: 'easy' | 'medium' | 'hard' | 'expert'): Array<{ sum: number; cells: number[][] }> {
    const cages: Array<{ sum: number; cells: number[][] }> = [];
    const used = Array(9).fill(null).map(() => Array(9).fill(false));

    // Determine cage size range based on difficulty
    const cageSizeRange = {
      easy: { min: 2, max: 3 },
      medium: { min: 2, max: 4 },
      hard: { min: 2, max: 5 },
      expert: { min: 2, max: 6 },
    }[difficulty];

    // Fill the grid with cages
    for (let row = 0; row < 9; row++) {
      for (let col = 0; col < 9; col++) {
        if (!used[row][col]) {
          const cageSize = Math.floor(Math.random() * (cageSizeRange.max - cageSizeRange.min + 1)) + cageSizeRange.min;
          const cells = this.buildCage(row, col, cageSize, used);

          // Calculate sum from solution
          const sum = cells.reduce((acc, [r, c]) => acc + this.solution[r][c], 0);

          cages.push({ sum, cells });
        }
      }
    }

    return cages;
  }

  private buildCage(startRow: number, startCol: number, targetSize: number, used: boolean[][]): number[][] {
    const cells: number[][] = [[startRow, startCol]];
    used[startRow][startCol] = true;

    // Grow cage by adding adjacent cells
    while (cells.length < targetSize) {
      const candidates: number[][] = [];

      // Find all adjacent unassigned cells
      for (const [r, c] of cells) {
        const neighbors = [
          [r - 1, c], [r + 1, c], [r, c - 1], [r, c + 1]
        ];

        for (const [nr, nc] of neighbors) {
          if (nr >= 0 && nr < 9 && nc >= 0 && nc < 9 && !used[nr][nc]) {
            // Ensure cage doesn't span multiple 3x3 boxes too much (optional constraint)
            candidates.push([nr, nc]);
          }
        }
      }

      if (candidates.length === 0) break; // Can't grow anymore

      // Pick a random candidate
      const [newRow, newCol] = candidates[Math.floor(Math.random() * candidates.length)];
      cells.push([newRow, newCol]);
      used[newRow][newCol] = true;
    }

    return cells;
  }
}

// Crossword Generator
export class CrosswordGenerator {
  private grid: (string | null)[][] = [];
  private rows: number;
  private cols: number;
  private placedWords: Array<{
    word: string;
    row: number;
    col: number;
    direction: 'across' | 'down';
  }> = [];

  generate(
    wordsWithClues: Array<{ word: string; clue: string }>,
    rows = 15,
    cols = 15
  ): {
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
    this.rows = rows;
    this.cols = cols;
    this.grid = Array(rows).fill(null).map(() => Array(cols).fill(null));
    this.placedWords = [];

    // Sort words by length (longer first for better placement)
    const sorted = [...wordsWithClues].sort((a, b) => b.word.length - a.word.length);

    // Place first word horizontally in the middle
    if (sorted.length > 0) {
      const firstWord = sorted[0].word.toUpperCase();
      const startRow = Math.floor(rows / 2);
      const startCol = Math.floor((cols - firstWord.length) / 2);
      this.placeWord(firstWord, startRow, startCol, 'across');
    }

    // Place remaining words
    for (let i = 1; i < sorted.length; i++) {
      const word = sorted[i].word.toUpperCase();
      const placed = this.findAndPlaceWord(word);
      if (!placed) {
        // Try to place it anywhere if intersection fails
        this.tryPlaceWordAnywhere(word);
      }
    }

    // Convert to final format with black cells (#)
    const finalGrid = this.grid.map(row =>
      row.map(cell => cell === null ? '#' : cell)
    );

    // Generate clue numbers and organize clues
    const clues = this.generateClues(wordsWithClues);

    return {
      rows,
      cols,
      grid: finalGrid,
      clues,
    };
  }

  private findAndPlaceWord(word: string): boolean {
    const attempts = 100;

    for (let attempt = 0; attempt < attempts; attempt++) {
      // Try to find an intersection with existing words
      for (const placed of this.placedWords) {
        for (let i = 0; i < placed.word.length; i++) {
          for (let j = 0; j < word.length; j++) {
            if (placed.word[i] === word[j]) {
              // Found a potential intersection
              let newRow: number, newCol: number;
              let newDir: 'across' | 'down';

              if (placed.direction === 'across') {
                // Place new word vertically
                newDir = 'down';
                newRow = placed.row - j;
                newCol = placed.col + i;
              } else {
                // Place new word horizontally
                newDir = 'across';
                newRow = placed.row + i;
                newCol = placed.col - j;
              }

              if (this.canPlaceWord(word, newRow, newCol, newDir)) {
                this.placeWord(word, newRow, newCol, newDir);
                return true;
              }
            }
          }
        }
      }
    }

    return false;
  }

  private tryPlaceWordAnywhere(word: string): boolean {
    const attempts = 50;

    for (let attempt = 0; attempt < attempts; attempt++) {
      const direction = Math.random() < 0.5 ? 'across' : 'down';
      const row = Math.floor(Math.random() * this.rows);
      const col = Math.floor(Math.random() * this.cols);

      if (this.canPlaceWord(word, row, col, direction)) {
        this.placeWord(word, row, col, direction);
        return true;
      }
    }

    return false;
  }

  private canPlaceWord(word: string, row: number, col: number, direction: 'across' | 'down'): boolean {
    if (direction === 'across') {
      if (col + word.length > this.cols) return false;

      // Check if cells before and after are empty
      if (col > 0 && this.grid[row][col - 1] !== null) return false;
      if (col + word.length < this.cols && this.grid[row][col + word.length] !== null) return false;

      for (let i = 0; i < word.length; i++) {
        const cell = this.grid[row][col + i];
        if (cell !== null && cell !== word[i]) return false;

        // Check perpendicular cells
        if (cell === null) {
          if (row > 0 && this.grid[row - 1][col + i] !== null) return false;
          if (row < this.rows - 1 && this.grid[row + 1][col + i] !== null) return false;
        }
      }
    } else {
      if (row + word.length > this.rows) return false;

      // Check if cells before and after are empty
      if (row > 0 && this.grid[row - 1][col] !== null) return false;
      if (row + word.length < this.rows && this.grid[row + word.length][col] !== null) return false;

      for (let i = 0; i < word.length; i++) {
        const cell = this.grid[row + i][col];
        if (cell !== null && cell !== word[i]) return false;

        // Check perpendicular cells
        if (cell === null) {
          if (col > 0 && this.grid[row + i][col - 1] !== null) return false;
          if (col < this.cols - 1 && this.grid[row + i][col + 1] !== null) return false;
        }
      }
    }

    return true;
  }

  private placeWord(word: string, row: number, col: number, direction: 'across' | 'down'): void {
    if (direction === 'across') {
      for (let i = 0; i < word.length; i++) {
        this.grid[row][col + i] = word[i];
      }
    } else {
      for (let i = 0; i < word.length; i++) {
        this.grid[row + i][col] = word[i];
      }
    }

    this.placedWords.push({ word, row, col, direction });
  }

  private generateClues(wordsWithClues: Array<{ word: string; clue: string }>): Array<{
    number: number;
    direction: 'across' | 'down';
    clue: string;
    answer: string;
    startRow: number;
    startCol: number;
  }> {
    const clues: Array<{
      number: number;
      direction: 'across' | 'down';
      clue: string;
      answer: string;
      startRow: number;
      startCol: number;
    }> = [];

    let clueNumber = 1;
    const numberedCells: { [key: string]: number } = {};

    // First pass: assign numbers to cells that start words
    for (let row = 0; row < this.rows; row++) {
      for (let col = 0; col < this.cols; col++) {
        if (this.grid[row][col] !== null) {
          const startsAcross = col === 0 || this.grid[row][col - 1] === null;
          const startsDown = row === 0 || this.grid[row - 1][col] === null;

          if (startsAcross || startsDown) {
            numberedCells[`${row},${col}`] = clueNumber++;
          }
        }
      }
    }

    // Second pass: match placed words with their clues
    for (const placed of this.placedWords) {
      const key = `${placed.row},${placed.col}`;
      const number = numberedCells[key] || 0;

      const wordData = wordsWithClues.find(w => w.word.toUpperCase() === placed.word);
      const clue = wordData?.clue || `Clue for ${placed.word}`;

      clues.push({
        number,
        direction: placed.direction,
        clue,
        answer: placed.word,
        startRow: placed.row,
        startCol: placed.col,
      });
    }

    // Sort clues by number then direction
    clues.sort((a, b) => {
      if (a.number !== b.number) return a.number - b.number;
      return a.direction === 'across' ? -1 : 1;
    });

    return clues;
  }
}

// Example usage and exports
export const generateSudoku = (difficulty: 'easy' | 'medium' | 'hard' | 'expert') => {
  const generator = new SudokuGenerator();
  return generator.generate(difficulty);
};

export const generateKillerSudoku = (difficulty: 'easy' | 'medium' | 'hard' | 'expert') => {
  const generator = new KillerSudokuGenerator();
  return generator.generate(difficulty);
};

export const generateCrossword = (
  wordsWithClues: Array<{ word: string; clue: string }>,
  rows?: number,
  cols?: number
) => {
  const generator = new CrosswordGenerator();
  return generator.generate(wordsWithClues, rows, cols);
};

export const generateWordSearch = (
  words: string[],
  rows?: number,
  cols?: number,
  theme?: string
) => {
  const generator = new WordSearchGenerator();
  return generator.generate(words, rows, cols, theme);
};
