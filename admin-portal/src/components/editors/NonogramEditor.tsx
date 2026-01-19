import { useState, useCallback, useEffect, useMemo } from 'react'
import { CheckCircle, Trash2, Wand2 } from 'lucide-react'
import ValidationStatus from './shared/ValidationStatus'

interface NonogramEditorProps {
  initialData?: {
    rows: number
    cols: number
    rowClues: number[][]
    colClues: number[][]
  }
  initialSolution?: {
    grid?: number[][]  // Solution might be { grid: [...] }
  } | number[][]       // Or solution might be direct array
  onChange?: (puzzleData: any, solution: any, isValid?: boolean) => void
  className?: string
}

type GridSize = 5 | 8 | 10 | 12 | 15

const createEmptyGrid = (rows: number, cols: number): number[][] =>
  Array(rows).fill(null).map(() => Array(cols).fill(0))

// Generate clues from a solution grid
const generateClues = (grid: number[][]): { rowClues: number[][]; colClues: number[][] } => {
  const rows = grid.length
  const cols = grid[0]?.length || 0

  // Generate row clues
  const rowClues: number[][] = []
  for (let r = 0; r < rows; r++) {
    const clue: number[] = []
    let count = 0
    for (let c = 0; c < cols; c++) {
      if (grid[r][c] === 1) {
        count++
      } else if (count > 0) {
        clue.push(count)
        count = 0
      }
    }
    if (count > 0) clue.push(count)
    rowClues.push(clue.length > 0 ? clue : [0])
  }

  // Generate column clues
  const colClues: number[][] = []
  for (let c = 0; c < cols; c++) {
    const clue: number[] = []
    let count = 0
    for (let r = 0; r < rows; r++) {
      if (grid[r][c] === 1) {
        count++
      } else if (count > 0) {
        clue.push(count)
        count = 0
      }
    }
    if (count > 0) clue.push(count)
    colClues.push(clue.length > 0 ? clue : [0])
  }

  return { rowClues, colClues }
}

// Generate a random pattern
const generateRandomPattern = (rows: number, cols: number, fillRatio: number = 0.4): number[][] => {
  return Array(rows).fill(null).map(() =>
    Array(cols).fill(null).map(() => Math.random() < fillRatio ? 1 : 0)
  )
}

// Generate a simple symmetric pattern
const generateSymmetricPattern = (rows: number, cols: number): number[][] => {
  const grid = createEmptyGrid(rows, cols)
  const centerR = Math.floor(rows / 2)
  const centerC = Math.floor(cols / 2)

  // Create a simple heart/diamond shape
  for (let r = 0; r < rows; r++) {
    for (let c = 0; c < cols; c++) {
      const distR = Math.abs(r - centerR)
      const distC = Math.abs(c - centerC)

      // Diamond pattern
      if (distR + distC <= Math.min(centerR, centerC)) {
        grid[r][c] = 1
      }
    }
  }

  return grid
}

// ============ Nonogram Solver for Validation ============

/**
 * Generate all valid placements for clues on a line
 */
const generatePlacements = (
  clues: number[],
  len: number,
  current: number[],
): number[][] => {
  const results: number[][] = []

  const generate = (
    clueIdx: number,
    pos: number,
    placement: number[],
  ): void => {
    if (clueIdx === clues.length) {
      const final = placement.slice()
      for (let i = pos; i < len; i++) {
        final[i] = -1
      }
      let valid = true
      for (let i = 0; i < len; i++) {
        if (current[i] !== 0 && current[i] !== final[i]) {
          valid = false
          break
        }
      }
      if (valid) {
        results.push(final)
      }
      return
    }

    const clue = clues[clueIdx]
    const remaining = clues.slice(clueIdx + 1).reduce((a, b) => a + b, 0)
    const remainingSpaces = clues.length - clueIdx - 1
    const maxStart = len - remaining - remainingSpaces - clue

    for (let start = pos; start <= maxStart; start++) {
      let canPlace = true

      for (let i = pos; i < start; i++) {
        if (current[i] === 1) {
          canPlace = false
          break
        }
      }
      if (!canPlace) continue

      for (let i = start; i < start + clue; i++) {
        if (current[i] === -1) {
          canPlace = false
          break
        }
      }
      if (!canPlace) continue

      const newPlacement = placement.slice()
      for (let i = pos; i < start; i++) {
        newPlacement[i] = -1
      }
      for (let i = start; i < start + clue; i++) {
        newPlacement[i] = 1
      }

      if (clueIdx < clues.length - 1) {
        if (current[start + clue] === 1) {
          continue
        }
        newPlacement[start + clue] = -1
        generate(clueIdx + 1, start + clue + 1, newPlacement)
      } else {
        generate(clueIdx + 1, start + clue, newPlacement)
      }
    }
  }

  generate(0, 0, Array(len).fill(0))
  return results
}

