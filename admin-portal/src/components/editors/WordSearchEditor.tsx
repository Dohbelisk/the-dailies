import { useState, useCallback, useEffect, useMemo } from 'react'
import { Plus, Trash2, CheckCircle, Shuffle, Wand2 } from 'lucide-react'
import ValidationStatus from './shared/ValidationStatus'

interface WordSearchWord {
  word: string
  startRow: number
  startCol: number
  endRow: number
  endCol: number
}

interface WordSearchEditorProps {
  initialData?: {
    rows: number
    cols: number
    theme?: string
    grid: string[][]
    words: WordSearchWord[]
  }
  onChange?: (puzzleData: any, solution: any) => void
  className?: string
}

type GridSize = 8 | 10 | 12 | 15

// Direction vectors for 8 directions
const DIRECTIONS = [
  { name: 'Right', dr: 0, dc: 1 },
  { name: 'Down', dr: 1, dc: 0 },
  { name: 'Down-Right', dr: 1, dc: 1 },
  { name: 'Down-Left', dr: 1, dc: -1 },
  { name: 'Left', dr: 0, dc: -1 },
  { name: 'Up', dr: -1, dc: 0 },
  { name: 'Up-Right', dr: -1, dc: 1 },
  { name: 'Up-Left', dr: -1, dc: -1 },
]

const createEmptyGrid = (rows: number, cols: number): string[][] =>
  Array(rows).fill(null).map(() => Array(cols).fill(''))

// Fill empty cells with random letters
const fillRandomLetters = (grid: string[][]): string[][] => {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  return grid.map(row =>
    row.map(cell => cell || alphabet[Math.floor(Math.random() * 26)])
  )
}

// Try to place a word in the grid
const placeWord = (
  grid: string[][],
  word: string,
  startRow: number,
  startCol: number,
  direction: { dr: number; dc: number }
): { success: boolean; endRow: number; endCol: number } => {
  const rows = grid.length
  const cols = grid[0].length

  // Check if word fits
  const endRow = startRow + direction.dr * (word.length - 1)
  const endCol = startCol + direction.dc * (word.length - 1)

  if (endRow < 0 || endRow >= rows || endCol < 0 || endCol >= cols) {
    return { success: false, endRow: -1, endCol: -1 }
  }

  // Check for conflicts
  for (let i = 0; i < word.length; i++) {
    const r = startRow + direction.dr * i
    const c = startCol + direction.dc * i
    const existing = grid[r][c]
    if (existing && existing !== word[i]) {
      return { success: false, endRow: -1, endCol: -1 }
    }
  }

  // Place the word
  for (let i = 0; i < word.length; i++) {
    const r = startRow + direction.dr * i
    const c = startCol + direction.dc * i
    grid[r][c] = word[i]
  }

  return { success: true, endRow, endCol }
}

// Try to place a word randomly
const placeWordRandomly = (
  grid: string[][],
  word: string
): { success: boolean; startRow: number; startCol: number; endRow: number; endCol: number } => {
  const rows = grid.length
  const cols = grid[0].length
  const shuffledDirections = [...DIRECTIONS].sort(() => Math.random() - 0.5)

  // Try multiple random positions
  for (let attempt = 0; attempt < 100; attempt++) {
    const startRow = Math.floor(Math.random() * rows)
    const startCol = Math.floor(Math.random() * cols)
    const direction = shuffledDirections[attempt % shuffledDirections.length]

    const gridCopy = grid.map(row => [...row])
    const result = placeWord(gridCopy, word, startRow, startCol, direction)

    if (result.success) {
      // Copy back to original grid
      for (let r = 0; r < rows; r++) {
        for (let c = 0; c < cols; c++) {
          grid[r][c] = gridCopy[r][c]
        }
      }
      return { success: true, startRow, startCol, endRow: result.endRow, endCol: result.endCol }
    }
  }

  return { success: false, startRow: -1, startCol: -1, endRow: -1, endCol: -1 }
}

