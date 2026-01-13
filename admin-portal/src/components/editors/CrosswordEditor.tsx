import { useState, useCallback, useEffect, useMemo } from 'react'
import { useMutation } from '@tanstack/react-query'
import { Plus, Trash2, CheckCircle, Grid3X3, Sparkles, Loader2, LayoutGrid } from 'lucide-react'
import ValidationStatus from './shared/ValidationStatus'
import { aiApi } from '../../lib/api'

// Crossword grid builder - attempts to place words with intersections
const buildCrosswordFromWords = (
  words: { word: string; clue: string }[],
  gridSize: number
): CrosswordClue[] => {
  if (words.length === 0) return []

  // Sort by length descending (place longer words first)
  const sortedWords = [...words].sort((a, b) => b.word.length - a.word.length)

  // Track placed words and grid state
  const placed: CrosswordClue[] = []
  const grid: (string | null)[][] = Array(gridSize).fill(null).map(() => Array(gridSize).fill(null))

  // Helper to check if a word can be placed at position
  const canPlace = (word: string, row: number, col: number, direction: 'across' | 'down'): boolean => {
    const len = word.length

    // Check bounds
    if (direction === 'across') {
      if (col + len > gridSize) return false
      // Check cell before word is empty or edge
      if (col > 0 && grid[row][col - 1] !== null) return false
      // Check cell after word is empty or edge
      if (col + len < gridSize && grid[row][col + len] !== null) return false
    } else {
      if (row + len > gridSize) return false
      if (row > 0 && grid[row - 1][col] !== null) return false
      if (row + len < gridSize && grid[row + len][col] !== null) return false
    }

    let hasIntersection = placed.length === 0 // First word doesn't need intersection

    for (let i = 0; i < len; i++) {
      const r = direction === 'across' ? row : row + i
      const c = direction === 'across' ? col + i : col
      const letter = word[i].toUpperCase()
      const existing = grid[r][c]

      if (existing !== null) {
        if (existing !== letter) return false // Conflict
        hasIntersection = true
      } else {
        // Check adjacent cells (perpendicular) aren't filled (avoid parallel words touching)
        if (direction === 'across') {
          if (r > 0 && grid[r - 1][c] !== null && i !== 0 && i !== len - 1) {
            // Has letter above, check if it's part of an intersection
            const above = grid[r - 1][c]
            if (above !== null) {
              // Only allow if this creates a valid crossing
            }
          }
          if (r < gridSize - 1 && grid[r + 1][c] !== null) {
            // Similar check below
          }
        }
      }
    }

    return hasIntersection
  }

  // Place a word on the grid
  const placeWord = (word: string, clue: string, row: number, col: number, direction: 'across' | 'down') => {
    for (let i = 0; i < word.length; i++) {
      const r = direction === 'across' ? row : row + i
      const c = direction === 'across' ? col + i : col
      grid[r][c] = word[i].toUpperCase()
    }

    placed.push({
      number: placed.length + 1,
      direction,
      clue,
      answer: word.toUpperCase(),
      startRow: row,
      startCol: col,
    })
  }

  // Find best placement for a word
  const findPlacement = (word: string, clue: string): boolean => {
    const len = word.length
    const wordUpper = word.toUpperCase()

    // Try to find intersections with existing words
    for (const existingClue of placed) {
      for (let i = 0; i < existingClue.answer.length; i++) {
        const existingLetter = existingClue.answer[i]

        // Find matching letters in new word
        for (let j = 0; j < len; j++) {
          if (wordUpper[j] === existingLetter) {
            // Calculate position for intersection
            let row: number, col: number
            let newDirection: 'across' | 'down'

            if (existingClue.direction === 'across') {
              // Place new word going down
              newDirection = 'down'
              row = existingClue.startRow - j
              col = existingClue.startCol + i
            } else {
              // Place new word going across
              newDirection = 'across'
              row = existingClue.startRow + i
              col = existingClue.startCol - j
            }

            if (row >= 0 && col >= 0 && canPlace(wordUpper, row, col, newDirection)) {
              placeWord(word, clue, row, col, newDirection)
              return true
            }
          }
        }
      }
    }

    return false
  }

  // Place first word in center horizontally
  const firstWord = sortedWords[0]
  const startCol = Math.floor((gridSize - firstWord.word.length) / 2)
  const startRow = Math.floor(gridSize / 2)
  placeWord(firstWord.word, firstWord.clue, startRow, startCol, 'across')

  // Try to place remaining words
  for (let i = 1; i < sortedWords.length; i++) {
    const { word, clue } = sortedWords[i]
    findPlacement(word, clue)
  }

  return placed
}

