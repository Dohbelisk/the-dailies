#!/bin/bash

# Automated Demo Recording Script for The Dailies
# Screen: 1080x2280
# Games: Killer Sudoku, Word Forge, Mathora, Pipes, Lights Out

echo "=== The Dailies - Automated Demo Recording ==="
echo "Games: Killer Sudoku, Word Forge, Mathora, Pipes, Lights Out"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Helper functions
tap() {
    echo -e "${GREEN}Tap:${NC} $1, $2"
    adb shell input tap $1 $2
}

swipe() {
    echo -e "${GREEN}Swipe:${NC} $1,$2 -> $3,$4"
    adb shell input swipe $1 $2 $3 $4 $5
}

wait_sec() {
    echo -e "${YELLOW}Waiting ${1}s...${NC}"
    sleep $1
}

press_back() {
    echo -e "${GREEN}Back button${NC}"
    adb shell input keyevent KEYCODE_BACK
}

# Screen dimensions (1080x2280)
WIDTH=1080
HEIGHT=2280
CENTER_X=$((WIDTH / 2))

# Start the app fresh
echo ""
echo "=== Starting Fresh Install ==="
adb shell am force-stop com.dohbelisk.thedailies
sleep 1
adb shell pm clear com.dohbelisk.thedailies 2>/dev/null
sleep 1
adb shell am start -n com.dohbelisk.thedailies/.MainActivity
sleep 5

# Start screen recording
echo ""
echo "=== Starting Screen Recording ==="
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RECORDING_FILE="/sdcard/thedailies_demo_${TIMESTAMP}.mp4"
adb shell screenrecord --time-limit 180 --bit-rate 8000000 $RECORDING_FILE &
RECORD_PID=$!
echo "Recording to: $RECORDING_FILE"
sleep 2

echo ""
echo "=== Recording Demo Sequence ==="

# ============================================
# ONBOARDING
# ============================================
echo ""
echo -e "${CYAN}--- Onboarding ---${NC}"
wait_sec 3

# Theme selection - tap dark theme (right side)
tap 750 1000
wait_sec 1
# Tap Continue/Get Started
tap $CENTER_X 1800
wait_sec 2
tap $CENTER_X 1800
wait_sec 2

# Terms - scroll and accept
swipe $CENTER_X 1400 $CENTER_X 600 400
wait_sec 1
# Tap Accept/Agree button
tap $CENTER_X 2000
wait_sec 1
tap $CENTER_X 1850
wait_sec 1
tap $CENTER_X 1750
wait_sec 3

# ============================================
# HOME SCREEN - Show all games
# ============================================
echo ""
echo -e "${CYAN}--- Home Screen Overview ---${NC}"
wait_sec 2

# Slow scroll to show games
swipe $CENTER_X 1500 $CENTER_X 800 800
wait_sec 1.5
swipe $CENTER_X 1500 $CENTER_X 800 800
wait_sec 1.5
swipe $CENTER_X 1500 $CENTER_X 800 800
wait_sec 2

# Scroll back to top
swipe $CENTER_X 600 $CENTER_X 1500 500
wait_sec 0.5
swipe $CENTER_X 600 $CENTER_X 1500 500
wait_sec 0.5
swipe $CENTER_X 600 $CENTER_X 1500 500
wait_sec 2

# ============================================
# GAME 1: KILLER SUDOKU (should be 2nd in list)
# ============================================
echo ""
echo -e "${CYAN}--- Game 1: Killer Sudoku ---${NC}"

# Tap Killer Sudoku card (second card, top right area)
tap 800 580
wait_sec 4

# Play some moves - tap cells in grid and enter numbers
# Grid is in upper portion, number pad at bottom
tap 300 700    # Tap a cell in cage
wait_sec 0.5
tap 432 1850   # Tap number 3
wait_sec 0.5

tap 500 800    # Another cell
wait_sec 0.5
tap 540 1850   # Tap number 5
wait_sec 0.5

tap 700 700    # Another cell
wait_sec 0.5
tap 648 1850   # Tap number 7
wait_sec 2

# Back to home
press_back
wait_sec 2

# ============================================
# GAME 2: WORD FORGE (scroll down to find it)
# ============================================
echo ""
echo -e "${CYAN}--- Game 2: Word Forge ---${NC}"

# Scroll down to find Word Forge
swipe $CENTER_X 1400 $CENTER_X 900 600
wait_sec 1

