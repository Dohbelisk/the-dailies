import { useState, useEffect, useCallback } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import toast from 'react-hot-toast'
import { ArrowLeft, Loader2, Save, Trash2, Code, Grid3X3 } from 'lucide-react'
import { puzzlesApi } from '../lib/api'
import PuzzleEditorWrapper from '../components/editors/PuzzleEditorWrapper'

const puzzleSchema = z.object({
  gameType: z.enum(['sudoku', 'killerSudoku', 'crossword', 'wordSearch', 'wordForge', 'nonogram', 'numberTarget', 'ballSort', 'pipes', 'lightsOut', 'wordLadder', 'connections']),
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

  const handleVisualDataChange = useCallback((data: any) => {
    setVisualPuzzleData(data)
  }, [])

  const updateMutation = useMutation({
    mutationFn: (data: any) => puzzlesApi.update(id!, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['puzzles'] })
      queryClient.invalidateQueries({ queryKey: ['puzzle', id] })
      toast.success('Puzzle updated successfully!')
      navigate('/puzzles')
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
      navigate('/puzzles')
    },
    onError: () => {
      toast.error('Failed to delete puzzle')
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
        </div>
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

            <div className="flex items-center gap-2">
              <input
                type="checkbox"
                id="isActive"
                {...register('isActive')}
                className="w-4 h-4 rounded border-gray-300"
              />
              <label htmlFor="isActive" className="text-sm text-gray-700 dark:text-gray-300">
                Active (visible to users)
              </label>
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
            disabled={updateMutation.isPending}
            className="btn btn-primary"
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
    </div>
  )
}
