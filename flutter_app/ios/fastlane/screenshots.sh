#!/bin/bash

# Screenshot Helper Script for The Dailies
# This script helps capture App Store screenshots across multiple device sizes

set -e

# Configuration
APP_NAME="The Dailies"
BUNDLE_ID="com.dohbelisk.thedailies"
SCREENSHOT_DIR="./screenshots"
FLUTTER_APP_DIR="../.."

# Device configurations for App Store
# Format: "Device Name|Folder Name|Screenshot Size"
DEVICES=(
  "iPhone 16 Pro Max|6.9-inch|1320x2868"
  "iPhone 16 Plus|6.7-inch|1290x2796"
  "iPhone 16 Pro|6.3-inch|1206x2622"
  "iPhone SE (3rd generation)|4.7-inch|750x1334"
  # iPad support
  "iPad Pro 13-inch (M4)|12.9-inch-ipad|2048x2732"
)

# Screenshot names (you'll take these in order)
SCREENSHOT_NAMES=(
  "01_home_screen"
  "02_sudoku_gameplay"
  "03_word_forge"
  "04_crossword"
  "05_completion"
  "06_stats"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
  echo ""
  echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
  echo -e "${BLUE}  $1${NC}"
  echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
  echo ""
}

print_step() {
  echo -e "${GREEN}▶ $1${NC}"
}

print_warning() {
  echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
  echo -e "${RED}✖ $1${NC}"
}

# Get device UDID by name
get_device_udid() {
  local device_name="$1"
  xcrun simctl list devices available | grep "$device_name" | head -1 | grep -oE '[A-F0-9-]{36}'
}

# Boot simulator
boot_simulator() {
  local device_name="$1"
  local udid=$(get_device_udid "$device_name")

  if [ -z "$udid" ]; then
    print_error "Device '$device_name' not found"
    return 1
  fi

  print_step "Booting $device_name ($udid)..."
  xcrun simctl boot "$udid" 2>/dev/null || true

  # Wait for boot
  sleep 3

  # Open Simulator app
  open -a Simulator

  echo "$udid"
}

# Shutdown simulator
shutdown_simulator() {
  local udid="$1"
  print_step "Shutting down simulator..."
  xcrun simctl shutdown "$udid" 2>/dev/null || true
}

# Take screenshot
take_screenshot() {
  local udid="$1"
  local folder="$2"
  local name="$3"

  local output_dir="$SCREENSHOT_DIR/$folder"
  mkdir -p "$output_dir"

  local filepath="$output_dir/${name}.png"
  xcrun simctl io "$udid" screenshot "$filepath"
  print_step "Saved: $filepath"
}

# Build and install Flutter app
build_and_install() {
  local udid="$1"

  print_step "Building Flutter app for simulator..."
  cd "$FLUTTER_APP_DIR"
  flutter build ios --simulator --release

  print_step "Installing app on simulator..."
  xcrun simctl install "$udid" "build/ios/iphonesimulator/Runner.app"

  print_step "Launching app..."
  xcrun simctl launch "$udid" "$BUNDLE_ID"

  cd - > /dev/null
}

# Interactive screenshot mode for single device
interactive_mode() {
  local device_name="$1"
  local folder_name="$2"

  print_header "Interactive Screenshot Mode: $device_name"

  local udid=$(boot_simulator "$device_name")
  if [ -z "$udid" ]; then
    return 1
  fi

  build_and_install "$udid"

  echo ""
  echo -e "${YELLOW}App is now running. Navigate to each screen and press Enter to capture.${NC}"
  echo -e "${YELLOW}Type 'q' to quit, 's' to skip to next screen.${NC}"
  echo ""

  for screen_name in "${SCREENSHOT_NAMES[@]}"; do
    echo -e "${BLUE}Ready to capture: $screen_name${NC}"
    echo -n "Press Enter to capture (or 's' to skip, 'q' to quit): "
    read -r input

    if [ "$input" = "q" ]; then
      break
    elif [ "$input" = "s" ]; then
      print_warning "Skipped $screen_name"
      continue
    fi

    take_screenshot "$udid" "$folder_name" "$screen_name"
  done

  shutdown_simulator "$udid"
  print_step "Done with $device_name!"
}

# Capture all devices
capture_all_devices() {
  print_header "Capturing Screenshots for All Devices"

  for device_config in "${DEVICES[@]}"; do
    IFS='|' read -r device_name folder_name size <<< "$device_config"
    interactive_mode "$device_name" "$folder_name"
    echo ""
  done

  print_header "All Screenshots Complete!"
  echo "Screenshots saved to: $SCREENSHOT_DIR"
  ls -la "$SCREENSHOT_DIR"
}

# Quick capture - take screenshot of current simulator
quick_capture() {
  local name="${1:-screenshot}"
  local folder="${2:-quick}"

  # Get booted device
  local udid=$(xcrun simctl list devices booted | grep -oE '[A-F0-9-]{36}' | head -1)

  if [ -z "$udid" ]; then
    print_error "No simulator is currently running"
    exit 1
  fi

  mkdir -p "$SCREENSHOT_DIR/$folder"
  take_screenshot "$udid" "$folder" "$name"
}

# Show help
show_help() {
  echo "Screenshot Helper for The Dailies"
  echo ""
  echo "Usage: $0 [command] [options]"
  echo ""
  echo "Commands:"
  echo "  all                    Capture screenshots for all configured devices"
  echo "  device <name>          Capture screenshots for a specific device"
  echo "  quick <name> [folder]  Quick capture of current simulator"
  echo "  list                   List available devices"
  echo "  help                   Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0 all                              # Capture all devices"
  echo "  $0 device 'iPhone 16 Pro Max'       # Capture specific device"
  echo "  $0 quick home_screen 6.9-inch       # Quick capture"
  echo ""
  echo "Screenshot Names (in order):"
  for name in "${SCREENSHOT_NAMES[@]}"; do
    echo "  - $name"
  done
}

# List devices
list_devices() {
  print_header "Configured Devices"
  for device_config in "${DEVICES[@]}"; do
    IFS='|' read -r device_name folder_name size <<< "$device_config"
    echo "  $device_name ($folder_name) - $size"
  done

  echo ""
  print_header "Available Simulators"
  xcrun simctl list devices available | grep -E "(iPhone|iPad)"
}

# Main
case "${1:-help}" in
  all)
    capture_all_devices
    ;;
  device)
    if [ -z "$2" ]; then
      print_error "Please specify a device name"
      exit 1
    fi
    # Find matching device config
    for device_config in "${DEVICES[@]}"; do
      IFS='|' read -r device_name folder_name size <<< "$device_config"
      if [[ "$device_name" == *"$2"* ]]; then
        interactive_mode "$device_name" "$folder_name"
        exit 0
      fi
    done
    # If no config found, use device name directly
    interactive_mode "$2" "custom"
    ;;
  quick)
    quick_capture "${2:-screenshot}" "${3:-quick}"
    ;;
  list)
    list_devices
    ;;
  help|--help|-h)
    show_help
    ;;
  *)
    show_help
    ;;
esac
