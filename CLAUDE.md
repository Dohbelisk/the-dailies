# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

The Dailies is a multi-platform daily puzzle game featuring **13 puzzle types**: Sudoku, Killer Sudoku, Crossword, Word Search, Word Forge, Nonogram, Number Target, Ball Sort, Pipes, Lights Out, Word Ladder, Connections, and Mathora. The project consists of three main components:

- **Flutter Mobile App** (`flutter_app/`) - Cross-platform mobile application (iOS, Android, Web)
- **NestJS Backend API** (`backend/`) - RESTful API with MongoDB and JWT authentication
- **React Admin Portal** (`admin-portal/`) - Web-based puzzle management dashboard

**Current Status:** ~97% complete - All core features implemented

---

## Git Workflow

- **Default branch for development:** `develop`
- **Production branch:** `main`
- All commits should be made to `develop` unless otherwise specified
- PRs should target `develop` by default
- Merges from `develop` to `main` trigger production deployments

---

## Quick Start - All Services

### Single Command Startup (Recommended)

**Option 1: Using npm (cross-platform):**
```bash
# First time setup
npm install

# Start everything
npm run dev
```

**Option 2: Using shell script (Mac/Linux):**
```bash
./start-all.sh
```

**Option 3: Using batch file (Windows):**
```bash
start-all.bat
```

**To stop all services:**
```bash
./stop-all.sh    # Mac/Linux
# or press Ctrl+C
```

### What Gets Started
- Backend API on `http://localhost:3000`
- Swagger docs on `http://localhost:3000/api/docs`
- Admin portal on `http://localhost:5173`
- Auto-installs dependencies if missing
- Creates `.env` if needed
- Shows live logs from all services

---

## Development Commands

### Backend (NestJS)
```bash
cd backend

# Install dependencies
npm install

# Environment setup
cp .env.example .env
# Edit .env with MongoDB URI and JWT secret

# Seed database (creates admin user + sample puzzles)
npm run seed

# Seed dictionary (~370k words for Word Forge)
npm run seed:dictionary

# Development
npm run start:dev

# Build & Production
npm run build
npm run start:prod

# Testing
npm run test
npm run test:watch
npm run test:cov

# Linting
npm run lint
```

**Default admin credentials:**
- Email: `admin@dohbelisk.com`
- Password: `5nifrenypro`

### Admin Portal (React + Vite)
```bash
cd admin-portal

npm install
npm run dev      # Development
npm run build    # Production build
npm run preview  # Preview production
npm run lint     # Linting
```

**Portal at:** `http://localhost:5173`

### Flutter App
```bash
cd flutter_app

flutter pub get           # Get dependencies
flutter run               # Run on device/emulator
flutter build apk         # Android
flutter build ios         # iOS
flutter build web         # Web
flutter test              # Run tests
flutter analyze           # Analyze code
```

**Note:** Update API URL in `lib/config/environment.dart` or `lib/services/api_service.dart` before running.

---

## Architecture

### Backend (NestJS)

**Module Structure:**
- `auth/` - JWT authentication with Passport (local & JWT strategies), admin role guard
- `users/` - User management with bcrypt password hashing, friend codes
- `puzzles/` - CRUD operations for puzzles with MongoDB indexes
- `scores/` - Score tracking, user statistics, streaks
- `friends/` - Friend system with requests and friend codes
- `challenges/` - Head-to-head multiplayer puzzle challenges
- `feedback/` - User feedback and bug reports
- `config/` - App configuration, feature flags, and version management
- `email/` - Email notifications (via Nodemailer)
- `seeds/` - Database seeding scripts
- `dictionary/` - Word dictionary for Word Forge validation (~370k words)
- `utils/` - Puzzle generators (Sudoku, Killer Sudoku, Crossword, Word Search, Word Forge, Nonogram, Number Target)

**Key Patterns:**
- All modules follow NestJS module/controller/service pattern
- MongoDB schemas use Mongoose with TypeScript decorators
- Swagger decorators on controllers for auto-generated API docs
- Guards: `JwtAuthGuard` for authentication, `AdminGuard` for admin-only routes
- Strategies: `LocalStrategy` for login, `JwtStrategy` for token validation
- JWT expiry: 7 days

