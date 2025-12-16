#!/bin/bash

# The Dailies - Start All Services
# This script starts the backend, admin portal, and provides Flutter instructions

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${PURPLE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║              🧩  THE DAILIES - STARTUP  🧩                  ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}\n"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if a port is in use
port_in_use() {
    lsof -i :"$1" >/dev/null 2>&1
}

# Function to cleanup on exit
cleanup() {
    echo -e "\n${YELLOW}🛑 Shutting down all services...${NC}"
    kill 0  # Kill all processes in the current process group
    exit
}

trap cleanup SIGINT SIGTERM

# Check if running interactively
if [ -t 0 ] && [ -z "$CI" ]; then
    # Interactive mode - ask user about Flutter app
    echo -e "${CYAN}📱 Do you want to start the Flutter app?${NC}"
    echo -e "${YELLOW}   (requires Flutter SDK and connected device/emulator)${NC}"
    echo -n "Start Flutter app? (y/N): "
    read -r START_FLUTTER
    echo ""

    if [[ $START_FLUTTER =~ ^[Yy]$ ]]; then
        FLUTTER_ENABLED=true
        echo -e "${GREEN}✓${NC} Flutter app will be started\n"
    else
        FLUTTER_ENABLED=false
        echo -e "${YELLOW}⊘${NC} Flutter app will be skipped\n"
    fi
else
    # Non-interactive mode (IDE, CI, etc.) - check environment variable
    if [ "$START_FLUTTER" = "true" ] || [ "$START_FLUTTER" = "1" ]; then
        FLUTTER_ENABLED=true
        echo -e "${GREEN}✓${NC} Flutter app enabled via environment variable\n"
    else
        FLUTTER_ENABLED=false
        echo -e "${YELLOW}⊘${NC} Flutter app disabled (non-interactive mode)\n"
        echo -e "${CYAN}   Tip: Set START_FLUTTER=true to enable Flutter in IDE${NC}\n"
    fi
fi

# Check prerequisites
echo -e "${CYAN}📋 Checking prerequisites...${NC}\n"

if ! command_exists node; then
    echo -e "${RED}❌ Node.js is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Node.js $(node --version)"

if ! command_exists npm; then
    echo -e "${RED}❌ npm is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} npm $(npm --version)"

if command_exists flutter; then
    echo -e "${GREEN}✓${NC} Flutter $(flutter --version | head -1)"
    FLUTTER_AVAILABLE=true
else
    if [ "$FLUTTER_ENABLED" = true ]; then
        echo -e "${RED}❌ Flutter is not installed but you requested to start the app${NC}"
        echo -e "${YELLOW}   Install Flutter from: https://flutter.dev/docs/get-started/install${NC}"
        exit 1
    else
        echo -e "${YELLOW}⚠${NC}  Flutter not found (optional for mobile app)"
        FLUTTER_AVAILABLE=false
    fi
fi

if command_exists mongod; then
    echo -e "${GREEN}✓${NC} MongoDB available"
else
    echo -e "${YELLOW}⚠${NC}  MongoDB not found in PATH (might be running as service)"
fi

echo ""

# Check if MongoDB is running
echo -e "${CYAN}🔍 Checking MongoDB...${NC}"
if port_in_use 27017; then
    echo -e "${GREEN}✓${NC} MongoDB is running on port 27017\n"
else
    echo -e "${YELLOW}⚠${NC}  MongoDB is not running on port 27017"
    echo -e "${YELLOW}   Please start MongoDB manually or it will auto-start${NC}\n"
fi

# Check if backend dependencies are installed
if [ ! -d "backend/node_modules" ]; then
    echo -e "${YELLOW}📦 Installing backend dependencies...${NC}"
    cd backend && npm install && cd ..
    echo -e "${GREEN}✓${NC} Backend dependencies installed\n"
fi

# Check if admin portal dependencies are installed
if [ ! -d "admin-portal/node_modules" ]; then
    echo -e "${YELLOW}📦 Installing admin portal dependencies...${NC}"
    cd admin-portal && npm install && cd ..
    echo -e "${GREEN}✓${NC} Admin portal dependencies installed\n"
fi

