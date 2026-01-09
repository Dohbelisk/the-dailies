# Admin Portal CLAUDE.md

React-based web dashboard for puzzle management.

## Tech Stack

- React 18 + TypeScript + Vite
- TailwindCSS for styling
- React Router for navigation
- TanStack Query for server state
- Zustand for client state (auth persistence)
- React Hook Form + Zod for validation
- Axios for API calls
- Lucide React for icons

## Pages

| Page | Purpose |
|------|---------|
| `Login.tsx` | Admin authentication |
| `Dashboard.tsx` | Statistics overview, today's puzzles |
| `PuzzleList.tsx` | Browse, filter (type, difficulty, status, date range), toggle, delete puzzles |
| `PuzzleCreate.tsx` | Visual editor (Sudoku) or JSON editor with mode toggle |
| `PuzzleEdit.tsx` | Edit existing puzzles with Visual/JSON toggle |
| `PuzzleGenerate.tsx` | Auto-generate single puzzles or full week |
| `FeedbackList.tsx` | View, filter, manage user feedback |

## Visual Puzzle Editors

Located in `components/editors/`:

| Editor | Purpose |
|--------|---------|
| `SudokuEditor.tsx` | Interactive 9x9 grid with validate/solve buttons |
| `KillerSudokuEditor.tsx` | Cage drawing with color assignment |
| `PuzzleEditorWrapper.tsx` | Switches editor by game type |

**Shared Components** (`components/editors/shared/`):
- `GridEditor.tsx` - Reusable 9x9 grid component
- `NumberPad.tsx` - Number input buttons 1-9
- `ValidationStatus.tsx` - Shows validation results

## Implementation Notes

- Auth state persisted to localStorage via Zustand
- TanStack Query invalidation on mutations
- Date picker sets time to 00:00:00 for backend matching
- Native `confirm()` for delete confirmations
- Puzzle generation modal includes "Remove existing puzzles" option

## Environment Variables

```
VITE_API_URL    # Backend API URL
```