**Database Schemas:**

```typescript
// User Schema
User {
  email: string (unique)
  password: string (hashed)
  username: string
  friendCode: string (unique, 8-char alphanumeric)
  role: 'user' | 'admin'
  isActive: boolean
}

// Puzzle Schema
Puzzle {
  gameType: 'sudoku' | 'killerSudoku' | 'crossword' | 'wordSearch' | 'wordForge' | 'nonogram' | 'numberTarget' | 'ballSort' | 'pipes' | 'lightsOut' | 'wordLadder' | 'connections'
  difficulty: 'easy' | 'medium' | 'hard' | 'expert'
  date: Date
  puzzleData: Object
  solution: Object
  targetTime: number (seconds)
  title?: string
  description?: string
  isActive: boolean
}

// Dictionary Schema (for Word Forge)
Dictionary {
  word: string (unique, indexed)
  length: number (indexed)
  letters: string[] (sorted unique letters, indexed)
}

// Score Schema
Score {
  puzzleId: ObjectId
  userId?: ObjectId
  deviceId?: string
  time: number
  score: number
  mistakes: number
  hintsUsed: number
  completed: boolean
}

// Friend & FriendRequest Schemas
Friend { userId, friendId, friendsSince }
FriendRequest { senderId, receiverId, status: 'pending' | 'accepted' | 'declined' }

// Challenge Schema
Challenge {
  challengerId, opponentId, puzzleId
  gameType, difficulty
  status: 'pending' | 'accepted' | 'declined' | 'completed' | 'expired' | 'cancelled'
  challengerScore/Time/Mistakes, challengerCompleted
  opponentScore/Time/Mistakes, opponentCompleted
  winnerId, expiresAt (24h), message?
}

// Feedback Schema
Feedback {
  type: 'bug_report' | 'new_game_suggestion' | 'puzzle_suggestion' | 'puzzle_mistake' | 'general'
  message, email?, status, adminNotes?
  puzzleId?, gameType?, difficulty?, puzzleDate?, deviceInfo?
}

// AppConfig Schema (singleton, configId='main')
AppConfig {
  configId: 'main'
  latestVersion: string     // Latest available app version
  minVersion: string        // Minimum required (force update below this)
  updateUrl: string         // App store URL
  updateMessage: string     // Optional update dialog message
  forceUpdateMessage: string // Force update dialog message
  maintenanceMode: boolean  // Block app access
  maintenanceMessage: string
}

// FeatureFlag Schema
FeatureFlag {
  key: string (unique)      // e.g., 'challenges_enabled', 'debug_menu_enabled'
  name: string              // Human-readable name
  description: string
  enabled: boolean          // Global state
  minAppVersion?: string    // Enable only for >= this version
  maxAppVersion?: string    // Enable only for <= this version
  enabledForUserIds: string[] // Beta user IDs
  rolloutPercentage: number // 0-100 for gradual rollouts
  expiresAt?: Date          // Auto-disable after this date
  metadata: object          // Additional config data
}
```

### Flutter App (Provider Pattern)

**State Management:**
- Provider for reactive state management
- `GameProvider` - Central game state for all puzzle types
- `ThemeProvider` - Dark mode and theme management (light/dark/system)
- `AuthService` - JWT token management with SharedPreferences

**Services:**

| Service | Purpose |
|---------|---------|
| `ApiService` | HTTP client, offline mock data fallback |
| `AuthService` | JWT auth, token persistence, user state |
| `GameService` | Puzzle fetching and parsing |
| `GameStateService` | Persistent game state (in-progress detection) |
| `FavoritesService` | Favorite games pinned to top of home screen |
| `ConfigService` | Feature flags, version checking, app config |
| `AdMobService` | Rewarded video ads (singleton) |
| `HintService` | 3 free hints/day + ad rewards |
| `TokenService` | Archive access tokens |
| `PurchaseService` | In-app purchases (premium subscription) |
| `AudioService` | Sound effects, music, haptics |
| `FriendsService` | Friend list, requests, search |
| `ChallengeService` | Multiplayer challenges |
| `ConsentService` | GDPR consent management |

**Screens:**

