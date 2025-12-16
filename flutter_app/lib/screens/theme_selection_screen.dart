import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart' as app;

class ThemeSelectionScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const ThemeSelectionScreen({super.key, required this.onComplete});

  @override
  State<ThemeSelectionScreen> createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen> {
  app.ThemeMode? _selectedMode;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<app.ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    final backgroundColor = isDark ? const Color(0xFF0F1020) : const Color(0xFFF0EDE5);
    final surfaceColor = isDark ? const Color(0xFF1A1B2E) : const Color(0xFFFAFAFA);
    final textColor = isDark ? const Color(0xFFF5F5F5) : const Color(0xFF1A1A1A);
    final primaryColor = isDark ? const Color(0xFFE8B86D) : const Color(0xFF2D3A4A);
    final subtleTextColor = textColor.withOpacity(0.6);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Text(
                'Welcome to',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  color: subtleTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The Dailies',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'Choose your preferred theme',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  color: subtleTextColor,
                ),
              ),
              const SizedBox(height: 24),
              _ThemeOption(
                icon: Icons.light_mode_outlined,
                title: 'Light Mode',
                subtitle: 'Classic bright appearance',
                isSelected: _selectedMode == app.ThemeMode.light,
                surfaceColor: surfaceColor,
                textColor: textColor,
                primaryColor: primaryColor,
                onTap: () => _selectTheme(app.ThemeMode.light, themeProvider),
              ),
              const SizedBox(height: 16),
              _ThemeOption(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                subtitle: 'Easy on the eyes',
                isSelected: _selectedMode == app.ThemeMode.dark,
                surfaceColor: surfaceColor,
                textColor: textColor,
                primaryColor: primaryColor,
                onTap: () => _selectTheme(app.ThemeMode.dark, themeProvider),
              ),
              const SizedBox(height: 16),
              _ThemeOption(
                icon: Icons.settings_brightness_outlined,
                title: 'Follow Device',
                subtitle: 'Match your system settings',
                isSelected: _selectedMode == app.ThemeMode.system,
                surfaceColor: surfaceColor,
                textColor: textColor,
                primaryColor: primaryColor,
                onTap: () => _selectTheme(app.ThemeMode.system, themeProvider),
              ),
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedMode != null
                      ? () async {
                          await themeProvider.setThemeMode(_selectedMode!);
                          widget.onComplete();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: isDark ? const Color(0xFF0F1020) : const Color(0xFFFAFAFA),
                    disabledBackgroundColor: primaryColor.withOpacity(0.3),
                    disabledForegroundColor: textColor.withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'You can change this anytime in settings',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: subtleTextColor,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  void _selectTheme(app.ThemeMode mode, app.ThemeProvider provider) {
    setState(() {
      _selectedMode = mode;
    });
    // Preview the theme immediately
    provider.setThemeMode(mode);
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final Color surfaceColor;
  final Color textColor;
  final Color primaryColor;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.surfaceColor,
    required this.textColor,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : textColor.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor.withOpacity(0.1)
                    : textColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? primaryColor : textColor.withOpacity(0.6),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      color: textColor.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: primaryColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
