import { useState, useMemo } from 'react'
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
  Plus,
  Upload,
  Calendar,
  CalendarDays,
  CheckSquare,
  Square,
  Loader2,
} from 'lucide-react'
import { dictionaryApi, wordForgeApi } from '../lib/api'
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

type TabType = 'all' | 'today' | 'tomorrow'

function formatDate(date: Date): string {
  return date.toISOString().split('T')[0]
}

export default function Dictionary() {
  const [activeTab, setActiveTab] = useState<TabType>('all')
  const [searchQuery, setSearchQuery] = useState('')
  const [lengthFilter, setLengthFilter] = useState<string>('')
  const [startsWithFilter, setStartsWithFilter] = useState('')
  const [hasClueFilter, setHasClueFilter] = useState<string>('')
  const [page, setPage] = useState(1)
  const [activeMenu, setActiveMenu] = useState<string | null>(null)
  const [editingWord, setEditingWord] = useState<DictionaryWord | null>(null)
  const [showAddModal, setShowAddModal] = useState(false)
  const [showBulkModal, setShowBulkModal] = useState(false)
  const [newWord, setNewWord] = useState('')
  const [newWordClue, setNewWordClue] = useState('')
  const [bulkWords, setBulkWords] = useState('')
  const [selectedWords, setSelectedWords] = useState<Set<string>>(new Set())

  const queryClient = useQueryClient()

  // Calculate today and tomorrow dates
  const today = useMemo(() => formatDate(new Date()), [])
  const tomorrow = useMemo(() => {
    const d = new Date()
    d.setDate(d.getDate() + 1)
    return formatDate(d)
  }, [])

  // Query for all dictionary words (with filters)
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
    enabled: activeTab === 'all',
  })

  // Query for today's Word Forge words
  const { data: todayData, isLoading: todayLoading } = useQuery({
    queryKey: ['word-forge-words', 'today', today],
    queryFn: () => wordForgeApi.getWordsForDate(today).then((res) => res.data),
    enabled: activeTab === 'today',
  })

  // Query for tomorrow's Word Forge words
  const { data: tomorrowData, isLoading: tomorrowLoading } = useQuery({
    queryKey: ['word-forge-words', 'tomorrow', tomorrow],
    queryFn: () => wordForgeApi.getWordsForDate(tomorrow).then((res) => res.data),
    enabled: activeTab === 'tomorrow',
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

  // Bulk delete mutation (delete from dictionary AND update future puzzles)
  const bulkDeleteMutation = useMutation({
    mutationFn: async (words: string[]) => {
      // First delete from dictionary
      const deleteResult = await dictionaryApi.bulkDeleteWords(words)
      // Then update future puzzles
      const puzzleResult = await wordForgeApi.removeWordsFromFuture(words)
      return { deleteResult: deleteResult.data, puzzleResult: puzzleResult.data }
    },
    onSuccess: (data) => {
      queryClient.invalidateQueries({ queryKey: ['dictionary'] })
      queryClient.invalidateQueries({ queryKey: ['dictionary-status'] })
      queryClient.invalidateQueries({ queryKey: ['word-forge-words'] })
      setSelectedWords(new Set())
      toast.success(
        `Deleted ${data.deleteResult.deleted} words. Updated ${data.puzzleResult.puzzlesUpdated} future puzzles.`
      )
    },
    onError: () => {
      toast.error('Failed to delete words')
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

  const addWordMutation = useMutation({
    mutationFn: ({ word, clue }: { word: string; clue?: string }) =>
      dictionaryApi.addWord(word, clue),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['dictionary'] })
      queryClient.invalidateQueries({ queryKey: ['dictionary-status'] })
      toast.success('Word added to dictionary')
      setShowAddModal(false)
      setNewWord('')
      setNewWordClue('')
    },
    onError: () => {
      toast.error('Failed to add word')
    },
  })

  const bulkAddMutation = useMutation({
    mutationFn: (words: string[]) => dictionaryApi.bulkAddWords(words),
    onSuccess: (data) => {
      queryClient.invalidateQueries({ queryKey: ['dictionary'] })
      queryClient.invalidateQueries({ queryKey: ['dictionary-status'] })
      toast.success(`Added ${data.data.added} words to dictionary`)
      setShowBulkModal(false)
      setBulkWords('')
    },
    onError: () => {
      toast.error('Failed to add words')
    },
  })

  // Get words based on active tab
  const getDisplayWords = (): string[] => {
    if (activeTab === 'today') {
      return todayData?.words || []
    } else if (activeTab === 'tomorrow') {
      return tomorrowData?.words || []
    }
    return []
  }

  const words: DictionaryWord[] = data?.words || []
  const pagination: PaginationInfo = data?.pagination || { page: 1, limit: 50, total: 0, totalPages: 0 }
  const wordForgeWords = getDisplayWords()

  const handleDelete = (word: string) => {
    if (confirm(`Are you sure you want to delete "${word}" from the dictionary?`)) {
      deleteMutation.mutate(word)
    }
    setActiveMenu(null)
  }

  const handleBulkDelete = () => {
    const wordsToDelete = Array.from(selectedWords)
    if (wordsToDelete.length === 0) return

    if (
      confirm(
        `Are you sure you want to delete ${wordsToDelete.length} words?\n\nThis will also remove them from all future Word Forge puzzles.`
      )
    ) {
      bulkDeleteMutation.mutate(wordsToDelete)
    }
  }

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault()
    setPage(1)
  }

  const hasClue = (word: DictionaryWord): boolean => {
    return !!word.clue && word.clue !== '' && !word.clue.startsWith('Define:')
  }

  const toggleWordSelection = (word: string) => {
    setSelectedWords((prev) => {
      const newSet = new Set(prev)
      if (newSet.has(word)) {
        newSet.delete(word)
      } else {
        newSet.add(word)
      }
      return newSet
    })
  }

  const toggleSelectAll = () => {
    if (activeTab === 'all') {
      const allWords = words.map((w) => w.word)
      if (selectedWords.size === allWords.length) {
        setSelectedWords(new Set())
      } else {
        setSelectedWords(new Set(allWords))
      }
    } else {
      if (selectedWords.size === wordForgeWords.length) {
        setSelectedWords(new Set())
      } else {
        setSelectedWords(new Set(wordForgeWords))
      }
    }
  }

  const handleTabChange = (tab: TabType) => {
    setActiveTab(tab)
    setSelectedWords(new Set())
    setPage(1)
  }

  const isLoadingWords = activeTab === 'all' ? isLoading : activeTab === 'today' ? todayLoading : tomorrowLoading

  const currentWordList = activeTab === 'all' ? words.map((w) => w.word) : wordForgeWords

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Dictionary</h1>
          {status && (
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
              {status.wordCount?.toLocaleString()} words
            </p>
          )}
        </div>
        <div className="flex gap-2">
          {selectedWords.size > 0 && (
            <button
              onClick={handleBulkDelete}
              disabled={bulkDeleteMutation.isPending}
              className="btn bg-red-600 hover:bg-red-700 text-white flex items-center gap-2"
            >
              {bulkDeleteMutation.isPending ? (
                <Loader2 className="w-4 h-4 animate-spin" />
              ) : (
                <Trash2 className="w-4 h-4" />
              )}
              Delete {selectedWords.size} Selected
            </button>
          )}
          <button onClick={() => setShowBulkModal(true)} className="btn btn-secondary flex items-center gap-2">
            <Upload className="w-4 h-4" />
            Bulk Add
          </button>
          <button onClick={() => setShowAddModal(true)} className="btn btn-primary flex items-center gap-2">
            <Plus className="w-4 h-4" />
            Add Word
          </button>
        </div>
      </div>

      {/* Tabs */}
      <div className="border-b border-gray-200 dark:border-gray-700">
        <nav className="-mb-px flex gap-4">
          <button
            onClick={() => handleTabChange('all')}
            className={`flex items-center gap-2 py-3 px-1 border-b-2 text-sm font-medium transition-colors ${
              activeTab === 'all'
                ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 dark:text-gray-400 dark:hover:text-gray-300'
            }`}
          >
            <Book className="w-4 h-4" />
            All Words
          </button>
          <button
            onClick={() => handleTabChange('today')}
            className={`flex items-center gap-2 py-3 px-1 border-b-2 text-sm font-medium transition-colors ${
              activeTab === 'today'
                ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 dark:text-gray-400 dark:hover:text-gray-300'
            }`}
          >
            <Calendar className="w-4 h-4" />
            Today's Word Forge
          </button>
          <button
            onClick={() => handleTabChange('tomorrow')}
            className={`flex items-center gap-2 py-3 px-1 border-b-2 text-sm font-medium transition-colors ${
              activeTab === 'tomorrow'
                ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 dark:text-gray-400 dark:hover:text-gray-300'
            }`}
          >
            <CalendarDays className="w-4 h-4" />
            Tomorrow's Word Forge
          </button>
        </nav>
      </div>

      {/* Stats (only show for All Words tab) */}
      {activeTab === 'all' && (
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
                <p className="text-2xl font-bold text-gray-900 dark:text-white">{status?.minWordLength || 4}</p>
                <p className="text-xs text-gray-500 dark:text-gray-400">Min Length</p>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Word Forge info banner */}
      {(activeTab === 'today' || activeTab === 'tomorrow') && (
        <div className="card p-4 bg-amber-50 dark:bg-amber-900/20 border-amber-200 dark:border-amber-800">
          <p className="text-sm text-amber-800 dark:text-amber-200">
            {activeTab === 'today' ? "Today's" : "Tomorrow's"} Word Forge has{' '}
            <strong>{wordForgeWords.length}</strong> words. Select words to delete them from the dictionary and all
            future Word Forge puzzles.
          </p>
        </div>
      )}

      {/* Filters (only for All Words tab) */}
      {activeTab === 'all' && (
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
                  <option key={len} value={len}>
                    {len} letters
                  </option>
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
      )}

      {/* Table */}
      <div className="card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 dark:bg-gray-700/50">
              <tr>
                <th className="px-4 py-3 text-left">
                  <button
                    onClick={toggleSelectAll}
                    className="p-1 hover:bg-gray-200 dark:hover:bg-gray-600 rounded"
                    title={selectedWords.size === currentWordList.length ? 'Deselect all' : 'Select all'}
                  >
                    {selectedWords.size === currentWordList.length && currentWordList.length > 0 ? (
                      <CheckSquare className="w-4 h-4 text-blue-600" />
                    ) : (
                      <Square className="w-4 h-4 text-gray-400" />
                    )}
                  </button>
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Word
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Length
                </th>
                {activeTab === 'all' && (
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                    Clue
                  </th>
                )}
                <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
              {isLoadingWords ? (
                <tr>
                  <td colSpan={activeTab === 'all' ? 5 : 4} className="px-6 py-12 text-center text-gray-500">
                    <Loader2 className="w-6 h-6 animate-spin mx-auto mb-2" />
                    Loading words...
                  </td>
                </tr>
              ) : activeTab === 'all' ? (
                words.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="px-6 py-12 text-center text-gray-500">
                      No words found
                    </td>
                  </tr>
                ) : (
                  words.map((word) => (
                    <tr key={word._id} className="hover:bg-gray-50 dark:hover:bg-gray-700/50">
                      <td className="px-4 py-4">
                        <button
                          onClick={() => toggleWordSelection(word.word)}
                          className="p-1 hover:bg-gray-200 dark:hover:bg-gray-600 rounded"
                        >
                          {selectedWords.has(word.word) ? (
                            <CheckSquare className="w-4 h-4 text-blue-600" />
                          ) : (
                            <Square className="w-4 h-4 text-gray-400" />
                          )}
                        </button>
                      </td>
                      <td className="px-6 py-4">
                        <span className="font-mono font-medium text-gray-900 dark:text-white">{word.word}</span>
                      </td>
                      <td className="px-6 py-4 text-gray-600 dark:text-gray-400">{word.length}</td>
                      <td className="px-6 py-4">
                        {hasClue(word) ? (
                          <span className="text-sm text-gray-700 dark:text-gray-300">{word.clue}</span>
                        ) : (
                          <span className="text-sm text-gray-400 italic">
                            {word.clue?.startsWith('Define:') ? 'Placeholder' : 'No clue'}
                          </span>
                        )}
                      </td>
                      <td className="px-6 py-4 text-right">
                        <div className="relative inline-block">
                          <button
                            onClick={() => setActiveMenu(activeMenu === word._id ? null : word._id)}
                            className="p-2 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg"
                          >
                            <MoreVertical className="w-4 h-4" />
                          </button>

                          {activeMenu === word._id && (
                            <>
                              <div className="fixed inset-0 z-10" onClick={() => setActiveMenu(null)} />
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
                )
              ) : wordForgeWords.length === 0 ? (
                <tr>
                  <td colSpan={4} className="px-6 py-12 text-center text-gray-500">
                    No Word Forge puzzle found for {activeTab === 'today' ? 'today' : 'tomorrow'}
                  </td>
                </tr>
              ) : (
                wordForgeWords.map((word) => (
                  <tr key={word} className="hover:bg-gray-50 dark:hover:bg-gray-700/50">
                    <td className="px-4 py-4">
                      <button
                        onClick={() => toggleWordSelection(word)}
                        className="p-1 hover:bg-gray-200 dark:hover:bg-gray-600 rounded"
                      >
                        {selectedWords.has(word) ? (
                          <CheckSquare className="w-4 h-4 text-blue-600" />
                        ) : (
                          <Square className="w-4 h-4 text-gray-400" />
                        )}
                      </button>
                    </td>
                    <td className="px-6 py-4">
                      <span className="font-mono font-medium text-gray-900 dark:text-white">{word}</span>
                    </td>
                    <td className="px-6 py-4 text-gray-600 dark:text-gray-400">{word.length}</td>
                    <td className="px-6 py-4 text-right">
                      <button
                        onClick={() => {
                          if (confirm(`Delete "${word}" from dictionary and future puzzles?`)) {
                            bulkDeleteMutation.mutate([word])
                          }
                        }}
                        className="p-2 text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg"
                        title="Delete word"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination (only for All Words tab) */}
        {activeTab === 'all' && pagination.totalPages > 1 && (
          <div className="px-6 py-4 border-t border-gray-200 dark:border-gray-700 flex items-center justify-between">
            <p className="text-sm text-gray-500 dark:text-gray-400">
              Showing {(pagination.page - 1) * pagination.limit + 1} to{' '}
              {Math.min(pagination.page * pagination.limit, pagination.total)} of {pagination.total.toLocaleString()}{' '}
              words
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

      {/* Add Word Modal */}
      {showAddModal && (
        <>
          <div className="fixed inset-0 bg-black/50 z-40" onClick={() => setShowAddModal(false)} />
          <div className="fixed inset-0 flex items-center justify-center z-50 p-4">
            <div className="bg-white dark:bg-gray-800 rounded-lg shadow-xl w-full max-w-md">
              <div className="p-6">
                <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-4">Add Word to Dictionary</h2>
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                      Word (min 4 letters)
                    </label>
                    <input
                      type="text"
                      value={newWord}
                      onChange={(e) => setNewWord(e.target.value.toUpperCase())}
                      className="input w-full font-mono"
                      placeholder="EXAMPLE"
                      minLength={4}
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                      Clue (optional)
                    </label>
                    <input
                      type="text"
                      value={newWordClue}
                      onChange={(e) => setNewWordClue(e.target.value)}
                      className="input w-full"
                      placeholder="Definition or clue for crosswords"
                    />
                  </div>
                </div>
                <div className="flex justify-end gap-3 mt-6">
                  <button
                    onClick={() => {
                      setShowAddModal(false)
                      setNewWord('')
                      setNewWordClue('')
                    }}
                    className="btn btn-secondary"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={() => {
                      if (newWord.length >= 4) {
                        addWordMutation.mutate({
                          word: newWord,
                          clue: newWordClue || undefined,
                        })
                      }
                    }}
                    disabled={newWord.length < 4 || addWordMutation.isPending}
                    className="btn btn-primary"
                  >
                    {addWordMutation.isPending ? 'Adding...' : 'Add Word'}
                  </button>
                </div>
              </div>
            </div>
          </div>
        </>
      )}

      {/* Bulk Add Modal */}
      {showBulkModal && (
        <>
          <div className="fixed inset-0 bg-black/50 z-40" onClick={() => setShowBulkModal(false)} />
          <div className="fixed inset-0 flex items-center justify-center z-50 p-4">
            <div className="bg-white dark:bg-gray-800 rounded-lg shadow-xl w-full max-w-lg">
              <div className="p-6">
                <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-4">Bulk Add Words</h2>
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                      Words (one per line, min 4 letters each)
                    </label>
                    <textarea
                      value={bulkWords}
                      onChange={(e) => setBulkWords(e.target.value.toUpperCase())}
                      className="input w-full font-mono h-48 resize-none"
                      placeholder={'EXAMPLE\nWORDS\nHERE'}
                    />
                  </div>
                  <p className="text-sm text-gray-500 dark:text-gray-400">
                    {bulkWords.split('\n').filter((w) => w.trim().length >= 4).length} valid words detected
                  </p>
                </div>
                <div className="flex justify-end gap-3 mt-6">
                  <button
                    onClick={() => {
                      setShowBulkModal(false)
                      setBulkWords('')
                    }}
                    className="btn btn-secondary"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={() => {
                      const words = bulkWords
                        .split('\n')
                        .map((w) => w.trim())
                        .filter((w) => w.length >= 4)
                      if (words.length > 0) {
                        bulkAddMutation.mutate(words)
                      }
                    }}
                    disabled={
                      bulkWords.split('\n').filter((w) => w.trim().length >= 4).length === 0 ||
                      bulkAddMutation.isPending
                    }
                    className="btn btn-primary"
                  >
                    {bulkAddMutation.isPending
                      ? 'Adding...'
                      : `Add ${bulkWords.split('\n').filter((w) => w.trim().length >= 4).length} Words`}
                  </button>
                </div>
              </div>
            </div>
          </div>
        </>
      )}
    </div>
  )
}
