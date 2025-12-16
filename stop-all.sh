#!/bin/bash

# The Dailies - Stop All Services

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🛑 Stopping The Dailies services...${NC}\n"

# Kill processes on specific ports
kill_port() {
    local port=$1
    local name=$2
    local pid=$(lsof -ti:$port 2>/dev/null)

    if [ -n "$pid" ]; then
        kill -9 $pid 2>/dev/null
        echo -e "${GREEN}✓${NC} Stopped $name (port $port, PID: $pid)"
    else
        echo -e "${YELLOW}⚠${NC}  No process running on port $port ($name)"
    fi
}

kill_port 3000 "Backend"
kill_port 5173 "Admin Portal"

# Clean up log files
if [ -f "backend.log" ]; then
    rm backend.log
    echo -e "${GREEN}✓${NC} Removed backend.log"
fi

if [ -f "admin-portal.log" ]; then
    rm admin-portal.log
    echo -e "${GREEN}✓${NC} Removed admin-portal.log"
fi

if [ -f "flutter.log" ]; then
    rm flutter.log
    echo -e "${GREEN}✓${NC} Removed flutter.log"
fi

# Kill any flutter processes
pkill -f "flutter run" 2>/dev/null && echo -e "${GREEN}✓${NC} Stopped Flutter processes"

echo -e "\n${GREEN}✨ All services stopped!${NC}\n"
