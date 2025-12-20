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

// Word Forge Generator
export class WordForgeGenerator {
  // Common English words (4+ letters) - curated subset for puzzle generation
  private static readonly WORD_LIST: string[] = [
    // This is a subset - in production, load from a larger dictionary file
    'ABLE', 'ABOUT', 'ABOVE', 'ACCEPT', 'ACCOUNT', 'ACHIEVE', 'ACROSS', 'ACTION', 'ACTIVE', 'ACTUAL',
    'ADDING', 'ADVANCE', 'AFTER', 'AGAIN', 'AGAINST', 'AGENT', 'AGREE', 'AHEAD', 'ALLOW', 'ALMOST',
    'ALONE', 'ALONG', 'ALREADY', 'ALSO', 'ALWAYS', 'AMONG', 'AMOUNT', 'ANIMAL', 'ANOTHER', 'ANSWER',
    'APART', 'APPEAR', 'APPLY', 'AREA', 'ARGUE', 'ARISE', 'AROUND', 'ARRIVE', 'ASIDE', 'ASKING',
    'BABY', 'BACK', 'BALANCE', 'BALL', 'BAND', 'BANK', 'BASE', 'BASIC', 'BATTLE', 'BEAR',
    'BEAT', 'BECOME', 'BEEN', 'BEFORE', 'BEGIN', 'BEHIND', 'BEING', 'BELIEVE', 'BELONG', 'BELOW',
    'BEND', 'BENEFIT', 'BESIDE', 'BEST', 'BETTER', 'BETWEEN', 'BEYOND', 'BILLION', 'BIND', 'BIRD',
    'BLACK', 'BLANK', 'BLEND', 'BLIND', 'BLOCK', 'BLOOD', 'BLOW', 'BLUE', 'BOARD', 'BOAT',
    'BODY', 'BOLD', 'BONE', 'BOOK', 'BOOM', 'BORN', 'BOTH', 'BOTTOM', 'BOUND', 'BRAIN',
    'BRANCH', 'BRAND', 'BREAD', 'BREAK', 'BREATH', 'BRIDGE', 'BRIEF', 'BRIGHT', 'BRING', 'BROAD',
    'BROKEN', 'BROTHER', 'BROWN', 'BUILD', 'BUILDING', 'BURN', 'BURST', 'BUSINESS', 'BUSY', 'BUYER',
    'CABLE', 'CALL', 'CALM', 'CAME', 'CAMP', 'CAMPAIGN', 'CAMPUS', 'CANNOT', 'CAPABLE', 'CAPITAL',
    'CAPTAIN', 'CAPTURE', 'CARD', 'CARE', 'CAREER', 'CAREFUL', 'CARRY', 'CASE', 'CASH', 'CAST',
    'CATCH', 'CATEGORY', 'CAUSE', 'CELL', 'CENTER', 'CENTRAL', 'CENTURY', 'CHAIN', 'CHAIR', 'CHALLENGE',
    'CHAMBER', 'CHAMPION', 'CHANCE', 'CHANGE', 'CHANNEL', 'CHAPTER', 'CHARACTER', 'CHARGE', 'CHART', 'CHASE',
    'CHEAP', 'CHECK', 'CHIEF', 'CHILD', 'CHILDREN', 'CHOICE', 'CHOOSE', 'CHURCH', 'CIRCLE', 'CITIZEN',
    'CITY', 'CIVIL', 'CLAIM', 'CLASS', 'CLASSIC', 'CLEAN', 'CLEAR', 'CLIMB', 'CLOCK', 'CLOSE',
    'CLOUD', 'CLUB', 'COACH', 'COAL', 'COAST', 'CODE', 'COFFEE', 'COLD', 'COLLECT', 'COLLEGE',
    'COLOR', 'COLUMN', 'COMBAT', 'COMBINE', 'COME', 'COMFORT', 'COMING', 'COMMAND', 'COMMENT', 'COMMERCIAL',
    'COMMON', 'COMMUNITY', 'COMPANY', 'COMPARE', 'COMPETE', 'COMPLETE', 'COMPLEX', 'COMPUTER', 'CONCEPT', 'CONCERN',
    'CONDITION', 'CONDUCT', 'CONFERENCE', 'CONFIRM', 'CONFLICT', 'CONNECT', 'CONSIDER', 'CONSTANT', 'CONSUMER', 'CONTACT',
    'CONTAIN', 'CONTENT', 'CONTEXT', 'CONTINUE', 'CONTRACT', 'CONTRAST', 'CONTRIBUTE', 'CONTROL', 'COOK', 'COOL',
    'COPY', 'CORE', 'CORNER', 'CORPORATE', 'CORRECT', 'COST', 'COULD', 'COUNCIL', 'COUNT', 'COUNTRY',
    'COUNTY', 'COUPLE', 'COURAGE', 'COURSE', 'COURT', 'COVER', 'CRACK', 'CRAFT', 'CRASH', 'CRAZY',
    'CREAM', 'CREATE', 'CREDIT', 'CREW', 'CRIME', 'CRISIS', 'CRITICAL', 'CROSS', 'CROWD', 'CRUCIAL',
    'CULTURAL', 'CULTURE', 'CURRENT', 'CUSTOMER', 'CYCLE', 'DAILY', 'DAMAGE', 'DANCE', 'DANGER', 'DANGEROUS',
    'DARK', 'DATA', 'DATE', 'DAUGHTER', 'DEAD', 'DEAL', 'DEALER', 'DEAR', 'DEATH', 'DEBATE',
    'DECADE', 'DECIDE', 'DECISION', 'DECK', 'DECLARE', 'DECLINE', 'DEEP', 'DEEPLY', 'DEFEAT', 'DEFEND',
    'DEFENSE', 'DEFINE', 'DEGREE', 'DELAY', 'DELIVER', 'DEMAND', 'DEMOCRACY', 'DEMOCRATIC', 'DEMONSTRATE', 'DENY',
    'DEPARTMENT', 'DEPEND', 'DEPTH', 'DEPUTY', 'DERIVE', 'DESCRIBE', 'DESERT', 'DESERVE', 'DESIGN', 'DESIGNER',
    'DESIRE', 'DESK', 'DESPITE', 'DESTROY', 'DETAIL', 'DETECT', 'DETERMINE', 'DEVELOP', 'DEVICE', 'DIALOGUE',
    'DIAMOND', 'DIFFER', 'DIFFERENT', 'DIFFICULT', 'DIGITAL', 'DINING', 'DINNER', 'DIRECT', 'DIRECTION', 'DIRECTOR',
    'DIRTY', 'DISAPPEAR', 'DISCOVER', 'DISCUSS', 'DISEASE', 'DISH', 'DISPLAY', 'DISTANCE', 'DISTINCT', 'DISTRIBUTE',
    'DISTRICT', 'DIVERSE', 'DIVIDE', 'DOCTOR', 'DOCUMENT', 'DOLLAR', 'DOMESTIC', 'DOMINANT', 'DOMINATE', 'DONE',
    'DOOR', 'DOUBLE', 'DOUBT', 'DOWN', 'DOZEN', 'DRAFT', 'DRAG', 'DRAMA', 'DRAMATIC', 'DRAW',
    'DRAWING', 'DREAM', 'DRESS', 'DRINK', 'DRIVE', 'DRIVER', 'DROP', 'DRUG', 'DURING', 'DUST',
    'DUTY', 'EACH', 'EAGER', 'EARLY', 'EARN', 'EARTH', 'EASE', 'EASILY', 'EAST', 'EASTERN',
    'EASY', 'ECONOMIC', 'ECONOMY', 'EDGE', 'EDITION', 'EDITOR', 'EDUCATE', 'EDUCATION', 'EFFECT', 'EFFECTIVE',
    'EFFORT', 'EIGHT', 'EITHER', 'ELDER', 'ELECT', 'ELECTION', 'ELECTRIC', 'ELEMENT', 'ELIMINATE', 'ELITE',
    'ELSE', 'ELSEWHERE', 'EMAIL', 'EMERGE', 'EMERGENCY', 'EMOTION', 'EMOTIONAL', 'EMPHASIS', 'EMPHASIZE', 'EMPLOY',
    'EMPLOYEE', 'EMPLOYER', 'EMPTY', 'ENABLE', 'ENCOUNTER', 'ENCOURAGE', 'ENDING', 'ENEMY', 'ENERGY', 'ENGAGE',
    'ENGINE', 'ENGINEER', 'ENGLISH', 'ENHANCE', 'ENJOY', 'ENOUGH', 'ENSURE', 'ENTER', 'ENTERPRISE', 'ENTIRE',
    'ENTIRELY', 'ENTRANCE', 'ENTRY', 'ENVIRONMENT', 'EQUAL', 'EQUIPMENT', 'ERROR', 'ESCAPE', 'ESPECIALLY', 'ESSENTIAL',
    'ESTABLISH', 'ESTATE', 'ESTIMATE', 'ETHNIC', 'EVALUATE', 'EVEN', 'EVENING', 'EVENT', 'EVENTUALLY', 'EVER',
    'EVERY', 'EVERYBODY', 'EVERYDAY', 'EVERYONE', 'EVERYTHING', 'EVIDENCE', 'EVIL', 'EVOLUTION', 'EXACT', 'EXACTLY',
    'EXAMINE', 'EXAMPLE', 'EXCELLENT', 'EXCEPT', 'EXCHANGE', 'EXCITING', 'EXECUTIVE', 'EXERCISE', 'EXHIBIT', 'EXIST',
    'EXISTENCE', 'EXISTING', 'EXPAND', 'EXPANSION', 'EXPECT', 'EXPECTATION', 'EXPENSE', 'EXPENSIVE', 'EXPERIENCE', 'EXPERIMENT',
    'EXPERT', 'EXPLAIN', 'EXPLANATION', 'EXPLORE', 'EXPORT', 'EXPOSE', 'EXPOSURE', 'EXPRESS', 'EXPRESSION', 'EXTEND',
    'EXTENSION', 'EXTENSIVE', 'EXTENT', 'EXTERNAL', 'EXTRA', 'EXTRAORDINARY', 'EXTREME', 'EXTREMELY', 'FACE', 'FACILITY',
    'FACT', 'FACTOR', 'FACTORY', 'FAIL', 'FAILURE', 'FAIR', 'FAIRLY', 'FAITH', 'FALL', 'FALSE',
    'FAME', 'FAMILIAR', 'FAMILY', 'FAMOUS', 'FANCY', 'FANTASY', 'FARM', 'FARMER', 'FASHION', 'FAST',
    'FATHER', 'FAULT', 'FAVOR', 'FAVORITE', 'FEAR', 'FEATURE', 'FEDERAL', 'FEED', 'FEEL', 'FEELING',
    'FELLOW', 'FEMALE', 'FENCE', 'FICTION', 'FIELD', 'FIFTEEN', 'FIFTH', 'FIFTY', 'FIGHT', 'FIGHTER',
    'FIGHTING', 'FIGURE', 'FILE', 'FILL', 'FILM', 'FINAL', 'FINALLY', 'FINANCE', 'FINANCIAL', 'FIND',
    'FINDING', 'FINE', 'FINGER', 'FINISH', 'FIRE', 'FIRM', 'FIRST', 'FISH', 'FITNESS', 'FIVE',
    'FIXED', 'FLAG', 'FLAME', 'FLASH', 'FLAT', 'FLAVOR', 'FLESH', 'FLIGHT', 'FLOAT', 'FLOOD',
    'FLOOR', 'FLOW', 'FLOWER', 'FLYING', 'FOCUS', 'FOLK', 'FOLLOW', 'FOLLOWING', 'FOOD', 'FOOT',
    'FOOTBALL', 'FORCE', 'FOREIGN', 'FOREST', 'FOREVER', 'FORGET', 'FORM', 'FORMAL', 'FORMAT', 'FORMATION',
    'FORMER', 'FORMULA', 'FORTH', 'FORTUNE', 'FORWARD', 'FOUND', 'FOUNDATION', 'FOUNDER', 'FOUR', 'FOURTH',
    'FRAME', 'FRAMEWORK', 'FREE', 'FREEDOM', 'FRENCH', 'FREQUENCY', 'FREQUENT', 'FRESH', 'FRIEND', 'FRIENDLY',
    'FRONT', 'FRUIT', 'FUEL', 'FULL', 'FULLY', 'FUNCTION', 'FUND', 'FUNDAMENTAL', 'FUNDING', 'FUNNY',
    'FURNITURE', 'FURTHERMORE', 'FUTURE', 'GAIN', 'GALAXY', 'GALLERY', 'GAME', 'GANG', 'GARDEN', 'GARLIC',
    'GATHER', 'GAVE', 'GEAR', 'GENDER', 'GENE', 'GENERAL', 'GENERALLY', 'GENERATE', 'GENERATION', 'GENETIC',
    'GENRE', 'GENTLE', 'GENTLEMAN', 'GENUINE', 'GETTING', 'GHOST', 'GIANT', 'GIFT', 'GIRL', 'GIVE',
    'GIVEN', 'GLAD', 'GLANCE', 'GLASS', 'GLOBAL', 'GLORY', 'GOAL', 'GOLD', 'GOLDEN', 'GOLF',
    'GONE', 'GOOD', 'GOSPEL', 'GOVERN', 'GOVERNMENT', 'GOVERNOR', 'GRAB', 'GRACE', 'GRADE', 'GRAIN',
    'GRAND', 'GRANDFATHER', 'GRANDMOTHER', 'GRANT', 'GRAPH', 'GRASP', 'GRASS', 'GRAVE', 'GRAY', 'GREAT',
    'GREEN', 'GREY', 'GROCERY', 'GROUND', 'GROUP', 'GROW', 'GROWING', 'GROWTH', 'GUARANTEE', 'GUARD',
    'GUESS', 'GUEST', 'GUIDE', 'GUIDELINE', 'GUILTY', 'GUITAR', 'HABIT', 'HAIR', 'HALF', 'HALL',
    'HAND', 'HANDLE', 'HANG', 'HAPPEN', 'HAPPY', 'HARD', 'HARDLY', 'HARM', 'HATE', 'HAVE',
    'HEAD', 'HEADLINE', 'HEADQUARTERS', 'HEALTH', 'HEALTHY', 'HEAR', 'HEARING', 'HEART', 'HEAT', 'HEAVEN',
    'HEAVILY', 'HEAVY', 'HEIGHT', 'HELD', 'HELICOPTER', 'HELL', 'HELLO', 'HELP', 'HELPFUL', 'HERE',
    'HERO', 'HERSELF', 'HIDE', 'HIGH', 'HIGHLIGHT', 'HIGHLY', 'HILL', 'HIMSELF', 'HIRE', 'HISTORIAN',
    'HISTORIC', 'HISTORICAL', 'HISTORY', 'HOLD', 'HOLDER', 'HOLE', 'HOLIDAY', 'HOLY', 'HOME', 'HOMELESS',
    'HONEST', 'HONOR', 'HOPE', 'HORIZON', 'HORROR', 'HORSE', 'HOSPITAL', 'HOST', 'HOTEL', 'HOUR',
    'HOUSE', 'HOUSEHOLD', 'HOUSING', 'HOWEVER', 'HUGE', 'HUMAN', 'HUMOR', 'HUNDRED', 'HUNGRY', 'HUNT',
    'HUNTER', 'HUNTING', 'HURT', 'HUSBAND', 'IDEA', 'IDEAL', 'IDENTIFY', 'IDENTITY', 'IGNORE', 'ILLEGAL',
    'ILLNESS', 'IMAGE', 'IMAGINATION', 'IMAGINE', 'IMMEDIATE', 'IMMEDIATELY', 'IMMIGRANT', 'IMPACT', 'IMPLEMENT', 'IMPLICATION',
    'IMPLY', 'IMPORTANCE', 'IMPORTANT', 'IMPOSE', 'IMPOSSIBLE', 'IMPRESS', 'IMPRESSION', 'IMPRESSIVE', 'IMPROVE', 'IMPROVEMENT',
    'INCIDENT', 'INCLUDE', 'INCLUDING', 'INCOME', 'INCORPORATE', 'INCREASE', 'INCREASED', 'INCREASING', 'INCREDIBLE', 'INDEED',
    'INDEPENDENCE', 'INDEPENDENT', 'INDEX', 'INDIAN', 'INDICATE', 'INDICATION', 'INDIVIDUAL', 'INDUSTRIAL', 'INDUSTRY', 'INFANT',
    'INFECTION', 'INFLATION', 'INFLUENCE', 'INFORM', 'INFORMATION', 'INITIAL', 'INITIALLY', 'INITIATIVE', 'INJURY', 'INNER',
    'INNOCENT', 'INQUIRY', 'INSIDE', 'INSIGHT', 'INSIST', 'INSPIRE', 'INSTALL', 'INSTANCE', 'INSTEAD', 'INSTITUTION',
    'INSTRUCTION', 'INSTRUMENT', 'INSURANCE', 'INTELLECTUAL', 'INTELLIGENCE', 'INTEND', 'INTENSE', 'INTENSITY', 'INTENTION', 'INTEREST',
    'INTERESTED', 'INTERESTING', 'INTERNAL', 'INTERNATIONAL', 'INTERNET', 'INTERPRET', 'INTERVENTION', 'INTERVIEW', 'INTO', 'INTRODUCE',
    'INTRODUCTION', 'INVASION', 'INVEST', 'INVESTIGATE', 'INVESTIGATION', 'INVESTIGATOR', 'INVESTMENT', 'INVESTOR', 'INVITE', 'INVOLVE',
    'INVOLVED', 'INVOLVEMENT', 'IRON', 'ISLAND', 'ISSUE', 'ITEM', 'ITSELF', 'JACKET', 'JAIL', 'JAZZ',
    'JEWISH', 'JOIN', 'JOINT', 'JOKE', 'JOURNAL', 'JOURNALIST', 'JOURNEY', 'JUDGE', 'JUDGMENT', 'JUICE',
    'JUMP', 'JUNIOR', 'JURY', 'JUST', 'JUSTICE', 'JUSTIFY', 'KEEN', 'KEEP', 'KICK', 'KIDNEY',
    'KILL', 'KILLER', 'KILLING', 'KIND', 'KING', 'KISS', 'KITCHEN', 'KNEE', 'KNIFE', 'KNOCK',
    'KNOW', 'KNOWING', 'KNOWLEDGE', 'LABEL', 'LABOR', 'LABORATORY', 'LACK', 'LADY', 'LAKE', 'LAND',
    'LANDSCAPE', 'LANGUAGE', 'LAPTOP', 'LARGE', 'LARGELY', 'LAST', 'LATE', 'LATER', 'LATEST', 'LATIN',
    'LATTER', 'LAUGH', 'LAUNCH', 'LAWN', 'LAWSUIT', 'LAWYER', 'LAYER', 'LEAD', 'LEADER', 'LEADERSHIP',
    'LEADING', 'LEAF', 'LEAGUE', 'LEAN', 'LEARN', 'LEARNING', 'LEAST', 'LEATHER', 'LEAVE', 'LEFT',
    'LEGAL', 'LEGEND', 'LEGISLATION', 'LEGITIMATE', 'LEMON', 'LENGTH', 'LESS', 'LESSON', 'LETTER', 'LEVEL',
    'LIBERAL', 'LIBRARY', 'LICENSE', 'LIFE', 'LIFESTYLE', 'LIFETIME', 'LIFT', 'LIGHT', 'LIKE', 'LIKELY',
    'LIMIT', 'LIMITED', 'LINE', 'LINK', 'LIST', 'LISTEN', 'LITERARY', 'LITERATURE', 'LITTLE', 'LIVE',
    'LIVING', 'LOAD', 'LOAN', 'LOCAL', 'LOCATE', 'LOCATION', 'LOCK', 'LONG', 'LOOK', 'LOOSE',
    'LORD', 'LOSE', 'LOSS', 'LOST', 'LOTS', 'LOUD', 'LOVE', 'LOVELY', 'LOVER', 'LOWER',
    'LUCK', 'LUCKY', 'LUNCH', 'LUNG', 'MACHINE', 'MAGAZINE', 'MAGIC', 'MAIL', 'MAIN', 'MAINLY',
    'MAINSTREAM', 'MAINTAIN', 'MAINTENANCE', 'MAJOR', 'MAJORITY', 'MAKE', 'MAKER', 'MAKEUP', 'MALE', 'MALL',
    'MANAGE', 'MANAGEMENT', 'MANAGER', 'MANNER', 'MANUFACTURER', 'MANUFACTURING', 'MANY', 'MARGIN', 'MARK', 'MARKET',
    'MARKETING', 'MARRIAGE', 'MARRIED', 'MARRY', 'MASK', 'MASS', 'MASSIVE', 'MASTER', 'MATCH', 'MATERIAL',
    'MATH', 'MATTER', 'MAXIMUM', 'MAYBE', 'MAYOR', 'MEAL', 'MEAN', 'MEANING', 'MEANINGFUL', 'MEANS',
    'MEANWHILE', 'MEASURE', 'MEASUREMENT', 'MEAT', 'MECHANISM', 'MEDIA', 'MEDICAL', 'MEDICATION', 'MEDICINE', 'MEDIUM',
    'MEET', 'MEETING', 'MEMBER', 'MEMBERSHIP', 'MEMORY', 'MENTAL', 'MENTION', 'MENU', 'MERE', 'MERELY',
    'MERIT', 'MESSAGE', 'METAL', 'METHOD', 'MIDDLE', 'MIGHT', 'MILITARY', 'MILK', 'MILLION', 'MIND',
    'MINE', 'MINIMUM', 'MINISTER', 'MINOR', 'MINORITY', 'MINUTE', 'MIRACLE', 'MIRROR', 'MISS', 'MISSILE',
    'MISSION', 'MISTAKE', 'MODEL', 'MODERATE', 'MODERN', 'MODEST', 'MODIFY', 'MOMENT', 'MONEY', 'MONITOR',
    'MONTH', 'MONTHLY', 'MOOD', 'MOON', 'MORAL', 'MORE', 'MOREOVER', 'MORNING', 'MORTGAGE', 'MOST',
    'MOSTLY', 'MOTHER', 'MOTION', 'MOTIVATION', 'MOTOR', 'MOUNT', 'MOUNTAIN', 'MOUSE', 'MOUTH', 'MOVE',
    'MOVEMENT', 'MOVIE', 'MUCH', 'MULTIPLE', 'MURDER', 'MUSCLE', 'MUSEUM', 'MUSIC', 'MUSICAL', 'MUSICIAN',
    'MUSLIM', 'MUST', 'MUTUAL', 'MYSELF', 'MYSTERY', 'MYTH', 'NAKED', 'NAME', 'NARRATIVE', 'NARROW',
    'NATION', 'NATIONAL', 'NATIVE', 'NATURAL', 'NATURALLY', 'NATURE', 'NEAR', 'NEARBY', 'NEARLY', 'NECESSARILY',
    'NECESSARY', 'NECK', 'NEED', 'NEGATIVE', 'NEGOTIATE', 'NEGOTIATION', 'NEIGHBOR', 'NEIGHBORHOOD', 'NEITHER', 'NERVE',
    'NERVOUS', 'NETWORK', 'NEVER', 'NEVERTHELESS', 'NEWS', 'NEWSPAPER', 'NEXT', 'NICE', 'NIGHT', 'NINE',
    'NOBODY', 'NODE', 'NOISE', 'NOMINATION', 'NONE', 'NONETHELESS', 'NORMAL', 'NORMALLY', 'NORTH', 'NORTHERN',
    'NOSE', 'NOTE', 'NOTHING', 'NOTICE', 'NOTION', 'NOVEL', 'NOVEMBER', 'NOWHERE', 'NUCLEAR', 'NUMBER',
    'NUMEROUS', 'NURSE', 'OBJECT', 'OBJECTIVE', 'OBLIGATION', 'OBSERVATION', 'OBSERVE', 'OBSERVER', 'OBTAIN', 'OBVIOUS',
    'OBVIOUSLY', 'OCCASION', 'OCCASIONALLY', 'OCCUPATION', 'OCCUPY', 'OCCUR', 'OCEAN', 'OCTOBER', 'ODDS', 'OFFENSE',
    'OFFENSIVE', 'OFFER', 'OFFICE', 'OFFICER', 'OFFICIAL', 'OFTEN', 'OKAY', 'ONCE', 'ONGOING', 'ONION',
    'ONLINE', 'ONLY', 'ONTO', 'OPEN', 'OPENING', 'OPERATE', 'OPERATING', 'OPERATION', 'OPERATOR', 'OPINION',
    'OPPONENT', 'OPPORTUNITY', 'OPPOSE', 'OPPOSITE', 'OPPOSITION', 'OPTION', 'ORANGE', 'ORDER', 'ORDINARY', 'ORGAN',
    'ORGANIC', 'ORGANIZATION', 'ORGANIZE', 'ORIENTATION', 'ORIGIN', 'ORIGINAL', 'ORIGINALLY', 'OTHER', 'OTHERWISE', 'OUGHT',
    'OURSELVES', 'OUTCOME', 'OUTDOOR', 'OUTER', 'OUTLET', 'OUTLINE', 'OUTPUT', 'OUTSIDE', 'OUTSTANDING', 'OVERALL',
    'OVERCOME', 'OVERLOOK', 'OVERNIGHT', 'OVERSEAS', 'OVERWHELMING', 'OWNER', 'OWNERSHIP', 'PACE', 'PACK', 'PACKAGE',
    'PAGE', 'PAIN', 'PAINFUL', 'PAINT', 'PAINTER', 'PAINTING', 'PAIR', 'PALACE', 'PALE', 'PALM',
    'PANEL', 'PANIC', 'PAPER', 'PARENT', 'PARK', 'PARKING', 'PART', 'PARTICIPANT', 'PARTICIPATE', 'PARTICIPATION',
    'PARTICULAR', 'PARTICULARLY', 'PARTLY', 'PARTNER', 'PARTNERSHIP', 'PARTY', 'PASS', 'PASSAGE', 'PASSENGER', 'PASSING',
    'PASSION', 'PAST', 'PATH', 'PATIENCE', 'PATIENT', 'PATTERN', 'PAUSE', 'PAYMENT', 'PEACE', 'PEAK',
    'PEER', 'PENALTY', 'PENSION', 'PEOPLE', 'PEPPER', 'PERCENT', 'PERCENTAGE', 'PERCEPTION', 'PERFECT', 'PERFECTLY',
    'PERFORM', 'PERFORMANCE', 'PERHAPS', 'PERIOD', 'PERMANENT', 'PERMISSION', 'PERMIT', 'PERSON', 'PERSONAL', 'PERSONALITY',
    'PERSONALLY', 'PERSONNEL', 'PERSPECTIVE', 'PERSUADE', 'PHASE', 'PHENOMENON', 'PHILOSOPHY', 'PHONE', 'PHOTO', 'PHOTOGRAPH',
    'PHOTOGRAPHER', 'PHOTOGRAPHY', 'PHRASE', 'PHYSICAL', 'PHYSICALLY', 'PHYSICIAN', 'PIANO', 'PICK', 'PICTURE', 'PIECE',
    'PILE', 'PILOT', 'PINE', 'PINK', 'PIPE', 'PITCH', 'PLACE', 'PLAIN', 'PLAN', 'PLANE',
    'PLANET', 'PLANNING', 'PLANT', 'PLASTIC', 'PLATE', 'PLATFORM', 'PLAY', 'PLAYER', 'PLEASE', 'PLEASURE',
    'PLENTY', 'PLOT', 'PLUS', 'POCKET', 'POEM', 'POET', 'POETRY', 'POINT', 'POINTED', 'POLICE',
    'POLICY', 'POLITICAL', 'POLITICALLY', 'POLITICIAN', 'POLITICS', 'POLL', 'POLLUTION', 'POOL', 'POOR', 'POPULAR',
    'POPULARITY', 'POPULATION', 'PORCH', 'PORT', 'PORTION', 'PORTRAIT', 'PORTRAY', 'POSE', 'POSITION', 'POSITIVE',
    'POSSESS', 'POSSESSION', 'POSSIBILITY', 'POSSIBLE', 'POSSIBLY', 'POST', 'POTATO', 'POTENTIAL', 'POTENTIALLY', 'POUND',
    'POUR', 'POVERTY', 'POWDER', 'POWER', 'POWERFUL', 'PRACTICAL', 'PRACTICE', 'PRAY', 'PRAYER', 'PRECISELY',
    'PREDICT', 'PREFER', 'PREFERENCE', 'PREGNANCY', 'PREGNANT', 'PREMISE', 'PREMIUM', 'PREPARATION', 'PREPARE', 'PREPARED',
    'PRESCRIPTION', 'PRESENCE', 'PRESENT', 'PRESENTATION', 'PRESERVE', 'PRESIDENT', 'PRESIDENTIAL', 'PRESS', 'PRESSURE', 'PRESUMABLY',
    'PRETEND', 'PRETTY', 'PREVENT', 'PREVIOUS', 'PREVIOUSLY', 'PRICE', 'PRIDE', 'PRIEST', 'PRIMARY', 'PRIME',
    'PRINCE', 'PRINCIPAL', 'PRINCIPLE', 'PRINT', 'PRIOR', 'PRIORITY', 'PRISON', 'PRISONER', 'PRIVACY', 'PRIVATE',
    'PRIZE', 'PROBABLY', 'PROBLEM', 'PROCEDURE', 'PROCEED', 'PROCESS', 'PRODUCE', 'PRODUCER', 'PRODUCT', 'PRODUCTION',
    'PROFESSION', 'PROFESSIONAL', 'PROFESSOR', 'PROFILE', 'PROFIT', 'PROGRAM', 'PROGRESS', 'PROJECT', 'PROMINENT', 'PROMISE',
    'PROMOTE', 'PROMOTION', 'PROMPT', 'PROOF', 'PROPER', 'PROPERLY', 'PROPERTY', 'PROPORTION', 'PROPOSAL', 'PROPOSE',
    'PROPOSED', 'PROSECUTOR', 'PROSPECT', 'PROTECT', 'PROTECTION', 'PROTEIN', 'PROTEST', 'PROUD', 'PROVE', 'PROVIDE',
    'PROVIDER', 'PROVINCE', 'PROVISION', 'PSYCHOLOGICAL', 'PSYCHOLOGY', 'PUBLIC', 'PUBLICATION', 'PUBLICLY', 'PUBLISH', 'PUBLISHER',
    'PULL', 'PULSE', 'PUMP', 'PUNCH', 'PUNISHMENT', 'PURCHASE', 'PURE', 'PURPLE', 'PURPOSE', 'PURSUE',
    'PUSH', 'PUTTING', 'QUALIFY', 'QUALITY', 'QUANTITY', 'QUARTER', 'QUEEN', 'QUESTION', 'QUICK', 'QUICKLY',
    'QUIET', 'QUIETLY', 'QUIT', 'QUITE', 'QUOTE', 'RACE', 'RACIAL', 'RACING', 'RADICAL', 'RADIO',
    'RAGE', 'RAIL', 'RAIN', 'RAISE', 'RANGE', 'RANK', 'RAPID', 'RAPIDLY', 'RARE', 'RARELY',
    'RATE', 'RATHER', 'RATING', 'RATIO', 'REACH', 'REACT', 'REACTION', 'READ', 'READER', 'READING',
    'READY', 'REAL', 'REALISTIC', 'REALITY', 'REALIZE', 'REALLY', 'REASON', 'REASONABLE', 'RECALL', 'RECEIVE',
    'RECENT', 'RECENTLY', 'RECIPE', 'RECOGNITION', 'RECOGNIZE', 'RECOMMEND', 'RECOMMENDATION', 'RECORD', 'RECORDING', 'RECOVER',
    'RECOVERY', 'RECRUIT', 'REDUCE', 'REDUCTION', 'REFER', 'REFERENCE', 'REFLECT', 'REFLECTION', 'REFORM', 'REFUGEE',
    'REFUSE', 'REGARD', 'REGARDING', 'REGARDLESS', 'REGIME', 'REGION', 'REGIONAL', 'REGISTER', 'REGULAR', 'REGULARLY',
    'REGULATE', 'REGULATION', 'REINFORCE', 'REJECT', 'RELATE', 'RELATED', 'RELATION', 'RELATIONSHIP', 'RELATIVE', 'RELATIVELY',
    'RELAX', 'RELEASE', 'RELEVANT', 'RELIEF', 'RELIGION', 'RELIGIOUS', 'RELY', 'REMAIN', 'REMAINING', 'REMARKABLE',
    'REMEMBER', 'REMIND', 'REMOTE', 'REMOVE', 'REPEAT', 'REPEATEDLY', 'REPLACE', 'REPLACEMENT', 'REPLY', 'REPORT',
    'REPORTER', 'REPRESENT', 'REPRESENTATION', 'REPRESENTATIVE', 'REPUBLIC', 'REPUBLICAN', 'REPUTATION', 'REQUEST', 'REQUIRE', 'REQUIREMENT',
    'RESCUE', 'RESEARCH', 'RESEARCHER', 'RESERVATION', 'RESERVE', 'RESIDENT', 'RESIDENTIAL', 'RESIGN', 'RESIST', 'RESISTANCE',
    'RESOLUTION', 'RESOLVE', 'RESORT', 'RESOURCE', 'RESPECT', 'RESPOND', 'RESPONDENT', 'RESPONSE', 'RESPONSIBILITY', 'RESPONSIBLE',
    'REST', 'RESTAURANT', 'RESTORE', 'RESTRICTION', 'RESULT', 'RETAIN', 'RETIRE', 'RETIREMENT', 'RETURN', 'REVEAL',
    'REVENUE', 'REVERSE', 'REVIEW', 'REVOLUTION', 'REWARD', 'RHETORIC', 'RHYTHM', 'RICE', 'RICH', 'RIDE',
    'RIDER', 'RIDICULOUS', 'RIGHT', 'RING', 'RISE', 'RISING', 'RISK', 'RIVER', 'ROAD', 'ROBOT',
    'ROCK', 'ROLE', 'ROLL', 'ROMANTIC', 'ROOF', 'ROOM', 'ROOT', 'ROPE', 'ROSE', 'ROUGH',
    'ROUGHLY', 'ROUND', 'ROUTE', 'ROUTINE', 'ROYAL', 'RUBBISH', 'RULE', 'RULING', 'RUNNING', 'RURAL',
    'RUSH', 'SACRED', 'SACRIFICE', 'SADLY', 'SAFE', 'SAFETY', 'SAKE', 'SALAD', 'SALARY', 'SALE',
    'SALES', 'SALT', 'SAME', 'SAMPLE', 'SANCTION', 'SAND', 'SATELLITE', 'SATISFACTION', 'SATISFY', 'SAUCE',
    'SAVE', 'SAVING', 'SCALE', 'SCANDAL', 'SCARED', 'SCENARIO', 'SCENE', 'SCHEDULE', 'SCHEME', 'SCHOLAR',
    'SCHOLARSHIP', 'SCHOOL', 'SCIENCE', 'SCIENTIFIC', 'SCIENTIST', 'SCOPE', 'SCORE', 'SCREEN', 'SCRIPT', 'SCULPTURE',
    'SEARCH', 'SEASON', 'SEAT', 'SECOND', 'SECONDARY', 'SECRET', 'SECRETARY', 'SECTION', 'SECTOR', 'SECURE',
    'SECURITY', 'SEED', 'SEEK', 'SEEM', 'SEGMENT', 'SEIZE', 'SELECT', 'SELECTION', 'SELF', 'SELL',
    'SENATE', 'SENATOR', 'SEND', 'SENIOR', 'SENSE', 'SENSITIVE', 'SENTENCE', 'SEPARATE', 'SEQUENCE', 'SERIES',
    'SERIOUS', 'SERIOUSLY', 'SERVANT', 'SERVE', 'SERVER', 'SERVICE', 'SESSION', 'SETTING', 'SETTLE', 'SETTLEMENT',
    'SEVEN', 'SEVERAL', 'SEVERE', 'SHAKE', 'SHALL', 'SHAME', 'SHAPE', 'SHARE', 'SHARP', 'SHEET',
    'SHELF', 'SHELL', 'SHELTER', 'SHIFT', 'SHINE', 'SHIP', 'SHIRT', 'SHOCK', 'SHOE', 'SHOOT',
    'SHOOTING', 'SHOP', 'SHOPPING', 'SHORE', 'SHORT', 'SHORTLY', 'SHOT', 'SHOULD', 'SHOULDER', 'SHOUT',
    'SHOW', 'SHOWER', 'SHUT', 'SICK', 'SIDE', 'SIGHT', 'SIGN', 'SIGNAL', 'SIGNATURE', 'SIGNIFICANCE',
    'SIGNIFICANT', 'SIGNIFICANTLY', 'SILENCE', 'SILENT', 'SILVER', 'SIMILAR', 'SIMILARLY', 'SIMPLE', 'SIMPLY', 'SINCE',
    'SING', 'SINGER', 'SINGLE', 'SINK', 'SISTER', 'SITE', 'SITUATION', 'SIZE', 'SKILL', 'SKIN',
    'SLEEP', 'SLICE', 'SLIDE', 'SLIGHT', 'SLIGHTLY', 'SLIP', 'SLOW', 'SLOWLY', 'SMALL', 'SMART',
    'SMELL', 'SMILE', 'SMOKE', 'SMOKING', 'SMOOTH', 'SNAP', 'SNOW', 'SOCCER', 'SOCIAL', 'SOCIETY',
    'SOFT', 'SOFTWARE', 'SOIL', 'SOLAR', 'SOLDIER', 'SOLE', 'SOLELY', 'SOLID', 'SOLUTION', 'SOLVE',
    'SOME', 'SOMEBODY', 'SOMEHOW', 'SOMEONE', 'SOMETHING', 'SOMETIMES', 'SOMEWHAT', 'SOMEWHERE', 'SONG', 'SOON',
    'SOPHISTICATED', 'SORRY', 'SORT', 'SOUL', 'SOUND', 'SOUP', 'SOURCE', 'SOUTH', 'SOUTHERN', 'SPACE',
    'SPAN', 'SPANISH', 'SPARE', 'SPEAK', 'SPEAKER', 'SPEAKING', 'SPECIAL', 'SPECIALIST', 'SPECIES', 'SPECIFIC',
    'SPECIFICALLY', 'SPEECH', 'SPEED', 'SPEND', 'SPENDING', 'SPIN', 'SPIRIT', 'SPIRITUAL', 'SPLIT', 'SPOKESMAN',
    'SPONSOR', 'SPORT', 'SPOT', 'SPREAD', 'SPRING', 'SQUAD', 'SQUARE', 'SQUEEZE', 'STABILITY', 'STABLE',
    'STACK', 'STAFF', 'STAGE', 'STAIR', 'STAKE', 'STAND', 'STANDARD', 'STANDING', 'STAR', 'STARE',
    'START', 'STATE', 'STATEMENT', 'STATION', 'STATISTICAL', 'STATISTICS', 'STATUS', 'STAY', 'STEADY', 'STEAL',
    'STEAM', 'STEEL', 'STEEP', 'STEM', 'STEP', 'STICK', 'STIFF', 'STILL', 'STIMULUS', 'STOCK',
    'STOMACH', 'STONE', 'STOP', 'STORAGE', 'STORE', 'STORM', 'STORY', 'STRAIGHT', 'STRAIN', 'STRANGE',
    'STRANGER', 'STRATEGIC', 'STRATEGY', 'STREAM', 'STREET', 'STRENGTH', 'STRENGTHEN', 'STRESS', 'STRETCH', 'STRICT',
    'STRIKE', 'STRING', 'STRIP', 'STROKE', 'STRONG', 'STRONGLY', 'STRUCTURAL', 'STRUCTURE', 'STRUGGLE', 'STUDENT',
    'STUDIO', 'STUDY', 'STUFF', 'STUPID', 'STYLE', 'SUBJECT', 'SUBMIT', 'SUBSEQUENT', 'SUBSTANCE', 'SUBSTANTIAL',
    'SUBTLE', 'SUCCEED', 'SUCCESS', 'SUCCESSFUL', 'SUCCESSFULLY', 'SUCH', 'SUDDEN', 'SUDDENLY', 'SUFFER', 'SUFFICIENT',
    'SUGAR', 'SUGGEST', 'SUGGESTION', 'SUICIDE', 'SUIT', 'SUMMER', 'SUMMIT', 'SUPER', 'SUPPLY', 'SUPPORT',
    'SUPPORTER', 'SUPPOSE', 'SUPPOSED', 'SUPREME', 'SURE', 'SURELY', 'SURFACE', 'SURGERY', 'SURPRISE', 'SURPRISED',
    'SURPRISING', 'SURPRISINGLY', 'SURROUND', 'SURVEY', 'SURVIVAL', 'SURVIVE', 'SURVIVOR', 'SUSPECT', 'SUSPEND', 'SUSTAIN',
    'SWEAR', 'SWEEP', 'SWEET', 'SWIM', 'SWING', 'SWITCH', 'SYMBOL', 'SYMPTOM', 'SYSTEM', 'TABLE',
    'TABLET', 'TACTIC', 'TAIL', 'TAKE', 'TALE', 'TALENT', 'TALK', 'TALKING', 'TALL', 'TANK',
    'TAPE', 'TARGET', 'TASK', 'TASTE', 'TEACHER', 'TEACHING', 'TEAM', 'TEAR', 'TECHNICAL', 'TECHNIQUE',
    'TECHNOLOGY', 'TEENAGE', 'TEENAGER', 'TELEPHONE', 'TELEVISION', 'TELL', 'TEMPERATURE', 'TEMPLE', 'TEMPORARY', 'TEND',
    'TENDENCY', 'TENSION', 'TENT', 'TERM', 'TERMS', 'TERRIBLE', 'TERRITORY', 'TERROR', 'TERRORISM', 'TERRORIST',
    'TEST', 'TESTIFY', 'TESTIMONY', 'TESTING', 'TEXT', 'THAN', 'THANK', 'THANKS', 'THAT', 'THEATER',
    'THEME', 'THEMSELVES', 'THEN', 'THEORY', 'THERAPY', 'THERE', 'THEREBY', 'THEREFORE', 'THICK', 'THIN',
    'THING', 'THINK', 'THINKING', 'THIRD', 'THIRTY', 'THIS', 'THOROUGH', 'THOSE', 'THOUGH', 'THOUGHT',
    'THOUSAND', 'THREAD', 'THREAT', 'THREATEN', 'THREE', 'THROAT', 'THROUGH', 'THROUGHOUT', 'THROW', 'THUS',
    'TICKET', 'TIGHT', 'TIME', 'TINY', 'TIRE', 'TIRED', 'TISSUE', 'TITLE', 'TODAY', 'TOGETHER',
    'TOLERANCE', 'TOLL', 'TOMATO', 'TOMORROW', 'TONE', 'TONGUE', 'TONIGHT', 'TOOL', 'TOOTH', 'TOPIC',
    'TOTAL', 'TOTALLY', 'TOUCH', 'TOUGH', 'TOUR', 'TOURIST', 'TOURNAMENT', 'TOWARD', 'TOWARDS', 'TOWER',
    'TOWN', 'TRACK', 'TRADE', 'TRADITION', 'TRADITIONAL', 'TRAFFIC', 'TRAGEDY', 'TRAIL', 'TRAIN', 'TRAINER',
    'TRAINING', 'TRANSFER', 'TRANSFORM', 'TRANSFORMATION', 'TRANSITION', 'TRANSLATE', 'TRANSMISSION', 'TRANSPORT', 'TRANSPORTATION', 'TRAP',
    'TRAVEL', 'TREAT', 'TREATMENT', 'TREATY', 'TREE', 'TREMENDOUS', 'TREND', 'TRIAL', 'TRIBE', 'TRIBUTE',
    'TRICK', 'TRIGGER', 'TRILLION', 'TRIP', 'TROOP', 'TROUBLE', 'TRUCK', 'TRUE', 'TRULY', 'TRUST',
    'TRUTH', 'TUBE', 'TUNNEL', 'TURN', 'TWELVE', 'TWENTY', 'TWICE', 'TWIN', 'TYPE', 'TYPICAL',
    'TYPICALLY', 'UGLY', 'ULTIMATE', 'ULTIMATELY', 'UNABLE', 'UNCLE', 'UNDER', 'UNDERGO', 'UNDERSTAND', 'UNDERSTANDING',
    'UNFORTUNATELY', 'UNIFORM', 'UNION', 'UNIQUE', 'UNIT', 'UNITED', 'UNITY', 'UNIVERSAL', 'UNIVERSE', 'UNIVERSITY',
    'UNKNOWN', 'UNLESS', 'UNLIKE', 'UNLIKELY', 'UNTIL', 'UNUSUAL', 'UPDATE', 'UPON', 'UPPER', 'UPSET',
    'URBAN', 'URGE', 'USED', 'USEFUL', 'USER', 'USUAL', 'USUALLY', 'UTILITY', 'VACATION', 'VALID',
    'VALLEY', 'VALUABLE', 'VALUE', 'VARIABLE', 'VARIATION', 'VARIETY', 'VARIOUS', 'VARY', 'VAST', 'VEGETABLE',
    'VEHICLE', 'VENTURE', 'VERSION', 'VERSUS', 'VERY', 'VESSEL', 'VETERAN', 'VICTIM', 'VICTORY', 'VIDEO',
    'VIEW', 'VIEWER', 'VILLAGE', 'VIOLATE', 'VIOLATION', 'VIOLENCE', 'VIOLENT', 'VIRTUAL', 'VIRTUALLY', 'VIRTUE',
    'VIRUS', 'VISIBLE', 'VISION', 'VISIT', 'VISITOR', 'VISUAL', 'VITAL', 'VOICE', 'VOLUME', 'VOLUNTEER',
    'VOTE', 'VOTER', 'VULNERABLE', 'WAGE', 'WAIT', 'WAKE', 'WALK', 'WALL', 'WANDER', 'WANT',
    'WARM', 'WARN', 'WARNING', 'WASH', 'WASTE', 'WATCH', 'WATER', 'WAVE', 'WEAK', 'WEALTH',
    'WEALTHY', 'WEAPON', 'WEAR', 'WEATHER', 'WEDDING', 'WEEK', 'WEEKEND', 'WEEKLY', 'WEIGH', 'WEIGHT',
    'WEIRD', 'WELCOME', 'WELFARE', 'WELL', 'WEST', 'WESTERN', 'WHATEVER', 'WHEEL', 'WHENEVER', 'WHERE',
    'WHEREAS', 'WHETHER', 'WHICH', 'WHILE', 'WHISPER', 'WHITE', 'WHOLE', 'WHOM', 'WHOSE', 'WIDE',
    'WIDELY', 'WIDESPREAD', 'WIFE', 'WILD', 'WILDLIFE', 'WILL', 'WILLING', 'WIND', 'WINDOW', 'WINE',
    'WING', 'WINNER', 'WINTER', 'WIRE', 'WISDOM', 'WISE', 'WISH', 'WITH', 'WITHDRAW', 'WITHIN',
    'WITHOUT', 'WITNESS', 'WOMAN', 'WOMEN', 'WONDER', 'WONDERFUL', 'WOOD', 'WOODEN', 'WORD', 'WORK',
    'WORKER', 'WORKING', 'WORKOUT', 'WORKPLACE', 'WORKSHOP', 'WORLD', 'WORRIED', 'WORRY', 'WORSE', 'WORST',
    'WORTH', 'WOULD', 'WOUND', 'WRAP', 'WRITE', 'WRITER', 'WRITING', 'WRONG', 'YARD', 'YEAH',
    'YEAR', 'YELLOW', 'YESTERDAY', 'YIELD', 'YOUNG', 'YOUNGSTER', 'YOUR', 'YOURS', 'YOURSELF', 'YOUTH',
    'ZERO', 'ZONE',
  ];

