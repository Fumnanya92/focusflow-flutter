import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color Palette - CORRECTED based on ALL mockups
  static const Color primary = Color(0xFF19E66B); // Bright green (main brand)
  static const Color primaryTeal = Color(0xFF2DD4BF); // Teal/cyan for buttons
  static const Color primaryOrange = Color(0xFFF59E0B); // Orange for fire/streaks
  
  // Background Colors
  static const Color backgroundDark = Color(0xFF0A1111); // Very dark background
  static const Color backgroundDarkAlt = Color(0xFF0F1613); 
  
  // Card/Surface Colors - Navy blue tinted
  static const Color surfaceDark = Color(0xFF1E293B); // Navy card background
  static const Color surfaceDarkAlt = Color(0xFF334155); // Slightly lighter
  static const Color surfaceVeryDark = Color(0xFF0F172A); // Very dark navy
  
  // Text Colors
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGray = Color(0xFF9CA3AF);
  static const Color textGrayLight = Color(0xFFD1D5DB);
  static const Color textGrayDark = Color(0xFF6B7280);
  static const Color textTeal = Color(0xFF5EEAD4);
  static const Color textGreen = Color(0xFF6EE7A0);
  
  // Button Colors
  static const Color buttonPrimary = Color(0xFF19E66B); // Bright green
  static const Color buttonTeal = Color(0xFF2DD4BF); // Teal for special actions
  static const Color buttonSecondary = Color(0xFF334155); // Gray/navy
  static const Color buttonDanger = Color(0xFFEF4444);
  
  // Border Colors (very subtle)
  static const Color borderDark = Color(0xFF1F2937);
  static const Color borderGreen = Color(0xFF2D4A3E);
  static const Color borderNavy = Color(0xFF334155);
  
  // Status/Badge Colors
  static const Color badgeGreen = Color(0xFF10B981);
  static const Color badgeOrange = Color(0xFFF59E0B);
  static const Color badgeBlue = Color(0xFF3B82F6);
  static const Color badgePurple = Color(0xFF8B5CF6);
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Additional theme colors for compatibility
  static const Color textPrimary = textWhite;
  static const Color textSecondary = textGray;
  static const Color surfaceLight = Color(0xFFF4F5F4);
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color borderLight = Color(0xFFE4E4E7);

  // Dark Theme (Main theme)
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primary,
    scaffoldBackgroundColor: backgroundDark,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: primaryTeal,
      surface: surfaceDark,
      error: error,
      onPrimary: backgroundDark,
      onSecondary: backgroundDark,
      onSurface: textWhite,
      onError: textWhite,
    ),
    
    // Typography
    textTheme: GoogleFonts.plusJakartaSansTextTheme(
      const TextTheme(
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w800,
          color: textWhite,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w800,
          color: textWhite,
          letterSpacing: -0.5,
        ),
        displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: textWhite,
          letterSpacing: -0.5,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textWhite,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textWhite,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textWhite,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textWhite,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textWhite,
        ),
        titleSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textWhite,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textWhite,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textGrayLight,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textGray,
        ),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textWhite,
        ),
        labelMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textWhite,
        ),
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textGray,
        ),
      ),
    ),
    
    // AppBar Theme
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: backgroundDark,
      foregroundColor: textWhite,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textWhite,
      ),
    ),
    
    // Card Theme
    cardTheme: const CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      color: surfaceDark,
    ),
    
    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: primary,
        foregroundColor: backgroundDark,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
        minimumSize: const Size(double.infinity, 56),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    
    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: BorderSide(color: primary.withValues(alpha: 0.5), width: 1.5),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
        minimumSize: const Size(double.infinity, 56),
      ),
    ),
    
    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: textGray,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
      ),
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: borderNavy, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: borderNavy, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      hintStyle: TextStyle(color: textGray.withValues(alpha: 0.6)),
      labelStyle: const TextStyle(color: textGrayLight),
      // Ensure text is always visible
      floatingLabelStyle: const TextStyle(color: primary),
      prefixIconColor: textGrayLight,
      suffixIconColor: textGrayLight,
    ),
    
    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: backgroundDark,
      selectedItemColor: primaryTeal, // Teal for active
      unselectedItemColor: textGray,
      elevation: 0,
      selectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
    
    // FAB Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: backgroundDark,
      elevation: 4,
    ),
  );

  // Light Theme (minimal - app is primarily dark)
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primary,
    scaffoldBackgroundColor: const Color(0xFFF9FAFB),
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: primaryTeal,
      surface: Color(0xFFFFFFFF),
      error: error,
      onPrimary: backgroundDark,
      onSecondary: backgroundDark,
      onSurface: Color(0xFF111827),
      onError: textWhite,
    ),
  );

  // Border Radius Constants
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusXLarge = 32.0;
  static const double radiusFull = 9999.0;

  // Spacing Constants
  static const double spaceXSmall = 4.0;
  static const double spaceSmall = 8.0;
  static const double spaceMedium = 16.0;
  static const double spaceLarge = 24.0;
  static const double spaceXLarge = 32.0;
  static const double spaceXXLarge = 48.0;
}
