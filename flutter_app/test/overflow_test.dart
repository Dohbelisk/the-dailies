import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_daily/widgets/number_pad.dart';
import 'package:puzzle_daily/widgets/sudoku_grid.dart';
import 'package:puzzle_daily/widgets/keyboard_input.dart';
import 'package:puzzle_daily/widgets/puzzle_card.dart';
import 'package:puzzle_daily/widgets/game_timer.dart';
import 'package:puzzle_daily/models/game_models.dart';

/// Common device sizes for testing overflow
/// These represent the logical pixel sizes (not physical)
class DeviceSizes {
  // iPhone SE (1st gen) - smallest common iPhone (320pt)
  static const iphoneSE1 = Size(320, 568);

  // iPhone SE (2nd/3rd gen), iPhone 8 (375pt)
  static const iphoneSE = Size(375, 667);

  // iPhone 12/13/14/15 Mini (375pt but taller)
  static const iphoneMini = Size(375, 812);

  // iPhone 12/13/14/15, iPhone 12/13/14/15 Pro (390pt)
  static const iphone = Size(390, 844);

  // iPhone 12/13/14 Pro Max, iPhone 15 Plus/Pro Max (430pt)
  static const iphoneProMax = Size(430, 932);

  // iPad Mini (744pt)
  static const ipadMini = Size(744, 1133);

  // iPad Pro 11" (834pt)
  static const ipadPro11 = Size(834, 1194);

  // Small Android phone (360pt - very common)
  static const androidSmall = Size(360, 640);

  // Medium Android phone (411pt)
  static const androidMedium = Size(411, 731);

  // Large Android phone (411pt but taller)
  static const androidLarge = Size(411, 823);

  // All phone sizes to test
  static const phones = [
    // Note: iPhone SE 1st Gen (320pt) removed - 9-year-old device, too small for modern UI
    ('iPhone SE', iphoneSE),
    ('iPhone Mini', iphoneMini),
    ('iPhone', iphone),
    ('iPhone Pro Max', iphoneProMax),
    ('Android Small', androidSmall),
    ('Android Medium', androidMedium),
    ('Android Large', androidLarge),
  ];

  // Tablets
  static const tablets = [
    ('iPad Mini', ipadMini),
    ('iPad Pro 11"', ipadPro11),
  ];

  // All devices
  static const all = [
    ...phones,
    ...tablets,
  ];
}

