import { useState, useCallback, useEffect } from 'react'
import { Shuffle, Trash2, CheckCircle } from 'lucide-react'
import ToggleGrid from './shared/ToggleGrid'
import ValidationStatus from './shared/ValidationStatus'

interface LightsOutEditorProps {
  initialData?: {
    rows: number
    cols: number
    initialState: boolean[][]
  }
  initialSolution?: {
    moves: { row: number; col: number }[]
    minMoves: number
  }
  onChange?: (puzzleData: any, solution: any, isValid?: boolean) => void
  className?: string
}

type GridSize = 3 | 4 | 5

const createEmptyGrid = (size: GridSize): boolean[][] =>
  Array(size).fill(null).map(() => Array(size).fill(false))

// Toggle a cell and its neighbors (lights out mechanic)
const toggleWithNeighbors = (grid: boolean[][], row: number, col: number): boolean[][] => {
  const newGrid = grid.map(r => [...r])
  const size = grid.length

  // Toggle the cell itself
  newGrid[row][col] = !newGrid[row][col]

  // Toggle neighbors
  if (row > 0) newGrid[row - 1][col] = !newGrid[row - 1][col]
  if (row < size - 1) newGrid[row + 1][col] = !newGrid[row + 1][col]
  if (col > 0) newGrid[row][col - 1] = !newGrid[row][col - 1]
  if (col < size - 1) newGrid[row][col + 1] = !newGrid[row][col + 1]

  return newGrid
}

// Check if puzzle is solved (all lights off)
const isSolved = (grid: boolean[][]): boolean =>
  grid.every(row => row.every(cell => !cell))

// Solve lights out using Gaussian elimination (returns solution moves or null)
const solveLightsOut = (grid: boolean[][]): { row: number; col: number }[] | null => {
  const size = grid.length
  const n = size * size

  // Create augmented matrix
  // Each row represents a cell, columns are the effect of pressing each button
  const matrix: number[][] = []

  for (let i = 0; i < n; i++) {
    const row = new Array(n + 1).fill(0)
    const r = Math.floor(i / size)
    const c = i % size

    // This button affects itself
    row[i] = 1
    // And its neighbors
    if (r > 0) row[i - size] = 1
    if (r < size - 1) row[i + size] = 1
    if (c > 0) row[i - 1] = 1
    if (c < size - 1) row[i + 1] = 1

    // Right side: current state (we want to turn it off if on)
    row[n] = grid[r][c] ? 1 : 0

    matrix.push(row)
  }

  // Gaussian elimination in GF(2)
  let pivotRow = 0
  for (let col = 0; col < n && pivotRow < n; col++) {
    // Find pivot
    let foundPivot = -1
    for (let row = pivotRow; row < n; row++) {
      if (matrix[row][col] === 1) {
        foundPivot = row
        break
      }
    }

    if (foundPivot === -1) continue

    // Swap rows
    [matrix[pivotRow], matrix[foundPivot]] = [matrix[foundPivot], matrix[pivotRow]]

    // Eliminate
    for (let row = 0; row < n; row++) {
      if (row !== pivotRow && matrix[row][col] === 1) {
        for (let c = 0; c <= n; c++) {
          matrix[row][c] ^= matrix[pivotRow][c]
        }
      }
    }

    pivotRow++
  }

  // Check for inconsistency
  for (let row = pivotRow; row < n; row++) {
    if (matrix[row][n] === 1) {
      return null // No solution
    }
  }

  // Extract solution (back substitution)
  const solution = new Array(n).fill(0)
  for (let row = 0; row < pivotRow; row++) {
    // Find leading 1
    for (let col = 0; col < n; col++) {
      if (matrix[row][col] === 1) {
        solution[col] = matrix[row][n]
        break
      }
    }
  }

  // Convert to moves
  const moves: { row: number; col: number }[] = []
  for (let i = 0; i < n; i++) {
    if (solution[i] === 1) {
      moves.push({
        row: Math.floor(i / size),
        col: i % size,
      })
    }
  }

  return moves
}

// Generate a random solvable puzzle
const generateRandomPuzzle = (size: GridSize): { grid: boolean[][]; moves: { row: number; col: number }[] } => {
  // Start with solved state and apply random moves
  let grid = createEmptyGrid(size)
  const moves: { row: number; col: number }[] = []

  // Apply 3-8 random moves
  const numMoves = Math.floor(Math.random() * 6) + 3
  const usedCells = new Set<string>()

  for (let i = 0; i < numMoves; i++) {
    let row: number, col: number
    let key: string

    // Pick a random cell we haven't used
    do {
      row = Math.floor(Math.random() * size)
      col = Math.floor(Math.random() * size)
      key = `${row},${col}`
    } while (usedCells.has(key))

    usedCells.add(key)
    grid = toggleWithNeighbors(grid, row, col)
    moves.push({ row, col })
  }

  // If we ended up with all lights off, add one more move
  if (isSolved(grid)) {
    const row = Math.floor(Math.random() * size)
    const col = Math.floor(Math.random() * size)
    grid = toggleWithNeighbors(grid, row, col)
    moves.push({ row, col })
  }

  return { grid, moves }
}