/**
 * Solve a single line using line-solving logic
 * Returns array with 1 (filled), -1 (empty), or 0 (unknown)
 */
const solveLine = (line: number[], clues: number[]): number[] => {
  const len = line.length
  const result = line.slice()

  // Handle empty line (clue is [0])
  if (clues.length === 1 && clues[0] === 0) {
    return result.map((c) => (c === 0 ? -1 : c))
  }

  // Handle fully constrained line
  const totalFilled = clues.reduce((a, b) => a + b, 0)
  const minSpaces = clues.length - 1
  if (totalFilled + minSpaces === len) {
    let pos = 0
    for (let i = 0; i < clues.length; i++) {
      for (let j = 0; j < clues[i]; j++) {
        result[pos++] = 1
      }
      if (i < clues.length - 1) {
        result[pos++] = -1
      }
    }
    return result
  }

  const placements = generatePlacements(clues, len, line)

  if (placements.length === 0) {
    return result
  }

  // Find cells that are the same across all valid placements
  for (let i = 0; i < len; i++) {
    if (result[i] !== 0) continue

    const firstVal = placements[0][i]
    let allSame = true
    for (let p = 1; p < placements.length; p++) {
      if (placements[p][i] !== firstVal) {
        allSame = false
        break
      }
    }
    if (allSame) {
      result[i] = firstVal
    }
  }

  return result
}

/**
 * Check if a nonogram can be solved using line-by-line logic alone (no guessing)
 */
const isLogicallySolvable = (
  rowClues: number[][],
  colClues: number[][],
): { solvable: boolean; unsolvedCount: number } => {
  const rows = rowClues.length
  const cols = colClues.length

  // 0 = unknown, 1 = filled, -1 = empty
  const grid: number[][] = Array(rows)
    .fill(null)
    .map(() => Array(cols).fill(0))

  let changed = true
  let iterations = 0
  const maxIterations = rows * cols * 2

  while (changed && iterations < maxIterations) {
    changed = false
    iterations++

    // Process each row
    for (let r = 0; r < rows; r++) {
      const line = grid[r].slice()
      const newLine = solveLine(line, rowClues[r])
      for (let c = 0; c < cols; c++) {
        if (grid[r][c] === 0 && newLine[c] !== 0) {
          grid[r][c] = newLine[c]
          changed = true
        }
      }
    }

    // Process each column
    for (let c = 0; c < cols; c++) {
      const line = grid.map((row) => row[c])
      const newLine = solveLine(line, colClues[c])
      for (let r = 0; r < rows; r++) {
        if (grid[r][c] === 0 && newLine[r] !== 0) {
          grid[r][c] = newLine[r]
          changed = true
        }
      }
    }
  }

  // Count unsolved cells
  let unsolvedCount = 0
  for (let r = 0; r < rows; r++) {
    for (let c = 0; c < cols; c++) {
      if (grid[r][c] === 0) {
        unsolvedCount++
      }
    }
  }

  return { solvable: unsolvedCount === 0, unsolvedCount }
}

