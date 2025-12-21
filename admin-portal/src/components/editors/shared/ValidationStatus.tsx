import { CheckCircle, XCircle, AlertTriangle, Loader2 } from 'lucide-react'
import clsx from 'clsx'

export interface ValidationError {
  row: number
  col: number
  message: string
}

interface ValidationStatusProps {
  isValidating?: boolean
  isValid?: boolean
  hasUniqueSolution?: boolean
  errors?: ValidationError[]
  className?: string
}

export default function ValidationStatus({
  isValidating,
  isValid,
  hasUniqueSolution,
  errors = [],
  className,
}: ValidationStatusProps) {
  if (isValidating) {
    return (
      <div className={clsx('flex items-center gap-2 text-gray-500', className)}>
        <Loader2 className="w-4 h-4 animate-spin" />
        <span>Validating puzzle...</span>
      </div>
    )
  }

  if (isValid === undefined) {
    return null
  }

  if (isValid && hasUniqueSolution) {
    return (
      <div className={clsx('flex items-center gap-2 text-green-600 dark:text-green-400', className)}>
        <CheckCircle className="w-4 h-4" />
        <span>Valid puzzle with unique solution</span>
      </div>
    )
  }

  if (isValid && !hasUniqueSolution) {
    return (
      <div className={clsx('flex items-center gap-2 text-yellow-600 dark:text-yellow-400', className)}>
        <AlertTriangle className="w-4 h-4" />
        <span>Valid puzzle but has multiple solutions</span>
      </div>
    )
  }

  return (
    <div className={clsx('space-y-2', className)}>
      <div className="flex items-center gap-2 text-red-600 dark:text-red-400">
        <XCircle className="w-4 h-4" />
        <span>Invalid puzzle</span>
      </div>
      {errors.length > 0 && (
        <ul className="text-sm text-red-600 dark:text-red-400 list-disc list-inside space-y-1">
          {errors.slice(0, 5).map((error, idx) => (
            <li key={idx}>
              {error.row >= 0 && error.col >= 0
                ? "[R" + (error.row + 1) + ", C" + (error.col + 1) + "] "
                : ""}
              {error.message}
            </li>
          ))}
          {errors.length > 5 && (
            <li className="text-gray-500">...and {errors.length - 5} more errors</li>
          )}
        </ul>
      )}
    </div>
  )
}
