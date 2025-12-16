# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

The Dailies is a multi-platform daily puzzle game featuring Sudoku, Killer Sudoku, Crossword, and Word Search puzzles. The project consists of three main components:

- **Flutter Mobile App** (`flutter_app/`) - Cross-platform mobile application
- **NestJS Backend API** (`backend/`) - RESTful API with MongoDB and JWT authentication
- **React Admin Portal** (`admin-portal/`) - Web-based puzzle management dashboard

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
- ✅ Backend API on `http://localhost:3000`
- ✅ Swagger docs on `http://localhost:3000/api/docs`
- ✅ Admin portal on `http://localhost:5173`
- ✅ Auto-installs dependencies if missing
- ✅ Creates `.env` if needed
- ✅ Shows live logs from all services

---

## Monetization System

The app uses a **freemium model** with AdMob advertising, token-based archive access, and in-app purchase subscriptions.

### Ad Implementation (✅ Complete)

**AdMob Service** (`flutter_app/lib/services/admob_service.dart`):
- Banner ads on home screen (bottom placement)
- Interstitial ads after puzzle completion (every 2-3 games)
- Rewarded video ads for hints (watch video → get 3 hints)
- Rewarded video ads for tokens (watch video → get 5 tokens)
- Premium user detection (automatically skips all ads)

**Hint Service** (`flutter_app/lib/services/hint_service.dart`):
- 3 free hints per day for free users
- Watch rewarded video ads for 3 more hints
- Daily reset at midnight
- Unlimited hints for premium users

**Configuration Files:**
- Android: `flutter_app/android/app/src/main/AndroidManifest.xml`
- iOS: `flutter_app/ios/Runner/Info.plist`

**Test Ad Units** (currently active):
- ⚠️ Must be replaced with production IDs before release
- See `MONETIZATION.md` and `ADS_IMPLEMENTATION.md` for details

### Archive & Token System (✅ Complete)

**Token Service** (`flutter_app/lib/services/token_service.dart`):
- Token-based economy for archive puzzle access
- 1 free token per day (resets at midnight)
- Watch rewarded video ads to earn 5 tokens
- Token costs: Easy (1), Medium (2), Hard/Expert (3)
- Premium users bypass token requirements entirely

**Archive Screen** (`flutter_app/lib/screens/archive_screen.dart`):
- Browse and play puzzles from previous days
- Date navigation (swipe through past dates)
- Locked puzzle UI for insufficient tokens
- "Get Tokens" dialog with multiple options
- Token balance display

**Token Balance Widget** (`flutter_app/lib/widgets/token_balance_widget.dart`):
- Displays current token count for free users
- Shows "Premium" badge for premium users
- Tappable to navigate to archive

**User Flow:**
1. Free users can only play today's puzzles for free
2. Archive puzzles cost tokens (1-3 based on difficulty)
3. Watch ads to earn tokens or go premium for unlimited access

### Revenue Model

**Free Tier (Ad-Supported):**
- Banner ads (~$0.50 CPM)
- Interstitial ads (~$3-5 CPM)
- Rewarded ads for hints (~$10-15 CPM)
- Rewarded ads for tokens (~$10-15 CPM)
- Expected: $0.50 - $3.00 per user per month

**Premium Tier ($4.99/month or $39.99/year):**
- Ad-free experience
- Unlimited hints
- Unlimited archive access (no tokens needed)
- Advanced statistics (planned)
- Custom themes (planned)

### Documentation

- `MONETIZATION.md` - Comprehensive monetization strategy
- `ADS_IMPLEMENTATION.md` - Technical implementation guide for AdMob
- `ARCHIVE_SYSTEM.md` - Archive and token system guide
- Production checklist included in all documents

### Next Steps for Monetization

1. [ ] Test archive and token system on device
2. [ ] Implement SubscriptionService for in-app purchases
3. [ ] Add backend subscription endpoints
4. [ ] Build revenue analytics dashboard (include token metrics)
5. [ ] Replace test ad IDs with production IDs
6. [ ] Optional: Add token purchase IAPs
7. [ ] Add privacy policy and GDPR compliance

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

# Development
npm run start:dev

# Build
npm run build

# Production
npm run start:prod

# Testing
npm run test
npm run test:watch
npm run test:cov

# Linting
npm run lint
```

**Default admin credentials:**
- Email: `admin@thedailies.app`
- Password: `admin123`

**API will be at:** `http://localhost:3000`
**Swagger docs at:** `http://localhost:3000/api/docs`

