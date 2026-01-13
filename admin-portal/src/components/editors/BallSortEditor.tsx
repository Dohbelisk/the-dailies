import { useState, useCallback, useEffect } from 'react'
import { Shuffle, Trash2, CheckCircle, Plus, Minus } from 'lucide-react'
import ValidationStatus from './shared/ValidationStatus'

interface BallSortEditorProps {
  initialData?: {
    tubes: number
    colors: number
    tubeCapacity: number
    initialState: string[][]
  }
  initialSolution?: {
    moves: { from: number; to: number }[]
    minMoves: number
  }
  onChange?: (puzzleData: any, solution: any, isValid?: boolean) => void
  className?: string
}

const COLORS = [
  { name: 'red', bg: 'bg-red-500', border: 'border-red-600' },
  { name: 'blue', bg: 'bg-blue-500', border: 'border-blue-600' },
  { name: 'green', bg: 'bg-green-500', border: 'border-green-600' },
  { name: 'yellow', bg: 'bg-yellow-400', border: 'border-yellow-500' },
  { name: 'purple', bg: 'bg-purple-500', border: 'border-purple-600' },
  { name: 'orange', bg: 'bg-orange-500', border: 'border-orange-600' },
  { name: 'pink', bg: 'bg-pink-400', border: 'border-pink-500' },
  { name: 'cyan', bg: 'bg-cyan-400', border: 'border-cyan-500' },
  { name: 'lime', bg: 'bg-lime-400', border: 'border-lime-500' },
  { name: 'teal', bg: 'bg-teal-500', border: 'border-teal-600' },
]

const getColorStyle = (colorName: string) => {
  const color = COLORS.find(c => c.name === colorName)
  return color || { name: colorName, bg: 'bg-gray-400', border: 'border-gray-500' }
}

// Generate a scrambled puzzle
const generateScrambledPuzzle = (numColors: number, tubeCapacity: number): string[][] => {
  const numTubes = numColors + 2 // 2 empty tubes for working space

  // Create solved state first
  const balls: string[] = []
  for (let i = 0; i < numColors; i++) {
    for (let j = 0; j < tubeCapacity; j++) {
      balls.push(COLORS[i].name)
    }
  }

  // Shuffle balls
  for (let i = balls.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1))
    ;[balls[i], balls[j]] = [balls[j], balls[i]]
  }

  // Distribute to tubes
  const tubes: string[][] = []
  let ballIndex = 0
  for (let t = 0; t < numTubes; t++) {
    if (t < numColors) {
      tubes.push(balls.slice(ballIndex, ballIndex + tubeCapacity))
      ballIndex += tubeCapacity
    } else {
      tubes.push([]) // Empty tubes
    }
  }

  return tubes
}

