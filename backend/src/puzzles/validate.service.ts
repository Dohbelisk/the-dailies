import { Injectable } from "@nestjs/common";
import { DictionaryService } from "../dictionary/dictionary.service";

export interface ValidationError {
  row: number;
  col: number;
  message: string;
}

export interface SudokuValidationResult {
  isValid: boolean;
  errors: ValidationError[];
  hasUniqueSolution: boolean;
  solution?: number[][];
}

export interface SudokuSolveResult {
  success: boolean;
  solution?: number[][];
  error?: string;
}

export interface Cage {
  sum: number;
  cells: [number, number][];
}

export interface KillerSudokuValidationResult {
  isValid: boolean;
  errors: ValidationError[];
  hasUniqueSolution: boolean;
  solution?: number[][];
}

export interface KillerSudokuSolveResult {
  success: boolean;
  solution?: number[][];
  error?: string;
}

// Word Ladder interfaces
export interface WordLadderValidationResult {
  isValid: boolean;
  errors: ValidationError[];
  path?: string[];
  minSteps?: number;
}

// Number Target interfaces
export interface NumberTargetValidationResult {
  isValid: boolean;
  errors: ValidationError[];
  targetSolutions?: {
    target: number;
    expression: string;
    reachable: boolean;
  }[];
}

// Word Forge interfaces
export interface WordForgeValidationResult {
  isValid: boolean;
  errors: ValidationError[];
  allWords?: string[];
  pangrams?: string[];
  maxScore?: number;
}

@Injectable()
export class ValidateService {
  constructor(private readonly dictionaryService: DictionaryService) {}
  /**
   * Validates a Sudoku puzzle and optionally returns its solution
   */
  validateSudoku(grid: number[][]): SudokuValidationResult {
    const errors: ValidationError[] = [];

    // Check grid dimensions
    if (!grid || grid.length !== 9) {
      return {
        isValid: false,
        errors: [{ row: -1, col: -1, message: "Grid must be 9x9" }],
        hasUniqueSolution: false,
      };
    }

    for (let i = 0; i < 9; i++) {
      if (!grid[i] || grid[i].length !== 9) {
        return {
          isValid: false,
          errors: [
            { row: i, col: -1, message: `Row ${i + 1} must have 9 cells` },
          ],
          hasUniqueSolution: false,
        };
      }
    }

    // Check for invalid values
    for (let row = 0; row < 9; row++) {
      for (let col = 0; col < 9; col++) {
        const val = grid[row][col];
        if (val !== 0 && (val < 1 || val > 9 || !Number.isInteger(val))) {
          errors.push({
            row,
            col,
            message: `Invalid value ${val} at row ${row + 1}, column ${col + 1}`,
          });
        }
      }
    }

    if (errors.length > 0) {
      return { isValid: false, errors, hasUniqueSolution: false };
    }

    // Check for constraint violations in initial grid
    const constraintErrors = this.checkConstraints(grid);
    if (constraintErrors.length > 0) {
      return {
        isValid: false,
        errors: constraintErrors,
        hasUniqueSolution: false,
      };
    }

    // Try to solve and check for unique solution
    const solveResult = this.solveSudoku(grid);

    if (!solveResult.success) {
      return {
        isValid: false,
        errors: [{ row: -1, col: -1, message: "Puzzle has no solution" }],
        hasUniqueSolution: false,
      };
    }

    // Check for unique solution
    const hasUnique = this.hasUniqueSolution(grid);

    return {
      isValid: true,
      errors: [],
      hasUniqueSolution: hasUnique,
      solution: solveResult.solution,
    };
  }

  /**
   * Solves a Sudoku puzzle
   */
  solveSudoku(grid: number[][]): SudokuSolveResult {
    // Make a deep copy
    const workingGrid = grid.map((row) => [...row]);

    if (this.solve(workingGrid)) {
      return { success: true, solution: workingGrid };
    }

    return { success: false, error: "No solution exists for this puzzle" };
  }

