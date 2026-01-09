# Backend CLAUDE.md

NestJS backend API with MongoDB and JWT authentication.

## Module Structure

| Module | Purpose |
|--------|---------|
| `auth/` | JWT authentication with Passport (local & JWT strategies), admin role guard |
| `users/` | User management with bcrypt password hashing, friend codes |
| `puzzles/` | CRUD operations for puzzles with MongoDB indexes |
| `scores/` | Score tracking, user statistics, streaks |
| `friends/` | Friend system with requests and friend codes |
| `challenges/` | Head-to-head multiplayer puzzle challenges |
| `feedback/` | User feedback and bug reports |
| `config/` | App configuration, feature flags, version management |
| `email/` | Email notifications (via Nodemailer) |
| `notifications/` | Push notifications via Firebase Cloud Messaging (FCM) |
| `seeds/` | Database seeding scripts |
| `dictionary/` | Word dictionary for Word Forge validation (~370k words) |
| `utils/` | Puzzle generators |

## Key Patterns

- All modules follow NestJS module/controller/service pattern
- MongoDB schemas use Mongoose with TypeScript decorators
- Swagger decorators on controllers for auto-generated API docs
- Guards: `JwtAuthGuard` for authentication, `AdminGuard` for admin-only routes
- Strategies: `LocalStrategy` for login, `JwtStrategy` for token validation
- JWT expiry: 7 days

## Database Schemas

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
  gameType: 'sudoku' | 'killerSudoku' | 'crossword' | 'wordSearch' | 'wordForge' | 'nonogram' | 'numberTarget' | 'ballSort' | 'pipes' | 'lightsOut' | 'wordLadder' | 'connections' | 'mathora'
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
  latestVersion: string
  minVersion: string
  updateUrl: string
  updateMessage: string
  forceUpdateMessage: string
  maintenanceMode: boolean
  maintenanceMessage: string
}

// FeatureFlag Schema
FeatureFlag {
  key: string (unique)
  name: string
  description: string
  enabled: boolean
  minAppVersion?: string
  maxAppVersion?: string
  enabledForUserIds: string[]
  rolloutPercentage: number (0-100)
  expiresAt?: Date
  metadata: object
}
```

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
POST /api/auth/google                      # Google OAuth login/register
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

### Dictionary Routes
```
GET  /api/dictionary/validate?word=X       # Check if word is valid
POST /api/dictionary/validate-many         # Check multiple words
POST /api/dictionary/validate-for-puzzle   # Check word is valid for puzzle letters
GET  /api/dictionary/count                 # Get total word count
GET  /api/dictionary/status                # Get dictionary status
```

### Push Notifications Routes (require JWT)
```
POST /api/notifications/register           # Register device FCM token
POST /api/notifications/send               # Send notification (admin only)
DELETE /api/notifications/unregister       # Unregister device token
```

## Implementation Notes

- MongoDB async config via ConfigService
- JWT secret from `JWT_SECRET` env var
- bcrypt salt rounds: 10
- Indexes on `{ gameType, date }`, `{ date }`, `{ gameType, isActive }`
- Seed script is idempotent (upsert pattern)
- Email failures non-blocking (won't fail API response)
- CORS origins from `CORS_ORIGINS` env var

### Timezone Handling
- All puzzle dates use **SAST (South African Standard Time, UTC+2)** for global rollover
- Backend stores dates at midnight SAST: puzzles for "2025-01-08" are stored as `2025-01-08T00:00:00+02:00`
- This ensures puzzles roll over at the same moment worldwide (midnight in South Africa)

## Environment Variables

```
MONGODB_URI      # MongoDB connection string
JWT_SECRET       # JWT signing secret
CORS_ORIGINS     # Allowed origins (comma-separated)
FEEDBACK_EMAIL   # Email for feedback notifications
PORT             # Server port (default: 3000)
```
