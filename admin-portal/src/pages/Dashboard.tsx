import { useQuery } from '@tanstack/react-query'
import { Link } from 'react-router-dom'
import { format } from 'date-fns'
import {
  Puzzle,
  Calendar,
  TrendingUp,
  Plus,
  Grid3X3,
  Hash,
  FileText,
  Search,
  Hexagon,
  LayoutGrid,
  Target,
} from 'lucide-react'
import { puzzlesApi } from '../lib/api'

const gameTypeIcons: Record<string, typeof Grid3X3> = {
  sudoku: Grid3X3,
  killerSudoku: Hash,
  crossword: FileText,
  wordSearch: Search,
  wordForge: Hexagon,
  nonogram: LayoutGrid,
  numberTarget: Target,
}

const gameTypeColors: Record<string, string> = {
  sudoku: 'bg-indigo-100 text-indigo-700 dark:bg-indigo-900/30 dark:text-indigo-400',
  killerSudoku: 'bg-pink-100 text-pink-700 dark:bg-pink-900/30 dark:text-pink-400',
  crossword: 'bg-teal-100 text-teal-700 dark:bg-teal-900/30 dark:text-teal-400',
  wordSearch: 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400',
  wordForge: 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400',
  nonogram: 'bg-slate-100 text-slate-700 dark:bg-slate-900/30 dark:text-slate-400',
  numberTarget: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400',
}

