import { useCallback } from 'react'

export interface CategoryGroup {
  name: string
  words: string[]
  difficulty: number
}

interface CategoryGroupEditorProps {
  category: CategoryGroup
  onChange: (category: CategoryGroup) => void
  className?: string
}

const DIFFICULTY_STYLES: Record<number, { bg: string; border: string; label: string }> = {
  1: {
    bg: 'bg-yellow-100 dark:bg-yellow-900/30',
    border: 'border-yellow-400 dark:border-yellow-600',
    label: 'Easiest (Yellow)',
  },
  2: {
    bg: 'bg-green-100 dark:bg-green-900/30',
    border: 'border-green-400 dark:border-green-600',
    label: 'Easy (Green)',
  },
  3: {
    bg: 'bg-blue-100 dark:bg-blue-900/30',
    border: 'border-blue-400 dark:border-blue-600',
    label: 'Medium (Blue)',
  },
  4: {
    bg: 'bg-purple-100 dark:bg-purple-900/30',
    border: 'border-purple-400 dark:border-purple-600',
    label: 'Hardest (Purple)',
  },
}

export default function CategoryGroupEditor({
  category,
  onChange,
  className = '',
}: CategoryGroupEditorProps) {
  const style = DIFFICULTY_STYLES[category.difficulty] || DIFFICULTY_STYLES[1]

  const handleNameChange = useCallback(
    (name: string) => {
      onChange({ ...category, name })
    },
    [category, onChange]
  )

  const handleWordChange = useCallback(
    (index: number, word: string) => {
      const newWords = [...category.words]
      newWords[index] = word.toUpperCase()
      onChange({ ...category, words: newWords })
    },
    [category, onChange]
  )

  // Ensure we always have exactly 4 words
  const words = [...category.words]
  while (words.length < 4) {
    words.push('')
  }

  return (
    <div
      className={`p-4 rounded-lg border-2 ${style.bg} ${style.border} ${className}`}
    >
      <div className="flex items-center justify-between mb-3">
        <span className="text-sm font-medium text-gray-600 dark:text-gray-400">
          {style.label}
        </span>
      </div>

      <div className="space-y-3">
        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
            Category Name
          </label>
          <input
            type="text"
            value={category.name}
            onChange={(e) => handleNameChange(e.target.value)}
            placeholder="Enter category name..."
            className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md
                       bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100
                       focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
            Words (4 required)
          </label>
          <div className="grid grid-cols-2 gap-2">
            {words.slice(0, 4).map((word, index) => (
              <input
                key={index}
                type="text"
                value={word}
                onChange={(e) => handleWordChange(index, e.target.value)}
                placeholder={`Word ${index + 1}`}
                className="px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md
                           bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100
                           uppercase tracking-wide font-medium
                           focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              />
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
