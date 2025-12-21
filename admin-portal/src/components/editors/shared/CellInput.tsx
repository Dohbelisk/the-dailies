import clsx from 'clsx'

interface CellInputProps {
  value: number | null
  isSelected: boolean
  isHighlighted: boolean
  isInitial: boolean
  isError: boolean
  onClick: () => void
  className?: string
}

export default function CellInput({
  value,
  isSelected,
  isHighlighted,
  isInitial,
  isError,
  onClick,
  className,
}: CellInputProps) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={clsx(
        'w-full h-full flex items-center justify-center text-lg font-medium transition-colors focus:outline-none',
        isSelected && 'bg-blue-200 dark:bg-blue-800',
        isHighlighted && !isSelected && 'bg-blue-50 dark:bg-blue-900/30',
        isError && 'text-red-600 dark:text-red-400',
        isInitial && 'font-bold',
        !isSelected && !isHighlighted && 'hover:bg-gray-100 dark:hover:bg-gray-700',
        className
      )}
    >
      {value || ''}
    </button>
  )
}
