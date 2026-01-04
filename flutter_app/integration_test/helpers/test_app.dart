import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:puzzle_daily/providers/game_provider.dart';
import 'package:puzzle_daily/providers/theme_provider.dart';
import 'package:puzzle_daily/services/auth_service.dart';

/// A test wrapper widget that provides all necessary providers for integration tests
class TestApp extends StatelessWidget {
  final Widget child;
  final AuthService? authService;
  final GameProvider? gameProvider;
  final ThemeProvider? themeProvider;

  const TestApp({
    super.key,
    required this.child,
    this.authService,
    this.gameProvider,
    this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => themeProvider ?? ThemeProvider(),
        ),
        ChangeNotifierProvider<GameProvider>(
          create: (_) => gameProvider ?? GameProvider(),
        ),
        if (authService != null)
          ChangeNotifierProvider<AuthService>.value(value: authService!),
      ],
      child: MaterialApp(
        title: 'The Dailies - Test',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        home: child,
      ),
    );
  }
}

/// Simple test wrapper without providers for isolated widget tests
class SimpleTestApp extends StatelessWidget {
  final Widget child;
  final bool darkMode;

  const SimpleTestApp({
    super.key,
    required this.child,
    this.darkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test',
      debugShowCheckedModeBanner: false,
      theme: darkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(body: child),
    );
  }
}

/// Extension to help with pump and settling animations
extension WidgetTesterExtension on Object {
  /// Waits for animations to complete
  Future<void> pumpAndSettle(dynamic tester, {Duration timeout = const Duration(seconds: 10)}) async {
    await (tester as dynamic).pumpAndSettle(timeout);
  }
}
