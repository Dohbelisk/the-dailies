import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { format } from 'date-fns'
import toast from 'react-hot-toast'
import {
  Search,
  Filter,
  MoreVertical,
  Trash2,
  Bug,
  Lightbulb,
  AlertTriangle,
  MessageSquare,
  Puzzle,
  Mail,
  CheckCircle,
  Clock,
  XCircle,
  Eye,
} from 'lucide-react'
import { feedbackApi } from '../lib/api'
import FeedbackDetailModal from '../components/FeedbackDetailModal'

const feedbackTypeConfig: Record<string, { icon: typeof Bug; label: string; color: string }> = {
  bug_report: { icon: Bug, label: 'Bug Report', color: 'text-red-600 bg-red-100 dark:bg-red-900/30 dark:text-red-400' },
  new_game_suggestion: { icon: Lightbulb, label: 'New Game', color: 'text-yellow-600 bg-yellow-100 dark:bg-yellow-900/30 dark:text-yellow-400' },
  puzzle_suggestion: { icon: Puzzle, label: 'Puzzle Idea', color: 'text-purple-600 bg-purple-100 dark:bg-purple-900/30 dark:text-purple-400' },
  puzzle_mistake: { icon: AlertTriangle, label: 'Puzzle Mistake', color: 'text-orange-600 bg-orange-100 dark:bg-orange-900/30 dark:text-orange-400' },
  general: { icon: MessageSquare, label: 'General', color: 'text-blue-600 bg-blue-100 dark:bg-blue-900/30 dark:text-blue-400' },
}

const statusConfig: Record<string, { icon: typeof Clock; label: string; color: string }> = {
  new: { icon: Mail, label: 'New', color: 'text-blue-600 bg-blue-100 dark:bg-blue-900/30 dark:text-blue-400' },
  in_progress: { icon: Clock, label: 'In Progress', color: 'text-yellow-600 bg-yellow-100 dark:bg-yellow-900/30 dark:text-yellow-400' },
  resolved: { icon: CheckCircle, label: 'Resolved', color: 'text-green-600 bg-green-100 dark:bg-green-900/30 dark:text-green-400' },
  dismissed: { icon: XCircle, label: 'Dismissed', color: 'text-gray-600 bg-gray-100 dark:bg-gray-700 dark:text-gray-400' },
}

interface Feedback {
  _id: string
  type: string
  message: string
  email?: string
  status: string
  adminNotes?: string
  puzzleId?: string
  gameType?: string
  difficulty?: string
  puzzleDate?: string
  deviceInfo?: string
  createdAt: string
  updatedAt: string
}

