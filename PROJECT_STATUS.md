# The Dailies - Project Status

**Last Updated:** 2025-12-30
**Overall Completion:** ~99%

---

## Executive Summary

The Dailies is a freemium daily puzzle game with **13 game types** (Sudoku, Killer Sudoku, Crossword, Word Search, Word Forge, Nonogram, Number Target, Ball Sort, Pipes, Lights Out, Word Ladder, Connections, Mathora). The project consists of three components:

| Component | Status | Completion |
|-----------|--------|------------|
| Flutter App | Production Ready | 99% |
| NestJS Backend | Production Ready | 99% |
| React Admin Portal | Functional | 95% |

**What Works Now:**
- All 13 puzzle game types implemented (12 active, 1 inactive)
- **12 games fully device-tested and ready** (Word Search inactive for improvements)
- User authentication (login/register)
- Friends system (add, accept, remove)
- **Friend challenges (async)** - Challenge friends to same puzzle
- **Favorites system** - Pin favorite games to top of home screen
- **Game state persistence** - In-progress indicator on home screen
- Token-based archive access
- Hint system with daily limits
- Rewarded video ads for hints/tokens
- One-time premium purchase (IAP integration)
- Admin portal for puzzle management with **visual Sudoku editor**
- Puzzle auto-generation for all 13 types
- Puzzle validation endpoints (validate/solve)
- Advanced filtering (type, difficulty, status, date range)
- Statistics tracking
- GDPR consent and privacy policy
- Feature flags and version checking system
- Debug menu for development/testing
- Dictionary management for Word Forge (~370k words)

**What's Missing (Before Production):**
- Production ad unit IDs (currently using test IDs)
- Configure IAP product in App Store Connect / Google Play Console
- Test IAP on physical devices

**Post-Launch Enhancements:**
- Visual editors for remaining puzzle types (Killer Sudoku, Crossword, etc.)
- Admin portal: leaderboard UI, user management, feature flag UI
- Word Search quality improvements (currently inactive)
- Push notifications for challenges

---

## Component Details

### 1. Flutter App (`flutter_app/`)

#### Screens (12 total)
| Screen | File | Status | Notes |
|--------|------|--------|-------|
| Home | `screens/home_screen.dart` | Complete | Today's puzzles, navigation, GDPR check |
| Game | `screens/game_screen.dart` | Complete | All 4 game types + challenge mode |
| Archive | `screens/archive_screen.dart` | Complete | Token-based past puzzles |
| Stats | `screens/stats_screen.dart` | Complete | User statistics |
| Settings | `screens/settings_screen.dart` | Complete | Theme, sound, privacy settings |
| Login | `screens/auth/login_screen.dart` | Complete | Email/password auth |
| Register | `screens/auth/register_screen.dart` | Complete | User registration |
| Friends | `screens/friends/friends_screen.dart` | Complete | Friend management |
| Friend Profile | `screens/friends/friend_profile_screen.dart` | Complete | Friend details + send challenge |
| Challenges | `screens/challenges/challenges_screen.dart` | Complete | Pending/active/completed challenges |
| Privacy Policy | `screens/legal/privacy_policy_screen.dart` | Complete | GDPR-compliant privacy policy |
| Terms of Service | `screens/legal/terms_of_service_screen.dart` | Complete | App terms of service |

#### Services (13 total)
| Service | File | Status | Notes |
|---------|------|--------|-------|
| ApiService | `services/api_service.dart` | Complete | REST client + mock fallback, uses env config |
| AuthService | `services/auth_service.dart` | Complete | JWT token management |
| GameService | `services/game_service.dart` | Complete | Puzzle fetching wrapper |
| GameStateService | `services/game_state_service.dart` | Complete | Persistent game state, in-progress detection |
| FavoritesService | `services/favorites_service.dart` | Complete | Favorite games pinned to top |
| AdMobService | `services/admob_service.dart` | Complete | Rewarded ads, respects consent settings |
| HintService | `services/hint_service.dart` | Complete | 3 free/day + ads |
| TokenService | `services/token_service.dart` | Complete | Archive access economy |
| PurchaseService | `services/purchase_service.dart` | Complete | One-time premium IAP, uses env config |
| AudioService | `services/audio_service.dart` | Complete | Sound effects, music, haptics |
| FriendsService | `services/friends_service.dart` | Complete | Friend operations |
| ChallengeService | `services/challenge_service.dart` | Complete | Challenge CRUD + result submission |
| ConsentService | `services/consent_service.dart` | Complete | GDPR consent management |

