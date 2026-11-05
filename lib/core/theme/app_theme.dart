import 'package:flutter/material.dart';

class AppTheme {

  static const Color primaryNavy = Color(0xFF0A192F);
  static const Color surfaceNavy = Color(0xFF112240);
  static const Color surfaceNavyLight = Color(0xFF1E3A5F);

  static const Color primaryLightBg = Color(0xFFF1F5F9);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceLightElevated = Color(0xFFE2E8F0);
  static const Color textDarkPrimary = Color(0xFF0F172A);
  static const Color textDarkSecondary = Color(0xFF475569);
  static const Color borderLight = Color(0xFFCBD5E1);

  static const Color bgDark = primaryNavy;
  static const Color bgCard = surfaceNavy;
  static const Color bgCardLight = surfaceNavyLight;

  static const Color accentCyan = Color(0xFF64FFDA);
  static const Color accentBlue = Color(0xFF1E88E5);

  static const Color lfcRed = Color(0xFFE63946);
  static const Color lfcDarkRed = Color(0xFF9B0A22);
  static const Color lfcYellow = Color(0xFFFFD166);
  static const Color accentGold = Color(0xFFFFD166);
  static const Color lfcTeal = Color(0xFF00B2A9);

  static const Color textPrimary = Color(0xFFE2E8F0);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderSubtle = Color(0xFF233554);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF38BDF8);
  static const Color adidasBlack = Color(0xFF0B0F17);

  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
  static Color cardColor(BuildContext context) => isDark(context) ? surfaceNavy : surfaceLight;
  static Color bgColor(BuildContext context) => isDark(context) ? primaryNavy : primaryLightBg;
  static Color textColor(BuildContext context) => isDark(context) ? textPrimary : textDarkPrimary;
  static Color subtextColor(BuildContext context) => isDark(context) ? textSecondary : textDarkSecondary;
  static Color borderColor(BuildContext context) => isDark(context) ? borderSubtle : borderLight;
  static Color surfaceLightColor(BuildContext context) => isDark(context) ? surfaceNavyLight : surfaceLightElevated;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryNavy,
      primaryColor: accentBlue,
      colorScheme: const ColorScheme.dark(
        primary: accentBlue,
        secondary: accentCyan,
        surface: surfaceNavy,
        error: danger,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryNavy,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surfaceNavy,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderSubtle, width: 1.0),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceNavyLight,
        selectedColor: accentBlue.withValues(alpha: 0.4),
        secondarySelectedColor: accentBlue,
        labelStyle: const TextStyle(fontSize: 12, color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: surfaceNavy,
        selectedIconTheme: IconThemeData(color: accentCyan),
        unselectedIconTheme: IconThemeData(color: textSecondary),
        selectedLabelTextStyle: TextStyle(
          color: accentCyan,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: textSecondary,
          fontSize: 12,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceNavyLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentCyan, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: primaryLightBg,
      primaryColor: lfcRed,
      colorScheme: const ColorScheme.light(
        primary: lfcRed,
        secondary: lfcTeal,
        surface: surfaceLight,
        error: danger,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textDarkPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceLight,
        elevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textDarkPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: textDarkPrimary),
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight, width: 1.0),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceLightElevated,
        selectedColor: lfcRed.withValues(alpha: 0.15),
        secondarySelectedColor: lfcRed,
        labelStyle: const TextStyle(fontSize: 12, color: textDarkPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: surfaceLight,
        selectedIconTheme: IconThemeData(color: lfcRed),
        unselectedIconTheme: IconThemeData(color: textDarkSecondary),
        selectedLabelTextStyle: TextStyle(
          color: lfcRed,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: textDarkSecondary,
          fontSize: 12,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lfcRed, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
      ),
    );
  }
}
