import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color focusRed = Color(0xFFFF6B6B);
  static const Color focusRedLight = Color(0xFFFF8E8E);
  static const Color focusRedLighter = Color(0xFFFFA5A5);
  
  static const Color breakGreen = Color(0xFF4ECDC4);
  static const Color breakGreenLight = Color(0xFF6ED9D0);
  static const Color breakGreenLighter = Color(0xFF8FE5DD);
  
  static const Color longBreakPurple = Color(0xFFA78BFA);
  static const Color longBreakPurpleLight = Color(0xFFC4B5FD);
  static const Color longBreakPurpleLighter = Color(0xFFDDD6FE);
  
  static const Color backgroundColor = Color(0xFFF7F8FA);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);
  static const Color accentOrange = Color(0xFFF59E0B);
  
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningYellow = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);

  static LinearGradient getFocusGradient() {
    return const LinearGradient(
      colors: [focusRed, focusRedLight, focusRedLighter],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient getBreakGradient() {
    return const LinearGradient(
      colors: [breakGreen, breakGreenLight, breakGreenLighter],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient getLongBreakGradient() {
    return const LinearGradient(
      colors: [longBreakPurple, longBreakPurpleLight, longBreakPurpleLighter],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: focusRed,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 72,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -2,
        ),
        displayMedium: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textSecondary,
        ),
      ),
    );
  }
}
