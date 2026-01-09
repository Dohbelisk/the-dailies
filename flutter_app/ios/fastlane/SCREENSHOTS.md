# App Store Screenshots Guide

This guide explains how to capture App Store screenshots for The Dailies using Fastlane.

## Quick Start

```bash
cd flutter_app/ios

# See available devices
fastlane screenshot_list

# Capture all devices (interactive)
fastlane screenshots

# Capture specific device
fastlane screenshot_device device:"iPhone 16 Pro Max"

# Quick capture of current simulator
fastlane screenshot_quick name:home_screen folder:6.9-inch
```

## How It Works

Since Flutter apps don't use native iOS UI elements, we use a custom script (`screenshots.sh`) that:

1. Boots the simulator for each device size
2. Builds and installs the Flutter app
3. Prompts you to navigate to each screen
4. Captures screenshots using `xcrun simctl`

## App Store Requirements

Apple requires screenshots for these device sizes:

| Device | Screen Size | Required |
|--------|-------------|----------|
| iPhone 16 Pro Max | 6.9" (1320x2868) | Yes |
| iPhone 16 Plus | 6.7" (1290x2796) | Yes |
| iPhone SE | 4.7" (750x1334) | Optional |
| iPad Pro 13" | 12.9" (2048x2732) | If iPad supported |
| iPad Pro 11" | 11" (1668x2388) | If iPad supported |

## Recommended Screenshots

Capture these screens in order:

| # | Screen | What to Show |
|---|--------|--------------|
| 1 | `01_home_screen` | Today's puzzles grid with variety |
| 2 | `02_sudoku_gameplay` | Mid-game Sudoku with notes |
| 3 | `03_word_forge` | Honeycomb with found words list |
| 4 | `04_crossword` | Partially completed crossword |
| 5 | `05_completion` | Completion dialog with score |
| 6 | `06_stats` | Statistics or achievements screen |

## Step-by-Step Process

### 1. Prepare Your Content

Before capturing, set up the app state you want to show:

- **Home Screen**: Have a mix of completed/in-progress puzzles
- **Gameplay**: Get to an interesting mid-game state
- **Stats**: Have some meaningful statistics to display

### 2. Run the Screenshot Tool

```bash
cd flutter_app/ios
fastlane screenshots
```

The tool will:
1. Boot each simulator one at a time
2. Build and install the app
3. Launch the app
4. Prompt you for each screenshot

### 3. Navigate and Capture

For each screen:
1. Navigate to the desired screen in the simulator
2. Adjust the content as needed
3. Press **Enter** to capture
4. Type **s** to skip a screen
5. Type **q** to quit early

### 4. Review Screenshots

Screenshots are saved to `ios/fastlane/screenshots/`:

```
screenshots/
├── 6.9-inch/
│   ├── 01_home_screen.png
│   ├── 02_sudoku_gameplay.png
│   └── ...
├── 6.7-inch/
│   └── ...
└── 4.7-inch/
    └── ...
```

### 5. Upload to App Store Connect

```bash
# Upload screenshots only (no binary)
fastlane upload_screenshots
```

Or upload manually through App Store Connect.

## Tips for Great Screenshots

### Content Tips
- Show the app in its best light with interesting content
- Use dark mode for some screenshots (variety)
- Show different puzzle types to highlight variety
- Display meaningful progress/achievements

### Technical Tips
- Take screenshots in **light mode** unless dark mode is a feature
- Ensure the status bar shows a good time (e.g., 9:41)
- Hide any debug UI or test data
- Make sure animations are complete before capturing

### Status Bar

To set a clean status bar (9:41, full battery):
```bash
xcrun simctl status_bar booted override --time "9:41" --batteryState charged --batteryLevel 100
```

## Troubleshooting

### Simulator Won't Boot
```bash
# List available simulators
xcrun simctl list devices available

# Manually boot a device
xcrun simctl boot "iPhone 16 Pro Max"
```

### App Won't Install
```bash
# Clean and rebuild
cd flutter_app
flutter clean
flutter build ios --simulator
```

### Screenshots Look Wrong
- Check the simulator scale (Window > Physical Size)
- Ensure no system dialogs are showing
- Wait for animations to complete

## Alternative: Manual Screenshots

If you prefer manual capture:

1. Run the app: `flutter run`
2. Navigate to the desired screen
3. Press **Cmd+S** in Simulator to save screenshot
4. Repeat for each device size

## File Structure

```
ios/fastlane/
├── Fastfile          # Fastlane lanes
├── Appfile           # App configuration
├── Snapfile          # Screenshot configuration
├── screenshots.sh    # Screenshot helper script
├── SCREENSHOTS.md    # This guide
└── screenshots/      # Output directory (gitignored)
```
