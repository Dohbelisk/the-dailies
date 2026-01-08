# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

The Dailies is a multi-platform daily puzzle game featuring **13 puzzle types**: Sudoku, Killer Sudoku, Crossword, Word Search, Word Forge, Nonogram, Number Target, Ball Sort, Pipes, Lights Out, Word Ladder, Connections, and Mathora.

| Component | Location | Tech Stack |
|-----------|----------|------------|
| Mobile App | `flutter_app/` | Flutter (iOS, Android, Web) |
| Backend API | `backend/` | NestJS + MongoDB + JWT |
| Admin Portal | `admin-portal/` | React + Vite + TailwindCSS |

**Current Status:** ~99% complete - All core features implemented, TestFlight/Firebase deployment ready

---

## Git Workflow

- **Development branch:** `develop` (default for commits and PRs)
- **Production branch:** `main`
- Merges from `develop` to `main` trigger production deployments

---

## Quick Start

```bash
# Start all services (backend + admin portal)
npm install && npm run dev

# Or use shell scripts
./start-all.sh    # Start
./stop-all.sh     # Stop
```

**Services:**
- Backend API: `http://localhost:3000`
- Swagger docs: `http://localhost:3000/api/docs`
- Admin portal: `http://localhost:5173`

**Default admin:** `admin@dohbelisk.com` / `5nifrenypro`

---

## Development Commands

### Backend
```bash
cd backend
npm install
npm run start:dev          # Development
npm run seed               # Seed database
npm run seed:dictionary    # Seed word dictionary
npm run test               # Run tests
```

### Flutter App
```bash
cd flutter_app
flutter pub get
flutter run                # Run on device/emulator
flutter test               # Run tests
flutter analyze            # Analyze code
```

### Admin Portal
```bash
cd admin-portal
npm install
npm run dev                # Development
npm run build              # Production build
```

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
db.dropDatabase()              # Reset (then re-seed)
```

---

## Documentation

| Topic | Location |
|-------|----------|
| Backend architecture | `backend/CLAUDE.md` |
| Flutter app architecture | `flutter_app/CLAUDE.md` |
| Admin portal architecture | `admin-portal/CLAUDE.md` |
| Puzzle data formats | `.claude/docs/puzzle-formats.md` |
| Puzzle generators | `.claude/docs/puzzle-generators.md` |
| Deployment & CI/CD | `.claude/docs/deployment.md` |
| Monetization & IAP | `.claude/docs/monetization.md` |

---

## Game Vetting Status

| Game Type | Status | Notes |
|-----------|--------|-------|
| Sudoku, Killer Sudoku, Crossword | Ready | Fully tested |
| Word Forge, Nonogram, Number Target | Ready | Fully tested |
| Ball Sort, Pipes, Lights Out | Ready | Fully tested |
| Word Ladder, Connections, Mathora | Ready | Fully tested |
| Word Search | Inactive | Quality improvements needed |

---

## Remaining Tasks

### Critical (Before Production)
- [ ] Test IAP on physical devices (Apple/Google)
- [ ] Replace test ad IDs with production IDs
- [ ] Configure IAP products in Google Play Console

### High Priority (Post-Launch)
- [ ] Add leaderboard UI to admin portal
- [ ] Add user management to admin portal
- [ ] Add feature flag management UI to admin portal

### Medium Priority
- [ ] Implement push notification triggers (challenge received, daily reminder)
- [ ] Add analytics dashboard
- [ ] Seed initial feature flags

### Completed
- [x] Game vetting (12/13 ready)
- [x] iOS TestFlight CI/CD
- [x] Android Firebase App Distribution CI/CD
- [x] iOS subscription in App Store Connect
- [x] Google Sign-In authentication
- [x] Push notifications backend
- [x] Achievements system
