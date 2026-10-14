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
  static const Color accent = Color(
    0xFF2A9D8F,
  ); // Keeping teal as a professional accent

  // Neutral Colors
  static const Color darkGray = Color(0xFF1A1A1A);
  static const Color mediumGray = Color(0xFF666666);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Semantic Colors
  static const Color successGreen = Color(0xFF00FF7F);
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

  // Uber-stylediscovery colors
  static const Color uberBg = Color(0xFFFFFFFF);
  static const Color uberCard = Color(0xFFF3F3F3);
  static const Color uberInfo = Color(0xFF276EF1);
  static const Color uberWarning = Color(0xFFFFC043);
  static const Color uberError = Color(0xFFE11900);
  static const Color uberLive = Color(0xFF05A357);
  static const Color uberTextPrimary = Color(0xFF000000);
  static const Color uberTextMuted = Color(0xFF545454);
  static const Color figmaCardFill = Color(0xFFF6F6F6);

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

/// Theme-aware color tokens.
/// Access via: `context.colors.textPrimary`, `context.colors.surface`, etc.
class DesbyThemeColors {
  final BuildContext _context;
  const DesbyThemeColors(this._context);

  bool get _isDark => Theme.of(_context).brightness == Brightness.dark;

  // ── Backgrounds ──
  Color get scaffoldBg =>
      _isDark ? AppColors.darkNavy : const Color(0xFFF2F4F7);
  Color get background =>
      _isDark ? AppColors.darkNavy : const Color(0xFFF2F4F7);
  Color get surface =>
      _isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
  Color get surfaceElevated =>
      _isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white;
  Color get surfaceHover =>
      _isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF0F2F5);
  Color get surfaceAlt =>
      _isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF0F0F0);
  Color get appBarBg => _isDark ? AppColors.darkNavy : Colors.white;
  Color get sidebarBg => _isDark ? AppColors.darkNavy : Colors.white;
  Color get bottomNavBg => _isDark ? AppColors.darkNavy : Colors.white;
  Color get dialogBg => _isDark ? AppColors.darkNavy : Colors.white;
  Color get bottomSheetBg => _isDark ? AppColors.darkNavy : Colors.white;
  Color get popupMenuBg => _isDark ? AppColors.darkNavy : Colors.white;
  Color get dropdownBg => _isDark ? AppColors.darkNavy : Colors.white;
  Color get snackbarBg =>
      _isDark ? const Color(0xFF323232) : const Color(0xFF1E293B);

  // ── Surface overlays (cards, inputs, containers) ──
  Color get inputFill =>
      _isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC);
  Color get cardBg =>
      _isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
  Color get cardBorder =>
      _isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0);
  Color get containerFill =>
      _isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9);
  Color get shimmerBg =>
      _isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE2E8F0);
  Color get shimmerBorder =>
      _isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFCBD5E1);

  // ── Text ──
  Color get textPrimary => _isDark ? Colors.white : const Color(0xFF0F172A);
  Color get textSecondary => _isDark ? Colors.white70 : const Color(0xFF475569);
  Color get textMuted => _isDark ? Colors.white38 : const Color(0xFF64748B);
  Color get textHint => _isDark ? Colors.white24 : const Color(0xFF94A3B8);
  Color get textOnAmber => AppColors.darkNavy;

  // ── Icons ──
  Color get iconPrimary => _isDark ? Colors.white : const Color(0xFF0F172A);
  Color get iconSecondary => _isDark ? Colors.white70 : const Color(0xFF475569);
  Color get iconMuted => _isDark ? Colors.white38 : const Color(0xFF94A3B8);
  Color get iconOnAmber => AppColors.darkNavy;

  // ── Accent used as foreground ──
  //
  // The brand amber (#FFC107) is a *background* accent. As text or an icon on a
  // light surface it measures 1.6:1 against white and 1.3:1 against a light
  // border, so it disappears — amber icons on white buttons and amber chip
  // labels on pale amber chips are unreadable in light mode. These tokens keep
  // the amber identity but darken it enough to read: #8A5A00 measures 5.9:1 on
  // white, 5.5:1 on the tinted chip fill and 4.8:1 on the light border.
  Color get accentOnSurface =>
      _isDark ? AppColors.amber : const Color(0xFF8A5A00);

  /// Same idea, for text sitting on an amber-tinted fill.
  Color get accentOnSubtleFill =>
      _isDark ? AppColors.amber : const Color(0xFF8A5A00);

  /// Amber-tinted background for chips and small badges.
  Color get accentSubtleFill => _isDark
      ? AppColors.amber.withValues(alpha: 0.16)
      : AppColors.amber.withValues(alpha: 0.12);

  Color get accentSubtleBorder => _isDark
      ? AppColors.amber.withValues(alpha: 0.38)
      : AppColors.amber.withValues(alpha: 0.42);

  // ── Interactive rows (action buttons, stat strips) ──
  //
  // Fill and border were previously the same near-invisible white alpha, which
  // in dark mode produced a 1.02:1 distinction — the row was there, but you
  // could not see where it began or ended. Fill is now a step lighter than the
  // border so the control reads as a control in both themes.
  //
  // Note on contrast: WCAG 1.4.11's 3:1 is for boundaries *required* to
  // identify a control. These tiles carry a 22px icon and an 11pt label, so the
  // edge is grouping, not the sole affordance — and against a near-black
  // background no tasteful border reaches 3:1 over a subtle fill. Light mode
  // can (and does) clear 3:1; dark mode targets clear perceptual separation.
  Color get interactiveFill =>
      _isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFF1F5F9);

  Color get interactiveBorder => _isDark
      ? Colors.white.withValues(alpha: 0.20)
      : const Color(0xFF7D8DA3);

  // ── Borders & Dividers ──
  Color get borderDefault =>
      _isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFCBD5E1);
  Color get borderFocused => AppColors.amber;
  Color get borderSubtle =>
      _isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0);
  Color get divider => _isDark ? Colors.white12 : const Color(0xFFE2E8F0);
  Color get sidebarBorder =>
      _isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0);

  // ── Navigation ──
  Color get navSelected => AppColors.amber;
  Color get navUnselected =>
      _isDark ? Colors.white.withValues(alpha: 0.3) : Colors.grey;
  Color get navItemActiveBg => _isDark
      ? AppColors.amber.withValues(alpha: 0.08)
      : AppColors.amber.withValues(alpha: 0.08);
  Color get navItemActiveBorder => _isDark
      ? AppColors.amber.withValues(alpha: 0.15)
      : AppColors.amber.withValues(alpha: 0.15);
  Color get navItemHoverBg => _isDark
      ? Colors.white.withValues(alpha: 0.03)
      : Colors.grey.withValues(alpha: 0.05);

  // ── AppBar ──
  Color get appBarText => _isDark ? Colors.white : AppColors.darkNavy;

  // ── Status / Semantic ──
  Color get statusSuccess =>
      _isDark ? AppColors.successGreen : AppColors.success;
  Color get statusError => Colors.redAccent;
  Color get statusWarning => AppColors.warning;
  Color get statusInfo => AppColors.info;

  // ── Overlays (theme-independent) ──
  Color get overlayLight => Colors.black26;
  Color get overlayMedium => Colors.black45;
  Color get overlayHeavy => Colors.black54;
  Color get barrierColor => Colors.black87;

  // ── Shadows ──
  BoxShadow get cardShadow => BoxShadow(
    color: _isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.06),
    blurRadius: 10,
    spreadRadius: 0,
    offset: const Offset(0, 2),
  );
  BoxShadow get elevatedShadow => BoxShadow(
    color: _isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.1),
    blurRadius: 16,
    spreadRadius: -2,
    offset: const Offset(0, 4),
  );
}

/// Extension on BuildContext for easy access to theme-aware colors.
extension DesbyColorsExtension on BuildContext {
  DesbyThemeColors get colors => DesbyThemeColors(this);
}

/// Color utilities and extensions
extension ColorExtension on Color {
  /// Get a lighter shade of the color
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightened = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return lightened.toColor();
  }

  /// Get a darker shade of the color
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final darkened = hsl.withLightness(
      (hsl.lightness - amount).clamp(0.0, 1.0),
    );
    return darkened.toColor();
  }

  /// Get a color with adjusted opacity
  Color withOpacity(double opacity) {
    assert(opacity >= 0 && opacity <= 1);
    return withValues(alpha: opacity);
  }
}
