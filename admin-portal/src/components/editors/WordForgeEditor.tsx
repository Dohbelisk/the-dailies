import { useState, useCallback, useEffect } from 'react'
import { useMutation } from '@tanstack/react-query'
import { Wand2, Loader2, X, Star } from 'lucide-react'
import { validateApi } from '../../lib/api'
import LetterPicker from './shared/LetterPicker'
import ValidationStatus from './shared/ValidationStatus'

interface WordForgeEditorProps {
  initialData?: {
    letters: string[]
    centerLetter: string
  }
  initialSolution?: {
    allWords: string[]
    pangrams: string[]
    maxScore: number
  }
  onChange?: (puzzleData: any, solution: any) => void
  className?: string
}

interface ValidationResult {
  isValid: boolean
  errors: { row: number; col: number; message: string }[]
  allWords?: string[]
  pangrams?: string[]
  maxScore?: number
}

export function WordForgeEditor({
  initialData,
  initialSolution,
  onChange,
  className = '',
}: WordForgeEditorProps) {
  const [letters, setLetters] = useState<string[]>(initialData?.letters || [])
  const [centerLetter, setCenterLetter] = useState<string>(initialData?.centerLetter || '')
  const [solution, setSolution] = useState<{
    allWords: string[]
    pangrams: string[]
    maxScore: number
  } | null>(initialSolution || null)
  const [validationResult, setValidationResult] = useState<ValidationResult | null>(null)

  // Notify parent of changes
  useEffect(() => {
    if (onChange && validationResult?.isValid && solution) {
      onChange(
        { letters, centerLetter },
        solution
      )
    }
  }, [letters, centerLetter, solution, onChange, validationResult])

  const validateMutation = useMutation({
    mutationFn: () => validateApi.validateWordForge(letters, centerLetter),
    onSuccess: (response) => {
      const result = response.data as ValidationResult
      setValidationResult({
        isValid: result.isValid,
        errors: result.errors,
      })
      if (result.isValid && result.allWords) {
        setSolution({
          allWords: result.allWords,
          pangrams: result.pangrams || [],
          maxScore: result.maxScore || 0,
        })
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

  const handleLetterSelect = useCallback((letter: string) => {
    setLetters(prev => {
      if (prev.includes(letter)) {
        // Remove the letter
        const newLetters = prev.filter(l => l !== letter)
        // If we removed the center letter, clear it
        if (letter === centerLetter) {
          setCenterLetter('')
        }
        return newLetters
      } else if (prev.length < 7) {
        // Add the letter
        return [...prev, letter]
      }
      return prev
    })
    setSolution(null)
    setValidationResult(null)
  }, [centerLetter])

  const handleCenterLetterChange = useCallback((letter: string) => {
    setCenterLetter(letter)
    setSolution(null)
    setValidationResult(null)
  }, [])

  const handleClear = useCallback(() => {
    setLetters([])
    setCenterLetter('')
    setSolution(null)
    setValidationResult(null)
  }, [])

  const handleValidate = useCallback(() => {
    if (letters.length !== 7) {
      setValidationResult({
        isValid: false,
        errors: [{ row: -1, col: -1, message: 'Please select exactly 7 letters' }],
      })
      return
    }
    if (!centerLetter) {
      setValidationResult({
        isValid: false,
        errors: [{ row: -1, col: -1, message: 'Please select a center letter' }],
      })
      return
    }
    validateMutation.mutate()
  }, [letters, centerLetter, validateMutation])

  const isValidating = validateMutation.isPending

  return (
    <div className={`space-y-6 ${className}`}>
      {/* Letter picker */}
      <div>
        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
          Select 7 Letters
        </label>
        <LetterPicker
          onSelect={handleLetterSelect}
          selectedLetters={letters}
          maxSelections={7}
        />
      </div>

      {/* Selected letters display */}
      {letters.length > 0 && (
        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Selected Letters
          </label>
          <div className="flex gap-2 flex-wrap">
            {letters.map((letter, index) => (
              <button
                key={index}
                type="button"
                onClick={() => handleLetterSelect(letter)}
                className={`w-12 h-12 flex items-center justify-center text-xl font-bold rounded-lg
                           border-2 transition-all ${
                             letter === centerLetter
                               ? 'bg-amber-400 dark:bg-amber-500 text-amber-900 border-amber-600'
                               : 'bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-200 border-gray-300 dark:border-gray-600 hover:bg-gray-200 dark:hover:bg-gray-600'
                           }`}
                title={letter === centerLetter ? 'Center letter' : 'Click to remove'}
              >
                {letter}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Center letter selector */}
      {letters.length === 7 && (
        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Select Center Letter (must appear in all words)
          </label>
          <div className="flex gap-2 flex-wrap">
            {letters.map((letter) => (
              <button
                key={letter}
                type="button"
                onClick={() => handleCenterLetterChange(letter)}
                className={`w-12 h-12 flex items-center justify-center text-xl font-bold rounded-lg
                           border-2 transition-all ${
                             letter === centerLetter
                               ? 'bg-amber-400 dark:bg-amber-500 text-amber-900 border-amber-600'
                               : 'bg-white dark:bg-gray-700 text-gray-800 dark:text-gray-200 border-gray-300 dark:border-gray-600 hover:bg-amber-100 dark:hover:bg-amber-900/30'
                           }`}
              >
                {letter}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Actions */}
      <div className="flex gap-2 flex-wrap">
        <button
          type="button"
          onClick={handleClear}
          className="flex items-center gap-2 px-4 py-2 bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-300 rounded-md hover:bg-red-200 dark:hover:bg-red-900/50 transition-colors"
        >
          <X className="w-4 h-4" />
          Clear
        </button>
        <button
          type="button"
          onClick={handleValidate}
          disabled={isValidating || letters.length !== 7 || !centerLetter}
          className="flex items-center gap-2 px-4 py-2 bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 rounded-md hover:bg-blue-200 dark:hover:bg-blue-900/50 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {isValidating ? (
            <Loader2 className="w-4 h-4 animate-spin" />
          ) : (
            <Wand2 className="w-4 h-4" />
          )}
          {isValidating ? 'Finding Words...' : 'Generate Words'}
        </button>
      </div>

      {/* Validation status */}
      <ValidationStatus
        isValidating={isValidating}
        isValid={validationResult?.isValid}
        hasUniqueSolution={validationResult?.isValid}
        errors={validationResult?.errors}
      />

      {/* Solution / Word list */}
      {solution && (
        <div className="space-y-4">
          {/* Stats */}
          <div className="p-4 bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg">
            <h4 className="font-medium text-green-800 dark:text-green-200 mb-2">
              Puzzle Statistics
            </h4>
            <div className="grid grid-cols-3 gap-4 text-center">
              <div>
                <div className="text-2xl font-bold text-green-700 dark:text-green-300">
                  {solution.allWords.length}
                </div>
                <div className="text-sm text-green-600 dark:text-green-400">Words</div>
              </div>
              <div>
                <div className="text-2xl font-bold text-amber-600 dark:text-amber-400">
                  {solution.pangrams.length}
                </div>
                <div className="text-sm text-amber-600 dark:text-amber-400">Pangrams</div>
              </div>
              <div>
                <div className="text-2xl font-bold text-blue-600 dark:text-blue-400">
                  {solution.maxScore}
                </div>
                <div className="text-sm text-blue-600 dark:text-blue-400">Max Score</div>
              </div>
            </div>
          </div>

          {/* Pangrams */}
          {solution.pangrams.length > 0 && (
            <div>
              <h5 className="font-medium text-gray-700 dark:text-gray-300 mb-2 flex items-center gap-2">
                <Star className="w-4 h-4 text-amber-500" />
                Pangrams (use all 7 letters)
              </h5>
              <div className="flex flex-wrap gap-2">
                {solution.pangrams.map((word) => (
                  <span
                    key={word}
                    className="px-3 py-1 bg-amber-100 dark:bg-amber-900/30 text-amber-800 dark:text-amber-200 rounded-full text-sm font-medium"
                  >
                    {word}
                  </span>
                ))}
              </div>
            </div>
          )}

          {/* All words */}
          <div>
            <h5 className="font-medium text-gray-700 dark:text-gray-300 mb-2">
              All Valid Words ({solution.allWords.length})
            </h5>
            <div className="max-h-48 overflow-y-auto p-3 bg-gray-50 dark:bg-gray-800 rounded-lg">
              <div className="flex flex-wrap gap-2">
                {solution.allWords.map((word) => (
                  <span
                    key={word}
                    className={`px-2 py-1 rounded text-sm font-mono ${
                      solution.pangrams.includes(word)
                        ? 'bg-amber-100 dark:bg-amber-900/30 text-amber-800 dark:text-amber-200 font-bold'
                        : 'bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300'
                    }`}
                  >
                    {word}
                  </span>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

export default WordForgeEditor