| Screen | Purpose |
|--------|---------|
| `HomeScreen` | Today's puzzles, navigation |
| `GameScreen` | Puzzle gameplay (all 4 types) |
| `ArchiveScreen` | Past puzzles with token access |
| `StatsScreen` | User statistics |
| `SettingsScreen` | Audio, theme, privacy, IAP |
| `DebugMenuScreen` | Hidden debug menu for feature flag overrides |
| `FriendsScreen` | Friend list, requests, search |
| `FriendProfileScreen` | Friend details, head-to-head stats |
| `ChallengesScreen` | Pending, active, completed challenges |
| `LoginScreen` / `RegisterScreen` | Authentication |
| `ThemeSelectionScreen` | First-launch theme picker |
| `TermsOfServiceScreen` / `PrivacyPolicyScreen` | Legal |

**Widgets:**
- `SudokuGrid`, `KillerSudokuGrid`, `CrosswordGrid`, `WordSearchGrid`, `WordForgeGrid`, `NonogramGrid`, `NumberTargetGrid`, `BallSortGrid`, `PipesGrid`, `LightsOutGrid`, `WordLadderGrid`, `ConnectionsGrid`, `MathoraGrid`
- `NumberPad`, `KeyboardInput`
- `GameTimer`, `PuzzleCard`, `TokenBalanceWidget`
- `CompletionDialog`, `FeedbackDialog`, `ConsentDialog`
- `ForceUpdateDialog`, `UpdateAvailableDialog`, `MaintenanceDialog`
- `AnimatedBackground`

**Game-Specific State in GameProvider:**
- Sudoku/Killer Sudoku: cell selection, notes mode (`Set<int>` per cell), grid validation
- Crossword: word-based selection (across/down), cursor auto-advances to next empty cell, auto-moves to next incomplete word on completion, clue list auto-scrolls to selected clue
- Word Search: drag selection with direction validation (straight lines/diagonals only)
- Word Forge: 7-letter honeycomb, center letter required in all words, 4+ letter words only, pangram bonuses
- Nonogram: fill/mark mode toggle, row/column clue validation
- Number Target: expression builder with +, -, ×, ÷ operations
- Ball Sort: tube selection, ball movement validation
- Pipes: endpoint connections, pipe rotation
- Lights Out: toggle grid cells and neighbors
- Word Ladder: single letter changes between words
- Connections: group 16 words into 4 categories
- Mathora: apply math operations to reach target number within move limit

**Scoring Algorithm:**
- Base score: 1000 points
- Time multiplier: bonus if under target, penalty if over
- Mistake penalty: -50 per error
- Hint penalty: -100 per hint
- Difficulty multiplier: 1x easy, 1.5x medium, 2x hard, 3x expert
- Final score clamped to 0-10000

### Admin Portal (React)

**Tech Stack:**
- React 18 + TypeScript + Vite
- TailwindCSS for styling
- React Router for navigation
- TanStack Query for server state
- Zustand for client state (auth persistence)
- React Hook Form + Zod for validation
- Axios for API calls
- Lucide React for icons

**Pages:**
- `Login.tsx` - Admin authentication
- `Dashboard.tsx` - Statistics overview, today's puzzles
- `PuzzleList.tsx` - Browse, filter (type, difficulty, status, date range), toggle, delete puzzles
- `PuzzleCreate.tsx` - Visual editor (Sudoku) or JSON editor with mode toggle
- `PuzzleEdit.tsx` - Edit existing puzzles with Visual/JSON toggle
- `PuzzleGenerate.tsx` - Auto-generate single puzzles or full week
- `FeedbackList.tsx` - View, filter, manage user feedback

**Visual Puzzle Editors** (`components/editors/`):
- `SudokuEditor.tsx` - Interactive 9x9 grid with validate/solve buttons
- `KillerSudokuEditor.tsx` - Cage drawing with color assignment
- `PuzzleEditorWrapper.tsx` - Switches editor by game type
- `shared/GridEditor.tsx` - Reusable 9x9 grid component
- `shared/NumberPad.tsx` - Number input buttons 1-9
- `shared/ValidationStatus.tsx` - Shows validation results

---

## API Endpoints

