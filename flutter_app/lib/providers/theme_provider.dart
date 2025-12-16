import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeMode { light, dark, system }

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isFirstLaunch = true;
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get isFirstLaunch => _isFirstLaunch;
  bool get isInitialized => _isInitialized;

  // Returns true if the app should display in dark mode
  bool get isDarkMode {
    switch (_themeMode) {
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
      case ThemeMode.system:
        // Follow device theme
        final brightness =
            SchedulerBinding.instance.platformDispatcher.platformBrightness;
        return brightness == Brightness.dark;
    }
  }

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if theme has been set before (not first launch)
    _isFirstLaunch = !prefs.containsKey('themeMode');

    if (!_isFirstLaunch) {
      final themeModeString = prefs.getString('themeMode') ?? 'system';
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == themeModeString,
        orElse: () => ThemeMode.system,
      );
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    _isFirstLaunch = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.name);

    notifyListeners();
  }

  // Legacy toggle method for backwards compatibility
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }

  // Mark first launch as complete without changing theme
  Future<void> completeFirstLaunch() async {
    _isFirstLaunch = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', _themeMode.name);
    notifyListeners();
  }
}
