import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors - Deep Navy Blue (Xanh nước biển đậm) as main, with Liverpool Gold/Teal/Red accents
  static const Color primaryNavy = Color(0xFF0A192F);       // Deep Navy background (Xanh nước biển đậm)
  static const Color surfaceNavy = Color(0xFF112240);       // Surface / Card Deep Navy
  static const Color surfaceNavyLight = Color(0xFF1E3A5F);  // Elevated Surface Navy Light
  
  // Backwards compatible aliases mapping to Deep Navy surfaces
  static const Color bgDark = primaryNavy;
  static const Color bgCard = surfaceNavy;
  static const Color bgCardLight = surfaceNavyLight;
  
  static const Color accentCyan = Color(0xFF64FFDA);        // Vibrant Aqua / Cyan accent
  static const Color accentBlue = Color(0xFF1E88E5);        // Royal Blue
  
  // Accents & Brand Elements
  static const Color lfcRed = Color(0xFFE63946);           // Signature LFC Red highlight
  static const Color lfcDarkRed = Color(0xFF9B0A22);
  static const Color lfcYellow = Color(0xFFFFD166);        // Gold / Yellow highlight
  static const Color lfcTeal = Color(0xFF00B2A9);          // Liverpool Liverbird Teal
  
  // Text colors
  static const Color textPrimary = Color(0xFFE2E8F0);      // High contrast crisp text
  static const Color textSecondary = Color(0xFF94A3B8);    // Soft Slate Gray
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderSubtle = Color(0xFF233554);     // Deep navy border

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF38BDF8);
  static const Color adidasBlack = Color(0xFF0B0F17);

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
}
