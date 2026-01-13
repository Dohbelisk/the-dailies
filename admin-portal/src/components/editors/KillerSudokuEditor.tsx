import { useState, useCallback, useEffect, useMemo } from 'react'
import { useMutation } from '@tanstack/react-query'
import { CheckCircle, Wand2, RotateCcw, Loader2, Plus, Trash2 } from 'lucide-react'
import GridEditor from './shared/GridEditor'
import ValidationStatus, { ValidationError } from './shared/ValidationStatus'
import { validateApi, Cage } from '../../lib/api'

interface KillerSudokuEditorProps {
  initialCages?: Cage[]
  initialSolution?: number[][]
  onChange: (data: { grid: number[][]; solution: number[][]; cages: Cage[]; isValid?: boolean }) => void
}

// Muted colors for cages - designed to be visually distinct when adjacent
const CAGE_COLORS = [
  'bg-amber-100 dark:bg-amber-900/40',
  'bg-sky-100 dark:bg-sky-900/40',
  'bg-rose-100 dark:bg-rose-900/40',
  'bg-emerald-100 dark:bg-emerald-900/40',
  'bg-violet-100 dark:bg-violet-900/40',
  'bg-orange-100 dark:bg-orange-900/40',
  'bg-teal-100 dark:bg-teal-900/40',
  'bg-pink-100 dark:bg-pink-900/40',
]

/**
 * Graph coloring algorithm to assign colors to cages
 * such that adjacent cages (sharing an edge) have different colors
 */
function computeCageColors(cages: Cage[], cellToCageMap: Map<string, number>): number[] {
  if (cages.length === 0) return []

  // Build adjacency list - two cages are adjacent if they share an orthogonal edge
  const adjacency: Set<number>[] = cages.map(() => new Set())

  cages.forEach((cage, cageIdx) => {
    cage.cells.forEach(([row, col]) => {
      // Check all 4 orthogonal neighbors
      const neighbors: [number, number][] = [
        [row - 1, col],
        [row + 1, col],
        [row, col - 1],
        [row, col + 1],
      ]

      neighbors.forEach(([nr, nc]) => {
        const neighborKey = `${nr},${nc}`
        const neighborCageIdx = cellToCageMap.get(neighborKey)
        if (neighborCageIdx !== undefined && neighborCageIdx !== cageIdx) {
          adjacency[cageIdx].add(neighborCageIdx)
          adjacency[neighborCageIdx].add(cageIdx)
        }
      })
    })
  })

  // Greedy graph coloring
  const colors: number[] = new Array(cages.length).fill(-1)

  for (let cageIdx = 0; cageIdx < cages.length; cageIdx++) {
    // Find colors used by adjacent cages
    const usedColors = new Set<number>()
    adjacency[cageIdx].forEach((neighborIdx) => {
      if (colors[neighborIdx] !== -1) {
        usedColors.add(colors[neighborIdx])
      }
    })

    // Assign the first available color
    let color = 0
    while (usedColors.has(color)) {
      color++
    }
    colors[cageIdx] = color % CAGE_COLORS.length
  }

  return colors
}

const createEmptyGrid = (): number[][] =>
  Array(9).fill(null).map(() => Array(9).fill(0))