#### Providers
| Provider | File | Status |
|----------|------|--------|
| GameProvider | `providers/game_provider.dart` | Complete |
| ThemeProvider | `providers/theme_provider.dart` | Complete |

#### Key Models
- `game_models.dart` - DailyPuzzle, SudokuPuzzle, KillerSudokuPuzzle, CrosswordPuzzle, WordSearchPuzzle
- `user_models.dart` - User, LoginResult, RegisterResult
- `friend_models.dart` - Friend, FriendRequest, FriendStats
- `challenge_models.dart` - Challenge, ChallengeStatus, ChallengeStats, CreateChallengeRequest

#### Widgets (19 total)
- SudokuGrid, KillerSudokuGrid, CrosswordGrid, WordSearchGrid, WordForgeGrid, NonogramGrid, NumberTargetGrid
- BallSortGrid, PipesGrid, LightsOutGrid, WordLadderGrid, ConnectionsGrid
- PuzzleCard, TokenBalanceWidget, CompletionDialog
- GameTimer, NumberPad, KeyboardInput, AnimatedBackground
- ConsentDialog (GDPR consent modal)

#### Dependencies (key ones)
```yaml
provider: ^6.1.1          # State management
http: ^1.1.0              # API calls
shared_preferences: ^2.2.2 # Local storage
google_mobile_ads: ^5.1.0  # AdMob
flutter_animate: ^4.3.0    # Animations
confetti: ^0.7.0          # Celebrations
audioplayers: ^5.2.1      # Sound (not used)
vibration: ^2.0.0         # Haptics (not used)
in_app_purchase: ^3.2.0   # IAP (not integrated)
```

---

### 2. Backend API (`backend/`)

#### Modules (6 total)
| Module | Status | Description |
|--------|--------|-------------|
| PuzzlesModule | Complete | CRUD + generation |
| ScoresModule | Complete | Score tracking |
| AuthModule | Complete | JWT authentication |
| UsersModule | Complete | User management |
| FriendsModule | Complete | Friend system |
| ChallengesModule | Complete | Async friend challenges |

#### API Endpoints

**Public Routes:**
```
GET  /api/puzzles/today              - Today's puzzles
GET  /api/puzzles/type/:gameType     - Puzzles by type
GET  /api/puzzles/type/:type/date/:date - Specific puzzle
GET  /api/puzzles/:id                - Puzzle by ID
POST /api/scores                     - Submit score
GET  /api/scores/stats               - User statistics
POST /api/auth/login                 - Login
POST /api/auth/register              - Register
GET  /api/auth/me                    - Current user (JWT)
```

**Friends Routes (JWT required):**
```
GET    /api/friends                  - Get friends list
POST   /api/friends/request          - Send request by ID
POST   /api/friends/request/code     - Send by friend code
POST   /api/friends/request/username - Send by username
GET    /api/friends/requests/pending - Pending requests
GET    /api/friends/requests/sent    - Sent requests
POST   /api/friends/requests/:id/accept  - Accept request
POST   /api/friends/requests/:id/decline - Decline request
DELETE /api/friends/:friendId        - Remove friend
GET    /api/friends/search?username= - Search users
```

**Challenges Routes (JWT required):**
```
POST   /api/challenges               - Create challenge
GET    /api/challenges               - Get all challenges (?status=)
GET    /api/challenges/pending       - Pending challenges (received)
GET    /api/challenges/active        - Active challenges (in progress)
GET    /api/challenges/stats         - Challenge statistics
GET    /api/challenges/stats/:friendId - Stats with specific friend
GET    /api/challenges/:id           - Get specific challenge
POST   /api/challenges/:id/accept    - Accept challenge
POST   /api/challenges/:id/decline   - Decline challenge
POST   /api/challenges/:id/cancel    - Cancel challenge (challenger only)
POST   /api/challenges/submit        - Submit challenge result
```

**Admin Routes (JWT + Admin role):**
```
GET    /api/puzzles                  - All puzzles (paginated)
POST   /api/puzzles                  - Create puzzle
POST   /api/puzzles/bulk             - Bulk create
PATCH  /api/puzzles/:id              - Update puzzle
DELETE /api/puzzles/:id              - Delete puzzle
GET    /api/puzzles/admin/stats      - Statistics
POST   /api/generate/sudoku          - Generate Sudoku
POST   /api/generate/killer-sudoku   - Generate Killer Sudoku
POST   /api/generate/crossword       - Generate Crossword
POST   /api/generate/word-search     - Generate Word Search
POST   /api/generate/week            - Generate full week
```

