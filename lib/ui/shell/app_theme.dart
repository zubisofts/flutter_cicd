import 'package:flutter/material.dart';

class AppTheme {
  // ── Dark (GitHub dark) ────────────────────────────────────────────────────
  static const _darkBg = Color(0xFF0D1117);
  static const _darkSurface = Color(0xFF161B22);
  static const _darkBorder = Color(0xFF30363D);
  static const _darkAccent = Color(0xFF58A6FF);
  static const _darkTextPrimary = Color(0xFFE6EDF3);
  static const _darkTextSecondary = Color(0xFF8B949E);

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkBg,
      colorScheme: const ColorScheme.dark(
        surface: _darkSurface,
        primary: _darkAccent,
        onSurface: _darkTextPrimary,
        onSurfaceVariant: _darkTextSecondary,
        onPrimary: Colors.black,
        outline: _darkBorder,
        error: Color(0xFFF85149),
      ),
      cardTheme: CardThemeData(
        color: _darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: _darkBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _darkAccent),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        hintStyle: const TextStyle(color: _darkTextSecondary, fontSize: 13),
        labelStyle: const TextStyle(color: _darkTextSecondary, fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkAccent,
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
          foregroundColor: _darkTextPrimary,
          side: const BorderSide(color: _darkBorder),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6)),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
            color: _darkTextPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(
            color: _darkTextPrimary, fontSize: 15, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(
            color: _darkTextPrimary, fontSize: 13, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(color: _darkTextPrimary, fontSize: 13),
        bodySmall: TextStyle(color: _darkTextSecondary, fontSize: 12),
        labelSmall: TextStyle(
            color: _darkTextSecondary,
            fontSize: 11,
            letterSpacing: 0.5),
      ),
      dividerTheme: const DividerThemeData(
          color: _darkBorder, thickness: 1, space: 0),
    );
  }

  // ── Light (GitHub light) ──────────────────────────────────────────────────
  static const _lightBg = Color(0xFFFFFFFF);
  static const _lightSurface = Color(0xFFF6F8FA);
  static const _lightBorder = Color(0xFFD0D7DE);
  static const _lightAccent = Color(0xFF0969DA);
  static const _lightTextPrimary = Color(0xFF24292F);
  static const _lightTextSecondary = Color(0xFF57606A);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _lightBg,
      colorScheme: const ColorScheme.light(
        surface: _lightSurface,
        primary: _lightAccent,
        onSurface: _lightTextPrimary,
        onSurfaceVariant: _lightTextSecondary,
        onPrimary: Colors.white,
        outline: _lightBorder,
        error: Color(0xFFCF222E),
      ),
      cardTheme: CardThemeData(
        color: _lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: _lightBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _lightAccent),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        hintStyle:
            const TextStyle(color: _lightTextSecondary, fontSize: 13),
        labelStyle:
            const TextStyle(color: _lightTextSecondary, fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6)),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _lightTextPrimary,
          side: const BorderSide(color: _lightBorder),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6)),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
            color: _lightTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600),
        titleMedium: TextStyle(
            color: _lightTextPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600),
        titleSmall: TextStyle(
            color: _lightTextPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(color: _lightTextPrimary, fontSize: 13),
        bodySmall:
            TextStyle(color: _lightTextSecondary, fontSize: 12),
        labelSmall: TextStyle(
            color: _lightTextSecondary,
            fontSize: 11,
            letterSpacing: 0.5),
      ),
      dividerTheme: const DividerThemeData(
          color: _lightBorder, thickness: 1, space: 0),
    );
  }

  // ── Status colors (same for both themes) ──────────────────────────────────
  static const colorSuccess = Color(0xFF3FB950);
  static const colorError = Color(0xFFF85149);
  static const colorWarning = Color(0xFFD29922);
  static const colorRunning = Color(0xFF58A6FF);
  static const colorSkipped = Color(0xFF8B949E);
  static const colorPending = Color(0xFF30363D);

  // ── Log level colors ──────────────────────────────────────────────────────
  static const logInfo = Color(0xFFE6EDF3);
  static const logError = Color(0xFFF85149);
  static const logWarning = Color(0xFFD29922);
  static const logSuccess = Color(0xFF3FB950);
  static const logDebug = Color(0xFF8B949E);

  static const fontMono = 'monospace';
}

