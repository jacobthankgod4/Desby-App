import 'package:flutter/material.dart';

/// Desby OS Color Palette
/// Extracted from App Logo: Dark Navy and Amber
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // Brand Colors
  static const Color amber = Color(0xFFFFC107);
  static const Color darkNavy = Color(0xFF0A1921);
  static const Color darkGreen = Color(0xFF1B3022);
  static const Color deepBlue = Color(0xFF102A35);

  // Primary Colors (Amber-based)
  static const Color primary = amber;
  static const Color primaryLight = Color(0xFFFFD54F);
  static const Color primaryDark = Color(0xFFFFA000);

  // Secondary Colors (Navy-based)
  static const Color secondary = darkNavy;
  static const Color secondaryLight = deepBlue;
  static const Color secondaryDark = Color(0xFF051016);

  // Accent Colors
  static const Color accent = Color(0xFF2A9D8F); // Keeping teal as a professional accent

  // Neutral Colors
  static const Color darkGray = Color(0xFF1A1A1A);
  static const Color mediumGray = Color(0xFF666666);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Background Colors
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color backgroundDark = darkNavy;
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = deepBlue;

// Border Colors
  static const Color borderLight = Color(0xFFD9E2EA);
  static const Color borderDark = Color(0xFF424242);

  // Desktop UI/UX Framework Colors
  // Frame colors
  static const Color bgShell = Color(0xFF071A1F);
  static const Color bgSurface = Color(0xFFFFFFFF);
  static const Color bgSidebar = Color(0xFFF5F7FA);
  static const Color bgSubtle = Color(0xFFF8FAFC);

  // Text colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Border colors
  static const Color borderActive = amber;
  
  // Clothing Color Palette for Client Selection
  static const List<Color> clothingColors = [
    Color(0xFF000000), // Black
    Color(0xFFFFFFFF), // White
    Color(0xFF000080), // Navy
    Color(0xFF808080), // Grey
    Color(0xFFDC143C), // Red
    Color(0xFF0000FF), // Blue
    Color(0xFF008000), // Green
    Color(0xFF8B4513), // Brown
    Color(0xFF800020), // Burgundy
    Color(0xFFFFD700), // Gold
    Color(0xFFFFC0CB), // Pink
    Color(0xFFFFA500), // Orange
    Color(0xFF800080), // Purple
    Color(0xFFF5F5DC), // Beige
    Color(0xFFFFFDD0), // Cream
    Color(0xFF008080), // Teal
    Color(0xFF800000), // Maroon
    Color(0xFF808000), // Olive
    Color(0xFF36454F), // Charcoal
    Color(0xFFFFFFF0), // Ivory
  ];
  
  static const List<String> clothingColorNames = [
    'Black',
    'White',
    'Navy',
    'Grey',
    'Red',
    'Blue',
    'Green',
    'Brown',
    'Burgundy',
    'Gold',
    'Pink',
    'Orange',
    'Purple',
    'Beige',
    'Cream',
    'Teal',
    'Maroon',
    'Olive',
    'Charcoal',
    'Ivory',
  ];
}

/// Color utilities and extensions
extension ColorExtension on Color {
  /// Get a lighter shade of the color
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightened = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return lightened.toColor();
  }

  /// Get a darker shade of the color
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final darkened = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darkened.toColor();
  }

  /// Get a color with adjusted opacity
  Color withOpacity(double opacity) {
    assert(opacity >= 0 && opacity <= 1);
    return withValues(alpha: opacity);
  }
}
