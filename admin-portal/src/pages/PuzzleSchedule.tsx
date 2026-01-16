import { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import {
  Calendar,
  CalendarDays,
  CalendarClock,
  Clock,
  CheckCircle,
  XCircle,
  Edit,
  BarChart3,
  Users,
  Timer,
  Trophy,
  AlertCircle,
  Sparkles,
} from 'lucide-react'
import { puzzlesApi, scoresApi, GAME_TYPE_LABELS, GameType } from '../lib/api'
import GeneratePuzzlesModal from '../components/GeneratePuzzlesModal'

type TabType = 'today' | 'tomorrow' | 'week' | 'yesterday'

interface Puzzle {
  _id: string
  gameType: GameType
  difficulty: string
  date: string
  isActive: boolean
  targetTime?: number
  title?: string
}

interface PuzzleStats {
  puzzleId: string
  totalPlays: number
  completions: number
  averageTime: number
  averageScore: number
  bestTime: number
  bestScore: number
}

function formatDate(date: Date): string {
  // Use local date components to avoid timezone issues
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

function formatDisplayDate(dateStr: string): string {
  const date = new Date(dateStr)
  return date.toLocaleDateString('en-US', {
    weekday: 'short',
    month: 'short',
    day: 'numeric',
  })
}

function formatTime(seconds: number): string {
  const mins = Math.floor(seconds / 60)
  const secs = seconds % 60
  return `${mins}:${secs.toString().padStart(2, '0')}`
}

function getDifficultyColor(difficulty: string): string {
  switch (difficulty.toLowerCase()) {
    case 'easy':
      return 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400'
    case 'medium':
      return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400'
    case 'hard':
      return 'bg-orange-100 text-orange-800 dark:bg-orange-900/30 dark:text-orange-400'
    case 'expert':
      return 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400'
    default:
      return 'bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-400'
  }
}

export default function PuzzleSchedule() {
  const [activeTab, setActiveTab] = useState<TabType>('today')
  const [puzzles, setPuzzles] = useState<Puzzle[]>([])
  const [stats, setStats] = useState<Record<string, PuzzleStats>>({})
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [showGenerateModal, setShowGenerateModal] = useState(false)
  const [generateDate, setGenerateDate] = useState<string>('')

  const tabs: { id: TabType; label: string; icon: React.ReactNode }[] = [
    { id: 'today', label: "Today's Puzzles", icon: <Calendar className="w-4 h-4" /> },
    { id: 'tomorrow', label: "Tomorrow's Puzzles", icon: <CalendarClock className="w-4 h-4" /> },
    { id: 'week', label: "This Week", icon: <CalendarDays className="w-4 h-4" /> },
    { id: 'yesterday', label: "Yesterday's Puzzles", icon: <Clock className="w-4 h-4" /> },
  ]

  useEffect(() => {
    loadPuzzles()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [activeTab])

  const getDateRange = (): { startDate: string; endDate: string } => {
    const now = new Date()
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())

    switch (activeTab) {
      case 'today':
        return { startDate: formatDate(today), endDate: formatDate(today) }
      case 'tomorrow': {
        const tomorrow = new Date(today)
        tomorrow.setDate(tomorrow.getDate() + 1)
        return { startDate: formatDate(tomorrow), endDate: formatDate(tomorrow) }
      }
      case 'week': {
        const endOfWeek = new Date(today)
        endOfWeek.setDate(endOfWeek.getDate() + 6)
        return { startDate: formatDate(today), endDate: formatDate(endOfWeek) }
      }
      case 'yesterday': {
        const yesterday = new Date(today)
        yesterday.setDate(yesterday.getDate() - 1)
        return { startDate: formatDate(yesterday), endDate: formatDate(yesterday) }
      }
    }
  }

  const getCurrentTabDate = (): string => {
    const now = new Date()
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())

    if (activeTab === 'tomorrow') {
      const tomorrow = new Date(today)
      tomorrow.setDate(tomorrow.getDate() + 1)
      return formatDate(tomorrow)
    }
    return formatDate(today)
  }

  const handleOpenGenerateModal = () => {
    setGenerateDate(getCurrentTabDate())
    setShowGenerateModal(true)
  }

  const loadPuzzles = async () => {
    setLoading(true)
    setError(null)

    try {
      const { startDate, endDate } = getDateRange()
      const response = await puzzlesApi.getByDateRange(startDate, endDate)
      const puzzleData = response.data as Puzzle[]
      setPuzzles(puzzleData)

      // Load stats for yesterday's puzzles
      if (activeTab === 'yesterday' && puzzleData.length > 0) {
        const statsMap: Record<string, PuzzleStats> = {}
        await Promise.all(
          puzzleData.map(async (puzzle) => {
            try {
              const statsResponse = await scoresApi.getByPuzzle(puzzle._id)
              const scores = statsResponse.data as any[]

              if (scores.length > 0) {
                const completedScores = scores.filter((s) => s.completed)
                statsMap[puzzle._id] = {
                  puzzleId: puzzle._id,
                  totalPlays: scores.length,
                  completions: completedScores.length,
                  averageTime: completedScores.length > 0
                    ? Math.round(completedScores.reduce((sum, s) => sum + s.time, 0) / completedScores.length)
                    : 0,
                  averageScore: completedScores.length > 0
                    ? Math.round(completedScores.reduce((sum, s) => sum + s.score, 0) / completedScores.length)
                    : 0,
                  bestTime: completedScores.length > 0
                    ? Math.min(...completedScores.map((s) => s.time))
                    : 0,
                  bestScore: completedScores.length > 0
                    ? Math.max(...completedScores.map((s) => s.score))
                    : 0,
                }
              }
            } catch (e) {
              // Stats not available for this puzzle
            }
          })
        )
        setStats(statsMap)
      } else {
        setStats({})
      }
    } catch (e: any) {
      setError(e.message || 'Failed to load puzzles')
    } finally {
      setLoading(false)
    }
  }

  // Group puzzles by date for week view
  const puzzlesByDate = puzzles.reduce<Record<string, Puzzle[]>>((acc, puzzle) => {
    const date = puzzle.date.split('T')[0]
    if (!acc[date]) acc[date] = []
    acc[date].push(puzzle)
    return acc
  }, {})

  const renderPuzzleCard = (puzzle: Puzzle, showStats: boolean = false) => {
    const puzzleStats = stats[puzzle._id]

    return (
      <div
        key={puzzle._id}
        className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4 hover:shadow-md transition-shadow"
      >
        <div className="flex items-start justify-between mb-3">
          <div>
            <h3 className="font-semibold text-gray-900 dark:text-white">
              {GAME_TYPE_LABELS[puzzle.gameType] || puzzle.gameType}
            </h3>
            {puzzle.title && (
              <p className="text-sm text-gray-500 dark:text-gray-400">{puzzle.title}</p>
            )}
          </div>
          <div className="flex items-center gap-2">
            <span
              className={`px-2 py-1 text-xs font-medium rounded-full ${getDifficultyColor(
                puzzle.difficulty
              )}`}
            >
              {puzzle.difficulty}
            </span>
            {puzzle.isActive ? (
              <span className="flex items-center gap-1 px-2 py-1 text-xs font-medium rounded-full bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400">
                <CheckCircle className="w-3.5 h-3.5" />
                Active
              </span>
            ) : (
              <span className="flex items-center gap-1 px-2 py-1 text-xs font-medium rounded-full bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-400">
                <XCircle className="w-3.5 h-3.5" />
                Pending
              </span>
            )}
          </div>
        </div>

        {puzzle.targetTime && (
          <div className="flex items-center gap-1 text-sm text-gray-500 dark:text-gray-400 mb-3">
            <Timer className="w-4 h-4" />
            <span>Target: {formatTime(puzzle.targetTime)}</span>
          </div>
        )}

        {/* Stats section for yesterday's puzzles */}
        {showStats && puzzleStats && (
          <div className="mt-3 pt-3 border-t border-gray-200 dark:border-gray-700">
            <div className="grid grid-cols-2 gap-3">
              <div className="flex items-center gap-2">
                <Users className="w-4 h-4 text-blue-500" />
                <div>
                  <p className="text-xs text-gray-500 dark:text-gray-400">Plays</p>
                  <p className="font-semibold text-gray-900 dark:text-white">
                    {puzzleStats.totalPlays}
                  </p>
                </div>
              </div>
              <div className="flex items-center gap-2">
                <CheckCircle className="w-4 h-4 text-green-500" />
                <div>
                  <p className="text-xs text-gray-500 dark:text-gray-400">Completions</p>
                  <p className="font-semibold text-gray-900 dark:text-white">
                    {puzzleStats.completions}
                  </p>
                </div>
              </div>
              <div className="flex items-center gap-2">
                <Timer className="w-4 h-4 text-orange-500" />
                <div>
                  <p className="text-xs text-gray-500 dark:text-gray-400">Avg Time</p>
                  <p className="font-semibold text-gray-900 dark:text-white">
                    {puzzleStats.averageTime > 0 ? formatTime(puzzleStats.averageTime) : '-'}
                  </p>
                </div>
              </div>
              <div className="flex items-center gap-2">
                <Trophy className="w-4 h-4 text-yellow-500" />
                <div>
                  <p className="text-xs text-gray-500 dark:text-gray-400">Avg Score</p>
                  <p className="font-semibold text-gray-900 dark:text-white">
                    {puzzleStats.averageScore > 0 ? puzzleStats.averageScore : '-'}
                  </p>
                </div>
              </div>
            </div>
            {puzzleStats.bestTime > 0 && (
              <div className="mt-2 pt-2 border-t border-gray-100 dark:border-gray-700 flex justify-between text-sm">
                <span className="text-gray-500 dark:text-gray-400">
                  Best: {formatTime(puzzleStats.bestTime)}
                </span>
                <span className="text-gray-500 dark:text-gray-400">
                  High Score: {puzzleStats.bestScore}
                </span>
              </div>
            )}
          </div>
        )}

        {showStats && !puzzleStats && (
          <div className="mt-3 pt-3 border-t border-gray-200 dark:border-gray-700">
            <p className="text-sm text-gray-400 dark:text-gray-500 italic">No plays yet</p>
          </div>
        )}

        {/* Actions */}
        <div className="mt-3 pt-3 border-t border-gray-200 dark:border-gray-700 flex gap-2">
          <Link
            to={`/puzzles/${puzzle._id}/edit`}
            className="flex-1 flex items-center justify-center gap-1 px-3 py-2 text-sm bg-gray-100 hover:bg-gray-200 dark:bg-gray-700 dark:hover:bg-gray-600 rounded-lg transition-colors"
          >
            <Edit className="w-4 h-4" />
            Edit
          </Link>
          {showStats && puzzleStats && puzzleStats.totalPlays > 0 && (
            <button
              className="flex-1 flex items-center justify-center gap-1 px-3 py-2 text-sm bg-blue-100 hover:bg-blue-200 dark:bg-blue-900/30 dark:hover:bg-blue-900/50 text-blue-700 dark:text-blue-400 rounded-lg transition-colors"
              onClick={() => {/* Could open detailed stats modal */}}
            >
              <BarChart3 className="w-4 h-4" />
              Details
            </button>
          )}
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
            Puzzle Schedule
          </h1>
          <p className="text-gray-500 dark:text-gray-400">
            View and manage puzzles by date
          </p>
        </div>
        {(activeTab === 'today' || activeTab === 'tomorrow') && (
          <button
            onClick={handleOpenGenerateModal}
            className="flex items-center gap-2 px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors"
          >
            <Sparkles className="w-4 h-4" />
            Generate Puzzles
          </button>
        )}
      </div>

      {/* Tabs */}
      <div className="border-b border-gray-200 dark:border-gray-700">
        <nav className="flex gap-4 -mb-px">
          {tabs.map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`flex items-center gap-2 px-4 py-3 text-sm font-medium border-b-2 transition-colors ${
                activeTab === tab.id
                  ? 'border-primary-500 text-primary-600 dark:text-primary-400'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 dark:text-gray-400 dark:hover:text-gray-300'
              }`}
            >
              {tab.icon}
              {tab.label}
            </button>
          ))}
        </nav>
      </div>

      {/* Content */}
      {loading ? (
        <div className="flex items-center justify-center py-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-500" />
        </div>
      ) : error ? (
        <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4 flex items-center gap-3">
          <AlertCircle className="w-5 h-5 text-red-500" />
          <p className="text-red-700 dark:text-red-400">{error}</p>
        </div>
      ) : puzzles.length === 0 ? (
        <div className="text-center py-12">
          <Calendar className="w-12 h-12 text-gray-300 dark:text-gray-600 mx-auto mb-4" />
          <p className="text-gray-500 dark:text-gray-400">No puzzles scheduled for this period</p>
          <Link
            to="/puzzles/generate"
            className="inline-flex items-center gap-2 mt-4 px-4 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition-colors"
          >
            Generate Puzzles
          </Link>
        </div>
      ) : activeTab === 'week' ? (
        // Week view - grouped by date
        <div className="space-y-8">
          {Object.entries(puzzlesByDate)
            .sort(([a], [b]) => a.localeCompare(b))
            .map(([date, datePuzzles]) => (
              <div key={date}>
                <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4 flex items-center gap-2">
                  <Calendar className="w-5 h-5 text-primary-500" />
                  {formatDisplayDate(date)}
                  <span className="text-sm font-normal text-gray-500 dark:text-gray-400">
                    ({datePuzzles.length} puzzle{datePuzzles.length !== 1 ? 's' : ''})
                  </span>
                </h2>
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
                  {datePuzzles.map((puzzle) => renderPuzzleCard(puzzle, false))}
                </div>
              </div>
            ))}
        </div>
      ) : (
        // Single day view
        <div>
          <div className="flex items-center gap-2 mb-4">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
              {puzzles.length} puzzle{puzzles.length !== 1 ? 's' : ''}
            </h2>
            {activeTab === 'yesterday' && (
              <span className="px-2 py-1 text-xs bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400 rounded-full">
                With Stats
              </span>
            )}
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
            {puzzles.map((puzzle) => renderPuzzleCard(puzzle, activeTab === 'yesterday'))}
          </div>
        </div>
      )}

      {/* Generate Puzzles Modal */}
      <GeneratePuzzlesModal
        isOpen={showGenerateModal}
        onClose={() => setShowGenerateModal(false)}
        date={generateDate}
        onSuccess={loadPuzzles}
      />
    </div>
  )
}
