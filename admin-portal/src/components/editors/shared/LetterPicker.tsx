interface LetterPickerProps {
  onSelect: (letter: string) => void
  selectedLetters?: string[]
  disabledLetters?: string[]
  maxSelections?: number
  className?: string
}

const ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('')

export default function LetterPicker({
  onSelect,
  selectedLetters = [],
  disabledLetters = [],
  maxSelections,
  className = '',
}: LetterPickerProps) {
  const isSelected = (letter: string) => selectedLetters.includes(letter)
  const isDisabled = (letter: string) => disabledLetters.includes(letter)
  const isMaxReached = maxSelections !== undefined && selectedLetters.length >= maxSelections

  const getButtonClasses = (letter: string) => {
    const selected = isSelected(letter)
    const disabled = isDisabled(letter) || (isMaxReached && !selected)

    const classes = [
      'w-10 h-10 flex items-center justify-center',
      'text-lg font-semibold rounded-md',
      'transition-all duration-150',
      'border',
    ]

    if (disabled) {
      classes.push(
        'bg-gray-100 dark:bg-gray-800',
        'text-gray-300 dark:text-gray-600',
        'border-gray-200 dark:border-gray-700',
        'cursor-not-allowed'
      )
    } else if (selected) {
      classes.push(
        'bg-blue-500 dark:bg-blue-600',
        'text-white',
        'border-blue-600 dark:border-blue-500',
        'cursor-pointer',
        'hover:bg-blue-600 dark:hover:bg-blue-500'
      )
    } else {
      classes.push(
        'bg-white dark:bg-gray-700',
        'text-gray-700 dark:text-gray-200',
        'border-gray-300 dark:border-gray-600',
        'cursor-pointer',
        'hover:bg-gray-100 dark:hover:bg-gray-600',
        'hover:border-blue-400 dark:hover:border-blue-500'
      )
    }

    return classes.join(' ')
  }

  return (
    <div className={className}>
      <div className="grid grid-cols-7 gap-1">
        {ALPHABET.map((letter) => (
          <button
            key={letter}
            type="button"
            className={getButtonClasses(letter)}
            onClick={() => {
              const disabled = isDisabled(letter) || (isMaxReached && !isSelected(letter))
              if (!disabled) {
                onSelect(letter)
              }
            }}
            disabled={isDisabled(letter)}
            aria-label={`Letter ${letter}${isSelected(letter) ? ' (selected)' : ''}`}
            aria-pressed={isSelected(letter)}
          >
            {letter}
          </button>
        ))}
      </div>
      {maxSelections !== undefined && (
        <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">
          {selectedLetters.length} / {maxSelections} letters selected
        </p>
      )}
    </div>
  )
}
