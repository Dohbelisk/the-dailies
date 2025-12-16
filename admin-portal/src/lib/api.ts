import axios from 'axios'
import { useAuthStore } from '../stores/authStore'

const api = axios.create({
  baseURL: '/api',
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
  delete: (id: string) =>
    api.delete(`/puzzles/${id}`),
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

export default api