  /**
   * Backtracking solver
   */
  private solve(grid: number[][]): boolean {
    const emptyCell = this.findEmptyCell(grid);
    if (!emptyCell) return true; // Puzzle is solved

    const [row, col] = emptyCell;

    for (let num = 1; num <= 9; num++) {
      if (this.isValidPlacement(grid, row, col, num)) {
        grid[row][col] = num;
        if (this.solve(grid)) return true;
        grid[row][col] = 0;
      }
    }

    return false;
  }

  /**
   * Find first empty cell (value 0)
   */
  private findEmptyCell(grid: number[][]): [number, number] | null {
    for (let row = 0; row < 9; row++) {
      for (let col = 0; col < 9; col++) {
        if (grid[row][col] === 0) return [row, col];
      }
    }
    return null;
  }

  /**
   * Check if placing num at (row, col) is valid
   */
  private isValidPlacement(
    grid: number[][],
    row: number,
    col: number,
    num: number,
  ): boolean {
    // Check row
    if (grid[row].includes(num)) return false;

    // Check column
    for (let i = 0; i < 9; i++) {
      if (grid[i][col] === num) return false;
    }

    // Check 3x3 box
    const boxRow = Math.floor(row / 3) * 3;
    const boxCol = Math.floor(col / 3) * 3;
    for (let i = boxRow; i < boxRow + 3; i++) {
      for (let j = boxCol; j < boxCol + 3; j++) {
        if (grid[i][j] === num) return false;
      }
    }

    return true;
  }

  /**
   * Check for constraint violations in the initial grid
   */
  private checkConstraints(grid: number[][]): ValidationError[] {
    const errors: ValidationError[] = [];

    // Check rows
    for (let row = 0; row < 9; row++) {
      const seen = new Map<number, number>();
      for (let col = 0; col < 9; col++) {
        const val = grid[row][col];
        if (val !== 0) {
          if (seen.has(val)) {
            errors.push({
              row,
              col,
              message: `Duplicate ${val} in row ${row + 1}`,
            });
          }
          seen.set(val, col);
        }
      }
    }

    // Check columns
    for (let col = 0; col < 9; col++) {
      const seen = new Map<number, number>();
      for (let row = 0; row < 9; row++) {
        const val = grid[row][col];
        if (val !== 0) {
          if (seen.has(val)) {
            errors.push({
              row,
              col,
              message: `Duplicate ${val} in column ${col + 1}`,
            });
          }
          seen.set(val, row);
        }
      }
    }

    // Check 3x3 boxes
    for (let boxRow = 0; boxRow < 3; boxRow++) {
      for (let boxCol = 0; boxCol < 3; boxCol++) {
        const seen = new Map<number, [number, number]>();
        for (let i = 0; i < 3; i++) {
          for (let j = 0; j < 3; j++) {
            const row = boxRow * 3 + i;
            const col = boxCol * 3 + j;
            const val = grid[row][col];
            if (val !== 0) {
              if (seen.has(val)) {
                errors.push({
                  row,
                  col,
                  message: `Duplicate ${val} in 3x3 box`,
                });
              }
              seen.set(val, [row, col]);
            }
          }
        }
      }
    }

    return errors;
  }

  /**
   * Check if the puzzle has exactly one solution
   */
  private hasUniqueSolution(grid: number[][]): boolean {
    const workingGrid = grid.map((row) => [...row]);
    let solutionCount = 0;

    const countSolutions = (g: number[][]): void => {
      if (solutionCount > 1) return; // Early exit if multiple solutions found

      const emptyCell = this.findEmptyCell(g);
      if (!emptyCell) {
        solutionCount++;
        return;
      }

      const [row, col] = emptyCell;

      for (let num = 1; num <= 9; num++) {
        if (this.isValidPlacement(g, row, col, num)) {
          g[row][col] = num;
          countSolutions(g);
          if (solutionCount > 1) return;
          g[row][col] = 0;
        }
      }
    };

    countSolutions(workingGrid);
    return solutionCount === 1;
  }