### Public Routes
```
GET  /api/puzzles/today                    # All puzzles for today
GET  /api/puzzles/type/:gameType           # Latest 30 puzzles of type
GET  /api/puzzles/type/:gameType/date/:date # Puzzle by type and date (YYYY-MM-DD)
GET  /api/puzzles/:id                      # Puzzle by ID
POST /api/scores                           # Submit score
GET  /api/scores/stats                     # User statistics
GET  /api/scores/puzzle/:puzzleId          # Top 100 scores for puzzle
GET  /api/scores/leaderboard/:puzzleId     # Leaderboard
POST /api/feedback                         # Submit feedback (no auth required)
```

### Auth Routes
```
POST /api/auth/login                       # Login (returns JWT)
POST /api/auth/register                    # Register new user
GET  /api/auth/me                          # Get current user (requires JWT)
```

### Friends Routes (require JWT)
```
GET  /api/friends                          # Get friend list
POST /api/friends/request                  # Send request by user ID
POST /api/friends/request/code             # Send request by friend code
POST /api/friends/request/username         # Send request by username
GET  /api/friends/requests/pending         # Pending requests received
GET  /api/friends/requests/sent            # Sent requests
POST /api/friends/requests/:id/accept      # Accept request
POST /api/friends/requests/:id/decline     # Decline request
DELETE /api/friends/:friendId              # Remove friend
GET  /api/friends/search?username=X        # Search users
```

### Challenges Routes (require JWT)
```
POST /api/challenges                       # Create challenge (must be friends)
GET  /api/challenges                       # Get challenges (filter by status)
GET  /api/challenges/pending               # Pending challenges received
GET  /api/challenges/active                # Active challenges
GET  /api/challenges/stats                 # Overall challenge stats
GET  /api/challenges/stats/:friendId       # Head-to-head stats with friend
GET  /api/challenges/:id                   # Challenge details
POST /api/challenges/:id/accept            # Accept challenge
POST /api/challenges/:id/decline           # Decline challenge
POST /api/challenges/:id/cancel            # Cancel (challenger only)
POST /api/challenges/submit                # Submit result
```

### Admin Routes (require JWT + admin role)
```
GET    /api/puzzles                        # List all with filters
POST   /api/puzzles                        # Create puzzle
PATCH  /api/puzzles/:id                    # Update puzzle
DELETE /api/puzzles/:id                    # Delete puzzle
POST   /api/puzzles/bulk                   # Bulk create
PATCH  /api/puzzles/:id/toggle-active      # Toggle active status
GET    /api/puzzles/admin/stats            # Puzzle statistics

POST   /api/generate/sudoku                # Generate Sudoku
POST   /api/generate/killer-sudoku         # Generate Killer Sudoku
POST   /api/generate/crossword             # Generate Crossword
POST   /api/generate/word-search           # Generate Word Search
POST   /api/generate/word-forge            # Generate Word Forge
POST   /api/generate/nonogram              # Generate Nonogram
POST   /api/generate/number-target         # Generate Number Target
POST   /api/generate/week                  # Generate full week

POST   /api/validate/sudoku                # Validate Sudoku puzzle
POST   /api/validate/sudoku/solve          # Solve Sudoku puzzle
POST   /api/validate/killer-sudoku         # Validate Killer Sudoku cages
POST   /api/validate/killer-sudoku/solve   # Solve Killer Sudoku puzzle

GET    /api/feedback                       # List feedback with filters
GET    /api/feedback/stats                 # Feedback statistics
GET    /api/feedback/:id                   # Feedback by ID
PATCH  /api/feedback/:id                   # Update status/notes
DELETE /api/feedback/:id                   # Delete feedback
```

### Config Routes
```
# Public
GET  /api/config                          # Get app config (versions, maintenance)
GET  /api/config/feature-flags?appVersion=X # Get feature flags for app version

# Admin (require JWT + admin role)
PUT   /api/config                          # Update app config
GET   /api/config/admin/flags              # List all feature flags
POST  /api/config/admin/flags              # Create feature flag
PATCH /api/config/admin/flags/:id          # Update feature flag
DELETE /api/config/admin/flags/:id         # Delete feature flag
```

