# Flutter App CLAUDE.md

Cross-platform mobile application using Flutter with Provider pattern for state management.

## State Management

- **Provider** for reactive state management
- `GameProvider` - Central game state for all puzzle types
- `ThemeProvider` - Dark mode and theme management (light/dark/system)
- `AuthService` - JWT token management with SharedPreferences

## Services

| Service | Purpose |
|---------|---------|
| `ApiService` | HTTP client, offline mock data fallback |
| `AuthService` | JWT auth, token persistence, user state, profile picture |
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
| `GoogleSignInService` | Google OAuth authentication |
| `FirebaseService` | Firebase initialization and push notifications |
| `AchievementsService` | Achievement tracking and unlocks |
| `ShakeDetectorService` | Shake-to-report bug feedback (iOS motion detection) |
| `NotificationService` | Push notifications and iOS badge management |
| `DictionaryService` | Local word dictionary for Word Forge validation |

## Screens

| Screen | Purpose |
|--------|---------|
| `HomeScreen` | Today's puzzles, navigation |
| `GameScreen` | Puzzle gameplay (all 13 game types) |
| `ArchiveScreen` | Past puzzles with token access |
| `StatsScreen` | User statistics |
| `SettingsScreen` | Profile section, audio, theme, privacy, IAP, logout |
| `DebugMenuScreen` | Hidden debug menu for feature flag overrides |
| `FriendsScreen` | Friend list, requests, search |
| `FriendProfileScreen` | Friend details, head-to-head stats |
| `ChallengesScreen` | Pending, active, completed challenges |
| `AchievementsScreen` | View earned and locked achievements |
| `LoginScreen` / `RegisterScreen` | Email/password and Google Sign-In auth |
| `ThemeSelectionScreen` | First-launch theme picker |
| `TermsOfServiceScreen` / `PrivacyPolicyScreen` | Legal |

## Widgets

**Game Grids:**
- `SudokuGrid`, `KillerSudokuGrid`, `CrosswordGrid`, `WordSearchGrid`
- `WordForgeGrid`, `NonogramGrid`, `NumberTargetGrid`, `BallSortGrid`
- `PipesGrid`, `LightsOutGrid`, `WordLadderGrid`, `ConnectionsGrid`, `MathoraGrid`

**Input:**
- `NumberPad`, `KeyboardInput`

**UI Components:**
- `GameTimer`, `PuzzleCard`, `TokenBalanceWidget`
- `CompletionDialog`, `FeedbackDialog`, `ConsentDialog`
- `ForceUpdateDialog`, `UpdateAvailableDialog`, `MaintenanceDialog`
- `AnimatedBackground`
- `GoogleSignInButton`, `AchievementUnlockToast`
- `DailyStatsBanner`, `HeroPuzzleCard`, `VibrantPuzzleCard`
- `GameIcon`

## Game-Specific State in GameProvider

| Game | State Details |
|------|---------------|
| Sudoku/Killer Sudoku | Cell selection, notes mode (`Set<int>` per cell), grid validation |
| Crossword | Word-based selection (across/down), cursor auto-advances, clue auto-scroll |
| Word Search | Drag selection with direction validation (straight lines/diagonals only) |
| Word Forge | 7-letter honeycomb, center letter required, 4+ letter words, pangram bonuses |
| Nonogram | Fill/mark mode toggle, row/column clue validation, haptic feedback on drag |
| Number Target | Expression builder with +, -, ×, ÷, auto-complete when result matches target |
| Ball Sort | Tube selection, ball movement validation |
| Pipes | Endpoint connections, pipe rotation |
| Lights Out | Toggle grid cells and neighbors |
| Word Ladder | Single letter changes between words |
| Connections | Group 16 words into 4 categories |
| Mathora | Apply math operations to reach target within move limit |

## Scoring Algorithm

```
Base score: 1000 points
Time multiplier: bonus if under target, penalty if over
Mistake penalty: -50 per error
Hint penalty: -100 per hint
Difficulty multiplier: 1x easy, 1.5x medium, 2x hard, 3x expert
Final score clamped to 0-10000
```

## Implementation Notes

- Grid coordinates: `[row][col]` (0 = top-left)
- ApiService falls back to mock data if backend unreachable
- SharedPreferences for local persistence
- Singleton pattern for AdMob, Hint, Token, Audio services
- ChangeNotifier pattern for reactive updates
- Device ID (UUID) generated on first launch for anonymous stats tracking
- iOS badge management via native method channel (`com.dohbelisk.thedailies/badge`)

### Feature Flags & Debug Menu

- `ConfigService` fetches flags on app startup
- Caches flags for offline support
- Local overrides via debug menu for testing
- Usage: `ConfigService().isFeatureEnabled('feature_key')`
- **Access Debug Menu:** Settings Screen → Tap version number 7 times

### Version Checking

On app startup, `ConfigService` compares current version against server config:
- **Force Update**: current < minVersion (non-dismissable)
- **Update Available**: current < latestVersion (dismissable)
- **Maintenance Mode**: if enabled (non-dismissable)

## Sound Assets

Located in `assets/sounds/`:

| File | Use Case |
|------|----------|
| `tap.mp3` | Cell selection, button taps |
| `success.mp3` | Correct answer, valid entry |
| `error.mp3` | Wrong answer, invalid entry |
| `complete.mp3` | Puzzle completion |
| `word_found.mp3` | Word search word found |
| `hint.mp3` | When hint is used |
| `background.mp3` | Background music (loops) |

## Social Features

### Friends System
- Unique 8-character friend codes per user (A-Z, 2-9)
- Add friends by code, username search, or user ID
- Friend requests with accept/decline flow

### Challenges
- Head-to-head puzzle competitions between friends
- 24-hour expiry on pending challenges
- Winner: highest score, then fastest time as tiebreaker

### Feedback
- In-app feedback form (shake-to-report on iOS)
- Types: bug report, game suggestion, puzzle suggestion, puzzle mistake, general
- Device info auto-collection