export function BallSortEditor({
  initialData,
  initialSolution,
  onChange,
  className = '',
}: BallSortEditorProps) {
  void initialSolution // Solution is generated, not loaded
  const [numColors, setNumColors] = useState(initialData?.colors || 4)
  const [tubeCapacity, setTubeCapacity] = useState(initialData?.tubeCapacity || 4)
  const [tubes, setTubes] = useState<string[][]>(
    initialData?.initialState || generateScrambledPuzzle(4, 4)
  )
  const [selectedTube, setSelectedTube] = useState<number | null>(null)
  const [selectedColor, setSelectedColor] = useState<string | null>(null)
  const [validationResult, setValidationResult] = useState<{
    isValid: boolean
    hasUniqueSolution: boolean
    errors: { row: number; col: number; message: string }[]
  } | null>(null)

  const numTubes = numColors + 2

  // Notify parent of changes
  useEffect(() => {
    if (onChange && validationResult?.isValid) {
      onChange(
        {
          tubes: numTubes,
          colors: numColors,
          tubeCapacity,
          initialState: tubes,
        },
        { moves: [], minMoves: 0 }, // TODO: Could add solver
        true
      )
    }
  }, [tubes, numColors, tubeCapacity, numTubes, onChange, validationResult])

  const handleColorCountChange = useCallback((delta: number) => {
    const newCount = Math.max(2, Math.min(10, numColors + delta))
    setNumColors(newCount)
    setTubes(generateScrambledPuzzle(newCount, tubeCapacity))
    setValidationResult(null)
  }, [numColors, tubeCapacity])

  const handleCapacityChange = useCallback((delta: number) => {
    const newCapacity = Math.max(3, Math.min(6, tubeCapacity + delta))
    setTubeCapacity(newCapacity)
    setTubes(generateScrambledPuzzle(numColors, newCapacity))
    setValidationResult(null)
  }, [numColors, tubeCapacity])

  const handleShuffle = useCallback(() => {
    setTubes(generateScrambledPuzzle(numColors, tubeCapacity))
    setValidationResult(null)
    setSelectedTube(null)
  }, [numColors, tubeCapacity])

  const handleTubeClick = useCallback((tubeIndex: number) => {
    if (selectedColor) {
      // Adding a ball to this tube
      if (tubes[tubeIndex].length < tubeCapacity) {
        setTubes(prev => {
          const newTubes = prev.map(t => [...t])
          newTubes[tubeIndex].push(selectedColor)
          return newTubes
        })
        setValidationResult(null)
      }
    } else if (selectedTube === tubeIndex) {
      // Deselect
      setSelectedTube(null)
    } else if (selectedTube !== null) {
      // Moving ball from selectedTube to this tube
      if (tubes[selectedTube].length > 0 && tubes[tubeIndex].length < tubeCapacity) {
        setTubes(prev => {
          const newTubes = prev.map(t => [...t])
          const ball = newTubes[selectedTube].pop()!
          newTubes[tubeIndex].push(ball)
          return newTubes
        })
        setValidationResult(null)
      }
      setSelectedTube(null)
    } else {
      // Select this tube
      setSelectedTube(tubeIndex)
    }
  }, [selectedTube, selectedColor, tubes, tubeCapacity])

  const handleBallClick = useCallback((tubeIndex: number, ballIndex: number, e: React.MouseEvent) => {
    e.stopPropagation()
    // Remove the ball
    setTubes(prev => {
      const newTubes = prev.map(t => [...t])
      newTubes[tubeIndex].splice(ballIndex, 1)
      return newTubes
    })
    setValidationResult(null)
  }, [])

  const handleColorSelect = useCallback((colorName: string) => {
    if (selectedColor === colorName) {
      setSelectedColor(null)
    } else {
      setSelectedColor(colorName)
      setSelectedTube(null)
    }
  }, [selectedColor])

  const handleClear = useCallback(() => {
    setTubes(Array(numTubes).fill(null).map(() => []))
    setValidationResult(null)
    setSelectedTube(null)
    setSelectedColor(null)
  }, [numTubes])

  const handleValidate = useCallback(() => {
    const errors: { row: number; col: number; message: string }[] = []

    // Count balls per color
    const colorCounts = new Map<string, number>()
    for (const tube of tubes) {
      for (const ball of tube) {
        colorCounts.set(ball, (colorCounts.get(ball) || 0) + 1)
      }
    }

    // Check each color has exactly tubeCapacity balls
    for (let i = 0; i < numColors; i++) {
      const color = COLORS[i].name
      const count = colorCounts.get(color) || 0
      if (count !== tubeCapacity) {
        errors.push({
          row: -1,
          col: -1,
          message: `${color} has ${count} balls (need ${tubeCapacity})`,
        })
      }
    }

    // Check total ball count
    const totalBalls = tubes.reduce((sum, t) => sum + t.length, 0)
    const expectedBalls = numColors * tubeCapacity
    if (totalBalls !== expectedBalls) {
      errors.push({
        row: -1,
        col: -1,
        message: `Total ${totalBalls} balls (need ${expectedBalls})`,
      })
    }

    // Check no tube exceeds capacity
    for (let i = 0; i < tubes.length; i++) {
      if (tubes[i].length > tubeCapacity) {
        errors.push({
          row: -1,
          col: -1,
          message: `Tube ${i + 1} has too many balls`,
        })
      }
    }

    if (errors.length > 0) {
      setValidationResult({ isValid: false, hasUniqueSolution: false, errors })
    } else {
      setValidationResult({ isValid: true, hasUniqueSolution: true, errors: [] })
    }
  }, [tubes, numColors, tubeCapacity])

  return (
    <div className={`space-y-6 ${className}`}>
      {/* Settings */}
      <div className="flex flex-wrap gap-6">
        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Number of Colors
          </label>
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={() => handleColorCountChange(-1)}
              disabled={numColors <= 2}
              className="p-2 bg-gray-100 dark:bg-gray-700 rounded-md hover:bg-gray-200 dark:hover:bg-gray-600 disabled:opacity-50"
            >
              <Minus className="w-4 h-4" />
            </button>
            <span className="w-8 text-center font-bold">{numColors}</span>
            <button
              type="button"
              onClick={() => handleColorCountChange(1)}
              disabled={numColors >= 10}
              className="p-2 bg-gray-100 dark:bg-gray-700 rounded-md hover:bg-gray-200 dark:hover:bg-gray-600 disabled:opacity-50"
            >
              <Plus className="w-4 h-4" />
            </button>
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Tube Capacity
          </label>
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={() => handleCapacityChange(-1)}
              disabled={tubeCapacity <= 3}
              className="p-2 bg-gray-100 dark:bg-gray-700 rounded-md hover:bg-gray-200 dark:hover:bg-gray-600 disabled:opacity-50"
            >
              <Minus className="w-4 h-4" />
            </button>
            <span className="w-8 text-center font-bold">{tubeCapacity}</span>
            <button
              type="button"
              onClick={() => handleCapacityChange(1)}
              disabled={tubeCapacity >= 6}
              className="p-2 bg-gray-100 dark:bg-gray-700 rounded-md hover:bg-gray-200 dark:hover:bg-gray-600 disabled:opacity-50"
            >
              <Plus className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      {/* Color palette for manual editing */}
      <div>
        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
          Add Balls (click color, then click tube)
        </label>
        <div className="flex gap-2 flex-wrap">
          {COLORS.slice(0, numColors).map((color) => (
            <button
              key={color.name}
              type="button"
              onClick={() => handleColorSelect(color.name)}
              className={`w-8 h-8 rounded-full ${color.bg} border-2 ${
                selectedColor === color.name
                  ? 'ring-2 ring-offset-2 ring-blue-500'
                  : color.border
              } transition-all`}
              title={color.name}
            />
          ))}
          {selectedColor && (
            <span className="text-sm text-gray-500 dark:text-gray-400 self-center ml-2">
              Click a tube to add {selectedColor}
            </span>
          )}
        </div>
      </div>

      {/* Tubes */}
      <div>
        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
          Tubes (click to select, right-click balls to remove)
        </label>
        <div className="flex gap-3 flex-wrap">
          {tubes.map((tube, tubeIdx) => (
            <div
              key={tubeIdx}
              onClick={() => handleTubeClick(tubeIdx)}
              className={`relative flex flex-col-reverse items-center p-1 rounded-b-2xl
                         border-2 border-t-0 cursor-pointer transition-all
                         ${selectedTube === tubeIdx
                           ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20'
                           : 'border-gray-400 dark:border-gray-600 bg-gray-50 dark:bg-gray-800'
                         }`}
              style={{
                width: '48px',
                minHeight: `${tubeCapacity * 32 + 16}px`,
              }}
            >
              {/* Tube number */}
              <span className="absolute -top-6 text-xs text-gray-500 dark:text-gray-400">
                {tubeIdx + 1}
              </span>

              {/* Balls */}
              {tube.map((ball, ballIdx) => {
                const style = getColorStyle(ball)
                return (
                  <button
                    key={ballIdx}
                    type="button"
                    onClick={(e) => handleBallClick(tubeIdx, ballIdx, e)}
                    className={`w-8 h-8 rounded-full ${style.bg} border-2 ${style.border}
                               transition-transform hover:scale-110`}
                    title={`${ball} (click to remove)`}
                  />
                )
              })}

              {/* Empty slots */}
              {Array(tubeCapacity - tube.length).fill(null).map((_, i) => (
                <div
                  key={`empty-${i}`}
                  className="w-8 h-8 rounded-full border-2 border-dashed border-gray-300 dark:border-gray-600"
                />
              ))}
            </div>
          ))}
        </div>
      </div>

      {/* Actions */}
      <div className="flex gap-2 flex-wrap">
        <button
          type="button"
          onClick={handleShuffle}
          className="flex items-center gap-2 px-4 py-2 bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-300 rounded-md hover:bg-purple-200 dark:hover:bg-purple-900/50 transition-colors"
        >
          <Shuffle className="w-4 h-4" />
          Shuffle
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
    </div>
  )
}

export default BallSortEditor