  // ============================================
  // Killer Sudoku Methods
  // ============================================

  /**
   * Validates a Killer Sudoku puzzle
   */
  validateKillerSudoku(cages: Cage[]): KillerSudokuValidationResult {
    const errors: ValidationError[] = [];

    // Validate cages exist
    if (!cages || cages.length === 0) {
      return {
        isValid: false,
        errors: [
          { row: -1, col: -1, message: "At least one cage is required" },
        ],
        hasUniqueSolution: false,
      };
    }

    // Check all cells are covered exactly once
    const cellCoverage = new Map<string, number>();
    for (let row = 0; row < 9; row++) {
      for (let col = 0; col < 9; col++) {
        cellCoverage.set(`${row},${col}`, 0);
      }
    }

    for (let cageIdx = 0; cageIdx < cages.length; cageIdx++) {
      const cage = cages[cageIdx];

      // Validate cage has cells
      if (!cage.cells || cage.cells.length === 0) {
        errors.push({
          row: -1,
          col: -1,
          message: `Cage ${cageIdx + 1} has no cells`,
        });
        continue;
      }

      // Validate cage sum
      if (!cage.sum || cage.sum < 1) {
        errors.push({
          row: cage.cells[0]?.[0] ?? -1,
          col: cage.cells[0]?.[1] ?? -1,
          message: `Cage ${cageIdx + 1} has invalid sum`,
        });
      }

      // Check cage cells are valid and track coverage
      for (const [row, col] of cage.cells) {
        if (row < 0 || row > 8 || col < 0 || col > 8) {
          errors.push({
            row,
            col,
            message: `Invalid cell position [${row}, ${col}] in cage ${cageIdx + 1}`,
          });
          continue;
        }

        const key = `${row},${col}`;
        cellCoverage.set(key, (cellCoverage.get(key) || 0) + 1);
      }

      // Validate cage cells are contiguous (orthogonally connected)
      if (!this.isCageContiguous(cage.cells)) {
        errors.push({
          row: cage.cells[0]?.[0] ?? -1,
          col: cage.cells[0]?.[1] ?? -1,
          message: `Cage ${cageIdx + 1} cells are not contiguous`,
        });
      }

      // Validate sum is achievable with unique digits
      if (!this.isSumAchievable(cage.sum, cage.cells.length)) {
        errors.push({
          row: cage.cells[0]?.[0] ?? -1,
          col: cage.cells[0]?.[1] ?? -1,
          message: `Cage ${cageIdx + 1}: sum ${cage.sum} is not achievable with ${cage.cells.length} unique digits`,
        });
      }
    }

    // Check for uncovered or multiply-covered cells
    for (const [key, count] of cellCoverage) {
      const [row, col] = key.split(",").map(Number);
      if (count === 0) {
        errors.push({
          row,
          col,
          message: `Cell [${row + 1}, ${col + 1}] is not in any cage`,
        });
      } else if (count > 1) {
        errors.push({
          row,
          col,
          message: `Cell [${row + 1}, ${col + 1}] is in multiple cages`,
        });
      }
    }

    if (errors.length > 0) {
      return { isValid: false, errors, hasUniqueSolution: false };
    }

    // Try to solve
    const solveResult = this.solveKillerSudoku(cages);

    if (!solveResult.success) {
      return {
        isValid: false,
        errors: [{ row: -1, col: -1, message: "Puzzle has no solution" }],
        hasUniqueSolution: false,
      };
    }

    // Check for unique solution
    const hasUnique = this.hasUniqueKillerSolution(cages);

    return {
      isValid: true,
      errors: [],
      hasUniqueSolution: hasUnique,
      solution: solveResult.solution,
    };
  }

