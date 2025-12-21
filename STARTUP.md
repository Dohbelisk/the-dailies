# 🚀 The Dailies - Startup Guide

Quick reference for starting The Dailies development environment.

## Prerequisites

Before starting, ensure you have:
- ✅ **Node.js 18+** installed
- ✅ **MongoDB** running (local or cloud)
- ✅ **Flutter** (optional, for mobile app)

Check with:
```bash
node --version   # Should be v18 or higher
npm --version    # Should be v9 or higher
mongod --version # Should show MongoDB version
```

## 🎯 Quick Start Options

### Option 1: NPM Command (Recommended)

**Best for:** Cross-platform development, CI/CD pipelines

```bash
# First time setup
npm install

# Start backend + admin portal
npm run dev

# Stop: Press Ctrl+C
```

**Features:**
- ✅ Cross-platform (Mac/Linux/Windows)
- ✅ Color-coded console output
- ✅ Single terminal window
- ✅ Easy to integrate with IDE

---

### Option 2: Shell Script (Mac/Linux)

**Best for:** Mac/Linux users who want detailed startup info

```bash
# Make executable (first time only)
chmod +x start-all.sh

# Start everything
./start-all.sh

# Stop services
./stop-all.sh
# or press Ctrl+C
```

**Features:**
- ✅ Beautiful colored output
- ✅ **Interactive Flutter prompt** - choose to start mobile app
- ✅ Prerequisites checking
- ✅ Auto-installs dependencies
- ✅ Creates .env if missing
- ✅ Shows live logs
- ✅ Provides MongoDB status
- ✅ Detects connected devices/emulators
- ✅ Starts Flutter app on device automatically

---

### Option 3: Batch File (Windows)

**Best for:** Windows users

```batch
start-all.bat
```

**Features:**
- ✅ Opens separate windows for each service
- ✅ Auto-installs dependencies
- ✅ Creates .env if missing
- ✅ Services keep running after script closes

---

### Option 4: Manual Start (Individual Services)

**Best for:** Debugging, working on specific component

**Backend:**
```bash
cd backend
npm install
npm run start:dev
```

**Admin Portal:**
```bash
cd admin-portal
npm install
npm run dev
```

**Flutter App:**
```bash
cd flutter_app
flutter pub get
flutter run
```

---

## 📍 Service URLs

Once started, access your services at:

| Service | URL | Purpose |
|---------|-----|---------|
| Backend API | http://localhost:3000 | REST API endpoints |
| Swagger Docs | http://localhost:3000/api/docs | API documentation |
| Admin Portal | http://localhost:5173 | Puzzle management |
| MongoDB | localhost:27017 | Database |

---

## 🔐 Default Credentials

**Admin Login:**
- Email: `admin@dohbelisk.com`
- Password: `5nifrenypro`

> ⚠️ Change these in production!

---

## 🐛 Troubleshooting

### Port Already in Use

If you get "port already in use" errors:

```bash
# Check what's using the port
lsof -i :3000    # Backend
lsof -i :5173    # Admin portal
lsof -i :27017   # MongoDB

# Kill the process
kill -9 <PID>

# Or use the stop script
./stop-all.sh
```

### MongoDB Not Running

**Mac (Homebrew):**
```bash
brew services start mongodb-community
```

**Linux:**
```bash
sudo systemctl start mongod
```

**Windows:**
```batch
net start MongoDB
```

**Docker:**
```bash
docker run -d -p 27017:27017 --name mongodb mongo:latest
```

### Dependencies Not Installing

```bash
# Clear npm cache
npm cache clean --force

# Remove node_modules
rm -rf node_modules backend/node_modules admin-portal/node_modules

# Reinstall
npm run install:all
```

### Environment File Missing

```bash
# Backend
cp backend/.env.example backend/.env

# Edit the file and update:
# - MONGODB_URI (your database connection)
# - JWT_SECRET (random secure string)
```

---

## 📊 Available NPM Commands

From the root directory:

```bash
npm run dev              # Start backend + admin portal
npm run dev:backend      # Start backend only
npm run dev:admin        # Start admin portal only
npm run build            # Build both projects
npm run build:backend    # Build backend only
npm run build:admin      # Build admin portal only
npm run install:all      # Install all dependencies
npm run seed             # Seed database with sample data
npm run test             # Run backend tests
npm run lint             # Lint all code
```

---

## 🔥 First Time Setup Checklist

- [ ] Install Node.js 18+
- [ ] Install MongoDB
- [ ] Clone the repository
- [ ] Run `npm install` in root
- [ ] Copy `backend/.env.example` to `backend/.env`
- [ ] Update `.env` with your MongoDB URI
- [ ] Start MongoDB
- [ ] Run `npm run seed` to create admin user
- [ ] Run `npm run dev` to start services
- [ ] Open http://localhost:5173
- [ ] Login with admin@dohbelisk.com / 5nifrenypro
- [ ] Generate some puzzles!

---

## 🎮 Development Workflow

**Daily workflow:**
```bash
# 1. Start MongoDB (if not running)
brew services start mongodb-community  # Mac

# 2. Start all services
npm run dev

# 3. Open browser
open http://localhost:5173

# 4. Make changes, services auto-reload

# 5. Stop when done
Ctrl+C
```

---

## 📱 Flutter App Setup

### Automatic Startup (Shell Script)

When using `./start-all.sh`, you'll be prompted:

```
📱 Do you want to start the Flutter app?
   (requires Flutter SDK and connected device/emulator)
Start Flutter app? (y/N):
```

**If you choose 'y':**
1. ✅ Script checks for Flutter installation
2. ✅ Detects connected devices/emulators
3. ✅ Installs dependencies if needed (`flutter pub get`)
4. ✅ Launches app on available device
5. ✅ Shows hot reload instructions
6. ✅ Streams logs to `flutter.log`

**If no devices detected:**
- Script shows helpful message
- Provides instructions to start simulator/emulator
- Continues without starting Flutter app

**Supported devices:**
- iOS Simulator (Mac only)
- Android Emulator
- Physical iOS/Android devices

### Manual Startup

The Flutter app connects to the backend API. Update the API URL:

1. Open `flutter_app/lib/services/api_service.dart`
2. Change line 7:
   ```dart
   static const String baseUrl = 'http://YOUR_IP:3000/api';
   ```
3. For iOS Simulator: `http://localhost:3000/api`
4. For Android Emulator: `http://10.0.2.2:3000/api`
5. For Physical Device: `http://YOUR_MACHINE_IP:3000/api`

**Find your IP:**
```bash
# Mac/Linux
ifconfig | grep "inet "

# Windows
ipconfig
```

**Start Flutter:**
```bash
cd flutter_app
flutter pub get
flutter run
```

### Flutter Hot Reload

Once running, you can:
- Press **'r'** for hot reload (preserves state)
- Press **'R'** for hot restart (resets state)
- Press **'q'** to quit
- Check logs: `tail -f flutter.log`

---

## 🔄 Updating the Project

```bash
# Pull latest changes
git pull

# Install any new dependencies
npm run install:all

# Rebuild
npm run build

# Restart services
npm run dev
```

---

## 📝 Log Files

When using `./start-all.sh`:
- Backend logs: `backend.log`
- Admin portal logs: `admin-portal.log`

View live logs:
```bash
tail -f backend.log
tail -f admin-portal.log
```

---

## 🆘 Getting Help

1. Check the [README.md](README.md) for project overview
2. Check [CLAUDE.md](CLAUDE.md) for architecture details
3. View API docs at http://localhost:3000/api/docs
4. Check GitHub issues

---

Happy coding! 🧩✨
