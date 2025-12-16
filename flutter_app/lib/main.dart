import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'config/environment.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/game_service.dart';
import 'services/audio_service.dart';
import 'services/admob_service.dart';
import 'services/hint_service.dart';
import 'services/token_service.dart';
import 'services/purchase_service.dart';
import 'services/friends_service.dart';
import 'services/challenge_service.dart';
import 'services/consent_service.dart';
import 'providers/theme_provider.dart';
import 'providers/game_provider.dart';
import 'screens/home_screen.dart';
import 'screens/theme_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Print environment config in debug mode
  if (kDebugMode) {
    Environment.printConfig();
  }

  // Initialize Auth Service
  final authService = AuthService();
  await authService.initialize();

  // Initialize Consent Service (needed before AdMob for GDPR compliance)
  await ConsentService().initialize();

  // Initialize AdMob (will respect consent settings)
  await AdMobService().initialize();

  // Initialize Hint Service
  await HintService().initialize();

  // Initialize Token Service
  await TokenService().initialize();

  // Initialize Purchase Service
  await PurchaseService().initialize();

  // Initialize Audio Service
  await AudioService().initialize();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(TheDailiesApp(authService: authService));
}

class TheDailiesApp extends StatefulWidget {
  final AuthService authService;

  const TheDailiesApp({super.key, required this.authService});

  @override
  State<TheDailiesApp> createState() => _TheDailiesAppState();
}

class _TheDailiesAppState extends State<TheDailiesApp> {
  bool _themeSelectionComplete = false;

  void _onThemeSelectionComplete() {
    setState(() {
      _themeSelectionComplete = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: widget.authService),
        ProxyProvider<AuthService, ApiService>(
          update: (_, auth, __) => ApiService(authService: auth),
        ),
        ProxyProvider<AuthService, FriendsService>(
          update: (_, auth, __) => FriendsService(
            baseUrl: Environment.apiUrl,
            authService: auth,
          ),
        ),
        ProxyProvider<AuthService, ChallengeService>(
          update: (_, auth, __) => ChallengeService(
            baseUrl: Environment.apiUrl,
            authService: auth,
          ),
        ),
        ProxyProvider<ApiService, GameService>(
          update: (_, api, __) => GameService(api),
        ),
        ChangeNotifierProvider(create: (_) => GameProvider()),
        Provider(create: (_) => AudioService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          // Show loading while ThemeProvider initializes
          if (!themeProvider.isInitialized) {
            return MaterialApp(
              title: 'The Dailies',
              debugShowCheckedModeBanner: false,
              theme: _buildTheme(false),
              home: const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          }

          // Show theme selection on first launch
          final showThemeSelection =
              themeProvider.isFirstLaunch && !_themeSelectionComplete;

          return MaterialApp(
            title: 'The Dailies',
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(themeProvider.isDarkMode),
            home: showThemeSelection
                ? ThemeSelectionScreen(onComplete: _onThemeSelectionComplete)
                : const HomeScreen(),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(bool isDarkMode) {
    final baseTheme = isDarkMode ? ThemeData.dark() : ThemeData.light();
    
    final colorScheme = isDarkMode
        ? const ColorScheme.dark(
            primary: Color(0xFFE8B86D),
            secondary: Color(0xFF7ECFB3),
            surface: Color(0xFF1A1B2E),
            background: Color(0xFF0F1020),
            error: Color(0xFFCF6679),
            onPrimary: Color(0xFF0F1020),
            onSecondary: Color(0xFF0F1020),
            onSurface: Color(0xFFF5F5F5),
            onBackground: Color(0xFFF5F5F5),
          )
        : const ColorScheme.light(
            primary: Color(0xFF2D3A4A),
            secondary: Color(0xFF4A9B7F),
            surface: Color(0xFFFAFAFA),
            background: Color(0xFFF0EDE5),
            error: Color(0xFFB00020),
            onPrimary: Color(0xFFFAFAFA),
            onSecondary: Color(0xFFFAFAFA),
            onSurface: Color(0xFF1A1A1A),
            onBackground: Color(0xFF1A1A1A),
          );

    return baseTheme.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.background,
      textTheme: GoogleFonts.spaceGroteskTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          color: colorScheme.onBackground,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 36,
          fontWeight: FontWeight.w600,
          color: colorScheme.onBackground,
        ),
        headlineLarge: GoogleFonts.spaceGrotesk(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: colorScheme.onBackground,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: colorScheme.onBackground,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onBackground,
        ),
        bodyLarge: GoogleFonts.spaceGrotesk(
          fontSize: 16,
          color: colorScheme.onBackground,
        ),
        bodyMedium: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          color: colorScheme.onBackground,
        ),
        labelLarge: GoogleFonts.spaceMono(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colorScheme.onBackground,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onBackground),
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: colorScheme.onBackground,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.onBackground.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