  generate(difficulty: 'easy' | 'medium' | 'hard' | 'expert'): {
    puzzleData: {
      letters: string[];
      centerLetter: string;
      validWords: string[];
      pangrams: string[];
    };
    solution: {
      allWords: string[];
      pangrams: string[];
      maxScore: number;
    };
  } {
    // Try to find a good letter set with enough words
    let bestResult = this.tryGeneratePuzzle();
    let attempts = 0;
    const maxAttempts = 50;

    // Target word counts based on difficulty
    const minWords = { easy: 15, medium: 25, hard: 35, expert: 50 }[difficulty];

    while (bestResult.validWords.length < minWords && attempts < maxAttempts) {
      const newResult = this.tryGeneratePuzzle();
      if (newResult.validWords.length > bestResult.validWords.length) {
        bestResult = newResult;
      }
      attempts++;
    }

    // Calculate score
    const maxScore = this.calculateMaxScore(bestResult.validWords, bestResult.pangrams);

    return {
      puzzleData: {
        letters: bestResult.letters,
        centerLetter: bestResult.centerLetter,
        validWords: bestResult.validWords,
        pangrams: bestResult.pangrams,
      },
      solution: {
        allWords: bestResult.validWords,
        pangrams: bestResult.pangrams,
        maxScore,
      },
    };
  }

