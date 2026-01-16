import { SudokuEditor } from './SudokuEditor'
import KillerSudokuEditor from './KillerSudokuEditor'
import LightsOutEditor from './LightsOutEditor'
import ConnectionsEditor from './ConnectionsEditor'
import WordLadderEditor from './WordLadderEditor'
import NumberTargetEditor from './NumberTargetEditor'
import WordForgeEditor from './WordForgeEditor'
import CrosswordEditor from './CrosswordEditor'
import WordSearchEditor from './WordSearchEditor'
import NonogramEditor from './NonogramEditor'
import BallSortEditor from './BallSortEditor'
import PipesEditor from './PipesEditor'
import MathoraEditor from './MathoraEditor'

interface PuzzleEditorWrapperProps {
  gameType: string
  puzzleData?: Record<string, unknown>
  solution?: Record<string, unknown>
  onChange?: (puzzleData: unknown, solution: unknown, isValid?: boolean) => void
  className?: string
}

export default function PuzzleEditorWrapper({
  gameType,
  puzzleData,
  solution,
  onChange,
  className,
}: PuzzleEditorWrapperProps) {
  const handleSudokuChange = (grid: number[][], sol: number[][], isValid?: boolean) => {
    onChange?.({ grid }, { grid: sol }, isValid)
  }

  const handleKillerSudokuChange = (data: { grid: number[][]; solution: number[][]; cages: unknown; isValid?: boolean }) => {
    onChange?.({ cages: data.cages, grid: data.grid }, { grid: data.solution }, data.isValid)
  }

  const handleGenericChange = (data: unknown, sol: unknown, isValid?: boolean) => {
    onChange?.(data, sol, isValid)
  }

  switch (gameType) {
    case 'sudoku':
      return (
        <SudokuEditor
          initialGrid={puzzleData?.grid as number[][] | undefined}
          initialSolution={solution?.grid as number[][] | undefined}
          onChange={handleSudokuChange}
          className={className}
        />
      )

    case 'killerSudoku':
      return (
        <KillerSudokuEditor
          initialGrid={puzzleData?.grid as number[][] | undefined}
          initialCages={puzzleData?.cages as any}
          initialSolution={solution?.grid as number[][] | undefined}
          onChange={handleKillerSudokuChange}
        />
      )

    case 'lightsOut':
      return (
        <LightsOutEditor
          initialData={puzzleData as any}
          initialSolution={solution as any}
          onChange={handleGenericChange}
          className={className}
        />
      )

    case 'connections':
      return (
        <ConnectionsEditor
          initialData={puzzleData as any}
          onChange={handleGenericChange}
          className={className}
        />
      )

    case 'wordLadder':
      return (
        <WordLadderEditor
          initialData={puzzleData as any}
          initialSolution={solution as any}
          onChange={handleGenericChange}
          className={className}
        />
      )

    case 'numberTarget':
      return (
        <NumberTargetEditor
          initialData={puzzleData as any}
          initialSolution={solution as any}
          onChange={handleGenericChange}
          className={className}
        />
      )

    case 'wordForge':
      return (
        <WordForgeEditor
          initialData={puzzleData as any}
          initialSolution={solution as any}
          onChange={handleGenericChange}
          className={className}
        />
      )

    case 'crossword':
      return (
        <CrosswordEditor
          initialData={puzzleData as any}
          onChange={handleGenericChange}
          className={className}
        />
      )

    case 'wordSearch':
      return (
        <WordSearchEditor
          initialData={puzzleData as any}
          onChange={handleGenericChange}
          className={className}
        />
      )

    case 'nonogram':
      return (
        <NonogramEditor
          initialData={puzzleData as any}
          initialSolution={solution as any}
          onChange={handleGenericChange}
          className={className}
        />
      )

    case 'ballSort':
      return (
        <BallSortEditor
          initialData={puzzleData as any}
          initialSolution={solution as any}
          onChange={handleGenericChange}
          className={className}
        />
      )

    case 'pipes':
      return (
        <PipesEditor
          initialData={puzzleData as any}
          initialSolution={solution as any}
          onChange={handleGenericChange}
          className={className}
        />
      )

    case 'mathora':
      return (
        <MathoraEditor
          initialData={puzzleData as any}
          initialSolution={solution as any}
          onChange={handleGenericChange}
          className={className}
        />
      )

    default:
      return (
        <div className="p-4 bg-gray-100 dark:bg-gray-800 rounded-lg text-gray-600 dark:text-gray-400">
          No visual editor available for {gameType}. Use JSON mode.
        </div>
      )
  }
}
