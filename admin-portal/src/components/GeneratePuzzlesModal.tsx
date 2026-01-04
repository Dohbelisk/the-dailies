import { useState } from 'react'
import { X, Loader2, Sparkles, CheckCircle, XCircle, AlertTriangle } from 'lucide-react'
import { generateApi, GAME_TYPES, GAME_TYPE_LABELS, GameType, Difficulty } from '../lib/api'

interface GeneratePuzzlesModalProps {
  isOpen: boolean
  onClose: () => void
  date: string
  onSuccess: () => void
}

interface PuzzleConfig {
  enabled: boolean
  difficulty: Difficulty
}

type GenerateStatus = 'idle' | 'generating' | 'success' | 'error'

interface GenerationResult {
  gameType: GameType
  status: 'success' | 'error'
  message?: string
}

// Default crossword and word search data for auto-generation
const DEFAULT_CROSSWORD_DATA = [
  { word: 'FLUTTER', clue: 'Google UI toolkit for mobile apps' },
  { word: 'REACT', clue: 'Popular JavaScript library for UIs' },
  { word: 'CODE', clue: 'What programmers write' },
  { word: 'DEBUG', clue: 'Find and fix errors' },
  { word: 'API', clue: 'Application Programming Interface' },
]

const DEFAULT_WORD_SEARCH_DATA = {
  theme: 'Technology',
  words: ['COMPUTER', 'INTERNET', 'SOFTWARE', 'HARDWARE', 'DATABASE', 'NETWORK', 'MOBILE', 'CLOUD'],
}

// Games that can be auto-generated without additional input
const AUTO_GENERATABLE_GAMES: GameType[] = [
  'sudoku',
  'killerSudoku',
  'wordForge',
  'nonogram',
  'numberTarget',
  'ballSort',
  'pipes',
  'lightsOut',
  'wordLadder',
  'connections',
  'mathora',
]

// Games that need special handling (will use defaults)
const SPECIAL_GAMES: GameType[] = ['crossword', 'wordSearch']