export default function Dashboard() {
  const { data: stats, isLoading: statsLoading } = useQuery({
    queryKey: ['puzzleStats'],
    queryFn: () => puzzlesApi.getStats().then((res) => res.data),
  })

  const { data: todaysPuzzles, isLoading: todayLoading } = useQuery({
    queryKey: ['todaysPuzzles'],
    queryFn: () => puzzlesApi.getToday().then((res) => res.data),
  })

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
            Dashboard
          </h1>
          <p className="text-gray-500 dark:text-gray-400">
            {format(new Date(), 'EEEE, MMMM d, yyyy')}
          </p>
        </div>
        <Link to="/puzzles/create" className="btn btn-primary">
          <Plus className="w-4 h-4" />
          New Puzzle
        </Link>
      </div>

      {/* Stats cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="card p-6">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 bg-primary-100 dark:bg-primary-900/30 rounded-xl flex items-center justify-center">
              <Puzzle className="w-6 h-6 text-primary-600 dark:text-primary-400" />
            </div>
            <div>
              <p className="text-sm text-gray-500 dark:text-gray-400">
                Total Puzzles
              </p>
              <p className="text-2xl font-bold text-gray-900 dark:text-white">
                {statsLoading ? '...' : stats?.totalPuzzles || 0}
              </p>
            </div>
          </div>
        </div>

        <div className="card p-6">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 bg-green-100 dark:bg-green-900/30 rounded-xl flex items-center justify-center">
              <Calendar className="w-6 h-6 text-green-600 dark:text-green-400" />
            </div>
            <div>
              <p className="text-sm text-gray-500 dark:text-gray-400">
                Today's Puzzles
              </p>
              <p className="text-2xl font-bold text-gray-900 dark:text-white">
                {todayLoading ? '...' : todaysPuzzles?.length || 0}
              </p>
            </div>
          </div>
        </div>

        <div className="card p-6">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 bg-purple-100 dark:bg-purple-900/30 rounded-xl flex items-center justify-center">
              <TrendingUp className="w-6 h-6 text-purple-600 dark:text-purple-400" />
            </div>
            <div>
              <p className="text-sm text-gray-500 dark:text-gray-400">
                Active Puzzles
              </p>
              <p className="text-2xl font-bold text-gray-900 dark:text-white">
                {statsLoading
                  ? '...'
                  : Object.values(stats?.byGameType || {}).reduce(
                      (sum: number, t: any) => sum + (t.active || 0),
                      0
                    )}
              </p>
            </div>
          </div>
        </div>

        <div className="card p-6">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 bg-amber-100 dark:bg-amber-900/30 rounded-xl flex items-center justify-center">
              <Grid3X3 className="w-6 h-6 text-amber-600 dark:text-amber-400" />
            </div>
            <div>
              <p className="text-sm text-gray-500 dark:text-gray-400">
                Game Types
              </p>
              <p className="text-2xl font-bold text-gray-900 dark:text-white">7</p>
            </div>
          </div>
        </div>
      </div>

      {/* Puzzles by type */}
      <div className="card">
        <div className="p-6 border-b border-gray-200 dark:border-gray-700">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
            Puzzles by Type
          </h2>
        </div>
        <div className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            {['sudoku', 'killerSudoku', 'crossword', 'wordSearch', 'wordForge', 'nonogram', 'numberTarget'].map((type) => {
              const Icon = gameTypeIcons[type]
              const typeStats = stats?.byGameType?.[type] || { total: 0, active: 0 }
              const displayNameMap: Record<string, string> = {
                sudoku: 'Sudoku',
                killerSudoku: 'Killer Sudoku',
                crossword: 'Crossword',
                wordSearch: 'Word Search',
                wordForge: 'Word Forge',
                nonogram: 'Nonogram',
                numberTarget: 'Number Target',
              }
              const displayName = displayNameMap[type] || type

              return (
                <div
                  key={type}
                  className="p-4 rounded-xl bg-gray-50 dark:bg-gray-700/50"
                >
                  <div className="flex items-center gap-3 mb-3">
                    <div
                      className={`w-10 h-10 rounded-lg flex items-center justify-center ${gameTypeColors[type]}`}
                    >
                      <Icon className="w-5 h-5" />
                    </div>
                    <span className="font-medium text-gray-900 dark:text-white">
                      {displayName}
                    </span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-500 dark:text-gray-400">Total</span>
                    <span className="font-medium text-gray-900 dark:text-white">
                      {typeStats.total}
                    </span>
                  </div>
                  <div className="flex justify-between text-sm mt-1">
                    <span className="text-gray-500 dark:text-gray-400">Active</span>
                    <span className="font-medium text-green-600 dark:text-green-400">
                      {typeStats.active}
                    </span>
                  </div>
                </div>
              )
            })}
          </div>
        </div>
      </div>

      {/* Today's puzzles */}
      <div className="card">
        <div className="p-6 border-b border-gray-200 dark:border-gray-700 flex items-center justify-between">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
            Today's Puzzles
          </h2>
          <Link
            to="/puzzles/create"
            className="text-sm text-primary-600 hover:text-primary-700 dark:text-primary-400"
          >
            Add Puzzle →
          </Link>
        </div>
        <div className="divide-y divide-gray-200 dark:divide-gray-700">
          {todayLoading ? (
            <div className="p-6 text-center text-gray-500">Loading...</div>
          ) : todaysPuzzles?.length === 0 ? (
            <div className="p-6 text-center">
              <p className="text-gray-500 dark:text-gray-400 mb-4">
                No puzzles scheduled for today
              </p>
              <Link to="/puzzles/create" className="btn btn-primary">
                <Plus className="w-4 h-4" />
                Create Puzzle
              </Link>
            </div>
          ) : (
            todaysPuzzles?.map((puzzle: any) => {
              const Icon = gameTypeIcons[puzzle.gameType] || Puzzle
              return (
                <Link
                  key={puzzle._id}
                  to={`/puzzles/${puzzle._id}/edit`}
                  className="flex items-center gap-4 p-4 hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors"
                >
                  <div
                    className={`w-10 h-10 rounded-lg flex items-center justify-center ${
                      gameTypeColors[puzzle.gameType]
                    }`}
                  >
                    <Icon className="w-5 h-5" />
                  </div>
                  <div className="flex-1">
                    <p className="font-medium text-gray-900 dark:text-white">
                      {puzzle.title ||
                        `${puzzle.gameType} - ${puzzle.difficulty}`}
                    </p>
                    <p className="text-sm text-gray-500 dark:text-gray-400">
                      {puzzle.difficulty} • Target: {puzzle.targetTime}s
                    </p>
                  </div>
                  <span
                    className={`px-2 py-1 text-xs rounded-full ${
                      puzzle.isActive
                        ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400'
                        : 'bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-400'
                    }`}
                  >
                    {puzzle.isActive ? 'Active' : 'Inactive'}
                  </span>
                </Link>
              )
            })
          )}
        </div>
      </div>
    </div>
  )
}
