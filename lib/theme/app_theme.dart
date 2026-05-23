import 'package:flutter/material.dart';
import 'typography.dart';

class AppTheme {
  AppTheme._();

  static const Color _trueDarkNavy = Color(0xFF0A1921);
  static const Color _desbyAmber = Color(0xFFFFC107);

  static ThemeData get lightTheme => _darkThemeTemplate;
  static ThemeData get darkTheme => _darkThemeTemplate;

  static ThemeData get _darkThemeTemplate {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: _desbyAmber,
        onPrimary: _trueDarkNavy,
        secondary: _desbyAmber,
        surface: _trueDarkNavy,
        error: Colors.redAccent,
      ),
      scaffoldBackgroundColor: _trueDarkNavy,
      appBarTheme: const AppBarTheme(
        backgroundColor: _trueDarkNavy,
        foregroundColor: Colors.white,
        elevation: 0,
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
        labelStyle: const TextStyle(color: Colors.white38),
        prefixIconColor: _desbyAmber,
      ),
    );
  }
}
