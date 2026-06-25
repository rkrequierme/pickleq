import 'package:flutter/material.dart';

class AppTheme {
  static const Color obsidianBg = Color(0xFF0B0D12);
  static const Color slateCard = Color(0xFF141923);
  static const Color slateCardHover = Color(0xFF1B2232);
  static const Color neonLime = Color(0xFFC6FF00); // Pickleball Lime
  static const Color electricTeal = Color(0xFF00F5FF);
  static const Color coralRed = Color(0xFFFF3D3D);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8A98A8);
  static const Color borderMuted = Color(0xFF222B3C);

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
          fontFamily: 'Outfit',
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.2,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: obsidianBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: textSecondary, fontSize: 14),
        labelStyle: const TextStyle(color: textPrimary, fontSize: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderMuted, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neonLime, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: coralRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: coralRed, width: 1.5),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonLime,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: neonLime,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: slateCard,
        selectedIconTheme: IconThemeData(color: neonLime, size: 26),
        unselectedIconTheme: IconThemeData(color: textSecondary, size: 22),
        selectedLabelTextStyle: TextStyle(
          color: neonLime,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'Outfit',
        ),
        unselectedLabelTextStyle: TextStyle(
          color: textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w400,
          fontFamily: 'Outfit',
        ),
        labelType: NavigationRailLabelType.all,
        useIndicator: false,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: slateCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: textSecondary,
        ),
      ),
    );
  }

  static BoxDecoration glassCard({
    Color? color,
    double radius = 16,
    double borderWidth = 1,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: color ?? slateCard.withOpacity(0.9),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? borderMuted,
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration glowingGlow({Color? color, double radius = 12}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: (color ?? neonLime).withOpacity(0.12),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
    );
  }
}