### Dictionary Routes (for Word Forge)
```
GET  /api/dictionary/validate?word=X       # Check if word is valid
POST /api/dictionary/validate-many         # Check multiple words
POST /api/dictionary/validate-for-puzzle   # Check word is valid for puzzle letters
GET  /api/dictionary/count                 # Get total word count
GET  /api/dictionary/status                # Get dictionary status
```

---

## Puzzle Data Formats

### Sudoku
```json
{
  "grid": [[5,3,0,...], ...],     // 9x9, 0 = empty
  "solution": [[5,3,4,...], ...]  // 9x9, complete
}
```

### Killer Sudoku
```json
{
  "grid": [[0,0,0,...], ...],
  "solution": [[5,3,4,...], ...],
  "cages": [
    {"sum": 8, "cells": [[0,0], [0,1]]},
    {"sum": 15, "cells": [[0,2], [1,2], [2,2]]}
  ]
}
```

### Crossword
```json
{
  "rows": 10, "cols": 10,
  "grid": [["F","L","U",...], ...],  // Letters and "#" for black
  "clues": [{
    "number": 1,
    "direction": "across",
    "clue": "Google UI toolkit",
    "answer": "FLUTTER",
    "startRow": 0, "startCol": 0
  }]
}
```

### Word Search
```json
{
  "rows": 10, "cols": 10,
  "theme": "Programming",
  "grid": [["F","L","U",...], ...],  // Uppercase letters
  "words": [{
    "word": "FLUTTER",
    "startRow": 0, "startCol": 0,
    "endRow": 0, "endCol": 6
  }]
}
```

### Word Forge
```json
{
  "letters": ["A", "C", "E", "L", "N", "R", "T"],  // 7 unique letters
  "centerLetter": "A",                              // Must be in every word
  "validWords": ["CRANE", "LANCE", "ANTLER", ...],  // Validated against dictionary
  "pangrams": ["CENTRAL"]                           // Words using all 7 letters
}
```
*Note: Word validation uses the Dictionary module (~370k words). Run `npm run seed:dictionary` to populate.*

### Nonogram
```json
{
  "rows": 5, "cols": 5,
  "rowClues": [[1, 1], [5], [1, 1, 1], [5], [1, 1]],
  "colClues": [[1, 1], [5], [1, 1, 1], [5], [1, 1]],
  "solution": [[1,0,1,0,1], [1,1,1,1,1], ...]  // 1=filled, 0=empty
}
```

### Number Target
```json
{
  "numbers": [2, 5, 7, 3],           // 4 numbers to use
  "target": 24,                       // Target to reach
  "solutions": ["(7-5)*(3+2)*2", ...] // Valid expressions
}
```

### Ball Sort
```json
{
  "tubes": 6,                          // Total tubes
  "colors": 4,                         // Number of colors
  "tubeCapacity": 4,                   // Balls per tube
  "initialState": [                    // 2D array of color strings per tube
    ["red", "blue", "green", "yellow"],
    ["blue", "green", "red", "yellow"],
    // ... more tubes, last 2 typically empty
  ]
}
```

### Pipes
```json
{
  "rows": 5, "cols": 5,
  "endpoints": [                       // 2 endpoints per color
    { "color": "red", "row": 0, "col": 0 },
    { "color": "red", "row": 4, "col": 4 }
  ],
  "bridges": []                        // Optional bridge cells [row, col]
}
```

### Lights Out
```json
{
  "rows": 3, "cols": 3,
  "initialState": [                    // 2D boolean array (true=on)
    [true, false, true],
    [false, true, false],
    [true, false, true]
  ]
}
```

### Word Ladder
```json
{
  "startWord": "COLD",                 // Starting word
  "targetWord": "WARM",                // Target word (same length)
  "wordLength": 4
}
```

### Connections
```json
{
  "words": [                           // 16 shuffled words
    "APPLE", "DOG", "RED", "RUN", ...
  ],
  "categories": [                      // 4 categories of 4 words each
    { "name": "Fruits", "words": ["APPLE", "BANANA", "ORANGE", "GRAPE"], "difficulty": 1 },
    { "name": "Animals", "words": ["DOG", "CAT", "BIRD", "FISH"], "difficulty": 2 },
    { "name": "Colors", "words": ["RED", "BLUE", "GREEN", "YELLOW"], "difficulty": 3 },
    { "name": "Actions", "words": ["RUN", "WALK", "JUMP", "SWIM"], "difficulty": 4 }
  ]
}
```