#### Database Schemas
- `User` - email, password (bcrypt), username, role, friendCode
- `Puzzle` - gameType, difficulty, date, puzzleData, solution, targetTime, isActive
- `Score` - userId, puzzleId, score, time, mistakes, hintsUsed
- `Friend` - user1, user2, createdAt
- `FriendRequest` - sender, receiver, status, createdAt
- `Challenge` - challengerId, opponentId, puzzleId, gameType, difficulty, status, scores, winner, expiresAt

#### Puzzle Generators (`utils/puzzle-generators.ts`)
- `generateSudoku(difficulty)` - Backtracking algorithm
- `generateKillerSudoku(difficulty)` - Sudoku + cage generation
- `generateCrossword(wordsWithClues, rows, cols)` - Word placement with intersections
- `generateWordSearch(words, rows, cols, theme)` - 8-direction placement

---

### 3. Admin Portal (`admin-portal/`)

#### Pages (6 total)
| Page | File | Status | Description |
|------|------|--------|-------------|
| Login | `pages/Login.tsx` | Complete | Admin authentication |
| Dashboard | `pages/Dashboard.tsx` | Complete | Statistics overview |
| PuzzleList | `pages/PuzzleList.tsx` | Complete | Browse/filter (type, difficulty, status, date range) |
| PuzzleCreate | `pages/PuzzleCreate.tsx` | Complete | Visual/JSON editor toggle |
| PuzzleEdit | `pages/PuzzleEdit.tsx` | Complete | Visual/JSON editor toggle |
| PuzzleGenerate | `pages/PuzzleGenerate.tsx` | Complete | Auto-generation |

#### Visual Editors (`components/editors/`)
| Component | Status | Description |
|-----------|--------|-------------|
| SudokuEditor | Complete | Interactive 9x9 grid with validate/solve |
| KillerSudokuEditor | Complete | Cage drawing with color assignment |
| PuzzleEditorWrapper | Complete | Switches editor by game type |
| shared/GridEditor | Complete | Reusable 9x9 grid component |
| shared/NumberPad | Complete | Number input buttons 1-9 |
| shared/ValidationStatus | Complete | Shows validation results |

#### Tech Stack
- React 18 + TypeScript
- Vite (build)
- TailwindCSS (styling)
- React Router (navigation)
- TanStack Query (server state)
- Zustand (client state - `authStore.ts`)
- React Hook Form + Zod (validation)
- Axios (API client - `lib/api.ts`)

#### Key Files
- `App.tsx` - Routes and protected route wrapper
- `stores/authStore.ts` - JWT token management
- `lib/api.ts` - API client with auth interceptors
- `components/Layout.tsx` - Page layout wrapper

---

## Monetization System Status

### Implemented
| Feature | Status | Location |
|---------|--------|----------|
| AdMob rewarded videos | Working (TEST IDs) | `admob_service.dart` |
| Hint system (3 free/day) | Working | `hint_service.dart` |
| Token system | Working | `token_service.dart` |
| Archive access control | Working | `archive_screen.dart` |
| Premium user detection | Working | All services check `isPremium` |

### Not Implemented
| Feature | Priority | Notes |
|---------|----------|-------|
| In-App Purchase | HIGH | Dependency added, no integration |
| SubscriptionService | HIGH | Doesn't exist |
| Backend subscription endpoints | HIGH | Not created |
| Production Ad IDs | HIGH | Must replace test IDs |
| Retry ads (mistakes) | MEDIUM | Described in docs, not coded |
| Privacy policy | HIGH | Required for app stores |
| GDPR consent | HIGH | Required for EU |

### Token Economy
```
Token Sources:
- Daily login: 1 token (resets midnight)
- Watch ad: 5 tokens

Token Costs:
- Easy puzzle: 1 token
- Medium puzzle: 2 tokens
- Hard/Expert puzzle: 3 tokens

Premium users: Bypass all token requirements
```

---

## Known Issues & TODOs

### Code TODOs
1. **`auth_service.dart:139`** - Anonymous user data migration endpoint
2. **`archive_screen.dart:139`** - Premium subscription screen navigation

