import { useState, useCallback, useEffect } from 'react'
import { useMutation } from '@tanstack/react-query'
import clsx from 'clsx'
import { Loader2, CheckCircle, Wand2 } from 'lucide-react'
import { validateApi } from '../../lib/api'
import NumberPad from './shared/NumberPad'
import ValidationStatus from './shared/ValidationStatus'

interface SudokuEditorProps {
  initialGrid?: number[][]
  initialSolution?: number[][]
  onChange?: (grid: number[][], solution: number[][], isValid?: boolean) => void
  className?: string
}

interface ValidationResult {
  isValid: boolean
  errors: { row: number; col: number; message: string }[]
  hasUniqueSolution: boolean
  solution?: number[][]
}

interface SolveResult {
  success: boolean
  solution?: number[][]
  error?: string
}

const createEmptyGrid = (): number[][] => 
  Array(9).fill(null).map(() => Array(9).fill(0))

export function SudokuEditor({
  initialGrid,
  initialSolution,
  onChange,
  className,
}: SudokuEditorProps) {
  const [grid, setGrid] = useState<number[][]>(initialGrid || createEmptyGrid())
  const [solution, setSolution] = useState<number[][]>(initialSolution || createEmptyGrid())
  const [selectedCell, setSelectedCell] = useState<[number, number] | null>(null)
  const [validationResult, setValidationResult] = useState<ValidationResult | null>(null)

  // Reset when initialGrid changes
  useEffect(() => {
    if (initialGrid) {
      setGrid(initialGrid)
    }
    if (initialSolution) {
      setSolution(initialSolution)
    }
  }, [initialGrid, initialSolution])

  // Notify parent of changes
  useEffect(() => {
    onChange?.(grid, solution, validationResult?.isValid && validationResult?.hasUniqueSolution)
  }, [grid, solution, onChange, validationResult])

  const validateMutation = useMutation({
    mutationFn: (g: number[][]) => validateApi.validateSudoku(g),
    onSuccess: (response) => {
      const result = response.data as ValidationResult
      setValidationResult(result)
      if (result.solution) {
        setSolution(result.solution)
      }
    },
  })

  const solveMutation = useMutation({
    mutationFn: (g: number[][]) => validateApi.solveSudoku(g),
    onSuccess: (response) => {
      const result = response.data as SolveResult
      if (result.success && result.solution) {
        setSolution(result.solution)
        setValidationResult({
          isValid: true,
          errors: [],
          hasUniqueSolution: true,
          solution: result.solution,
        })
      }
    },
  })

  const handleCellClick = useCallback((row: number, col: number) => {
    setSelectedCell([row, col])
  }, [])

  const handleNumberInput = useCallback((num: number) => {
    if (!selectedCell) return
    const [row, col] = selectedCell
    const newGrid = grid.map(r => [...r])
    newGrid[row][col] = num
    setGrid(newGrid)
    setValidationResult(null) // Clear validation when grid changes
  }, [selectedCell, grid])

  const handleClear = useCallback(() => {
    if (!selectedCell) return
    const [row, col] = selectedCell
    const newGrid = grid.map(r => [...r])
    newGrid[row][col] = 0
    setGrid(newGrid)
    setValidationResult(null)
  }, [selectedCell, grid])

  const handleValidate = useCallback(() => {
    validateMutation.mutate(grid)
  }, [grid, validateMutation])

  const handleSolve = useCallback(() => {
    solveMutation.mutate(grid)
  }, [grid, solveMutation])

  const handleClearAll = useCallback(() => {
    setGrid(createEmptyGrid())
    setSolution(createEmptyGrid())
    setValidationResult(null)
    setSelectedCell(null)
  }, [])

  // Handle keyboard input
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (!selectedCell) return

      const [row, col] = selectedCell

      // Number keys
      if (e.key >= '1' && e.key <= '9') {
        handleNumberInput(parseInt(e.key))
        return
      }

      // Clear keys
      if (e.key === '0' || e.key === 'Backspace' || e.key === 'Delete') {
        handleClear()
        return
      }

      // Arrow keys
      if (e.key === 'ArrowUp' && row > 0) {
        setSelectedCell([row - 1, col])
      } else if (e.key === 'ArrowDown' && row < 8) {
        setSelectedCell([row + 1, col])
      } else if (e.key === 'ArrowLeft' && col > 0) {
        setSelectedCell([row, col - 1])
      } else if (e.key === 'ArrowRight' && col < 8) {
        setSelectedCell([row, col + 1])
      }
    }

    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [selectedCell, handleNumberInput, handleClear])

  const isHighlighted = (row: number, col: number): boolean => {
    if (!selectedCell) return false
    const [selRow, selCol] = selectedCell
    // Same row, column, or 3x3 box
    const sameRow = row === selRow
    const sameCol = col === selCol
    const sameBox = 
      Math.floor(row / 3) === Math.floor(selRow / 3) &&
      Math.floor(col / 3) === Math.floor(selCol / 3)
    return sameRow || sameCol || sameBox
  }

  const hasError = (row: number, col: number): boolean => {
    if (!validationResult) return false
    return validationResult.errors.some(e => e.row === row && e.col === col)
  }

  return (
    <div className={clsx('space-y-4', className)}>
      {/* Grid */}
      <div className="inline-block">
        <div 
          className="grid grid-cols-9 border-2 border-gray-800 dark:border-gray-200"
          style={{ width: 'fit-content' }}
        >
          {grid.map((row, rowIdx) =>
            row.map((cell, colIdx) => (
              <button
                key={rowIdx + "-" + colIdx}
                type="button"
                onClick={() => handleCellClick(rowIdx, colIdx)}
                className={clsx(
                  'w-10 h-10 flex items-center justify-center text-lg font-medium',
                  'transition-colors focus:outline-none border border-gray-300 dark:border-gray-600',
                  // Thicker borders for 3x3 boxes
                  colIdx % 3 === 2 && colIdx !== 8 && 'border-r-2 border-r-gray-800 dark:border-r-gray-200',
                  rowIdx % 3 === 2 && rowIdx !== 8 && 'border-b-2 border-b-gray-800 dark:border-b-gray-200',
                  // Selection and highlighting
                  selectedCell?.[0] === rowIdx && selectedCell?.[1] === colIdx
                    ? 'bg-blue-200 dark:bg-blue-800'
                    : isHighlighted(rowIdx, colIdx)
                    ? 'bg-blue-50 dark:bg-blue-900/30'
                    : 'hover:bg-gray-100 dark:hover:bg-gray-700',
                  // Error styling
                  hasError(rowIdx, colIdx) && 'text-red-600 dark:text-red-400',
                  // Initial values (non-zero) are bold
                  cell !== 0 && 'font-bold text-gray-900 dark:text-white'
                )}
              >
                {cell || ''}
              </button>
            ))
          )}
        </div>
      </div>

      {/* Controls */}
      <div className="flex flex-wrap items-start gap-6">
        <div className="space-y-2">
          <p className="text-sm text-gray-500 dark:text-gray-400">
            Click a cell, then use number pad or keyboard (1-9)
          </p>
          <NumberPad
            onNumberClick={handleNumberInput}
            onClear={handleClear}
            disabled={!selectedCell}
          />
        </div>

        <div className="space-y-3">
          <div className="flex flex-wrap gap-2">
            <button
              type="button"
              onClick={handleValidate}
              disabled={validateMutation.isPending}
              className={clsx(
                'flex items-center gap-2 px-4 py-2 rounded-lg font-medium',
                'bg-blue-600 text-white hover:bg-blue-700',
                'disabled:opacity-50 disabled:cursor-not-allowed'
              )}
            >
              {validateMutation.isPending ? (
                <Loader2 className="w-4 h-4 animate-spin" />
              ) : (
                <CheckCircle className="w-4 h-4" />
              )}
              Validate
            </button>

            <button
              type="button"
              onClick={handleSolve}
              disabled={solveMutation.isPending}
              className={clsx(
                'flex items-center gap-2 px-4 py-2 rounded-lg font-medium',
                'bg-purple-600 text-white hover:bg-purple-700',
                'disabled:opacity-50 disabled:cursor-not-allowed'
              )}
            >
              {solveMutation.isPending ? (
                <Loader2 className="w-4 h-4 animate-spin" />
              ) : (
                <Wand2 className="w-4 h-4" />
              )}
              Solve
            </button>

            <button
              type="button"
              onClick={handleClearAll}
              className="px-4 py-2 rounded-lg font-medium bg-gray-200 dark:bg-gray-700 hover:bg-gray-300 dark:hover:bg-gray-600"
            >
              Clear All
            </button>
          </div>

          <ValidationStatus
            isValidating={validateMutation.isPending}
            isValid={validationResult?.isValid}
            hasUniqueSolution={validationResult?.hasUniqueSolution}
            errors={validationResult?.errors}
          />
        </div>
      </div>

      {/* Solution display */}
      {solution.some(row => row.some(cell => cell !== 0)) && (
        <div className="space-y-2">
          <h4 className="font-medium text-gray-700 dark:text-gray-300">Solution</h4>
          <div className="inline-block">
            <div 
              className="grid grid-cols-9 border-2 border-gray-600 dark:border-gray-400 opacity-75"
              style={{ width: 'fit-content' }}
            >
              {solution.map((row, rowIdx) =>
                row.map((cell, colIdx) => (
                  <div
                    key={"sol-" + rowIdx + "-" + colIdx}
                    className={clsx(
                      'w-8 h-8 flex items-center justify-center text-sm',
                      'border border-gray-200 dark:border-gray-600 bg-gray-50 dark:bg-gray-800',
                      colIdx % 3 === 2 && colIdx !== 8 && 'border-r-2 border-r-gray-600 dark:border-r-gray-400',
                      rowIdx % 3 === 2 && rowIdx !== 8 && 'border-b-2 border-b-gray-600 dark:border-b-gray-400'
                    )}
                  >
                    {cell || ''}
                  </div>
                ))
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