### Mathora
```json
{
  "startNumber": 8,                    // Starting value
  "targetNumber": 200,                 // Target to reach
  "moves": 3,                          // Maximum moves allowed
  "operations": [                      // Grid of available operations
    { "type": "add", "value": 50, "display": "+50" },
    { "type": "multiply", "value": 10, "display": "×10" },
    { "type": "subtract", "value": 5, "display": "-5" },
    { "type": "divide", "value": 2, "display": "÷2" },
    ...
  ]
}
// Solution: array of operations that solve the puzzle
// Example: 8 × 10 = 80 → 80 + 100 = 180 → 180 + 20 = 200
```

---

## Monetization System

The app uses a **freemium model** with AdMob advertising, token-based archive access, and in-app purchase subscriptions.

### AdMob Integration
- Rewarded video ads for hints (watch video -> 3 hints)
- Rewarded video ads for tokens (watch video -> 5 tokens)
- Interstitial ads after puzzle completion (every 2-3 games)
- Premium users skip all ads automatically
- GDPR consent tracked via ConsentService

### Token System
- 1 free token per day (resets at midnight)
- Token costs: Easy (1), Medium (2), Hard/Expert (3)
- Watch rewarded ads for 5 tokens
- Premium users have unlimited archive access

### Hint System
- 3 free hints per day
- Watch rewarded ads for 3 more hints
- Premium users have unlimited hints

### In-App Purchases (PurchaseService)
- Premium subscription: non-consumable product
- Handles purchase lifecycle (pending, purchased, restored, error)
- Local backup storage for premium status
- Restore purchases functionality

### Revenue Model
**Free Tier:** Banner ads (~$0.50 CPM), Interstitial (~$3-5 CPM), Rewarded (~$10-15 CPM)
**Premium Tier ($4.99/month or $39.99/year):** Ad-free, unlimited hints, unlimited archive

### Configuration
- Android: `flutter_app/android/app/src/main/AndroidManifest.xml`
- iOS: `flutter_app/ios/Runner/Info.plist`
- Environment: `flutter_app/lib/config/environment.dart`

**Test Ad Units:** Must be replaced with production IDs before release. See `MONETIZATION.md` and `ADS_IMPLEMENTATION.md`.

---

## Social Features

### Friends System
- Unique 8-character friend codes per user (ambiguity-free: A-Z, 2-9)
- Add friends by code, username search, or user ID
- Friend requests with accept/decline flow
- Bidirectional friendship on accept
- View friend statistics

### Challenges
- Head-to-head puzzle competitions between friends
- Challenge creation with puzzle auto-selection
- 24-hour expiry on pending challenges
- Winner determination: score first, then time as tiebreaker
- Challenge statistics (wins, losses, ties, win rate)
- Prevents simultaneous active challenges between same users

### Feedback System
- In-app feedback form with types: bug report, game suggestion, puzzle suggestion, puzzle mistake, general
- Device info auto-collection
- Puzzle context linking (puzzleId, gameType, difficulty, date)
- Email notifications to admin on submission
- Admin portal for feedback management

---

## Feature Flags & Versioning

### Feature Flag System

**Server-Side (Backend):**
- Feature flags stored in MongoDB with `FeatureFlag` schema
- Version-based targeting: enable features only for specific app versions
- User-based targeting: enable for specific user IDs (beta testing)
- Rollout percentages: gradual rollout to X% of users
- Expiration dates: auto-disable features after a date

**Client-Side (Flutter):**
- `ConfigService` fetches flags on app startup
- Caches flags for offline support
- Local overrides via debug menu for testing
- Usage: `ConfigService().isFeatureEnabled('feature_key')`

**Example Feature Flags:**
- `debug_menu_enabled` - Controls access to hidden debug menu
- `challenges_enabled` - Enable/disable multiplayer challenges
- `new_puzzle_type` - Feature gate for new puzzle types

### Version Checking

