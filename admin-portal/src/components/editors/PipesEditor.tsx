import { useState, useCallback, useEffect, useMemo, useRef } from 'react'
import { Trash2, CheckCircle, Wand2, Play, ArrowLeft, RotateCcw } from 'lucide-react'
import ValidationStatus from './shared/ValidationStatus'

interface PipesEndpoint {
  color: string
  row: number
  col: number
}

interface PipesEditorProps {
  initialData?: {
    rows: number
    cols: number
    endpoints: PipesEndpoint[]
  }
  initialSolution?: {
    paths: Record<string, { row: number; col: number }[]>
  }
  onChange?: (puzzleData: any, solution: any, isValid?: boolean) => void
  className?: string
}

type GridSize = 5 | 6 | 7 | 8 | 10 | 12

const PIPE_COLORS: Record<string, string> = {
  red: '#EF4444',
  blue: '#3B82F6',
  green: '#22C55E',
  yellow: '#EAB308',
  orange: '#F97316',
  purple: '#A855F7',
  pink: '#EC4899',
  cyan: '#06B6D4',
  maroon: '#881337',
  lime: '#84CC16',
  teal: '#14B8A6',
  coral: '#FB7185',
  navy: '#1E3A8A',
  gold: '#F59E0B',
  crimson: '#DC2626',
  olive: '#4D7C0F',
  indigo: '#6366F1',
  salmon: '#FDA4AF',
  violet: '#7C3AED',
  tan: '#D2B48C',
}

const EDITOR_COLORS = [
  'red', 'blue', 'green', 'yellow', 'orange', 'purple', 'pink', 'cyan',
  'maroon', 'lime', 'teal', 'coral',
]

const getHexColor = (name: string): string => PIPE_COLORS[name] || '#9CA3AF'

// Generate a simple puzzle with random endpoints
const generateSimplePuzzle = (size: GridSize, numColors: number): PipesEndpoint[] => {
  const endpoints: PipesEndpoint[] = []
  const usedCells = new Set<string>()
  const colors = EDITOR_COLORS.slice(0, numColors)

  for (const color of colors) {
    for (let j = 0; j < 2; j++) {
      let attempts = 0
      while (attempts < 100) {
        const row = Math.floor(Math.random() * size)
        const col = Math.floor(Math.random() * size)
        const key = `${row},${col}`

        if (!usedCells.has(key)) {
          usedCells.add(key)
          endpoints.push({ color, row, col })
          break
        }
        attempts++
      }
    }
  }

  return endpoints
}

// ─── Play Mode Component ────────────────────────────────────────────────────

interface PlayModeProps {
  size: number
  endpoints: PipesEndpoint[]
  solution?: Record<string, { row: number; col: number }[]>
  onExit: () => void
}