export default function FeedbackList() {
  const [searchQuery, setSearchQuery] = useState('')
  const [typeFilter, setTypeFilter] = useState<string>('')
  const [statusFilter, setStatusFilter] = useState<string>('')
  const [activeMenu, setActiveMenu] = useState<string | null>(null)
  const [selectedFeedback, setSelectedFeedback] = useState<Feedback | null>(null)

  const queryClient = useQueryClient()

  const { data: feedback, isLoading } = useQuery({
    queryKey: ['feedback', typeFilter, statusFilter],
    queryFn: () => {
      const params: Record<string, string> = {}
      if (typeFilter) params.type = typeFilter
      if (statusFilter) params.status = statusFilter
      return feedbackApi.getAll(params).then((res) => res.data)
    },
  })

  const { data: stats } = useQuery({
    queryKey: ['feedback-stats'],
    queryFn: () => feedbackApi.getStats().then((res) => res.data),
  })

  const deleteMutation = useMutation({
    mutationFn: (id: string) => feedbackApi.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['feedback'] })
      queryClient.invalidateQueries({ queryKey: ['feedback-stats'] })
      toast.success('Feedback deleted')
    },
    onError: () => {
      toast.error('Failed to delete feedback')
    },
  })

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: { status?: string; adminNotes?: string } }) =>
      feedbackApi.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['feedback'] })
      queryClient.invalidateQueries({ queryKey: ['feedback-stats'] })
      toast.success('Feedback updated')
    },
    onError: () => {
      toast.error('Failed to update feedback')
    },
  })

  const filteredFeedback = feedback?.filter((item: Feedback) => {
    if (!searchQuery) return true
    const search = searchQuery.toLowerCase()
    return (
      item.message.toLowerCase().includes(search) ||
      item.email?.toLowerCase().includes(search) ||
      item.type.toLowerCase().includes(search)
    )
  })

  const handleDelete = (id: string) => {
    if (confirm('Are you sure you want to delete this feedback?')) {
      deleteMutation.mutate(id)
    }
    setActiveMenu(null)
  }

  const handleQuickStatusChange = (id: string, status: string) => {
    updateMutation.mutate({ id, data: { status } })
    setActiveMenu(null)
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
            Feedback
          </h1>
          {stats && (
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
              {stats.newCount} new · {stats.total} total
            </p>
          )}
        </div>
      </div>

      {/* Stats Cards */}
      {stats && (
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {Object.entries(statusConfig).map(([key, config]) => {
            const Icon = config.icon
            const count = stats.byStatus?.[key] || 0
            return (
              <div
                key={key}
                className="card p-4 cursor-pointer hover:border-gray-300 dark:hover:border-gray-600 transition-colors"
                onClick={() => setStatusFilter(statusFilter === key ? '' : key)}
              >
                <div className="flex items-center gap-3">
                  <div className={`p-2 rounded-lg ${config.color}`}>
                    <Icon className="w-4 h-4" />
                  </div>
                  <div>
                    <p className="text-2xl font-bold text-gray-900 dark:text-white">{count}</p>
                    <p className="text-xs text-gray-500 dark:text-gray-400">{config.label}</p>
                  </div>
                </div>
              </div>
            )
          })}
        </div>
      )}

      {/* Filters */}
      <div className="card p-4">
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              placeholder="Search feedback..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="input pl-10"
            />
          </div>
          <div className="flex items-center gap-2">
            <Filter className="w-4 h-4 text-gray-400" />
            <select
              value={typeFilter}
              onChange={(e) => setTypeFilter(e.target.value)}
              className="input w-auto"
            >
              <option value="">All Types</option>
              <option value="bug_report">Bug Report</option>
              <option value="new_game_suggestion">New Game Suggestion</option>
              <option value="puzzle_suggestion">Puzzle Suggestion</option>
              <option value="puzzle_mistake">Puzzle Mistake</option>
              <option value="general">General</option>
            </select>
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="input w-auto"
            >
              <option value="">All Status</option>
              <option value="new">New</option>
              <option value="in_progress">In Progress</option>
              <option value="resolved">Resolved</option>
              <option value="dismissed">Dismissed</option>
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
                  Type
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Message
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Status
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Email
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Date
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
                    Loading feedback...
                  </td>
                </tr>
              ) : filteredFeedback?.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-6 py-12 text-center text-gray-500">
                    No feedback found
                  </td>
                </tr>
              ) : (
                filteredFeedback?.map((item: Feedback) => {
                  const typeConf = feedbackTypeConfig[item.type] || feedbackTypeConfig.general
                  const statusConf = statusConfig[item.status] || statusConfig.new
                  const TypeIcon = typeConf.icon
                  const StatusIcon = statusConf.icon

                  return (
                    <tr
                      key={item._id}
                      className="hover:bg-gray-50 dark:hover:bg-gray-700/50 cursor-pointer"
                      onClick={() => setSelectedFeedback(item)}
                    >
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-2">
                          <span className={`inline-flex items-center gap-1 px-2 py-1 text-xs font-medium rounded-full ${typeConf.color}`}>
                            <TypeIcon className="w-3 h-3" />
                            {typeConf.label}
                          </span>
                          {item.puzzleId && (
                            <span className="text-xs text-gray-400" title="Has puzzle context">
                              <Puzzle className="w-3 h-3" />
                            </span>
                          )}
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <p className="text-sm text-gray-900 dark:text-white line-clamp-2 max-w-md">
                          {item.message}
                        </p>
                      </td>
                      <td className="px-6 py-4">
                        <span className={`inline-flex items-center gap-1 px-2 py-1 text-xs font-medium rounded-full ${statusConf.color}`}>
                          <StatusIcon className="w-3 h-3" />
                          {statusConf.label}
                        </span>
                      </td>
                      <td className="px-6 py-4">
                        {item.email ? (
                          <a
                            href={`mailto:${item.email}`}
                            className="text-sm text-blue-600 hover:underline"
                            onClick={(e) => e.stopPropagation()}
                          >
                            {item.email}
                          </a>
                        ) : (
                          <span className="text-sm text-gray-400">Anonymous</span>
                        )}
                      </td>
                      <td className="px-6 py-4 text-gray-600 dark:text-gray-400 text-sm">
                        {format(new Date(item.createdAt), 'MMM d, yyyy')}
                      </td>
                      <td className="px-6 py-4 text-right">
                        <div className="relative inline-block" onClick={(e) => e.stopPropagation()}>
                          <button
                            onClick={() =>
                              setActiveMenu(activeMenu === item._id ? null : item._id)
                            }
                            className="p-2 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg"
                          >
                            <MoreVertical className="w-4 h-4" />
                          </button>

                          {activeMenu === item._id && (
                            <>
                              <div
                                className="fixed inset-0 z-10"
                                onClick={() => setActiveMenu(null)}
                              />
                              <div className="absolute right-0 mt-2 w-48 bg-white dark:bg-gray-800 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700 z-20">
                                <button
                                  onClick={() => {
                                    setSelectedFeedback(item)
                                    setActiveMenu(null)
                                  }}
                                  className="w-full flex items-center gap-2 px-4 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700"
                                >
                                  <Eye className="w-4 h-4" />
                                  View Details
                                </button>
                                {item.status !== 'resolved' && (
                                  <button
                                    onClick={() => handleQuickStatusChange(item._id, 'resolved')}
                                    className="w-full flex items-center gap-2 px-4 py-2 text-sm text-green-600 hover:bg-green-50 dark:hover:bg-green-900/20"
                                  >
                                    <CheckCircle className="w-4 h-4" />
                                    Mark Resolved
                                  </button>
                                )}
                                {item.status !== 'dismissed' && (
                                  <button
                                    onClick={() => handleQuickStatusChange(item._id, 'dismissed')}
                                    className="w-full flex items-center gap-2 px-4 py-2 text-sm text-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700"
                                  >
                                    <XCircle className="w-4 h-4" />
                                    Dismiss
                                  </button>
                                )}
                                <button
                                  onClick={() => handleDelete(item._id)}
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

      {/* Detail Modal */}
      {selectedFeedback && (
        <FeedbackDetailModal
          feedback={selectedFeedback}
          onClose={() => setSelectedFeedback(null)}
          onUpdate={(data) => {
            updateMutation.mutate({ id: selectedFeedback._id, data })
          }}
        />
      )}
    </div>
  )
}
