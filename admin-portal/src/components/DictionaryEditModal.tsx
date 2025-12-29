import { useState } from 'react'
import { X, Book } from 'lucide-react'

interface DictionaryWord {
  _id: string
  word: string
  length: number
  letters: string[]
  clue?: string
}

interface DictionaryEditModalProps {
  word: DictionaryWord
  onClose: () => void
  onSave: (clue: string) => void
  isSaving: boolean
}

export default function DictionaryEditModal({
  word,
  onClose,
  onSave,
  isSaving,
}: DictionaryEditModalProps) {
  const [clue, setClue] = useState(word.clue || '')

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    onSave(clue.trim())
  }

  const isPlaceholder = word.clue?.startsWith('Define:')

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="absolute inset-0 bg-black/50" onClick={onClose} />
      <div className="relative bg-white dark:bg-gray-800 rounded-xl shadow-xl max-w-md w-full mx-4">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200 dark:border-gray-700">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-blue-100 dark:bg-blue-900/30">
              <Book className="w-5 h-5 text-blue-600 dark:text-blue-400" />
            </div>
            <div>
              <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
                Edit Clue
              </h2>
              <p className="text-sm text-gray-500 dark:text-gray-400">
                {word.word} ({word.length} letters)
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-2 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Word
            </label>
            <div className="px-4 py-3 bg-gray-100 dark:bg-gray-700 rounded-lg font-mono text-lg font-medium text-gray-900 dark:text-white">
              {word.word}
            </div>
          </div>

          <div>
            <label
              htmlFor="clue"
              className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2"
            >
              Clue
            </label>
            <textarea
              id="clue"
              value={clue}
              onChange={(e) => setClue(e.target.value)}
              placeholder="Enter a short clue (5-6 words)..."
              rows={3}
              className="input"
            />
            {isPlaceholder && (
              <p className="mt-1 text-xs text-yellow-600 dark:text-yellow-400">
                This word has a placeholder clue. Please provide a real definition.
              </p>
            )}
            <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">
              Keep clues brief (5-6 words). Mix of straight and cryptic styles.
            </p>
          </div>

          {/* Actions */}
          <div className="flex items-center justify-end gap-3 pt-4">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isSaving}
              className="btn-primary"
            >
              {isSaving ? 'Saving...' : 'Save Clue'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