/// Helper function to run a widget test with overflow detection at a specific size
/// Allows tolerance for sub-pixel overflow (common with floating-point math)
Future<void> testOverflowAtSize(
  WidgetTester tester,
  Widget widget,
  String deviceName,
  Size size, {
  double tolerance = 1.0, // Allow up to 1px overflow (floating-point precision)
}) async {
  final overflowErrors = <String>[];
  final originalOnError = FlutterError.onError;

  // Regex to extract overflow amount from error message
  final overflowRegex = RegExp(r'overflowed by ([\d.]+) pixels');

  FlutterError.onError = (FlutterErrorDetails details) {
    final message = details.exception.toString();
    if (message.contains('overflowed') || message.contains('OVERFLOW')) {
      // Check if overflow is within tolerance
      final match = overflowRegex.firstMatch(message);
      if (match != null) {
        final overflowAmount = double.tryParse(match.group(1) ?? '0') ?? 0;
        if (overflowAmount > tolerance) {
          overflowErrors.add(message);
        }
      } else {
        overflowErrors.add(message);
      }
    }
  };

  try {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(child: widget),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      overflowErrors,
      isEmpty,
      reason: 'Overflow on $deviceName (${size.width}x${size.height}): ${overflowErrors.join(', ')}',
    );
  } finally {
    FlutterError.onError = originalOnError;
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ==========================================
  // WIDGET TESTS
  // ==========================================

  group('NumberPad Overflow Tests', () {
    for (final (deviceName, size) in DeviceSizes.phones) {
      testWidgets('NumberPad without calculator - fits on $deviceName', (tester) async {
        await testOverflowAtSize(
          tester,
          NumberPad(
            notesMode: false,
            onNumberTap: (_) {},
            onClearTap: () {},
            onNotesTap: () {},
            onHintTap: () {},
            showCalculator: false,
          ),
          deviceName,
          size,
        );
      });

      testWidgets('NumberPad with calculator - fits on $deviceName', (tester) async {
        await testOverflowAtSize(
          tester,
          NumberPad(
            notesMode: false,
            onNumberTap: (_) {},
            onClearTap: () {},
            onNotesTap: () {},
            onHintTap: () {},
            showCalculator: true,
          ),
          deviceName,
          size,
        );
      });

      testWidgets('NumberPad notes mode - fits on $deviceName', (tester) async {
        await testOverflowAtSize(
          tester,
          NumberPad(
            notesMode: true,
            onNumberTap: (_) {},
            onClearTap: () {},
            onNotesTap: () {},
            onHintTap: () {},
            showCalculator: true,
          ),
          deviceName,
          size,
        );
      });
    }
  });

  group('KeyboardInput Overflow Tests', () {
    for (final (deviceName, size) in DeviceSizes.phones) {
      testWidgets('KeyboardInput fits on $deviceName', (tester) async {
        await testOverflowAtSize(
          tester,
          KeyboardInput(
            onLetterTap: (_) {},
            onDeleteTap: () {},
          ),
          deviceName,
          size,
        );
      });
    }
  });

  group('GameTimer Overflow Tests', () {
    for (final (deviceName, size) in DeviceSizes.phones) {
      testWidgets('GameTimer fits on $deviceName', (tester) async {
        await testOverflowAtSize(
          tester,
          const GameTimer(seconds: 3599), // Max typical display: 59:59
          deviceName,
          size,
        );
      });
    }
  });

  group('SudokuGrid Overflow Tests', () {
    // Create a minimal sudoku puzzle for testing
    final puzzle = SudokuPuzzle(
      grid: List.generate(9, (_) => List.filled(9, null)),
      initialGrid: List.generate(9, (_) => List.filled(9, null)),
      solution: List.generate(9, (r) => List.generate(9, (c) => ((r * 3 + r ~/ 3 + c) % 9) + 1)),
      notes: List.generate(9, (_) => List.generate(9, (_) => <int>{})),
    );

    for (final (deviceName, size) in DeviceSizes.phones) {
      testWidgets('SudokuGrid fits on $deviceName', (tester) async {
        await testOverflowAtSize(
          tester,
          SudokuGrid(
            puzzle: puzzle,
            onCellTap: (_, __) {},
          ),
          deviceName,
          size,
        );
      });
    }
  });

  group('PuzzleCard Overflow Tests', () {
    // Create a minimal puzzle for testing
    final puzzle = DailyPuzzle(
      id: 'test-1',
      gameType: GameType.sudoku,
      difficulty: Difficulty.medium,
      date: DateTime.now(),
      puzzleData: {},
    );

    for (final (deviceName, size) in DeviceSizes.phones) {
      testWidgets('PuzzleCard fits on $deviceName', (tester) async {
        await testOverflowAtSize(
          tester,
          SizedBox(
            width: size.width - 32, // Account for typical horizontal padding
            height: 150,
            child: PuzzleCard(
              puzzle: puzzle,
              onTap: () {},
            ),
          ),
          deviceName,
          size,
        );
      });
    }
  });

  // ==========================================
  // SCREEN LAYOUT TESTS
  // ==========================================

  group('Home Screen Header Overflow Tests', () {
    // Test the action chips row that appears in HomeScreen (now scrollable)
    for (final (deviceName, size) in DeviceSizes.phones) {
      testWidgets('Home screen action chips fit on $deviceName', (tester) async {
        await testOverflowAtSize(
          tester,
          Builder(
            builder: (context) {
              final theme = Theme.of(context);
              return Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // Important: prevent Row from expanding
                    children: [
                      _buildActionChip(
                        icon: Icons.people_outline_rounded,
                        label: 'Friends',
                        theme: theme,
                      ),
                      const SizedBox(width: 8),
                      _buildActionChip(
                        icon: Icons.emoji_events_outlined,
                        label: 'Challenges',
                        theme: theme,
                      ),
                      const SizedBox(width: 8),
                      _buildActionChip(
                        icon: Icons.history_rounded,
                        label: 'Archive',
                        theme: theme,
                      ),
                      const SizedBox(width: 8),
                      _buildActionChip(
                        icon: Icons.bar_chart_rounded,
                        label: 'Stats',
                        theme: theme,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          deviceName,
          size,
        );
      });
    }
  });

  group('Game Screen Header Overflow Tests', () {
    // Test the game screen header row with title, timer, and buttons (very compact layout)
    for (final (deviceName, size) in DeviceSizes.phones) {
      testWidgets('Game header fits on $deviceName', (tester) async {
        await testOverflowAtSize(
          tester,
          Builder(
            builder: (context) {
              final theme = Theme.of(context);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: const EdgeInsets.all(6),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.help_outline_rounded, size: 20),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: const EdgeInsets.all(6),
                      onPressed: () {},
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sports_esports_rounded,
                                size: 14,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  'Killer Sudoku', // Longest game name
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              4, // 4 stars for expert difficulty
                              (index) => Icon(
                                Icons.star_rounded,
                                size: 10,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const GameTimer(seconds: 3599),
                        IconButton(
                          icon: const Icon(Icons.pause_rounded, size: 20),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: const EdgeInsets.all(4),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_rounded, size: 20),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: const EdgeInsets.all(4),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          deviceName,
          size,
        );
      });
    }
  });

  group('Home Screen Full Header Overflow Tests', () {
    // Test the full home screen header with date, token, and icon buttons
    for (final (deviceName, size) in DeviceSizes.phones) {
      testWidgets('Home full header fits on $deviceName', (tester) async {
        await testOverflowAtSize(
          tester,
          Builder(
            builder: (context) {
              final theme = Theme.of(context);
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top bar - Date and icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Wednesday, January 15', // Long date
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Token balance mock
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.toll_rounded, size: 16, color: Colors.amber),
                                  SizedBox(width: 4),
                                  Text('99', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // Icon buttons row
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded, size: 22),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.light_mode_rounded, size: 22),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.settings_rounded, size: 22),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Action chips row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildActionChip(
                            icon: Icons.people_outline_rounded,
                            label: 'Friends',
                            theme: theme,
                          ),
                          const SizedBox(width: 8),
                          _buildActionChip(
                            icon: Icons.emoji_events_outlined,
                            label: 'Challenges',
                            theme: theme,
                          ),
                          const SizedBox(width: 8),
                          _buildActionChip(
                            icon: Icons.history_rounded,
                            label: 'Archive',
                            theme: theme,
                          ),
                          const SizedBox(width: 8),
                          _buildActionChip(
                            icon: Icons.bar_chart_rounded,
                            label: 'Stats',
                            theme: theme,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          deviceName,
          size,
        );
      });
    }
  });

  group('Combined Game Layout Overflow Tests', () {
    // Test typical game screen layout: header + grid + number pad
    final puzzle = SudokuPuzzle(
      grid: List.generate(9, (_) => List.filled(9, null)),
      initialGrid: List.generate(9, (_) => List.filled(9, null)),
      solution: List.generate(9, (r) => List.generate(9, (c) => ((r * 3 + r ~/ 3 + c) % 9) + 1)),
      notes: List.generate(9, (_) => List.generate(9, (_) => <int>{})),
    );

    for (final (deviceName, size) in DeviceSizes.phones) {
      testWidgets('Game layout (header + grid + numberpad) fits on $deviceName', (tester) async {
        await testOverflowAtSize(
          tester,
          Builder(
            builder: (context) {
              final theme = Theme.of(context);
              return SingleChildScrollView(
                child: Column(
                  children: [
                    // Header (very compact layout)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded, size: 20),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            padding: const EdgeInsets.all(6),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.help_outline_rounded, size: 20),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            padding: const EdgeInsets.all(6),
                            onPressed: () {},
                          ),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Sudoku',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(
                                    2,
                                    (index) => Icon(
                                      Icons.star_rounded,
                                      size: 10,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const GameTimer(seconds: 125),
                              IconButton(
                                icon: const Icon(Icons.pause_rounded, size: 20),
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                padding: const EdgeInsets.all(4),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: const Icon(Icons.settings_rounded, size: 20),
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                padding: const EdgeInsets.all(4),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Grid
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SudokuGrid(
                        puzzle: puzzle,
                        onCellTap: (_, __) {},
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Number pad
                    NumberPad(
                      notesMode: false,
                      onNumberTap: (_) {},
                      onClearTap: () {},
                      onNotesTap: () {},
                      onHintTap: () {},
                      showCalculator: true,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
          deviceName,
          size,
        );
      });
    }
  });

  group('Crossword Game Layout Overflow Tests', () {
    // Test crossword screen layout with keyboard (very compact header)
    for (final (deviceName, size) in DeviceSizes.phones) {
      testWidgets('Crossword layout (header + keyboard) fits on $deviceName', (tester) async {
        await testOverflowAtSize(
          tester,
          Builder(
            builder: (context) {
              final theme = Theme.of(context);
              return SingleChildScrollView(
                child: Column(
                  children: [
                    // Header (very compact layout)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded, size: 20),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            padding: const EdgeInsets.all(6),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.help_outline_rounded, size: 20),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            padding: const EdgeInsets.all(6),
                            onPressed: () {},
                          ),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Crossword',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(
                                    3,
                                    (index) => Icon(
                                      Icons.star_rounded,
                                      size: 10,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const GameTimer(seconds: 300),
                              IconButton(
                                icon: const Icon(Icons.pause_rounded, size: 20),
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                padding: const EdgeInsets.all(4),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: const Icon(Icons.settings_rounded, size: 20),
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                padding: const EdgeInsets.all(4),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 200), // Placeholder for grid
                    // Keyboard
                    KeyboardInput(
                      onLetterTap: (_) {},
                      onDeleteTap: () {},
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
          deviceName,
          size,
        );
      });
    }
  });

  group('PuzzleCard Grid (Home Screen) Overflow Tests', () {
    // Test two puzzle cards side by side as they appear on home screen
    final puzzle1 = DailyPuzzle(
      id: 'test-1',
      gameType: GameType.killerSudoku,
      difficulty: Difficulty.expert,
      date: DateTime.now(),
      puzzleData: {},
    );
    final puzzle2 = DailyPuzzle(
      id: 'test-2',
      gameType: GameType.connections,
      difficulty: Difficulty.hard,
      date: DateTime.now(),
      puzzleData: {},
    );

    for (final (deviceName, size) in DeviceSizes.phones) {
      testWidgets('Puzzle card grid (2 columns) fits on $deviceName', (tester) async {
        await testOverflowAtSize(
          tester,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1.1,
                    child: PuzzleCard(
                      puzzle: puzzle1,
                      onTap: () {},
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1.1,
                    child: PuzzleCard(
                      puzzle: puzzle2,
                      onTap: () {},
                    ),
                  ),
                ),
              ],
            ),
          ),
          deviceName,
          size,
        );
      });
    }
  });
}

// Helper widget for testing action chips (mirrors HomeScreen._buildActionChip)
Widget _buildActionChip({
  required IconData icon,
  required String label,
  required ThemeData theme,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: theme.colorScheme.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: theme.colorScheme.primary.withValues(alpha: 0.2),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.primary),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}
