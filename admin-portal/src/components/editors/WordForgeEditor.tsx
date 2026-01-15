import { useState, useCallback, useEffect } from 'react'
import { useMutation } from '@tanstack/react-query'
import { Wand2, Loader2, X, Star, Sparkles, Save, Check, Pencil } from 'lucide-react'
import { validateApi, aiApi, dictionaryApi } from '../../lib/api'
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
  onChange?: (puzzleData: any, solution: any, isValid?: boolean) => void
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

  // Clue generation state
  const [generatedClues, setGeneratedClues] = useState<{ word: string; clue: string }[]>([])
  const [editingClue, setEditingClue] = useState<string | null>(null)
  const [editedClueValue, setEditedClueValue] = useState('')
  const [cluesSaved, setCluesSaved] = useState(false)

  // Notify parent of changes
  useEffect(() => {
    if (onChange && validationResult?.isValid && solution) {
      onChange(
        { letters, centerLetter },
        solution,
        true
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
        // Clear any previous clues when generating new words
        setGeneratedClues([])
        setCluesSaved(false)
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

  // Generate clues mutation
  const generateCluesMutation = useMutation({
    mutationFn: (words: string[]) => aiApi.generateWordClues(words),
    onSuccess: (response) => {
      setGeneratedClues(response.data.clues)
      setCluesSaved(false)
    },
    onError: (error: any) => {
      alert(error.response?.data?.message || 'Failed to generate clues')
    },
  })

  // Save clues mutation
  const saveCluesMutation = useMutation({
    mutationFn: (clues: { word: string; clue: string }[]) => dictionaryApi.updateCluesBulk(clues),
    onSuccess: (response) => {
      setCluesSaved(true)
      alert(`Successfully updated ${response.data.updated} clues!${response.data.notFound.length > 0 ? `\n\nWords not found: ${response.data.notFound.join(', ')}` : ''}`)
    },
    onError: (error: any) => {
      alert(error.response?.data?.message || 'Failed to save clues')
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
  const isGeneratingClues = generateCluesMutation.isPending
  const isSavingClues = saveCluesMutation.isPending

  const handleGenerateClues = useCallback(() => {
    if (!solution?.allWords.length) return
    generateCluesMutation.mutate(solution.allWords)
  }, [solution, generateCluesMutation])

  const handleEditClue = useCallback((word: string, currentClue: string) => {
    setEditingClue(word)
    setEditedClueValue(currentClue)
  }, [])

  const handleSaveEditedClue = useCallback((word: string) => {
    setGeneratedClues(prev =>
      prev.map(c => c.word === word ? { ...c, clue: editedClueValue } : c)
    )
    setEditingClue(null)
    setEditedClueValue('')
  }, [editedClueValue])

  const handleCancelEdit = useCallback(() => {
    setEditingClue(null)
    setEditedClueValue('')
  }, [])

  const handleSaveClues = useCallback(() => {
    if (!generatedClues.length) return
    saveCluesMutation.mutate(generatedClues)
  }, [generatedClues, saveCluesMutation])

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

          {/* AI Clue Generator */}
          <div className="p-4 bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-800 rounded-lg">
            <h4 className="font-medium text-purple-800 dark:text-purple-200 mb-3 flex items-center gap-2">
              <Sparkles className="w-4 h-4" />
              AI Clue Generator
            </h4>
            <p className="text-sm text-purple-600 dark:text-purple-400 mb-3">
              Generate dictionary clues for all {solution.allWords.length} words. Review and edit before saving to the dictionary.
            </p>
            <button
              type="button"
              onClick={handleGenerateClues}
              disabled={isGeneratingClues}
              className="flex items-center gap-2 px-4 py-2 bg-purple-600 text-white rounded-md hover:bg-purple-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isGeneratingClues ? (
                <Loader2 className="w-4 h-4 animate-spin" />
              ) : (
                <Sparkles className="w-4 h-4" />
              )}
              {isGeneratingClues ? 'Generating Clues...' : 'Generate Clues with AI'}
            </button>
          </div>

          {/* Generated Clues Review */}
          {generatedClues.length > 0 && (
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <h5 className="font-medium text-gray-700 dark:text-gray-300">
                  Generated Clues ({generatedClues.length})
                </h5>
                <button
                  type="button"
                  onClick={handleSaveClues}
                  disabled={isSavingClues || cluesSaved}
                  className={`flex items-center gap-2 px-4 py-2 rounded-md transition-colors disabled:opacity-50 disabled:cursor-not-allowed ${
                    cluesSaved
                      ? 'bg-green-600 text-white'
                      : 'bg-blue-600 text-white hover:bg-blue-700'
                  }`}
                >
                  {isSavingClues ? (
                    <Loader2 className="w-4 h-4 animate-spin" />
                  ) : cluesSaved ? (
                    <Check className="w-4 h-4" />
                  ) : (
                    <Save className="w-4 h-4" />
                  )}
                  {isSavingClues ? 'Saving...' : cluesSaved ? 'Saved!' : 'Save All Clues to Dictionary'}
                </button>
              </div>

              <div className="max-h-96 overflow-y-auto border border-gray-200 dark:border-gray-700 rounded-lg">
                <table className="w-full text-sm">
                  <thead className="bg-gray-50 dark:bg-gray-800 sticky top-0">
                    <tr>
                      <th className="px-4 py-2 text-left font-medium text-gray-700 dark:text-gray-300">Word</th>
                      <th className="px-4 py-2 text-left font-medium text-gray-700 dark:text-gray-300">Clue</th>
                      <th className="px-4 py-2 w-20"></th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                    {generatedClues.map(({ word, clue }) => (
                      <tr key={word} className="hover:bg-gray-50 dark:hover:bg-gray-800/50">
                        <td className="px-4 py-2 font-mono font-medium text-gray-900 dark:text-gray-100">
                          {word}
                          {solution.pangrams.includes(word) && (
                            <Star className="w-3 h-3 inline ml-1 text-amber-500" />
                          )}
                        </td>
                        <td className="px-4 py-2">
                          {editingClue === word ? (
                            <div className="flex gap-2">
                              <input
                                type="text"
                                value={editedClueValue}
                                onChange={(e) => setEditedClueValue(e.target.value)}
                                className="flex-1 px-2 py-1 border border-gray-300 dark:border-gray-600 rounded bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100"
                                autoFocus
                                onKeyDown={(e) => {
                                  if (e.key === 'Enter') handleSaveEditedClue(word)
                                  if (e.key === 'Escape') handleCancelEdit()
                                }}
                              />
                              <button
                                type="button"
                                onClick={() => handleSaveEditedClue(word)}
                                className="px-2 py-1 bg-green-600 text-white rounded hover:bg-green-700"
                              >
                                <Check className="w-4 h-4" />
                              </button>
                              <button
                                type="button"
                                onClick={handleCancelEdit}
                                className="px-2 py-1 bg-gray-400 text-white rounded hover:bg-gray-500"
                              >
                                <X className="w-4 h-4" />
                              </button>
                            </div>
                          ) : (
                            <span className="text-gray-600 dark:text-gray-400">{clue}</span>
                          )}
                        </td>
                        <td className="px-4 py-2">
                          {editingClue !== word && (
                            <button
                              type="button"
                              onClick={() => handleEditClue(word, clue)}
                              className="p-1 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
                              title="Edit clue"
                            >
                              <Pencil className="w-4 h-4" />
                            </button>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  )
}

export default WordForgeEditor