# Check if .env exists
if [ ! -f "backend/.env" ]; then
    echo -e "${YELLOW}⚠${NC}  Creating backend/.env from .env.example"
    cp backend/.env.example backend/.env
    echo -e "${GREEN}✓${NC} Created backend/.env (please update with your settings)\n"
fi

# Start services
TOTAL_SERVICES=2
if [ "$FLUTTER_ENABLED" = true ]; then
    TOTAL_SERVICES=3
fi

echo -e "${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║               🚀  STARTING SERVICES  🚀                    ║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}\n"

# Start backend
echo -e "${BLUE}[1/$TOTAL_SERVICES]${NC} Starting Backend API (NestJS)..."
cd backend
npm run start:dev > ../backend.log 2>&1 &
BACKEND_PID=$!
cd ..
echo -e "${GREEN}✓${NC} Backend started (PID: $BACKEND_PID)"
echo -e "      ${CYAN}http://localhost:3000${NC}"
echo -e "      ${CYAN}http://localhost:3000/api/docs${NC} (Swagger)\n"

# Wait a moment for backend to start
sleep 2

# Start admin portal
echo -e "${BLUE}[2/$TOTAL_SERVICES]${NC} Starting Admin Portal (React + Vite)..."
cd admin-portal
npm run dev > ../admin-portal.log 2>&1 &
ADMIN_PID=$!
cd ..
echo -e "${GREEN}✓${NC} Admin Portal started (PID: $ADMIN_PID)"
echo -e "      ${CYAN}http://localhost:5173${NC}\n"

# Wait for services to be ready
echo -e "${YELLOW}⏳ Waiting for services to be ready...${NC}"
sleep 3

# Check if services are running
if port_in_use 3000; then
    echo -e "${GREEN}✓${NC} Backend is ready on port 3000"
else
    echo -e "${RED}✗${NC} Backend failed to start (check backend.log)"
fi

if port_in_use 5173; then
    echo -e "${GREEN}✓${NC} Admin Portal is ready on port 5173\n"
else
    echo -e "${RED}✗${NC} Admin Portal failed to start (check admin-portal.log)\n"
fi

# Start Flutter app if requested
if [ "$FLUTTER_ENABLED" = true ]; then
    echo -e "${BLUE}[3/$TOTAL_SERVICES]${NC} Starting Flutter App..."

    # Check if flutter_app directory exists
    if [ ! -d "flutter_app" ]; then
        echo -e "${RED}✗${NC} flutter_app directory not found\n"
    else
        cd flutter_app

        # Check if dependencies are installed
        if [ ! -d ".dart_tool" ]; then
            echo -e "${YELLOW}   Installing Flutter dependencies...${NC}"
            flutter pub get > /dev/null 2>&1
        fi

        # Get available devices
        DEVICES_OUTPUT=$(flutter devices 2>/dev/null)
        DEVICE_COUNT=$(echo "$DEVICES_OUTPUT" | grep -c "•" || echo "0")

        if [ "$DEVICE_COUNT" -eq "0" ]; then
            echo -e "${YELLOW}⚠${NC}  No devices detected. Available options:"
            echo -e "${CYAN}   - Start an iOS Simulator${NC}"
            echo -e "${CYAN}   - Start an Android Emulator${NC}"
            echo -e "${CYAN}   - Connect a physical device${NC}"
            echo -e "\n${YELLOW}   Run 'flutter devices' to see available devices${NC}\n"
            cd ..
        else
            echo -e "${GREEN}✓${NC} Detected $DEVICE_COUNT device(s)"
            echo -e "${CYAN}   Available devices:${NC}"
            echo "$DEVICES_OUTPUT" | grep "•" | head -5
            echo ""

            # Device selection priority:
            # 1. Samsung (SM N970U1 / R58M809YHMZ)
            # 2. Wayne's iPhone (00008130-001C293A2662001C)
            # 3. iOS Simulator
            # 4. First available device

            TARGET_DEVICE=""
            DEVICE_NAME=""

            # Check for Samsung device
            if echo "$DEVICES_OUTPUT" | grep -q "R58M809YHMZ"; then
                TARGET_DEVICE="R58M809YHMZ"
                DEVICE_NAME="Samsung SM N970U1"
                echo -e "${GREEN}✓${NC} Selected: ${CYAN}$DEVICE_NAME${NC} (priority 1)"
            # Check for Wayne's iPhone
            elif echo "$DEVICES_OUTPUT" | grep -q "00008130-001C293A2662001C"; then
                TARGET_DEVICE="00008130-001C293A2662001C"
                DEVICE_NAME="Wayne's iPhone 15 Pro"
                echo -e "${GREEN}✓${NC} Selected: ${CYAN}$DEVICE_NAME${NC} (priority 2)"
            # Check for iOS Simulator
            elif echo "$DEVICES_OUTPUT" | grep -qi "simulator"; then
                # Extract simulator device ID
                TARGET_DEVICE=$(echo "$DEVICES_OUTPUT" | grep -i "simulator" | head -1 | sed 's/.*• \([^ ]*\) •.*/\1/')
                DEVICE_NAME="iOS Simulator"
                echo -e "${GREEN}✓${NC} Selected: ${CYAN}$DEVICE_NAME${NC} (priority 3)"
            fi

            # Start Flutter app
            echo -e "${YELLOW}   Launching Flutter app...${NC}"
            if [ -n "$TARGET_DEVICE" ]; then
                flutter run -d "$TARGET_DEVICE" > ../flutter.log 2>&1 &
            else
                # Fallback to default device selection
                DEVICE_NAME="default device"
                echo -e "${YELLOW}⚠${NC}  No preferred device found, using default"
                flutter run > ../flutter.log 2>&1 &
            fi
            FLUTTER_PID=$!
            cd ..
            echo -e "${GREEN}✓${NC} Flutter app started on ${CYAN}$DEVICE_NAME${NC} (PID: $FLUTTER_PID)"
            echo -e "      ${YELLOW}Hot reload:${NC} Press 'r' in the Flutter terminal"
            echo -e "      ${YELLOW}Hot restart:${NC} Press 'R' in the Flutter terminal"
            echo -e "      ${YELLOW}Logs:${NC} tail -f flutter.log\n"
        fi
    fi