export default function KillerSudokuEditor({
  initialCages,
  initialSolution,
  onChange,
}: KillerSudokuEditorProps) {
  const [cages, setCages] = useState<Cage[]>(initialCages ?? [])
  const [solution, setSolution] = useState<number[][]>(initialSolution ?? createEmptyGrid())
  const [selectedCell, setSelectedCell] = useState<[number, number] | null>(null)
  const [selectedCageIndex, setSelectedCageIndex] = useState<number | null>(null)
  const [validationResult, setValidationResult] = useState<{
    isValid?: boolean
    hasUniqueSolution?: boolean
    errors: ValidationError[]
  }>({ errors: [] })

  // Build a map of cell -> cage index for quick lookup
  const cellToCageMap = useMemo(() => {
    const map = new Map<string, number>()
    cages.forEach((cage, idx) => {
      cage.cells.forEach(([r, c]) => {
        map.set(`${r},${c}`, idx)
      })
    })
    return map
  }, [cages])

  // Compute cage colors using graph coloring (adjacent cages get different colors)
  const cageColors = useMemo(() => {
    return computeCageColors(cages, cellToCageMap)
  }, [cages, cellToCageMap])

  // Update parent when cages or solution changes
  useEffect(() => {
    onChange({
      grid: createEmptyGrid(),
      solution,
      cages,
      isValid: validationResult?.isValid && validationResult?.hasUniqueSolution
    })
  }, [cages, solution, onChange, validationResult])

  // Validation mutation
  const validateMutation = useMutation({
    mutationFn: (cagesData: Cage[]) => validateApi.validateKillerSudoku(cagesData),
    onSuccess: (response) => {
      const data = response.data
      setValidationResult({
        isValid: data.isValid,
        hasUniqueSolution: data.hasUniqueSolution,
        errors: data.errors,
      })
      if (data.isValid && data.solution) {
        setSolution(data.solution)
      }
    },
    onError: (error: any) => {
      setValidationResult({
        isValid: false,
        hasUniqueSolution: false,
        errors: [{ row: -1, col: -1, message: error.message || 'Validation failed' }],
      })
    },
  })

  // Solve mutation
  const solveMutation = useMutation({
    mutationFn: (cagesData: Cage[]) => validateApi.solveKillerSudoku(cagesData),
    onSuccess: (response) => {
      const data = response.data
      if (data.success && data.solution) {
        setSolution(data.solution)
        setValidationResult({
          isValid: true,
          hasUniqueSolution: true,
          errors: [],
        })
      } else {
        setValidationResult({
          isValid: false,
          hasUniqueSolution: false,
          errors: [{ row: -1, col: -1, message: data.error || 'Could not solve puzzle' }],
        })
      }
    },
    onError: (error: any) => {
      setValidationResult({
        isValid: false,
        hasUniqueSolution: false,
        errors: [{ row: -1, col: -1, message: error.message || 'Solve failed' }],
      })
    },
  })

  const handleCellSelect = useCallback((row: number, col: number) => {
    setSelectedCell([row, col])
  }, [])

  const handleAddCellToCage = useCallback(() => {
    if (selectedCell === null || selectedCageIndex === null) return

    const [row, col] = selectedCell
    const cellKey = `${row},${col}`

    // Check if cell is already in a cage
    if (cellToCageMap.has(cellKey)) {
      // Remove from existing cage first
      const existingCageIdx = cellToCageMap.get(cellKey)!
      setCages(prev => prev.map((cage, idx) => {
        if (idx === existingCageIdx) {
          return {
            ...cage,
            cells: cage.cells.filter(([r, c]) => !(r === row && c === col)),
          }
        }
        return cage
      }).filter(cage => cage.cells.length > 0))
    }

    // Add to selected cage
    setCages(prev => prev.map((cage, idx) => {
      if (idx === selectedCageIndex) {
        // Check if cell already in this cage
        if (cage.cells.some(([r, c]) => r === row && c === col)) {
          return cage
        }
        return {
          ...cage,
          cells: [...cage.cells, [row, col] as [number, number]],
        }
      }
      return cage
    }))

    setValidationResult({ errors: [] })
  }, [selectedCell, selectedCageIndex, cellToCageMap])

  const handleRemoveCellFromCage = useCallback(() => {
    if (selectedCell === null) return

    const [row, col] = selectedCell
    const cellKey = `${row},${col}`

    if (!cellToCageMap.has(cellKey)) return

    setCages(prev => prev.map(cage => ({
      ...cage,
      cells: cage.cells.filter(([r, c]) => !(r === row && c === col)),
    })).filter(cage => cage.cells.length > 0))

    setValidationResult({ errors: [] })
  }, [selectedCell, cellToCageMap])

  const handleAddCage = useCallback(() => {
    setCages(prev => [...prev, { sum: 0, cells: [] }])
    setSelectedCageIndex(cages.length)
    setValidationResult({ errors: [] })
  }, [cages.length])

  const handleDeleteCage = useCallback((index: number) => {
    setCages(prev => prev.filter((_, idx) => idx !== index))
    if (selectedCageIndex === index) {
      setSelectedCageIndex(null)
    } else if (selectedCageIndex !== null && selectedCageIndex > index) {
      setSelectedCageIndex(selectedCageIndex - 1)
    }
    setValidationResult({ errors: [] })
  }, [selectedCageIndex])

  const handleSumChange = useCallback((index: number, sum: number) => {
    setCages(prev => prev.map((cage, idx) => {
      if (idx === index) {
        return { ...cage, sum }
      }
      return cage
    }))
    setValidationResult({ errors: [] })
  }, [])

  const handleReset = useCallback(() => {
    setCages([])
    setSolution(createEmptyGrid())
    setSelectedCell(null)
    setSelectedCageIndex(null)
    setValidationResult({ errors: [] })
  }, [])

  const isLoading = validateMutation.isPending || solveMutation.isPending

  // Custom grid renderer for Killer Sudoku with cage visualization
  const renderGrid = () => {
    return (
      <div className="inline-block border-2 border-gray-700 dark:border-gray-400 rounded-lg overflow-hidden">
        <div className="grid grid-cols-9">
          {Array(9).fill(null).map((_, rowIdx) =>
            Array(9).fill(null).map((_, colIdx) => {
              const cellKey = `${rowIdx},${colIdx}`
              const cageIdx = cellToCageMap.get(cellKey)
              const isSelected = selectedCell?.[0] === rowIdx && selectedCell?.[1] === colIdx
              const isInSelectedCage = cageIdx === selectedCageIndex
              const colorClass = cageIdx !== undefined ? CAGE_COLORS[cageColors[cageIdx]] : 'bg-white dark:bg-gray-800'

              // Determine border styles for cage boundaries
              const cage = cageIdx !== undefined ? cages[cageIdx] : null
              const isTopEdge = cage && !cage.cells.some(([r, c]) => r === rowIdx - 1 && c === colIdx)
              const isBottomEdge = cage && !cage.cells.some(([r, c]) => r === rowIdx + 1 && c === colIdx)
              const isLeftEdge = cage && !cage.cells.some(([r, c]) => r === rowIdx && c === colIdx - 1)
              const isRightEdge = cage && !cage.cells.some(([r, c]) => r === rowIdx && c === colIdx + 1)

              // Check if this is the top-left cell of the cage (to show sum)
              const isTopLeftOfCage = cage && cage.cells.length > 0 &&
                cage.cells.every(([r, c]) => r > rowIdx || (r === rowIdx && c >= colIdx))

              return (
                <button
                  key={`${rowIdx}-${colIdx}`}
                  type="button"
                  className={`
                    w-10 h-10 flex items-center justify-center text-lg font-semibold relative
                    border border-gray-300 dark:border-gray-600
                    transition-colors duration-100
                    ${colIdx % 3 === 0 && colIdx !== 0 ? 'border-l-2 border-l-gray-500 dark:border-l-gray-400' : ''}
                    ${rowIdx % 3 === 0 && rowIdx !== 0 ? 'border-t-2 border-t-gray-500 dark:border-t-gray-400' : ''}
                    ${isSelected ? 'ring-2 ring-blue-500 z-10' : ''}
                    ${isInSelectedCage ? 'ring-1 ring-green-500' : ''}
                    ${colorClass}
                    ${isTopEdge ? 'border-t-2 border-t-gray-800 dark:border-t-gray-200' : ''}
                    ${isBottomEdge ? 'border-b-2 border-b-gray-800 dark:border-b-gray-200' : ''}
                    ${isLeftEdge ? 'border-l-2 border-l-gray-800 dark:border-l-gray-200' : ''}
                    ${isRightEdge ? 'border-r-2 border-r-gray-800 dark:border-r-gray-200' : ''}
                    cursor-pointer hover:brightness-95
                  `}
                  onClick={() => handleCellSelect(rowIdx, colIdx)}
                >
                  {isTopLeftOfCage && cage && (
                    <span className="absolute top-0 left-0.5 text-[10px] font-bold text-gray-700 dark:text-gray-300">
                      {cage.sum || '?'}
                    </span>
                  )}
                  {solution[rowIdx][colIdx] !== 0 && (
                    <span className="text-gray-400 text-sm">
                      {solution[rowIdx][colIdx]}
                    </span>
                  )}
                </button>
              )
            })
          )}
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap gap-8">
        {/* Main Grid */}
        <div className="space-y-4">
          <h3 className="font-medium text-gray-900 dark:text-white">Killer Sudoku Grid</h3>
          {renderGrid()}
          <p className="text-sm text-gray-500 dark:text-gray-400">
            Click cells to select. Use cage list to assign cells to cages.
          </p>
        </div>

        {/* Cage Management */}
        <div className="space-y-4 min-w-[280px]">
          <div className="flex items-center justify-between">
            <h3 className="font-medium text-gray-900 dark:text-white">Cages</h3>
            <button
              type="button"
              onClick={handleAddCage}
              className="btn btn-secondary text-sm"
            >
              <Plus className="w-4 h-4" />
              Add Cage
            </button>
          </div>

          <div className="max-h-80 overflow-y-auto space-y-2">
            {cages.map((cage, idx) => (
              <div
                key={idx}
                className={`p-3 rounded-lg border-2 cursor-pointer transition-colors ${
                  selectedCageIndex === idx
                    ? 'border-green-500'
                    : 'border-gray-200 dark:border-gray-700 hover:border-gray-300'
                } ${CAGE_COLORS[cageColors[idx] ?? 0]}`}
                onClick={() => setSelectedCageIndex(idx)}
              >
                <div className="flex items-center justify-between gap-2">
                  <div className="flex items-center gap-2">
                    <span className="text-sm font-medium">Cage {idx + 1}</span>
                    <span className="text-xs text-gray-500">({cage.cells.length} cells)</span>
                  </div>
                  <button
                    type="button"
                    onClick={(e) => {
                      e.stopPropagation()
                      handleDeleteCage(idx)
                    }}
                    className="p-1 text-red-500 hover:bg-red-100 dark:hover:bg-red-900/30 rounded"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
                <div className="mt-2 flex items-center gap-2">
                  <label className="text-xs text-gray-600 dark:text-gray-400">Sum:</label>
                  <input
                    type="number"
                    min="1"
                    max="45"
                    value={cage.sum || ''}
                    onChange={(e) => handleSumChange(idx, parseInt(e.target.value) || 0)}
                    onClick={(e) => e.stopPropagation()}
                    className="w-16 px-2 py-1 text-sm border rounded dark:bg-gray-800 dark:border-gray-600"
                    placeholder="0"
                  />
                </div>
              </div>
            ))}
            {cages.length === 0 && (
              <p className="text-sm text-gray-500 dark:text-gray-400 text-center py-4">
                No cages yet. Click "Add Cage" to start.
              </p>
            )}
          </div>

          {/* Cell Assignment Buttons */}
          <div className="flex gap-2">
            <button
              type="button"
              onClick={handleAddCellToCage}
              disabled={selectedCell === null || selectedCageIndex === null}
              className="btn btn-secondary text-sm flex-1"
            >
              Add Cell to Cage
            </button>
            <button
              type="button"
              onClick={handleRemoveCellFromCage}
              disabled={selectedCell === null || !cellToCageMap.has(`${selectedCell?.[0]},${selectedCell?.[1]}`)}
              className="btn btn-secondary text-sm flex-1"
            >
              Remove Cell
            </button>
          </div>
        </div>

        {/* Solution Grid (read-only) */}
        <div className="space-y-4">
          <h3 className="font-medium text-gray-900 dark:text-white">Solution</h3>
          <GridEditor
            grid={solution}
            selectedCell={null}
            onCellSelect={() => {}}
            readonly
          />
          <p className="text-sm text-gray-500 dark:text-gray-400">
            Generated solution (read-only)
          </p>
        </div>
      </div>

      {/* Action Buttons */}
      <div className="flex flex-wrap gap-3">
        <button
          type="button"
          onClick={() => validateMutation.mutate(cages)}
          disabled={isLoading || cages.length === 0}
          className="btn btn-secondary"
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
          onClick={() => solveMutation.mutate(cages)}
          disabled={isLoading || cages.length === 0}
          className="btn btn-primary"
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
          onClick={handleReset}
          disabled={isLoading}
          className="btn btn-secondary"
        >
          <RotateCcw className="w-4 h-4" />
          Reset
        </button>
      </div>

      {/* Validation Status */}
      <ValidationStatus
        isValidating={isLoading}
        isValid={validationResult.isValid}
        hasUniqueSolution={validationResult.hasUniqueSolution}
        errors={validationResult.errors}
      />
    </div>
  )
}