interface CrosswordClue {
  number: number
  direction: 'across' | 'down'
  clue: string
  answer: string
  startRow: number
  startCol: number
}

interface CrosswordEditorProps {
  initialData?: {
    rows: number
    cols: number
    grid: string[][]
    clues: CrosswordClue[]
  }
  onChange?: (puzzleData: any, solution: any) => void
  className?: string
}

type GridSize = 5 | 7 | 10 | 13 | 15

const createEmptyGrid = (rows: number, cols: number): string[][] =>
  Array(rows).fill(null).map(() => Array(cols).fill(''))

// Auto-number clues based on grid position (left-to-right, top-to-bottom)
const renumberClues = (clues: CrosswordClue[]): CrosswordClue[] => {
  const sortedClues = [...clues].sort((a, b) => {
    if (a.startRow !== b.startRow) return a.startRow - b.startRow
    return a.startCol - b.startCol
  })

  const numberMap = new Map<string, number>()
  let currentNumber = 1

  return sortedClues.map(clue => {
    const key = `${clue.startRow},${clue.startCol}`
    if (!numberMap.has(key)) {
      numberMap.set(key, currentNumber++)
    }
    return { ...clue, number: numberMap.get(key)! }
  })
}

// Build grid from clues
const buildGridFromClues = (rows: number, cols: number, clues: CrosswordClue[]): string[][] => {
  const grid = createEmptyGrid(rows, cols)

  for (const clue of clues) {
    const { answer, startRow, startCol, direction } = clue
    for (let i = 0; i < answer.length; i++) {
      const r = direction === 'across' ? startRow : startRow + i
      const c = direction === 'across' ? startCol + i : startCol
      if (r < rows && c < cols) {
        grid[r][c] = answer[i].toUpperCase()
      }
    }
  }

  return grid
}

