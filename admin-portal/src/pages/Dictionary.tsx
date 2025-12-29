import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import toast from 'react-hot-toast'
import {
  Search,
  Filter,
  MoreVertical,
  Trash2,
  Edit,
  Book,
  Hash,
  ChevronLeft,
  ChevronRight,
} from 'lucide-react'
import { dictionaryApi } from '../lib/api'
import DictionaryEditModal from '../components/DictionaryEditModal'

interface DictionaryWord {
  _id: string
  word: string
  length: number
  letters: string[]
  clue?: string
}

interface PaginationInfo {
  page: number
  limit: number
  total: number
  totalPages: number
}

export default function Dictionary() {
  const [searchQuery, setSearchQuery] = useState('')
  const [lengthFilter, setLengthFilter] = useState<string>('')
  const [startsWithFilter, setStartsWithFilter] = useState('')
  const [hasClueFilter, setHasClueFilter] = useState<string>('')
  const [page, setPage] = useState(1)
  const [activeMenu, setActiveMenu] = useState<string | null>(null)
  const [editingWord, setEditingWord] = useState<DictionaryWord | null>(null)

  const queryClient = useQueryClient()

  const { data, isLoading } = useQuery({
    queryKey: ['dictionary', page, searchQuery, lengthFilter, startsWithFilter, hasClueFilter],
    queryFn: () => {
      const params: Record<string, string | number> = { page, limit: 50 }
      if (searchQuery) params.search = searchQuery
      if (lengthFilter) params.length = parseInt(lengthFilter, 10)
      if (startsWithFilter) params.startsWith = startsWithFilter
      if (hasClueFilter) params.hasClue = hasClueFilter
      return dictionaryApi.getAll(params).then((res) => res.data)
    },
  })

  const { data: status } = useQuery({
    queryKey: ['dictionary-status'],
    queryFn: () => dictionaryApi.getStatus().then((res) => res.data),
  })

  const deleteMutation = useMutation({
    mutationFn: (word: string) => dictionaryApi.delete(word),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['dictionary'] })
      queryClient.invalidateQueries({ queryKey: ['dictionary-status'] })
      toast.success('Word deleted')
    },
    onError: () => {
      toast.error('Failed to delete word')
    },
  })

  const updateClueMutation = useMutation({
    mutationFn: ({ word, clue }: { word: string; clue: string }) =>
      dictionaryApi.updateClue(word, clue),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['dictionary'] })
      toast.success('Clue updated')
      setEditingWord(null)
    },
    onError: () => {
      toast.error('Failed to update clue')
    },
  })

  const words: DictionaryWord[] = data?.words || []
  const pagination: PaginationInfo = data?.pagination || { page: 1, limit: 50, total: 0, totalPages: 0 }

  const handleDelete = (word: string) => {
    if (confirm(`Are you sure you want to delete "${word}" from the dictionary?`)) {
      deleteMutation.mutate(word)
    }
    setActiveMenu(null)
  }

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault()
    setPage(1)
  }

  const hasClue = (word: DictionaryWord): boolean => {
    return !!word.clue && word.clue !== '' && !word.clue.startsWith('Define:')
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
            Dictionary
          </h1>
          {status && (
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
              {status.wordCount?.toLocaleString()} words
            </p>
          )}
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="card p-4">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-blue-100 dark:bg-blue-900/30">
              <Book className="w-4 h-4 text-blue-600 dark:text-blue-400" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900 dark:text-white">
                {status?.wordCount?.toLocaleString() || 0}
              </p>
              <p className="text-xs text-gray-500 dark:text-gray-400">Total Words</p>
            </div>
          </div>
        </div>
        <div className="card p-4">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-green-100 dark:bg-green-900/30">
              <Hash className="w-4 h-4 text-green-600 dark:text-green-400" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900 dark:text-white">
                {status?.minWordLength || 4}
              </p>
              <p className="text-xs text-gray-500 dark:text-gray-400">Min Length</p>
            </div>
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className="card p-4">
        <form onSubmit={handleSearch} className="flex flex-col sm:flex-row gap-4">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              placeholder="Search words..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="input pl-10"
            />
          </div>
          <div className="flex items-center gap-2 flex-wrap">
            <Filter className="w-4 h-4 text-gray-400" />
            <select
              value={lengthFilter}
              onChange={(e) => {
                setLengthFilter(e.target.value)
                setPage(1)
              }}
              className="input w-auto"
            >
              <option value="">All Lengths</option>
              {[4, 5, 6, 7, 8, 9, 10, 11, 12].map((len) => (
                <option key={len} value={len}>{len} letters</option>
              ))}
            </select>
            <input
              type="text"
              placeholder="Starts with..."
              value={startsWithFilter}
              onChange={(e) => {
                setStartsWithFilter(e.target.value.toUpperCase().slice(0, 2))
                setPage(1)
              }}
              className="input w-24"
              maxLength={2}
            />
            <select
              value={hasClueFilter}
              onChange={(e) => {
                setHasClueFilter(e.target.value)
                setPage(1)
              }}
              className="input w-auto"
            >
              <option value="">All Clues</option>
              <option value="true">Has Clue</option>
              <option value="false">Needs Clue</option>
            </select>
          </div>
        </form>
      </div>

      {/* Table */}
      <div className="card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 dark:bg-gray-700/50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Word
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Length
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Clue
                </th>
                <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
              {isLoading ? (
                <tr>
                  <td colSpan={4} className="px-6 py-12 text-center text-gray-500">
                    Loading dictionary...
                  </td>
                </tr>
              ) : words.length === 0 ? (
                <tr>
                  <td colSpan={4} className="px-6 py-12 text-center text-gray-500">
                    No words found
                  </td>
                </tr>
              ) : (
                words.map((word) => (
                  <tr
                    key={word._id}
                    className="hover:bg-gray-50 dark:hover:bg-gray-700/50"
                  >
                    <td className="px-6 py-4">
                      <span className="font-mono font-medium text-gray-900 dark:text-white">
                        {word.word}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-gray-600 dark:text-gray-400">
                      {word.length}
                    </td>
                    <td className="px-6 py-4">
                      {hasClue(word) ? (
                        <span className="text-sm text-gray-700 dark:text-gray-300">
                          {word.clue}
                        </span>
                      ) : (
                        <span className="text-sm text-gray-400 italic">
                          {word.clue?.startsWith('Define:') ? 'Placeholder' : 'No clue'}
                        </span>
                      )}
                    </td>
                    <td className="px-6 py-4 text-right">
                      <div className="relative inline-block">
                        <button
                          onClick={() =>
                            setActiveMenu(activeMenu === word._id ? null : word._id)
                          }
                          className="p-2 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg"
                        >
                          <MoreVertical className="w-4 h-4" />
                        </button>

                        {activeMenu === word._id && (
                          <>
                            <div
                              className="fixed inset-0 z-10"
                              onClick={() => setActiveMenu(null)}
                            />
                            <div className="absolute right-0 mt-2 w-40 bg-white dark:bg-gray-800 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700 z-20">
                              <button
                                onClick={() => {
                                  setEditingWord(word)
                                  setActiveMenu(null)
                                }}
                                className="w-full flex items-center gap-2 px-4 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700"
                              >
                                <Edit className="w-4 h-4" />
                                Edit Clue
                              </button>
                              <button
                                onClick={() => handleDelete(word.word)}
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
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        {pagination.totalPages > 1 && (
          <div className="px-6 py-4 border-t border-gray-200 dark:border-gray-700 flex items-center justify-between">
            <p className="text-sm text-gray-500 dark:text-gray-400">
              Showing {((pagination.page - 1) * pagination.limit) + 1} to{' '}
              {Math.min(pagination.page * pagination.limit, pagination.total)} of{' '}
              {pagination.total.toLocaleString()} words
            </p>
            <div className="flex items-center gap-2">
              <button
                onClick={() => setPage(Math.max(1, page - 1))}
                disabled={page === 1}
                className="p-2 rounded-lg border border-gray-200 dark:border-gray-700 hover:bg-gray-100 dark:hover:bg-gray-700 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <ChevronLeft className="w-4 h-4" />
              </button>
              <span className="text-sm text-gray-600 dark:text-gray-400">
                Page {pagination.page} of {pagination.totalPages}
              </span>
              <button
                onClick={() => setPage(Math.min(pagination.totalPages, page + 1))}
                disabled={page === pagination.totalPages}
                className="p-2 rounded-lg border border-gray-200 dark:border-gray-700 hover:bg-gray-100 dark:hover:bg-gray-700 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <ChevronRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Edit Modal */}
      {editingWord && (
        <DictionaryEditModal
          word={editingWord}
          onClose={() => setEditingWord(null)}
          onSave={(clue) => updateClueMutation.mutate({ word: editingWord.word, clue })}
          isSaving={updateClueMutation.isPending}
        />
      )}
    </div>
  )
}
