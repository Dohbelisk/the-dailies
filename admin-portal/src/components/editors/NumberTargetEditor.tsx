import { useState, useCallback, useEffect } from 'react'
import { useMutation } from '@tanstack/react-query'
import { Calculator, Shuffle, Loader2, CheckCircle, XCircle } from 'lucide-react'
import { validateApi } from '../../lib/api'
import ValidationStatus from './shared/ValidationStatus'

interface NumberTargetEditorProps {
  initialData?: {
    numbers: number[]
    targets: { target: number; difficulty: string }[]
  }
  initialSolution?: {
    targetSolutions: { target: number; expression: string }[]
  }
  onChange?: (puzzleData: any, solution: any, isValid?: boolean) => void
  className?: string
}

interface TargetInput {
  target: number | ''
  difficulty: string
}

interface ValidationResult {
  isValid: boolean
  errors: { row: number; col: number; message: string }[]
  targetSolutions?: { target: number; expression: string; reachable: boolean }[]
}

const DEFAULT_TARGETS: TargetInput[] = [
  { target: '', difficulty: 'extraEasy' },
  { target: '', difficulty: 'easy' },
  { target: '', difficulty: 'medium' },
  { target: '', difficulty: 'hard' },
  { target: '', difficulty: 'expert' },
]

// Generate random numbers between min and max
const randomInt = (min: number, max: number) =>
  Math.floor(Math.random() * (max - min + 1)) + min

