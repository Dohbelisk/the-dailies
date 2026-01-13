import axios from 'axios'
import { useAuthStore } from '../stores/authStore'

// Use environment variable in production, proxy in development
const API_BASE_URL = import.meta.env.VITE_API_URL || '/api'

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Add auth token to requests
api.interceptors.request.use((config) => {
  const token = useAuthStore.getState().token
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// Handle auth errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      useAuthStore.getState().logout()
      window.location.href = '/login'
    }
    return Promise.reject(error)
  }
)

// Auth
export const authApi = {
  login: (email: string, password: string) =>
    api.post('/auth/login', { email, password }),
  register: (email: string, password: string, username?: string) =>
    api.post('/auth/register', { email, password, username }),
  me: () => api.get('/auth/me'),
}

// Puzzles
export const puzzlesApi = {
  getAll: (params?: Record<string, any>) =>
    api.get('/puzzles', { params }),
  getById: (id: string) =>
    api.get(`/puzzles/${id}`),
  getToday: () =>
    api.get('/puzzles/today'),
  getByDate: (date: string) =>
    api.get('/puzzles', { params: { date } }),
  getByDateRange: (startDate: string, endDate: string) =>
    api.get('/puzzles', { params: { startDate, endDate } }),
  getByTypeAndDate: (gameType: string, date: string) =>
    api.get(`/puzzles/type/${gameType}/date/${date}`),
  getStats: () =>
    api.get('/puzzles/admin/stats'),
  create: (data: any) =>
    api.post('/puzzles', data),
  createMany: (data: any[]) =>
    api.post('/puzzles/bulk', data),
  update: (id: string, data: any) =>
    api.patch(`/puzzles/${id}`, data),
  toggleActive: (id: string) =>
    api.patch(`/puzzles/${id}/toggle-active`),
  updateStatus: (id: string, status: PuzzleStatus) =>
    api.patch(`/puzzles/${id}/status`, { status }),
  delete: (id: string) =>
    api.delete(`/puzzles/${id}`),
}

// Game Types
export const GAME_TYPES = [
  'sudoku',
  'killerSudoku',
  'crossword',
  'wordSearch',
  'wordForge',
  'nonogram',
  'numberTarget',
  'ballSort',
  'pipes',
  'lightsOut',
  'wordLadder',
  'connections',
  'mathora',
] as const

export type GameType = typeof GAME_TYPES[number]

// Puzzle Status
export const PUZZLE_STATUSES = ['pending', 'active', 'inactive'] as const
export type PuzzleStatus = typeof PUZZLE_STATUSES[number]

export const PUZZLE_STATUS_LABELS: Record<PuzzleStatus, string> = {
  pending: 'Pending',
  active: 'Active',
  inactive: 'Inactive',
}

export const GAME_TYPE_LABELS: Record<GameType, string> = {
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

// Scores
export const scoresApi = {
  getStats: () =>
    api.get('/scores/stats'),
  getByPuzzle: (puzzleId: string) =>
    api.get(`/scores/puzzle/${puzzleId}`),
  getLeaderboard: (puzzleId: string) =>
    api.get(`/scores/leaderboard/${puzzleId}`),
}

// Feedback
export const feedbackApi = {
  getAll: (params?: Record<string, any>) =>
    api.get('/feedback', { params }),
  getById: (id: string) =>
    api.get(`/feedback/${id}`),
  getStats: () =>
    api.get('/feedback/stats'),
  update: (id: string, data: { status?: string; adminNotes?: string }) =>
    api.patch(`/feedback/${id}`, data),
  delete: (id: string) =>
    api.delete(`/feedback/${id}`),
}

// Dictionary
export const dictionaryApi = {
  getAll: (params?: Record<string, any>) =>
    api.get('/dictionary', { params }),
  getByWord: (word: string) =>
    api.get(`/dictionary/word/${word}`),
  updateClue: (word: string, clue: string) =>
    api.patch(`/dictionary/word/${word}`, { clue }),
  delete: (word: string) =>
    api.delete(`/dictionary/word/${word}`),
  getStatus: () =>
    api.get('/dictionary/status'),
  addWord: (word: string, clue?: string) =>
    api.post('/dictionary/word', { word, clue }),
  bulkAddWords: (words: string[]) =>
    api.post('/dictionary/words/bulk', { words }),
}

// Generate
export type Difficulty = 'easy' | 'medium' | 'hard' | 'expert'

export const generateApi = {
  sudoku: (date: string, difficulty: Difficulty) =>
    api.post('/generate/sudoku', { date, difficulty }),
  killerSudoku: (date: string, difficulty: Difficulty) =>
    api.post('/generate/killer-sudoku', { date, difficulty }),
  crossword: (date: string, difficulty: Difficulty, wordsWithClues: { word: string; clue: string }[]) =>
    api.post('/generate/crossword', { date, difficulty, wordsWithClues }),
  wordSearch: (date: string, difficulty: Difficulty, words: string[], theme?: string) =>
    api.post('/generate/word-search', { date, difficulty, words, theme }),
  wordForge: (date: string, difficulty: Difficulty) =>
    api.post('/generate/word-forge', { date, difficulty }),
  nonogram: (date: string, difficulty: Difficulty) =>
    api.post('/generate/nonogram', { date, difficulty }),
  numberTarget: (date: string, difficulty: Difficulty) =>
    api.post('/generate/number-target', { date, difficulty }),
  ballSort: (date: string, difficulty: Difficulty) =>
    api.post('/generate/ball-sort', { date, difficulty }),
  pipes: (date: string, difficulty: Difficulty) =>
    api.post('/generate/pipes', { date, difficulty }),
  lightsOut: (date: string, difficulty: Difficulty) =>
    api.post('/generate/lights-out', { date, difficulty }),
  wordLadder: (date: string, difficulty: Difficulty) =>
    api.post('/generate/word-ladder', { date, difficulty }),
  connections: (date: string, difficulty: Difficulty) =>
    api.post('/generate/connections', { date, difficulty }),
  mathora: (date: string, difficulty: Difficulty) =>
    api.post('/generate/mathora', { date, difficulty }),
}

// Validation
export interface Cage {
  sum: number
  cells: [number, number][]
}

export const validateApi = {
  validateSudoku: (grid: number[][]) =>
    api.post('/validate/sudoku', { grid }),
  solveSudoku: (grid: number[][]) =>
    api.post('/validate/sudoku/solve', { grid }),
  validateKillerSudoku: (cages: Cage[]) =>
    api.post('/validate/killer-sudoku', { cages }),
  solveKillerSudoku: (cages: Cage[]) =>
    api.post('/validate/killer-sudoku/solve', { cages }),
  validateWordLadder: (startWord: string, targetWord: string, wordLength: number) =>
    api.post('/validate/word-ladder', { startWord, targetWord, wordLength }),
  validateNumberTarget: (numbers: number[], targets: { target: number; difficulty: string }[]) =>
    api.post('/validate/number-target', { numbers, targets }),
  validateWordForge: (letters: string[], centerLetter: string) =>
    api.post('/validate/word-forge', { letters, centerLetter }),
}

// AI
export const aiApi = {
  getStatus: () => api.get('/ai/status'),
  generateCrosswordWords: (theme: string, count?: number, minLength?: number, maxLength?: number) =>
    api.post('/ai/crossword-words', { theme, count, minLength, maxLength }),
  generateConnections: (theme?: string) =>
    api.post('/ai/connections', { theme }),
}

export default api
