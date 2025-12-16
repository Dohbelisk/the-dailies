import { Routes, Route, Navigate } from 'react-router-dom'
import { useAuthStore } from './stores/authStore'
import Layout from './components/Layout'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import PuzzleList from './pages/PuzzleList'
import PuzzleCreate from './pages/PuzzleCreate'
import PuzzleEdit from './pages/PuzzleEdit'
import PuzzleGenerate from './pages/PuzzleGenerate'
import FeedbackList from './pages/FeedbackList'

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { token } = useAuthStore()
  
  if (!token) {
    return <Navigate to="/login" replace />
  }
  
  return <>{children}</>
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route
        path="/"
        element={
          <ProtectedRoute>
            <Layout />
          </ProtectedRoute>
        }
      >
        <Route index element={<Dashboard />} />
        <Route path="puzzles" element={<PuzzleList />} />
        <Route path="puzzles/create" element={<PuzzleCreate />} />
        <Route path="puzzles/generate" element={<PuzzleGenerate />} />
        <Route path="puzzles/:id/edit" element={<PuzzleEdit />} />
        <Route path="feedback" element={<FeedbackList />} />
      </Route>
    </Routes>
  )
}
