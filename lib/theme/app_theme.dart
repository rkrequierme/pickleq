import 'package:flutter/material.dart';

class AppTheme {
  // Material 3 Clean Dark Palette
  static const Color obsidianBg = Color(0xFF121212); // Standard dark background
  static const Color slateCard = Color(0xFF1E1E1E); // Elevated surface card
  static const Color slateCardHover = Color(0xFF252525);
  static const Color neonLime = Color(0xFFC6FF00); // Main brand primary
  static const Color electricTeal = Color(0xFF00E5FF);
  static const Color coralRed = Color(0xFFCF6679); // M3 Dark error color
  static const Color textPrimary = Color(0xFFE1E1E1);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color borderMuted = Color(0xFF2C2C2C); // Solid thin border

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: obsidianBg,
      cardColor: slateCard,
      dividerColor: borderMuted,
      
      colorScheme: const ColorScheme.dark(
        primary: neonLime,
        secondary: electricTeal,
        error: coralRed,
        surface: slateCard,
        onSurface: textPrimary,
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: obsidianBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: textSecondary, fontSize: 13),
        labelStyle: const TextStyle(color: textPrimary, fontSize: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderMuted, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: neonLime, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: coralRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: coralRed, width: 1.5),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonLime,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: neonLime,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: slateCard,
        selectedIconTheme: IconThemeData(color: neonLime, size: 24),
        unselectedIconTheme: IconThemeData(color: textSecondary, size: 20),
        selectedLabelTextStyle: TextStyle(
          color: neonLime,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
        unselectedLabelTextStyle: TextStyle(
          color: textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.normal,
          fontFamily: 'Inter',
        ),
        labelType: NavigationRailLabelType.all,
        useIndicator: false,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: slateCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titleTextStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: textSecondary,
        ),
      ),
    );
  }

  // Overwritten helper: Returns a flat card box decoration (replaces glassmorphism)
  static BoxDecoration glassCard({
    Color? color,
    double radius = 12,
    double borderWidth = 1,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: color ?? slateCard,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? borderMuted,
        width: borderWidth,
      ),
    );
  }

  // Overwritten helper: Returns a flat border radius without glowing shadows
  static BoxDecoration glowingGlow({Color? color, double radius = 8}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: (color ?? neonLime).withOpacity(0.3),
        width: 1,
      ),
    );
  }
}
