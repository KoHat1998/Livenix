import 'package:flutter/material.dart';

class AppTheme {
  // Tokens
  static const bg = Color(0xFF0E0F13);
  static const surface = Color(0xFF171A1F);
  static const surfaceVariant = Color(0xFF1D2128);
  static const primary = Color(0xFF7C3AED);
  static const pink = Color(0xFFEC4899);
  static const accent = Color(0xFF3B82F6);
  static const danger = Color(0xFFEF4444);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF9AA3B2);
  static const liveRed = Color(0xFFFF375F);

  static ThemeData darkThemeData({TextTheme? textTheme}) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: primary,
      scaffoldBackgroundColor: bg,
    );

    return base.copyWith(
      scaffoldBackgroundColor: bg,
      primaryColor: primary,

      // Text
      textTheme: (textTheme ?? base.textTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        hintStyle: const TextStyle(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary),
        ),
      ),

      // App bar
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
      ),

      // Cards  ✅ use CardThemeData (not CardTheme)
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Chips
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surfaceVariant,
        labelStyle: const TextStyle(color: textPrimary),
      ),
    );
  }

  static LinearGradient primaryGradient = const LinearGradient(
    colors: [primary, pink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
