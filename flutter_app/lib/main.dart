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
import 'services/firebase_service.dart';
import 'services/remote_config_service.dart';
import 'services/notification_service.dart';
import 'services/achievements_service.dart';
import 'services/dictionary_service.dart';
import 'services/logging_service.dart';
import 'providers/theme_provider.dart';
import 'providers/game_provider.dart';
import 'screens/home_screen.dart';
import 'screens/theme_selection_screen.dart';
import 'widgets/version_dialogs.dart';
import 'widgets/shake_feedback_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final log = LoggingService();

  // Print environment config in debug mode
  if (kDebugMode) {
    Environment.printConfig();
  }

  log.info('App starting', tag: 'Init');

  // Initialize Firebase Core (must be first)
  try {
    await FirebaseService().initialize();
    log.logServiceInit('Firebase');
  } catch (e) {
    log.logServiceInit('Firebase', success: false, error: e.toString());
  }

  // Initialize Auth Service
  final authService = AuthService();
  try {
    await authService.initialize();
    log.logServiceInit('AuthService');
    if (authService.currentUser != null) {
      log.setUserContext(
        userId: authService.currentUser!.id,
        email: authService.currentUser!.email,
        isAnonymous: false,
      );
    } else {
      log.setUserContext(isAnonymous: true);
    }
  } catch (e) {
    log.logServiceInit('AuthService', success: false, error: e.toString());
  }

  // Initialize Consent Service (needed before AdMob/Crashlytics for GDPR compliance)
  try {
    await ConsentService().initialize();
    log.logServiceInit('ConsentService');
  } catch (e) {
    log.logServiceInit('ConsentService', success: false, error: e.toString());
  }

  // Initialize Crashlytics (respects consent settings)
  try {
    await FirebaseService().initializeCrashlytics();
    log.logServiceInit('Crashlytics');
  } catch (e) {
    log.logServiceInit('Crashlytics', success: false, error: e.toString());
  }

  // Initialize AdMob (will respect consent settings)
  try {
    await AdMobService().initialize();
    log.logServiceInit('AdMob');
  } catch (e) {
    log.logServiceInit('AdMob', success: false, error: e.toString());
  }

  // Initialize Remote Config Service (replaces backend config)
  try {
    await RemoteConfigService().initialize();
    log.logServiceInit('RemoteConfig');
  } catch (e) {
    log.logServiceInit('RemoteConfig', success: false, error: e.toString());
  }

  // Initialize FCM and Notification Service
  try {
    await FirebaseService().initializeFCM();
    log.logServiceInit('FCM');
  } catch (e) {
    log.logServiceInit('FCM', success: false, error: e.toString());
  }

  try {
    await NotificationService().initialize();
    log.logServiceInit('NotificationService');
  } catch (e) {
    log.logServiceInit('NotificationService', success: false, error: e.toString());
  }

  // Initialize Hint Service
  try {
    await HintService().initialize();
    log.logServiceInit('HintService');
  } catch (e) {
    log.logServiceInit('HintService', success: false, error: e.toString());
  }

  // Initialize Token Service
  try {
    await TokenService().initialize();
    log.logServiceInit('TokenService');
  } catch (e) {
    log.logServiceInit('TokenService', success: false, error: e.toString());
  }

  // Initialize Purchase Service
  try {
    await PurchaseService().initialize();
    log.logServiceInit('PurchaseService');
  } catch (e) {
    log.logServiceInit('PurchaseService', success: false, error: e.toString());
  }

  // Initialize Audio Service
  try {
    await AudioService().initialize();
    log.logServiceInit('AudioService');
  } catch (e) {
    log.logServiceInit('AudioService', success: false, error: e.toString());
  }

  // Initialize Achievements Service
  try {
    await AchievementsService().initialize();
    log.logServiceInit('AchievementsService');
  } catch (e) {
    log.logServiceInit('AchievementsService', success: false, error: e.toString());
  }

  // Initialize Dictionary Service (load from cache/assets first)
  try {
    await DictionaryService().load();
    log.logServiceInit('DictionaryService', success: true);
    log.info('Dictionary loaded: ${DictionaryService().wordCount} words', tag: 'Dictionary');
  } catch (e) {
    log.logServiceInit('DictionaryService', success: false, error: e.toString());
  }

  // Sync dictionary in background (non-blocking)
  DictionaryService().syncFromServer().then((updated) {
    if (updated) {
      log.info('Dictionary synced from server: ${DictionaryService().wordCount} words', tag: 'Dictionary');
    }
  }).catchError((e) {
    log.warning('Dictionary sync failed: $e', tag: 'Dictionary');
  });

  log.info('App initialization complete', tag: 'Init');

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
  final RemoteConfigService _configService = RemoteConfigService();

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
            builder: (context, child) {
              // Wrap all screens with shake-to-report functionality
              return ShakeFeedbackWrapper(
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: showThemeSelection
                ? ThemeSelectionScreen(onComplete: _onThemeSelectionComplete)
                : _VersionCheckWrapper(
                    configService: _configService,
                    child: const HomeScreen(),
                  ),
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
            color: colorScheme.onSurface.withValues(alpha: 0.1),
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

/// Wrapper widget that checks app version on startup and shows appropriate dialogs
class _VersionCheckWrapper extends StatefulWidget {
  final RemoteConfigService configService;
  final Widget child;

  const _VersionCheckWrapper({
    required this.configService,
    required this.child,
  });

  @override
  State<_VersionCheckWrapper> createState() => _VersionCheckWrapperState();
}

class _VersionCheckWrapperState extends State<_VersionCheckWrapper> {
  @override
  void initState() {
    super.initState();
    // Perform version check after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVersion();
    });
  }

  Future<void> _checkVersion() async {
    final status = widget.configService.checkVersionStatus();
    final config = widget.configService.appConfig;

    // Check maintenance mode first
    if (config.maintenanceMode) {
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => MaintenanceDialog(config: config),
        );
      }
      return; // Stay blocked
    }

    // Check for force update (non-dismissable)
    if (status == VersionStatus.forceUpdate) {
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => ForceUpdateDialog(
            config: config,
            currentVersion: widget.configService.currentVersion,
          ),
        );
      }
      return; // Stay blocked
    }

    // Check for optional update (dismissable)
    if (status == VersionStatus.updateAvailable) {
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: true,
          builder: (_) => UpdateAvailableDialog(
            config: config,
            currentVersion: widget.configService.currentVersion,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always show the child, dialogs will overlay when needed
    return widget.child;
  }
}