else
    # Display Flutter instructions if not started
    echo -e "${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║            📱  FLUTTER APP (OPTIONAL)  📱                  ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}\n"

    if command_exists flutter; then
        echo -e "${CYAN}To start the Flutter app manually:${NC}"
        echo -e "  cd flutter_app"
        echo -e "  flutter run\n"
        echo -e "${YELLOW}Note:${NC} Update ${CYAN}lib/services/api_service.dart${NC} with your backend URL"
        echo -e "      (Use your machine's IP address for physical devices)\n"
    else
        echo -e "${YELLOW}Flutter is not installed. Install from:${NC}"
        echo -e "  ${CYAN}https://flutter.dev/docs/get-started/install${NC}\n"
    fi
fi

# Display summary
echo -e "${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║                  🎮  QUICK LINKS  🎮                       ║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}\n"

echo -e "  ${GREEN}Backend API:${NC}      ${CYAN}http://localhost:3000${NC}"
echo -e "  ${GREEN}Swagger Docs:${NC}     ${CYAN}http://localhost:3000/api/docs${NC}"
echo -e "  ${GREEN}Admin Portal:${NC}     ${CYAN}http://localhost:5173${NC}"
if [ "$FLUTTER_ENABLED" = true ] && [ -n "$FLUTTER_PID" ]; then
    echo -e "  ${GREEN}Flutter App:${NC}      Running on connected device"
fi
echo -e "  ${GREEN}Default Login:${NC}    admin@thedailies.app / admin123\n"

echo -e "${YELLOW}📝 Logs:${NC}"
echo -e "  Backend:       tail -f backend.log"
echo -e "  Admin Portal:  tail -f admin-portal.log"
if [ "$FLUTTER_ENABLED" = true ] && [ -f "flutter.log" ]; then
    echo -e "  Flutter App:   tail -f flutter.log"
fi
echo ""

echo -e "${GREEN}✨ All services are running!${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop all services${NC}\n"

# Keep script running and show live logs
echo -e "${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║                    📊  LIVE LOGS  📊                       ║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}\n"

# Tail logs based on what's running
if [ "$FLUTTER_ENABLED" = true ] && [ -f "flutter.log" ]; then
    tail -f backend.log admin-portal.log flutter.log 2>/dev/null &
else
    tail -f backend.log admin-portal.log 2>/dev/null &
fi

# Wait for user interrupt
wait
