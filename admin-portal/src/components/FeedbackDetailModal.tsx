import { useState } from 'react'
import { format } from 'date-fns'
import {
  X,
  Bug,
  Lightbulb,
  AlertTriangle,
  MessageSquare,
  Puzzle,
  Mail,
  Smartphone,
  Calendar,
  Link as LinkIcon,
} from 'lucide-react'

const feedbackTypeConfig: Record<string, { icon: typeof Bug; label: string; color: string }> = {
  bug_report: { icon: Bug, label: 'Bug Report', color: 'text-red-600 bg-red-100 dark:bg-red-900/30 dark:text-red-400' },
  new_game_suggestion: { icon: Lightbulb, label: 'New Game Suggestion', color: 'text-yellow-600 bg-yellow-100 dark:bg-yellow-900/30 dark:text-yellow-400' },
  puzzle_suggestion: { icon: Puzzle, label: 'Puzzle Suggestion', color: 'text-purple-600 bg-purple-100 dark:bg-purple-900/30 dark:text-purple-400' },
  puzzle_mistake: { icon: AlertTriangle, label: 'Puzzle Mistake', color: 'text-orange-600 bg-orange-100 dark:bg-orange-900/30 dark:text-orange-400' },
  general: { icon: MessageSquare, label: 'General Feedback', color: 'text-blue-600 bg-blue-100 dark:bg-blue-900/30 dark:text-blue-400' },
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

interface FeedbackDetailModalProps {
  feedback: Feedback
  onClose: () => void
  onUpdate: (data: { status?: string; adminNotes?: string }) => void
}

export default function FeedbackDetailModal({
  feedback,
  onClose,
  onUpdate,
}: FeedbackDetailModalProps) {
  const [status, setStatus] = useState(feedback.status)
  const [adminNotes, setAdminNotes] = useState(feedback.adminNotes || '')
  const [hasChanges, setHasChanges] = useState(false)

  const typeConf = feedbackTypeConfig[feedback.type] || feedbackTypeConfig.general
  const TypeIcon = typeConf.icon

  const handleStatusChange = (newStatus: string) => {
    setStatus(newStatus)
    setHasChanges(true)
  }

  const handleNotesChange = (notes: string) => {
    setAdminNotes(notes)
    setHasChanges(true)
  }

  const handleSave = () => {
    const updates: { status?: string; adminNotes?: string } = {}
    if (status !== feedback.status) updates.status = status
    if (adminNotes !== (feedback.adminNotes || '')) updates.adminNotes = adminNotes
    if (Object.keys(updates).length > 0) {
      onUpdate(updates)
    }
    onClose()
  }

  const formatGameType = (type: string) => {
    const mapping: Record<string, string> = {
      sudoku: 'Sudoku',
      killerSudoku: 'Killer Sudoku',
      crossword: 'Crossword',
      wordSearch: 'Word Search',
    }
    return mapping[type] || type
  }

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      {/* Backdrop */}
      <div
        className="fixed inset-0 bg-black/50 transition-opacity"
        onClick={onClose}
      />

      {/* Modal */}
      <div className="flex min-h-full items-center justify-center p-4">
        <div className="relative bg-white dark:bg-gray-800 rounded-xl shadow-xl w-full max-w-2xl">
          {/* Header */}
          <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200 dark:border-gray-700">
            <div className="flex items-center gap-3">
              <span className={`inline-flex items-center gap-1 px-2 py-1 text-xs font-medium rounded-full ${typeConf.color}`}>
                <TypeIcon className="w-3 h-3" />
                {typeConf.label}
              </span>
              <span className="text-sm text-gray-500 dark:text-gray-400">
                {format(new Date(feedback.createdAt), 'MMM d, yyyy h:mm a')}
              </span>
            </div>
            <button
              onClick={onClose}
              className="p-2 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          {/* Content */}
          <div className="px-6 py-4 space-y-6">
            {/* Message */}
            <div>
              <label className="label">Message</label>
              <div className="card p-4 bg-gray-50 dark:bg-gray-900">
                <p className="text-gray-900 dark:text-white whitespace-pre-wrap">
                  {feedback.message}
                </p>
              </div>
            </div>

            {/* Contact Email */}
            {feedback.email && (
              <div className="flex items-center gap-3">
                <Mail className="w-4 h-4 text-gray-400" />
                <a
                  href={`mailto:${feedback.email}`}
                  className="text-blue-600 hover:underline"
                >
                  {feedback.email}
                </a>
              </div>
            )}

            {/* Game Context */}
            {feedback.puzzleId && (
              <div className="card p-4 space-y-3">
                <h3 className="font-medium text-gray-900 dark:text-white flex items-center gap-2">
                  <Puzzle className="w-4 h-4" />
                  Game Context
                </h3>
                <div className="grid grid-cols-2 gap-4 text-sm">
                  <div>
                    <span className="text-gray-500 dark:text-gray-400">Puzzle ID:</span>
                    <p className="text-gray-900 dark:text-white font-mono text-xs">
                      {feedback.puzzleId}
                    </p>
                  </div>
                  {feedback.gameType && (
                    <div>
                      <span className="text-gray-500 dark:text-gray-400">Game Type:</span>
                      <p className="text-gray-900 dark:text-white">
                        {formatGameType(feedback.gameType)}
                      </p>
                    </div>
                  )}
                  {feedback.difficulty && (
                    <div>
                      <span className="text-gray-500 dark:text-gray-400">Difficulty:</span>
                      <p className="text-gray-900 dark:text-white capitalize">
                        {feedback.difficulty}
                      </p>
                    </div>
                  )}
                  {feedback.puzzleDate && (
                    <div>
                      <span className="text-gray-500 dark:text-gray-400">Puzzle Date:</span>
                      <p className="text-gray-900 dark:text-white">
                        {format(new Date(feedback.puzzleDate), 'MMM d, yyyy')}
                      </p>
                    </div>
                  )}
                </div>
                <a
                  href={`/puzzles/${feedback.puzzleId}/edit`}
                  className="inline-flex items-center gap-1 text-sm text-blue-600 hover:underline"
                >
                  <LinkIcon className="w-3 h-3" />
                  View Puzzle
                </a>
              </div>
            )}

            {/* Device Info */}
            {feedback.deviceInfo && (
              <div className="flex items-start gap-3 text-sm">
                <Smartphone className="w-4 h-4 text-gray-400 mt-0.5" />
                <div>
                  <span className="text-gray-500 dark:text-gray-400">Device Info:</span>
                  <p className="text-gray-900 dark:text-white">{feedback.deviceInfo}</p>
                </div>
              </div>
            )}

            {/* Status */}
            <div>
              <label className="label">Status</label>
              <select
                value={status}
                onChange={(e) => handleStatusChange(e.target.value)}
                className="input"
              >
                <option value="new">New</option>
                <option value="in_progress">In Progress</option>
                <option value="resolved">Resolved</option>
                <option value="dismissed">Dismissed</option>
              </select>
            </div>

            {/* Admin Notes */}
            <div>
              <label className="label">Admin Notes</label>
              <textarea
                value={adminNotes}
                onChange={(e) => handleNotesChange(e.target.value)}
                placeholder="Add notes about how this was resolved..."
                className="input min-h-[100px]"
              />
            </div>

            {/* Timestamps */}
            <div className="flex items-center gap-4 text-xs text-gray-500 dark:text-gray-400">
              <div className="flex items-center gap-1">
                <Calendar className="w-3 h-3" />
                Created: {format(new Date(feedback.createdAt), 'MMM d, yyyy h:mm a')}
              </div>
              <div className="flex items-center gap-1">
                <Calendar className="w-3 h-3" />
                Updated: {format(new Date(feedback.updatedAt), 'MMM d, yyyy h:mm a')}
              </div>
            </div>
          </div>

          {/* Footer */}
          <div className="flex items-center justify-end gap-3 px-6 py-4 border-t border-gray-200 dark:border-gray-700">
            <button onClick={onClose} className="btn btn-secondary">
              Cancel
            </button>
            <button
              onClick={handleSave}
              className="btn btn-primary"
              disabled={!hasChanges}
            >
              Save Changes
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
