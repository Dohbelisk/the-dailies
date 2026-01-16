import { useState, useEffect, useCallback } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import toast from 'react-hot-toast'
import { ArrowLeft, Loader2, Save, Trash2, Code, Grid3X3, Eye, EyeOff, CheckCircle } from 'lucide-react'
import { puzzlesApi, PuzzleStatus } from '../lib/api'
import PuzzleEditorWrapper from '../components/editors/PuzzleEditorWrapper'

function isToday(dateString: string): boolean {
  const puzzleDate = new Date(dateString)
  const today = new Date()
  return (
    puzzleDate.getFullYear() === today.getFullYear() &&
    puzzleDate.getMonth() === today.getMonth() &&
    puzzleDate.getDate() === today.getDate()
  )
}

const puzzleSchema = z.object({
  gameType: z.enum(['sudoku', 'killerSudoku', 'crossword', 'wordSearch', 'wordForge', 'nonogram', 'numberTarget', 'ballSort', 'pipes', 'lightsOut', 'wordLadder', 'connections', 'mathora']),
  difficulty: z.enum(['easy', 'medium', 'hard', 'expert']),
  date: z.string().min(1, 'Date is required'),
  title: z.string().optional(),
  description: z.string().optional(),
  targetTime: z.coerce.number().optional(),
  isActive: z.boolean().default(true),
})

type PuzzleFormData = z.infer<typeof puzzleSchema>
type EditorMode = 'visual' | 'json'