export function NonogramEditor({
  initialData,
  initialSolution,
  onChange,
  className = '',
}: NonogramEditorProps) {
  const [rows, setRows] = useState(initialData?.rows || 5)
  const [cols, setCols] = useState(initialData?.cols || 5)
  const [grid, setGrid] = useState<number[][]>(() => {
    // Handle solution as { grid: [...] } or direct array
    if (initialSolution) {
      if (Array.isArray(initialSolution)) {
        return initialSolution
      }
      if (initialSolution.grid) {
        return initialSolution.grid
      }
    }
    const r = initialData?.rows || 5
    const c = initialData?.cols || 5
    return createEmptyGrid(r, c)
  })
  const [validationResult, setValidationResult] = useState<{
    isValid: boolean
    hasUniqueSolution: boolean
    errors: { row: number; col: number; message: string }[]
  } | null>(null)

  // Generate clues from the current grid
  const { rowClues, colClues } = useMemo(() => generateClues(grid), [grid])

  // Notify parent of changes
  useEffect(() => {
    if (onChange && validationResult?.isValid) {
      onChange(
        { rows, cols, rowClues, colClues },
        { grid },
        true
      )
    }
  }, [rows, cols, rowClues, colClues, grid, onChange, validationResult])

  const handleSizeChange = useCallback((size: GridSize) => {
    setRows(size)
    setCols(size)
    setGrid(createEmptyGrid(size, size))
    setValidationResult(null)
  }, [])

  const handleCellClick = useCallback((row: number, col: number) => {
    setGrid(prev => {
      const newGrid = prev.map(r => [...r])
      newGrid[row][col] = newGrid[row][col] === 1 ? 0 : 1
      return newGrid
    })
    setValidationResult(null)
  }, [])

  const handleClear = useCallback(() => {
    setGrid(createEmptyGrid(rows, cols))
    setValidationResult(null)
  }, [rows, cols])

  const handleRandomPattern = useCallback(() => {
    setGrid(generateRandomPattern(rows, cols))
    setValidationResult(null)
  }, [rows, cols])

  const handleSymmetricPattern = useCallback(() => {
    setGrid(generateSymmetricPattern(rows, cols))
    setValidationResult(null)
  }, [rows, cols])

  const handleValidate = useCallback(() => {
    const errors: { row: number; col: number; message: string }[] = []

    // Check if there are any filled cells
    const filledCount = grid.flat().filter(c => c === 1).length
    if (filledCount === 0) {
      errors.push({ row: -1, col: -1, message: 'Draw a pattern first (click cells to fill)' })
      setValidationResult({ isValid: false, hasUniqueSolution: false, errors })
      return
    }

    // Check if pattern is too simple (less than 10% filled)
    const totalCells = rows * cols
    if (filledCount < totalCells * 0.1) {
      errors.push({ row: -1, col: -1, message: 'Pattern too simple. Add more filled cells.' })
      setValidationResult({ isValid: false, hasUniqueSolution: false, errors })
      return
    }

    // Generate clues and check if puzzle is solvable with logic alone
    const { rowClues: currentRowClues, colClues: currentColClues } = generateClues(grid)
    const solverResult = isLogicallySolvable(currentRowClues, currentColClues)

    if (!solverResult.solvable) {
      errors.push({
        row: -1,
        col: -1,
        message: `Puzzle requires guessing to solve (${solverResult.unsolvedCount} ambiguous cells). Try a different pattern.`
      })
      setValidationResult({ isValid: false, hasUniqueSolution: false, errors })
    } else {
      setValidationResult({ isValid: true, hasUniqueSolution: true, errors: [] })
    }
  }, [grid, rows, cols])

  // Calculate max clue length for sizing
  const maxRowClueLength = Math.max(...rowClues.map(c => c.length), 1)
  const maxColClueLength = Math.max(...colClues.map(c => c.length), 1)

  // Stats
  const filledCount = grid.flat().filter(c => c === 1).length
  const totalCells = rows * cols

  return (
    <div className={`space-y-6 ${className}`}>
      {/* Size selector */}
      <div>
        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
          Grid Size
        </label>
        <div className="flex gap-2 flex-wrap">
          {([5, 8, 10, 12, 15] as GridSize[]).map((size) => (
            <button
              key={size}
              type="button"
              onClick={() => handleSizeChange(size)}
              className={`px-3 py-2 rounded-md font-medium transition-colors ${
                rows === size
                  ? 'bg-blue-500 text-white'
                  : 'bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600'
              }`}
            >
              {size}×{size}
            </button>
          ))}
        </div>
      </div>

      {/* Instructions */}
      <div className="text-sm text-gray-600 dark:text-gray-400">
        Click cells to toggle filled/empty. Clues are auto-generated from your pattern.
      </div>

      {/* Grid with clues */}
      <div className="overflow-auto">
        <div className="inline-block">
          {/* Column clues */}
          <div className="flex" style={{ marginLeft: `${maxRowClueLength * 24 + 8}px` }}>
            {colClues.map((clue, colIdx) => (
              <div
                key={colIdx}
                className="w-7 flex flex-col items-center justify-end pb-1"
                style={{ height: `${maxColClueLength * 20 + 8}px` }}
              >
                {clue.map((num, i) => (
                  <span
                    key={i}
                    className="text-xs font-medium text-gray-600 dark:text-gray-400 leading-tight"
                  >
                    {num}
                  </span>
                ))}
              </div>
            ))}
          </div>

          {/* Rows with clues */}
          {grid.map((row, rowIdx) => (
            <div key={rowIdx} className="flex items-center">
              {/* Row clues */}
              <div
                className="flex items-center justify-end gap-1 pr-2"
                style={{ width: `${maxRowClueLength * 24}px` }}
              >
                {rowClues[rowIdx].map((num, i) => (
                  <span
                    key={i}
                    className="text-xs font-medium text-gray-600 dark:text-gray-400 w-5 text-center"
                  >
                    {num}
                  </span>
                ))}
              </div>

              {/* Grid cells */}
              <div className="flex">
                {row.map((cell, colIdx) => (
                  <button
                    key={colIdx}
                    type="button"
                    onClick={() => handleCellClick(rowIdx, colIdx)}
                    className={`w-7 h-7 border border-gray-300 dark:border-gray-600 transition-colors ${
                      cell === 1
                        ? 'bg-gray-800 dark:bg-gray-200'
                        : 'bg-white dark:bg-gray-700 hover:bg-gray-100 dark:hover:bg-gray-600'
                    } ${
                      // Add thicker borders for 5x5 sections
                      colIdx % 5 === 0 && colIdx !== 0 ? 'border-l-2 border-l-gray-500' : ''
                    } ${
                      rowIdx % 5 === 0 && rowIdx !== 0 ? 'border-t-2 border-t-gray-500' : ''
                    }`}
                  />
                ))}
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Stats */}
      <div className="text-sm text-gray-500 dark:text-gray-400">
        {filledCount} / {totalCells} cells filled ({Math.round(filledCount / totalCells * 100)}%)
      </div>

      {/* Actions */}
      <div className="flex gap-2 flex-wrap">
        <button
          type="button"
          onClick={handleRandomPattern}
          className="flex items-center gap-2 px-4 py-2 bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-300 rounded-md hover:bg-purple-200 dark:hover:bg-purple-900/50 transition-colors"
        >
          <Wand2 className="w-4 h-4" />
          Random Pattern
        </button>
        <button
          type="button"
          onClick={handleSymmetricPattern}
          className="flex items-center gap-2 px-4 py-2 bg-indigo-100 dark:bg-indigo-900/30 text-indigo-700 dark:text-indigo-300 rounded-md hover:bg-indigo-200 dark:hover:bg-indigo-900/50 transition-colors"
        >
          <Wand2 className="w-4 h-4" />
          Diamond Pattern
        </button>
        <button
          type="button"
          onClick={handleClear}
          className="flex items-center gap-2 px-4 py-2 bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-300 rounded-md hover:bg-red-200 dark:hover:bg-red-900/50 transition-colors"
        >
          <Trash2 className="w-4 h-4" />
          Clear
        </button>
        <button
          type="button"
          onClick={handleValidate}
          className="flex items-center gap-2 px-4 py-2 bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 rounded-md hover:bg-blue-200 dark:hover:bg-blue-900/50 transition-colors"
        >
          <CheckCircle className="w-4 h-4" />
          Validate
        </button>
      </div>

      {/* Validation status */}
      <ValidationStatus
        isValid={validationResult?.isValid}
        hasUniqueSolution={validationResult?.hasUniqueSolution}
        errors={validationResult?.errors}
      />

      {/* Generated clues preview */}
      {validationResult?.isValid && (
        <div className="p-4 bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg">
          <h4 className="font-medium text-green-800 dark:text-green-200 mb-2">
            Generated Clues
          </h4>
          <div className="grid grid-cols-2 gap-4 text-sm">
            <div>
              <span className="font-medium text-gray-700 dark:text-gray-300">Row Clues:</span>
              <div className="text-gray-600 dark:text-gray-400 font-mono text-xs mt-1">
                {rowClues.map((c, i) => `${i + 1}: [${c.join(', ')}]`).join('\n')}
              </div>
            </div>
            <div>
              <span className="font-medium text-gray-700 dark:text-gray-300">Column Clues:</span>
              <div className="text-gray-600 dark:text-gray-400 font-mono text-xs mt-1">
                {colClues.map((c, i) => `${i + 1}: [${c.join(', ')}]`).join('\n')}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

export default NonogramEditor