### Missing Features
1. ~~**AudioService** - All methods stubbed, no sound files~~ **DONE** - Complete with volume controls
2. ~~**Vibration** - Toggle exists, no service integration~~ **DONE** - Integrated via HapticFeedback
3. ~~**SubscriptionService**~~ N/A - Using one-time purchase (PurchaseService)
4. **Analytics** - No tracking implementation
5. **Push notifications** - Not implemented

### Configuration Issues
1. ~~**API URL** - Hardcoded to `localhost:3000` in Flutter app~~ **FIXED** - Now uses environment config
2. **Ad Unit IDs** - Using test IDs (no revenue) - Set via `--dart-define` for production
3. ~~**No environment configs** - Should use .env files~~ **FIXED** - Created `lib/config/environment.dart`

---

## File Structure Summary

```
puzzle-daily/
├── flutter_app/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── config/
│   │   │   └── environment.dart      # Environment configuration
│   │   ├── models/
│   │   │   ├── game_models.dart
│   │   │   ├── user_models.dart
│   │   │   ├── friend_models.dart
│   │   │   └── challenge_models.dart
│   │   ├── providers/
│   │   │   ├── game_provider.dart
│   │   │   └── theme_provider.dart
│   │   ├── screens/
│   │   │   ├── home_screen.dart
│   │   │   ├── game_screen.dart
│   │   │   ├── archive_screen.dart
│   │   │   ├── stats_screen.dart
│   │   │   ├── settings_screen.dart
│   │   │   ├── auth/
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── register_screen.dart
│   │   │   ├── friends/
│   │   │   │   ├── friends_screen.dart
│   │   │   │   └── friend_profile_screen.dart
│   │   │   ├── challenges/
│   │   │   │   ├── challenges_screen.dart
│   │   │   │   └── create_challenge_dialog.dart
│   │   │   └── legal/
│   │   │       ├── privacy_policy_screen.dart
│   │   │       └── terms_of_service_screen.dart
│   │   ├── services/
│   │   │   ├── api_service.dart
│   │   │   ├── auth_service.dart
│   │   │   ├── game_service.dart
│   │   │   ├── admob_service.dart
│   │   │   ├── hint_service.dart
│   │   │   ├── token_service.dart
│   │   │   ├── purchase_service.dart
│   │   │   ├── audio_service.dart
│   │   │   ├── friends_service.dart
│   │   │   ├── challenge_service.dart
│   │   │   └── consent_service.dart
│   │   └── widgets/
│   │       ├── sudoku_grid.dart
│   │       ├── killer_sudoku_grid.dart
│   │       ├── crossword_grid.dart
│   │       ├── word_search_grid.dart
│   │       ├── puzzle_card.dart
│   │       ├── token_balance_widget.dart
│   │       ├── completion_dialog.dart
│   │       └── consent_dialog.dart
│   ├── android/app/src/main/AndroidManifest.xml
│   ├── ios/Runner/Info.plist
│   └── pubspec.yaml
│
├── backend/
│   ├── src/
│   │   ├── main.ts
│   │   ├── app.module.ts
│   │   ├── auth/
│   │   │   ├── auth.module.ts
│   │   │   ├── auth.service.ts
│   │   │   ├── auth.controller.ts
│   │   │   ├── guards/
│   │   │   │   ├── jwt-auth.guard.ts
│   │   │   │   ├── local-auth.guard.ts
│   │   │   │   └── admin.guard.ts
│   │   │   └── strategies/
│   │   │       ├── jwt.strategy.ts
│   │   │       └── local.strategy.ts
│   │   ├── users/
│   │   │   ├── users.module.ts
│   │   │   ├── users.service.ts
│   │   │   └── schemas/user.schema.ts
│   │   ├── puzzles/
│   │   │   ├── puzzles.module.ts
│   │   │   ├── puzzles.service.ts
│   │   │   ├── puzzles.controller.ts
│   │   │   ├── generate.controller.ts
│   │   │   ├── dto/puzzle.dto.ts
│   │   │   └── schemas/puzzle.schema.ts
│   │   ├── scores/
│   │   │   ├── scores.module.ts
│   │   │   ├── scores.service.ts
│   │   │   ├── scores.controller.ts
│   │   │   └── schemas/score.schema.ts
│   │   ├── friends/
│   │   │   ├── friends.module.ts
│   │   │   ├── friends.service.ts
│   │   │   ├── friends.controller.ts
│   │   │   └── schemas/
│   │   │       ├── friend.schema.ts
│   │   │       └── friend-request.schema.ts
│   │   ├── challenges/
│   │   │   ├── challenges.module.ts
│   │   │   ├── challenges.service.ts
│   │   │   ├── challenges.controller.ts
│   │   │   ├── dto/challenge.dto.ts
│   │   │   └── schemas/challenge.schema.ts
│   │   ├── seeds/seed.ts
│   │   └── utils/puzzle-generators.ts
│   └── package.json
│
├── admin-portal/
│   ├── src/
│   │   ├── main.tsx
│   │   ├── App.tsx
│   │   ├── components/Layout.tsx
│   │   ├── lib/api.ts
│   │   ├── stores/authStore.ts
│   │   └── pages/
│   │       ├── Login.tsx
│   │       ├── Dashboard.tsx
│   │       ├── PuzzleList.tsx
│   │       ├── PuzzleCreate.tsx
│   │       ├── PuzzleEdit.tsx
│   │       └── PuzzleGenerate.tsx
│   └── package.json
│
├── CLAUDE.md              # Development guide
├── PROJECT_STATUS.md      # This file
├── MONETIZATION.md        # Revenue strategy
├── ADS_IMPLEMENTATION.md  # AdMob technical guide
├── ARCHIVE_SYSTEM.md      # Token system guide
├── README.md              # General readme
└── start-all.sh           # Start all services
```