  /**
   * Solves a Killer Sudoku puzzle
   */
  solveKillerSudoku(cages: Cage[]): KillerSudokuSolveResult {
    const grid: number[][] = Array(9)
      .fill(null)
      .map(() => Array(9).fill(0));

    if (this.solveKiller(grid, cages)) {
      return { success: true, solution: grid };
    }

    return { success: false, error: "No solution exists for this puzzle" };
  }

  /**
   * Backtracking solver for Killer Sudoku
   */
  private solveKiller(grid: number[][], cages: Cage[]): boolean {
    const emptyCell = this.findEmptyCell(grid);
    if (!emptyCell) return true;

    const [row, col] = emptyCell;

    for (let num = 1; num <= 9; num++) {
      if (this.isValidKillerPlacement(grid, row, col, num, cages)) {
        grid[row][col] = num;
        if (this.solveKiller(grid, cages)) return true;
        grid[row][col] = 0;
      }
    }

    return false;
  }

  /**
   * Check if placing num at (row, col) is valid for Killer Sudoku
   */
  private isValidKillerPlacement(
    grid: number[][],
    row: number,
    col: number,
    num: number,
    cages: Cage[],
  ): boolean {
    // Standard Sudoku checks
    if (!this.isValidPlacement(grid, row, col, num)) {
      return false;
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
    // and must leave room for remaining cells
    if (sum > cage.sum) {
      return false;
    }

    // Check if remaining sum is achievable
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
   * Check if a cage's cells are contiguous (orthogonally connected)
   */
  private isCageContiguous(cells: [number, number][]): boolean {
    if (cells.length <= 1) return true;

    const cellSet = new Set(cells.map(([r, c]) => `${r},${c}`));
    const visited = new Set<string>();
    const queue: [number, number][] = [cells[0]];
    visited.add(`${cells[0][0]},${cells[0][1]}`);

    while (queue.length > 0) {
      const [row, col] = queue.shift()!;
      const neighbors: [number, number][] = [
        [row - 1, col],
        [row + 1, col],
        [row, col - 1],
        [row, col + 1],
      ];

      for (const [nr, nc] of neighbors) {
        const key = `${nr},${nc}`;
        if (cellSet.has(key) && !visited.has(key)) {
          visited.add(key);
          queue.push([nr, nc]);
        }
      }
    }

    return visited.size === cells.length;
  }

  /**
   * Check if a sum is achievable with n unique digits (1-9)
   */
  private isSumAchievable(sum: number, n: number): boolean {
    // Minimum sum with n digits: 1+2+...+n = n*(n+1)/2
    const minSum = (n * (n + 1)) / 2;
    // Maximum sum with n digits: 9+8+...+(10-n) = n*(19-n)/2
    const maxSum = (n * (19 - n)) / 2;
    return sum >= minSum && sum <= maxSum;
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

  /**
   * Check if Killer Sudoku has unique solution
   */
  private hasUniqueKillerSolution(cages: Cage[]): boolean {
    const grid: number[][] = Array(9)
      .fill(null)
      .map(() => Array(9).fill(0));
    let solutionCount = 0;

    const countSolutions = (g: number[][]): void => {
      if (solutionCount > 1) return;

      const emptyCell = this.findEmptyCell(g);
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

    countSolutions(grid);
    return solutionCount === 1;
  }

  // ============================================
  // Word Ladder Methods
  // ============================================

  /**
   * Validates a Word Ladder puzzle and finds the shortest path
   */
  async validateWordLadder(
    startWord: string,
    targetWord: string,
    wordLength: number,
  ): Promise<WordLadderValidationResult> {
    const errors: ValidationError[] = [];
    const start = startWord.toUpperCase().trim();
    const target = targetWord.toUpperCase().trim();

    // Validate input
    if (!start || start.length !== wordLength) {
      errors.push({
        row: -1,
        col: -1,
        message: `Start word must be exactly ${wordLength} letters`,
      });
    }

    if (!target || target.length !== wordLength) {
      errors.push({
        row: -1,
        col: -1,
        message: `Target word must be exactly ${wordLength} letters`,
      });
    }

    if (!/^[A-Z]+$/.test(start)) {
      errors.push({
        row: -1,
        col: -1,
        message: "Start word must contain only letters",
      });
    }

    if (!/^[A-Z]+$/.test(target)) {
      errors.push({
        row: -1,
        col: -1,
        message: "Target word must contain only letters",
      });
    }

    if (errors.length > 0) {
      return { isValid: false, errors };
    }

    // Check if words exist in dictionary
    const [startExists, targetExists] = await Promise.all([
      this.dictionaryService.isValidWord(start),
      this.dictionaryService.isValidWord(target),
    ]);

    if (!startExists) {
      errors.push({
        row: -1,
        col: -1,
        message: `"${start}" is not in the dictionary`,
      });
    }

    if (!targetExists) {
      errors.push({
        row: -1,
        col: -1,
        message: `"${target}" is not in the dictionary`,
      });
    }

    if (errors.length > 0) {
      return { isValid: false, errors };
    }

    // Find shortest path using BFS
    const path = await this.findWordLadderPath(start, target, wordLength);

    if (!path) {
      return {
        isValid: false,
        errors: [
          {
            row: -1,
            col: -1,
            message: `No valid path exists from "${start}" to "${target}"`,
          },
        ],
      };
    }

    return {
      isValid: true,
      errors: [],
      path,
      minSteps: path.length - 1,
    };
  }

  /**
   * BFS to find shortest path between two words
   */
  private async findWordLadderPath(
    start: string,
    target: string,
    wordLength: number,
  ): Promise<string[] | null> {
    if (start === target) return [start];

    // Get all words of the correct length from dictionary
    const allWords = await this.getAllWordsOfLength(wordLength);
    const wordSet = new Set(allWords);

    if (!wordSet.has(start) || !wordSet.has(target)) {
      return null;
    }

    // BFS
    const queue: { word: string; path: string[] }[] = [
      { word: start, path: [start] },
    ];
    const visited = new Set<string>([start]);

    while (queue.length > 0) {
      const { word, path } = queue.shift()!;

      // Try changing each letter
      for (let i = 0; i < word.length; i++) {
        for (let c = 65; c <= 90; c++) {
          // A-Z
          const newChar = String.fromCharCode(c);
          if (newChar === word[i]) continue;

          const newWord = word.slice(0, i) + newChar + word.slice(i + 1);

          if (newWord === target) {
            return [...path, newWord];
          }

          if (wordSet.has(newWord) && !visited.has(newWord)) {
            visited.add(newWord);
            queue.push({ word: newWord, path: [...path, newWord] });
          }
        }
      }
    }

    return null;
  }

  /**
   * Get all words of a specific length from the dictionary
   */
  private async getAllWordsOfLength(length: number): Promise<string[]> {
    // This queries the dictionary for words of the specified length
    const result = await this.dictionaryService.findAll({
      length,
      limit: 100000, // Large limit to get all words
    });
    return result.words.map((w) => w.word);
  }

  // ============================================
  // Number Target Methods
  // ============================================

  /**
   * Validates a Number Target puzzle and finds solutions for each target
   */
  validateNumberTarget(
    numbers: number[],
    targets: { target: number; difficulty: string }[],
  ): NumberTargetValidationResult {
    const errors: ValidationError[] = [];

    // Validate numbers
    if (!numbers || numbers.length !== 4) {
      errors.push({
        row: -1,
        col: -1,
        message: "Exactly 4 numbers are required",
      });
      return { isValid: false, errors };
    }

    for (let i = 0; i < numbers.length; i++) {
      if (!Number.isInteger(numbers[i]) || numbers[i] < 1 || numbers[i] > 100) {
        errors.push({
          row: -1,
          col: -1,
          message: `Number ${i + 1} must be an integer between 1 and 100`,
        });
      }
    }

    // Validate targets
    if (!targets || targets.length === 0) {
      errors.push({
        row: -1,
        col: -1,
        message: "At least one target is required",
      });
      return { isValid: false, errors };
    }

    if (errors.length > 0) {
      return { isValid: false, errors };
    }

    // Try to solve for each target
    const targetSolutions: {
      target: number;
      expression: string;
      reachable: boolean;
    }[] = [];

    for (const { target } of targets) {
      const expression = this.findExpression(numbers, target);
      targetSolutions.push({
        target,
        expression: expression || "",
        reachable: !!expression,
      });
    }

    const allReachable = targetSolutions.every((t) => t.reachable);

    if (!allReachable) {
      const unreachable = targetSolutions
        .filter((t) => !t.reachable)
        .map((t) => t.target);
      errors.push({
        row: -1,
        col: -1,
        message: `Target(s) ${unreachable.join(", ")} cannot be reached with the given numbers`,
      });
    }

    return {
      isValid: allReachable,
      errors,
      targetSolutions,
    };
  }

  /**
   * Find an expression that evaluates to the target using all 4 numbers
   */
  private findExpression(numbers: number[], target: number): string | null {
    const ops = ["+", "-", "*", "/"];

    // Generate all permutations of numbers
    const perms = this.permutations(numbers);

    for (const perm of perms) {
      // Try all combinations of operators
      for (const op1 of ops) {
        for (const op2 of ops) {
          for (const op3 of ops) {
            // Try different parenthesizations
            const expressions = [
              // ((a op1 b) op2 c) op3 d
              `((${perm[0]}${op1}${perm[1]})${op2}${perm[2]})${op3}${perm[3]}`,
              // (a op1 (b op2 c)) op3 d
              `(${perm[0]}${op1}(${perm[1]}${op2}${perm[2]}))${op3}${perm[3]}`,
              // (a op1 b) op2 (c op3 d)
              `(${perm[0]}${op1}${perm[1]})${op2}(${perm[2]}${op3}${perm[3]})`,
              // a op1 ((b op2 c) op3 d)
              `${perm[0]}${op1}((${perm[1]}${op2}${perm[2]})${op3}${perm[3]})`,
              // a op1 (b op2 (c op3 d))
              `${perm[0]}${op1}(${perm[1]}${op2}(${perm[2]}${op3}${perm[3]}))`,
            ];

            for (const expr of expressions) {
              try {
                // Safe evaluation
                const result = this.evaluateExpression(expr);
                if (Math.abs(result - target) < 0.0001) {
                  return this.formatExpression(expr);
                }
              } catch {
                // Invalid expression, continue
              }
            }
          }
        }
      }
    }

    return null;
  }

  /**
   * Generate all permutations of an array
   */
  private permutations<T>(arr: T[]): T[][] {
    if (arr.length <= 1) return [arr];

    const result: T[][] = [];
    for (let i = 0; i < arr.length; i++) {
      const rest = [...arr.slice(0, i), ...arr.slice(i + 1)];
      const restPerms = this.permutations(rest);
      for (const perm of restPerms) {
        result.push([arr[i], ...perm]);
      }
    }
    return result;
  }

  /**
   * Safely evaluate a mathematical expression
   */
  private evaluateExpression(expr: string): number {
    // Replace operators for evaluation
    const sanitized = expr.replace(/\*/g, "*").replace(/\//g, "/");

    // Simple recursive descent parser to avoid eval()
    return this.parseExpression(sanitized);
  }

  private parseExpression(expr: string): number {
    expr = expr.trim();

    // Remove outer parentheses if present
    if (expr.startsWith("(") && expr.endsWith(")")) {
      let depth = 0;
      let canRemove = true;
      for (let i = 0; i < expr.length - 1; i++) {
        if (expr[i] === "(") depth++;
        if (expr[i] === ")") depth--;
        if (depth === 0 && i < expr.length - 1) {
          canRemove = false;
          break;
        }
      }
      if (canRemove) {
        expr = expr.slice(1, -1).trim();
      }
    }

    // Find the last + or - not inside parentheses
    let depth = 0;
    for (let i = expr.length - 1; i >= 0; i--) {
      if (expr[i] === ")") depth++;
      if (expr[i] === "(") depth--;
      if (depth === 0 && (expr[i] === "+" || expr[i] === "-") && i > 0) {
        const left = this.parseExpression(expr.slice(0, i));
        const right = this.parseExpression(expr.slice(i + 1));
        return expr[i] === "+" ? left + right : left - right;
      }
    }

    // Find the last * or / not inside parentheses
    depth = 0;
    for (let i = expr.length - 1; i >= 0; i--) {
      if (expr[i] === ")") depth++;
      if (expr[i] === "(") depth--;
      if (depth === 0 && (expr[i] === "*" || expr[i] === "/") && i > 0) {
        const left = this.parseExpression(expr.slice(0, i));
        const right = this.parseExpression(expr.slice(i + 1));
        if (expr[i] === "/") {
          if (right === 0) throw new Error("Division by zero");
          return left / right;
        }
        return left * right;
      }
    }

    // Must be a number
    const num = parseFloat(expr);
    if (isNaN(num)) throw new Error(`Invalid number: ${expr}`);
    return num;
  }

  /**
   * Format expression for display (replace * with × and / with ÷)
   */
  private formatExpression(expr: string): string {
    return expr.replace(/\*/g, "×").replace(/\//g, "÷");
  }

  // ============================================
  // Word Forge Methods
  // ============================================

  /**
   * Validates Word Forge letters and generates all valid words
   */
  async validateWordForge(
    letters: string[],
    centerLetter: string,
  ): Promise<WordForgeValidationResult> {
    const errors: ValidationError[] = [];
    const normalizedLetters = letters.map((l) => l.toUpperCase().trim());
    const normalizedCenter = centerLetter.toUpperCase().trim();

    // Validate letters
    if (!normalizedLetters || normalizedLetters.length !== 7) {
      errors.push({
        row: -1,
        col: -1,
        message: "Exactly 7 letters are required",
      });
      return { isValid: false, errors };
    }

    // Check for duplicates
    const letterSet = new Set(normalizedLetters);
    if (letterSet.size !== 7) {
      errors.push({
        row: -1,
        col: -1,
        message: "All 7 letters must be unique",
      });
    }

    // Validate all are letters
    for (const letter of normalizedLetters) {
      if (!/^[A-Z]$/.test(letter)) {
        errors.push({
          row: -1,
          col: -1,
          message: `"${letter}" is not a valid letter`,
        });
      }
    }

    // Validate center letter is one of the 7
    if (!normalizedLetters.includes(normalizedCenter)) {
      errors.push({
        row: -1,
        col: -1,
        message: "Center letter must be one of the 7 selected letters",
      });
    }

    if (errors.length > 0) {
      return { isValid: false, errors };
    }

    // Find all valid words
    const allWords = await this.dictionaryService.findValidWords(
      normalizedLetters,
      normalizedCenter,
      4,
    );

    if (allWords.length < 10) {
      errors.push({
        row: -1,
        col: -1,
        message: `Only ${allWords.length} valid words found. Try different letters for a better puzzle.`,
      });
      return { isValid: false, errors, allWords };
    }

    // Identify pangrams (words using all 7 letters)
    const pangrams = allWords.filter((word) =>
      normalizedLetters.every((l) => word.includes(l)),
    );

    // Calculate max score
    // 4-letter words = 1 point, 5+ letter words = word length, pangrams = word length + 7
    let maxScore = 0;
    for (const word of allWords) {
      if (word.length === 4) {
        maxScore += 1;
      } else {
        maxScore += word.length;
      }
      if (pangrams.includes(word)) {
        maxScore += 7; // Pangram bonus
      }
    }

    return {
      isValid: true,
      errors: [],
      allWords,
      pangrams,
      maxScore,
    };
  }
}
