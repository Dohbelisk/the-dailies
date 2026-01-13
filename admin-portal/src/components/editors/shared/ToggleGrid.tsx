interface ToggleGridProps {
  grid: boolean[][]
  onToggle: (row: number, col: number) => void
  readonly?: boolean
  cellSize?: 'sm' | 'md' | 'lg'
  className?: string
}

const CELL_SIZES = {
  sm: 'w-8 h-8 text-sm',
  md: 'w-10 h-10 text-base',
  lg: 'w-12 h-12 text-lg',
}

export default function ToggleGrid({
  grid,
  onToggle,
  readonly = false,
  cellSize = 'md',
  className = '',
}: ToggleGridProps) {
  const rows = grid.length
  const cols = rows > 0 ? grid[0].length : 0

  const getCellClasses = (isOn: boolean) => {
    const classes = [
      CELL_SIZES[cellSize],
      'flex items-center justify-center font-semibold',
      'border border-gray-400 dark:border-gray-500',
      'transition-all duration-150',
    ]

    if (isOn) {
      classes.push('bg-amber-400 dark:bg-amber-500 text-amber-900 dark:text-amber-100')
    } else {
      classes.push('bg-gray-700 dark:bg-gray-800 text-gray-400 dark:text-gray-500')
    }

    if (!readonly) {
      classes.push('cursor-pointer')
      if (isOn) {
        classes.push('hover:bg-amber-300 dark:hover:bg-amber-400')
      } else {
        classes.push('hover:bg-gray-600 dark:hover:bg-gray-700')
      }
    }

    return classes.join(' ')
  }

  return (
    <div
      className={`inline-block border-2 border-gray-600 dark:border-gray-400 rounded-lg overflow-hidden ${className}`}
    >
      <div
        className="grid"
        style={{ gridTemplateColumns: `repeat(${cols}, 1fr)` }}
      >
        {grid.map((row, rowIdx) =>
          row.map((cell, colIdx) => (
            <button
              key={`${rowIdx}-${colIdx}`}
              type="button"
              className={getCellClasses(cell)}
              onClick={() => !readonly && onToggle(rowIdx, colIdx)}
              disabled={readonly}
              aria-label={`Cell ${rowIdx + 1},${colIdx + 1}: ${cell ? 'on' : 'off'}`}
            >
              {cell ? '●' : '○'}
            </button>
          ))
        )}
      </div>
    </div>
  )
}
