import { useState, useCallback, useEffect } from 'react'
import { useMutation } from '@tanstack/react-query'
import { Search, Loader2 } from 'lucide-react'
import { validateApi } from '../../lib/api'
import ValidationStatus from './shared/ValidationStatus'

interface WordLadderEditorProps {
  initialData?: {
    startWord: string
    targetWord: string
    wordLength: number
  }
  initialSolution?: {
    path: string[]
    minSteps: number
  }
  onChange?: (puzzleData: any, solution: any, isValid?: boolean) => void
  className?: string
}

type WordLength = 3 | 4 | 5

interface ValidationResult {
  isValid: boolean
  errors: { row: number; col: number; message: string }[]
  path?: string[]
  minSteps?: number
}

export function WordLadderEditor({
  initialData,
  initialSolution,
  onChange,
  className = '',
}: WordLadderEditorProps) {
  const [wordLength, setWordLength] = useState<WordLength>(
    (initialData?.wordLength as WordLength) || 4
  )
  const [startWord, setStartWord] = useState(initialData?.startWord || '')
  const [targetWord, setTargetWord] = useState(initialData?.targetWord || '')
  const [solution, setSolution] = useState<{ path: string[]; minSteps: number } | null>(
    initialSolution || null
  )
  const [validationResult, setValidationResult] = useState<ValidationResult | null>(null)

  // Notify parent of changes
  useEffect(() => {
    if (onChange && validationResult?.isValid && solution) {
      onChange(
        { startWord: startWord.toUpperCase(), targetWord: targetWord.toUpperCase(), wordLength },
        solution,
        true
      )
    }
  }, [startWord, targetWord, wordLength, solution, onChange, validationResult])

  const validateMutation = useMutation({
    mutationFn: () =>
      validateApi.validateWordLadder(startWord, targetWord, wordLength),
    onSuccess: (response) => {
      const result = response.data as ValidationResult
      setValidationResult({
        isValid: result.isValid,
        errors: result.errors,
      })
      if (result.isValid && result.path) {
        setSolution({ path: result.path, minSteps: result.minSteps! })
      } else {
        setSolution(null)
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

  const handleWordLengthChange = useCallback((length: WordLength) => {
    setWordLength(length)
    setStartWord('')
    setTargetWord('')
    setSolution(null)
    setValidationResult(null)
  }, [])

  const handleStartWordChange = useCallback((value: string) => {
    const cleaned = value.toUpperCase().replace(/[^A-Z]/g, '').slice(0, wordLength)
    setStartWord(cleaned)
    setSolution(null)
    setValidationResult(null)
  }, [wordLength])

  const handleTargetWordChange = useCallback((value: string) => {
    const cleaned = value.toUpperCase().replace(/[^A-Z]/g, '').slice(0, wordLength)
    setTargetWord(cleaned)
    setSolution(null)
    setValidationResult(null)
  }, [wordLength])

  const handleValidate = useCallback(() => {
    if (startWord.length !== wordLength) {
      setValidationResult({
        isValid: false,
        errors: [{ row: -1, col: -1, message: `Start word must be ${wordLength} letters` }],
      })
      return
    }
    if (targetWord.length !== wordLength) {
      setValidationResult({
        isValid: false,
        errors: [{ row: -1, col: -1, message: `Target word must be ${wordLength} letters` }],
      })
      return
    }
    if (startWord === targetWord) {
      setValidationResult({
        isValid: false,
        errors: [{ row: -1, col: -1, message: 'Start and target words must be different' }],
      })
      return
    }
    validateMutation.mutate()
  }, [startWord, targetWord, wordLength, validateMutation])

  const isValidating = validateMutation.isPending

  return (
    <div className={`space-y-6 ${className}`}>
      {/* Word length selector */}
      <div>
        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
          Word Length
        </label>
        <div className="flex gap-2">
          {([3, 4, 5] as WordLength[]).map((length) => (
            <button
              key={length}
              type="button"
              onClick={() => handleWordLengthChange(length)}
              className={`px-4 py-2 rounded-md font-medium transition-colors ${
                wordLength === length
                  ? 'bg-blue-500 text-white'
                  : 'bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600'
              }`}
            >
              {length} letters
            </button>
          ))}
        </div>
      </div>

      {/* Word inputs */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Start Word
          </label>
          <input
            type="text"
            value={startWord}
            onChange={(e) => handleStartWordChange(e.target.value)}
            placeholder={`Enter ${wordLength}-letter word`}
            maxLength={wordLength}
            className="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg
                       bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100
                       text-xl font-mono uppercase tracking-widest text-center
                       focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
          />
          <p className="mt-1 text-xs text-gray-500 dark:text-gray-400 text-center">
            {startWord.length}/{wordLength}
          </p>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Target Word
          </label>
          <input
            type="text"
            value={targetWord}
            onChange={(e) => handleTargetWordChange(e.target.value)}
            placeholder={`Enter ${wordLength}-letter word`}
            maxLength={wordLength}
            className="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg
                       bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100
                       text-xl font-mono uppercase tracking-widest text-center
                       focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
          />
          <p className="mt-1 text-xs text-gray-500 dark:text-gray-400 text-center">
            {targetWord.length}/{wordLength}
          </p>
        </div>
      </div>

      {/* Validate button */}
      <div>
        <button
          type="button"
          onClick={handleValidate}
          disabled={isValidating || startWord.length !== wordLength || targetWord.length !== wordLength}
          className="flex items-center gap-2 px-4 py-2 bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 rounded-md hover:bg-blue-200 dark:hover:bg-blue-900/50 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {isValidating ? (
            <Loader2 className="w-4 h-4 animate-spin" />
          ) : (
            <Search className="w-4 h-4" />
          )}
          {isValidating ? 'Finding Path...' : 'Find Path'}
        </button>
      </div>

      {/* Validation status */}
      <ValidationStatus
        isValidating={isValidating}
        isValid={validationResult?.isValid}
        hasUniqueSolution={validationResult?.isValid}
        errors={validationResult?.errors}
      />

      {/* Solution path */}
      {solution && (
        <div className="p-4 bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg">
          <h4 className="font-medium text-green-800 dark:text-green-200 mb-3">
            Solution Path ({solution.minSteps} steps)
          </h4>
          <div className="flex flex-wrap items-center gap-2">
            {solution.path.map((word, index) => (
              <div key={index} className="flex items-center gap-2">
                <span
                  className={`px-3 py-2 rounded-lg font-mono text-lg uppercase tracking-wider ${
                    index === 0
                      ? 'bg-blue-500 text-white'
                      : index === solution.path.length - 1
                      ? 'bg-green-500 text-white'
                      : 'bg-gray-200 dark:bg-gray-600 text-gray-800 dark:text-gray-200'
                  }`}
                >
                  {word}
                </span>
                {index < solution.path.length - 1 && (
                  <span className="text-gray-400">→</span>
                )}
              </div>
            ))}
          </div>
          <p className="mt-3 text-sm text-green-600 dark:text-green-400">
            Each step changes exactly one letter to form a valid word.
          </p>
        </div>
      )}
    </div>
  )
}

export default WordLadderEditor