# Tap Word Forge card (should be visible now)
tap 280 580
wait_sec 4

# Word Forge gameplay - tap letters in honeycomb pattern
# Honeycomb is centered, with center letter and 6 surrounding
tap 540 850    # Center letter (required in all words)
wait_sec 0.3
tap 430 750    # Top-left letter
wait_sec 0.3
tap 650 750    # Top-right letter
wait_sec 0.3
tap 430 950    # Bottom-left letter
wait_sec 0.5

# Tap Submit/Enter button
tap 540 1150
wait_sec 1

# Try another word
tap 540 850    # Center
wait_sec 0.2
tap 650 950    # Bottom-right
wait_sec 0.2
tap 540 1050   # Bottom
wait_sec 0.2
tap 430 950    # Bottom-left
wait_sec 0.5
tap 540 1150   # Submit
wait_sec 2

# Back
press_back
wait_sec 2

# ============================================
# GAME 3: MATHORA
# ============================================
echo ""
echo -e "${CYAN}--- Game 3: Mathora ---${NC}"

# Tap Mathora card
tap 800 580
wait_sec 4

# Mathora gameplay - tap operations to reach target
# Operations are displayed as buttons
tap 350 900    # Tap an operation
wait_sec 0.8
tap 550 900    # Tap another operation
wait_sec 0.8
tap 750 900    # Tap another
wait_sec 0.8
tap 450 1050   # Tap another
wait_sec 2

# Back
press_back
wait_sec 2

# ============================================
# GAME 4: PIPES
# ============================================
echo ""
echo -e "${CYAN}--- Game 4: Pipes ---${NC}"

# Scroll down a bit
swipe $CENTER_X 1200 $CENTER_X 800 500
wait_sec 1

# Tap Pipes card
tap 280 580
wait_sec 4

# Pipes gameplay - drag to connect endpoints
# Grid is centered
swipe 300 600 300 800 300    # Drag down
wait_sec 0.5
swipe 500 600 700 600 300    # Drag right
wait_sec 0.5
swipe 700 800 700 1000 300   # Drag down
wait_sec 0.5
swipe 400 900 600 900 300    # Drag right
wait_sec 2

# Back
press_back
wait_sec 2

# ============================================
# GAME 5: LIGHTS OUT
# ============================================
echo ""
echo -e "${CYAN}--- Game 5: Lights Out ---${NC}"

# Tap Lights Out card
tap 800 580
wait_sec 4

# Lights Out gameplay - tap cells to toggle lights
tap 400 700    # Tap a light
wait_sec 0.4
tap 600 700    # Tap another
wait_sec 0.4
tap 500 850    # Tap another
wait_sec 0.4
tap 400 1000   # Tap another
wait_sec 0.4
tap 700 850    # Tap another
wait_sec 2

# Back
press_back
wait_sec 2

# ============================================
# FINAL: Scroll through home screen
# ============================================
echo ""
echo -e "${CYAN}--- Final Home Screen View ---${NC}"

# Scroll back to top
swipe $CENTER_X 600 $CENTER_X 1600 400
wait_sec 1
swipe $CENTER_X 600 $CENTER_X 1600 400
wait_sec 2

# Final pause on home screen
wait_sec 3

# ============================================
# STOP RECORDING
# ============================================
echo ""
echo "=== Stopping Recording ==="
adb shell pkill -INT screenrecord
sleep 3

# Pull the video
echo ""
echo "=== Downloading Video ==="
OUTPUT_DIR="/Users/steedles/Development/puzzle-daily/flutter_app/scripts"
OUTPUT_FILE="${OUTPUT_DIR}/demo_recording_${TIMESTAMP}.mp4"
adb pull $RECORDING_FILE "$OUTPUT_FILE"

# Clean up
adb shell rm $RECORDING_FILE 2>/dev/null

echo ""
echo "=========================================="
echo -e "${GREEN}Recording Complete!${NC}"
echo "=========================================="
echo ""
echo -e "Video saved to: ${CYAN}$OUTPUT_FILE${NC}"
echo ""
echo "Games featured:"
echo "  1. Killer Sudoku"
echo "  2. Word Forge"
echo "  3. Mathora"
echo "  4. Pipes"
echo "  5. Lights Out"
echo ""
echo "Next: Upload to opus.pro or kapwing.com"
echo ""