  private tryGeneratePuzzle(): {
    letters: string[];
    centerLetter: string;
    validWords: string[];
    pangrams: string[];
  } {
    // Pick 7 unique letters
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const letters: string[] = [];

    while (letters.length < 7) {
      const letter = alphabet[Math.floor(Math.random() * alphabet.length)];
      if (!letters.includes(letter)) {
        letters.push(letter);
      }
    }

    // Pick center letter (first letter becomes center)
    const centerLetter = letters[0];
    const letterSet = new Set(letters);

    // Find all valid words
    const validWords: string[] = [];
    const pangrams: string[] = [];

    for (const word of WordForgeGenerator.WORD_LIST) {
      if (word.length < 4) continue;
      if (!word.includes(centerLetter)) continue;

      // Check if word only uses our letters
      let valid = true;
      const usedLetters = new Set<string>();

      for (const char of word) {
        if (!letterSet.has(char)) {
          valid = false;
          break;
        }
        usedLetters.add(char);
      }

      if (valid) {
        validWords.push(word);
        // Check if it's a pangram (uses all 7 letters)
        if (usedLetters.size === 7) {
          pangrams.push(word);
        }
      }
    }

    return { letters, centerLetter, validWords, pangrams };
  }

  private calculateMaxScore(words: string[], pangrams: string[]): number {
    let score = 0;
    for (const word of words) {
      if (word.length === 4) {
        score += 1;
      } else {
        score += word.length;
      }
      if (pangrams.includes(word)) {
        score += 7; // Pangram bonus
      }
    }
    return score;
  }
}

