import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useMutation } from '@tanstack/react-query'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import toast from 'react-hot-toast'
import { ArrowLeft, Loader2, Upload } from 'lucide-react'
import { puzzlesApi } from '../lib/api'

const puzzleSchema = z.object({
  gameType: z.enum(['sudoku', 'killerSudoku', 'crossword', 'wordSearch']),
  difficulty: z.enum(['easy', 'medium', 'hard', 'expert']),
  date: z.string().min(1, 'Date is required'),
  title: z.string().optional(),
  description: z.string().optional(),
  targetTime: z.coerce.number().optional(),
  isActive: z.boolean().default(true),
})

type PuzzleFormData = z.infer<typeof puzzleSchema>

export default function PuzzleCreate() {
  const navigate = useNavigate()
  const [puzzleDataJson, setPuzzleDataJson] = useState('')
  const [jsonError, setJsonError] = useState('')

  const {
    register,
    handleSubmit,
    watch,
    formState: { errors },
  } = useForm<PuzzleFormData>({
    resolver: zodResolver(puzzleSchema),
    defaultValues: {
      gameType: 'sudoku',
      difficulty: 'medium',
      date: new Date().toISOString().split('T')[0],
      isActive: true,
      targetTime: 600,
    },
  })

  const gameType = watch('gameType')

  const createMutation = useMutation({
    mutationFn: (data: any) => puzzlesApi.create(data),
    onSuccess: () => {
      toast.success('Puzzle created successfully!')
      navigate('/puzzles')
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Failed to create puzzle')
    },
  })

  const onSubmit = (data: PuzzleFormData) => {
    // Validate JSON
    let puzzleData
    try {
      puzzleData = JSON.parse(puzzleDataJson)
      setJsonError('')
    } catch (e) {
      setJsonError('Invalid JSON format')
      return
    }

    createMutation.mutate({
      ...data,
      puzzleData,
    })
  }

  const getExampleJson = () => {
    const examples: Record<string, object> = {
      sudoku: {
        grid: [
          [5, 3, 0, 0, 7, 0, 0, 0, 0],
          [6, 0, 0, 1, 9, 5, 0, 0, 0],
          [0, 9, 8, 0, 0, 0, 0, 6, 0],
          [8, 0, 0, 0, 6, 0, 0, 0, 3],
          [4, 0, 0, 8, 0, 3, 0, 0, 1],
          [7, 0, 0, 0, 2, 0, 0, 0, 6],
          [0, 6, 0, 0, 0, 0, 2, 8, 0],
          [0, 0, 0, 4, 1, 9, 0, 0, 5],
          [0, 0, 0, 0, 8, 0, 0, 7, 9],
        ],
        solution: [
          [5, 3, 4, 6, 7, 8, 9, 1, 2],
          [6, 7, 2, 1, 9, 5, 3, 4, 8],
          [1, 9, 8, 3, 4, 2, 5, 6, 7],
          [8, 5, 9, 7, 6, 1, 4, 2, 3],
          [4, 2, 6, 8, 5, 3, 7, 9, 1],
          [7, 1, 3, 9, 2, 4, 8, 5, 6],
          [9, 6, 1, 5, 3, 7, 2, 8, 4],
          [2, 8, 7, 4, 1, 9, 6, 3, 5],
          [3, 4, 5, 2, 8, 6, 1, 7, 9],
        ],
      },
      killerSudoku: {
        grid: Array(9).fill(Array(9).fill(0)),
        solution: [
          [5, 3, 4, 6, 7, 8, 9, 1, 2],
          [6, 7, 2, 1, 9, 5, 3, 4, 8],
          [1, 9, 8, 3, 4, 2, 5, 6, 7],
          [8, 5, 9, 7, 6, 1, 4, 2, 3],
          [4, 2, 6, 8, 5, 3, 7, 9, 1],
          [7, 1, 3, 9, 2, 4, 8, 5, 6],
          [9, 6, 1, 5, 3, 7, 2, 8, 4],
          [2, 8, 7, 4, 1, 9, 6, 3, 5],
          [3, 4, 5, 2, 8, 6, 1, 7, 9],
        ],
        cages: [
          { sum: 8, cells: [[0, 0], [0, 1]] },
          { sum: 10, cells: [[0, 2], [1, 2]] },
        ],
      },
      crossword: {
        rows: 10,
        cols: 10,
        grid: [
          ['F', 'L', 'U', 'T', 'T', 'E', 'R', '#', '#', '#'],
          ['L', '#', 'N', '#', 'E', '#', 'E', 'C', 'H', 'O'],
          ['A', 'P', 'I', '#', 'C', 'O', 'D', 'E', '#', 'N'],
          ['S', '#', 'T', 'E', 'H', '#', '#', 'L', '#', 'E'],
          ['H', 'E', 'Y', '#', '#', '#', '#', 'L', '#', '#'],
          ['#', '#', '#', '#', '#', '#', '#', '#', '#', '#'],
          ['#', '#', '#', '#', '#', '#', '#', '#', '#', '#'],
          ['#', '#', '#', '#', '#', '#', '#', '#', '#', '#'],
          ['#', '#', '#', '#', '#', '#', '#', '#', '#', '#'],
          ['#', '#', '#', '#', '#', '#', '#', '#', '#', '#'],
        ],
        clues: [
          { number: 1, direction: 'across', clue: 'Google UI toolkit', answer: 'FLUTTER', startRow: 0, startCol: 0 },
          { number: 1, direction: 'down', clue: 'Quick movement', answer: 'FLASH', startRow: 0, startCol: 0 },
        ],
      },
      wordSearch: {
        rows: 10,
        cols: 10,
        theme: 'Programming',
        grid: [
          ['F', 'L', 'U', 'T', 'T', 'E', 'R', 'X', 'P', 'Q'],
          ['A', 'P', 'I', 'K', 'O', 'T', 'L', 'I', 'N', 'Z'],
          ['D', 'A', 'R', 'T', 'B', 'Y', 'T', 'E', 'S', 'W'],
          ['K', 'R', 'E', 'A', 'C', 'T', 'V', 'U', 'I', 'D'],
          ['C', 'O', 'D', 'E', 'N', 'O', 'D', 'E', 'F', 'G'],
          ['S', 'W', 'I', 'F', 'T', 'P', 'R', 'O', 'G', 'H'],
          ['J', 'A', 'V', 'A', 'M', 'N', 'O', 'P', 'Q', 'R'],
          ['R', 'U', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
          ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'],
          ['K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T'],
        ],
        words: [
          { word: 'FLUTTER', startRow: 0, startCol: 0, endRow: 0, endCol: 6 },
          { word: 'DART', startRow: 2, startCol: 0, endRow: 2, endCol: 3 },
        ],
      },
    }
    setPuzzleDataJson(JSON.stringify(examples[gameType], null, 2))
    setJsonError('')
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <button
          onClick={() => navigate(-1)}
          className="p-2 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg"
        >
          <ArrowLeft className="w-5 h-5" />
        </button>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
          Create New Puzzle
        </h1>
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
                Puzzle Data (JSON)
              </h2>
              <button
                type="button"
                onClick={getExampleJson}
                className="btn btn-secondary text-sm"
              >
                Load Example
              </button>
            </div>

            <textarea
              value={puzzleDataJson}
              onChange={(e) => {
                setPuzzleDataJson(e.target.value)
                setJsonError('')
              }}
              className="input font-mono text-sm h-96"
              placeholder="Paste puzzle JSON data here..."
            />
            {jsonError && (
              <p className="text-sm text-red-500">{jsonError}</p>
            )}

            <div className="text-sm text-gray-500 dark:text-gray-400">
              <p className="font-medium mb-2">Required fields for {gameType}:</p>
              {gameType === 'sudoku' && (
                <ul className="list-disc list-inside space-y-1">
                  <li>grid: 9x9 array (0 for empty cells)</li>
                  <li>solution: 9x9 array with answers</li>
                </ul>
              )}
              {gameType === 'killerSudoku' && (
                <ul className="list-disc list-inside space-y-1">
                  <li>grid: 9x9 array (usually all 0s)</li>
                  <li>solution: 9x9 array with answers</li>
                  <li>cages: array of {'{sum, cells}'}</li>
                </ul>
              )}
              {gameType === 'crossword' && (
                <ul className="list-disc list-inside space-y-1">
                  <li>rows, cols: grid dimensions</li>
                  <li>grid: 2D array (# for black cells)</li>
                  <li>clues: array of clue objects</li>
                </ul>
              )}
              {gameType === 'wordSearch' && (
                <ul className="list-disc list-inside space-y-1">
                  <li>rows, cols: grid dimensions</li>
                  <li>grid: 2D array of letters</li>
                  <li>words: array with positions</li>
                  <li>theme: optional theme name</li>
                </ul>
              )}
            </div>
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
            disabled={createMutation.isPending}
            className="btn btn-primary"
          >
            {createMutation.isPending ? (
              <>
                <Loader2 className="w-4 h-4 animate-spin" />
                Creating...
              </>
            ) : (
              <>
                <Upload className="w-4 h-4" />
                Create Puzzle
              </>
            )}
          </button>
        </div>
      </form>
    </div>
  )
}
