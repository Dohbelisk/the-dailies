# 🧩 The Dailies

A comprehensive daily puzzle game featuring **Sudoku**, **Killer Sudoku**, **Crossword**, and **Word Search** puzzles. Built with Flutter for mobile, NestJS for the backend API, and React for the admin portal.

![The Dailies](https://via.placeholder.com/800x400/6366F1/FFFFFF?text=The+Dailies)

## 🎮 Features

### Mobile App (Flutter)
- **4 Game Types**: Sudoku, Killer Sudoku, Crossword, Word Search
- **Daily Challenges**: New puzzles every day
- **Beautiful UI**: Smooth animations, dark mode support
- **Offline Support**: Play with cached puzzles
- **Progress Tracking**: Stats, streaks, and scores
- **Note Mode**: Pencil marks for Sudoku puzzles
- **Hints**: Get help when stuck

### Admin Portal (React)
- **Puzzle Management**: Create, edit, delete puzzles
- **Bulk Upload**: Add multiple puzzles at once
- **Scheduling**: Set puzzles for future dates
- **Analytics**: View puzzle statistics
- **User Management**: Admin authentication

### Backend API (NestJS)
- **RESTful API**: Full CRUD operations
- **Authentication**: JWT-based auth with admin roles
- **MongoDB**: Flexible document storage
- **Swagger Docs**: Auto-generated API documentation

## 📁 Project Structure

```
puzzle-daily/
├── flutter_app/          # Flutter mobile application
│   ├── lib/
│   │   ├── models/       # Data models
│   │   ├── providers/    # State management
│   │   ├── screens/      # App screens
│   │   ├── services/     # API & game services
│   │   └── widgets/      # Reusable widgets
│   └── pubspec.yaml
│
├── backend/              # NestJS API server
│   ├── src/
│   │   ├── auth/         # Authentication module
│   │   ├── puzzles/      # Puzzles CRUD
│   │   ├── scores/       # Score tracking
│   │   ├── users/        # User management
│   │   └── seeds/        # Database seeding
│   └── package.json
│
└── admin-portal/         # React admin dashboard
    ├── src/
    │   ├── components/   # React components
    │   ├── pages/        # Page components
    │   ├── stores/       # Zustand stores
    │   └── lib/          # API client
    └── package.json
```

## 🚀 Quick Start

### Option 1: Single Command Startup (Recommended)

**Using npm (cross-platform):**
```bash
# Install concurrently (first time only)
npm install

# Start backend + admin portal
npm run dev
```

**Using shell script (Mac/Linux):**
```bash
./start-all.sh
# You'll be prompted to start Flutter app on device
# Choose 'y' if you have a device/emulator connected
```

**Using batch file (Windows):**
```batch
start-all.bat
```

**Using IntelliJ IDEA:**
1. Open the run configurations dropdown (top-right)
2. Select "NPM Dev (Backend + Admin)" or "Start All (Backend + Admin)"
3. Click Run ▶️

> 💡 **IntelliJ Users:** See [.idea/INTELLIJ_SETUP.md](.idea/INTELLIJ_SETUP.md) for IDE-specific instructions and configurations.

The startup script will:
- ✅ Check prerequisites (Node.js, MongoDB)
- ✅ Install dependencies if needed
- ✅ Create `.env` file if missing
- ✅ Start backend on `http://localhost:3000`
- ✅ Start admin portal on `http://localhost:5173`
- ✅ Provide Flutter app instructions

**To stop all services:**
```bash
./stop-all.sh        # Mac/Linux
# or Ctrl+C in terminal
```

---

## 🔧 Manual Setup

### Prerequisites
- Node.js 18+
- Flutter 3.0+
- MongoDB (local or Atlas)
- npm or yarn

### 1. Backend Setup

```bash
cd backend

# Install dependencies
npm install

# Create environment file
cp .env.example .env
# Edit .env with your MongoDB URI and JWT secret

# Seed the database (creates admin user + sample puzzles)
npm run seed

# Start development server
npm run start:dev
```

The API will be available at `http://localhost:3000`
Swagger docs at `http://localhost:3000/api/docs`

**Default Admin Login:**
- Email: `admin@thedailies.app`
- Password: `admin123`

### 2. Admin Portal Setup

```bash
cd admin-portal

# Install dependencies
npm install

# Start development server
npm run dev
```

Open `http://localhost:5173` and login with admin credentials.

### 3. Flutter App Setup

```bash
cd flutter_app

# Get dependencies
flutter pub get

# Create asset directories
mkdir -p assets/sounds assets/images assets/fonts

# Run the app
flutter run
```

**Note:** Update `lib/services/api_service.dart` with your backend URL:
```dart
static const String baseUrl = 'http://YOUR_SERVER_IP:3000/api';
```

## 📝 Creating Puzzles

### Via Admin Portal

1. Login to the admin portal
2. Click "New Puzzle"
3. Select game type and difficulty
4. Paste the puzzle JSON data
5. Set the date and save

### Puzzle JSON Formats

#### Sudoku
```json
{
  "grid": [[5,3,0,0,7,0,0,0,0], ...],  // 0 = empty
  "solution": [[5,3,4,6,7,8,9,1,2], ...]
}
```

#### Killer Sudoku
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

#### Crossword
```json
{
  "rows": 10,
  "cols": 10,
  "grid": [["F","L","U","T","T","E","R","#","#","#"], ...],
  "clues": [
    {"number": 1, "direction": "across", "clue": "Google UI toolkit", "answer": "FLUTTER", "startRow": 0, "startCol": 0}
  ]
}
```

#### Word Search
```json
{
  "rows": 10,
  "cols": 10,
  "theme": "Programming",
  "grid": [["F","L","U","T","T","E","R","X","P","Q"], ...],
  "words": [
    {"word": "FLUTTER", "startRow": 0, "startCol": 0, "endRow": 0, "endCol": 6}
  ]
}
```

## 🔌 API Endpoints

### Public
- `GET /api/puzzles/today` - Get today's puzzles
- `GET /api/puzzles/type/:gameType` - Get puzzles by type
- `GET /api/puzzles/type/:gameType/date/:date` - Get specific puzzle
- `POST /api/scores` - Submit a score
- `GET /api/scores/stats` - Get user statistics

### Admin (requires auth)
- `GET /api/puzzles` - List all puzzles
- `POST /api/puzzles` - Create puzzle
- `PATCH /api/puzzles/:id` - Update puzzle
- `DELETE /api/puzzles/:id` - Delete puzzle
- `POST /api/puzzles/bulk` - Bulk create

### Auth
- `POST /api/auth/login` - Login
- `POST /api/auth/register` - Register
- `GET /api/auth/me` - Current user

## 🛠️ Technologies

### Mobile
- **Flutter** - Cross-platform UI framework
- **Provider** - State management
- **Flutter Animate** - Animations
- **Google Fonts** - Typography

### Backend
- **NestJS** - Node.js framework
- **MongoDB** - Database
- **Mongoose** - ODM
- **Passport** - Authentication
- **Swagger** - API documentation

### Admin Portal
- **React 18** - UI library
- **Vite** - Build tool
- **TailwindCSS** - Styling
- **React Query** - Data fetching
- **Zustand** - State management
- **React Hook Form** - Forms

## 📱 Screenshots

| Home | Sudoku | Word Search | Admin |
|------|--------|-------------|-------|
| ![Home](https://via.placeholder.com/200x400) | ![Sudoku](https://via.placeholder.com/200x400) | ![Word](https://via.placeholder.com/200x400) | ![Admin](https://via.placeholder.com/200x400) |

## 🔮 Future Improvements

- [ ] Push notifications for daily puzzles
- [ ] Multiplayer/competitive mode
- [ ] Puzzle generator algorithms
- [ ] Social sharing
- [ ] Leaderboards
- [ ] Achievement system
- [ ] More puzzle types (Kakuro, Nonogram, etc.)

## 📄 License

MIT License - feel free to use this project for learning or commercial purposes.

## 🤝 Contributing

Contributions are welcome! Please open an issue or submit a PR.

---

Built with ❤️ by Wayne Steedman