// Nonogram Generator
export class NonogramGenerator {
  generate(difficulty: 'easy' | 'medium' | 'hard' | 'expert'): {
    puzzleData: {
      rows: number;
      cols: number;
      rowClues: number[][];
      colClues: number[][];
    };
    solution: {
      grid: number[][];
    };
  } {
    // Grid size based on difficulty
    const size = { easy: 5, medium: 10, hard: 12, expert: 15 }[difficulty];

    // Generate a random pattern with some structure
    const grid = this.generatePattern(size, size, difficulty);

    // Generate clues from the pattern
    const rowClues = this.generateRowClues(grid);
    const colClues = this.generateColClues(grid);

    return {
      puzzleData: {
        rows: size,
        cols: size,
        rowClues,
        colClues,
      },
      solution: {
        grid,
      },
    };
  }

  private generatePattern(rows: number, cols: number, difficulty: string): number[][] {
    const grid: number[][] = Array(rows).fill(null).map(() => Array(cols).fill(0));

    // Fill density based on difficulty (easier = more filled = clearer patterns)
    const fillProbability = { easy: 0.6, medium: 0.5, hard: 0.45, expert: 0.4 }[difficulty] || 0.5;

    // Generate pattern with some symmetry for visual appeal
    const useSymmetry = Math.random() < 0.5;

    for (let r = 0; r < rows; r++) {
      for (let c = 0; c < cols; c++) {
        if (Math.random() < fillProbability) {
          grid[r][c] = 1;

          // Apply symmetry if enabled
          if (useSymmetry) {
            // Vertical symmetry
            grid[r][cols - 1 - c] = 1;
          }
        }
      }
    }

    // Ensure puzzle is solvable by having at least some clues
    // Add a simple shape in the middle for easier puzzles
    if (difficulty === 'easy') {
      const mid = Math.floor(rows / 2);
      for (let i = -1; i <= 1; i++) {
        for (let j = -1; j <= 1; j++) {
          if (mid + i >= 0 && mid + i < rows && mid + j >= 0 && mid + j < cols) {
            grid[mid + i][mid + j] = 1;
          }
        }
      }
    }

    return grid;
  }

