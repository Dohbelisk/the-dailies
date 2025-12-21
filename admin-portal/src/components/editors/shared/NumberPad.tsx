import clsx from 'clsx'

interface NumberPadProps {
  onNumberClick: (num: number) => void
  onClear: () => void
  disabled?: boolean
  className?: string
}

export default function NumberPad({
  onNumberClick,
  onClear,
  disabled = false,
  className,
}: NumberPadProps) {
  return (
    <div className={clsx('grid grid-cols-5 gap-2', className)}>
      {[1, 2, 3, 4, 5, 6, 7, 8, 9].map((num) => (
        <button
          key={num}
          type="button"
          onClick={() => onNumberClick(num)}
          disabled={disabled}
          className={clsx(
            'w-12 h-12 flex items-center justify-center text-lg font-medium rounded-lg',
            'bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600',
            'transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500',
            disabled && 'opacity-50 cursor-not-allowed'
          )}
        >
          {num}
        </button>
      ))}
      <button
        type="button"
        onClick={onClear}
        disabled={disabled}
        className={clsx(
          'w-12 h-12 flex items-center justify-center text-sm font-medium rounded-lg',
          'bg-red-100 dark:bg-red-900/30 text-red-600 dark:text-red-400',
          'hover:bg-red-200 dark:hover:bg-red-900/50',
          'transition-colors focus:outline-none focus:ring-2 focus:ring-red-500',
          disabled && 'opacity-50 cursor-not-allowed'
        )}
      >
        Clear
      </button>
    </div>
  )
}
