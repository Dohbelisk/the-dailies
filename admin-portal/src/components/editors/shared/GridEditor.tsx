import { useCallback } from 'react'

interface GridEditorProps {
  grid: (number | null)[][]
  selectedCell: [number, number] | null
  onCellSelect: (row: number, col: number) => void
  errors?: { row: number; col: number }[]
  readonly?: boolean
  highlightRelated?: boolean
}

export default function GridEditor({
  grid,
  selectedCell,
  onCellSelect,
  errors = [],
  readonly = false,
  highlightRelated = true,
}: GridEditorProps) {
  const isError = useCallback(
    (row: number, col: number) => {
      return errors.some((e) => e.row === row && e.col === col)
    },
    [errors]
  )

  const isHighlighted = useCallback(
    (row: number, col: number) => {
      if (!selectedCell || !highlightRelated) return false
      const [selRow, selCol] = selectedCell

      // Same row or column
      if (row === selRow || col === selCol) return true

      // Same 3x3 box
      const boxRow = Math.floor(selRow / 3)
      const boxCol = Math.floor(selCol / 3)
      const cellBoxRow = Math.floor(row / 3)
      const cellBoxCol = Math.floor(col / 3)

      return boxRow === cellBoxRow && boxCol === cellBoxCol
    },
    [selectedCell, highlightRelated]
  )

  const isSelected = useCallback(
    (row: number, col: number) => {
      if (!selectedCell) return false
      return selectedCell[0] === row && selectedCell[1] === col
    },
    [selectedCell]
  )

  const getCellClasses = (row: number, col: number) => {
    const classes = [
      'w-10 h-10 flex items-center justify-center text-lg font-semibold',
      'border border-gray-300 dark:border-gray-600',
      'transition-colors duration-100',
    ]

    // Thicker borders for 3x3 box boundaries
    if (col % 3 === 0 && col !== 0) {
      classes.push('border-l-2 border-l-gray-500 dark:border-l-gray-400')
    }
    if (row % 3 === 0 && row !== 0) {
      classes.push('border-t-2 border-t-gray-500 dark:border-t-gray-400')
    }

    // Selection and highlighting
    if (isSelected(row, col)) {
      classes.push('bg-blue-500 text-white')
    } else if (isError(row, col)) {
      classes.push('bg-red-200 dark:bg-red-900 text-red-800 dark:text-red-200')
    } else if (isHighlighted(row, col)) {
      classes.push('bg-blue-100 dark:bg-blue-900/30')
    } else {
      classes.push('bg-white dark:bg-gray-800')
    }

    // Cursor style
    if (!readonly) {
      classes.push('cursor-pointer hover:bg-blue-50 dark:hover:bg-blue-900/20')
    }

    return classes.join(' ')
  }

  return (
    <div className="inline-block border-2 border-gray-700 dark:border-gray-400 rounded-lg overflow-hidden">
      <div className="grid grid-cols-9">
        {grid.map((row, rowIdx) =>
          row.map((cell, colIdx) => (
            <button
              key={`${rowIdx}-${colIdx}`}
              type="button"
              className={getCellClasses(rowIdx, colIdx)}
              onClick={() => !readonly && onCellSelect(rowIdx, colIdx)}
              disabled={readonly}
            >
              {cell !== null && cell !== 0 ? cell : ''}
            </button>
          ))
        )}
      </div>
    </div>
  )
}