  private generateRowClues(grid: number[][]): number[][] {
    const clues: number[][] = [];

    for (const row of grid) {
      const rowClue: number[] = [];
      let count = 0;

      for (const cell of row) {
        if (cell === 1) {
          count++;
        } else if (count > 0) {
          rowClue.push(count);
          count = 0;
        }
      }

      if (count > 0) {
        rowClue.push(count);
      }

      // Empty row gets [0] as clue
      clues.push(rowClue.length > 0 ? rowClue : [0]);
    }

    return clues;
  }

  private generateColClues(grid: number[][]): number[][] {
    const clues: number[][] = [];
    const cols = grid[0].length;

    for (let c = 0; c < cols; c++) {
      const colClue: number[] = [];
      let count = 0;

      for (let r = 0; r < grid.length; r++) {
        if (grid[r][c] === 1) {
          count++;
        } else if (count > 0) {
          colClue.push(count);
          count = 0;
        }
      }

      if (count > 0) {
        colClue.push(count);
      }

      clues.push(colClue.length > 0 ? colClue : [0]);
    }

    return clues;
  }
}

// Number Target Generator (Make 10/24/etc)
export class NumberTargetGenerator {
  generate(difficulty: 'easy' | 'medium' | 'hard' | 'expert'): {
    puzzleData: {
      numbers: number[];
      target: number;
    };
    solution: {
      expression: string;
      alternates: string[];
    };
  } {
    // Target based on difficulty
    const targets = { easy: 10, medium: 24, hard: 100, expert: this.randomTarget() };
    const target = targets[difficulty];

    // Number ranges based on difficulty
    const ranges = {
      easy: { min: 1, max: 9 },
      medium: { min: 1, max: 13 },
      hard: { min: 1, max: 25 },
      expert: { min: 1, max: 100 },
    };
    const range = ranges[difficulty];

    // Generate solvable puzzle
    let result = this.generateSolvablePuzzle(target, range, difficulty);
    let attempts = 0;

    while (!result && attempts < 100) {
      result = this.generateSolvablePuzzle(target, range, difficulty);
      attempts++;
    }

    if (!result) {
      // Fallback to known solvable puzzle
      result = {
        numbers: [1, 2, 3, 4],
        expression: '(1+2+3)*4',
        alternates: ['4*(1+2+3)', '(3+2+1)*4'],
      };
    }

    return {
      puzzleData: {
        numbers: result.numbers,
        target,
      },
      solution: {
        expression: result.expression,
        alternates: result.alternates,
      },
    };
  }