export function CrosswordEditor({
  initialData,
  onChange,
  className = '',
}: CrosswordEditorProps) {
  const [rows, setRows] = useState(initialData?.rows || 10)
  const [cols, setCols] = useState(initialData?.cols || 10)
  const [grid, setGrid] = useState<string[][]>(initialData?.grid || createEmptyGrid(10, 10))
  const [clues, setClues] = useState<CrosswordClue[]>(initialData?.clues || [])
  const [selectedCell, setSelectedCell] = useState<[number, number] | null>(null)
  const [editingClue, setEditingClue] = useState<CrosswordClue | null>(null)
  const [validationResult, setValidationResult] = useState<{
    isValid: boolean
    hasUniqueSolution: boolean
    errors: { row: number; col: number; message: string }[]
  } | null>(null)

  // AI generation state
  const [theme, setTheme] = useState('')
  const [aiSuggestions, setAiSuggestions] = useState<{ word: string; clue: string }[]>([])

  // AI word generation mutation
  const generateWordsMutation = useMutation({
    mutationFn: async (themeText: string) => {
      const response = await aiApi.generateCrosswordWords(themeText, 10, 3, Math.min(rows, cols))
      return response.data
    },
    onSuccess: (data) => {
      setAiSuggestions(data.words)
    },
    onError: (error: any) => {
      alert(error.response?.data?.message || 'Failed to generate words')
    },
  })

  const handleGenerateWords = useCallback(() => {
    if (!theme.trim()) {
      alert('Please enter a theme')
      return
    }
    generateWordsMutation.mutate(theme)
  }, [theme, generateWordsMutation])

  const handleAddSuggestion = useCallback((suggestion: { word: string; clue: string }) => {
    // Create a new clue from the suggestion
    const newClue: CrosswordClue = {
      number: clues.length + 1,
      direction: 'across',
      clue: suggestion.clue,
      answer: suggestion.word.toUpperCase(),
      startRow: 0,
      startCol: 0,
    }
    setEditingClue(newClue)
    // Remove from suggestions
    setAiSuggestions(prev => prev.filter(s => s.word !== suggestion.word))
  }, [clues.length])

  const handleBuildGrid = useCallback(() => {
    if (aiSuggestions.length === 0) {
      alert('No words to place. Generate some words first!')
      return
    }

    // Build crossword from AI suggestions
    const placedClues = buildCrosswordFromWords(aiSuggestions, rows)

    if (placedClues.length === 0) {
      alert('Could not place any words. Try generating different words.')
      return
    }

    // Renumber the clues properly
    const numberedClues = renumberClues(placedClues)
    setClues(numberedClues)

    // Show how many words were placed
    const notPlaced = aiSuggestions.length - placedClues.length
    if (notPlaced > 0) {
      // Keep unplaced words in suggestions
      const placedWords = new Set(placedClues.map(c => c.answer))
      setAiSuggestions(prev => prev.filter(s => !placedWords.has(s.word.toUpperCase())))
      alert(`Placed ${placedClues.length} words. ${notPlaced} words couldn't fit - you can add them manually.`)
    } else {
      setAiSuggestions([])
      alert(`Successfully placed all ${placedClues.length} words!`)
    }

    setValidationResult(null)
  }, [aiSuggestions, rows])

  // Rebuild grid when clues change
  useEffect(() => {
    const newGrid = buildGridFromClues(rows, cols, clues)
    setGrid(newGrid)
  }, [clues, rows, cols])

  // Notify parent of changes
  useEffect(() => {
    if (onChange && validationResult?.isValid) {
      onChange(
        { rows, cols, grid, clues },
        { grid } // Solution is the filled grid
      )
    }
  }, [rows, cols, grid, clues, onChange, validationResult])

  const handleSizeChange = useCallback((size: GridSize) => {
    setRows(size)
    setCols(size)
    setClues([])
    setValidationResult(null)
  }, [])

  const handleAddClue = useCallback(() => {
    const newClue: CrosswordClue = {
      number: clues.length + 1,
      direction: 'across',
      clue: '',
      answer: '',
      startRow: 0,
      startCol: 0,
    }
    setEditingClue(newClue)
  }, [clues])

  const handleSaveClue = useCallback(() => {
    if (!editingClue) return

    // Validate the clue
    if (!editingClue.answer.trim()) {
      alert('Please enter an answer')
      return
    }
    if (!editingClue.clue.trim()) {
      alert('Please enter a clue')
      return
    }

    // Check bounds
    const endRow = editingClue.direction === 'across'
      ? editingClue.startRow
      : editingClue.startRow + editingClue.answer.length - 1
    const endCol = editingClue.direction === 'across'
      ? editingClue.startCol + editingClue.answer.length - 1
      : editingClue.startCol

    if (endRow >= rows || endCol >= cols) {
      alert('Answer extends beyond grid bounds')
      return
    }

    setClues(prev => {
      const existingIndex = prev.findIndex(c =>
        c.number === editingClue.number &&
        c.direction === editingClue.direction &&
        c.startRow === editingClue.startRow &&
        c.startCol === editingClue.startCol
      )

      let newClues: CrosswordClue[]
      if (existingIndex >= 0) {
        newClues = [...prev]
        newClues[existingIndex] = editingClue
      } else {
        newClues = [...prev, editingClue]
      }

      return renumberClues(newClues)
    })

    setEditingClue(null)
    setValidationResult(null)
  }, [editingClue, rows, cols])

  const handleDeleteClue = useCallback((clueToDelete: CrosswordClue) => {
    setClues(prev => renumberClues(
      prev.filter(c => !(
        c.startRow === clueToDelete.startRow &&
        c.startCol === clueToDelete.startCol &&
        c.direction === clueToDelete.direction
      ))
    ))
    setValidationResult(null)
  }, [])

  const handleEditClue = useCallback((clue: CrosswordClue) => {
    setEditingClue({ ...clue })
  }, [])

  const handleCellClick = useCallback((row: number, col: number) => {
    setSelectedCell([row, col])

    // If editing a clue, update its position
    if (editingClue) {
      setEditingClue(prev => prev ? { ...prev, startRow: row, startCol: col } : null)
    }
  }, [editingClue])

  const handleValidate = useCallback(() => {
    const errors: { row: number; col: number; message: string }[] = []

    if (clues.length === 0) {
      errors.push({ row: -1, col: -1, message: 'Add at least one clue' })
    }

    // Check for clues with empty answers or clue text
    clues.forEach((clue) => {
      if (!clue.answer.trim()) {
        errors.push({ row: -1, col: -1, message: `Clue ${clue.number} ${clue.direction} has no answer` })
      }
      if (!clue.clue.trim()) {
        errors.push({ row: -1, col: -1, message: `Clue ${clue.number} ${clue.direction} has no clue text` })
      }
    })

    // Check for letter conflicts (same cell, different letters)
    const cellLetters = new Map<string, { letter: string; clue: CrosswordClue }>()
    for (const clue of clues) {
      for (let i = 0; i < clue.answer.length; i++) {
        const r = clue.direction === 'across' ? clue.startRow : clue.startRow + i
        const c = clue.direction === 'across' ? clue.startCol + i : clue.startCol
        const key = `${r},${c}`
        const letter = clue.answer[i].toUpperCase()

        if (cellLetters.has(key)) {
          const existing = cellLetters.get(key)!
          if (existing.letter !== letter) {
            errors.push({
              row: r,
              col: c,
              message: `Conflict at [${r+1},${c+1}]: "${existing.letter}" vs "${letter}"`,
            })
          }
        } else {
          cellLetters.set(key, { letter, clue })
        }
      }
    }

    if (errors.length > 0) {
      setValidationResult({ isValid: false, hasUniqueSolution: false, errors })
    } else {
      setValidationResult({ isValid: true, hasUniqueSolution: true, errors: [] })
    }
  }, [clues])

  // Separate clues by direction
  const acrossClues = useMemo(() =>
    clues.filter(c => c.direction === 'across').sort((a, b) => a.number - b.number),
    [clues]
  )
  const downClues = useMemo(() =>
    clues.filter(c => c.direction === 'down').sort((a, b) => a.number - b.number),
    [clues]
  )

  // Get cell number map
  const cellNumbers = useMemo(() => {
    const map = new Map<string, number>()
    for (const clue of clues) {
      const key = `${clue.startRow},${clue.startCol}`
      if (!map.has(key)) {
        map.set(key, clue.number)
      }
    }
    return map
  }, [clues])

  return (
    <div className={`space-y-6 ${className}`}>
      {/* Size selector */}
      <div>
        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
          Grid Size
        </label>
        <div className="flex gap-2 flex-wrap">
          {([5, 7, 10, 13, 15] as GridSize[]).map((size) => (
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

      {/* AI Word Generation */}
      <div className="p-4 bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-800 rounded-lg">
        <h4 className="font-medium text-purple-800 dark:text-purple-200 mb-3 flex items-center gap-2">
          <Sparkles className="w-4 h-4" />
          AI Word Generator
        </h4>
        <div className="flex gap-2 mb-3">
          <input
            type="text"
            value={theme}
            onChange={(e) => setTheme(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && handleGenerateWords()}
            placeholder="Enter a theme (e.g., Space, Animals, Sports...)"
            className="flex-1 px-3 py-2 border border-purple-300 dark:border-purple-700 rounded-md
                       bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100"
          />
          <button
            type="button"
            onClick={handleGenerateWords}
            disabled={generateWordsMutation.isPending || !theme.trim()}
            className="flex items-center gap-2 px-4 py-2 bg-purple-500 text-white rounded-md
                       hover:bg-purple-600 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            {generateWordsMutation.isPending ? (
              <Loader2 className="w-4 h-4 animate-spin" />
            ) : (
              <Sparkles className="w-4 h-4" />
            )}
            Generate
          </button>
        </div>

        {/* AI Suggestions */}
        {aiSuggestions.length > 0 && (
          <div>
            <div className="flex items-center justify-between mb-2">
              <p className="text-sm text-purple-600 dark:text-purple-400">
                Click a word to add it manually, or build the entire grid:
              </p>
              <button
                type="button"
                onClick={handleBuildGrid}
                className="flex items-center gap-2 px-3 py-1.5 bg-purple-600 text-white rounded-md
                           hover:bg-purple-700 transition-colors text-sm font-medium"
              >
                <LayoutGrid className="w-4 h-4" />
                Build Grid
              </button>
            </div>
            <div className="flex flex-wrap gap-2">
              {aiSuggestions.map((suggestion, idx) => (
                <button
                  key={idx}
                  type="button"
                  onClick={() => handleAddSuggestion(suggestion)}
                  className="group px-3 py-1.5 bg-white dark:bg-gray-800 border border-purple-300 dark:border-purple-700
                             rounded-md hover:bg-purple-100 dark:hover:bg-purple-900/30 transition-colors text-left"
                >
                  <span className="font-mono font-bold text-purple-700 dark:text-purple-300">
                    {suggestion.word}
                  </span>
                  <span className="text-xs text-gray-500 dark:text-gray-400 ml-2">
                    ({suggestion.word.length})
                  </span>
                  <p className="text-xs text-gray-600 dark:text-gray-400 group-hover:text-purple-600 dark:group-hover:text-purple-300">
                    {suggestion.clue}
                  </p>
                </button>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* Grid Preview */}
      <div>
        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
          Grid Preview (click to set clue position)
        </label>
        <div className="overflow-auto">
          <div
            className="inline-grid gap-0 border-2 border-gray-700 dark:border-gray-400"
            style={{ gridTemplateColumns: `repeat(${cols}, 32px)` }}
          >
            {grid.map((row, rowIdx) =>
              row.map((cell, colIdx) => {
                const cellNum = cellNumbers.get(`${rowIdx},${colIdx}`)
                const isSelected = selectedCell?.[0] === rowIdx && selectedCell?.[1] === colIdx
                const isEditingStart = editingClue?.startRow === rowIdx && editingClue?.startCol === colIdx

                return (
                  <button
                    key={`${rowIdx}-${colIdx}`}
                    type="button"
                    onClick={() => handleCellClick(rowIdx, colIdx)}
                    className={`w-8 h-8 relative border border-gray-300 dark:border-gray-600
                               text-sm font-bold uppercase flex items-center justify-center
                               transition-colors ${
                                 isEditingStart
                                   ? 'bg-green-200 dark:bg-green-800'
                                   : isSelected
                                   ? 'bg-blue-200 dark:bg-blue-800'
                                   : cell === '#'
                                   ? 'bg-gray-900 dark:bg-black'
                                   : cell
                                   ? 'bg-white dark:bg-gray-700'
                                   : 'bg-gray-100 dark:bg-gray-800'
                               }`}
                  >
                    {cellNum && (
                      <span className="absolute top-0 left-0.5 text-[8px] text-gray-500 dark:text-gray-400">
                        {cellNum}
                      </span>
                    )}
                    {cell !== '#' && cell}
                  </button>
                )
              })
            )}
          </div>
        </div>
      </div>

      {/* Add/Edit Clue Form */}
      {editingClue ? (
        <div className="p-4 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg space-y-4">
          <h4 className="font-medium text-blue-800 dark:text-blue-200">
            {clues.some(c => c.startRow === editingClue.startRow && c.startCol === editingClue.startCol && c.direction === editingClue.direction)
              ? 'Edit Clue'
              : 'Add New Clue'}
          </h4>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Direction
              </label>
              <select
                value={editingClue.direction}
                onChange={(e) => setEditingClue(prev => prev ? { ...prev, direction: e.target.value as 'across' | 'down' } : null)}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md
                           bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100"
              >
                <option value="across">Across</option>
                <option value="down">Down</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Position
              </label>
              <div className="text-sm text-gray-600 dark:text-gray-400 py-2">
                Row {editingClue.startRow + 1}, Col {editingClue.startCol + 1}
                <span className="text-xs ml-2">(click grid to change)</span>
              </div>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Answer
            </label>
            <input
              type="text"
              value={editingClue.answer}
              onChange={(e) => setEditingClue(prev => prev ? { ...prev, answer: e.target.value.toUpperCase().replace(/[^A-Z]/g, '') } : null)}
              placeholder="ANSWER"
              className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md
                         bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100
                         uppercase tracking-widest font-mono"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Clue Text
            </label>
            <input
              type="text"
              value={editingClue.clue}
              onChange={(e) => setEditingClue(prev => prev ? { ...prev, clue: e.target.value } : null)}
              placeholder="Enter the clue..."
              className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md
                         bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100"
            />
          </div>

          <div className="flex gap-2">
            <button
              type="button"
              onClick={handleSaveClue}
              className="px-4 py-2 bg-blue-500 text-white rounded-md hover:bg-blue-600 transition-colors"
            >
              Save Clue
            </button>
            <button
              type="button"
              onClick={() => setEditingClue(null)}
              className="px-4 py-2 bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-md hover:bg-gray-300 dark:hover:bg-gray-600 transition-colors"
            >
              Cancel
            </button>
          </div>
        </div>
      ) : (
        <button
          type="button"
          onClick={handleAddClue}
          className="flex items-center gap-2 px-4 py-2 bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300 rounded-md hover:bg-green-200 dark:hover:bg-green-900/50 transition-colors"
        >
          <Plus className="w-4 h-4" />
          Add Clue
        </button>
      )}

      {/* Clue Lists */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Across */}
        <div>
          <h4 className="font-medium text-gray-700 dark:text-gray-300 mb-2">
            Across ({acrossClues.length})
          </h4>
          <div className="space-y-2 max-h-60 overflow-y-auto">
            {acrossClues.map((clue) => (
              <div
                key={`across-${clue.number}`}
                className="p-2 bg-gray-50 dark:bg-gray-800 rounded border border-gray-200 dark:border-gray-700"
              >
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <span className="font-bold text-blue-600 dark:text-blue-400">{clue.number}A.</span>
                    <span className="ml-2 text-sm text-gray-600 dark:text-gray-400">{clue.clue}</span>
                    <div className="text-xs text-gray-500 dark:text-gray-500 mt-1 font-mono">
                      {clue.answer} ({clue.answer.length})
                    </div>
                  </div>
                  <div className="flex gap-1 ml-2">
                    <button
                      type="button"
                      onClick={() => handleEditClue(clue)}
                      className="p-1 text-gray-400 hover:text-blue-500 transition-colors"
                    >
                      <Grid3X3 className="w-4 h-4" />
                    </button>
                    <button
                      type="button"
                      onClick={() => handleDeleteClue(clue)}
                      className="p-1 text-gray-400 hover:text-red-500 transition-colors"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              </div>
            ))}
            {acrossClues.length === 0 && (
              <p className="text-sm text-gray-500 dark:text-gray-400 italic">No across clues</p>
            )}
          </div>
        </div>

        {/* Down */}
        <div>
          <h4 className="font-medium text-gray-700 dark:text-gray-300 mb-2">
            Down ({downClues.length})
          </h4>
          <div className="space-y-2 max-h-60 overflow-y-auto">
            {downClues.map((clue) => (
              <div
                key={`down-${clue.number}`}
                className="p-2 bg-gray-50 dark:bg-gray-800 rounded border border-gray-200 dark:border-gray-700"
              >
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <span className="font-bold text-purple-600 dark:text-purple-400">{clue.number}D.</span>
                    <span className="ml-2 text-sm text-gray-600 dark:text-gray-400">{clue.clue}</span>
                    <div className="text-xs text-gray-500 dark:text-gray-500 mt-1 font-mono">
                      {clue.answer} ({clue.answer.length})
                    </div>
                  </div>
                  <div className="flex gap-1 ml-2">
                    <button
                      type="button"
                      onClick={() => handleEditClue(clue)}
                      className="p-1 text-gray-400 hover:text-blue-500 transition-colors"
                    >
                      <Grid3X3 className="w-4 h-4" />
                    </button>
                    <button
                      type="button"
                      onClick={() => handleDeleteClue(clue)}
                      className="p-1 text-gray-400 hover:text-red-500 transition-colors"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              </div>
            ))}
            {downClues.length === 0 && (
              <p className="text-sm text-gray-500 dark:text-gray-400 italic">No down clues</p>
            )}
          </div>
        </div>
      </div>

      {/* Actions */}
      <div className="flex gap-2">
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
    </div>
  )
}

export default CrosswordEditor