export default function GeneratePuzzlesModal({
  isOpen,
  onClose,
  date,
  onSuccess,
}: GeneratePuzzlesModalProps) {
  const [configs, setConfigs] = useState<Record<GameType, PuzzleConfig>>(() => {
    const initial: Record<string, PuzzleConfig> = {}
    GAME_TYPES.forEach((type) => {
      initial[type] = { enabled: false, difficulty: 'medium' }
    })
    return initial as Record<GameType, PuzzleConfig>
  })

  const [status, setStatus] = useState<GenerateStatus>('idle')
  const [results, setResults] = useState<GenerationResult[]>([])

  const toggleGame = (gameType: GameType) => {
    setConfigs((prev) => ({
      ...prev,
      [gameType]: { ...prev[gameType], enabled: !prev[gameType].enabled },
    }))
  }

  const setDifficulty = (gameType: GameType, difficulty: Difficulty) => {
    setConfigs((prev) => ({
      ...prev,
      [gameType]: { ...prev[gameType], difficulty },
    }))
  }

  const selectAll = () => {
    const newConfigs = { ...configs }
    GAME_TYPES.forEach((type) => {
      newConfigs[type] = { ...newConfigs[type], enabled: true }
    })
    setConfigs(newConfigs)
  }

  const selectNone = () => {
    const newConfigs = { ...configs }
    GAME_TYPES.forEach((type) => {
      newConfigs[type] = { ...newConfigs[type], enabled: false }
    })
    setConfigs(newConfigs)
  }

  const setAllDifficulty = (difficulty: Difficulty) => {
    const newConfigs = { ...configs }
    GAME_TYPES.forEach((type) => {
      newConfigs[type] = { ...newConfigs[type], difficulty }
    })
    setConfigs(newConfigs)
  }

  const handleGenerate = async () => {
    const enabledGames = GAME_TYPES.filter((type) => configs[type].enabled)
    if (enabledGames.length === 0) return

    setStatus('generating')
    setResults([])

    const generationResults: GenerationResult[] = []

    for (const gameType of enabledGames) {
      const config = configs[gameType]
      try {
        if (AUTO_GENERATABLE_GAMES.includes(gameType)) {
          // Simple generation - just needs date and difficulty
          const apiMethod = generateApi[gameType as keyof typeof generateApi]
          if (typeof apiMethod === 'function') {
            await (apiMethod as (date: string, difficulty: Difficulty) => Promise<any>)(
              date,
              config.difficulty
            )
          }
        } else if (gameType === 'crossword') {
          await generateApi.crossword(date, config.difficulty, DEFAULT_CROSSWORD_DATA)
        } else if (gameType === 'wordSearch') {
          await generateApi.wordSearch(
            date,
            config.difficulty,
            DEFAULT_WORD_SEARCH_DATA.words,
            DEFAULT_WORD_SEARCH_DATA.theme
          )
        }

        generationResults.push({ gameType, status: 'success' })
      } catch (error: any) {
        generationResults.push({
          gameType,
          status: 'error',
          message: error.response?.data?.message || error.message || 'Generation failed',
        })
      }

      setResults([...generationResults])
    }

    const hasErrors = generationResults.some((r) => r.status === 'error')
    setStatus(hasErrors ? 'error' : 'success')

    if (!hasErrors) {
      setTimeout(() => {
        onSuccess()
        handleClose()
      }, 1500)
    }
  }

  const handleClose = () => {
    if (status !== 'generating') {
      setStatus('idle')
      setResults([])
      onClose()
    }
  }

  const enabledCount = GAME_TYPES.filter((type) => configs[type].enabled).length

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex min-h-full items-center justify-center p-4">
        {/* Backdrop */}
        <div
          className="fixed inset-0 bg-black/50 transition-opacity"
          onClick={handleClose}
        />

        {/* Modal */}
        <div className="relative bg-white dark:bg-gray-800 rounded-xl shadow-xl max-w-2xl w-full max-h-[90vh] overflow-hidden">
          {/* Header */}
          <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200 dark:border-gray-700">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-primary-100 dark:bg-primary-900/30 rounded-lg">
                <Sparkles className="w-5 h-5 text-primary-600 dark:text-primary-400" />
              </div>
              <div>
                <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
                  Generate Puzzles
                </h2>
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  {new Date(date).toLocaleDateString('en-US', {
                    weekday: 'long',
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric',
                  })}
                </p>
              </div>
            </div>
            <button
              onClick={handleClose}
              disabled={status === 'generating'}
              className="p-2 text-gray-400 hover:text-gray-500 disabled:opacity-50"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          {/* Content */}
          <div className="px-6 py-4 max-h-[60vh] overflow-y-auto">
            {status === 'idle' && (
              <>
                {/* Quick Actions */}
                <div className="flex items-center justify-between mb-4">
                  <div className="flex gap-2">
                    <button
                      onClick={selectAll}
                      className="px-3 py-1.5 text-sm bg-gray-100 hover:bg-gray-200 dark:bg-gray-700 dark:hover:bg-gray-600 rounded-lg transition-colors"
                    >
                      Select All
                    </button>
                    <button
                      onClick={selectNone}
                      className="px-3 py-1.5 text-sm bg-gray-100 hover:bg-gray-200 dark:bg-gray-700 dark:hover:bg-gray-600 rounded-lg transition-colors"
                    >
                      Select None
                    </button>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className="text-sm text-gray-500 dark:text-gray-400">Set all to:</span>
                    <select
                      onChange={(e) => setAllDifficulty(e.target.value as Difficulty)}
                      className="px-2 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700"
                    >
                      <option value="">--</option>
                      <option value="easy">Easy</option>
                      <option value="medium">Medium</option>
                      <option value="hard">Hard</option>
                      <option value="expert">Expert</option>
                    </select>
                  </div>
                </div>

                {/* Game List */}
                <div className="space-y-2">
                  {GAME_TYPES.map((gameType) => {
                    const config = configs[gameType]
                    const isSpecial = SPECIAL_GAMES.includes(gameType)
                    const isWordSearch = gameType === 'wordSearch'

                    return (
                      <div
                        key={gameType}
                        className={`flex items-center justify-between p-3 rounded-lg border transition-colors ${
                          config.enabled
                            ? 'border-primary-300 bg-primary-50 dark:border-primary-700 dark:bg-primary-900/20'
                            : 'border-gray-200 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-700/50'
                        }`}
                      >
                        <div className="flex items-center gap-3">
                          <input
                            type="checkbox"
                            checked={config.enabled}
                            onChange={() => toggleGame(gameType)}
                            className="w-4 h-4 text-primary-600 rounded border-gray-300 focus:ring-primary-500"
                          />
                          <div>
                            <span className="font-medium text-gray-900 dark:text-white">
                              {GAME_TYPE_LABELS[gameType]}
                            </span>
                            {isSpecial && (
                              <span className="ml-2 px-2 py-0.5 text-xs bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400 rounded-full">
                                Uses defaults
                              </span>
                            )}
                            {isWordSearch && (
                              <span className="ml-2 px-2 py-0.5 text-xs bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-400 rounded-full">
                                Inactive
                              </span>
                            )}
                          </div>
                        </div>
                        <select
                          value={config.difficulty}
                          onChange={(e) => setDifficulty(gameType, e.target.value as Difficulty)}
                          className={`px-3 py-1.5 text-sm border rounded-lg bg-white dark:bg-gray-700 ${
                            config.enabled
                              ? 'border-primary-300 dark:border-primary-600'
                              : 'border-gray-300 dark:border-gray-600'
                          }`}
                        >
                          <option value="easy">Easy</option>
                          <option value="medium">Medium</option>
                          <option value="hard">Hard</option>
                          <option value="expert">Expert</option>
                        </select>
                      </div>
                    )
                  })}
                </div>

                <div className="mt-4 p-3 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg">
                  <p className="text-sm text-blue-700 dark:text-blue-300">
                    <strong>Note:</strong> Crossword and Word Search use default content. Word Search
                    puzzles are generated as inactive.
                  </p>
                </div>
              </>
            )}

            {(status === 'generating' || status === 'success' || status === 'error') && (
              <div className="space-y-3">
                {results.map((result) => (
                  <div
                    key={result.gameType}
                    className={`flex items-center justify-between p-3 rounded-lg border ${
                      result.status === 'success'
                        ? 'border-green-200 bg-green-50 dark:border-green-800 dark:bg-green-900/20'
                        : 'border-red-200 bg-red-50 dark:border-red-800 dark:bg-red-900/20'
                    }`}
                  >
                    <div className="flex items-center gap-3">
                      {result.status === 'success' ? (
                        <CheckCircle className="w-5 h-5 text-green-500" />
                      ) : (
                        <XCircle className="w-5 h-5 text-red-500" />
                      )}
                      <span className="font-medium text-gray-900 dark:text-white">
                        {GAME_TYPE_LABELS[result.gameType]}
                      </span>
                    </div>
                    {result.status === 'error' && (
                      <span className="text-sm text-red-600 dark:text-red-400">
                        {result.message}
                      </span>
                    )}
                  </div>
                ))}

                {status === 'generating' && (
                  <div className="flex items-center justify-center gap-2 p-4 text-gray-500 dark:text-gray-400">
                    <Loader2 className="w-5 h-5 animate-spin" />
                    <span>
                      Generating {results.length + 1} of {enabledCount}...
                    </span>
                  </div>
                )}

                {status === 'success' && (
                  <div className="flex items-center justify-center gap-2 p-4 text-green-600 dark:text-green-400">
                    <CheckCircle className="w-5 h-5" />
                    <span>All puzzles generated successfully!</span>
                  </div>
                )}

                {status === 'error' && (
                  <div className="flex items-center gap-2 p-4 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg">
                    <AlertTriangle className="w-5 h-5 text-yellow-500" />
                    <span className="text-yellow-700 dark:text-yellow-300">
                      Some puzzles failed to generate. Successfully generated puzzles have been
                      saved.
                    </span>
                  </div>
                )}
              </div>
            )}
          </div>

          {/* Footer */}
          <div className="flex items-center justify-between px-6 py-4 border-t border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-900/50">
            <span className="text-sm text-gray-500 dark:text-gray-400">
              {enabledCount} puzzle{enabledCount !== 1 ? 's' : ''} selected
            </span>
            <div className="flex gap-3">
              <button
                onClick={handleClose}
                disabled={status === 'generating'}
                className="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-600 disabled:opacity-50 transition-colors"
              >
                {status === 'error' ? 'Close' : 'Cancel'}
              </button>
              {status === 'idle' && (
                <button
                  onClick={handleGenerate}
                  disabled={enabledCount === 0}
                  className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-primary-600 rounded-lg hover:bg-primary-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                >
                  <Sparkles className="w-4 h-4" />
                  Generate {enabledCount > 0 ? `(${enabledCount})` : ''}
                </button>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