function PipesPlayMode({ size, endpoints, solution, onExit }: PlayModeProps) {
  const [paths, setPaths] = useState<Record<string, [number, number][]>>({})
  const [activeColor, setActiveColor] = useState<string | null>(null)
  const [isDrawing, setIsDrawing] = useState(false)
  const [showSolution, setShowSolution] = useState(false)
  const gridRef = useRef<HTMLDivElement>(null)

  // Get all unique colors
  const colors = useMemo(() => {
    const c = new Set<string>()
    endpoints.forEach(ep => c.add(ep.color))
    return Array.from(c)
  }, [endpoints])

  // Endpoint lookup
  const endpointMap = useMemo(() => {
    const map = new Map<string, PipesEndpoint>()
    endpoints.forEach(ep => map.set(`${ep.row},${ep.col}`, ep))
    return map
  }, [endpoints])

  // Cell ownership: which color occupies each cell
  const cellOwner = useMemo(() => {
    const map = new Map<string, string>()
    for (const [color, path] of Object.entries(paths)) {
      for (const [r, c] of path) {
        map.set(`${r},${c}`, color)
      }
    }
    return map
  }, [paths])

  // Check completion
  const completionStatus = useMemo(() => {
    let connected = 0
    for (const color of colors) {
      const path = paths[color]
      if (!path || path.length < 2) continue
      const eps = endpoints.filter(ep => ep.color === color)
      if (eps.length !== 2) continue
      const first = path[0]
      const last = path[path.length - 1]
      const ep1 = eps[0]
      const ep2 = eps[1]
      const startsAtEndpoint = (first[0] === ep1.row && first[1] === ep1.col) || (first[0] === ep2.row && first[1] === ep2.col)
      const endsAtEndpoint = (last[0] === ep1.row && last[1] === ep1.col) || (last[0] === ep2.row && last[1] === ep2.col)
      if (startsAtEndpoint && endsAtEndpoint) connected++
    }
    const totalCells = size * size
    const filledCells = new Set(Object.values(paths).flat().map(([r, c]) => `${r},${c}`)).size
    return { connected, total: colors.length, filledCells, totalCells }
  }, [paths, colors, endpoints, size])

  const isComplete = completionStatus.connected === completionStatus.total && completionStatus.filledCells === completionStatus.totalCells

  const getCellSize = () => {
    return Math.min(48, Math.floor(480 / size))
  }

  const getCellFromEvent = useCallback((e: React.MouseEvent | React.TouchEvent): [number, number] | null => {
    if (!gridRef.current) return null
    const rect = gridRef.current.getBoundingClientRect()
    const cellSize = getCellSize()
    let clientX: number, clientY: number
    if ('touches' in e) {
      clientX = e.touches[0].clientX
      clientY = e.touches[0].clientY
    } else {
      clientX = e.clientX
      clientY = e.clientY
    }
    const col = Math.floor((clientX - rect.left) / cellSize)
    const row = Math.floor((clientY - rect.top) / cellSize)
    if (row >= 0 && row < size && col >= 0 && col < size) return [row, col]
    return null
  }, [size])

  const isAdjacent = (a: [number, number], b: [number, number]) => {
    return Math.abs(a[0] - b[0]) + Math.abs(a[1] - b[1]) === 1
  }

  const handlePointerDown = useCallback((e: React.MouseEvent) => {
    e.preventDefault()
    const cell = getCellFromEvent(e)
    if (!cell) return

    const [row, col] = cell
    const key = `${row},${col}`

    // Check if clicking on an endpoint
    const endpoint = endpointMap.get(key)
    if (endpoint) {
      // Start drawing from this endpoint
      setActiveColor(endpoint.color)
      setIsDrawing(true)
      // Clear existing path for this color, but also free cells owned by it
      setPaths(prev => ({
        ...prev,
        [endpoint.color]: [[row, col]],
      }))
      return
    }

    // Check if clicking on an existing path
    const owner = cellOwner.get(key)
    if (owner) {
      const path = paths[owner]
      if (path) {
        // Find cell index in path and truncate there
        const idx = path.findIndex(([r, c]) => r === row && c === col)
        if (idx >= 0) {
          setActiveColor(owner)
          setIsDrawing(true)
          setPaths(prev => ({
            ...prev,
            [owner]: prev[owner].slice(0, idx + 1),
          }))
        }
      }
    }
  }, [getCellFromEvent, endpointMap, cellOwner, paths])

  const handlePointerMove = useCallback((e: React.MouseEvent) => {
    if (!isDrawing || !activeColor) return
    e.preventDefault()
    const cell = getCellFromEvent(e)
    if (!cell) return

    const [row, col] = cell
    const key = `${row},${col}`

    setPaths(prev => {
      const currentPath = prev[activeColor] || []
      if (currentPath.length === 0) return prev

      const last = currentPath[currentPath.length - 1]

      // Same cell - ignore
      if (last[0] === row && last[1] === col) return prev

      // Must be adjacent
      if (!isAdjacent(last, [row, col])) return prev

      // Check if we're backtracking on our own path
      if (currentPath.length >= 2) {
        const secondLast = currentPath[currentPath.length - 2]
        if (secondLast[0] === row && secondLast[1] === col) {
          // Backtrack: remove last cell
          return { ...prev, [activeColor]: currentPath.slice(0, -1) }
        }
      }

      // Check if this cell is already in our own path (loop)
      if (currentPath.some(([r, c]) => r === row && c === col)) return prev

      // Check if cell is owned by another color
      const owner = cellOwner.get(key)
      if (owner && owner !== activeColor) {
        // Overwrite: truncate the other color's path up to (but not including) this cell
        const otherPath = prev[owner] || []
        const otherIdx = otherPath.findIndex(([r, c]) => r === row && c === col)
        if (otherIdx >= 0) {
          return {
            ...prev,
            [owner]: otherPath.slice(0, otherIdx),
            [activeColor]: [...currentPath, [row, col]],
          }
        }
      }

      // Check if this is the other endpoint of our color - allow extending to it
      const endpoint = endpointMap.get(key)
      if (endpoint && endpoint.color === activeColor) {
        return { ...prev, [activeColor]: [...currentPath, [row, col]] }
      }

      // Free cell or own endpoint - extend
      if (!owner) {
        return { ...prev, [activeColor]: [...currentPath, [row, col]] }
      }

      return prev
    })
  }, [isDrawing, activeColor, getCellFromEvent, cellOwner, endpointMap])

  const handlePointerUp = useCallback(() => {
    setIsDrawing(false)
  }, [])

  const handleReset = useCallback(() => {
    setPaths({})
    setActiveColor(null)
    setIsDrawing(false)
    setShowSolution(false)
  }, [])

  const handleShowSolution = useCallback(() => {
    if (!solution) return
    const newPaths: Record<string, [number, number][]> = {}
    for (const [color, path] of Object.entries(solution)) {
      newPaths[color] = path.map(p => [p.row, p.col] as [number, number])
    }
    setPaths(newPaths)
    setShowSolution(true)
  }, [solution])

  const cellSize = getCellSize()
  const gridPx = cellSize * size

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <button
          onClick={onExit}
          className="flex items-center gap-2 px-3 py-2 text-sm bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-md hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors"
        >
          <ArrowLeft className="w-4 h-4" />
          Back to Editor
        </button>
        <div className="flex gap-2">
          <button
            onClick={handleReset}
            className="flex items-center gap-2 px-3 py-2 text-sm bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-300 rounded-md hover:bg-red-200 dark:hover:bg-red-900/50 transition-colors"
          >
            <RotateCcw className="w-4 h-4" />
            Reset
          </button>
          {solution && Object.keys(solution).length > 0 && (
            <button
              onClick={handleShowSolution}
              className="flex items-center gap-2 px-3 py-2 text-sm bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-300 rounded-md hover:bg-purple-200 dark:hover:bg-purple-900/50 transition-colors"
            >
              Show Solution
            </button>
          )}
        </div>
      </div>

      {/* Status bar */}
      <div className="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-800 rounded-lg">
        <div className="flex items-center gap-4 text-sm">
          <span className="text-gray-600 dark:text-gray-400">
            Pipes: <span className="font-semibold text-gray-900 dark:text-white">{completionStatus.connected}/{completionStatus.total}</span>
          </span>
          <span className="text-gray-600 dark:text-gray-400">
            Filled: <span className="font-semibold text-gray-900 dark:text-white">{completionStatus.filledCells}/{completionStatus.totalCells}</span>
          </span>
        </div>
        {isComplete && (
          <span className="px-3 py-1 bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300 rounded-full text-sm font-semibold">
            Puzzle Complete!
          </span>
        )}
        {showSolution && (
          <span className="px-3 py-1 bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-300 rounded-full text-sm font-semibold">
            Showing Solution
          </span>
        )}
      </div>

      {/* Color legend */}
      <div className="flex flex-wrap gap-2">
        {colors.map(color => {
          const path = paths[color] || []
          const eps = endpoints.filter(ep => ep.color === color)
          const isConnected = (() => {
            if (path.length < 2 || eps.length !== 2) return false
            const first = path[0]
            const last = path[path.length - 1]
            const startsOk = (first[0] === eps[0].row && first[1] === eps[0].col) || (first[0] === eps[1].row && first[1] === eps[1].col)
            const endsOk = (last[0] === eps[0].row && last[1] === eps[0].col) || (last[0] === eps[1].row && last[1] === eps[1].col)
            return startsOk && endsOk
          })()
          return (
            <div
              key={color}
              className={`flex items-center gap-1.5 px-2 py-1 rounded text-xs font-medium
                ${isConnected ? 'bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300' : 'bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400'}`}
            >
              <div className="w-3 h-3 rounded-full" style={{ backgroundColor: getHexColor(color) }} />
              <span>{color}</span>
              {isConnected && <CheckCircle className="w-3 h-3" />}
            </div>
          )
        })}
      </div>

      {/* Playable grid */}
      <div className="flex justify-center">
        <div
          ref={gridRef}
          className="relative select-none touch-none"
          style={{ width: gridPx, height: gridPx }}
          onMouseDown={handlePointerDown}
          onMouseMove={handlePointerMove}
          onMouseUp={handlePointerUp}
          onMouseLeave={handlePointerUp}
        >
          {/* SVG layer for paths */}
          <svg
            className="absolute inset-0"
            width={gridPx}
            height={gridPx}
            style={{ zIndex: 1 }}
          >
            {/* Grid lines */}
            {Array.from({ length: size + 1 }, (_, i) => (
              <g key={`grid-${i}`}>
                <line
                  x1={0} y1={i * cellSize} x2={gridPx} y2={i * cellSize}
                  stroke="currentColor" className="text-gray-300 dark:text-gray-600" strokeWidth={1}
                />
                <line
                  x1={i * cellSize} y1={0} x2={i * cellSize} y2={gridPx}
                  stroke="currentColor" className="text-gray-300 dark:text-gray-600" strokeWidth={1}
                />
              </g>
            ))}

            {/* Drawn paths */}
            {Object.entries(paths).map(([color, path]) => {
              if (path.length < 2) return null
              const hex = getHexColor(color)
              const points = path.map(([r, c]) => `${c * cellSize + cellSize / 2},${r * cellSize + cellSize / 2}`)
              return (
                <polyline
                  key={`path-${color}`}
                  points={points.join(' ')}
                  fill="none"
                  stroke={hex}
                  strokeWidth={cellSize * 0.4}
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  opacity={0.7}
                />
              )
            })}

            {/* Path cell fills (subtle) */}
            {Object.entries(paths).map(([color, path]) => {
              const hex = getHexColor(color)
              return path.map(([r, c], i) => {
                const isEndpoint = endpointMap.has(`${r},${c}`)
                if (isEndpoint) return null
                return (
                  <rect
                    key={`fill-${color}-${i}`}
                    x={c * cellSize + 1}
                    y={r * cellSize + 1}
                    width={cellSize - 2}
                    height={cellSize - 2}
                    fill={hex}
                    opacity={0.1}
                    rx={4}
                  />
                )
              })
            })}

            {/* Endpoints */}
            {endpoints.map((ep, i) => {
              const cx = ep.col * cellSize + cellSize / 2
              const cy = ep.row * cellSize + cellSize / 2
              const hex = getHexColor(ep.color)
              return (
                <g key={`ep-${i}`}>
                  <circle cx={cx} cy={cy} r={cellSize * 0.33} fill={hex} />
                  <circle cx={cx - cellSize * 0.08} cy={cy - cellSize * 0.08} r={cellSize * 0.1} fill="white" opacity={0.4} />
                </g>
              )
            })}
          </svg>

          {/* Invisible interaction layer */}
          <div className="absolute inset-0" style={{ zIndex: 2 }} />
        </div>
      </div>

      <p className="text-xs text-center text-gray-500 dark:text-gray-400">
        Click an endpoint or path and drag to draw. Connect all pairs and fill every cell.
      </p>
    </div>
  )
}