**On App Startup:**
1. `ConfigService` fetches `AppConfig` from server
2. Compares current app version against `minVersion` and `latestVersion`
3. Shows appropriate dialog:
   - **Force Update**: If current < minVersion (non-dismissable, blocks app)
   - **Update Available**: If current < latestVersion (dismissable)
   - **Maintenance Mode**: If enabled (non-dismissable, blocks app)

**Version Status:**
```dart
enum VersionStatus {
  upToDate,        // current >= latest
  updateAvailable, // min <= current < latest
  forceUpdate,     // current < min
}
```

### Debug Menu

**Access:** Settings Screen → Tap version number 7 times (requires `debug_menu_enabled` flag)

**Features:**
- View current/latest/minimum versions
- View environment info (API URL, is production)
- View all feature flags with server values
- Override flags locally (force enable/disable/use server)
- Clear all overrides
- Trigger test dialogs (force update, update available)
- Copy debug info to clipboard
- Refresh config from server

**Location:** `flutter_app/lib/screens/debug_menu_screen.dart`

---

## Puzzle Generators

**SudokuGenerator:**
- Backtracking algorithm for valid 9x9 grids
- Cells removed based on difficulty: easy=30, medium=40, hard=50, expert=55

**KillerSudokuGenerator:**
- Extends Sudoku solver with cage generation
- Flood-fill algorithm for cages
- Cage sizes: easy 2-3, medium 2-4, hard 2-5, expert 2-6

**CrosswordGenerator:**
- Places words via letter intersections
- Auto-numbers clues left-to-right, top-to-bottom

**WordSearchGenerator:**
- Places words in 8 directions (including diagonals)
- Fills remaining cells with random A-Z

**WordForgeGenerator:**
- Selects 7 unique letters with good word coverage
- Designates center letter (must be in all valid words)
- Validates words against Dictionary module (~370k words)
- Identifies pangrams (words using all 7 letters)

**NonogramGenerator:**
- Generates random pixel art patterns
- Calculates row/column clues automatically
- Grid sizes: easy 5x5, medium 10x10, hard 12x12, expert 15x15

**NumberTargetGenerator:**
- Generates 4 random numbers and a target
- Verifies at least one valid solution exists
- Target ranges: easy 10, medium 24, hard 100, expert 50-500

**BallSortGenerator:**
- Creates tube puzzles with colored balls
- Ensures solvability with empty tubes

**PipesGenerator:**
- Places color endpoints on grid
- Validates paths don't cross

**LightsOutGenerator:**
- Creates solvable light toggle puzzles
- Random initial states

**WordLadderGenerator:**
- Selects start/target words of same length
- Validates path exists through dictionary

**ConnectionsGenerator:**
- Groups words into themed categories
- Assigns difficulty levels 1-4

**MathoraGenerator:**
- Generates starting number and target number
- Creates operations grid (+, -, ×, ÷) with difficulty-based move limits
- Guarantees solvable puzzles with known solution path
- Easy: 3 moves, Medium: 4 moves, Hard: 5 moves, Expert: 6 moves

**Target Times (seconds):**
| Difficulty | Sudoku | Killer | Crossword | Word Search | Word Forge | Nonogram | Number Target | Mathora |
|------------|--------|--------|-----------|-------------|------------|----------|---------------|---------|
| Easy       | 300    | 450    | 360       | 180         | 300        | 180      | 120           | 60      |
| Medium     | 600    | 900    | 600       | 300         | 600        | 360      | 180           | 90      |
| Hard       | 900    | 1200   | 900       | 420         | 900        | 600      | 300           | 120     |
| Expert     | 1200   | 1800   | 1200      | 600         | 1200       | 900      | 420           | 180     |

---

## Implementation Notes