export function LightsOutEditor({
  initialData,
  initialSolution,
  onChange,
  className = '',
}: LightsOutEditorProps) {
  const [size, setSize] = useState<GridSize>(initialData?.rows as GridSize || 3)
  const [grid, setGrid] = useState<boolean[][]>(initialData?.initialState || createEmptyGrid(3))
  const [solution, setSolution] = useState<{ moves: { row: number; col: number }[]; minMoves: number } | null>(
    initialSolution || null
  )
  const [validationResult, setValidationResult] = useState<{
    isValid: boolean
    hasUniqueSolution: boolean
    errors: { row: number; col: number; message: string }[]
  } | null>(null)

  // Reset grid when size changes
  useEffect(() => {
    if (!initialData) {
      setGrid(createEmptyGrid(size))
      setSolution(null)
      setValidationResult(null)
    }
  }, [size, initialData])

  // Notify parent of changes
  useEffect(() => {
    if (onChange) {
      onChange(
        { rows: size, cols: size, initialState: grid },
        solution,
        validationResult?.isValid ?? false
      )
    }
  }, [grid, solution, size, onChange, validationResult])

  const handleToggle = useCallback((row: number, col: number) => {
    // In editor mode, just toggle the single cell (not neighbors)
    setGrid(prev => {
      const newGrid = prev.map(r => [...r])
      newGrid[row][col] = !newGrid[row][col]
      return newGrid
    })
    setValidationResult(null)
    setSolution(null)
  }, [])

  const handleClear = useCallback(() => {
    setGrid(createEmptyGrid(size))
    setSolution(null)
    setValidationResult(null)
  }, [size])

  const handleRandom = useCallback(() => {
    const { grid: newGrid } = generateRandomPuzzle(size)
    setGrid(newGrid)

    // Solve the puzzle to get optimal solution
    const solvedMoves = solveLightsOut(newGrid)
    if (solvedMoves) {
      setSolution({ moves: solvedMoves, minMoves: solvedMoves.length })
      setValidationResult({
        isValid: true,
        hasUniqueSolution: true,
        errors: [],
      })
    }
  }, [size])

  const handleValidate = useCallback(() => {
    // Check if there are any lights on
    const hasLightsOn = grid.some(row => row.some(cell => cell))

    if (!hasLightsOn) {
      setValidationResult({
        isValid: false,
        hasUniqueSolution: false,
        errors: [{ row: -1, col: -1, message: 'Puzzle must have at least one light on' }],
      })
      return
    }

    // Try to solve
    const moves = solveLightsOut(grid)

    if (moves === null) {
      setValidationResult({
        isValid: false,
        hasUniqueSolution: false,
        errors: [{ row: -1, col: -1, message: 'This puzzle has no solution' }],
      })
      setSolution(null)
    } else {
      setSolution({ moves, minMoves: moves.length })
      setValidationResult({
        isValid: true,
        hasUniqueSolution: true,
        errors: [],
      })
    }
  }, [grid])

  const handleSizeChange = useCallback((newSize: GridSize) => {
    setSize(newSize)
  }, [])

  const lightsOnCount = grid.flat().filter(Boolean).length

  return (
    <div className={`space-y-4 ${className}`}>
      {/* Size selector */}
      <div>
        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
          Grid Size
        </label>
        <div className="flex gap-2">
          {([3, 4, 5] as GridSize[]).map((s) => (
            <button
              key={s}
              type="button"
              onClick={() => handleSizeChange(s)}
              className={`px-4 py-2 rounded-md font-medium transition-colors ${
                size === s
                  ? 'bg-blue-500 text-white'
                  : 'bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600'
              }`}
            >
              {s}x{s}
            </button>
          ))}
        </div>
      </div>

      {/* Grid */}
      <div>
        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
          Toggle Lights (click to toggle individual cells)
        </label>
        <div className="flex justify-center">
          <ToggleGrid
            grid={grid}
            onToggle={handleToggle}
            cellSize="lg"
          />
        </div>
        <p className="mt-2 text-sm text-gray-500 dark:text-gray-400 text-center">
          {lightsOnCount} light{lightsOnCount !== 1 ? 's' : ''} on
        </p>
      </div>

      {/* Actions */}
      <div className="flex gap-2 flex-wrap">
        <button
          type="button"
          onClick={handleRandom}
          className="flex items-center gap-2 px-4 py-2 bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-300 rounded-md hover:bg-purple-200 dark:hover:bg-purple-900/50 transition-colors"
        >
          <Shuffle className="w-4 h-4" />
          Random
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

      {/* Solution info */}
      {solution && (
        <div className="p-4 bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg">
          <h4 className="font-medium text-green-800 dark:text-green-200 mb-2">
            Solution Found
          </h4>
          <p className="text-sm text-green-700 dark:text-green-300">
            Minimum moves: <strong>{solution.minMoves}</strong>
          </p>
          <p className="text-xs text-green-600 dark:text-green-400 mt-1">
            Moves: {solution.moves.map(m => `(${m.row + 1},${m.col + 1})`).join(' → ')}
          </p>
        </div>
      )}
    </div>
  )
}

export default LightsOutEditor