### Admin Portal (React + Vite)
```bash
cd admin-portal

# Install dependencies
npm install

# Development
npm run dev

# Build
npm run build

# Preview production build
npm run preview

# Linting
npm run lint
```

**Portal will be at:** `http://localhost:5173`

### Flutter App
```bash
cd flutter_app

# Get dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Build for specific platform
flutter build apk        # Android
flutter build ios        # iOS
flutter build web        # Web

# Run tests
flutter test

# Analyze code
flutter analyze
```

**Important:** Update `lib/services/api_service.dart` line 7 with your backend URL before running:
```dart
static const String baseUrl = 'http://YOUR_SERVER_IP:3000/api';
```

## Architecture

### Backend (NestJS)

**Module Structure:**
- `auth/` - JWT authentication with Passport (local & JWT strategies), admin role guard
- `users/` - User management with bcrypt password hashing
- `puzzles/` - CRUD operations for puzzles with MongoDB indexes on `gameType`, `date`, `isActive`
- `scores/` - Score tracking and user statistics
- `seeds/` - Database seeding script
- `utils/` - Puzzle generation utilities (SudokuGenerator, KillerSudokuGenerator, CrosswordGenerator, WordSearchGenerator)

**Key Patterns:**
- All modules follow NestJS module/controller/service pattern
- MongoDB schemas use Mongoose with TypeScript decorators
- Swagger decorators on controllers for auto-generated API docs
- Guards: `JwtAuthGuard` for authentication, `AdminGuard` for admin-only routes
- Strategies: `LocalStrategy` for login, `JwtStrategy` for token validation

**Puzzle Schema:**
The `Puzzle` model stores all game types with a flexible `puzzleData` field:
- `gameType`: enum - sudoku, killerSudoku, crossword, wordSearch
- `difficulty`: enum - easy, medium, hard, expert
- `date`: Date - puzzle scheduled date
- `puzzleData`: Object - game-specific data (grid, clues, cages, etc.)
- `solution`: Object - solution data
- `targetTime`: number - expected completion time in seconds
- `isActive`: boolean - whether puzzle is published

### Flutter App (Provider Pattern)

**State Management:**
- Uses Provider for state management
- `GameProvider` (`lib/providers/game_provider.dart`) - Central game state for all puzzle types
- `ThemeProvider` (`lib/providers/theme_provider.dart`) - Dark mode and theme management

**Services:**
- `ApiService` - HTTP client for backend communication, includes offline mock data fallback
- `GameService` - Game logic and validation
- `AudioService` - Sound effects management

**Game-Specific State in GameProvider:**
- Sudoku/Killer Sudoku: cell selection, notes mode, grid validation
- Crossword: clue selection, letter entry with auto-advance
- Word Search: drag selection with direction validation (straight lines/diagonals only)

**Scoring Algorithm** (in `GameProvider.calculateScore()`):
- Base score: 1000 points
- Time multiplier: bonus if under target, penalty if over
- Mistake penalty: -50 per error
- Hint penalty: -100 per hint
- Difficulty multiplier: 1x easy, 1.5x medium, 2x hard, 3x expert
- Final score clamped to 0-10000

### Admin Portal (React)

**Tech Stack:**
- React 18 with TypeScript
- Vite for build tooling
- TailwindCSS for styling
- React Router for navigation
- TanStack Query for server state
- Zustand for client state (`authStore`)
- React Hook Form + Zod for form validation
- Axios for API calls

**Pages:**
- `Login.tsx` - Authentication
- `Dashboard.tsx` - Overview statistics
- `PuzzleList.tsx` - Browse all puzzles
- `PuzzleCreate.tsx` - Manual puzzle creation
- `PuzzleEdit.tsx` - Edit existing puzzles
- `PuzzleGenerate.tsx` - Auto-generate puzzles using backend utilities

## Puzzle Data Formats

### Sudoku
```json
{
  "grid": [[5,3,0,...], ...],  // 9x9 array, 0 = empty
  "solution": [[5,3,4,...], ...]  // 9x9 array, complete solution
}
```

### Killer Sudoku
```json
{
  "grid": [[0,0,0,...], ...],  // All zeros initially
  "solution": [[5,3,4,...], ...],
  "cages": [
    {"sum": 8, "cells": [[0,0], [0,1]]},  // [row, col] pairs
    {"sum": 15, "cells": [[0,2], [1,2], [2,2]]}
  ]
}
```

### Crossword
```json
{
  "rows": 10,
  "cols": 10,
  "grid": [["F","L","U",...], ...],  // Letters and "#" for black cells
  "clues": [
    {
      "number": 1,
      "direction": "across",  // or "down"
      "clue": "Google UI toolkit",
      "answer": "FLUTTER",
      "startRow": 0,
      "startCol": 0
    }
  ]
}
```

