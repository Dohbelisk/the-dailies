import { useState, useCallback, useEffect } from 'react'
import { Plus, Trash2, CheckCircle, Wand2, ArrowRight } from 'lucide-react'
import ValidationStatus from './shared/ValidationStatus'

interface MathoraOperation {
  type: 'add' | 'subtract' | 'multiply' | 'divide'
  value: number
  display: string
}

interface MathoraEditorProps {
  initialData?: {
    startNumber: number
    targetNumber: number
    moves: number
    operations: MathoraOperation[]
  }
  initialSolution?: {
    steps: MathoraOperation[]
  }
  onChange?: (puzzleData: any, solution: any) => void
  className?: string
}

const OPERATION_SYMBOLS: Record<string, string> = {
  add: '+',
  subtract: '-',
  multiply: '×',
  divide: '÷',
}

const createDisplay = (type: string, value: number): string => {
  return `${OPERATION_SYMBOLS[type]}${value}`
}

const applyOperation = (num: number, op: MathoraOperation): number | null => {
  switch (op.type) {
    case 'add':
      return num + op.value
    case 'subtract':
      return num - op.value
    case 'multiply':
      return num * op.value
    case 'divide':
      if (op.value === 0 || num % op.value !== 0) return null
      return num / op.value
    default:
      return null
  }
}

// Generate a random puzzle
const generateRandomPuzzle = (difficulty: 'easy' | 'medium' | 'hard'): {
  startNumber: number
  targetNumber: number
  moves: number
  operations: MathoraOperation[]
  solutionSteps: MathoraOperation[]
} => {
  const configs = {
    easy: { moves: 3, startRange: [2, 20], targetRange: [50, 200] },
    medium: { moves: 4, startRange: [5, 30], targetRange: [100, 500] },
    hard: { moves: 5, startRange: [3, 25], targetRange: [200, 1000] },
  }

  const config = configs[difficulty]
  const startNumber = Math.floor(Math.random() * (config.startRange[1] - config.startRange[0])) + config.startRange[0]

  // Build solution by working forward
  const solutionSteps: MathoraOperation[] = []
  let currentValue = startNumber

  const addOps = [5, 10, 15, 20, 25, 30, 40, 50, 75, 100]
  const subOps = [5, 10, 15, 20, 25]
  const mulOps = [2, 3, 4, 5, 6, 8, 10]
  const divOps = [2, 3, 4, 5]

  for (let i = 0; i < config.moves; i++) {
    const opType = ['add', 'multiply', 'subtract', 'divide'][Math.floor(Math.random() * 4)] as MathoraOperation['type']
    let value: number
    let newValue: number | null = null

    // Pick a valid operation
    let attempts = 0
    while (newValue === null || newValue <= 0 || newValue > 10000) {
      if (attempts++ > 50) break

      switch (opType) {
        case 'add':
          value = addOps[Math.floor(Math.random() * addOps.length)]
          newValue = currentValue + value
          break
        case 'subtract':
          value = subOps[Math.floor(Math.random() * subOps.length)]
          newValue = currentValue - value
          break
        case 'multiply':
          value = mulOps[Math.floor(Math.random() * mulOps.length)]
          newValue = currentValue * value
          break
        case 'divide':
          // Find a divisor that works
          const validDivisors = divOps.filter(d => currentValue % d === 0)
          if (validDivisors.length === 0) {
            newValue = null
            continue
          }
          value = validDivisors[Math.floor(Math.random() * validDivisors.length)]
          newValue = currentValue / value
          break
      }
    }

    if (newValue !== null && newValue > 0) {
      solutionSteps.push({
        type: opType,
        value: value!,
        display: createDisplay(opType, value!),
      })
      currentValue = newValue
    }
  }

  // Round target to nearest 5
  const targetNumber = Math.round(currentValue / 5) * 5 || currentValue

  // Add distractor operations
  const distractors: MathoraOperation[] = []
  const allValues = [...addOps, ...mulOps]
  for (let i = 0; i < 8; i++) {
    const type = ['add', 'subtract', 'multiply', 'divide'][Math.floor(Math.random() * 4)] as MathoraOperation['type']
    const value = type === 'divide'
      ? divOps[Math.floor(Math.random() * divOps.length)]
      : type === 'subtract'
      ? subOps[Math.floor(Math.random() * subOps.length)]
      : allValues[Math.floor(Math.random() * allValues.length)]

    distractors.push({
      type,
      value,
      display: createDisplay(type, value),
    })
  }

  // Combine and shuffle
  const operations = [...solutionSteps, ...distractors]
    .sort(() => Math.random() - 0.5)

  return {
    startNumber,
    targetNumber,
    moves: config.moves,
    operations,
    solutionSteps,
  }
}