// ─── Editor Component ───────────────────────────────────────────────────────

export function PipesEditor({
  initialData,
  initialSolution,
  onChange,
  className = '',
}: PipesEditorProps) {
  const [mode, setMode] = useState<'edit' | 'play'>('edit')
  const [size, setSize] = useState<GridSize>((initialData?.rows as GridSize) || 5)
  const [endpoints, setEndpoints] = useState<PipesEndpoint[]>(
    initialData?.endpoints || generateSimplePuzzle(5, 3)
  )
  const [selectedColor, setSelectedColor] = useState<string | null>(null)
  const [validationResult, setValidationResult] = useState<{
    isValid: boolean
    hasUniqueSolution: boolean
    errors: { row: number; col: number; message: string }[]
  } | null>(null)

  // Store solution from initial data for play mode
  const solutionRef = useRef(initialSolution?.paths)

  // Count endpoints per color
  const colorEndpointCounts = useMemo(() => {
    const counts = new Map<string, number>()
    for (const ep of endpoints) {
      counts.set(ep.color, (counts.get(ep.color) || 0) + 1)
    }
    return counts
  }, [endpoints])

  // Get unique colors used in endpoints (for the palette)
  const usedColors = useMemo(() => {
    const s = new Set<string>()
    endpoints.forEach(ep => s.add(ep.color))
    return s
  }, [endpoints])

  // Colors available in palette: used colors + editor defaults up to grid capacity
  const paletteColors = useMemo(() => {
    const maxColors = Math.min(size, EDITOR_COLORS.length)
    const palette = EDITOR_COLORS.slice(0, maxColors)
    // Also include any colors used in endpoints that aren't in the default palette
    for (const color of usedColors) {
      if (!palette.includes(color)) palette.push(color)
    }
    return palette
  }, [size, usedColors])

  // Notify parent of changes
  useEffect(() => {
    if (onChange && validationResult?.isValid) {
      onChange(
        { rows: size, cols: size, endpoints, bridges: [] },
        solutionRef.current ? { paths: solutionRef.current } : { paths: {} },
        true
      )
    }
  }, [size, endpoints, onChange, validationResult])

  const handleSizeChange = useCallback((newSize: GridSize) => {
    setSize(newSize)
    setEndpoints([])
    setValidationResult(null)
  }, [])

  const handleCellClick = useCallback((row: number, col: number) => {
    const existingIdx = endpoints.findIndex(ep => ep.row === row && ep.col === col)
    if (existingIdx >= 0) {
      setEndpoints(prev => prev.filter((_, i) => i !== existingIdx))
      setValidationResult(null)
      return
    }

    if (!selectedColor) return

    const currentCount = colorEndpointCounts.get(selectedColor) || 0
    if (currentCount >= 2) return

    setEndpoints(prev => [...prev, { color: selectedColor, row, col }])
    setValidationResult(null)
  }, [selectedColor, endpoints, colorEndpointCounts])

  const handleColorSelect = useCallback((colorName: string) => {
    setSelectedColor(prev => prev === colorName ? null : colorName)
  }, [])

  const handleClear = useCallback(() => {
    setEndpoints([])
    setSelectedColor(null)
    setValidationResult(null)
  }, [])

  const handleRandomize = useCallback(() => {
    const numColors = Math.min(size - 1, 6)
    setEndpoints(generateSimplePuzzle(size, numColors))
    setValidationResult(null)
  }, [size])

  const handleValidate = useCallback(() => {
    const errors: { row: number; col: number; message: string }[] = []
    const colorCounts = new Map<string, number>()
    for (const ep of endpoints) {
      colorCounts.set(ep.color, (colorCounts.get(ep.color) || 0) + 1)
    }

    let validColorCount = 0
    for (const [color, count] of colorCounts) {
      if (count === 1) {
        errors.push({ row: -1, col: -1, message: `${color} has only 1 endpoint (need 2)` })
      } else if (count === 2) {
        validColorCount++
      } else if (count > 2) {
        errors.push({ row: -1, col: -1, message: `${color} has ${count} endpoints (need 2)` })
      }
    }

    if (validColorCount < 2) {
      errors.push({ row: -1, col: -1, message: 'Need at least 2 complete color pairs' })
    }

    if (errors.length > 0) {
      setValidationResult({ isValid: false, hasUniqueSolution: false, errors })
    } else {
      setValidationResult({ isValid: true, hasUniqueSolution: true, errors: [] })
    }
  }, [endpoints])

  // Create endpoint lookup map
  const endpointMap = useMemo(() => {
    const map = new Map<string, PipesEndpoint>()
    for (const ep of endpoints) {
      map.set(`${ep.row},${ep.col}`, ep)
    }
    return map
  }, [endpoints])

  if (mode === 'play') {
    return (
      <div className={className}>
        <PipesPlayMode
          size={size}
          endpoints={endpoints}
          solution={solutionRef.current}
          onExit={() => setMode('edit')}
        />
      </div>
    )
  }

  const cellPx = Math.min(48, Math.floor(480 / size))

  return (
    <div className={`space-y-6 ${className}`}>
      {/* Size selector */}
      <div>
        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
          Grid Size
        </label>
        <div className="flex gap-2 flex-wrap">
          {([5, 6, 7, 8, 10, 12] as GridSize[]).map((s) => (
            <button
              key={s}
              type="button"
              onClick={() => handleSizeChange(s)}
              className={`px-4 py-2 rounded-md font-medium transition-colors ${
                size === s
                  ? 'bg-blue-500 text-white'
                  : 'bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600'
              }`}
            >
              {s}x{s}
            </button>
          ))}
        </div>
      </div>

      {/* Color palette */}
      <div>
        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
          Select Color to Place (each color needs 2 endpoints)
        </label>
        <div className="flex gap-2 flex-wrap">
          {paletteColors.map((colorName) => {
            const count = colorEndpointCounts.get(colorName) || 0
            const isComplete = count === 2
            const isSelected = selectedColor === colorName
            const hex = getHexColor(colorName)

            return (
              <button
                key={colorName}
                type="button"
                onClick={() => handleColorSelect(colorName)}
                disabled={isComplete && !isSelected}
                className={`flex items-center gap-2 px-3 py-2 rounded-md border-2 transition-all ${
                  isSelected
                    ? 'border-blue-400 bg-white dark:bg-gray-800 ring-2 ring-offset-1 ring-blue-400'
                    : isComplete
                    ? 'border-gray-200 dark:border-gray-700 bg-gray-100 dark:bg-gray-800 opacity-50'
                    : 'border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600'
                }`}
              >
                <div className="w-4 h-4 rounded-full" style={{ backgroundColor: hex }} />
                <span className={`text-sm font-medium ${isComplete ? 'text-gray-400' : ''}`}>
                  {colorName} ({count}/2)
                </span>
              </button>
            )
          })}
        </div>
        {selectedColor && (
          <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">
            Click on the grid to place {selectedColor} endpoints
          </p>
        )}
      </div>

      {/* Grid */}
      <div>
        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
          Grid (click to place/remove endpoints)
        </label>
        <div className="inline-block border-2 border-gray-700 dark:border-gray-400 rounded-lg overflow-hidden">
          <div
            className="grid"
            style={{ gridTemplateColumns: `repeat(${size}, ${cellPx}px)` }}
          >
            {Array(size).fill(null).map((_, rowIdx) =>
              Array(size).fill(null).map((_, colIdx) => {
                const endpoint = endpointMap.get(`${rowIdx},${colIdx}`)
                const hex = endpoint ? getHexColor(endpoint.color) : null

                return (
                  <button
                    key={`${rowIdx}-${colIdx}`}
                    type="button"
                    onClick={() => handleCellClick(rowIdx, colIdx)}
                    className={`border border-gray-300 dark:border-gray-600
                               flex items-center justify-center transition-colors
                               ${endpoint
                                 ? ''
                                 : 'bg-white dark:bg-gray-700 hover:bg-gray-100 dark:hover:bg-gray-600'
                               }
                               ${selectedColor && !endpoint ? 'cursor-pointer' : ''}
                               ${endpoint ? 'cursor-pointer' : ''}`}
                    style={{
                      width: cellPx,
                      height: cellPx,
                      backgroundColor: endpoint ? `${hex}20` : undefined,
                    }}
                  >
                    {endpoint && (
                      <div
                        className="rounded-full border-2 border-white flex items-center justify-center text-white font-bold shadow-md"
                        style={{
                          width: cellPx * 0.65,
                          height: cellPx * 0.65,
                          backgroundColor: hex!,
                          fontSize: Math.max(10, cellPx * 0.28),
                        }}
                      >
                        {endpoints.filter(e => e.color === endpoint.color).indexOf(endpoint) + 1}
                      </div>
                    )}
                  </button>
                )
              })
            )}
          </div>
        </div>
      </div>

      {/* Actions */}
      <div className="flex gap-2 flex-wrap">
        <button
          type="button"
          onClick={() => setMode('play')}
          disabled={endpoints.length < 4}
          className="flex items-center gap-2 px-4 py-2 bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300 rounded-md hover:bg-green-200 dark:hover:bg-green-900/50 transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
        >
          <Play className="w-4 h-4" />
          Test Play
        </button>
        <button
          type="button"
          onClick={handleRandomize}
          className="flex items-center gap-2 px-4 py-2 bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-300 rounded-md hover:bg-purple-200 dark:hover:bg-purple-900/50 transition-colors"
        >
          <Wand2 className="w-4 h-4" />
          Random
        </button>
        <button
          type="button"
          onClick={handleClear}
          className="flex items-center gap-2 px-4 py-2 bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-300 rounded-md hover:bg-red-200 dark:hover:bg-red-900/50 transition-colors"
        >
          <Trash2 className="w-4 h-4" />
          Clear
        </button>
        <button
          type="button"
          onClick={handleValidate}
          className="flex items-center gap-2 px-4 py-2 bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 rounded-md hover:bg-blue-200 dark:hover:bg-blue-900/50 transition-colors"
        >
          <CheckCircle className="w-4 h-4" />
          Validate
        </button>
      </div>

      {/* Validation status */}
      <ValidationStatus
        isValid={validationResult?.isValid}
        hasUniqueSolution={validationResult?.hasUniqueSolution}
        errors={validationResult?.errors}
      />

      {/* Summary */}
      {validationResult?.isValid && (
        <div className="p-4 bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg">
          <h4 className="font-medium text-green-800 dark:text-green-200 mb-2">
            Puzzle Ready
          </h4>
          <p className="text-sm text-green-700 dark:text-green-300">
            {colorEndpointCounts.size} color pairs placed on a {size}x{size} grid
          </p>
        </div>
      )}
    </div>
  )
}

export default PipesEditor