### Word Search
```json
{
  "rows": 10,
  "cols": 10,
  "theme": "Programming",
  "grid": [["F","L","U",...], ...],  // All uppercase letters
  "words": [
    {
      "word": "FLUTTER",
      "startRow": 0,
      "startCol": 0,
      "endRow": 0,
      "endCol": 6
    }
  ]
}
```

## API Endpoints

### Public Routes
- `GET /api/puzzles/today` - Get all puzzles for today
- `GET /api/puzzles/type/:gameType` - Get puzzles by type (sudoku, killerSudoku, crossword, wordSearch)
- `GET /api/puzzles/type/:gameType/date/:date` - Get specific puzzle by type and date (YYYY-MM-DD)
- `POST /api/scores` - Submit a score
- `GET /api/scores/stats` - Get user statistics

### Admin Routes (require JWT + admin role)
- `GET /api/puzzles` - List all puzzles with pagination
- `POST /api/puzzles` - Create new puzzle
- `PATCH /api/puzzles/:id` - Update puzzle
- `DELETE /api/puzzles/:id` - Delete puzzle
- `POST /api/puzzles/bulk` - Bulk create puzzles

### Auth Routes
- `POST /api/auth/login` - Login (returns JWT)
- `POST /api/auth/register` - Register new user
- `GET /api/auth/me` - Get current user (requires JWT)

### Puzzle Generation Routes (admin only)
- `POST /api/generate/sudoku` - Generate Sudoku puzzle
- `POST /api/generate/killer-sudoku` - Generate Killer Sudoku puzzle with cages
- `POST /api/generate/crossword` - Generate Crossword puzzle from word/clue pairs
- `POST /api/generate/word-search` - Generate Word Search puzzle
- `POST /api/generate/week` - Generate a full week of puzzles (all types supported)

## Important Implementation Notes

### Backend
- MongoDB connection uses async configuration with ConfigService
- JWT secrets must be set in `.env` - never commit real secrets
- Password hashing uses bcrypt with salt rounds of 10
- Puzzle indexes optimize queries by `gameType`, `date`, and `isActive` combination
- The seed script uses `findOneAndUpdate` with `upsert: true` to be idempotent

**Puzzle Generators:**
- **SudokuGenerator** - Backtracking algorithm to generate valid 9x9 grids, removes cells based on difficulty
- **KillerSudokuGenerator** - Reuses Sudoku solver, then creates cages using flood-fill algorithm (cage size varies by difficulty)
- **CrosswordGenerator** - Places words by finding intersections at matching letters, assigns clue numbers left-to-right, top-to-bottom
- **WordSearchGenerator** - Places words in 8 directions (including diagonals), fills remaining cells with random letters
- All generators are tested in `utils/test-generators.ts` - run with `npx ts-node src/utils/test-generators.ts`

### Flutter
- `GameProvider` manages state for ALL game types - check current `gameType` before accessing game-specific state
- Grid coordinates are `[row][col]` - row is vertical (0 = top), col is horizontal (0 = left)
- Sudoku notes are stored as `Set<int>` per cell in a 9x9 array
- Word Search selection validates that drag path is straight line or diagonal only
- ApiService falls back to mock data if backend is unreachable - useful for offline development
- All puzzle grids use 0-based indexing

### Admin Portal
- Authentication state persisted in Zustand store with localStorage
- Puzzle JSON must be valid - use React Hook Form with Zod validation before submission
- Date picker should set time to 00:00:00 to match backend date comparison logic
- TanStack Query handles caching and refetching - invalidate queries after mutations

## Common Workflows

### Adding a New Puzzle Type
1. Add enum value to `GameType` in `backend/src/puzzles/schemas/puzzle.schema.ts`
2. Create Flutter model class in `flutter_app/lib/models/game_models.dart`
3. Add game-specific state to `GameProvider`
4. Create grid widget in `flutter_app/lib/widgets/`
5. Update `PuzzleCard` to handle new type
6. Add mock data to `ApiService._getMockPuzzles()`
7. Update admin portal puzzle creation form

### Running Tests
```bash
# Backend unit tests
cd backend && npm run test

# Flutter tests
cd flutter_app && flutter test
```

### Database Management
```bash
# Connect to MongoDB
mongosh mongodb://localhost:27017/the-dailies

# View all puzzles
db.puzzles.find()

# View users
db.users.find()

# Reset database
db.dropDatabase()
cd backend && npm run seed
```