export function NumberTargetEditor({
  initialData,
  initialSolution,
  onChange,
  className = '',
}: NumberTargetEditorProps) {
  const [numbers, setNumbers] = useState<(number | '')[]>(
    initialData?.numbers || ['', '', '', '', '', '']
  )
  const [targets, setTargets] = useState<TargetInput[]>(
    initialData?.targets?.map(t => ({ target: t.target, difficulty: t.difficulty })) ||
    DEFAULT_TARGETS
  )
  const [solution, setSolution] = useState<ValidationResult['targetSolutions'] | null>(
    initialSolution?.targetSolutions?.map(s => ({ ...s, reachable: true })) || null
  )
  const [validationResult, setValidationResult] = useState<ValidationResult | null>(null)

  // Notify parent of changes
  useEffect(() => {
    if (onChange && validationResult?.isValid && solution) {
      const validNumbers = numbers.filter((n): n is number => n !== '')
      const validTargets = targets
        .filter(t => t.target !== '')
        .map(t => ({ target: t.target as number, difficulty: t.difficulty }))

      onChange(
        { numbers: validNumbers, targets: validTargets },
        { targetSolutions: solution },
        true
      )
    }
  }, [numbers, targets, solution, onChange, validationResult])

  const validateMutation = useMutation({
    mutationFn: () => {
      const validNumbers = numbers.filter((n): n is number => n !== '')
      const validTargets = targets
        .filter(t => t.target !== '')
        .map(t => ({ target: t.target as number, difficulty: t.difficulty }))
      return validateApi.validateNumberTarget(validNumbers, validTargets)
    },
    onSuccess: (response) => {
      const result = response.data as ValidationResult
      setValidationResult({
        isValid: result.isValid,
        errors: result.errors,
        targetSolutions: result.targetSolutions,
      })
      if (result.targetSolutions) {
        setSolution(result.targetSolutions)
      }
    },
    onError: (error: any) => {
      setValidationResult({
        isValid: false,
        errors: [
          {
            row: -1,
            col: -1,
            message: error.response?.data?.message || 'Validation failed',
          },
        ],
      })
      setSolution(null)
    },
  })

  const handleNumberChange = useCallback((index: number, value: string) => {
    const num = value === '' ? '' : parseInt(value, 10)
    if (value !== '' && (isNaN(num as number) || (num as number) < 1 || (num as number) > 100)) {
      return
    }
    setNumbers(prev => {
      const newNumbers = [...prev]
      newNumbers[index] = num
      return newNumbers
    })
    setSolution(null)
    setValidationResult(null)
  }, [])

  const handleTargetChange = useCallback((index: number, value: string) => {
    const num = value === '' ? '' : parseInt(value, 10)
    if (value !== '' && (isNaN(num as number) || (num as number) < 1)) {
      return
    }
    setTargets(prev => {
      const newTargets = [...prev]
      newTargets[index] = { ...newTargets[index], target: num }
      return newTargets
    })
    setSolution(null)
    setValidationResult(null)
  }, [])

  const handleRandom = useCallback(() => {
    // Generate 6 random numbers (mix of small and larger)
    const newNumbers = [
      randomInt(1, 9),
      randomInt(1, 9),
      randomInt(2, 13),
      randomInt(2, 13),
      randomInt(5, 25),
      randomInt(5, 25),
    ]
    setNumbers(newNumbers)

    // Generate reasonable targets across 5 difficulty tiers
    const sum = newNumbers.reduce((a, b) => a + b, 0)
    const smallProduct = newNumbers[0] * newNumbers[1]
    const medProduct = newNumbers[2] * newNumbers[3]
    const largeProduct = newNumbers[4] * newNumbers[5]

    setTargets([
      { target: newNumbers[0] + newNumbers[1], difficulty: 'extraEasy' },
      { target: sum, difficulty: 'easy' },
      { target: smallProduct + newNumbers[2], difficulty: 'medium' },
      { target: medProduct * newNumbers[0], difficulty: 'hard' },
      { target: Math.floor(largeProduct * newNumbers[0]), difficulty: 'expert' },
    ])

    setSolution(null)
    setValidationResult(null)
  }, [])

  const handleValidate = useCallback(() => {
    const validNumbers = numbers.filter((n): n is number => n !== '')
    const validTargets = targets.filter(t => t.target !== '')

    if (validNumbers.length !== 6) {
      setValidationResult({
        isValid: false,
        errors: [{ row: -1, col: -1, message: 'Please enter all 6 numbers' }],
      })
      return
    }

    if (validTargets.length === 0) {
      setValidationResult({
        isValid: false,
        errors: [{ row: -1, col: -1, message: 'Please enter at least one target' }],
      })
      return
    }

    validateMutation.mutate()
  }, [numbers, targets, validateMutation])

  const isValidating = validateMutation.isPending

  return (
    <div className={`space-y-6 ${className}`}>
      {/* Numbers input */}
      <div>
        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
          Numbers (6 required, 1-100)
        </label>
        <div className="flex gap-3">
          {numbers.map((num, index) => (
            <input
              key={index}
              type="number"
              min={1}
              max={100}
              value={num}
              onChange={(e) => handleNumberChange(index, e.target.value)}
              placeholder="#"
              className="w-20 px-3 py-3 border border-gray-300 dark:border-gray-600 rounded-lg
                         bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100
                         text-xl font-bold text-center
                         focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            />
          ))}
        </div>
      </div>

      {/* Targets input */}
      <div>
        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
          Targets
        </label>
        <div className="space-y-3">
          {targets.map((target, index) => (
            <div key={index} className="flex items-center gap-3">
              <span
                className={`px-3 py-1 rounded-md text-sm font-medium ${
                  target.difficulty === 'extraEasy'
                    ? 'bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-300'
                    : target.difficulty === 'easy'
                    ? 'bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300'
                    : target.difficulty === 'medium'
                    ? 'bg-yellow-100 dark:bg-yellow-900/30 text-yellow-700 dark:text-yellow-300'
                    : target.difficulty === 'hard'
                    ? 'bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-300'
                    : 'bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-300'
                }`}
              >
                {target.difficulty === 'extraEasy' ? 'Extra Easy' : target.difficulty}
              </span>
              <input
                type="number"
                min={1}
                value={target.target}
                onChange={(e) => handleTargetChange(index, e.target.value)}
                placeholder="Target"
                className="w-28 px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg
                           bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100
                           text-lg font-bold text-center
                           focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              />
              {solution && solution[index] && (
                <div className="flex items-center gap-2">
                  {solution[index].reachable ? (
                    <>
                      <CheckCircle className="w-5 h-5 text-green-500" />
                      <span className="font-mono text-sm text-gray-600 dark:text-gray-400">
                        {solution[index].expression}
                      </span>
                    </>
                  ) : (
                    <XCircle className="w-5 h-5 text-red-500" />
                  )}
                </div>
              )}
            </div>
          ))}
        </div>
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
          onClick={handleValidate}
          disabled={isValidating}
          className="flex items-center gap-2 px-4 py-2 bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 rounded-md hover:bg-blue-200 dark:hover:bg-blue-900/50 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {isValidating ? (
            <Loader2 className="w-4 h-4 animate-spin" />
          ) : (
            <Calculator className="w-4 h-4" />
          )}
          {isValidating ? 'Solving...' : 'Solve & Validate'}
        </button>
      </div>

      {/* Validation status */}
      <ValidationStatus
        isValidating={isValidating}
        isValid={validationResult?.isValid}
        hasUniqueSolution={validationResult?.isValid}
        errors={validationResult?.errors}
      />

      {/* Solution summary */}
      {validationResult?.isValid && solution && (
        <div className="p-4 bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg">
          <h4 className="font-medium text-green-800 dark:text-green-200 mb-3">
            All Targets Reachable
          </h4>
          <div className="space-y-2">
            {solution.map((s, idx) => (
              <div key={idx} className="flex items-center gap-3 text-sm">
                <span className="font-bold text-gray-700 dark:text-gray-300 w-16">
                  = {s.target}
                </span>
                <span className="font-mono text-gray-600 dark:text-gray-400">
                  {s.expression}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}

export default NumberTargetEditor
