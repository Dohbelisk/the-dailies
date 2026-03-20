import { useState, useEffect } from 'react'
import { Outlet, NavLink, useNavigate } from 'react-router-dom'
import { useAuthStore } from '../stores/authStore'
import { puzzlesApi, GAME_TYPE_LABELS, GameType } from '../lib/api'
import {
  LayoutDashboard,
  Puzzle,
  LogOut,
  Menu,
  X,
  Wand2,
  MessageSquare,
  Book,
  CalendarDays,
  ChevronDown,
  Sun,
  Sunrise,
} from 'lucide-react'

const navItems = [
  { to: '/', icon: LayoutDashboard, label: 'Dashboard' },
  { to: '/schedule', icon: CalendarDays, label: 'Schedule' },
  { to: '/puzzles', icon: Puzzle, label: 'Puzzles' },
  { to: '/puzzles/generate', icon: Wand2, label: 'Generate' },
  { to: '/feedback', icon: MessageSquare, label: 'Feedback' },
  { to: '/dictionary', icon: Book, label: 'Dictionary' },
]

function formatDate(date: Date): string {
  const y = date.getFullYear()
  const m = String(date.getMonth() + 1).padStart(2, '0')
  const d = String(date.getDate()).padStart(2, '0')
  return `${y}-${m}-${d}`
}

interface PuzzleMenuItem {
  id: string
  gameType: GameType
  label: string
}

function DaySection({
  label,
  icon: Icon,
  date,
  onNavigate,
}: {
  label: string
  icon: React.ElementType
  date: string
  onNavigate: () => void
}) {
  const [open, setOpen] = useState(false)
  const [puzzles, setPuzzles] = useState<PuzzleMenuItem[]>([])
  const [loaded, setLoaded] = useState(false)

  useEffect(() => {
    if (open && !loaded) {
      puzzlesApi
        .getByDateRange(date, date)
        .then((res) => {
          const items = (res.data as any[])
            .map((p: any) => ({
              id: p._id || p.id,
              gameType: p.gameType as GameType,
              label: GAME_TYPE_LABELS[p.gameType as GameType] || p.gameType,
            }))
            .sort((a, b) => a.label.localeCompare(b.label))
          setPuzzles(items)
          setLoaded(true)
        })
        .catch(() => setLoaded(true))
    }
  }, [open, loaded, date])

  return (
    <div>
      <button
        onClick={() => setOpen(!open)}
        className="w-full flex items-center gap-3 px-4 py-3 rounded-lg transition-colors text-gray-600 hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-gray-700"
      >
        <Icon className="w-5 h-5" />
        <span className="font-medium flex-1 text-left">{label}</span>
        <ChevronDown
          className={`w-4 h-4 transition-transform ${open ? 'rotate-180' : ''}`}
        />
      </button>
      {open && (
        <div className="ml-4 pl-4 border-l border-gray-200 dark:border-gray-700 space-y-0.5 mt-0.5">
          {!loaded ? (
            <p className="text-xs text-gray-400 px-4 py-2">Loading...</p>
          ) : puzzles.length === 0 ? (
            <p className="text-xs text-gray-400 px-4 py-2">No puzzles</p>
          ) : (
            puzzles.map((p) => (
              <NavLink
                key={p.id}
                to={`/puzzles/${p.id}/edit`}
                className={({ isActive }) =>
                  `block px-4 py-2 text-sm rounded-lg transition-colors ${
                    isActive
                      ? 'bg-primary-50 text-primary-700 dark:bg-primary-900/20 dark:text-primary-400'
                      : 'text-gray-500 hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-gray-700'
                  }`
                }
                onClick={onNavigate}
              >
                {p.label}
              </NavLink>
            ))
          )}
        </div>
      )}
    </div>
  )
}

export default function Layout() {
  const [sidebarOpen, setSidebarOpen] = useState(false)
  const { user, logout } = useAuthStore()
  const navigate = useNavigate()

  const today = formatDate(new Date())
  const tomorrow = formatDate(
    new Date(Date.now() + 24 * 60 * 60 * 1000)
  )

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      {/* Mobile sidebar backdrop */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 bg-black/50 z-40 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside
        className={`fixed top-0 left-0 z-50 h-full w-64 bg-white dark:bg-gray-800 border-r border-gray-200 dark:border-gray-700 transform transition-transform duration-200 lg:translate-x-0 ${
          sidebarOpen ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        <div className="flex items-center justify-between h-16 px-6 border-b border-gray-200 dark:border-gray-700">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 bg-primary-600 rounded-lg flex items-center justify-center">
              <Puzzle className="w-5 h-5 text-white" />
            </div>
            <span className="font-bold text-lg text-gray-900 dark:text-white">
              The Dailies
            </span>
          </div>
          <button
            className="lg:hidden p-1 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700"
            onClick={() => setSidebarOpen(false)}
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <nav className="p-4 space-y-1 overflow-y-auto" style={{ maxHeight: 'calc(100vh - 10rem)' }}>
          {navItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.to === '/'}
              className={({ isActive }) =>
                `flex items-center gap-3 px-4 py-3 rounded-lg transition-colors ${
                  isActive
                    ? 'bg-primary-50 text-primary-700 dark:bg-primary-900/20 dark:text-primary-400'
                    : 'text-gray-600 hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-gray-700'
                }`
              }
              onClick={() => setSidebarOpen(false)}
            >
              <item.icon className="w-5 h-5" />
              <span className="font-medium">{item.label}</span>
            </NavLink>
          ))}

          <div className="pt-2 mt-2 border-t border-gray-200 dark:border-gray-700">
            <DaySection
              label="Today"
              icon={Sun}
              date={today}
              onNavigate={() => setSidebarOpen(false)}
            />
            <DaySection
              label="Tomorrow"
              icon={Sunrise}
              date={tomorrow}
              onNavigate={() => setSidebarOpen(false)}
            />
          </div>
        </nav>

        <div className="absolute bottom-0 left-0 right-0 p-4 border-t border-gray-200 dark:border-gray-700">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-10 h-10 bg-primary-100 dark:bg-primary-900 rounded-full flex items-center justify-center">
              <span className="text-primary-700 dark:text-primary-400 font-medium">
                {user?.email?.[0]?.toUpperCase() || 'A'}
              </span>
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium text-gray-900 dark:text-white truncate">
                {user?.username || 'Admin'}
              </p>
              <p className="text-xs text-gray-500 truncate">{user?.email}</p>
            </div>
          </div>
          <button
            onClick={handleLogout}
            className="w-full flex items-center justify-center gap-2 px-4 py-2 text-sm text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
          >
            <LogOut className="w-4 h-4" />
            Sign Out
          </button>
        </div>
      </aside>

      {/* Main content */}
      <div className="lg:pl-64">
        {/* Top bar */}
        <header className="sticky top-0 z-30 h-16 bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700 flex items-center px-4 lg:px-6">
          <button
            className="lg:hidden p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700"
            onClick={() => setSidebarOpen(true)}
          >
            <Menu className="w-5 h-5" />
          </button>
          <div className="ml-auto flex items-center gap-4">
            <span className="text-sm text-gray-500 dark:text-gray-400">
              Admin Portal
            </span>
          </div>
        </header>

        {/* Page content */}
        <main className="p-4 lg:p-6">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