export function WordSearchEditor({
  initialData,
  onChange,
  className = '',
}: WordSearchEditorProps) {
  const [rows, setRows] = useState(initialData?.rows || 10)
  const [cols, setCols] = useState(initialData?.cols || 10)
  const [theme, setTheme] = useState(initialData?.theme || '')
  const [grid, setGrid] = useState<string[][]>(initialData?.grid || createEmptyGrid(10, 10))
  const [words, setWords] = useState<WordSearchWord[]>(initialData?.words || [])
  const [newWord, setNewWord] = useState('')
  const [validationResult, setValidationResult] = useState<{
    isValid: boolean
    hasUniqueSolution: boolean
    errors: { row: number; col: number; message: string }[]
  } | null>(null)

  // Notify parent of changes
  useEffect(() => {
    if (onChange && validationResult?.isValid) {
      onChange(
        { rows, cols, theme, grid, words },
        { words }
      )
    }
  }, [rows, cols, theme, grid, words, onChange, validationResult])

  const handleSizeChange = useCallback((size: GridSize) => {
    setRows(size)
    setCols(size)
    setGrid(createEmptyGrid(size, size))
    setWords([])
    setValidationResult(null)
  }, [])

  const handleAddWord = useCallback(() => {
    const word = newWord.toUpperCase().replace(/[^A-Z]/g, '')
    if (!word || word.length < 3) {
      alert('Word must be at least 3 letters')
      return
    }

    if (words.some(w => w.word === word)) {
      alert('Word already added')
      return
    }

    // Try to place the word
    const gridCopy = grid.map(row => [...row])
    const result = placeWordRandomly(gridCopy, word)

    if (result.success) {
      setGrid(gridCopy)
      setWords(prev => [...prev, {
        word,
        startRow: result.startRow,
        startCol: result.startCol,
        endRow: result.endRow,
        endCol: result.endCol,
      }])
      setNewWord('')
      setValidationResult(null)
    } else {
      alert('Could not place word in grid. Try a smaller word or larger grid.')
    }
  }, [newWord, grid, words])

  const handleRemoveWord = useCallback((wordToRemove: string) => {
    // Rebuild grid without this word
    const remainingWords = words.filter(w => w.word !== wordToRemove)
    const newGrid = createEmptyGrid(rows, cols)

    // Re-place remaining words
    const newWordsList: WordSearchWord[] = []
    for (const w of remainingWords) {
      const result = placeWordRandomly(newGrid, w.word)
      if (result.success) {
        newWordsList.push({
          word: w.word,
          startRow: result.startRow,
          startCol: result.startCol,
          endRow: result.endRow,
          endCol: result.endCol,
        })
      }
    }

    setGrid(newGrid)
    setWords(newWordsList)
    setValidationResult(null)
  }, [words, rows, cols])

  const handleFillGrid = useCallback(() => {
    setGrid(prev => fillRandomLetters(prev.map(row => [...row])))
    setValidationResult(null)
  }, [])

  const handleClearGrid = useCallback(() => {
    // Keep word positions but clear filler letters
    const newGrid = createEmptyGrid(rows, cols)
    for (const w of words) {
      const dr = w.endRow === w.startRow ? 0 : (w.endRow > w.startRow ? 1 : -1)
      const dc = w.endCol === w.startCol ? 0 : (w.endCol > w.startCol ? 1 : -1)
      for (let i = 0; i < w.word.length; i++) {
        const r = w.startRow + dr * i
        const c = w.startCol + dc * i
        newGrid[r][c] = w.word[i]
      }
    }
    setGrid(newGrid)
    setValidationResult(null)
  }, [rows, cols, words])

  const handleValidate = useCallback(() => {
    const errors: { row: number; col: number; message: string }[] = []

    if (words.length < 3) {
      errors.push({ row: -1, col: -1, message: 'Add at least 3 words' })
    }

    // Check if grid is filled
    const hasEmptyCells = grid.some(row => row.some(cell => !cell))
    if (hasEmptyCells) {
      errors.push({ row: -1, col: -1, message: 'Fill the grid with random letters first' })
    }

    if (errors.length > 0) {
      setValidationResult({ isValid: false, hasUniqueSolution: false, errors })
    } else {
      setValidationResult({ isValid: true, hasUniqueSolution: true, errors: [] })
    }
  }, [words, grid])

  // Get highlighted cells for all words
  const highlightedCells = useMemo(() => {
    const cells = new Set<string>()
    for (const w of words) {
      const dr = w.endRow === w.startRow ? 0 : (w.endRow > w.startRow ? 1 : -1)
      const dc = w.endCol === w.startCol ? 0 : (w.endCol > w.startCol ? 1 : -1)
      for (let i = 0; i < w.word.length; i++) {
        cells.add(`${w.startRow + dr * i},${w.startCol + dc * i}`)
      }
    }
    return cells
  }, [words])

  return (
    <div className={`space-y-6 ${className}`}>
      {/* Size selector */}
      <div>
        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
          Grid Size
        </label>
        <div className="flex gap-2 flex-wrap">
          {([8, 10, 12, 15] as GridSize[]).map((size) => (
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

      {/* Theme input */}
      <div>
        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
          Theme (optional)
        </label>
        <input
          type="text"
          value={theme}
          onChange={(e) => setTheme(e.target.value)}
          placeholder="e.g., Animals, Sports, Countries..."
          className="w-full max-w-xs px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md
                     bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100"
        />
      </div>

      {/* Add word form */}
      <div>
        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
          Add Words
        </label>
        <div className="flex gap-2">
          <input
            type="text"
            value={newWord}
            onChange={(e) => setNewWord(e.target.value.toUpperCase())}
            onKeyDown={(e) => e.key === 'Enter' && handleAddWord()}
            placeholder="Enter word..."
            className="flex-1 max-w-xs px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md
                       bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100
                       uppercase tracking-wide"
          />
          <button
            type="button"
            onClick={handleAddWord}
            className="flex items-center gap-2 px-4 py-2 bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300 rounded-md hover:bg-green-200 dark:hover:bg-green-900/50 transition-colors"
          >
            <Plus className="w-4 h-4" />
            Add
          </button>
        </div>
      </div>

      {/* Word list */}
      {words.length > 0 && (
        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Words ({words.length})
          </label>
          <div className="flex flex-wrap gap-2">
            {words.map((w) => (
              <div
                key={w.word}
                className="flex items-center gap-2 px-3 py-1 bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 rounded-full"
              >
                <span className="font-medium">{w.word}</span>
                <button
                  type="button"
                  onClick={() => handleRemoveWord(w.word)}
                  className="text-blue-500 hover:text-red-500 transition-colors"
                >
                  <Trash2 className="w-3 h-3" />
                </button>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Grid Preview */}
      <div>
        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
          Grid Preview
        </label>
        <div className="overflow-auto">
          <div
            className="inline-grid gap-0 border-2 border-gray-700 dark:border-gray-400"
            style={{ gridTemplateColumns: `repeat(${cols}, 28px)` }}
          >
            {grid.map((row, rowIdx) =>
              row.map((cell, colIdx) => {
                const isHighlighted = highlightedCells.has(`${rowIdx},${colIdx}`)

                return (
                  <div
                    key={`${rowIdx}-${colIdx}`}
                    className={`w-7 h-7 flex items-center justify-center
                               text-sm font-bold uppercase
                               border border-gray-200 dark:border-gray-700
                               ${isHighlighted
                                 ? 'bg-yellow-100 dark:bg-yellow-900/30 text-yellow-800 dark:text-yellow-200'
                                 : cell
                                 ? 'bg-white dark:bg-gray-700 text-gray-700 dark:text-gray-300'
                                 : 'bg-gray-100 dark:bg-gray-800 text-gray-400'
                               }`}
                  >
                    {cell || '·'}
                  </div>
                )
              })
            )}
          </div>
        </div>
      </div>

      {/* Actions */}
      <div className="flex gap-2 flex-wrap">
        <button
          type="button"
          onClick={handleFillGrid}
          className="flex items-center gap-2 px-4 py-2 bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-300 rounded-md hover:bg-purple-200 dark:hover:bg-purple-900/50 transition-colors"
        >
          <Wand2 className="w-4 h-4" />
          Fill Random Letters
        </button>
        <button
          type="button"
          onClick={handleClearGrid}
          className="flex items-center gap-2 px-4 py-2 bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-md hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors"
        >
          <Shuffle className="w-4 h-4" />
          Clear Filler
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
    </div>
  )
}

export default WordSearchEditor
