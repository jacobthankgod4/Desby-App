import 'package:flutter/material.dart';
import 'typography.dart';

class AppTheme {
  AppTheme._();

  static const Color _trueDarkNavy = Color(0xFF0A1921);
  static const Color _desbyAmber = Color(0xFFFFC107);
  static const Color _softWhite = Color(0xFFF8F9FA);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: _desbyAmber,
        onPrimary: _trueDarkNavy,
        secondary: _desbyAmber,
        surface: Colors.white,
        onSurface: _trueDarkNavy,
        error: Colors.redAccent,
      ),
      scaffoldBackgroundColor: _softWhite,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: _trueDarkNavy,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: _trueDarkNavy),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.black12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _desbyAmber,
          foregroundColor: _trueDarkNavy,
          textStyle: AppTypography.button.copyWith(fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _desbyAmber, width: 2),
        ),
        labelStyle: const TextStyle(color: Colors.black38),
        prefixIconColor: _desbyAmber,
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.black12,
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: _desbyAmber,
        onPrimary: _trueDarkNavy,
        secondary: _desbyAmber,
        surface: _trueDarkNavy,
        onSurface: Colors.white,
        error: Colors.redAccent,
      ),
      scaffoldBackgroundColor: _trueDarkNavy,
      appBarTheme: const AppBarTheme(
        backgroundColor: _trueDarkNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.03),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _desbyAmber,
          foregroundColor: _trueDarkNavy,
          textStyle: AppTypography.button.copyWith(fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _desbyAmber, width: 2),
        ),
        labelStyle: const TextStyle(color: Colors.white38),
        prefixIconColor: _desbyAmber,
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.white12,
        thickness: 1,
      ),
    );
  }
}