  private randomTarget(): number {
    const targets = [10, 24, 42, 50, 100, 1000];
    return targets[Math.floor(Math.random() * targets.length)];
  }

  private generateSolvablePuzzle(
    target: number,
    range: { min: number; max: number },
    difficulty: string
  ): { numbers: number[]; expression: string; alternates: string[] } | null {
    // Generate 4 random numbers
    const numbers: number[] = [];
    for (let i = 0; i < 4; i++) {
      numbers.push(Math.floor(Math.random() * (range.max - range.min + 1)) + range.min);
    }

    // Try to find expressions that evaluate to target
    const solutions = this.findSolutions(numbers, target);

    if (solutions.length > 0) {
      return {
        numbers,
        expression: solutions[0],
        alternates: solutions.slice(1, 4), // Keep up to 3 alternates
      };
    }

    return null;
  }

  private findSolutions(numbers: number[], target: number): string[] {
    const solutions: string[] = [];
    const ops = ['+', '-', '*', '/'];

    // Generate all permutations of numbers
    const perms = this.permutations(numbers);

    for (const perm of perms) {
      // Try all combinations of operators
      for (const op1 of ops) {
        for (const op2 of ops) {
          for (const op3 of ops) {
            // Different groupings with parentheses
            const expressions = [
              `((${perm[0]}${op1}${perm[1]})${op2}${perm[2]})${op3}${perm[3]}`,
              `(${perm[0]}${op1}(${perm[1]}${op2}${perm[2]}))${op3}${perm[3]}`,
              `(${perm[0]}${op1}${perm[1]})${op2}(${perm[2]}${op3}${perm[3]})`,
              `${perm[0]}${op1}((${perm[1]}${op2}${perm[2]})${op3}${perm[3]})`,
              `${perm[0]}${op1}(${perm[1]}${op2}(${perm[2]}${op3}${perm[3]}))`,
            ];

            for (const expr of expressions) {
              try {
                // Safe evaluation using Function
                const result = Function(`"use strict"; return (${expr})`)();
                if (Math.abs(result - target) < 0.0001 && !solutions.includes(expr)) {
                  solutions.push(expr);
                  if (solutions.length >= 5) return solutions;
                }
              } catch {
                // Invalid expression, skip
              }
            }
          }
        }
      }
    }

    return solutions;
  }

  private permutations<T>(arr: T[]): T[][] {
    if (arr.length <= 1) return [arr];

    const result: T[][] = [];
    for (let i = 0; i < arr.length; i++) {
      const rest = [...arr.slice(0, i), ...arr.slice(i + 1)];
      const perms = this.permutations(rest);
      for (const perm of perms) {
        result.push([arr[i], ...perm]);
      }
    }
    return result;
  }
}

// Export convenience functions
export const generateWordForge = (difficulty: 'easy' | 'medium' | 'hard' | 'expert') => {
  const generator = new WordForgeGenerator();
  return generator.generate(difficulty);
};

export const generateNonogram = (difficulty: 'easy' | 'medium' | 'hard' | 'expert') => {
  const generator = new NonogramGenerator();
  return generator.generate(difficulty);
};

export const generateNumberTarget = (difficulty: 'easy' | 'medium' | 'hard' | 'expert') => {
  const generator = new NumberTargetGenerator();
  return generator.generate(difficulty);
};
