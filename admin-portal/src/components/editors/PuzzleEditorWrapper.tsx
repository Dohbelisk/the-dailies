import { SudokuEditor } from './SudokuEditor'

interface PuzzleEditorWrapperProps {
  gameType: string
  puzzleData?: {
    grid?: number[][]
    solution?: number[][]
    [key: string]: unknown
  }
  onChange?: (data: { grid: number[][]; solution: number[][] }) => void
  className?: string
}

export default function PuzzleEditorWrapper({
  gameType,
  puzzleData,
  onChange,
  className,
}: PuzzleEditorWrapperProps) {
  const handleSudokuChange = (grid: number[][], solution: number[][]) => {
    onChange?.({ grid, solution })
  }

  switch (gameType) {
    case 'sudoku':
      return (
        <SudokuEditor
          initialGrid={puzzleData?.grid}
          initialSolution={puzzleData?.solution}
          onChange={handleSudokuChange}
          className={className}
        />
      )

    case 'killerSudoku':
      // TODO: Implement KillerSudokuEditor
      return (
        <div className="p-4 bg-yellow-50 dark:bg-yellow-900/20 rounded-lg text-yellow-700 dark:text-yellow-400">
          Visual editor for Killer Sudoku coming soon. Use JSON mode for now.
        </div>
      )

    case 'crossword':
      return (
        <div className="p-4 bg-yellow-50 dark:bg-yellow-900/20 rounded-lg text-yellow-700 dark:text-yellow-400">
          Visual editor for Crossword coming soon. Use JSON mode for now.
        </div>
      )

    case 'wordSearch':
      return (
        <div className="p-4 bg-yellow-50 dark:bg-yellow-900/20 rounded-lg text-yellow-700 dark:text-yellow-400">
          Visual editor for Word Search coming soon. Use JSON mode for now.
        </div>
      )

    default:
      return (
        <div className="p-4 bg-gray-100 dark:bg-gray-800 rounded-lg text-gray-600 dark:text-gray-400">
          No visual editor available for {gameType}. Use JSON mode.
        </div>
      )
  }
}
