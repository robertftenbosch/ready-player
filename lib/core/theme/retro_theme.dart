import 'package:flutter/material.dart';
import 'retro_colors.dart';

class RetroTheme {
  RetroTheme._();

  static const _fontFamily = 'PressStart2P';

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: RetroColors.background,
      fontFamily: _fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: RetroColors.primary,
        secondary: RetroColors.secondary,
        error: RetroColors.accent,
        surface: RetroColors.surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: RetroColors.surface,
        foregroundColor: RetroColors.primary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 12,
          color: RetroColors.primary,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 16,
          color: RetroColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 14,
          color: RetroColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 10,
          color: RetroColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 8,
          color: RetroColors.textSecondary,
        ),
        bodySmall: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 6,
          color: RetroColors.textMuted,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RetroColors.surface,
          foregroundColor: RetroColors.primary,
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 8,
          ),
          shape: const RoundedRectangleBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