export default function PuzzleEdit() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const [puzzleDataJson, setPuzzleDataJson] = useState('')
  const [jsonError, setJsonError] = useState('')
  const [editorMode, setEditorMode] = useState<EditorMode>('visual')
  const [visualPuzzleData, setVisualPuzzleData] = useState<any>(null)
  const [isPuzzleValid, setIsPuzzleValid] = useState(false)
  const [showActivateModal, setShowActivateModal] = useState(false)
  const [savedPuzzleDate, setSavedPuzzleDate] = useState<string | null>(null)

  const { data: puzzle, isLoading } = useQuery({
    queryKey: ['puzzle', id],
    queryFn: () => puzzlesApi.getById(id!).then((res) => res.data),
    enabled: !!id,
  })

  const {
    register,
    handleSubmit,
    reset,
    watch,
    formState: { errors },
  } = useForm<PuzzleFormData>({
    resolver: zodResolver(puzzleSchema),
  })

  const gameType = watch('gameType')

  useEffect(() => {
    if (puzzle) {
      reset({
        gameType: puzzle.gameType,
        difficulty: puzzle.difficulty,
        date: new Date(puzzle.date).toISOString().split('T')[0],
        title: puzzle.title || '',
        description: puzzle.description || '',
        targetTime: puzzle.targetTime || 600,
        isActive: puzzle.isActive,
      })
      setPuzzleDataJson(JSON.stringify(puzzle.puzzleData, null, 2))
      setVisualPuzzleData(puzzle.puzzleData)
    }
  }, [puzzle, reset])

  const handleVisualDataChange = useCallback((data: any, _solution: any, isValid?: boolean) => {
    setVisualPuzzleData(data)
    setIsPuzzleValid(isValid ?? false)
  }, [])

  const updateMutation = useMutation({
    mutationFn: (data: any) => puzzlesApi.update(id!, data),
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({ queryKey: ['puzzles'] })
      queryClient.invalidateQueries({ queryKey: ['puzzle', id] })
      toast.success('Puzzle updated successfully!')

      // Check if puzzle is for today and not already active
      const currentStatus = puzzle?.status || (puzzle?.isActive ? 'active' : 'inactive')
      const puzzleDate = variables.date || puzzle?.date

      if (puzzleDate && isToday(puzzleDate) && currentStatus !== 'active') {
        setSavedPuzzleDate(puzzleDate)
        setShowActivateModal(true)
      } else {
        navigate(-1)
      }
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Failed to update puzzle')
    },
  })

  const deleteMutation = useMutation({
    mutationFn: () => puzzlesApi.delete(id!),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['puzzles'] })
      toast.success('Puzzle deleted')
      navigate(-1)
    },
    onError: () => {
      toast.error('Failed to delete puzzle')
    },
  })

  const updateStatusMutation = useMutation({
    mutationFn: (status: PuzzleStatus) => puzzlesApi.updateStatus(id!, status),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['puzzles'] })
      queryClient.invalidateQueries({ queryKey: ['puzzle', id] })
      toast.success('Puzzle status updated')
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Failed to update puzzle status')
    },
  })

  const onSubmit = (data: PuzzleFormData) => {
    let puzzleData

    if (editorMode === 'visual') {
      if (!visualPuzzleData) {
        setJsonError('Please enter puzzle data in the visual editor')
        return
      }
      puzzleData = visualPuzzleData
    } else {
      try {
        puzzleData = JSON.parse(puzzleDataJson)
        setJsonError('')
      } catch (e) {
        setJsonError('Invalid JSON format')
        return
      }
    }

    updateMutation.mutate({
      ...data,
      puzzleData,
    })
  }

  const handleDelete = () => {
    if (confirm('Are you sure you want to delete this puzzle? This cannot be undone.')) {
      deleteMutation.mutate()
    }
  }

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="w-8 h-8 animate-spin text-primary-600" />
      </div>
    )
  }

  if (!puzzle) {
    return (
      <div className="text-center py-12">
        <p className="text-gray-500">Puzzle not found</p>
        <button onClick={() => navigate('/puzzles')} className="btn btn-primary mt-4">
          Back to Puzzles
        </button>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <button
            onClick={() => navigate(-1)}
            className="p-2 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg"
          >
            <ArrowLeft className="w-5 h-5" />
          </button>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
            Edit Puzzle
          </h1>
          {/* Status Badge */}
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
              <span className={`inline-flex px-3 py-1 text-sm font-medium rounded-full ${statusColors[status] || statusColors.inactive}`}>
                {statusLabels[status] || status}
              </span>
            )
          })()}
        </div>
        <div className="flex items-center gap-2">
          {/* Activate/Deactivate Button */}
          {(() => {
            const status = puzzle.status || (puzzle.isActive ? 'active' : 'inactive')
            if (status === 'active') {
              return (
                <button
                  type="button"
                  onClick={() => updateStatusMutation.mutate('inactive')}
                  disabled={updateStatusMutation.isPending}
                  className="btn btn-secondary"
                >
                  {updateStatusMutation.isPending ? (
                    <Loader2 className="w-4 h-4 animate-spin" />
                  ) : (
                    <EyeOff className="w-4 h-4" />
                  )}
                  Deactivate
                </button>
              )
            } else {
              return (
                <button
                  type="button"
                  onClick={() => updateStatusMutation.mutate('active')}
                  disabled={updateStatusMutation.isPending}
                  className="btn btn-primary"
                >
                  {updateStatusMutation.isPending ? (
                    <Loader2 className="w-4 h-4 animate-spin" />
                  ) : (
                    <Eye className="w-4 h-4" />
                  )}
                  Activate
                </button>
              )
            }
          })()}
          <button
            onClick={handleDelete}
            disabled={deleteMutation.isPending}
            className="btn btn-danger"
          >
            {deleteMutation.isPending ? (
              <Loader2 className="w-4 h-4 animate-spin" />
            ) : (
              <Trash2 className="w-4 h-4" />
            )}
            Delete
          </button>
        </div>
      </div>

      <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Basic Info */}
          <div className="card p-6 space-y-4">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
              Basic Information
            </h2>

            <div>
              <label className="label">Game Type</label>
              <select {...register('gameType')} className="input">
                <option value="sudoku">Sudoku</option>
                <option value="killerSudoku">Killer Sudoku</option>
                <option value="crossword">Crossword</option>
                <option value="wordSearch">Word Search</option>
                <option value="wordForge">Word Forge</option>
                <option value="nonogram">Nonogram</option>
                <option value="numberTarget">Number Target</option>
                <option value="ballSort">Ball Sort</option>
                <option value="pipes">Pipes</option>
                <option value="lightsOut">Lights Out</option>
                <option value="wordLadder">Word Ladder</option>
                <option value="connections">Connections</option>
                <option value="mathora">Mathora</option>
              </select>
            </div>

            <div>
              <label className="label">Difficulty</label>
              <select {...register('difficulty')} className="input">
                <option value="easy">Easy</option>
                <option value="medium">Medium</option>
                <option value="hard">Hard</option>
                <option value="expert">Expert</option>
              </select>
            </div>

            <div>
              <label className="label">Date</label>
              <input type="date" {...register('date')} className="input" />
              {errors.date && (
                <p className="mt-1 text-sm text-red-500">{errors.date.message}</p>
              )}
            </div>

            <div>
              <label className="label">Title (optional)</label>
              <input
                type="text"
                {...register('title')}
                className="input"
                placeholder="e.g., Monday Challenge"
              />
            </div>

            <div>
              <label className="label">Target Time (seconds)</label>
              <input
                type="number"
                {...register('targetTime')}
                className="input"
                placeholder="600"
              />
            </div>

          </div>

          {/* Puzzle Data */}
          <div className="card p-6 space-y-4">
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
                Puzzle Data
              </h2>

              {/* Editor Mode Toggle */}
              <div className="flex items-center gap-2 bg-gray-100 dark:bg-gray-700 p-1 rounded-lg">
                <button
                  type="button"
                  onClick={() => setEditorMode('visual')}
                  className={`flex items-center gap-2 px-3 py-1.5 rounded-md text-sm font-medium transition-colors ${
                    editorMode === 'visual'
                      ? 'bg-white dark:bg-gray-600 text-gray-900 dark:text-white shadow-sm'
                      : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white'
                  }`}
                >
                  <Grid3X3 className="w-4 h-4" />
                  Visual
                </button>
                <button
                  type="button"
                  onClick={() => setEditorMode('json')}
                  className={`flex items-center gap-2 px-3 py-1.5 rounded-md text-sm font-medium transition-colors ${
                    editorMode === 'json'
                      ? 'bg-white dark:bg-gray-600 text-gray-900 dark:text-white shadow-sm'
                      : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white'
                  }`}
                >
                  <Code className="w-4 h-4" />
                  JSON
                </button>
              </div>
            </div>

            {editorMode === 'visual' ? (
              <PuzzleEditorWrapper
                gameType={gameType as any}
                puzzleData={puzzle?.puzzleData}
                onChange={handleVisualDataChange}
              />
            ) : (
              <textarea
                value={puzzleDataJson}
                onChange={(e) => {
                  setPuzzleDataJson(e.target.value)
                  setJsonError('')
                }}
                className="input font-mono text-sm h-96"
                placeholder="Puzzle JSON data..."
              />
            )}
            {jsonError && (
              <p className="text-sm text-red-500">{jsonError}</p>
            )}
          </div>
        </div>

        {/* Actions */}
        <div className="flex justify-end gap-4">
          <button
            type="button"
            onClick={() => navigate(-1)}
            className="btn btn-secondary"
          >
            Cancel
          </button>
          <button
            type="submit"
            disabled={updateMutation.isPending || (editorMode === 'visual' && !isPuzzleValid)}
            className="btn btn-primary"
            title={editorMode === 'visual' && !isPuzzleValid ? 'Validate the puzzle before saving' : undefined}
          >
            {updateMutation.isPending ? (
              <>
                <Loader2 className="w-4 h-4 animate-spin" />
                Saving...
              </>
            ) : (
              <>
                <Save className="w-4 h-4" />
                Save Changes
              </>
            )}
          </button>
        </div>
      </form>

      {/* Activate Puzzle Modal */}
      {showActivateModal && (
        <>
          <div className="fixed inset-0 bg-black/50 z-40" onClick={() => {
            setShowActivateModal(false)
            navigate(-1)
          }} />
          <div className="fixed inset-0 flex items-center justify-center z-50 p-4">
            <div className="bg-white dark:bg-gray-800 rounded-lg shadow-xl w-full max-w-md">
              <div className="p-6">
                <div className="flex items-center gap-3 mb-4">
                  <div className="p-2 rounded-full bg-green-100 dark:bg-green-900/30">
                    <CheckCircle className="w-6 h-6 text-green-600 dark:text-green-400" />
                  </div>
                  <h2 className="text-xl font-bold text-gray-900 dark:text-white">Puzzle Saved!</h2>
                </div>
                <p className="text-gray-600 dark:text-gray-400 mb-6">
                  This puzzle is scheduled for today. Would you like to activate it now so players can access it?
                </p>
                <div className="flex justify-end gap-3">
                  <button
                    onClick={() => {
                      setShowActivateModal(false)
                      navigate(-1)
                    }}
                    className="btn btn-secondary"
                  >
                    Not Now
                  </button>
                  <button
                    onClick={async () => {
                      try {
                        await puzzlesApi.updateStatus(id!, 'active')
                        queryClient.invalidateQueries({ queryKey: ['puzzles'] })
                        queryClient.invalidateQueries({ queryKey: ['puzzle', id] })
                        toast.success('Puzzle activated!')
                        setShowActivateModal(false)
                        navigate(-1)
                      } catch (error: any) {
                        toast.error(error.response?.data?.message || 'Failed to activate puzzle')
                      }
                    }}
                    className="btn btn-primary"
                  >
                    <Eye className="w-4 h-4" />
                    Activate Now
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
