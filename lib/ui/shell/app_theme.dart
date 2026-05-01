import 'package:flutter/material.dart';

class AppTheme {
  static const _bgColor = Color(0xFF0D1117);
  static const _surfaceColor = Color(0xFF161B22);
  static const _borderColor = Color(0xFF30363D);
  static const _accentColor = Color(0xFF58A6FF);
  static const _textPrimary = Color(0xFFE6EDF3);
  static const _textSecondary = Color(0xFF8B949E);

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _bgColor,
      colorScheme: const ColorScheme.dark(
        surface: _surfaceColor,
        primary: _accentColor,
        onSurface: _textPrimary,
        onPrimary: Colors.black,
        outline: _borderColor,
        error: Color(0xFFF85149),
      ),
      cardTheme: CardThemeData(
        color: _surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: _borderColor),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _bgColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _accentColor),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        hintStyle: const TextStyle(color: _textSecondary, fontSize: 13),
        labelStyle: const TextStyle(color: _textSecondary, fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _textPrimary,
          side: const BorderSide(color: _borderColor),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6)),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
            color: _textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(
            color: _textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(
            color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
        bodyMedium:
            TextStyle(color: _textPrimary, fontSize: 13),
        bodySmall: TextStyle(color: _textSecondary, fontSize: 12),
        labelSmall: TextStyle(
            color: _textSecondary,
            fontSize: 11,
            letterSpacing: 0.5),
      ),
      dividerTheme: const DividerThemeData(
          color: _borderColor, thickness: 1, space: 0),
    );
  }

  // Status colors
  static const colorSuccess = Color(0xFF3FB950);
  static const colorError = Color(0xFFF85149);
  static const colorWarning = Color(0xFFD29922);
  static const colorRunning = Color(0xFF58A6FF);
  static const colorSkipped = Color(0xFF8B949E);
  static const colorPending = Color(0xFF30363D);

  // Log level colors
  static const logInfo = Color(0xFFE6EDF3);
  static const logError = Color(0xFFF85149);
  static const logWarning = Color(0xFFD29922);
  static const logSuccess = Color(0xFF3FB950);
  static const logDebug = Color(0xFF8B949E);

  static const fontMono = 'monospace';
}
