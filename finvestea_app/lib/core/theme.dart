import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Finvestea Official Colors - Blue Theme
  static const Color primaryColor = Color(0xFF3FA9FF); // Primary Blue
  static const Color secondaryAccentColor = Color(0xFF7BD3FF); // Secondary Blue
  static const Color highlightColor = Color(0xFF4C8DFF); // Highlight Blue
  static const Color backgroundColorStart = Color(0xFF0A1A2F); // Deep Navy
  static const Color backgroundColorEnd = Color(0xFF142B4D); // Navy Blue
  static const Color backgroundColor = Color(0xFF0A1A2F);
  static const Color surfaceColor = Color(
    0x19FFFFFF,
  ); // Glass Card Background (0.1 alpha white)
  static const Color textPrimary = Color(0xFFFFFFFF); // White
  static const Color textSecondary = Color(0xFFA7B8D9); // Light Blue-Gray

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor:
          Colors.transparent, // We'll use gradient in Scaffold
      // Disable all splash / ripple / hover overlay effects app-wide
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryAccentColor,
        surface: surfaceColor,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.manropeTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: textPrimary, displayColor: textPrimary),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          elevation: 0,
          splashFactory: NoSplash.splashFactory,
          overlayColor: Colors.transparent,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          splashFactory: NoSplash.splashFactory,
          overlayColor: Colors.transparent,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          splashFactory: NoSplash.splashFactory,
          overlayColor: Colors.transparent,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
      ),
    );
  }

  static BoxDecoration get mainGradient => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [backgroundColorStart, backgroundColorEnd],
    ),
  );

  static BoxDecoration get glassDecoration => BoxDecoration(
    color: surfaceColor,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
    boxShadow: [
      BoxShadow(
        color: primaryColor.withValues(alpha: 0.1),
        blurRadius: 20,
        spreadRadius: 2,
      ),
    ],
  );
}
