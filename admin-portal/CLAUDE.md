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
| `PuzzleCreate.tsx` | Visual editor or JSON editor with mode toggle |
| `PuzzleEdit.tsx` | Edit existing puzzles with Visual/JSON toggle |
| `PuzzleGenerate.tsx` | Auto-generate single puzzles or full week |
| `FeedbackList.tsx` | View, filter, manage user feedback |
| `DictionaryPage.tsx` | Browse and manage word dictionary |
| `SchedulePage.tsx` | Calendar view of puzzle schedule |

## Layout & Sidebar

`components/Layout.tsx` - Main layout with collapsible sidebar:
- Standard nav: Dashboard, Schedule, Puzzles, Generate, Feedback, Dictionary
- **Today/Tomorrow sections**: Collapsible parent items that lazy-load puzzles for that date via `puzzlesApi.getByDateRange()`, with direct edit links per puzzle

## Visual Puzzle Editors

Located in `components/editors/`:

| Editor | Features |
|--------|----------|
| `SudokuEditor.tsx` | Interactive 9x9 grid with validate/solve buttons |
| `KillerSudokuEditor.tsx` | Cage drawing with color assignment |
| `CrosswordEditor.tsx` | Grid with clue management |
| `WordSearchEditor.tsx` | Grid sizes 5-15, 8-direction word placement, theme input |
| `WordForgeEditor.tsx` | Letter picker, AI clue generation, dictionary bulk save (auto-adds unknown words) |
| `NonogramEditor.tsx` | Row/column clue editor with grid preview |
| `NumberTargetEditor.tsx` | Number and target input with multi-tier targets |
| `BallSortEditor.tsx` | Tube color placement |
| `PipesEditor.tsx` | Endpoint placement (20 colors, grid 5-12) + **interactive test play mode** |
| `LightsOutEditor.tsx` | Toggle grid editor |
| `WordLadderEditor.tsx` | Start/target word with path validation |
| `ConnectionsEditor.tsx` | Category/word group editor |
| `MathoraEditor.tsx` | Operation pool editor |
| `PuzzleEditorWrapper.tsx` | Switches editor by game type |

### Pipes Test Play Mode
The Pipes editor includes a "Test Play" button that launches an interactive game:
- Click & drag from endpoints to draw colored paths
- Backtrack by dragging back, overwrite other paths by drawing through them
- Status bar shows connected pipes and grid fill progress
- "Show Solution" reveals stored solution paths
- Validates completion (all pipes connected + full grid coverage)

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
- Dictionary bulk clue save auto-upserts unknown words (adds word + length + letters)

## Environment Variables

```
VITE_API_URL    # Backend API URL
```
