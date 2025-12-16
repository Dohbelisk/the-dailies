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
} from 'lucide-react'
import { puzzlesApi } from '../lib/api'

const gameTypeIcons: Record<string, typeof Grid3X3> = {
  sudoku: Grid3X3,
  killerSudoku: Hash,
  crossword: FileText,
  wordSearch: Search,
}

export default function PuzzleList() {
  const [searchQuery, setSearchQuery] = useState('')
  const [gameTypeFilter, setGameTypeFilter] = useState<string>('')
  const [activeMenu, setActiveMenu] = useState<string | null>(null)

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

  const filteredPuzzles = puzzles?.filter((puzzle: any) => {
    if (!searchQuery) return true
    const search = searchQuery.toLowerCase()
    return (
      puzzle.title?.toLowerCase().includes(search) ||
      puzzle.gameType.toLowerCase().includes(search) ||
      puzzle.difficulty.toLowerCase().includes(search)
    )
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
      <div className="card p-4">
        <div className="flex flex-col sm:flex-row gap-4">
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
          <div className="flex items-center gap-2">
            <Filter className="w-4 h-4 text-gray-400" />
            <select
              value={gameTypeFilter}
              onChange={(e) => setGameTypeFilter(e.target.value)}
              className="input w-auto"
            >
              <option value="">All Types</option>
              <option value="sudoku">Sudoku</option>
              <option value="killerSudoku">Killer Sudoku</option>
              <option value="crossword">Crossword</option>
              <option value="wordSearch">Word Search</option>
            </select>
          </div>
        </div>
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
                  const displayType =
                    puzzle.gameType === 'killerSudoku'
                      ? 'Killer Sudoku'
                      : puzzle.gameType === 'wordSearch'
                      ? 'Word Search'
                      : puzzle.gameType.charAt(0).toUpperCase() +
                        puzzle.gameType.slice(1)

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
                        <span
                          className={`inline-flex px-2 py-1 text-xs font-medium rounded-full ${
                            puzzle.isActive
                              ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400'
                              : 'bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-400'
                          }`}
                        >
                          {puzzle.isActive ? 'Active' : 'Inactive'}
                        </span>
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
                                <button
                                  onClick={() => {
                                    toggleActiveMutation.mutate(puzzle._id)
                                    setActiveMenu(null)
                                  }}
                                  className="w-full flex items-center gap-2 px-4 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700"
                                >
                                  {puzzle.isActive ? (
                                    <>
                                      <EyeOff className="w-4 h-4" />
                                      Deactivate
                                    </>
                                  ) : (
                                    <>
                                      <Eye className="w-4 h-4" />
                                      Activate
                                    </>
                                  )}
                                </button>
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