export function MathoraEditor({
  initialData,
  initialSolution,
  onChange,
  className = '',
}: MathoraEditorProps) {
  const [startNumber, setStartNumber] = useState(initialData?.startNumber || 10)
  const [targetNumber, setTargetNumber] = useState(initialData?.targetNumber || 100)
  const [moves, setMoves] = useState(initialData?.moves || 3)
  const [operations, setOperations] = useState<MathoraOperation[]>(initialData?.operations || [])
  const [solutionSteps, setSolutionSteps] = useState<MathoraOperation[]>(initialSolution?.steps || [])
  const [newOpType, setNewOpType] = useState<MathoraOperation['type']>('add')
  const [newOpValue, setNewOpValue] = useState<number>(10)
  const [validationResult, setValidationResult] = useState<{
    isValid: boolean
    hasUniqueSolution: boolean
    errors: { row: number; col: number; message: string }[]
  } | null>(null)

  // Notify parent of changes
  useEffect(() => {
    if (onChange && validationResult?.isValid) {
      onChange(
        { startNumber, targetNumber, moves, operations },
        { steps: solutionSteps }
      )
    }
  }, [startNumber, targetNumber, moves, operations, solutionSteps, onChange, validationResult])

  const handleAddOperation = useCallback(() => {
    if (newOpValue <= 0) return

    const newOp: MathoraOperation = {
      type: newOpType,
      value: newOpValue,
      display: createDisplay(newOpType, newOpValue),
    }

    setOperations(prev => [...prev, newOp])
    setValidationResult(null)
  }, [newOpType, newOpValue])

  const handleRemoveOperation = useCallback((index: number) => {
    setOperations(prev => prev.filter((_, i) => i !== index))
    setValidationResult(null)
  }, [])

  const handleToggleSolution = useCallback((op: MathoraOperation) => {
    setSolutionSteps(prev => {
      const exists = prev.some(s =>
        s.type === op.type && s.value === op.value
      )
      if (exists) {
        return prev.filter(s => !(s.type === op.type && s.value === op.value))
      } else if (prev.length < moves) {
        return [...prev, op]
      }
      return prev
    })
    setValidationResult(null)
  }, [moves])

  const handleRandomize = useCallback((difficulty: 'easy' | 'medium' | 'hard') => {
    const puzzle = generateRandomPuzzle(difficulty)
    setStartNumber(puzzle.startNumber)
    setTargetNumber(puzzle.targetNumber)
    setMoves(puzzle.moves)
    setOperations(puzzle.operations)
    setSolutionSteps(puzzle.solutionSteps)
    setValidationResult(null)
  }, [])

  const handleClear = useCallback(() => {
    setOperations([])
    setSolutionSteps([])
    setValidationResult(null)
  }, [])

  const handleValidate = useCallback(() => {
    const errors: { row: number; col: number; message: string }[] = []

    if (operations.length < moves) {
      errors.push({ row: -1, col: -1, message: `Need at least ${moves} operations` })
    }

    if (solutionSteps.length !== moves) {
      errors.push({ row: -1, col: -1, message: `Solution needs exactly ${moves} steps (have ${solutionSteps.length})` })
    }

    // Verify solution reaches target
    if (solutionSteps.length === moves) {
      let value = startNumber
      for (const step of solutionSteps) {
        const result = applyOperation(value, step)
        if (result === null || result <= 0) {
          errors.push({ row: -1, col: -1, message: `Invalid operation: ${step.display} on ${value}` })
          break
        }
        value = result
      }

      if (value !== targetNumber) {
        errors.push({ row: -1, col: -1, message: `Solution gives ${value}, not ${targetNumber}` })
      }
    }

    if (errors.length > 0) {
      setValidationResult({ isValid: false, hasUniqueSolution: false, errors })
    } else {
      setValidationResult({ isValid: true, hasUniqueSolution: true, errors: [] })
    }
  }, [operations, solutionSteps, moves, startNumber, targetNumber])

  // Preview the solution path
  const solutionPreview = (() => {
    const steps: { value: number; op?: MathoraOperation }[] = [{ value: startNumber }]
    let current = startNumber

    for (const step of solutionSteps) {
      const result = applyOperation(current, step)
      if (result === null) break
      current = result
      steps.push({ value: current, op: step })
    }

    return steps
  })()

  return (
    <div className={`space-y-6 ${className}`}>
      {/* Basic settings */}
      <div className="grid grid-cols-3 gap-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
            Start Number
          </label>
          <input
            type="number"
            value={startNumber}
            onChange={(e) => { setStartNumber(parseInt(e.target.value) || 1); setValidationResult(null) }}
            min={1}
            max={100}
            className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md
                       bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
            Target Number
          </label>
          <input
            type="number"
            value={targetNumber}
            onChange={(e) => { setTargetNumber(parseInt(e.target.value) || 1); setValidationResult(null) }}
            min={1}
            max={10000}
            className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md
                       bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
            Moves Allowed
          </label>
          <input
            type="number"
            value={moves}
            onChange={(e) => { setMoves(parseInt(e.target.value) || 1); setValidationResult(null) }}
            min={2}
            max={6}
            className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md
                       bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100"
          />
        </div>
      </div>

      {/* Add operation */}
      <div>
        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
          Add Operation
        </label>
        <div className="flex gap-2 items-center">
          <select
            value={newOpType}
            onChange={(e) => setNewOpType(e.target.value as MathoraOperation['type'])}
            className="px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md
                       bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100"
          >
            <option value="add">+ Add</option>
            <option value="subtract">- Subtract</option>
            <option value="multiply">× Multiply</option>
            <option value="divide">÷ Divide</option>
          </select>
          <input
            type="number"
            value={newOpValue}
            onChange={(e) => setNewOpValue(parseInt(e.target.value) || 0)}
            min={1}
            max={100}
            className="w-24 px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md
                       bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100"
          />
          <button
            type="button"
            onClick={handleAddOperation}
            className="flex items-center gap-2 px-4 py-2 bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300 rounded-md hover:bg-green-200 dark:hover:bg-green-900/50 transition-colors"
          >
            <Plus className="w-4 h-4" />
            Add
          </button>
        </div>
      </div>

      {/* Operations list */}
      <div>
        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
          Operations (click to toggle in solution, {solutionSteps.length}/{moves} selected)
        </label>
        <div className="flex flex-wrap gap-2">
          {operations.map((op, idx) => {
            const inSolution = solutionSteps.some(s =>
              s.type === op.type && s.value === op.value
            )

            return (
              <div
                key={idx}
                className={`flex items-center gap-1 px-3 py-2 rounded-md border-2 transition-all ${
                  inSolution
                    ? 'border-green-500 bg-green-100 dark:bg-green-900/30'
                    : 'border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700'
                }`}
              >
                <button
                  type="button"
                  onClick={() => handleToggleSolution(op)}
                  className="font-mono font-bold text-lg"
                >
                  {op.display}
                </button>
                <button
                  type="button"
                  onClick={() => handleRemoveOperation(idx)}
                  className="ml-2 text-gray-400 hover:text-red-500"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            )
          })}
          {operations.length === 0 && (
            <p className="text-sm text-gray-500 dark:text-gray-400 italic">
              No operations added. Add some or use Random.
            </p>
          )}
        </div>
      </div>

      {/* Solution preview */}
      {solutionSteps.length > 0 && (
        <div className="p-4 bg-gray-50 dark:bg-gray-800 rounded-lg">
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Solution Preview
          </label>
          <div className="flex items-center gap-2 flex-wrap">
            {solutionPreview.map((step, idx) => (
              <div key={idx} className="flex items-center gap-2">
                {idx > 0 && (
                  <span className="text-gray-400 font-mono">{step.op?.display}</span>
                )}
                {idx > 0 && <ArrowRight className="w-4 h-4 text-gray-400" />}
                <span
                  className={`px-3 py-1 rounded-md font-bold ${
                    step.value === targetNumber
                      ? 'bg-green-500 text-white'
                      : 'bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300'
                  }`}
                >
                  {step.value}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Actions */}
      <div className="flex gap-2 flex-wrap">
        <button
          type="button"
          onClick={() => handleRandomize('easy')}
          className="flex items-center gap-2 px-4 py-2 bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300 rounded-md hover:bg-green-200 dark:hover:bg-green-900/50 transition-colors"
        >
          <Wand2 className="w-4 h-4" />
          Easy
        </button>
        <button
          type="button"
          onClick={() => handleRandomize('medium')}
          className="flex items-center gap-2 px-4 py-2 bg-yellow-100 dark:bg-yellow-900/30 text-yellow-700 dark:text-yellow-300 rounded-md hover:bg-yellow-200 dark:hover:bg-yellow-900/50 transition-colors"
        >
          <Wand2 className="w-4 h-4" />
          Medium
        </button>
        <button
          type="button"
          onClick={() => handleRandomize('hard')}
          className="flex items-center gap-2 px-4 py-2 bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-300 rounded-md hover:bg-red-200 dark:hover:bg-red-900/50 transition-colors"
        >
          <Wand2 className="w-4 h-4" />
          Hard
        </button>
        <button
          type="button"
          onClick={handleClear}
          className="flex items-center gap-2 px-4 py-2 bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-md hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors"
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

export default MathoraEditor
