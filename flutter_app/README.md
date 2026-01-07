# The Dailies - Flutter App

Cross-platform mobile application for The Dailies puzzle game.

## Features

- **13 Puzzle Types**: Sudoku, Killer Sudoku, Crossword, Word Search, Word Forge, Nonogram, Number Target, Ball Sort, Pipes, Lights Out, Word Ladder, Connections, Mathora
- **Daily Challenges**: New puzzles every day
- **Friend Challenges**: Head-to-head multiplayer puzzles
- **Authentication**: Email/password and Google Sign-In
- **User Profile**: Avatar, friend code, account management
- **Favorites**: Pin favorite games to the top
- **Dark Mode**: Light, dark, and system theme support
- **Sound & Haptics**: CC0 licensed audio, vibration feedback
- **Push Notifications**: Firebase Cloud Messaging
- **Achievements**: Track progress with unlockable achievements
- **Offline Support**: Play with cached puzzles

## Setup

```bash
# Get dependencies
flutter pub get

# Run on device/emulator
flutter run

# Build for production
flutter build apk         # Android
flutter build ios         # iOS
flutter build web         # Web
```

## Environment Configuration

Configure the app for different environments using `--dart-define`:

```bash
flutter run --dart-define=ENV=production \
            --dart-define=API_URL=https://api.thedailies.app
```

## Project Structure

```
lib/
├── config/           # Environment configuration
├── models/           # Data models (game, user, friend, challenge, achievement)
├── providers/        # State management (GameProvider, ThemeProvider)
├── screens/          # App screens (home, game, settings, auth, etc.)
├── services/         # Business logic (API, auth, Firebase, audio, etc.)
└── widgets/          # Reusable UI components (grids, dialogs, cards)

assets/
├── data/             # Dictionary for Word Forge
├── sounds/           # CC0 licensed sound effects and music
└── fonts/            # Custom fonts
```

## Key Services

| Service | Description |
|---------|-------------|
| `ApiService` | REST client with offline fallback |
| `AuthService` | JWT auth, token persistence, profile picture |
| `GoogleSignInService` | Google OAuth authentication |
| `FirebaseService` | Push notifications |
| `AudioService` | Sound effects and background music |
| `GameStateService` | Persistent game state |
| `AchievementsService` | Achievement tracking |

## Firebase Setup

1. Create Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add iOS and Android apps
3. Download config files:
   - `ios/Runner/GoogleService-Info.plist`
   - `android/app/google-services.json`
4. Run `flutterfire configure` if needed

## Google Sign-In Setup

### iOS
1. Add URL scheme to `ios/Runner/Info.plist` (reversed client ID from GoogleService-Info.plist)
2. Configure OAuth consent screen in Google Cloud Console

### Android
1. Add SHA-1 fingerprint to Firebase console
2. Google Sign-In will use `google-services.json` configuration

## Sound Assets

All sounds are CC0 (Public Domain) licensed:
- Sound effects: Juhani Junkala ([OpenGameArt.org](https://opengameart.org/content/512-sound-effects-8-bit-style))
- Background music: MintoDog ([OpenGameArt.org](https://opengameart.org/content/cozy-puzzle-title))

## Testing

```bash
flutter test              # Run all tests
flutter test --coverage   # With coverage
flutter analyze           # Static analysis
```

## Building for Release

### iOS (TestFlight)
```bash
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
```

### Android (Firebase App Distribution)
```bash
flutter build apk --release
flutter build appbundle --release
```

## CI/CD

Automated deployment via GitHub Actions:
- Push to `main` triggers `release.yml` workflow
- Auto-bumps version, builds both platforms
- Deploys to TestFlight (iOS) and Firebase App Distribution (Android)

See `.github/workflows/release.yml` for details.
