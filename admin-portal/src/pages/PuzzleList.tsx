import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Link } from 'react-router-dom'
import { format } from 'date-fns'
import toast from 'react-hot-toast'
import {
  Plus,
  Search,
  Filter,
  MoreVertical,
  Edit,
  Trash2,
  Eye,
  EyeOff,
  Grid3X3,
  Hash,
  FileText,
  Hexagon,
  LayoutGrid,
  Target,
  Circle,
  GitBranch,
  Lightbulb,
  ArrowUpDown,
  Link2,
  Calendar,
  X,
  Calculator,
} from 'lucide-react'
import { puzzlesApi, PuzzleStatus } from '../lib/api'

const gameTypeIcons: Record<string, typeof Grid3X3> = {
  sudoku: Grid3X3,
  killerSudoku: Hash,
  crossword: FileText,
  wordSearch: Search,
  wordForge: Hexagon,
  nonogram: LayoutGrid,
  numberTarget: Target,
  ballSort: Circle,
  pipes: GitBranch,
  lightsOut: Lightbulb,
  wordLadder: ArrowUpDown,
  connections: Link2,
  mathora: Calculator,
}

const gameTypes = [
  { value: 'sudoku', label: 'Sudoku' },
  { value: 'killerSudoku', label: 'Killer Sudoku' },
  { value: 'crossword', label: 'Crossword' },
  { value: 'wordSearch', label: 'Word Search' },
  { value: 'wordForge', label: 'Word Forge' },
  { value: 'nonogram', label: 'Nonogram' },
  { value: 'numberTarget', label: 'Number Target' },
  { value: 'ballSort', label: 'Ball Sort' },
  { value: 'pipes', label: 'Pipes' },
  { value: 'lightsOut', label: 'Lights Out' },
  { value: 'wordLadder', label: 'Word Ladder' },
  { value: 'connections', label: 'Connections' },
  { value: 'mathora', label: 'Mathora' },
]

const difficulties = [
  { value: 'easy', label: 'Easy' },
  { value: 'medium', label: 'Medium' },
  { value: 'hard', label: 'Hard' },
  { value: 'expert', label: 'Expert' },
]

