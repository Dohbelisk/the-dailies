import { useState, useCallback, useEffect, useMemo } from 'react'
import { useMutation } from '@tanstack/react-query'
import { Shuffle, CheckCircle, Sparkles, Loader2 } from 'lucide-react'
import CategoryGroupEditor, { CategoryGroup } from './shared/CategoryGroupEditor'
import ValidationStatus from './shared/ValidationStatus'
import { aiApi } from '../../lib/api'

interface ConnectionsEditorProps {
  initialData?: {
    words: string[]
    categories: CategoryGroup[]
  }
  onChange?: (puzzleData: any, solution: any, isValid?: boolean) => void
  className?: string
}

const createEmptyCategories = (): CategoryGroup[] => [
  { name: '', words: ['', '', '', ''], difficulty: 1 },
  { name: '', words: ['', '', '', ''], difficulty: 2 },
  { name: '', words: ['', '', '', ''], difficulty: 3 },
  { name: '', words: ['', '', '', ''], difficulty: 4 },
]

// Shuffle array using Fisher-Yates
const shuffleArray = <T,>(array: T[]): T[] => {
  const shuffled = [...array]
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1))
    ;[shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]]
  }
  return shuffled
}

export function ConnectionsEditor({
  initialData,
  onChange,
  className = '',
}: ConnectionsEditorProps) {
  const [categories, setCategories] = useState<CategoryGroup[]>(
    initialData?.categories || createEmptyCategories()
  )
  const [shuffledWords, setShuffledWords] = useState<string[]>([])
  const [validationResult, setValidationResult] = useState<{
    isValid: boolean
    hasUniqueSolution: boolean
    errors: { row: number; col: number; message: string }[]
  } | null>(null)
  const [theme, setTheme] = useState('')

  // AI generation mutation
  const generateMutation = useMutation({
    mutationFn: async (themeText?: string) => {
      const response = await aiApi.generateConnections(themeText || undefined)
      return response.data
    },
    onSuccess: (data) => {
      if (data.categories && data.categories.length === 4) {
        setCategories(data.categories)
        setValidationResult(null)
        setShuffledWords([])
      }
    },
    onError: (error: any) => {
      alert(error.response?.data?.message || 'Failed to generate puzzle')
    },
  })

  const handleGenerate = useCallback(() => {
    generateMutation.mutate(theme.trim() || undefined)
  }, [theme, generateMutation])

  // Initialize shuffled words from initial data
  useEffect(() => {
    if (initialData?.words) {
      setShuffledWords(initialData.words)
    }
  }, [initialData])

  // Notify parent of changes
  useEffect(() => {
    if (onChange && validationResult?.isValid) {
      onChange(
        { words: shuffledWords, categories },
        { categories },
        true
      )
    }
  }, [shuffledWords, categories, onChange, validationResult])

  const handleCategoryChange = useCallback((index: number, category: CategoryGroup) => {
    setCategories(prev => {
      const newCategories = [...prev]
      newCategories[index] = category
      return newCategories
    })
    setValidationResult(null)
  }, [])

  const handleValidate = useCallback(() => {
    const errors: { row: number; col: number; message: string }[] = []

    // Check all category names are filled
    categories.forEach((cat, i) => {
      if (!cat.name.trim()) {
        errors.push({
          row: i,
          col: -1,
          message: `Category ${i + 1} needs a name`,
        })
      }
    })

    // Check all words are filled
    categories.forEach((cat, catIdx) => {
      cat.words.forEach((word, wordIdx) => {
        if (!word.trim()) {
          errors.push({
            row: catIdx,
            col: wordIdx,
            message: `Category ${catIdx + 1}, Word ${wordIdx + 1} is empty`,
          })
        }
      })
    })

    // Check for duplicate words across all categories
    const allWords = categories.flatMap(c => c.words.map(w => w.trim().toUpperCase()))
    const wordCounts = new Map<string, number>()
    allWords.forEach(word => {
      if (word) {
        wordCounts.set(word, (wordCounts.get(word) || 0) + 1)
      }
    })

    wordCounts.forEach((count, word) => {
      if (count > 1) {
        errors.push({
          row: -1,
          col: -1,
          message: `"${word}" appears ${count} times (must be unique)`,
        })
      }
    })

    if (errors.length > 0) {
      setValidationResult({
        isValid: false,
        hasUniqueSolution: false,
        errors,
      })
      return
    }

    // Validation passed - shuffle words
    const allValidWords = categories.flatMap(c => c.words.map(w => w.trim().toUpperCase()))
    setShuffledWords(shuffleArray(allValidWords))
    setValidationResult({
      isValid: true,
      hasUniqueSolution: true,
      errors: [],
    })
  }, [categories])

  const handleShuffle = useCallback(() => {
    if (shuffledWords.length > 0) {
      setShuffledWords(shuffleArray(shuffledWords))
    }
  }, [shuffledWords])

  // Calculate stats
  const stats = useMemo(() => {
    const filledWords = categories.flatMap(c => c.words).filter(w => w.trim()).length
    const filledCategories = categories.filter(c => c.name.trim()).length
    return { filledWords, filledCategories }
  }, [categories])

  return (
    <div className={`space-y-6 ${className}`}>
      {/* AI Generator */}
      <div className="p-4 bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-800 rounded-lg">
        <h4 className="font-medium text-purple-800 dark:text-purple-200 mb-3 flex items-center gap-2">
          <Sparkles className="w-4 h-4" />
          AI Puzzle Generator
        </h4>
        <div className="flex gap-2">
          <input
            type="text"
            value={theme}
            onChange={(e) => setTheme(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && handleGenerate()}
            placeholder="Enter a theme (optional, e.g., Movies, Sports, Food...)"
            className="flex-1 px-3 py-2 border border-purple-300 dark:border-purple-700 rounded-md
                       bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100"
          />
          <button
            type="button"
            onClick={handleGenerate}
            disabled={generateMutation.isPending}
            className="flex items-center gap-2 px-4 py-2 bg-purple-500 text-white rounded-md
                       hover:bg-purple-600 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            {generateMutation.isPending ? (
              <Loader2 className="w-4 h-4 animate-spin" />
            ) : (
              <Sparkles className="w-4 h-4" />
            )}
            Generate
          </button>
        </div>
        <p className="text-xs text-purple-600 dark:text-purple-400 mt-2">
          Leave theme empty for a random creative puzzle, or enter a theme for targeted categories.
        </p>
      </div>

      {/* Categories */}
      <div className="space-y-4">
        {categories.map((category, index) => (
          <CategoryGroupEditor
            key={index}
            category={category}
            onChange={(updated) => handleCategoryChange(index, updated)}
          />
        ))}
      </div>

      {/* Stats */}
      <div className="flex items-center gap-4 text-sm text-gray-500 dark:text-gray-400">
        <span>
          {stats.filledCategories}/4 categories named
        </span>
        <span>
          {stats.filledWords}/16 words filled
        </span>
      </div>

      {/* Actions */}
      <div className="flex gap-2 flex-wrap">
        <button
          type="button"
          onClick={handleValidate}
          className="flex items-center gap-2 px-4 py-2 bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 rounded-md hover:bg-blue-200 dark:hover:bg-blue-900/50 transition-colors"
        >
          <CheckCircle className="w-4 h-4" />
          Validate
        </button>
        {shuffledWords.length > 0 && (
          <button
            type="button"
            onClick={handleShuffle}
            className="flex items-center gap-2 px-4 py-2 bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-300 rounded-md hover:bg-purple-200 dark:hover:bg-purple-900/50 transition-colors"
          >
            <Shuffle className="w-4 h-4" />
            Re-shuffle Preview
          </button>
        )}
      </div>

      {/* Validation status */}
      <ValidationStatus
        isValid={validationResult?.isValid}
        hasUniqueSolution={validationResult?.hasUniqueSolution}
        errors={validationResult?.errors}
      />

      {/* Preview Grid */}
      {shuffledWords.length === 16 && (
        <div className="mt-6">
          <h4 className="font-medium text-gray-700 dark:text-gray-300 mb-3">
            Preview (shuffled 4x4 grid)
          </h4>
          <div className="grid grid-cols-4 gap-2 max-w-md">
            {shuffledWords.map((word, index) => (
              <div
                key={index}
                className="p-3 bg-gray-100 dark:bg-gray-700 rounded-lg text-center
                           text-sm font-medium text-gray-800 dark:text-gray-200
                           uppercase tracking-wide"
              >
                {word}
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Solution Reference */}
      {validationResult?.isValid && (
        <div className="mt-4 p-4 bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg">
          <h4 className="font-medium text-green-800 dark:text-green-200 mb-2">
            Solution Reference
          </h4>
          <div className="space-y-2">
            {categories.map((cat, idx) => (
              <div key={idx} className="text-sm">
                <span className={`font-medium ${
                  cat.difficulty === 1 ? 'text-yellow-600 dark:text-yellow-400' :
                  cat.difficulty === 2 ? 'text-green-600 dark:text-green-400' :
                  cat.difficulty === 3 ? 'text-blue-600 dark:text-blue-400' :
                  'text-purple-600 dark:text-purple-400'
                }`}>
                  {cat.name}:
                </span>
                <span className="text-gray-600 dark:text-gray-400 ml-2">
                  {cat.words.map(w => w.toUpperCase()).join(', ')}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}

export default ConnectionsEditor