---

## Quick Start Commands

```bash
# Start all services
npm run dev              # From root
# OR
./start-all.sh           # Mac/Linux

# Individual services
cd backend && npm run start:dev     # API on :3000
cd admin-portal && npm run dev      # Portal on :5173
cd flutter_app && flutter run       # Mobile app (development)

# Production Flutter build with environment config
flutter run --dart-define=ENV=production \
            --dart-define=API_URL=https://api.thedailies.app \
            --dart-define=ADMOB_REWARDED_ID_ANDROID=ca-app-pub-XXX/YYY \
            --dart-define=ADMOB_REWARDED_ID_IOS=ca-app-pub-XXX/YYY

# Seed database
cd backend && npm run seed

# Default admin login
Email: admin@dohbelisk.com
Password: 5nifrenypro
```

---

## Next Steps (Priority Order)

### High Priority
1. [x] ~~Implement `SubscriptionService` in Flutter for in-app purchases~~ - Using one-time PurchaseService instead
2. [x] ~~Create backend subscription endpoints~~ - N/A (one-time purchase, no backend needed)
3. [ ] Replace test ad IDs with production IDs (use `--dart-define`)
4. [x] Add privacy policy and terms of service - **DONE** (`screens/legal/`)
5. [x] Implement GDPR consent dialog - **DONE** (`widgets/consent_dialog.dart`, `services/consent_service.dart`)

### Medium Priority
6. [x] Implement `AudioService` with actual sound files - **DONE** (add sound files to `assets/sounds/`)
7. [x] Add vibration feedback integration - **DONE** (uses HapticFeedback)
8. [ ] Implement retry system with rewarded ads
9. [ ] Add analytics/tracking
10. [x] Configure environment-based API URLs - **DONE** (`lib/config/environment.dart`)

### Low Priority
11. [ ] Build revenue analytics dashboard
12. [ ] Add push notifications
13. [ ] Implement offline mode improvements
14. [ ] Add more themes/customization
15. [x] Challenge/competition features - **DONE** (async challenges implemented)

---

## Development Notes

### Scoring Algorithm
```dart
baseScore = 1000
timeMultiplier = (targetTime / actualTime).clamp(0.5, 2.0)
mistakePenalty = mistakes * 50
hintPenalty = hints * 100
difficultyMultiplier = {easy: 1.0, medium: 1.5, hard: 2.0, expert: 3.0}

finalScore = ((baseScore * timeMultiplier) - mistakePenalty - hintPenalty)
             * difficultyMultiplier
```

### Grid Coordinate System
- All grids use `[row][col]` indexing
- row = vertical (0 = top)
- col = horizontal (0 = left)
- 0-based indexing throughout

### Authentication Flow
1. User logs in via `/api/auth/login`
2. Backend returns JWT token
3. Token stored in SharedPreferences (Flutter) / localStorage (Admin)
4. Token sent as `Authorization: Bearer <token>` header
5. Backend validates via `JwtStrategy`

---

**Document Version:** 1.0
**Created:** 2025-12-16