### Backend
- MongoDB async config via ConfigService
- JWT secret from `JWT_SECRET` env var
- bcrypt salt rounds: 10
- Indexes on `{ gameType, date }`, `{ date }`, `{ gameType, isActive }`
- Seed script is idempotent (upsert pattern)
- Email failures non-blocking (won't fail API response)
- CORS origins from `CORS_ORIGINS` env var

### Flutter
- Grid coordinates: `[row][col]` (0 = top-left)
- ApiService falls back to mock data if backend unreachable
- SharedPreferences for local persistence
- Singleton pattern for AdMob, Hint, Token, Audio services
- ChangeNotifier pattern for reactive updates

### Admin Portal
- Auth state persisted to localStorage via Zustand
- TanStack Query invalidation on mutations
- Date picker sets time to 00:00:00 for backend matching
- Native `confirm()` for delete confirmations

---

## Common Workflows

### Adding a New Puzzle Type
1. Add enum to `backend/src/puzzles/schemas/puzzle.schema.ts`
2. Create generator in `backend/src/utils/puzzle-generators.ts`
3. Add endpoint in `backend/src/puzzles/generate.controller.ts`
4. Create Flutter model in `flutter_app/lib/models/game_models.dart`
5. Add state to `GameProvider`
6. Create grid widget in `flutter_app/lib/widgets/`
7. Update `PuzzleCard` and `GameScreen`
8. Add mock data to `ApiService`
9. Update admin portal forms

### Running Tests
```bash
cd backend && npm run test     # Backend unit tests
cd flutter_app && flutter test # Flutter tests
```

### Database Management
```bash
mongosh mongodb://localhost:27017/the-dailies

db.puzzles.find()              # View puzzles
db.users.find()                # View users
db.challenges.find()           # View challenges
db.feedback.find()             # View feedback
db.dropDatabase()              # Reset (then re-seed)
```

---

## Deployment

### GitHub Actions

Automated CI/CD pipelines in `.github/workflows/`:

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci.yml` | PRs to develop/main, push to develop | Runs tests for backend, admin portal, and Flutter |
| `deploy-api.yml` | Push to main (backend changes) | Deploys API to Render |
| `deploy-admin.yml` | Push to main (admin-portal changes) | Deploys Admin Portal to Render |

**Required GitHub Secrets:**
- `RENDER_DEPLOY_HOOK_URL` - Render deploy hook URL for the API service
- `RENDER_ADMIN_DEPLOY_HOOK_URL` - Render deploy hook URL for the Admin Portal

**Required GitHub Variables:**
- `API_URL` - Production API URL (for environment display)
- `ADMIN_URL` - Production Admin Portal URL (for environment display)
- `VITE_API_URL` - API URL for admin portal build

**Setting up Render Deploy Hooks:**
1. Go to your Render service dashboard
2. Navigate to Settings → Deploy Hook
3. Copy the hook URL
4. Add it as a secret in GitHub: Settings → Secrets and variables → Actions

### Docker
```bash
docker-compose up -d
```
Containers: MongoDB 7, NestJS API, React Admin

### Render.com
Configuration in `render.yaml`:
- Backend: Node runtime, health check at `/api/puzzles/today`
- Admin: Static site with SPA rewrite

### Environment Variables
**Backend:**
- `MONGODB_URI` - MongoDB connection string
- `JWT_SECRET` - JWT signing secret
- `CORS_ORIGINS` - Allowed origins (comma-separated)
- `FEEDBACK_EMAIL` - Email for feedback notifications
- `PORT` - Server port (default: 3000)

**Admin Portal:**
- `VITE_API_URL` - Backend API URL

---

## Documentation Files
- `README.md` - Project overview
- `STARTUP.md` - Detailed startup guide
- `PROJECT_STATUS.md` - Feature completion status
- `MONETIZATION.md` - Revenue strategy
- `ADS_IMPLEMENTATION.md` - AdMob technical guide
- `ARCHIVE_SYSTEM.md` - Token system guide

---

## Remaining Tasks

1. [ ] Test IAP on physical devices
2. [ ] Replace test ad IDs with production IDs
3. [ ] Add leaderboard UI to admin portal
4. [ ] Add user management to admin portal
5. [ ] Implement push notifications for challenges
6. [ ] Add analytics dashboard
7. [ ] Performance testing with large datasets
8. [ ] Add feature flag management UI to admin portal
9. [ ] Add app config management UI to admin portal
10. [ ] Seed initial feature flags (debug_menu_enabled, etc.)
11. [ ] Add visual editors for remaining puzzle types (Killer Sudoku, Crossword, etc.)
