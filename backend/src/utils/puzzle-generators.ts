/**
 * Puzzle Generator Utilities
 *
 * These utilities help generate valid puzzles programmatically.
 * Can be used to auto-generate daily puzzles.
 */

// Sudoku Generator
export class SudokuGenerator {
  private grid: number[][] = [];

  generate(difficulty: "easy" | "medium" | "hard" | "expert"): {
    grid: number[][];
    solution: number[][];
  } {
    // Generate a complete valid Sudoku
    this.grid = Array(9)
      .fill(null)
      .map(() => Array(9).fill(0));
    this.fillGrid();

    const solution = this.grid.map((row) => [...row]);

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
      Array.from({ length: 81 }, (_, i) => [Math.floor(i / 9), i % 9]),
    );

    for (const [row, col] of positions) {
      if (removed >= count) break;
      if (this.grid[row][col] !== 0) {
        const backup = this.grid[row][col];
        this.grid[row][col] = 0;

        // Check if puzzle still has unique solution
        if (this.countSolutions(0) === 1) {
          removed++;
        } else {
          // Restore the cell - removing it creates multiple solutions
          this.grid[row][col] = backup;
        }
      }
    }
  }

  // Count solutions (stops at 2 since we only need to know if unique)
  private countSolutions(count: number): number {
    if (count > 1) return count; // Early exit - already found multiple

    const emptyCell = this.findEmptyCell();
    if (!emptyCell) return count + 1; // Found a complete solution

    const [row, col] = emptyCell;

    for (let num = 1; num <= 9; num++) {
      if (this.isValid(row, col, num)) {
        this.grid[row][col] = num;
        count = this.countSolutions(count);
        this.grid[row][col] = 0;

        if (count > 1) return count; // Early exit
      }
    }

    return count;
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
    theme?: string,
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
    this.grid = Array(rows)
      .fill(null)
      .map(() => Array(cols).fill(""));

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
      [0, 1], // right
      [1, 0], // down
      [1, 1], // diagonal down-right
      [-1, 1], // diagonal up-right
      [0, -1], // left
      [-1, 0], // up
      [-1, -1], // diagonal up-left
      [1, -1], // diagonal down-left
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
    const letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    for (let r = 0; r < rows; r++) {
      for (let c = 0; c < cols; c++) {
        if (this.grid[r][c] === "") {
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
    colDir: number,
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

      if (existing !== "" && existing !== word[i]) {
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
    colDir: number,
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

  generate(difficulty: "easy" | "medium" | "hard" | "expert"): {
    grid: number[][];
    solution: number[][];
    cages: Array<{ sum: number; cells: number[][] }>;
  } {
    // First generate a complete Sudoku solution
    const sudokuGen = new SudokuGenerator();
    const sudoku = sudokuGen.generate("easy"); // We need the full solution
    this.solution = sudoku.solution;

    // Create empty grid
    this.grid = Array(9)
      .fill(null)
      .map(() => Array(9).fill(0));

    // Generate cages based on difficulty
    const cages = this.generateCages(difficulty);

    // Add pre-set (given) numbers based on difficulty
    this.addGivens(difficulty, cages);

    // Verify unique solution and add more givens if needed
    this.ensureUniqueSolution(cages);

    return {
      grid: this.grid,
      solution: this.solution,
      cages,
    };
  }

  /**
   * Ensures the puzzle has a unique solution by adding givens if necessary
   */
  private ensureUniqueSolution(
    cages: Array<{ sum: number; cells: number[][] }>,
  ): void {
    const maxAttempts = 30; // Safety limit
    let attempts = 0;

    while (!this.hasUniqueSolution(cages) && attempts < maxAttempts) {
      attempts++;
      // Find an empty cell and add the solution value as a given
      const emptyCell = this.findStrategicEmptyCell(cages);
      if (emptyCell) {
        const [row, col] = emptyCell;
        this.grid[row][col] = this.solution[row][col];
      } else {
        break; // No more empty cells to fill
      }
    }
  }

  /**
   * Find an empty cell that would help constrain the puzzle
   * Prioritizes cells in larger cages or cells with fewer constraints
   */
  private findStrategicEmptyCell(
    cages: Array<{ sum: number; cells: number[][] }>,
  ): [number, number] | null {
    // Collect empty cells with their cage sizes
    const emptyCells: { cell: [number, number]; cageSize: number }[] = [];

    for (const cage of cages) {
      for (const [row, col] of cage.cells) {
        if (this.grid[row][col] === 0) {
          emptyCells.push({ cell: [row, col], cageSize: cage.cells.length });
        }
      }
    }

    if (emptyCells.length === 0) return null;

    // Prioritize cells in larger cages (more ambiguous)
    emptyCells.sort((a, b) => b.cageSize - a.cageSize);

    // Pick from top candidates with some randomness
    const topCandidates = emptyCells.slice(
      0,
      Math.min(5, emptyCells.length),
    );
    const chosen =
      topCandidates[Math.floor(Math.random() * topCandidates.length)];
    return chosen.cell;
  }

  /**
   * Check if the puzzle has exactly one solution
   * Uses MRV (Minimum Remaining Values) heuristic for efficiency
   */
  private hasUniqueSolution(
    cages: Array<{ sum: number; cells: number[][] }>,
  ): boolean {
    const testGrid = this.grid.map((row) => [...row]);
    let solutionCount = 0;
    let iterations = 0;
    const maxIterations = 100000; // Limit to prevent infinite loops

    const countSolutions = (g: number[][]): void => {
      if (solutionCount > 1) return; // Early exit
      if (iterations++ > maxIterations) {
        solutionCount = 2; // Assume not unique if too complex
        return;
      }

      const emptyCell = this.findBestEmptyCell(g, cages);
      if (!emptyCell) {
        solutionCount++;
        return;
      }

      const [row, col] = emptyCell;

      for (let num = 1; num <= 9; num++) {
        if (this.isValidKillerPlacement(g, row, col, num, cages)) {
          g[row][col] = num;
          countSolutions(g);
          if (solutionCount > 1) return;
          g[row][col] = 0;
        }
      }
    };

    countSolutions(testGrid);
    return solutionCount === 1;
  }

  /**
   * Find the empty cell with fewest valid candidates (MRV heuristic)
   */
  private findBestEmptyCell(
    grid: number[][],
    cages: Array<{ sum: number; cells: number[][] }>,
  ): [number, number] | null {
    let bestCell: [number, number] | null = null;
    let minOptions = 10;

    for (let row = 0; row < 9; row++) {
      for (let col = 0; col < 9; col++) {
        if (grid[row][col] === 0) {
          let options = 0;
          for (let num = 1; num <= 9; num++) {
            if (this.isValidKillerPlacement(grid, row, col, num, cages)) {
              options++;
            }
          }
          if (options < minOptions) {
            minOptions = options;
            bestCell = [row, col];
            if (options === 0) return bestCell; // No valid options, will backtrack
            if (options === 1) return bestCell; // Only one option, best choice
          }
        }
      }
    }

    return bestCell;
  }

  /**
   * Check if placing num at (row, col) is valid for Killer Sudoku
   */
  private isValidKillerPlacement(
    grid: number[][],
    row: number,
    col: number,
    num: number,
    cages: Array<{ sum: number; cells: number[][] }>,
  ): boolean {
    // Standard Sudoku checks - row
    if (grid[row].includes(num)) return false;

    // Column check
    for (let i = 0; i < 9; i++) {
      if (grid[i][col] === num) return false;
    }

    // 3x3 box check
    const boxRow = Math.floor(row / 3) * 3;
    const boxCol = Math.floor(col / 3) * 3;
    for (let i = boxRow; i < boxRow + 3; i++) {
      for (let j = boxCol; j < boxCol + 3; j++) {
        if (grid[i][j] === num) return false;
      }
    }

    // Find the cage containing this cell
    const cage = cages.find((c) =>
      c.cells.some(([r, c]) => r === row && c === col),
    );
    if (!cage) return false;

    // Check no duplicate in cage
    for (const [r, c] of cage.cells) {
      if ((r !== row || c !== col) && grid[r][c] === num) {
        return false;
      }
    }

    // Check cage sum constraint
    let sum = num;
    let emptyCount = 0;
    for (const [r, c] of cage.cells) {
      if (r === row && c === col) continue;
      if (grid[r][c] === 0) {
        emptyCount++;
      } else {
        sum += grid[r][c];
      }
    }

    // If cage is complete, sum must equal target
    if (emptyCount === 0 && sum !== cage.sum) {
      return false;
    }

    // If cage is incomplete, sum must not exceed target
    if (sum > cage.sum) {
      return false;
    }

    // Check if remaining sum is achievable with remaining empty cells
    const remainingSum = cage.sum - sum;
    const usedDigits = new Set<number>();
    usedDigits.add(num);
    for (const [r, c] of cage.cells) {
      if (grid[r][c] !== 0) {
        usedDigits.add(grid[r][c]);
      }
    }

    if (!this.canAchieveSum(remainingSum, emptyCount, usedDigits)) {
      return false;
    }

    return true;
  }

  /**
   * Check if remaining sum can be achieved with n more unique digits
   */
  private canAchieveSum(
    sum: number,
    n: number,
    usedDigits: Set<number>,
  ): boolean {
    if (n === 0) return sum === 0;
    if (sum <= 0) return false;

    // Get available digits
    const available: number[] = [];
    for (let d = 1; d <= 9; d++) {
      if (!usedDigits.has(d)) available.push(d);
    }

    if (available.length < n) return false;

    // Check min/max achievable
    const sortedAvailable = [...available].sort((a, b) => a - b);
    const minPossible = sortedAvailable.slice(0, n).reduce((a, b) => a + b, 0);
    const maxPossible = sortedAvailable.slice(-n).reduce((a, b) => a + b, 0);

    return sum >= minPossible && sum <= maxPossible;
  }

  private addGivens(
    difficulty: "easy" | "medium" | "hard" | "expert",
    cages: Array<{ sum: number; cells: number[][] }>,
  ): void {
    // Number of givens based on difficulty
    // Expert: no givens (pure Killer Sudoku challenge)
    // Hard: minimal givens (2-5)
    const givensCount = {
      easy: { min: 10, max: 14 },
      medium: { min: 6, max: 9 },
      hard: { min: 2, max: 5 },
      expert: { min: 0, max: 0 },
    }[difficulty];

    const targetGivens =
      Math.floor(Math.random() * (givensCount.max - givensCount.min + 1)) +
      givensCount.min;

    if (targetGivens === 0) return;

    // Collect all cells and shuffle them
    const allCells: number[][] = [];
    for (let row = 0; row < 9; row++) {
      for (let col = 0; col < 9; col++) {
        allCells.push([row, col]);
      }
    }

    // Shuffle cells
    for (let i = allCells.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [allCells[i], allCells[j]] = [allCells[j], allCells[i]];
    }

    // Try to spread givens across different cages for better distribution
    const cageMap = new Map<string, number>();
    cages.forEach((cage, idx) => {
      cage.cells.forEach(([r, c]) => {
        cageMap.set(`${r},${c}`, idx);
      });
    });

    const cagesWithGivens = new Set<number>();
    let givensAdded = 0;

    // First pass: try to add one given per cage until we hit target or run out
    for (const [row, col] of allCells) {
      if (givensAdded >= targetGivens) break;

      const cageIdx = cageMap.get(`${row},${col}`);
      if (cageIdx !== undefined && !cagesWithGivens.has(cageIdx)) {
        this.grid[row][col] = this.solution[row][col];
        cagesWithGivens.add(cageIdx);
        givensAdded++;
      }
    }

    // Second pass: if we need more givens, add from any remaining cells
    if (givensAdded < targetGivens) {
      for (const [row, col] of allCells) {
        if (givensAdded >= targetGivens) break;
        if (this.grid[row][col] === 0) {
          this.grid[row][col] = this.solution[row][col];
          givensAdded++;
        }
      }
    }
  }

  private generateCages(
    difficulty: "easy" | "medium" | "hard" | "expert",
  ): Array<{ sum: number; cells: number[][] }> {
    const cages: Array<{ sum: number; cells: number[][] }> = [];
    const used = Array(9)
      .fill(null)
      .map(() => Array(9).fill(false));

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
          const cageSize =
            Math.floor(
              Math.random() * (cageSizeRange.max - cageSizeRange.min + 1),
            ) + cageSizeRange.min;
          const cells = this.buildCage(row, col, cageSize, used);

          // Calculate sum from solution
          const sum = cells.reduce(
            (acc, [r, c]) => acc + this.solution[r][c],
            0,
          );

          cages.push({ sum, cells });
        }
      }
    }

    return cages;
  }

  private buildCage(
    startRow: number,
    startCol: number,
    targetSize: number,
    used: boolean[][],
  ): number[][] {
    const cells: number[][] = [[startRow, startCol]];
    used[startRow][startCol] = true;

    // Track values already in this cage to prevent duplicates
    const valuesInCage = new Set<number>([this.solution[startRow][startCol]]);

    // Grow cage by adding adjacent cells
    while (cells.length < targetSize) {
      const candidates: number[][] = [];

      // Find all adjacent unassigned cells
      for (const [r, c] of cells) {
        const neighbors = [
          [r - 1, c],
          [r + 1, c],
          [r, c - 1],
          [r, c + 1],
        ];

        for (const [nr, nc] of neighbors) {
          if (nr >= 0 && nr < 9 && nc >= 0 && nc < 9 && !used[nr][nc]) {
            // Check that adding this cell won't create a duplicate value in the cage
            const cellValue = this.solution[nr][nc];
            if (!valuesInCage.has(cellValue)) {
              candidates.push([nr, nc]);
            }
          }
        }
      }

      if (candidates.length === 0) break; // Can't grow anymore (no valid candidates without duplicates)

      // Pick a random candidate
      const [newRow, newCol] =
        candidates[Math.floor(Math.random() * candidates.length)];
      cells.push([newRow, newCol]);
      used[newRow][newCol] = true;
      valuesInCage.add(this.solution[newRow][newCol]);
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
    direction: "across" | "down";
  }> = [];

  generate(
    wordsWithClues: Array<{ word: string; clue: string }>,
    rows = 15,
    cols = 15,
  ): {
    rows: number;
    cols: number;
    grid: (string | null)[][];
    clues: Array<{
      number: number;
      direction: "across" | "down";
      clue: string;
      answer: string;
      startRow: number;
      startCol: number;
    }>;
  } {
    this.rows = rows;
    this.cols = cols;
    this.grid = Array(rows)
      .fill(null)
      .map(() => Array(cols).fill(null));
    this.placedWords = [];

    // Shuffle words first, then sort by length (preserves randomness for same-length words)
    const shuffled = this.shuffleArray([...wordsWithClues]);
    const sorted = shuffled.sort((a, b) => b.word.length - a.word.length);

    // Randomly choose starting direction
    const startDirection: "across" | "down" =
      Math.random() < 0.5 ? "across" : "down";

    // Place first word with random offset from center
    if (sorted.length > 0) {
      const firstWord = sorted[0].word.toUpperCase();
      const offsetRange = 2;
      const randomOffset =
        Math.floor(Math.random() * (offsetRange * 2 + 1)) - offsetRange;

      if (startDirection === "across") {
        const startRow = Math.floor(rows / 2) + randomOffset;
        const startCol = Math.floor((cols - firstWord.length) / 2);
        this.placeWord(firstWord, startRow, startCol, "across");
      } else {
        const startRow = Math.floor((rows - firstWord.length) / 2);
        const startCol = Math.floor(cols / 2) + randomOffset;
        this.placeWord(firstWord, startRow, startCol, "down");
      }
    }

    // Place remaining words - only if they connect to existing words
    for (let i = 1; i < sorted.length; i++) {
      const word = sorted[i].word.toUpperCase();
      // Only place words that intersect with the existing grid
      // Skip words that can't connect to maintain grid connectivity
      this.findAndPlaceWord(word);
    }

    // Convert to final format with black cells (#)
    const finalGrid = this.grid.map((row) =>
      row.map((cell) => (cell === null ? "#" : cell)),
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
    // Collect all valid placements first
    const validPlacements: Array<{
      row: number;
      col: number;
      direction: "across" | "down";
    }> = [];

    // Shuffle placed words to check intersections in random order
    const shuffledPlaced = this.shuffleArray([...this.placedWords]);

    for (const placed of shuffledPlaced) {
      // Create shuffled indices for both loops
      const iIndices = this.shuffleArray(
        Array.from({ length: placed.word.length }, (_, i) => i),
      );
      const jIndices = this.shuffleArray(
        Array.from({ length: word.length }, (_, j) => j),
      );

      for (const i of iIndices) {
        for (const j of jIndices) {
          if (placed.word[i] === word[j]) {
            // Found a potential intersection
            let newRow: number, newCol: number;
            let newDir: "across" | "down";

            if (placed.direction === "across") {
              // Place new word vertically
              newDir = "down";
              newRow = placed.row - j;
              newCol = placed.col + i;
            } else {
              // Place new word horizontally
              newDir = "across";
              newRow = placed.row + i;
              newCol = placed.col - j;
            }

            if (this.canPlaceWord(word, newRow, newCol, newDir)) {
              validPlacements.push({
                row: newRow,
                col: newCol,
                direction: newDir,
              });
            }
          }
        }
      }
    }

    // Pick a random valid placement if any exist
    if (validPlacements.length > 0) {
      const chosen =
        validPlacements[Math.floor(Math.random() * validPlacements.length)];
      this.placeWord(word, chosen.row, chosen.col, chosen.direction);
      return true;
    }

    return false;
  }

  private shuffleArray<T>(array: T[]): T[] {
    const shuffled = [...array];
    for (let i = shuffled.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
    }
    return shuffled;
  }

  private canPlaceWord(
    word: string,
    row: number,
    col: number,
    direction: "across" | "down",
  ): boolean {
    if (direction === "across") {
      if (col + word.length > this.cols) return false;

      // Check if cells before and after are empty
      if (col > 0 && this.grid[row][col - 1] !== null) return false;
      if (
        col + word.length < this.cols &&
        this.grid[row][col + word.length] !== null
      )
        return false;

      for (let i = 0; i < word.length; i++) {
        const cell = this.grid[row][col + i];
        if (cell !== null && cell !== word[i]) return false;

        // Check perpendicular cells
        if (cell === null) {
          if (row > 0 && this.grid[row - 1][col + i] !== null) return false;
          if (row < this.rows - 1 && this.grid[row + 1][col + i] !== null)
            return false;
        }
      }
    } else {
      if (row + word.length > this.rows) return false;

      // Check if cells before and after are empty
      if (row > 0 && this.grid[row - 1][col] !== null) return false;
      if (
        row + word.length < this.rows &&
        this.grid[row + word.length][col] !== null
      )
        return false;

      for (let i = 0; i < word.length; i++) {
        const cell = this.grid[row + i][col];
        if (cell !== null && cell !== word[i]) return false;

        // Check perpendicular cells
        if (cell === null) {
          if (col > 0 && this.grid[row + i][col - 1] !== null) return false;
          if (col < this.cols - 1 && this.grid[row + i][col + 1] !== null)
            return false;
        }
      }
    }

    return true;
  }

  private placeWord(
    word: string,
    row: number,
    col: number,
    direction: "across" | "down",
  ): void {
    if (direction === "across") {
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

  private generateClues(
    wordsWithClues: Array<{ word: string; clue: string }>,
  ): Array<{
    number: number;
    direction: "across" | "down";
    clue: string;
    answer: string;
    startRow: number;
    startCol: number;
  }> {
    const clues: Array<{
      number: number;
      direction: "across" | "down";
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

      const wordData = wordsWithClues.find(
        (w) => w.word.toUpperCase() === placed.word,
      );
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
      return a.direction === "across" ? -1 : 1;
    });

    return clues;
  }
}

// Example usage and exports
export const generateSudoku = (
  difficulty: "easy" | "medium" | "hard" | "expert",
) => {
  const generator = new SudokuGenerator();
  return generator.generate(difficulty);
};

export const generateKillerSudoku = (
  difficulty: "easy" | "medium" | "hard" | "expert",
) => {
  const generator = new KillerSudokuGenerator();
  return generator.generate(difficulty);
};

export const generateCrossword = (
  wordsWithClues: Array<{ word: string; clue: string }>,
  rows?: number,
  cols?: number,
) => {
  const generator = new CrosswordGenerator();
  return generator.generate(wordsWithClues, rows, cols);
};

export const generateWordSearch = (
  words: string[],
  rows?: number,
  cols?: number,
  theme?: string,
) => {
  const generator = new WordSearchGenerator();
  return generator.generate(words, rows, cols, theme);
};

// Word Forge Generator
export class WordForgeGenerator {
  // Common English words (4+ letters) - curated subset for puzzle generation
  private static readonly WORD_LIST: string[] = [
    // This is a subset - in production, load from a larger dictionary file
    "ABLE",
    "ABOUT",
    "ABOVE",
    "ACCEPT",
    "ACCOUNT",
    "ACHIEVE",
    "ACROSS",
    "ACTION",
    "ACTIVE",
    "ACTUAL",
    "ADDING",
    "ADVANCE",
    "AFTER",
    "AGAIN",
    "AGAINST",
    "AGENT",
    "AGREE",
    "AHEAD",
    "ALLOW",
    "ALMOST",
    "ALONE",
    "ALONG",
    "ALREADY",
    "ALSO",
    "ALWAYS",
    "AMONG",
    "AMOUNT",
    "ANIMAL",
    "ANOTHER",
    "ANSWER",
    "APART",
    "APPEAR",
    "APPLY",
    "AREA",
    "ARGUE",
    "ARISE",
    "AROUND",
    "ARRIVE",
    "ASIDE",
    "ASKING",
    "BABY",
    "BACK",
    "BALANCE",
    "BALL",
    "BAND",
    "BANK",
    "BASE",
    "BASIC",
    "BATTLE",
    "BEAR",
    "BEAT",
    "BECOME",
    "BEEN",
    "BEFORE",
    "BEGIN",
    "BEHIND",
    "BEING",
    "BELIEVE",
    "BELONG",
    "BELOW",
    "BEND",
    "BENEFIT",
    "BESIDE",
    "BEST",
    "BETTER",
    "BETWEEN",
    "BEYOND",
    "BILLION",
    "BIND",
    "BIRD",
    "BLACK",
    "BLANK",
    "BLEND",
    "BLIND",
    "BLOCK",
    "BLOOD",
    "BLOW",
    "BLUE",
    "BOARD",
    "BOAT",
    "BODY",
    "BOLD",
    "BONE",
    "BOOK",
    "BOOM",
    "BORN",
    "BOTH",
    "BOTTOM",
    "BOUND",
    "BRAIN",
    "BRANCH",
    "BRAND",
    "BREAD",
    "BREAK",
    "BREATH",
    "BRIDGE",
    "BRIEF",
    "BRIGHT",
    "BRING",
    "BROAD",
    "BROKEN",
    "BROTHER",
    "BROWN",
    "BUILD",
    "BUILDING",
    "BURN",
    "BURST",
    "BUSINESS",
    "BUSY",
    "BUYER",
    "CABLE",
    "CALL",
    "CALM",
    "CAME",
    "CAMP",
    "CAMPAIGN",
    "CAMPUS",
    "CANNOT",
    "CAPABLE",
    "CAPITAL",
    "CAPTAIN",
    "CAPTURE",
    "CARD",
    "CARE",
    "CAREER",
    "CAREFUL",
    "CARRY",
    "CASE",
    "CASH",
    "CAST",
    "CATCH",
    "CATEGORY",
    "CAUSE",
    "CELL",
    "CENTER",
    "CENTRAL",
    "CENTURY",
    "CHAIN",
    "CHAIR",
    "CHALLENGE",
    "CHAMBER",
    "CHAMPION",
    "CHANCE",
    "CHANGE",
    "CHANNEL",
    "CHAPTER",
    "CHARACTER",
    "CHARGE",
    "CHART",
    "CHASE",
    "CHEAP",
    "CHECK",
    "CHIEF",
    "CHILD",
    "CHILDREN",
    "CHOICE",
    "CHOOSE",
    "CHURCH",
    "CIRCLE",
    "CITIZEN",
    "CITY",
    "CIVIL",
    "CLAIM",
    "CLASS",
    "CLASSIC",
    "CLEAN",
    "CLEAR",
    "CLIMB",
    "CLOCK",
    "CLOSE",
    "CLOUD",
    "CLUB",
    "COACH",
    "COAL",
    "COAST",
    "CODE",
    "COFFEE",
    "COLD",
    "COLLECT",
    "COLLEGE",
    "COLOR",
    "COLUMN",
    "COMBAT",
    "COMBINE",
    "COME",
    "COMFORT",
    "COMING",
    "COMMAND",
    "COMMENT",
    "COMMERCIAL",
    "COMMON",
    "COMMUNITY",
    "COMPANY",
    "COMPARE",
    "COMPETE",
    "COMPLETE",
    "COMPLEX",
    "COMPUTER",
    "CONCEPT",
    "CONCERN",
    "CONDITION",
    "CONDUCT",
    "CONFERENCE",
    "CONFIRM",
    "CONFLICT",
    "CONNECT",
    "CONSIDER",
    "CONSTANT",
    "CONSUMER",
    "CONTACT",
    "CONTAIN",
    "CONTENT",
    "CONTEXT",
    "CONTINUE",
    "CONTRACT",
    "CONTRAST",
    "CONTRIBUTE",
    "CONTROL",
    "COOK",
    "COOL",
    "COPY",
    "CORE",
    "CORNER",
    "CORPORATE",
    "CORRECT",
    "COST",
    "COULD",
    "COUNCIL",
    "COUNT",
    "COUNTRY",
    "COUNTY",
    "COUPLE",
    "COURAGE",
    "COURSE",
    "COURT",
    "COVER",
    "CRACK",
    "CRAFT",
    "CRASH",
    "CRAZY",
    "CREAM",
    "CREATE",
    "CREDIT",
    "CREW",
    "CRIME",
    "CRISIS",
    "CRITICAL",
    "CROSS",
    "CROWD",
    "CRUCIAL",
    "CULTURAL",
    "CULTURE",
    "CURRENT",
    "CUSTOMER",
    "CYCLE",
    "DAILY",
    "DAMAGE",
    "DANCE",
    "DANGER",
    "DANGEROUS",
    "DARK",
    "DATA",
    "DATE",
    "DAUGHTER",
    "DEAD",
    "DEAL",
    "DEALER",
    "DEAR",
    "DEATH",
    "DEBATE",
    "DECADE",
    "DECIDE",
    "DECISION",
    "DECK",
    "DECLARE",
    "DECLINE",
    "DEEP",
    "DEEPLY",
    "DEFEAT",
    "DEFEND",
    "DEFENSE",
    "DEFINE",
    "DEGREE",
    "DELAY",
    "DELIVER",
    "DEMAND",
    "DEMOCRACY",
    "DEMOCRATIC",
    "DEMONSTRATE",
    "DENY",
    "DEPARTMENT",
    "DEPEND",
    "DEPTH",
    "DEPUTY",
    "DERIVE",
    "DESCRIBE",
    "DESERT",
    "DESERVE",
    "DESIGN",
    "DESIGNER",
    "DESIRE",
    "DESK",
    "DESPITE",
    "DESTROY",
    "DETAIL",
    "DETECT",
    "DETERMINE",
    "DEVELOP",
    "DEVICE",
    "DIALOGUE",
    "DIAMOND",
    "DIFFER",
    "DIFFERENT",
    "DIFFICULT",
    "DIGITAL",
    "DINING",
    "DINNER",
    "DIRECT",
    "DIRECTION",
    "DIRECTOR",
    "DIRTY",
    "DISAPPEAR",
    "DISCOVER",
    "DISCUSS",
    "DISEASE",
    "DISH",
    "DISPLAY",
    "DISTANCE",
    "DISTINCT",
    "DISTRIBUTE",
    "DISTRICT",
    "DIVERSE",
    "DIVIDE",
    "DOCTOR",
    "DOCUMENT",
    "DOLLAR",
    "DOMESTIC",
    "DOMINANT",
    "DOMINATE",
    "DONE",
    "DOOR",
    "DOUBLE",
    "DOUBT",
    "DOWN",
    "DOZEN",
    "DRAFT",
    "DRAG",
    "DRAMA",
    "DRAMATIC",
    "DRAW",
    "DRAWING",
    "DREAM",
    "DRESS",
    "DRINK",
    "DRIVE",
    "DRIVER",
    "DROP",
    "DRUG",
    "DURING",
    "DUST",
    "DUTY",
    "EACH",
    "EAGER",
    "EARLY",
    "EARN",
    "EARTH",
    "EASE",
    "EASILY",
    "EAST",
    "EASTERN",
    "EASY",
    "ECONOMIC",
    "ECONOMY",
    "EDGE",
    "EDITION",
    "EDITOR",
    "EDUCATE",
    "EDUCATION",
    "EFFECT",
    "EFFECTIVE",
    "EFFORT",
    "EIGHT",
    "EITHER",
    "ELDER",
    "ELECT",
    "ELECTION",
    "ELECTRIC",
    "ELEMENT",
    "ELIMINATE",
    "ELITE",
    "ELSE",
    "ELSEWHERE",
    "EMAIL",
    "EMERGE",
    "EMERGENCY",
    "EMOTION",
    "EMOTIONAL",
    "EMPHASIS",
    "EMPHASIZE",
    "EMPLOY",
    "EMPLOYEE",
    "EMPLOYER",
    "EMPTY",
    "ENABLE",
    "ENCOUNTER",
    "ENCOURAGE",
    "ENDING",
    "ENEMY",
    "ENERGY",
    "ENGAGE",
    "ENGINE",
    "ENGINEER",
    "ENGLISH",
    "ENHANCE",
    "ENJOY",
    "ENOUGH",
    "ENSURE",
    "ENTER",
    "ENTERPRISE",
    "ENTIRE",
    "ENTIRELY",
    "ENTRANCE",
    "ENTRY",
    "ENVIRONMENT",
    "EQUAL",
    "EQUIPMENT",
    "ERROR",
    "ESCAPE",
    "ESPECIALLY",
    "ESSENTIAL",
    "ESTABLISH",
    "ESTATE",
    "ESTIMATE",
    "ETHNIC",
    "EVALUATE",
    "EVEN",
    "EVENING",
    "EVENT",
    "EVENTUALLY",
    "EVER",
    "EVERY",
    "EVERYBODY",
    "EVERYDAY",
    "EVERYONE",
    "EVERYTHING",
    "EVIDENCE",
    "EVIL",
    "EVOLUTION",
    "EXACT",
    "EXACTLY",
    "EXAMINE",
    "EXAMPLE",
    "EXCELLENT",
    "EXCEPT",
    "EXCHANGE",
    "EXCITING",
    "EXECUTIVE",
    "EXERCISE",
    "EXHIBIT",
    "EXIST",
    "EXISTENCE",
    "EXISTING",
    "EXPAND",
    "EXPANSION",
    "EXPECT",
    "EXPECTATION",
    "EXPENSE",
    "EXPENSIVE",
    "EXPERIENCE",
    "EXPERIMENT",
    "EXPERT",
    "EXPLAIN",
    "EXPLANATION",
    "EXPLORE",
    "EXPORT",
    "EXPOSE",
    "EXPOSURE",
    "EXPRESS",
    "EXPRESSION",
    "EXTEND",
    "EXTENSION",
    "EXTENSIVE",
    "EXTENT",
    "EXTERNAL",
    "EXTRA",
    "EXTRAORDINARY",
    "EXTREME",
    "EXTREMELY",
    "FACE",
    "FACILITY",
    "FACT",
    "FACTOR",
    "FACTORY",
    "FAIL",
    "FAILURE",
    "FAIR",
    "FAIRLY",
    "FAITH",
    "FALL",
    "FALSE",
    "FAME",
    "FAMILIAR",
    "FAMILY",
    "FAMOUS",
    "FANCY",
    "FANTASY",
    "FARM",
    "FARMER",
    "FASHION",
    "FAST",
    "FATHER",
    "FAULT",
    "FAVOR",
    "FAVORITE",
    "FEAR",
    "FEATURE",
    "FEDERAL",
    "FEED",
    "FEEL",
    "FEELING",
    "FELLOW",
    "FEMALE",
    "FENCE",
    "FICTION",
    "FIELD",
    "FIFTEEN",
    "FIFTH",
    "FIFTY",
    "FIGHT",
    "FIGHTER",
    "FIGHTING",
    "FIGURE",
    "FILE",
    "FILL",
    "FILM",
    "FINAL",
    "FINALLY",
    "FINANCE",
    "FINANCIAL",
    "FIND",
    "FINDING",
    "FINE",
    "FINGER",
    "FINISH",
    "FIRE",
    "FIRM",
    "FIRST",
    "FISH",
    "FITNESS",
    "FIVE",
    "FIXED",
    "FLAG",
    "FLAME",
    "FLASH",
    "FLAT",
    "FLAVOR",
    "FLESH",
    "FLIGHT",
    "FLOAT",
    "FLOOD",
    "FLOOR",
    "FLOW",
    "FLOWER",
    "FLYING",
    "FOCUS",
    "FOLK",
    "FOLLOW",
    "FOLLOWING",
    "FOOD",
    "FOOT",
    "FOOTBALL",
    "FORCE",
    "FOREIGN",
    "FOREST",
    "FOREVER",
    "FORGET",
    "FORM",
    "FORMAL",
    "FORMAT",
    "FORMATION",
    "FORMER",
    "FORMULA",
    "FORTH",
    "FORTUNE",
    "FORWARD",
    "FOUND",
    "FOUNDATION",
    "FOUNDER",
    "FOUR",
    "FOURTH",
    "FRAME",
    "FRAMEWORK",
    "FREE",
    "FREEDOM",
    "FRENCH",
    "FREQUENCY",
    "FREQUENT",
    "FRESH",
    "FRIEND",
    "FRIENDLY",
    "FRONT",
    "FRUIT",
    "FUEL",
    "FULL",
    "FULLY",
    "FUNCTION",
    "FUND",
    "FUNDAMENTAL",
    "FUNDING",
    "FUNNY",
    "FURNITURE",
    "FURTHERMORE",
    "FUTURE",
    "GAIN",
    "GALAXY",
    "GALLERY",
    "GAME",
    "GANG",
    "GARDEN",
    "GARLIC",
    "GATHER",
    "GAVE",
    "GEAR",
    "GENDER",
    "GENE",
    "GENERAL",
    "GENERALLY",
    "GENERATE",
    "GENERATION",
    "GENETIC",
    "GENRE",
    "GENTLE",
    "GENTLEMAN",
    "GENUINE",
    "GETTING",
    "GHOST",
    "GIANT",
    "GIFT",
    "GIRL",
    "GIVE",
    "GIVEN",
    "GLAD",
    "GLANCE",
    "GLASS",
    "GLOBAL",
    "GLORY",
    "GOAL",
    "GOLD",
    "GOLDEN",
    "GOLF",
    "GONE",
    "GOOD",
    "GOSPEL",
    "GOVERN",
    "GOVERNMENT",
    "GOVERNOR",
    "GRAB",
    "GRACE",
    "GRADE",
    "GRAIN",
    "GRAND",
    "GRANDFATHER",
    "GRANDMOTHER",
    "GRANT",
    "GRAPH",
    "GRASP",
    "GRASS",
    "GRAVE",
    "GRAY",
    "GREAT",
    "GREEN",
    "GREY",
    "GROCERY",
    "GROUND",
    "GROUP",
    "GROW",
    "GROWING",
    "GROWTH",
    "GUARANTEE",
    "GUARD",
    "GUESS",
    "GUEST",
    "GUIDE",
    "GUIDELINE",
    "GUILTY",
    "GUITAR",
    "HABIT",
    "HAIR",
    "HALF",
    "HALL",
    "HAND",
    "HANDLE",
    "HANG",
    "HAPPEN",
    "HAPPY",
    "HARD",
    "HARDLY",
    "HARM",
    "HATE",
    "HAVE",
    "HEAD",
    "HEADLINE",
    "HEADQUARTERS",
    "HEALTH",
    "HEALTHY",
    "HEAR",
    "HEARING",
    "HEART",
    "HEAT",
    "HEAVEN",
    "HEAVILY",
    "HEAVY",
    "HEIGHT",
    "HELD",
    "HELICOPTER",
    "HELL",
    "HELLO",
    "HELP",
    "HELPFUL",
    "HERE",
    "HERO",
    "HERSELF",
    "HIDE",
    "HIGH",
    "HIGHLIGHT",
    "HIGHLY",
    "HILL",
    "HIMSELF",
    "HIRE",
    "HISTORIAN",
    "HISTORIC",
    "HISTORICAL",
    "HISTORY",
    "HOLD",
    "HOLDER",
    "HOLE",
    "HOLIDAY",
    "HOLY",
    "HOME",
    "HOMELESS",
    "HONEST",
    "HONOR",
    "HOPE",
    "HORIZON",
    "HORROR",
    "HORSE",
    "HOSPITAL",
    "HOST",
    "HOTEL",
    "HOUR",
    "HOUSE",
    "HOUSEHOLD",
    "HOUSING",
    "HOWEVER",
    "HUGE",
    "HUMAN",
    "HUMOR",
    "HUNDRED",
    "HUNGRY",
    "HUNT",
    "HUNTER",
    "HUNTING",
    "HURT",
    "HUSBAND",
    "IDEA",
    "IDEAL",
    "IDENTIFY",
    "IDENTITY",
    "IGNORE",
    "ILLEGAL",
    "ILLNESS",
    "IMAGE",
    "IMAGINATION",
    "IMAGINE",
    "IMMEDIATE",
    "IMMEDIATELY",
    "IMMIGRANT",
    "IMPACT",
    "IMPLEMENT",
    "IMPLICATION",
    "IMPLY",
    "IMPORTANCE",
    "IMPORTANT",
    "IMPOSE",
    "IMPOSSIBLE",
    "IMPRESS",
    "IMPRESSION",
    "IMPRESSIVE",
    "IMPROVE",
    "IMPROVEMENT",
    "INCIDENT",
    "INCLUDE",
    "INCLUDING",
    "INCOME",
    "INCORPORATE",
    "INCREASE",
    "INCREASED",
    "INCREASING",
    "INCREDIBLE",
    "INDEED",
    "INDEPENDENCE",
    "INDEPENDENT",
    "INDEX",
    "INDIAN",
    "INDICATE",
    "INDICATION",
    "INDIVIDUAL",
    "INDUSTRIAL",
    "INDUSTRY",
    "INFANT",
    "INFECTION",
    "INFLATION",
    "INFLUENCE",
    "INFORM",
    "INFORMATION",
    "INITIAL",
    "INITIALLY",
    "INITIATIVE",
    "INJURY",
    "INNER",
    "INNOCENT",
    "INQUIRY",
    "INSIDE",
    "INSIGHT",
    "INSIST",
    "INSPIRE",
    "INSTALL",
    "INSTANCE",
    "INSTEAD",
    "INSTITUTION",
    "INSTRUCTION",
    "INSTRUMENT",
    "INSURANCE",
    "INTELLECTUAL",
    "INTELLIGENCE",
    "INTEND",
    "INTENSE",
    "INTENSITY",
    "INTENTION",
    "INTEREST",
    "INTERESTED",
    "INTERESTING",
    "INTERNAL",
    "INTERNATIONAL",
    "INTERNET",
    "INTERPRET",
    "INTERVENTION",
    "INTERVIEW",
    "INTO",
    "INTRODUCE",
    "INTRODUCTION",
    "INVASION",
    "INVEST",
    "INVESTIGATE",
    "INVESTIGATION",
    "INVESTIGATOR",
    "INVESTMENT",
    "INVESTOR",
    "INVITE",
    "INVOLVE",
    "INVOLVED",
    "INVOLVEMENT",
    "IRON",
    "ISLAND",
    "ISSUE",
    "ITEM",
    "ITSELF",
    "JACKET",
    "JAIL",
    "JAZZ",
    "JEWISH",
    "JOIN",
    "JOINT",
    "JOKE",
    "JOURNAL",
    "JOURNALIST",
    "JOURNEY",
    "JUDGE",
    "JUDGMENT",
    "JUICE",
    "JUMP",
    "JUNIOR",
    "JURY",
    "JUST",
    "JUSTICE",
    "JUSTIFY",
    "KEEN",
    "KEEP",
    "KICK",
    "KIDNEY",
    "KILL",
    "KILLER",
    "KILLING",
    "KIND",
    "KING",
    "KISS",
    "KITCHEN",
    "KNEE",
    "KNIFE",
    "KNOCK",
    "KNOW",
    "KNOWING",
    "KNOWLEDGE",
    "LABEL",
    "LABOR",
    "LABORATORY",
    "LACK",
    "LADY",
    "LAKE",
    "LAND",
    "LANDSCAPE",
    "LANGUAGE",
    "LAPTOP",
    "LARGE",
    "LARGELY",
    "LAST",
    "LATE",
    "LATER",
    "LATEST",
    "LATIN",
    "LATTER",
    "LAUGH",
    "LAUNCH",
    "LAWN",
    "LAWSUIT",
    "LAWYER",
    "LAYER",
    "LEAD",
    "LEADER",
    "LEADERSHIP",
    "LEADING",
    "LEAF",
    "LEAGUE",
    "LEAN",
    "LEARN",
    "LEARNING",
    "LEAST",
    "LEATHER",
    "LEAVE",
    "LEFT",
    "LEGAL",
    "LEGEND",
    "LEGISLATION",
    "LEGITIMATE",
    "LEMON",
    "LENGTH",
    "LESS",
    "LESSON",
    "LETTER",
    "LEVEL",
    "LIBERAL",
    "LIBRARY",
    "LICENSE",
    "LIFE",
    "LIFESTYLE",
    "LIFETIME",
    "LIFT",
    "LIGHT",
    "LIKE",
    "LIKELY",
    "LIMIT",
    "LIMITED",
    "LINE",
    "LINK",
    "LIST",
    "LISTEN",
    "LITERARY",
    "LITERATURE",
    "LITTLE",
    "LIVE",
    "LIVING",
    "LOAD",
    "LOAN",
    "LOCAL",
    "LOCATE",
    "LOCATION",
    "LOCK",
    "LONG",
    "LOOK",
    "LOOSE",
    "LORD",
    "LOSE",
    "LOSS",
    "LOST",
    "LOTS",
    "LOUD",
    "LOVE",
    "LOVELY",
    "LOVER",
    "LOWER",
    "LUCK",
    "LUCKY",
    "LUNCH",
    "LUNG",
    "MACHINE",
    "MAGAZINE",
    "MAGIC",
    "MAIL",
    "MAIN",
    "MAINLY",
    "MAINSTREAM",
    "MAINTAIN",
    "MAINTENANCE",
    "MAJOR",
    "MAJORITY",
    "MAKE",
    "MAKER",
    "MAKEUP",
    "MALE",
    "MALL",
    "MANAGE",
    "MANAGEMENT",
    "MANAGER",
    "MANNER",
    "MANUFACTURER",
    "MANUFACTURING",
    "MANY",
    "MARGIN",
    "MARK",
    "MARKET",
    "MARKETING",
    "MARRIAGE",
    "MARRIED",
    "MARRY",
    "MASK",
    "MASS",
    "MASSIVE",
    "MASTER",
    "MATCH",
    "MATERIAL",
    "MATH",
    "MATTER",
    "MAXIMUM",
    "MAYBE",
    "MAYOR",
    "MEAL",
    "MEAN",
    "MEANING",
    "MEANINGFUL",
    "MEANS",
    "MEANWHILE",
    "MEASURE",
    "MEASUREMENT",
    "MEAT",
    "MECHANISM",
    "MEDIA",
    "MEDICAL",
    "MEDICATION",
    "MEDICINE",
    "MEDIUM",
    "MEET",
    "MEETING",
    "MEMBER",
    "MEMBERSHIP",
    "MEMORY",
    "MENTAL",
    "MENTION",
    "MENU",
    "MERE",
    "MERELY",
    "MERIT",
    "MESSAGE",
    "METAL",
    "METHOD",
    "MIDDLE",
    "MIGHT",
    "MILITARY",
    "MILK",
    "MILLION",
    "MIND",
    "MINE",
    "MINIMUM",
    "MINISTER",
    "MINOR",
    "MINORITY",
    "MINUTE",
    "MIRACLE",
    "MIRROR",
    "MISS",
    "MISSILE",
    "MISSION",
    "MISTAKE",
    "MODEL",
    "MODERATE",
    "MODERN",
    "MODEST",
    "MODIFY",
    "MOMENT",
    "MONEY",
    "MONITOR",
    "MONTH",
    "MONTHLY",
    "MOOD",
    "MOON",
    "MORAL",
    "MORE",
    "MOREOVER",
    "MORNING",
    "MORTGAGE",
    "MOST",
    "MOSTLY",
    "MOTHER",
    "MOTION",
    "MOTIVATION",
    "MOTOR",
    "MOUNT",
    "MOUNTAIN",
    "MOUSE",
    "MOUTH",
    "MOVE",
    "MOVEMENT",
    "MOVIE",
    "MUCH",
    "MULTIPLE",
    "MURDER",
    "MUSCLE",
    "MUSEUM",
    "MUSIC",
    "MUSICAL",
    "MUSICIAN",
    "MUSLIM",
    "MUST",
    "MUTUAL",
    "MYSELF",
    "MYSTERY",
    "MYTH",
    "NAKED",
    "NAME",
    "NARRATIVE",
    "NARROW",
    "NATION",
    "NATIONAL",
    "NATIVE",
    "NATURAL",
    "NATURALLY",
    "NATURE",
    "NEAR",
    "NEARBY",
    "NEARLY",
    "NECESSARILY",
    "NECESSARY",
    "NECK",
    "NEED",
    "NEGATIVE",
    "NEGOTIATE",
    "NEGOTIATION",
    "NEIGHBOR",
    "NEIGHBORHOOD",
    "NEITHER",
    "NERVE",
    "NERVOUS",
    "NETWORK",
    "NEVER",
    "NEVERTHELESS",
    "NEWS",
    "NEWSPAPER",
    "NEXT",
    "NICE",
    "NIGHT",
    "NINE",
    "NOBODY",
    "NODE",
    "NOISE",
    "NOMINATION",
    "NONE",
    "NONETHELESS",
    "NORMAL",
    "NORMALLY",
    "NORTH",
    "NORTHERN",
    "NOSE",
    "NOTE",
    "NOTHING",
    "NOTICE",
    "NOTION",
    "NOVEL",
    "NOVEMBER",
    "NOWHERE",
    "NUCLEAR",
    "NUMBER",
    "NUMEROUS",
    "NURSE",
    "OBJECT",
    "OBJECTIVE",
    "OBLIGATION",
    "OBSERVATION",
    "OBSERVE",
    "OBSERVER",
    "OBTAIN",
    "OBVIOUS",
    "OBVIOUSLY",
    "OCCASION",
    "OCCASIONALLY",
    "OCCUPATION",
    "OCCUPY",
    "OCCUR",
    "OCEAN",
    "OCTOBER",
    "ODDS",
    "OFFENSE",
    "OFFENSIVE",
    "OFFER",
    "OFFICE",
    "OFFICER",
    "OFFICIAL",
    "OFTEN",
    "OKAY",
    "ONCE",
    "ONGOING",
    "ONION",
    "ONLINE",
    "ONLY",
    "ONTO",
    "OPEN",
    "OPENING",
    "OPERATE",
    "OPERATING",
    "OPERATION",
    "OPERATOR",
    "OPINION",
    "OPPONENT",
    "OPPORTUNITY",
    "OPPOSE",
    "OPPOSITE",
    "OPPOSITION",
    "OPTION",
    "ORANGE",
    "ORDER",
    "ORDINARY",
    "ORGAN",
    "ORGANIC",
    "ORGANIZATION",
    "ORGANIZE",
    "ORIENTATION",
    "ORIGIN",
    "ORIGINAL",
    "ORIGINALLY",
    "OTHER",
    "OTHERWISE",
    "OUGHT",
    "OURSELVES",
    "OUTCOME",
    "OUTDOOR",
    "OUTER",
    "OUTLET",
    "OUTLINE",
    "OUTPUT",
    "OUTSIDE",
    "OUTSTANDING",
    "OVERALL",
    "OVERCOME",
    "OVERLOOK",
    "OVERNIGHT",
    "OVERSEAS",
    "OVERWHELMING",
    "OWNER",
    "OWNERSHIP",
    "PACE",
    "PACK",
    "PACKAGE",
    "PAGE",
    "PAIN",
    "PAINFUL",
    "PAINT",
    "PAINTER",
    "PAINTING",
    "PAIR",
    "PALACE",
    "PALE",
    "PALM",
    "PANEL",
    "PANIC",
    "PAPER",
    "PARENT",
    "PARK",
    "PARKING",
    "PART",
    "PARTICIPANT",
    "PARTICIPATE",
    "PARTICIPATION",
    "PARTICULAR",
    "PARTICULARLY",
    "PARTLY",
    "PARTNER",
    "PARTNERSHIP",
    "PARTY",
    "PASS",
    "PASSAGE",
    "PASSENGER",
    "PASSING",
    "PASSION",
    "PAST",
    "PATH",
    "PATIENCE",
    "PATIENT",
    "PATTERN",
    "PAUSE",
    "PAYMENT",
    "PEACE",
    "PEAK",
    "PEER",
    "PENALTY",
    "PENSION",
    "PEOPLE",
    "PEPPER",
    "PERCENT",
    "PERCENTAGE",
    "PERCEPTION",
    "PERFECT",
    "PERFECTLY",
    "PERFORM",
    "PERFORMANCE",
    "PERHAPS",
    "PERIOD",
    "PERMANENT",
    "PERMISSION",
    "PERMIT",
    "PERSON",
    "PERSONAL",
    "PERSONALITY",
    "PERSONALLY",
    "PERSONNEL",
    "PERSPECTIVE",
    "PERSUADE",
    "PHASE",
    "PHENOMENON",
    "PHILOSOPHY",
    "PHONE",
    "PHOTO",
    "PHOTOGRAPH",
    "PHOTOGRAPHER",
    "PHOTOGRAPHY",
    "PHRASE",
    "PHYSICAL",
    "PHYSICALLY",
    "PHYSICIAN",
    "PIANO",
    "PICK",
    "PICTURE",
    "PIECE",
    "PILE",
    "PILOT",
    "PINE",
    "PINK",
    "PIPE",
    "PITCH",
    "PLACE",
    "PLAIN",
    "PLAN",
    "PLANE",
    "PLANET",
    "PLANNING",
    "PLANT",
    "PLASTIC",
    "PLATE",
    "PLATFORM",
    "PLAY",
    "PLAYER",
    "PLEASE",
    "PLEASURE",
    "PLENTY",
    "PLOT",
    "PLUS",
    "POCKET",
    "POEM",
    "POET",
    "POETRY",
    "POINT",
    "POINTED",
    "POLICE",
    "POLICY",
    "POLITICAL",
    "POLITICALLY",
    "POLITICIAN",
    "POLITICS",
    "POLL",
    "POLLUTION",
    "POOL",
    "POOR",
    "POPULAR",
    "POPULARITY",
    "POPULATION",
    "PORCH",
    "PORT",
    "PORTION",
    "PORTRAIT",
    "PORTRAY",
    "POSE",
    "POSITION",
    "POSITIVE",
    "POSSESS",
    "POSSESSION",
    "POSSIBILITY",
    "POSSIBLE",
    "POSSIBLY",
    "POST",
    "POTATO",
    "POTENTIAL",
    "POTENTIALLY",
    "POUND",
    "POUR",
    "POVERTY",
    "POWDER",
    "POWER",
    "POWERFUL",
    "PRACTICAL",
    "PRACTICE",
    "PRAY",
    "PRAYER",
    "PRECISELY",
    "PREDICT",
    "PREFER",
    "PREFERENCE",
    "PREGNANCY",
    "PREGNANT",
    "PREMISE",
    "PREMIUM",
    "PREPARATION",
    "PREPARE",
    "PREPARED",
    "PRESCRIPTION",
    "PRESENCE",
    "PRESENT",
    "PRESENTATION",
    "PRESERVE",
    "PRESIDENT",
    "PRESIDENTIAL",
    "PRESS",
    "PRESSURE",
    "PRESUMABLY",
    "PRETEND",
    "PRETTY",
    "PREVENT",
    "PREVIOUS",
    "PREVIOUSLY",
    "PRICE",
    "PRIDE",
    "PRIEST",
    "PRIMARY",
    "PRIME",
    "PRINCE",
    "PRINCIPAL",
    "PRINCIPLE",
    "PRINT",
    "PRIOR",
    "PRIORITY",
    "PRISON",
    "PRISONER",
    "PRIVACY",
    "PRIVATE",
    "PRIZE",
    "PROBABLY",
    "PROBLEM",
    "PROCEDURE",
    "PROCEED",
    "PROCESS",
    "PRODUCE",
    "PRODUCER",
    "PRODUCT",
    "PRODUCTION",
    "PROFESSION",
    "PROFESSIONAL",
    "PROFESSOR",
    "PROFILE",
    "PROFIT",
    "PROGRAM",
    "PROGRESS",
    "PROJECT",
    "PROMINENT",
    "PROMISE",
    "PROMOTE",
    "PROMOTION",
    "PROMPT",
    "PROOF",
    "PROPER",
    "PROPERLY",
    "PROPERTY",
    "PROPORTION",
    "PROPOSAL",
    "PROPOSE",
    "PROPOSED",
    "PROSECUTOR",
    "PROSPECT",
    "PROTECT",
    "PROTECTION",
    "PROTEIN",
    "PROTEST",
    "PROUD",
    "PROVE",
    "PROVIDE",
    "PROVIDER",
    "PROVINCE",
    "PROVISION",
    "PSYCHOLOGICAL",
    "PSYCHOLOGY",
    "PUBLIC",
    "PUBLICATION",
    "PUBLICLY",
    "PUBLISH",
    "PUBLISHER",
    "PULL",
    "PULSE",
    "PUMP",
    "PUNCH",
    "PUNISHMENT",
    "PURCHASE",
    "PURE",
    "PURPLE",
    "PURPOSE",
    "PURSUE",
    "PUSH",
    "PUTTING",
    "QUALIFY",
    "QUALITY",
    "QUANTITY",
    "QUARTER",
    "QUEEN",
    "QUESTION",
    "QUICK",
    "QUICKLY",
    "QUIET",
    "QUIETLY",
    "QUIT",
    "QUITE",
    "QUOTE",
    "RACE",
    "RACIAL",
    "RACING",
    "RADICAL",
    "RADIO",
    "RAGE",
    "RAIL",
    "RAIN",
    "RAISE",
    "RANGE",
    "RANK",
    "RAPID",
    "RAPIDLY",
    "RARE",
    "RARELY",
    "RATE",
    "RATHER",
    "RATING",
    "RATIO",
    "REACH",
    "REACT",
    "REACTION",
    "READ",
    "READER",
    "READING",
    "READY",
    "REAL",
    "REALISTIC",
    "REALITY",
    "REALIZE",
    "REALLY",
    "REASON",
    "REASONABLE",
    "RECALL",
    "RECEIVE",
    "RECENT",
    "RECENTLY",
    "RECIPE",
    "RECOGNITION",
    "RECOGNIZE",
    "RECOMMEND",
    "RECOMMENDATION",
    "RECORD",
    "RECORDING",
    "RECOVER",
    "RECOVERY",
    "RECRUIT",
    "REDUCE",
    "REDUCTION",
    "REFER",
    "REFERENCE",
    "REFLECT",
    "REFLECTION",
    "REFORM",
    "REFUGEE",
    "REFUSE",
    "REGARD",
    "REGARDING",
    "REGARDLESS",
    "REGIME",
    "REGION",
    "REGIONAL",
    "REGISTER",
    "REGULAR",
    "REGULARLY",
    "REGULATE",
    "REGULATION",
    "REINFORCE",
    "REJECT",
    "RELATE",
    "RELATED",
    "RELATION",
    "RELATIONSHIP",
    "RELATIVE",
    "RELATIVELY",
    "RELAX",
    "RELEASE",
    "RELEVANT",
    "RELIEF",
    "RELIGION",
    "RELIGIOUS",
    "RELY",
    "REMAIN",
    "REMAINING",
    "REMARKABLE",
    "REMEMBER",
    "REMIND",
    "REMOTE",
    "REMOVE",
    "REPEAT",
    "REPEATEDLY",
    "REPLACE",
    "REPLACEMENT",
    "REPLY",
    "REPORT",
    "REPORTER",
    "REPRESENT",
    "REPRESENTATION",
    "REPRESENTATIVE",
    "REPUBLIC",
    "REPUBLICAN",
    "REPUTATION",
    "REQUEST",
    "REQUIRE",
    "REQUIREMENT",
    "RESCUE",
    "RESEARCH",
    "RESEARCHER",
    "RESERVATION",
    "RESERVE",
    "RESIDENT",
    "RESIDENTIAL",
    "RESIGN",
    "RESIST",
    "RESISTANCE",
    "RESOLUTION",
    "RESOLVE",
    "RESORT",
    "RESOURCE",
    "RESPECT",
    "RESPOND",
    "RESPONDENT",
    "RESPONSE",
    "RESPONSIBILITY",
    "RESPONSIBLE",
    "REST",
    "RESTAURANT",
    "RESTORE",
    "RESTRICTION",
    "RESULT",
    "RETAIN",
    "RETIRE",
    "RETIREMENT",
    "RETURN",
    "REVEAL",
    "REVENUE",
    "REVERSE",
    "REVIEW",
    "REVOLUTION",
    "REWARD",
    "RHETORIC",
    "RHYTHM",
    "RICE",
    "RICH",
    "RIDE",
    "RIDER",
    "RIDICULOUS",
    "RIGHT",
    "RING",
    "RISE",
    "RISING",
    "RISK",
    "RIVER",
    "ROAD",
    "ROBOT",
    "ROCK",
    "ROLE",
    "ROLL",
    "ROMANTIC",
    "ROOF",
    "ROOM",
    "ROOT",
    "ROPE",
    "ROSE",
    "ROUGH",
    "ROUGHLY",
    "ROUND",
    "ROUTE",
    "ROUTINE",
    "ROYAL",
    "RUBBISH",
    "RULE",
    "RULING",
    "RUNNING",
    "RURAL",
    "RUSH",
    "SACRED",
    "SACRIFICE",
    "SADLY",
    "SAFE",
    "SAFETY",
    "SAKE",
    "SALAD",
    "SALARY",
    "SALE",
    "SALES",
    "SALT",
    "SAME",
    "SAMPLE",
    "SANCTION",
    "SAND",
    "SATELLITE",
    "SATISFACTION",
    "SATISFY",
    "SAUCE",
    "SAVE",
    "SAVING",
    "SCALE",
    "SCANDAL",
    "SCARED",
    "SCENARIO",
    "SCENE",
    "SCHEDULE",
    "SCHEME",
    "SCHOLAR",
    "SCHOLARSHIP",
    "SCHOOL",
    "SCIENCE",
    "SCIENTIFIC",
    "SCIENTIST",
    "SCOPE",
    "SCORE",
    "SCREEN",
    "SCRIPT",
    "SCULPTURE",
    "SEARCH",
    "SEASON",
    "SEAT",
    "SECOND",
    "SECONDARY",
    "SECRET",
    "SECRETARY",
    "SECTION",
    "SECTOR",
    "SECURE",
    "SECURITY",
    "SEED",
    "SEEK",
    "SEEM",
    "SEGMENT",
    "SEIZE",
    "SELECT",
    "SELECTION",
    "SELF",
    "SELL",
    "SENATE",
    "SENATOR",
    "SEND",
    "SENIOR",
    "SENSE",
    "SENSITIVE",
    "SENTENCE",
    "SEPARATE",
    "SEQUENCE",
    "SERIES",
    "SERIOUS",
    "SERIOUSLY",
    "SERVANT",
    "SERVE",
    "SERVER",
    "SERVICE",
    "SESSION",
    "SETTING",
    "SETTLE",
    "SETTLEMENT",
    "SEVEN",
    "SEVERAL",
    "SEVERE",
    "SHAKE",
    "SHALL",
    "SHAME",
    "SHAPE",
    "SHARE",
    "SHARP",
    "SHEET",
    "SHELF",
    "SHELL",
    "SHELTER",
    "SHIFT",
    "SHINE",
    "SHIP",
    "SHIRT",
    "SHOCK",
    "SHOE",
    "SHOOT",
    "SHOOTING",
    "SHOP",
    "SHOPPING",
    "SHORE",
    "SHORT",
    "SHORTLY",
    "SHOT",
    "SHOULD",
    "SHOULDER",
    "SHOUT",
    "SHOW",
    "SHOWER",
    "SHUT",
    "SICK",
    "SIDE",
    "SIGHT",
    "SIGN",
    "SIGNAL",
    "SIGNATURE",
    "SIGNIFICANCE",
    "SIGNIFICANT",
    "SIGNIFICANTLY",
    "SILENCE",
    "SILENT",
    "SILVER",
    "SIMILAR",
    "SIMILARLY",
    "SIMPLE",
    "SIMPLY",
    "SINCE",
    "SING",
    "SINGER",
    "SINGLE",
    "SINK",
    "SISTER",
    "SITE",
    "SITUATION",
    "SIZE",
    "SKILL",
    "SKIN",
    "SLEEP",
    "SLICE",
    "SLIDE",
    "SLIGHT",
    "SLIGHTLY",
    "SLIP",
    "SLOW",
    "SLOWLY",
    "SMALL",
    "SMART",
    "SMELL",
    "SMILE",
    "SMOKE",
    "SMOKING",
    "SMOOTH",
    "SNAP",
    "SNOW",
    "SOCCER",
    "SOCIAL",
    "SOCIETY",
    "SOFT",
    "SOFTWARE",
    "SOIL",
    "SOLAR",
    "SOLDIER",
    "SOLE",
    "SOLELY",
    "SOLID",
    "SOLUTION",
    "SOLVE",
    "SOME",
    "SOMEBODY",
    "SOMEHOW",
    "SOMEONE",
    "SOMETHING",
    "SOMETIMES",
    "SOMEWHAT",
    "SOMEWHERE",
    "SONG",
    "SOON",
    "SOPHISTICATED",
    "SORRY",
    "SORT",
    "SOUL",
    "SOUND",
    "SOUP",
    "SOURCE",
    "SOUTH",
    "SOUTHERN",
    "SPACE",
    "SPAN",
    "SPANISH",
    "SPARE",
    "SPEAK",
    "SPEAKER",
    "SPEAKING",
    "SPECIAL",
    "SPECIALIST",
    "SPECIES",
    "SPECIFIC",
    "SPECIFICALLY",
    "SPEECH",
    "SPEED",
    "SPEND",
    "SPENDING",
    "SPIN",
    "SPIRIT",
    "SPIRITUAL",
    "SPLIT",
    "SPOKESMAN",
    "SPONSOR",
    "SPORT",
    "SPOT",
    "SPREAD",
    "SPRING",
    "SQUAD",
    "SQUARE",
    "SQUEEZE",
    "STABILITY",
    "STABLE",
    "STACK",
    "STAFF",
    "STAGE",
    "STAIR",
    "STAKE",
    "STAND",
    "STANDARD",
    "STANDING",
    "STAR",
    "STARE",
    "START",
    "STATE",
    "STATEMENT",
    "STATION",
    "STATISTICAL",
    "STATISTICS",
    "STATUS",
    "STAY",
    "STEADY",
    "STEAL",
    "STEAM",
    "STEEL",
    "STEEP",
    "STEM",
    "STEP",
    "STICK",
    "STIFF",
    "STILL",
    "STIMULUS",
    "STOCK",
    "STOMACH",
    "STONE",
    "STOP",
    "STORAGE",
    "STORE",
    "STORM",
    "STORY",
    "STRAIGHT",
    "STRAIN",
    "STRANGE",
    "STRANGER",
    "STRATEGIC",
    "STRATEGY",
    "STREAM",
    "STREET",
    "STRENGTH",
    "STRENGTHEN",
    "STRESS",
    "STRETCH",
    "STRICT",
    "STRIKE",
    "STRING",
    "STRIP",
    "STROKE",
    "STRONG",
    "STRONGLY",
    "STRUCTURAL",
    "STRUCTURE",
    "STRUGGLE",
    "STUDENT",
    "STUDIO",
    "STUDY",
    "STUFF",
    "STUPID",
    "STYLE",
    "SUBJECT",
    "SUBMIT",
    "SUBSEQUENT",
    "SUBSTANCE",
    "SUBSTANTIAL",
    "SUBTLE",
    "SUCCEED",
    "SUCCESS",
    "SUCCESSFUL",
    "SUCCESSFULLY",
    "SUCH",
    "SUDDEN",
    "SUDDENLY",
    "SUFFER",
    "SUFFICIENT",
    "SUGAR",
    "SUGGEST",
    "SUGGESTION",
    "SUICIDE",
    "SUIT",
    "SUMMER",
    "SUMMIT",
    "SUPER",
    "SUPPLY",
    "SUPPORT",
    "SUPPORTER",
    "SUPPOSE",
    "SUPPOSED",
    "SUPREME",
    "SURE",
    "SURELY",
    "SURFACE",
    "SURGERY",
    "SURPRISE",
    "SURPRISED",
    "SURPRISING",
    "SURPRISINGLY",
    "SURROUND",
    "SURVEY",
    "SURVIVAL",
    "SURVIVE",
    "SURVIVOR",
    "SUSPECT",
    "SUSPEND",
    "SUSTAIN",
    "SWEAR",
    "SWEEP",
    "SWEET",
    "SWIM",
    "SWING",
    "SWITCH",
    "SYMBOL",
    "SYMPTOM",
    "SYSTEM",
    "TABLE",
    "TABLET",
    "TACTIC",
    "TAIL",
    "TAKE",
    "TALE",
    "TALENT",
    "TALK",
    "TALKING",
    "TALL",
    "TANK",
    "TAPE",
    "TARGET",
    "TASK",
    "TASTE",
    "TEACHER",
    "TEACHING",
    "TEAM",
    "TEAR",
    "TECHNICAL",
    "TECHNIQUE",
    "TECHNOLOGY",
    "TEENAGE",
    "TEENAGER",
    "TELEPHONE",
    "TELEVISION",
    "TELL",
    "TEMPERATURE",
    "TEMPLE",
    "TEMPORARY",
    "TEND",
    "TENDENCY",
    "TENSION",
    "TENT",
    "TERM",
    "TERMS",
    "TERRIBLE",
    "TERRITORY",
    "TERROR",
    "TERRORISM",
    "TERRORIST",
    "TEST",
    "TESTIFY",
    "TESTIMONY",
    "TESTING",
    "TEXT",
    "THAN",
    "THANK",
    "THANKS",
    "THAT",
    "THEATER",
    "THEME",
    "THEMSELVES",
    "THEN",
    "THEORY",
    "THERAPY",
    "THERE",
    "THEREBY",
    "THEREFORE",
    "THICK",
    "THIN",
    "THING",
    "THINK",
    "THINKING",
    "THIRD",
    "THIRTY",
    "THIS",
    "THOROUGH",
    "THOSE",
    "THOUGH",
    "THOUGHT",
    "THOUSAND",
    "THREAD",
    "THREAT",
    "THREATEN",
    "THREE",
    "THROAT",
    "THROUGH",
    "THROUGHOUT",
    "THROW",
    "THUS",
    "TICKET",
    "TIGHT",
    "TIME",
    "TINY",
    "TIRE",
    "TIRED",
    "TISSUE",
    "TITLE",
    "TODAY",
    "TOGETHER",
    "TOLERANCE",
    "TOLL",
    "TOMATO",
    "TOMORROW",
    "TONE",
    "TONGUE",
    "TONIGHT",
    "TOOL",
    "TOOTH",
    "TOPIC",
    "TOTAL",
    "TOTALLY",
    "TOUCH",
    "TOUGH",
    "TOUR",
    "TOURIST",
    "TOURNAMENT",
    "TOWARD",
    "TOWARDS",
    "TOWER",
    "TOWN",
    "TRACK",
    "TRADE",
    "TRADITION",
    "TRADITIONAL",
    "TRAFFIC",
    "TRAGEDY",
    "TRAIL",
    "TRAIN",
    "TRAINER",
    "TRAINING",
    "TRANSFER",
    "TRANSFORM",
    "TRANSFORMATION",
    "TRANSITION",
    "TRANSLATE",
    "TRANSMISSION",
    "TRANSPORT",
    "TRANSPORTATION",
    "TRAP",
    "TRAVEL",
    "TREAT",
    "TREATMENT",
    "TREATY",
    "TREE",
    "TREMENDOUS",
    "TREND",
    "TRIAL",
    "TRIBE",
    "TRIBUTE",
    "TRICK",
    "TRIGGER",
    "TRILLION",
    "TRIP",
    "TROOP",
    "TROUBLE",
    "TRUCK",
    "TRUE",
    "TRULY",
    "TRUST",
    "TRUTH",
    "TUBE",
    "TUNNEL",
    "TURN",
    "TWELVE",
    "TWENTY",
    "TWICE",
    "TWIN",
    "TYPE",
    "TYPICAL",
    "TYPICALLY",
    "UGLY",
    "ULTIMATE",
    "ULTIMATELY",
    "UNABLE",
    "UNCLE",
    "UNDER",
    "UNDERGO",
    "UNDERSTAND",
    "UNDERSTANDING",
    "UNFORTUNATELY",
    "UNIFORM",
    "UNION",
    "UNIQUE",
    "UNIT",
    "UNITED",
    "UNITY",
    "UNIVERSAL",
    "UNIVERSE",
    "UNIVERSITY",
    "UNKNOWN",
    "UNLESS",
    "UNLIKE",
    "UNLIKELY",
    "UNTIL",
    "UNUSUAL",
    "UPDATE",
    "UPON",
    "UPPER",
    "UPSET",
    "URBAN",
    "URGE",
    "USED",
    "USEFUL",
    "USER",
    "USUAL",
    "USUALLY",
    "UTILITY",
    "VACATION",
    "VALID",
    "VALLEY",
    "VALUABLE",
    "VALUE",
    "VARIABLE",
    "VARIATION",
    "VARIETY",
    "VARIOUS",
    "VARY",
    "VAST",
    "VEGETABLE",
    "VEHICLE",
    "VENTURE",
    "VERSION",
    "VERSUS",
    "VERY",
    "VESSEL",
    "VETERAN",
    "VICTIM",
    "VICTORY",
    "VIDEO",
    "VIEW",
    "VIEWER",
    "VILLAGE",
    "VIOLATE",
    "VIOLATION",
    "VIOLENCE",
    "VIOLENT",
    "VIRTUAL",
    "VIRTUALLY",
    "VIRTUE",
    "VIRUS",
    "VISIBLE",
    "VISION",
    "VISIT",
    "VISITOR",
    "VISUAL",
    "VITAL",
    "VOICE",
    "VOLUME",
    "VOLUNTEER",
    "VOTE",
    "VOTER",
    "VULNERABLE",
    "WAGE",
    "WAIT",
    "WAKE",
    "WALK",
    "WALL",
    "WANDER",
    "WANT",
    "WARM",
    "WARN",
    "WARNING",
    "WASH",
    "WASTE",
    "WATCH",
    "WATER",
    "WAVE",
    "WEAK",
    "WEALTH",
    "WEALTHY",
    "WEAPON",
    "WEAR",
    "WEATHER",
    "WEDDING",
    "WEEK",
    "WEEKEND",
    "WEEKLY",
    "WEIGH",
    "WEIGHT",
    "WEIRD",
    "WELCOME",
    "WELFARE",
    "WELL",
    "WEST",
    "WESTERN",
    "WHATEVER",
    "WHEEL",
    "WHENEVER",
    "WHERE",
    "WHEREAS",
    "WHETHER",
    "WHICH",
    "WHILE",
    "WHISPER",
    "WHITE",
    "WHOLE",
    "WHOM",
    "WHOSE",
    "WIDE",
    "WIDELY",
    "WIDESPREAD",
    "WIFE",
    "WILD",
    "WILDLIFE",
    "WILL",
    "WILLING",
    "WIND",
    "WINDOW",
    "WINE",
    "WING",
    "WINNER",
    "WINTER",
    "WIRE",
    "WISDOM",
    "WISE",
    "WISH",
    "WITH",
    "WITHDRAW",
    "WITHIN",
    "WITHOUT",
    "WITNESS",
    "WOMAN",
    "WOMEN",
    "WONDER",
    "WONDERFUL",
    "WOOD",
    "WOODEN",
    "WORD",
    "WORK",
    "WORKER",
    "WORKING",
    "WORKOUT",
    "WORKPLACE",
    "WORKSHOP",
    "WORLD",
    "WORRIED",
    "WORRY",
    "WORSE",
    "WORST",
    "WORTH",
    "WOULD",
    "WOUND",
    "WRAP",
    "WRITE",
    "WRITER",
    "WRITING",
    "WRONG",
    "YARD",
    "YEAH",
    "YEAR",
    "YELLOW",
    "YESTERDAY",
    "YIELD",
    "YOUNG",
    "YOUNGSTER",
    "YOUR",
    "YOURS",
    "YOURSELF",
    "YOUTH",
    "ZERO",
    "ZONE",
  ];

  generate(difficulty: "easy" | "medium" | "hard" | "expert"): {
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
    // Try to find a good letter set with enough words AND at least one pangram
    let bestResult = this.tryGeneratePuzzle();
    let attempts = 0;
    const maxAttempts = 100;

    // Target word counts based on difficulty
    const minWords = { easy: 15, medium: 25, hard: 35, expert: 50 }[difficulty];

    // MUST have at least one pangram (7-letter word using all letters)
    while (
      (bestResult.pangrams.length === 0 ||
        bestResult.validWords.length < minWords) &&
      attempts < maxAttempts
    ) {
      const newResult = this.tryGeneratePuzzle();
      // Prefer results with pangrams
      if (newResult.pangrams.length > 0) {
        if (
          bestResult.pangrams.length === 0 ||
          newResult.validWords.length > bestResult.validWords.length
        ) {
          bestResult = newResult;
        }
      } else if (
        bestResult.pangrams.length === 0 &&
        newResult.validWords.length > bestResult.validWords.length
      ) {
        bestResult = newResult;
      }
      attempts++;
    }

    // If still no pangram after max attempts, try using known pangram-friendly letter sets
    if (bestResult.pangrams.length === 0) {
      bestResult = this.generateWithKnownPangram();
    }

    // Calculate score
    const maxScore = this.calculateMaxScore(
      bestResult.validWords,
      bestResult.pangrams,
    );

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
    const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
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

  // Pre-defined pangram puzzles with guaranteed 7-letter words
  private static readonly PANGRAM_SETS = [
    {
      letters: ["G", "A", "R", "D", "E", "N", "I"],
      centerLetter: "G",
      pangrams: ["READING", "GRADING"],
      validWords: [
        "GAIN",
        "GRIN",
        "GRIND",
        "GRAIN",
        "GRAND",
        "GRADE",
        "RANGE",
        "ANGER",
        "DANGER",
        "GARDEN",
        "READING",
        "GRADING",
        "RIDGE",
        "AGING",
        "RAGED",
        "RING",
        "DRAG",
        "DARING",
        "RAGING",
      ],
    },
    {
      letters: ["T", "R", "A", "I", "N", "E", "D"],
      centerLetter: "T",
      pangrams: ["TRAINED"],
      validWords: [
        "TRAIN",
        "TRADE",
        "TREAD",
        "TREAT",
        "TRIED",
        "TIRED",
        "RATE",
        "TEAR",
        "TIDE",
        "DATE",
        "TEND",
        "RENT",
        "DENT",
        "NEAT",
        "EDIT",
        "DIET",
        "RIDE",
        "RAIN",
        "DRAIN",
        "RANTED",
        "TRAINED",
        "RATED",
        "TRADED",
      ],
    },
    {
      letters: ["S", "T", "A", "R", "I", "N", "G"],
      centerLetter: "S",
      pangrams: ["RATINGS", "STARING"],
      validWords: [
        "STAR",
        "STAIRS",
        "STIR",
        "SING",
        "STING",
        "STRING",
        "RING",
        "RAIN",
        "GRAIN",
        "TRAIN",
        "STRAIN",
        "RATS",
        "ARTS",
        "GRANT",
        "GRANTS",
        "GIANT",
        "GIANTS",
        "SAINT",
        "SAINTS",
        "STARING",
        "RATINGS",
        "GRAINS",
        "TRAINS",
      ],
    },
    {
      letters: ["P", "L", "A", "Y", "I", "N", "G"],
      centerLetter: "P",
      pangrams: ["PLAYING"],
      validWords: [
        "PLAY",
        "PLAN",
        "PAIN",
        "PAIL",
        "PLAIN",
        "PLYING",
        "PLAYING",
        "APPLY",
        "PAYING",
        "PING",
        "NAIL",
        "GAIN",
        "ALIGN",
        "LYING",
        "INLAY",
        "LAYING",
      ],
    },
    {
      letters: ["C", "R", "E", "A", "T", "I", "N"],
      centerLetter: "C",
      pangrams: ["CERTAIN"],
      validWords: [
        "CARE",
        "CART",
        "RACE",
        "TRACE",
        "CRANE",
        "CREATE",
        "REACT",
        "NECTAR",
        "TRANCE",
        "CERTAIN",
        "CITE",
        "NICE",
        "RICE",
        "CRATE",
        "RETAIN",
        "ACNE",
        "CANE",
        "ANTIC",
      ],
    },
    {
      letters: ["W", "O", "R", "K", "I", "N", "G"],
      centerLetter: "W",
      pangrams: ["WORKING"],
      validWords: [
        "WORK",
        "WORN",
        "WINK",
        "WING",
        "KNOW",
        "GROW",
        "GOWN",
        "ROWING",
        "KNOWING",
        "WORKING",
        "GROWN",
        "WRONG",
        "OWING",
        "GROWING",
        "WRING",
      ],
    },
  ];

  // Fallback: Use pre-defined pangram sets
  private generateWithKnownPangram(): {
    letters: string[];
    centerLetter: string;
    validWords: string[];
    pangrams: string[];
  } {
    // Pick a random pre-defined set
    const set =
      WordForgeGenerator.PANGRAM_SETS[
        Math.floor(Math.random() * WordForgeGenerator.PANGRAM_SETS.length)
      ];
    return {
      letters: [...set.letters],
      centerLetter: set.centerLetter,
      validWords: [...set.validWords],
      pangrams: [...set.pangrams],
    };
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
  generate(difficulty: "easy" | "medium" | "hard" | "expert"): {
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

    // Try to generate a logically solvable puzzle
    const maxAttempts = 50;
    for (let attempt = 0; attempt < maxAttempts; attempt++) {
      // Generate a random pattern with some structure
      const grid = this.generatePattern(size, size, difficulty);

      // Generate clues from the pattern
      const rowClues = this.generateRowClues(grid);
      const colClues = this.generateColClues(grid);

      // Verify the puzzle is solvable using pure logic (no guessing)
      if (this.isLogicallySolvable(rowClues, colClues, grid)) {
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
    }

    // Fallback: generate a simple, guaranteed-solvable pattern
    const grid = this.generateSimplePattern(size);
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

  /**
   * Checks if a nonogram can be solved using line-by-line logic alone (no guessing)
   */
  private isLogicallySolvable(
    rowClues: number[][],
    colClues: number[][],
    _solution: number[][],
  ): boolean {
    const rows = rowClues.length;
    const cols = colClues.length;

    // 0 = unknown, 1 = filled, -1 = empty
    const grid: number[][] = Array(rows)
      .fill(null)
      .map(() => Array(cols).fill(0));

    let changed = true;
    let iterations = 0;
    const maxIterations = rows * cols * 2;

    while (changed && iterations < maxIterations) {
      changed = false;
      iterations++;

      // Process each row
      for (let r = 0; r < rows; r++) {
        const line = grid[r].slice();
        const newLine = this.solveLine(line, rowClues[r]);
        for (let c = 0; c < cols; c++) {
          if (grid[r][c] === 0 && newLine[c] !== 0) {
            grid[r][c] = newLine[c];
            changed = true;
          }
        }
      }

      // Process each column
      for (let c = 0; c < cols; c++) {
        const line = grid.map((row) => row[c]);
        const newLine = this.solveLine(line, colClues[c]);
        for (let r = 0; r < rows; r++) {
          if (grid[r][c] === 0 && newLine[r] !== 0) {
            grid[r][c] = newLine[r];
            changed = true;
          }
        }
      }
    }

    // Check if fully solved (no unknowns remain)
    for (let r = 0; r < rows; r++) {
      for (let c = 0; c < cols; c++) {
        if (grid[r][c] === 0) {
          return false; // Still has unknowns - requires guessing
        }
      }
    }

    return true;
  }

  /**
   * Solve a single line using line-solving logic
   * Returns array with 1 (filled), -1 (empty), or 0 (unknown)
   */
  private solveLine(line: number[], clues: number[]): number[] {
    const len = line.length;
    const result = line.slice();

    // Handle empty line (clue is [0])
    if (clues.length === 1 && clues[0] === 0) {
      return result.map((c) => (c === 0 ? -1 : c));
    }

    // Handle fully filled line
    const totalFilled = clues.reduce((a, b) => a + b, 0);
    const minSpaces = clues.length - 1;
    if (totalFilled + minSpaces === len) {
      // Entire line is determined
      let pos = 0;
      for (let i = 0; i < clues.length; i++) {
        for (let j = 0; j < clues[i]; j++) {
          result[pos++] = 1;
        }
        if (i < clues.length - 1) {
          result[pos++] = -1;
        }
      }
      return result;
    }

    // Generate all possible placements for the clues
    const placements = this.generatePlacements(clues, len, line);

    if (placements.length === 0) {
      return result; // Invalid state, return as-is
    }

    // Find cells that are the same across all valid placements
    for (let i = 0; i < len; i++) {
      if (result[i] !== 0) continue;

      const firstVal = placements[0][i];
      let allSame = true;
      for (let p = 1; p < placements.length; p++) {
        if (placements[p][i] !== firstVal) {
          allSame = false;
          break;
        }
      }
      if (allSame) {
        result[i] = firstVal;
      }
    }

    return result;
  }

  /**
   * Generate all valid placements for clues on a line
   */
  private generatePlacements(
    clues: number[],
    len: number,
    current: number[],
  ): number[][] {
    const results: number[][] = [];

    const generate = (
      clueIdx: number,
      pos: number,
      placement: number[],
    ): void => {
      if (clueIdx === clues.length) {
        // Fill rest with empty
        const final = placement.slice();
        for (let i = pos; i < len; i++) {
          final[i] = -1;
        }
        // Verify placement matches current constraints
        let valid = true;
        for (let i = 0; i < len; i++) {
          if (current[i] !== 0 && current[i] !== final[i]) {
            valid = false;
            break;
          }
        }
        if (valid) {
          results.push(final);
        }
        return;
      }

      const clue = clues[clueIdx];
      const remaining = clues.slice(clueIdx + 1).reduce((a, b) => a + b, 0);
      const remainingSpaces = clues.length - clueIdx - 1;
      const maxStart = len - remaining - remainingSpaces - clue;

      for (let start = pos; start <= maxStart; start++) {
        // Check if we can place clue at this position
        let canPlace = true;

        // Check empty cells before
        for (let i = pos; i < start; i++) {
          if (current[i] === 1) {
            canPlace = false;
            break;
          }
        }
        if (!canPlace) continue;

        // Check filled cells
        for (let i = start; i < start + clue; i++) {
          if (current[i] === -1) {
            canPlace = false;
            break;
          }
        }
        if (!canPlace) continue;

        // Build placement
        const newPlacement = placement.slice();
        for (let i = pos; i < start; i++) {
          newPlacement[i] = -1;
        }
        for (let i = start; i < start + clue; i++) {
          newPlacement[i] = 1;
        }

        // Add gap after if not last clue
        if (clueIdx < clues.length - 1) {
          if (current[start + clue] === 1) {
            continue; // Can't place gap here
          }
          newPlacement[start + clue] = -1;
          generate(clueIdx + 1, start + clue + 1, newPlacement);
        } else {
          generate(clueIdx + 1, start + clue, newPlacement);
        }
      }
    };

    generate(0, 0, Array(len).fill(0));
    return results;
  }

  /**
   * Generate a simple pattern that is guaranteed to be solvable
   */
  private generateSimplePattern(size: number): number[][] {
    const grid: number[][] = Array(size)
      .fill(null)
      .map(() => Array(size).fill(0));

    // Create a simple cross or diamond pattern
    const mid = Math.floor(size / 2);

    // Horizontal line
    for (let c = 1; c < size - 1; c++) {
      grid[mid][c] = 1;
    }

    // Vertical line
    for (let r = 1; r < size - 1; r++) {
      grid[r][mid] = 1;
    }

    // Add corners for visual interest
    grid[1][1] = 1;
    grid[1][size - 2] = 1;
    grid[size - 2][1] = 1;
    grid[size - 2][size - 2] = 1;

    return grid;
  }

  private generatePattern(
    rows: number,
    cols: number,
    difficulty: string,
  ): number[][] {
    const grid: number[][] = Array(rows)
      .fill(null)
      .map(() => Array(cols).fill(0));

    // Fill density based on difficulty (easier = more filled = clearer patterns)
    const fillProbability =
      { easy: 0.6, medium: 0.5, hard: 0.45, expert: 0.4 }[difficulty] || 0.5;

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
    if (difficulty === "easy") {
      const mid = Math.floor(rows / 2);
      for (let i = -1; i <= 1; i++) {
        for (let j = -1; j <= 1; j++) {
          if (
            mid + i >= 0 &&
            mid + i < rows &&
            mid + j >= 0 &&
            mid + j < cols
          ) {
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
type TargetDifficulty = "extraEasy" | "easy" | "medium" | "hard" | "expert";

export class NumberTargetGenerator {
  generate(difficulty: "easy" | "medium" | "hard" | "expert"): {
    puzzleData: {
      numbers: number[];
      target: number;
      targets?: { target: number; difficulty: TargetDifficulty }[];
    };
    solution: {
      expression: string;
      alternates: string[];
      targetSolutions?: {
        target: number;
        expression: string;
      }[];
    };
  } {
    // Number ranges based on difficulty
    const ranges = {
      easy: { min: 1, max: 9 },
      medium: { min: 1, max: 15 },
      hard: { min: 1, max: 25 },
      expert: { min: 1, max: 50 },
    };
    const range = ranges[difficulty];

    // Generate numbers and find 5 solvable targets with increasing difficulty
    let result = this.generateMultiTargetPuzzle(range, difficulty);
    let attempts = 0;

    while (!result && attempts < 100) {
      result = this.generateMultiTargetPuzzle(range, difficulty);
      attempts++;
    }

    if (!result) {
      // Fallback to known solvable puzzle with 6 numbers
      result = {
        numbers: [1, 2, 3, 4, 5, 6],
        targets: [
          { target: 3, difficulty: "extraEasy" as const, expression: "1+2" },
          { target: 11, difficulty: "easy" as const, expression: "5+6" },
          { target: 21, difficulty: "medium" as const, expression: "(1+2)*3+4+5+6" },
          { target: 90, difficulty: "hard" as const, expression: "(1+2+3)*(4+5+6)" },
          { target: 720, difficulty: "expert" as const, expression: "1*2*3*4*5*6" },
        ],
      };
    }

    // Use the medium target as the main target for backwards compatibility
    const mainTarget = result.targets[2]; // Medium is now index 2

    return {
      puzzleData: {
        numbers: result.numbers,
        target: mainTarget.target,
        targets: result.targets.map((t) => ({
          target: t.target,
          difficulty: t.difficulty,
        })),
      },
      solution: {
        expression: mainTarget.expression,
        alternates: [],
        targetSolutions: result.targets.map((t) => ({
          target: t.target,
          expression: t.expression,
        })),
      },
    };
  }

  private generateMultiTargetPuzzle(
    range: { min: number; max: number },
    _difficulty: string,
  ): {
    numbers: number[];
    targets: {
      target: number;
      difficulty: TargetDifficulty;
      expression: string;
    }[];
  } | null {
    // Generate 6 random numbers
    const numbers: number[] = [];
    for (let i = 0; i < 6; i++) {
      numbers.push(
        Math.floor(Math.random() * (range.max - range.min + 1)) + range.min,
      );
    }

    // Find all possible targets we can make with these numbers
    const allTargets = this.findAllTargets(numbers);

    if (allTargets.length < 5) {
      return null; // Need at least 5 targets
    }

    // Sort targets by value to get increasing difficulty
    allTargets.sort((a, b) => a.target - b.target);

    // Pick 5 targets across different difficulty ranges
    // Extra Easy: 2-10, Easy: 10-25, Medium: 25-75, Hard: 75-200, Expert: 200-1000
    const extraEasyTargets = allTargets.filter(
      (t) => t.target >= 2 && t.target <= 10,
    );
    const easyTargets = allTargets.filter(
      (t) => t.target > 10 && t.target <= 25,
    );
    const mediumTargets = allTargets.filter(
      (t) => t.target > 25 && t.target <= 75,
    );
    const hardTargets = allTargets.filter(
      (t) => t.target > 75 && t.target <= 200,
    );
    const expertTargets = allTargets.filter(
      (t) => t.target > 200 && t.target <= 1000,
    );

    if (
      extraEasyTargets.length === 0 ||
      easyTargets.length === 0 ||
      mediumTargets.length === 0 ||
      hardTargets.length === 0 ||
      expertTargets.length === 0
    ) {
      // Fallback: pick 5 evenly spaced from all targets
      const step = Math.floor(allTargets.length / 5);
      if (step === 0) return null;
      return {
        numbers,
        targets: [
          { ...allTargets[0], difficulty: "extraEasy" as const },
          { ...allTargets[step], difficulty: "easy" as const },
          { ...allTargets[step * 2], difficulty: "medium" as const },
          { ...allTargets[step * 3], difficulty: "hard" as const },
          { ...allTargets[step * 4], difficulty: "expert" as const },
        ],
      };
    }

    // Pick random targets from each difficulty tier
    const extraEasyTarget =
      extraEasyTargets[Math.floor(Math.random() * extraEasyTargets.length)];
    const easyTarget =
      easyTargets[Math.floor(Math.random() * easyTargets.length)];
    const mediumTarget =
      mediumTargets[Math.floor(Math.random() * mediumTargets.length)];
    const hardTarget =
      hardTargets[Math.floor(Math.random() * hardTargets.length)];
    const expertTarget =
      expertTargets[Math.floor(Math.random() * expertTargets.length)];

    return {
      numbers,
      targets: [
        { ...extraEasyTarget, difficulty: "extraEasy" as const },
        { ...easyTarget, difficulty: "easy" as const },
        { ...mediumTarget, difficulty: "medium" as const },
        { ...hardTarget, difficulty: "hard" as const },
        { ...expertTarget, difficulty: "expert" as const },
      ],
    };
  }

  private findAllTargets(
    numbers: number[],
  ): { target: number; expression: string }[] {
    const targetMap = new Map<number, string>();

    // Use recursive approach to find all possible expressions with 6 numbers
    // This explores all ways to combine numbers with +, -, *, /
    this.findTargetsRecursive(numbers, targetMap);

    return Array.from(targetMap.entries()).map(([target, expression]) => ({
      target,
      expression,
    }));
  }

  private findTargetsRecursive(
    values: (number | string)[],
    targetMap: Map<number, string>,
  ): void {
    // Base case: single value
    if (values.length === 1) {
      const val = values[0];
      const numVal = typeof val === "string" ? this.evalExpr(val) : val;
      const expr = typeof val === "string" ? val : String(val);

      if (
        numVal !== null &&
        Number.isInteger(numVal) &&
        numVal > 0 &&
        numVal <= 1000 &&
        !targetMap.has(numVal)
      ) {
        targetMap.set(numVal, expr);
      }
      return;
    }

    // Try all pairs of values and combine them
    const ops = ["+", "-", "*", "/"];

    for (let i = 0; i < values.length; i++) {
      for (let j = i + 1; j < values.length; j++) {
        const a = values[i];
        const b = values[j];
        const aExpr = typeof a === "string" ? a : String(a);
        const bExpr = typeof b === "string" ? b : String(b);

        // Remaining values after removing i and j
        const remaining = values.filter((_, idx) => idx !== i && idx !== j);

        for (const op of ops) {
          // Try a op b
          const expr1 = `(${aExpr}${op}${bExpr})`;
          const val1 = this.evalExpr(expr1);
          if (val1 !== null && Number.isFinite(val1)) {
            this.findTargetsRecursive([...remaining, expr1], targetMap);
          }

          // Try b op a (for non-commutative ops)
          if (op === "-" || op === "/") {
            const expr2 = `(${bExpr}${op}${aExpr})`;
            const val2 = this.evalExpr(expr2);
            if (val2 !== null && Number.isFinite(val2)) {
              this.findTargetsRecursive([...remaining, expr2], targetMap);
            }
          }
        }
      }
    }
  }

  private evalExpr(expr: string): number | null {
    try {
      const result = Function(`"use strict"; return (${expr})`)();
      return Number.isFinite(result) ? result : null;
    } catch {
      return null;
    }
  }

  private randomTarget(): number {
    const targets = [10, 24, 42, 50, 100, 1000];
    return targets[Math.floor(Math.random() * targets.length)];
  }

  private generateSolvablePuzzle(
    target: number,
    range: { min: number; max: number },
    _difficulty: string,
  ): { numbers: number[]; expression: string; alternates: string[] } | null {
    // Generate 6 random numbers
    const numbers: number[] = [];
    for (let i = 0; i < 6; i++) {
      numbers.push(
        Math.floor(Math.random() * (range.max - range.min + 1)) + range.min,
      );
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
    const targetMap = new Map<number, string>();

    // Use recursive approach to find all solutions
    this.findTargetsRecursive(numbers, targetMap);

    // Find expressions that match the target
    if (targetMap.has(target)) {
      solutions.push(targetMap.get(target)!);
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

// Ball Sort Generator
export class BallSortGenerator {
  private static readonly COLORS = [
    "red",
    "blue",
    "green",
    "yellow",
    "purple",
    "orange",
    "pink",
    "cyan",
    "lime",
    "teal",
  ];

  generate(difficulty: "easy" | "medium" | "hard" | "expert"): {
    puzzleData: {
      tubes: number;
      colors: number;
      tubeCapacity: number;
      initialState: string[][];
    };
    solution: {
      moves: Array<{ from: number; to: number }>;
      minMoves: number;
    };
  } {
    // Configuration based on difficulty
    // Easy: 6 tubes (4 colors + 2 empty)
    // Medium: 8 tubes (6 colors + 2 empty)
    // Hard: 10 tubes (8 colors + 2 empty)
    // Expert: 12 tubes (10 colors + 2 empty)
    const config = {
      easy: { colors: 4, tubes: 6, tubeCapacity: 4 },
      medium: { colors: 6, tubes: 8, tubeCapacity: 4 },
      hard: { colors: 8, tubes: 10, tubeCapacity: 4 },
      expert: { colors: 10, tubes: 12, tubeCapacity: 4 },
    }[difficulty];

    const colors = BallSortGenerator.COLORS.slice(0, config.colors);

    // Generate a solvable puzzle
    let result = this.generateSolvablePuzzle(config, colors);
    let attempts = 0;

    // Try to generate a puzzle with good minimum moves
    while (result.minMoves < 10 && attempts < 20) {
      const newResult = this.generateSolvablePuzzle(config, colors);
      if (newResult.minMoves > result.minMoves) {
        result = newResult;
      }
      attempts++;
    }

    return {
      puzzleData: {
        tubes: config.tubes,
        colors: config.colors,
        tubeCapacity: config.tubeCapacity,
        initialState: result.initialState,
      },
      solution: {
        moves: result.moves,
        minMoves: result.minMoves,
      },
    };
  }

  private generateSolvablePuzzle(
    config: { colors: number; tubes: number; tubeCapacity: number },
    colors: string[],
  ): {
    initialState: string[][];
    moves: Array<{ from: number; to: number }>;
    minMoves: number;
  } {
    // Start with solved state and scramble
    const solvedState: string[][] = [];

    // Fill tubes with single colors (solved state)
    for (let i = 0; i < config.colors; i++) {
      const tube: string[] = [];
      for (let j = 0; j < config.tubeCapacity; j++) {
        tube.push(colors[i]);
      }
      solvedState.push(tube);
    }

    // Add empty tubes
    for (let i = config.colors; i < config.tubes; i++) {
      solvedState.push([]);
    }

    // Scramble by making random valid moves in reverse
    const scrambled = this.scramblePuzzle(solvedState, config);

    // Solve the scrambled puzzle to get the solution
    const solution = this.solvePuzzle(scrambled, config);

    return {
      initialState: scrambled,
      moves: solution.moves,
      minMoves: solution.moves.length,
    };
  }

  private scramblePuzzle(
    state: string[][],
    config: { colors: number; tubes: number; tubeCapacity: number },
  ): string[][] {
    // Collect all balls into a single array
    const allBalls: string[] = [];
    for (const tube of state) {
      allBalls.push(...tube);
    }

    // Fisher-Yates shuffle
    for (let i = allBalls.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [allBalls[i], allBalls[j]] = [allBalls[j], allBalls[i]];
    }

    // Distribute balls into tubes (fill colored tubes, leave empty tubes empty)
    const scrambled: string[][] = [];
    let ballIndex = 0;

    for (let i = 0; i < config.colors; i++) {
      const tube: string[] = [];
      for (let j = 0; j < config.tubeCapacity; j++) {
        tube.push(allBalls[ballIndex++]);
      }
      scrambled.push(tube);
    }

    // Add empty tubes
    for (let i = config.colors; i < config.tubes; i++) {
      scrambled.push([]);
    }

    // Ensure puzzle isn't already solved (extremely unlikely but check anyway)
    if (this.isSolved(scrambled)) {
      // Swap two balls from different tubes
      const temp = scrambled[0][0];
      scrambled[0][0] = scrambled[1][0];
      scrambled[1][0] = temp;
    }

    return scrambled;
  }

  private getValidMoves(
    state: string[][],
    tubeCapacity: number,
  ): Array<{ from: number; to: number }> {
    const moves: Array<{ from: number; to: number }> = [];

    for (let from = 0; from < state.length; from++) {
      if (state[from].length === 0) continue; // Can't move from empty tube

      const topBall = state[from][state[from].length - 1];

      for (let to = 0; to < state.length; to++) {
        if (from === to) continue;

        // Can move to empty tube or tube with same color on top
        if (state[to].length === 0) {
          // Don't move to empty if source tube is all same color (pointless)
          if (!this.isTubeAllSameColor(state[from])) {
            moves.push({ from, to });
          }
        } else if (state[to].length < tubeCapacity) {
          const topOfDest = state[to][state[to].length - 1];
          if (topOfDest === topBall) {
            moves.push({ from, to });
          }
        }
      }
    }

    return moves;
  }

  private isTubeAllSameColor(tube: string[]): boolean {
    if (tube.length === 0) return true;
    return tube.every((ball) => ball === tube[0]);
  }

  private makeMove(state: string[][], from: number, to: number): void {
    const ball = state[from].pop();
    if (ball) {
      state[to].push(ball);
    }
  }

  private isSolved(state: string[][]): boolean {
    for (const tube of state) {
      if (tube.length > 0 && !this.isTubeAllSameColor(tube)) {
        return false;
      }
    }
    return true;
  }

  private solvePuzzle(
    initialState: string[][],
    config: { colors: number; tubes: number; tubeCapacity: number },
  ): { moves: Array<{ from: number; to: number }> } {
    // BFS to find shortest solution
    const stateToString = (state: string[][]): string => {
      return state.map((tube) => tube.join(",")).join("|");
    };

    const queue: Array<{
      state: string[][];
      moves: Array<{ from: number; to: number }>;
    }> = [{ state: initialState.map((t) => [...t]), moves: [] }];

    const visited = new Set<string>();
    visited.add(stateToString(initialState));

    let iterations = 0;
    const maxIterations = 50000;

    while (queue.length > 0 && iterations < maxIterations) {
      iterations++;
      const current = queue.shift()!;

      if (this.isSolved(current.state)) {
        return { moves: current.moves };
      }

      const validMoves = this.getValidMoves(current.state, config.tubeCapacity);

      for (const move of validMoves) {
        const newState = current.state.map((t) => [...t]);
        this.makeMove(newState, move.from, move.to);

        const stateStr = stateToString(newState);
        if (!visited.has(stateStr)) {
          visited.add(stateStr);
          queue.push({
            state: newState,
            moves: [...current.moves, move],
          });
        }
      }
    }

    // If no solution found in time, return empty (shouldn't happen with valid puzzles)
    return { moves: [] };
  }
}

// Export convenience functions
export const generateWordForge = (
  difficulty: "easy" | "medium" | "hard" | "expert",
) => {
  const generator = new WordForgeGenerator();
  return generator.generate(difficulty);
};

export const generateNonogram = (
  difficulty: "easy" | "medium" | "hard" | "expert",
) => {
  const generator = new NonogramGenerator();
  return generator.generate(difficulty);
};

export const generateNumberTarget = (
  difficulty: "easy" | "medium" | "hard" | "expert",
) => {
  const generator = new NumberTargetGenerator();
  return generator.generate(difficulty);
};

export const generateBallSort = (
  difficulty: "easy" | "medium" | "hard" | "expert",
) => {
  const generator = new BallSortGenerator();
  return generator.generate(difficulty);
};

// Pipes (Flow Free) Generator
export class PipesGenerator {
  private static readonly COLORS = [
    "red",
    "blue",
    "green",
    "yellow",
    "orange",
    "purple",
    "pink",
    "cyan",
  ];

  generate(difficulty: "easy" | "medium" | "hard" | "expert"): {
    puzzleData: {
      rows: number;
      cols: number;
      endpoints: Array<{ color: string; row: number; col: number }>;
      bridges: Array<{ row: number; col: number }>;
    };
    solution: {
      paths: Record<string, Array<{ row: number; col: number }>>;
    };
  } {
    const config = {
      easy: { size: 5, colors: 5 },
      medium: { size: 6, colors: 6 },
      hard: { size: 7, colors: 8 },
      expert: { size: 8, colors: 10 },
    }[difficulty];

    const colors = PipesGenerator.COLORS.slice(0, config.colors);

    // Try to generate a full-grid puzzle
    for (let attempt = 0; attempt < 20; attempt++) {
      const result = this.generateFullGridPuzzle(config.size, colors);
      if (result) {
        return {
          puzzleData: {
            rows: config.size,
            cols: config.size,
            endpoints: result.endpoints,
            bridges: [],
          },
          solution: {
            paths: result.paths,
          },
        };
      }
    }

    // Fallback to snake pattern
    const result = this.generateSnakePuzzle(config.size, colors);
    return {
      puzzleData: {
        rows: config.size,
        cols: config.size,
        endpoints: result.endpoints,
        bridges: [],
      },
      solution: {
        paths: result.paths,
      },
    };
  }

  private generateFullGridPuzzle(
    size: number,
    colors: string[],
  ): {
    endpoints: Array<{ color: string; row: number; col: number }>;
    paths: Record<string, Array<{ row: number; col: number }>>;
  } | null {
    const grid: number[][] = Array(size)
      .fill(null)
      .map(() => Array(size).fill(-1));

    const paths: Array<Array<{ row: number; col: number }>> = colors.map(
      () => [],
    );

    // Try to fill the grid using backtracking
    if (!this.fillGridBacktrack(grid, paths, size, colors.length)) {
      return null;
    }

    // Convert to output format
    const endpoints: Array<{ color: string; row: number; col: number }> = [];
    const pathsRecord: Record<string, Array<{ row: number; col: number }>> = {};

    for (let i = 0; i < colors.length; i++) {
      // Require at least 3 cells per path so endpoints aren't adjacent (trivial puzzle)
      if (paths[i].length >= 3) {
        pathsRecord[colors[i]] = paths[i];
        endpoints.push({
          color: colors[i],
          row: paths[i][0].row,
          col: paths[i][0].col,
        });
        endpoints.push({
          color: colors[i],
          row: paths[i][paths[i].length - 1].row,
          col: paths[i][paths[i].length - 1].col,
        });
      }
    }

    // Verify all colors have valid paths
    if (Object.keys(pathsRecord).length !== colors.length) {
      return null;
    }

    return { endpoints, paths: pathsRecord };
  }

  private fillGridBacktrack(
    grid: number[][],
    paths: Array<Array<{ row: number; col: number }>>,
    size: number,
    numColors: number,
  ): boolean {
    // Find first empty cell
    let emptyRow = -1,
      emptyCol = -1;
    outer: for (let r = 0; r < size; r++) {
      for (let c = 0; c < size; c++) {
        if (grid[r][c] === -1) {
          emptyRow = r;
          emptyCol = c;
          break outer;
        }
      }
    }

    // If no empty cell, check all paths are valid
    // Require at least 3 cells per path so endpoints aren't adjacent (trivial puzzle)
    if (emptyRow === -1) {
      return paths.every((p) => p.length >= 3);
    }

    // Shuffle color order for randomness
    const colorOrder = this.shuffledRange(numColors);

    for (const colorIdx of colorOrder) {
      const path = paths[colorIdx];

      // Option 1: Start a new path here (if path is empty)
      if (path.length === 0) {
        grid[emptyRow][emptyCol] = colorIdx;
        path.push({ row: emptyRow, col: emptyCol });

        if (this.fillGridBacktrack(grid, paths, size, numColors)) {
          return true;
        }

        grid[emptyRow][emptyCol] = -1;
        path.pop();
      }

      // Option 2: Extend existing path (if adjacent to path end)
      if (path.length > 0) {
        const last = path[path.length - 1];
        const isAdjacentToEnd =
          (Math.abs(last.row - emptyRow) === 1 && last.col === emptyCol) ||
          (Math.abs(last.col - emptyCol) === 1 && last.row === emptyRow);

        if (isAdjacentToEnd) {
          grid[emptyRow][emptyCol] = colorIdx;
          path.push({ row: emptyRow, col: emptyCol });

          if (this.fillGridBacktrack(grid, paths, size, numColors)) {
            return true;
          }

          grid[emptyRow][emptyCol] = -1;
          path.pop();
        }
      }
    }

    return false;
  }

  private shuffledRange(n: number): number[] {
    const arr = Array.from({ length: n }, (_, i) => i);
    for (let i = arr.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [arr[i], arr[j]] = [arr[j], arr[i]];
    }
    return arr;
  }

  private generateSnakePuzzle(
    size: number,
    colors: string[],
  ): {
    endpoints: Array<{ color: string; row: number; col: number }>;
    paths: Record<string, Array<{ row: number; col: number }>>;
  } {
    // Create a snake pattern that fills the entire grid
    const allCells: Array<{ row: number; col: number }> = [];
    for (let r = 0; r < size; r++) {
      if (r % 2 === 0) {
        for (let c = 0; c < size; c++) {
          allCells.push({ row: r, col: c });
        }
      } else {
        for (let c = size - 1; c >= 0; c--) {
          allCells.push({ row: r, col: c });
        }
      }
    }

    // Divide snake into color segments
    const endpoints: Array<{ color: string; row: number; col: number }> = [];
    const paths: Record<string, Array<{ row: number; col: number }>> = {};
    const cellsPerColor = Math.floor(allCells.length / colors.length);

    let idx = 0;
    for (let i = 0; i < colors.length; i++) {
      const isLast = i === colors.length - 1;
      const segmentLength = isLast ? allCells.length - idx : cellsPerColor;
      const path = allCells.slice(idx, idx + segmentLength);

      // Require at least 3 cells per path so endpoints aren't adjacent (trivial puzzle)
      if (path.length >= 3) {
        paths[colors[i]] = path;
        endpoints.push({ color: colors[i], ...path[0] });
        endpoints.push({ color: colors[i], ...path[path.length - 1] });
      }

      idx += segmentLength;
    }

    return { endpoints, paths };
  }
}

// Lights Out Generator
export class LightsOutGenerator {
  generate(difficulty: "easy" | "medium" | "hard" | "expert"): {
    puzzleData: {
      rows: number;
      cols: number;
      initialState: boolean[][];
    };
    solution: {
      moves: Array<{ row: number; col: number }>;
      minMoves: number;
    };
  } {
    const config = {
      easy: { size: 3, minLights: 3, maxLights: 4 },
      medium: { size: 4, minLights: 5, maxLights: 7 },
      hard: { size: 5, minLights: 8, maxLights: 12 },
      expert: { size: 5, minLights: 12, maxLights: 16 },
    }[difficulty];

    // Generate by working backwards from solved state
    const result = this.generateSolvablePuzzle(
      config.size,
      config.minLights,
      config.maxLights,
    );

    return {
      puzzleData: {
        rows: config.size,
        cols: config.size,
        initialState: result.initialState,
      },
      solution: {
        moves: result.moves,
        minMoves: result.moves.length,
      },
    };
  }

  private generateSolvablePuzzle(
    size: number,
    minLights: number,
    maxLights: number,
  ): {
    initialState: boolean[][];
    moves: Array<{ row: number; col: number }>;
  } {
    // Start with all lights off
    const state: boolean[][] = Array(size)
      .fill(null)
      .map(() => Array(size).fill(false));
    const moves: Array<{ row: number; col: number }> = [];

    // Randomly toggle cells to create the puzzle
    // These toggles become the solution
    const numToggles =
      minLights + Math.floor(Math.random() * (maxLights - minLights + 1));
    const usedPositions = new Set<string>();

    for (let i = 0; i < numToggles; i++) {
      let row: number, col: number;
      let attempts = 0;

      do {
        row = Math.floor(Math.random() * size);
        col = Math.floor(Math.random() * size);
        attempts++;
      } while (usedPositions.has(`${row},${col}`) && attempts < 50);

      if (!usedPositions.has(`${row},${col}`)) {
        usedPositions.add(`${row},${col}`);
        this.toggle(state, row, col);
        moves.push({ row, col });
      }
    }

    // Count lit cells - if none, retry
    const litCount = state.flat().filter((v) => v).length;
    if (litCount === 0) {
      return this.generateSolvablePuzzle(size, minLights, maxLights);
    }

    return { initialState: state, moves };
  }

  private toggle(state: boolean[][], row: number, col: number): void {
    const size = state.length;
    const directions = [
      [0, 0],
      [0, 1],
      [1, 0],
      [0, -1],
      [-1, 0],
    ];

    for (const [dr, dc] of directions) {
      const nr = row + dr;
      const nc = col + dc;
      if (nr >= 0 && nr < size && nc >= 0 && nc < size) {
        state[nr][nc] = !state[nr][nc];
      }
    }
  }
}

// Word Ladder Generator
export class WordLadderGenerator {
  // Common 3-4-5 letter words for word ladder puzzles
  private static readonly WORD_LISTS: Record<number, string[]> = {
    3: [
      "CAT",
      "BAT",
      "HAT",
      "RAT",
      "SAT",
      "COT",
      "COW",
      "BOW",
      "ROW",
      "TOW",
      "DOG",
      "LOG",
      "FOG",
      "HOG",
      "JOG",
      "BOG",
      "PIG",
      "BIG",
      "DIG",
      "FIG",
      "CAN",
      "MAN",
      "TAN",
      "PAN",
      "RAN",
      "BAN",
      "FAN",
      "VAN",
      "WAR",
      "CAR",
      "BAR",
      "FAR",
      "JAR",
      "TAR",
      "BED",
      "RED",
      "LED",
      "WED",
      "FED",
      "PEN",
      "TEN",
      "HEN",
      "MEN",
      "DEN",
      "BIN",
      "PIN",
      "TIN",
      "WIN",
      "SIN",
      "FIN",
    ],
    4: [
      "COLD",
      "CORD",
      "CARD",
      "WARD",
      "WARM",
      "WORM",
      "WORD",
      "WORK",
      "FORK",
      "FORM",
      "FARM",
      "HARM",
      "HARD",
      "HAND",
      "LAND",
      "LANE",
      "LATE",
      "GATE",
      "GAME",
      "CAME",
      "CASE",
      "CAVE",
      "HAVE",
      "HATE",
      "HARE",
      "CARE",
      "CORE",
      "BORE",
      "BONE",
      "CONE",
      "TONE",
      "TUNE",
      "DUNE",
      "DONE",
      "GONE",
      "LONE",
      "LOVE",
      "LIVE",
      "GIVE",
      "GAVE",
      "SAVE",
      "SAFE",
      "SAGE",
      "PAGE",
      "PALE",
      "TALE",
      "TALL",
      "BALL",
      "BELL",
      "BELT",
      "BEST",
      "REST",
      "RUST",
      "JUST",
      "MUST",
      "MIST",
      "LIST",
      "LOST",
      "COST",
      "COAT",
      "BOAT",
      "BEAT",
      "HEAT",
    ],
    5: [
      "STONE",
      "STORE",
      "STARE",
      "SPARE",
      "SPACE",
      "PLACE",
      "PLANE",
      "PLATE",
      "SLATE",
      "SKATE",
      "STATE",
      "STAGE",
      "STAKE",
      "SNAKE",
      "SHAKE",
      "SHADE",
      "SHARE",
      "SHORE",
      "SHORT",
      "SHIRT",
      "SHIFT",
      "SHAFT",
      "SHALT",
      "SHALL",
      "SMALL",
      "SMELL",
      "SPELL",
      "SWELL",
      "DWELL",
      "DWELT",
      "DEALT",
      "DELTA",
      "WORLD",
      "WOULD",
      "COULD",
      "CLOUD",
      "CLOUT",
      "CLOTH",
      "CLOSE",
      "CHOSE",
      "CHASE",
      "CHANT",
      "CHART",
      "CHARM",
      "CHAIN",
      "CHAIR",
      "CHEER",
      "CLEAR",
      "CLEAN",
      "CREAM",
      "DREAM",
      "DREAD",
      "BREAD",
      "BREAK",
      "BLEAK",
      "BLANK",
    ],
  };

  generate(difficulty: "easy" | "medium" | "hard" | "expert"): {
    puzzleData: {
      startWord: string;
      targetWord: string;
      wordLength: number;
    };
    solution: {
      path: string[];
      minSteps: number;
    };
  } {
    const config = {
      easy: { lengths: [3, 4], minSteps: 3, maxSteps: 4 },
      medium: { lengths: [4], minSteps: 5, maxSteps: 6 },
      hard: { lengths: [4, 5], minSteps: 7, maxSteps: 8 },
      expert: { lengths: [5], minSteps: 9, maxSteps: 12 },
    }[difficulty];

    const wordLength =
      config.lengths[Math.floor(Math.random() * config.lengths.length)];
    const words =
      WordLadderGenerator.WORD_LISTS[wordLength] ||
      WordLadderGenerator.WORD_LISTS[4];

    // Find a valid word pair with a path
    let result = this.findValidPuzzle(words, config.minSteps, config.maxSteps);
    let attempts = 0;

    while (!result && attempts < 50) {
      result = this.findValidPuzzle(words, config.minSteps, config.maxSteps);
      attempts++;
    }

    if (!result) {
      // Fallback
      result = {
        startWord: "COLD",
        targetWord: "WARM",
        path: ["COLD", "CORD", "CARD", "WARD", "WARM"],
      };
    }

    return {
      puzzleData: {
        startWord: result.startWord,
        targetWord: result.targetWord,
        wordLength: result.startWord.length,
      },
      solution: {
        path: result.path,
        minSteps: result.path.length - 1,
      },
    };
  }

  private findValidPuzzle(
    words: string[],
    minSteps: number,
    maxSteps: number,
  ): { startWord: string; targetWord: string; path: string[] } | null {
    // Pick random start word
    const startWord = words[Math.floor(Math.random() * words.length)];

    // BFS to find all reachable words with distances
    const distances = new Map<string, number>();
    const parents = new Map<string, string>();
    const queue: string[] = [startWord];
    distances.set(startWord, 0);

    while (queue.length > 0) {
      const current = queue.shift()!;
      const dist = distances.get(current)!;

      if (dist >= maxSteps) continue;

      for (const next of this.getNeighbors(current, words)) {
        if (!distances.has(next)) {
          distances.set(next, dist + 1);
          parents.set(next, current);
          queue.push(next);
        }
      }
    }

    // Find words at target distance
    const candidates = words.filter((w) => {
      const d = distances.get(w);
      return d !== undefined && d >= minSteps && d <= maxSteps;
    });

    if (candidates.length === 0) return null;

    const targetWord =
      candidates[Math.floor(Math.random() * candidates.length)];

    // Reconstruct path
    const path: string[] = [targetWord];
    let current = targetWord;
    while (parents.has(current)) {
      current = parents.get(current)!;
      path.unshift(current);
    }

    return { startWord, targetWord, path };
  }

  private getNeighbors(word: string, wordList: string[]): string[] {
    return wordList.filter((w) => {
      if (w === word || w.length !== word.length) return false;
      let diff = 0;
      for (let i = 0; i < word.length; i++) {
        if (word[i] !== w[i]) diff++;
        if (diff > 1) return false;
      }
      return diff === 1;
    });
  }

  /**
   * Generate a word ladder with specific step requirements
   * Used by the preview endpoint for custom difficulty generation
   */
  generateWithSteps(
    wordLength: number,
    minSteps: number,
    maxSteps: number,
  ): { startWord: string; targetWord: string; path: string[] } | null {
    const words =
      WordLadderGenerator.WORD_LISTS[wordLength] ||
      WordLadderGenerator.WORD_LISTS[4];

    // Try multiple times to find a valid puzzle
    let result = this.findValidPuzzle(words, minSteps, maxSteps);
    let attempts = 0;

    while (!result && attempts < 100) {
      result = this.findValidPuzzle(words, minSteps, maxSteps);
      attempts++;
    }

    return result;
  }
}

// Connections Generator
export class ConnectionsGenerator {
  // Pre-built category database
  private static readonly CATEGORIES: Array<{
    name: string;
    words: string[];
    difficulty: 1 | 2 | 3 | 4;
  }> = [
    // Difficulty 1 (Yellow - Easy)
    {
      name: "Primary Colors",
      words: ["RED", "BLUE", "YELLOW", "GREEN"],
      difficulty: 1,
    },
    {
      name: "Fruits",
      words: ["APPLE", "BANANA", "ORANGE", "GRAPE"],
      difficulty: 1,
    },
    {
      name: "Planets",
      words: ["MARS", "VENUS", "EARTH", "SATURN"],
      difficulty: 1,
    },
    {
      name: "Seasons",
      words: ["SPRING", "SUMMER", "FALL", "WINTER"],
      difficulty: 1,
    },
    {
      name: "Card Suits",
      words: ["HEARTS", "CLUBS", "SPADES", "DIAMONDS"],
      difficulty: 1,
    },
    {
      name: "Directions",
      words: ["NORTH", "SOUTH", "EAST", "WEST"],
      difficulty: 1,
    },
    {
      name: "Body Parts",
      words: ["HAND", "FOOT", "HEAD", "ARM"],
      difficulty: 1,
    },

    // Difficulty 2 (Green - Medium)
    {
      name: "Types of Bread",
      words: ["RYE", "WHEAT", "SOURDOUGH", "BRIOCHE"],
      difficulty: 2,
    },
    {
      name: "Shades of Blue",
      words: ["NAVY", "TEAL", "AZURE", "COBALT"],
      difficulty: 2,
    },
    {
      name: "Greek Letters",
      words: ["ALPHA", "BETA", "GAMMA", "DELTA"],
      difficulty: 2,
    },
    {
      name: "Chess Pieces",
      words: ["KING", "QUEEN", "ROOK", "KNIGHT"],
      difficulty: 2,
    },
    {
      name: "Musical Instruments",
      words: ["PIANO", "GUITAR", "DRUMS", "VIOLIN"],
      difficulty: 2,
    },
    {
      name: "Dog Breeds",
      words: ["POODLE", "BEAGLE", "BOXER", "HUSKY"],
      difficulty: 2,
    },
    { name: "Trees", words: ["OAK", "MAPLE", "PINE", "BIRCH"], difficulty: 2 },

    // Difficulty 3 (Blue - Hard)
    {
      name: "_____ King",
      words: ["LION", "BURGER", "STEPHEN", "KONG"],
      difficulty: 3,
    },
    {
      name: 'Words Before "HOUSE"',
      words: ["WHITE", "GREEN", "POWER", "TREE"],
      difficulty: 3,
    },
    {
      name: "Double Letters",
      words: ["BALLOON", "COFFEE", "LETTER", "BUTTER"],
      difficulty: 3,
    },
    {
      name: "Things That Are Round",
      words: ["BALL", "MOON", "WHEEL", "COIN"],
      difficulty: 3,
    },
    {
      name: "Poker Terms",
      words: ["FOLD", "CALL", "RAISE", "CHECK"],
      difficulty: 3,
    },
    {
      name: "Units of Time",
      words: ["MINUTE", "SECOND", "HOUR", "DECADE"],
      difficulty: 3,
    },

    // Difficulty 4 (Purple - Tricky)
    {
      name: "Homophones of Numbers",
      words: ["WON", "TOO", "ATE", "FOR"],
      difficulty: 4,
    },
    {
      name: 'Anagrams of "LISTEN"',
      words: ["SILENT", "TINSEL", "ENLIST", "INLETS"],
      difficulty: 4,
    },
    {
      name: "Words That Sound Like Letters",
      words: ["BEE", "SEA", "JAY", "TEA"],
      difficulty: 4,
    },
    {
      name: "Hidden Body Parts",
      words: ["FARM", "BELOW", "FENCING", "SEARCH"],
      difficulty: 4,
    }, // ARM, ELBOW, CHIN, EAR
    {
      name: "Famous _____s",
      words: ["JACKSON", "JORDAN", "JAMES", "JOHNSON"],
      difficulty: 4,
    },
  ];

  generate(difficulty: "easy" | "medium" | "hard" | "expert"): {
    puzzleData: {
      words: string[];
      categories: Array<{ name: string; words: string[]; difficulty: number }>;
    };
    solution: {
      categories: Array<{ name: string; words: string[]; difficulty: number }>;
    };
  } {
    // Select categories - always use unique difficulties (1, 2, 3, 4) to ensure unique colors
    // Each solved category gets its own color (Yellow, Green, Blue, Purple)
    const config = {
      easy: { difficulties: [1, 2, 3, 4] },
      medium: { difficulties: [1, 2, 3, 4] },
      hard: { difficulties: [1, 2, 3, 4] },
      expert: { difficulties: [1, 2, 3, 4] },
    }[difficulty];

    const selectedCategories: Array<{
      name: string;
      words: string[];
      difficulty: number;
    }> = [];
    const usedWords = new Set<string>();
    const usedCategories = new Set<string>();

    for (const targetDiff of config.difficulties) {
      const candidates = ConnectionsGenerator.CATEGORIES.filter(
        (c) =>
          c.difficulty === targetDiff &&
          !usedCategories.has(c.name) &&
          !c.words.some((w) => usedWords.has(w)),
      );

      if (candidates.length > 0) {
        const selected =
          candidates[Math.floor(Math.random() * candidates.length)];
        selectedCategories.push({
          name: selected.name,
          words: [...selected.words],
          difficulty: selected.difficulty,
        });
        usedCategories.add(selected.name);
        selected.words.forEach((w) => usedWords.add(w));
      }
    }

    // If we couldn't get 4 categories, fill with any available
    while (selectedCategories.length < 4) {
      const candidates = ConnectionsGenerator.CATEGORIES.filter(
        (c) =>
          !usedCategories.has(c.name) && !c.words.some((w) => usedWords.has(w)),
      );

      if (candidates.length === 0) break;

      const selected =
        candidates[Math.floor(Math.random() * candidates.length)];
      selectedCategories.push({
        name: selected.name,
        words: [...selected.words],
        difficulty: selected.difficulty,
      });
      usedCategories.add(selected.name);
      selected.words.forEach((w) => usedWords.add(w));
    }

    // IMPORTANT: Ensure each category has a unique difficulty (1-4) for unique colors
    // This prevents duplicate colors when fallback selects categories with same base difficulty
    const usedDifficulties = new Set<number>();
    for (const category of selectedCategories) {
      if (usedDifficulties.has(category.difficulty)) {
        // Find an unused difficulty level
        for (let d = 1; d <= 4; d++) {
          if (!usedDifficulties.has(d)) {
            category.difficulty = d;
            break;
          }
        }
      }
      usedDifficulties.add(category.difficulty);
    }

    // Collect all words and shuffle
    const allWords = selectedCategories.flatMap((c) => c.words);
    this.shuffleArray(allWords);

    // Sort categories by difficulty for display
    selectedCategories.sort((a, b) => a.difficulty - b.difficulty);

    return {
      puzzleData: {
        words: allWords,
        categories: selectedCategories,
      },
      solution: {
        categories: selectedCategories,
      },
    };
  }

  private shuffleArray<T>(array: T[]): void {
    for (let i = array.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [array[i], array[j]] = [array[j], array[i]];
    }
  }
}

// Export convenience functions for new games
export const generatePipes = (
  difficulty: "easy" | "medium" | "hard" | "expert",
) => {
  const generator = new PipesGenerator();
  return generator.generate(difficulty);
};

export const generateLightsOut = (
  difficulty: "easy" | "medium" | "hard" | "expert",
) => {
  const generator = new LightsOutGenerator();
  return generator.generate(difficulty);
};

export const generateWordLadder = (
  difficulty: "easy" | "medium" | "hard" | "expert",
) => {
  const generator = new WordLadderGenerator();
  return generator.generate(difficulty);
};

export const generateConnections = (
  difficulty: "easy" | "medium" | "hard" | "expert",
) => {
  const generator = new ConnectionsGenerator();
  return generator.generate(difficulty);
};

// ============================================
// MATHORA GENERATOR
// ============================================

interface MathoraOperation {
  type: "add" | "subtract" | "multiply" | "divide";
  value: number;
  display: string;
}

interface MathoraPuzzle {
  puzzleData: {
    startNumber: number;
    targetNumber: number;
    moves: number;
    operations: MathoraOperation[];
  };
  solution: {
    steps: MathoraOperation[];
  };
}

export class MathoraGenerator {
  private readonly ADD_VALUES = [5, 10, 15, 20, 25, 30, 40, 50, 75, 100];
  private readonly SUBTRACT_VALUES = [5, 10, 15, 20, 25];
  private readonly MULTIPLY_VALUES = [2, 3, 4, 5, 6, 8, 10];
  private readonly DIVIDE_VALUES = [2, 3, 4, 5];

  generate(difficulty: "easy" | "medium" | "hard" | "expert"): MathoraPuzzle {
    const config = this.getDifficultyConfig(difficulty);

    // Generate a solvable puzzle by working backwards from target
    let attempts = 0;
    const maxAttempts = 100;

    while (attempts < maxAttempts) {
      attempts++;
      const puzzle = this.tryGeneratePuzzle(config);
      if (puzzle) {
        return puzzle;
      }
    }

    // Fallback: generate a simple puzzle
    return this.generateFallbackPuzzle(config);
  }

  private getDifficultyConfig(difficulty: string): {
    moves: number;
    operationCount: number;
    targetRange: { min: number; max: number };
    startRange: { min: number; max: number };
  } {
    switch (difficulty) {
      case "easy":
        return {
          moves: 3,
          operationCount: 12,
          targetRange: { min: 50, max: 200 },
          startRange: { min: 2, max: 20 },
        };
      case "medium":
        return {
          moves: 4,
          operationCount: 15,
          targetRange: { min: 100, max: 500 },
          startRange: { min: 5, max: 30 },
        };
      case "hard":
        return {
          moves: 5,
          operationCount: 16,
          targetRange: { min: 200, max: 1000 },
          startRange: { min: 3, max: 25 },
        };
      case "expert":
        return {
          moves: 6,
          operationCount: 18,
          targetRange: { min: 500, max: 2000 },
          startRange: { min: 2, max: 20 },
        };
      default:
        return {
          moves: 3,
          operationCount: 12,
          targetRange: { min: 50, max: 200 },
          startRange: { min: 2, max: 20 },
        };
    }
  }

  private tryGeneratePuzzle(config: {
    moves: number;
    operationCount: number;
    targetRange: { min: number; max: number };
    startRange: { min: number; max: number };
  }): MathoraPuzzle | null {
    // Generate starting number
    const startNumber =
      Math.floor(
        Math.random() * (config.startRange.max - config.startRange.min + 1),
      ) + config.startRange.min;

    // Generate solution operations (working forward)
    const solutionOps: MathoraOperation[] = [];
    let currentValue = startNumber;

    for (let i = 0; i < config.moves; i++) {
      const op = this.generateValidOperation(
        currentValue,
        i === config.moves - 1,
        config.targetRange,
      );
      if (!op) return null;
      solutionOps.push(op);
      currentValue = this.applyOperation(currentValue, op);
    }

    // Check if target is in valid range
    if (
      currentValue < config.targetRange.min ||
      currentValue > config.targetRange.max
    ) {
      return null;
    }

    // Ensure target is a nice round number
    if (currentValue % 5 !== 0) {
      return null;
    }

    const targetNumber = currentValue;

    // Generate distractor operations (operations that won't help or are red herrings)
    const allOperations = [...solutionOps];
    const distractorCount = config.operationCount - config.moves;

    for (let i = 0; i < distractorCount; i++) {
      const distractor = this.generateDistractorOperation(solutionOps);
      if (distractor && !this.operationExists(allOperations, distractor)) {
        allOperations.push(distractor);
      }
    }

    // Fill remaining slots if needed
    while (allOperations.length < config.operationCount) {
      const filler = this.generateRandomOperation();
      if (!this.operationExists(allOperations, filler)) {
        allOperations.push(filler);
      }
    }

    // Shuffle operations
    this.shuffleArray(allOperations);

    return {
      puzzleData: {
        startNumber,
        targetNumber,
        moves: config.moves,
        operations: allOperations,
      },
      solution: {
        steps: solutionOps,
      },
    };
  }

  private generateValidOperation(
    currentValue: number,
    isLast: boolean,
    targetRange: { min: number; max: number },
  ): MathoraOperation | null {
    const possibleOps: MathoraOperation[] = [];

    // Add operations
    for (const value of this.ADD_VALUES) {
      const result = currentValue + value;
      if (result <= targetRange.max * 2) {
        possibleOps.push({ type: "add", value, display: `+${value}` });
      }
    }

    // Subtract operations (don't go below 1)
    for (const value of this.SUBTRACT_VALUES) {
      const result = currentValue - value;
      if (result >= 1) {
        possibleOps.push({ type: "subtract", value, display: `-${value}` });
      }
    }

    // Multiply operations
    for (const value of this.MULTIPLY_VALUES) {
      const result = currentValue * value;
      if (result <= targetRange.max * 2) {
        possibleOps.push({ type: "multiply", value, display: `×${value}` });
      }
    }

    // Divide operations (only if result is whole number)
    for (const value of this.DIVIDE_VALUES) {
      if (currentValue % value === 0 && currentValue / value >= 1) {
        possibleOps.push({ type: "divide", value, display: `÷${value}` });
      }
    }

    if (possibleOps.length === 0) return null;
    return possibleOps[Math.floor(Math.random() * possibleOps.length)];
  }

  private generateDistractorOperation(
    _solutionOps: MathoraOperation[],
  ): MathoraOperation | null {
    const type = ["add", "subtract", "multiply", "divide"][
      Math.floor(Math.random() * 4)
    ] as "add" | "subtract" | "multiply" | "divide";

    let value: number;
    let display: string;

    switch (type) {
      case "add":
        value =
          this.ADD_VALUES[Math.floor(Math.random() * this.ADD_VALUES.length)];
        display = `+${value}`;
        break;
      case "subtract":
        value =
          this.SUBTRACT_VALUES[
            Math.floor(Math.random() * this.SUBTRACT_VALUES.length)
          ];
        display = `-${value}`;
        break;
      case "multiply":
        value =
          this.MULTIPLY_VALUES[
            Math.floor(Math.random() * this.MULTIPLY_VALUES.length)
          ];
        display = `×${value}`;
        break;
      case "divide":
        value =
          this.DIVIDE_VALUES[
            Math.floor(Math.random() * this.DIVIDE_VALUES.length)
          ];
        display = `÷${value}`;
        break;
    }

    return { type, value, display };
  }

  private generateRandomOperation(): MathoraOperation {
    const type = ["add", "subtract", "multiply", "divide"][
      Math.floor(Math.random() * 4)
    ] as "add" | "subtract" | "multiply" | "divide";

    let value: number;
    let display: string;

    switch (type) {
      case "add":
        value =
          this.ADD_VALUES[Math.floor(Math.random() * this.ADD_VALUES.length)];
        display = `+${value}`;
        break;
      case "subtract":
        value =
          this.SUBTRACT_VALUES[
            Math.floor(Math.random() * this.SUBTRACT_VALUES.length)
          ];
        display = `-${value}`;
        break;
      case "multiply":
        value =
          this.MULTIPLY_VALUES[
            Math.floor(Math.random() * this.MULTIPLY_VALUES.length)
          ];
        display = `×${value}`;
        break;
      case "divide":
        value =
          this.DIVIDE_VALUES[
            Math.floor(Math.random() * this.DIVIDE_VALUES.length)
          ];
        display = `÷${value}`;
        break;
    }

    return { type, value, display };
  }

  private operationExists(
    ops: MathoraOperation[],
    op: MathoraOperation,
  ): boolean {
    return ops.some((o) => o.type === op.type && o.value === op.value);
  }

  private applyOperation(value: number, op: MathoraOperation): number {
    switch (op.type) {
      case "add":
        return value + op.value;
      case "subtract":
        return value - op.value;
      case "multiply":
        return value * op.value;
      case "divide":
        return value / op.value;
    }
  }

  private generateFallbackPuzzle(config: {
    moves: number;
    operationCount: number;
    targetRange: { min: number; max: number };
    startRange: { min: number; max: number };
  }): MathoraPuzzle {
    // Simple fallback: 10 * 10 + 50 = 150 (3 moves)
    const startNumber = 10;
    const targetNumber = 150;
    const solutionOps: MathoraOperation[] = [
      { type: "multiply", value: 10, display: "×10" },
      { type: "add", value: 50, display: "+50" },
    ];

    if (config.moves >= 3) {
      solutionOps.push({ type: "add", value: 0, display: "+0" });
    }

    const allOperations: MathoraOperation[] = [
      { type: "add", value: 50, display: "+50" },
      { type: "add", value: 25, display: "+25" },
      { type: "add", value: 75, display: "+75" },
      { type: "multiply", value: 6, display: "×6" },
      { type: "add", value: 20, display: "+20" },
      { type: "multiply", value: 10, display: "×10" },
      { type: "multiply", value: 2, display: "×2" },
      { type: "multiply", value: 3, display: "×3" },
      { type: "multiply", value: 4, display: "×4" },
      { type: "multiply", value: 5, display: "×5" },
      { type: "subtract", value: 5, display: "-5" },
      { type: "divide", value: 2, display: "÷2" },
    ];

    return {
      puzzleData: {
        startNumber,
        targetNumber,
        moves: config.moves,
        operations: allOperations.slice(0, config.operationCount),
      },
      solution: {
        steps: solutionOps,
      },
    };
  }

  private shuffleArray<T>(array: T[]): void {
    for (let i = array.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [array[i], array[j]] = [array[j], array[i]];
    }
  }
}

export const generateMathora = (
  difficulty: "easy" | "medium" | "hard" | "expert",
) => {
  const generator = new MathoraGenerator();
  return generator.generate(difficulty);
};