export default function PuzzleList() {
  const [searchQuery, setSearchQuery] = useState('')
  const [gameTypeFilter, setGameTypeFilter] = useState<string>('')
  const [difficultyFilter, setDifficultyFilter] = useState<string>('')
  const [statusFilter, setStatusFilter] = useState<string>('')
  const [dateFrom, setDateFrom] = useState<string>('')
  const [dateTo, setDateTo] = useState<string>('')
  const [activeMenu, setActiveMenu] = useState<string | null>(null)

  const hasActiveFilters = gameTypeFilter || difficultyFilter || statusFilter || dateFrom || dateTo

  const clearFilters = () => {
    setGameTypeFilter('')
    setDifficultyFilter('')
    setStatusFilter('')
    setDateFrom('')
    setDateTo('')
    setSearchQuery('')
  }

  const queryClient = useQueryClient()

  const { data: puzzles, isLoading } = useQuery({
    queryKey: ['puzzles', gameTypeFilter],
    queryFn: () =>
      puzzlesApi
        .getAll(gameTypeFilter ? { gameType: gameTypeFilter } : {})
        .then((res) => res.data),
  })

  const deleteMutation = useMutation({
    mutationFn: (id: string) => puzzlesApi.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['puzzles'] })
      toast.success('Puzzle deleted')
    },
    onError: () => {
      toast.error('Failed to delete puzzle')
    },
  })

  const toggleActiveMutation = useMutation({
    mutationFn: (id: string) => puzzlesApi.toggleActive(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['puzzles'] })
      toast.success('Puzzle updated')
    },
    onError: () => {
      toast.error('Failed to update puzzle')
    },
  })

  const updateStatusMutation = useMutation({
    mutationFn: ({ id, status }: { id: string; status: PuzzleStatus }) =>
      puzzlesApi.updateStatus(id, status),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['puzzles'] })
      toast.success('Puzzle status updated')
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Failed to update puzzle status')
    },
  })

  const filteredPuzzles = puzzles?.filter((puzzle: any) => {
    // Search filter
    if (searchQuery) {
      const search = searchQuery.toLowerCase()
      const matchesSearch =
        puzzle.title?.toLowerCase().includes(search) ||
        puzzle.gameType.toLowerCase().includes(search) ||
        puzzle.difficulty.toLowerCase().includes(search)
      if (!matchesSearch) return false
    }

    // Difficulty filter
    if (difficultyFilter && puzzle.difficulty !== difficultyFilter) {
      return false
    }

    // Status filter - check both new status field and legacy isActive
    if (statusFilter) {
      const puzzleStatus = puzzle.status || (puzzle.isActive ? 'active' : 'inactive')
      if (puzzleStatus !== statusFilter) return false
    }

    // Date range filter
    if (dateFrom) {
      const puzzleDate = new Date(puzzle.date)
      const fromDate = new Date(dateFrom)
      if (puzzleDate < fromDate) return false
    }

    if (dateTo) {
      const puzzleDate = new Date(puzzle.date)
      const toDate = new Date(dateTo)
      toDate.setHours(23, 59, 59, 999) // Include the entire day
      if (puzzleDate > toDate) return false
    }

    return true
  })

  const handleDelete = (id: string) => {
    if (confirm('Are you sure you want to delete this puzzle?')) {
      deleteMutation.mutate(id)
    }
    setActiveMenu(null)
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
          Puzzles
        </h1>
        <Link to="/puzzles/create" className="btn btn-primary">
          <Plus className="w-4 h-4" />
          New Puzzle
        </Link>
      </div>

      {/* Filters */}
      <div className="card p-4 space-y-4">
        {/* Search and primary filters */}
        <div className="flex flex-col lg:flex-row gap-4">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              placeholder="Search puzzles..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="input pl-10"
            />
          </div>

          <div className="flex flex-wrap items-center gap-2">
            <Filter className="w-4 h-4 text-gray-400" />

            {/* Game Type Filter */}
            <select
              value={gameTypeFilter}
              onChange={(e) => setGameTypeFilter(e.target.value)}
              className="input w-auto"
            >
              <option value="">All Types</option>
              {gameTypes.map((type) => (
                <option key={type.value} value={type.value}>
                  {type.label}
                </option>
              ))}
            </select>

            {/* Difficulty Filter */}
            <select
              value={difficultyFilter}
              onChange={(e) => setDifficultyFilter(e.target.value)}
              className="input w-auto"
            >
              <option value="">All Difficulties</option>
              {difficulties.map((diff) => (
                <option key={diff.value} value={diff.value}>
                  {diff.label}
                </option>
              ))}
            </select>

            {/* Status Filter */}
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="input w-auto"
            >
              <option value="">All Status</option>
              <option value="pending">Pending</option>
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
            </select>
          </div>
        </div>

        {/* Date range filters */}
        <div className="flex flex-wrap items-center gap-4">
          <div className="flex items-center gap-2">
            <Calendar className="w-4 h-4 text-gray-400" />
            <span className="text-sm text-gray-500 dark:text-gray-400">Date Range:</span>
          </div>
          <div className="flex items-center gap-2">
            <input
              type="date"
              value={dateFrom}
              onChange={(e) => setDateFrom(e.target.value)}
              className="input w-auto"
              placeholder="From"
            />
            <span className="text-gray-400">to</span>
            <input
              type="date"
              value={dateTo}
              onChange={(e) => setDateTo(e.target.value)}
              className="input w-auto"
              placeholder="To"
            />
          </div>

          {/* Clear filters button */}
          {hasActiveFilters && (
            <button
              onClick={clearFilters}
              className="flex items-center gap-1 px-3 py-1.5 text-sm text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white bg-gray-100 dark:bg-gray-700 rounded-lg transition-colors"
            >
              <X className="w-3 h-3" />
              Clear filters
            </button>
          )}
        </div>

        {/* Results count */}
        {filteredPuzzles && (
          <div className="text-sm text-gray-500 dark:text-gray-400">
            Showing {filteredPuzzles.length} of {puzzles?.length || 0} puzzles
          </div>
        )}
      </div>

      {/* Table */}
      <div className="card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 dark:bg-gray-700/50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Puzzle
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Type
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Difficulty
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Date
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Status
                </th>
                <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
              {isLoading ? (
                <tr>
                  <td colSpan={6} className="px-6 py-12 text-center text-gray-500">
                    Loading puzzles...
                  </td>
                </tr>
              ) : filteredPuzzles?.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-6 py-12 text-center text-gray-500">
                    No puzzles found
                  </td>
                </tr>
              ) : (
                filteredPuzzles?.map((puzzle: any) => {
                  const Icon = gameTypeIcons[puzzle.gameType] || Grid3X3
                  const displayTypeMap: Record<string, string> = {
                    sudoku: 'Sudoku',
                    killerSudoku: 'Killer Sudoku',
                    crossword: 'Crossword',
                    wordSearch: 'Word Search',
                    wordForge: 'Word Forge',
                    nonogram: 'Nonogram',
                    numberTarget: 'Number Target',
                    ballSort: 'Ball Sort',
                    pipes: 'Pipes',
                    lightsOut: 'Lights Out',
                    wordLadder: 'Word Ladder',
                    connections: 'Connections',
                    mathora: 'Mathora',
                  }
                  const displayType = displayTypeMap[puzzle.gameType] || puzzle.gameType

                  return (
                    <tr
                      key={puzzle._id}
                      className="hover:bg-gray-50 dark:hover:bg-gray-700/50"
                    >
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 bg-gray-100 dark:bg-gray-700 rounded-lg flex items-center justify-center">
                            <Icon className="w-5 h-5 text-gray-600 dark:text-gray-400" />
                          </div>
                          <div>
                            <p className="font-medium text-gray-900 dark:text-white">
                              {puzzle.title || `Puzzle #${puzzle._id.slice(-6)}`}
                            </p>
                            <p className="text-sm text-gray-500 dark:text-gray-400">
                              Target: {puzzle.targetTime || 0}s
                            </p>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <span className="text-gray-900 dark:text-white">
                          {displayType}
                        </span>
                      </td>
                      <td className="px-6 py-4">
                        <span
                          className={`inline-flex px-2 py-1 text-xs font-medium rounded-full ${
                            puzzle.difficulty === 'easy'
                              ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400'
                              : puzzle.difficulty === 'medium'
                              ? 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400'
                              : puzzle.difficulty === 'hard'
                              ? 'bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400'
                              : 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400'
                          }`}
                        >
                          {puzzle.difficulty}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-gray-600 dark:text-gray-400">
                        {format(new Date(puzzle.date), 'MMM d, yyyy')}
                      </td>
                      <td className="px-6 py-4">
                        {(() => {
                          const status = puzzle.status || (puzzle.isActive ? 'active' : 'inactive')
                          const statusColors: Record<string, string> = {
                            pending: 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400',
                            active: 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400',
                            inactive: 'bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-400',
                          }
                          const statusLabels: Record<string, string> = {
                            pending: 'Pending',
                            active: 'Active',
                            inactive: 'Inactive',
                          }
                          return (
                            <span
                              className={`inline-flex px-2 py-1 text-xs font-medium rounded-full ${statusColors[status] || statusColors.inactive}`}
                            >
                              {statusLabels[status] || status}
                            </span>
                          )
                        })()}
                      </td>
                      <td className="px-6 py-4 text-right">
                        <div className="relative inline-block">
                          <button
                            onClick={() =>
                              setActiveMenu(
                                activeMenu === puzzle._id ? null : puzzle._id
                              )
                            }
                            className="p-2 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg"
                          >
                            <MoreVertical className="w-4 h-4" />
                          </button>

                          {activeMenu === puzzle._id && (
                            <>
                              <div
                                className="fixed inset-0 z-10"
                                onClick={() => setActiveMenu(null)}
                              />
                              <div className="absolute right-0 mt-2 w-48 bg-white dark:bg-gray-800 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700 z-20">
                                <Link
                                  to={`/puzzles/${puzzle._id}/edit`}
                                  className="flex items-center gap-2 px-4 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700"
                                >
                                  <Edit className="w-4 h-4" />
                                  Edit
                                </Link>
                                {(() => {
                                  const status = puzzle.status || (puzzle.isActive ? 'active' : 'inactive')
                                  if (status === 'active') {
                                    return (
                                      <button
                                        onClick={() => {
                                          updateStatusMutation.mutate({ id: puzzle._id, status: 'inactive' })
                                          setActiveMenu(null)
                                        }}
                                        className="w-full flex items-center gap-2 px-4 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700"
                                      >
                                        <EyeOff className="w-4 h-4" />
                                        Deactivate
                                      </button>
                                    )
                                  } else {
                                    return (
                                      <button
                                        onClick={() => {
                                          updateStatusMutation.mutate({ id: puzzle._id, status: 'active' })
                                          setActiveMenu(null)
                                        }}
                                        className="w-full flex items-center gap-2 px-4 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700"
                                      >
                                        <Eye className="w-4 h-4" />
                                        Activate
                                      </button>
                                    )
                                  }
                                })()}
                                <button
                                  onClick={() => handleDelete(puzzle._id)}
                                  className="w-full flex items-center gap-2 px-4 py-2 text-sm text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20"
                                >
                                  <Trash2 className="w-4 h-4" />
                                  Delete
                                </button>
                              </div>
                            </>
                          )}
                        </div>
                      </td>
                    </tr>
                  )
                })
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
