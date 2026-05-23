import 'package:flutter/material.dart';

/// Desby OS Shadow & Elevation System
/// Material Design 3 compliant with custom enhancements
class AppShadows {
  AppShadows._(); // Private constructor to prevent instantiation

  // Elevation levels (Material Design 3)
  static const double elevation0 = 0;
  static const double elevation1 = 1;
  static const double elevation2 = 3;
  static const double elevation3 = 6;
  static const double elevation4 = 8;
  static const double elevation5 = 12;

  // Shadow definitions for different elevations
  static const List<BoxShadow> shadow0 = [];

  static const List<BoxShadow> shadow1 = [
    BoxShadow(
      color: Color(0x0D000000), // 5% black
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> shadow2 = [
    BoxShadow(
      color: Color(0x1A000000), // 10% black
      offset: Offset(0, 3),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> shadow3 = [
    BoxShadow(
      color: Color(0x26000000), // 15% black
      offset: Offset(0, 6),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> shadow4 = [
    BoxShadow(
      color: Color(0x33000000), // 20% black
      offset: Offset(0, 8),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> shadow5 = [
    BoxShadow(
      color: Color(0x40000000), // 25% black
      offset: Offset(0, 12),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ];

  // Card shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 2),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> cardShadowHover = [
    BoxShadow(
      color: Color(0x26000000),
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> cardShadowPressed = [
    BoxShadow(
      color: Color(0x0D000000),
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
  ];

  // Button shadows
  static const List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> buttonShadowHover = [
    BoxShadow(
      color: Color(0x26000000),
      offset: Offset(0, 4),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> buttonShadowPressed = [];

  // FAB shadows
  static const List<BoxShadow> fabShadow = [
    BoxShadow(
      color: Color(0x33000000),
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> fabShadowHover = [
    BoxShadow(
      color: Color(0x40000000),
      offset: Offset(0, 8),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];

  // Dialog shadows
  static const List<BoxShadow> dialogShadow = [
    BoxShadow(
      color: Color(0x40000000),
      offset: Offset(0, 12),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ];

  // Bottom sheet shadows
  static const List<BoxShadow> bottomSheetShadow = [
    BoxShadow(
      color: Color(0x33000000),
      offset: Offset(0, -4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  // App bar shadows
  static const List<BoxShadow> appBarShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];

  // Floating label shadows
  static const List<BoxShadow> floatingLabelShadow = [
    BoxShadow(
      color: Color(0x0D000000),
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  // Chip shadows
  static const List<BoxShadow> chipShadow = [
    BoxShadow(
      color: Color(0x0D000000),
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
  ];

  // Tooltip shadows
  static const List<BoxShadow> tooltipShadow = [
    BoxShadow(
      color: Color(0x40000000),
      offset: Offset(0, 4),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];

  // Measurement diagram shadows
  static const List<BoxShadow> measurementShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 2),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];

  // Design gallery item shadows
  static const List<BoxShadow> designItemShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 2),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];

  // Fabric swatch shadows
  static const List<BoxShadow> fabricSwatchShadow = [
    BoxShadow(
      color: Color(0x0D000000),
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
  ];

  // Inset shadows (for pressed states)
  static const List<BoxShadow> insetShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  // Glow effects
  static const List<BoxShadow> glowPrimary = [
    BoxShadow(
      color: Color(0x336B4C8A), // Primary with 20% opacity
      offset: Offset(0, 0),
      blurRadius: 12,
      spreadRadius: 2,
    ),
  ];

  static const List<BoxShadow> glowSecondary = [
    BoxShadow(
      color: Color(0x33D4A574), // Secondary with 20% opacity
      offset: Offset(0, 0),
      blurRadius: 12,
      spreadRadius: 2,
    ),
  ];

  static const List<BoxShadow> glowAccent = [
    BoxShadow(
      color: Color(0x332A9D8F), // Accent with 20% opacity
      offset: Offset(0, 0),
      blurRadius: 12,
      spreadRadius: 2,
    ),
  ];

  static const List<BoxShadow> glowSuccess = [
    BoxShadow(
      color: Color(0x334CAF50), // Success with 20% opacity
      offset: Offset(0, 0),
      blurRadius: 12,
      spreadRadius: 2,
    ),
  ];

  static const List<BoxShadow> glowError = [
    BoxShadow(
      color: Color(0x33F44336), // Error with 20% opacity
      offset: Offset(0, 0),
      blurRadius: 12,
      spreadRadius: 2,
    ),
  ];
}

/// Shadow utilities and extensions
extension BoxShadowExtension on BoxShadow {
  /// Create a shadow with custom opacity
  BoxShadow withOpacity(double opacity) {
    return BoxShadow(
      color: color.withValues(alpha: opacity),
      offset: offset,
      blurRadius: blurRadius,
      spreadRadius: spreadRadius,
    );
  }

  /// Create a shadow with custom blur radius
  BoxShadow withBlurRadius(double blur) {
    return BoxShadow(
      color: color,
      offset: offset,
      blurRadius: blur,
      spreadRadius: spreadRadius,
    );
  }

  /// Create a shadow with custom offset
  BoxShadow withOffset(Offset newOffset) {
    return BoxShadow(
      color: color,
      offset: newOffset,
      blurRadius: blurRadius,
      spreadRadius: spreadRadius,
    );
  }
}

/// Common shadow presets
class AppBoxShadows {
  AppBoxShadows._(); // Private constructor to prevent instantiation

  // Get shadow by elevation level
  static List<BoxShadow> getElevationShadow(int elevation) {
    switch (elevation) {
      case 0:
        return AppShadows.shadow0;
      case 1:
        return AppShadows.shadow1;
      case 2:
        return AppShadows.shadow2;
      case 3:
        return AppShadows.shadow3;
      case 4:
        return AppShadows.shadow4;
      case 5:
        return AppShadows.shadow5;
      default:
        return AppShadows.shadow0;
    }
  }

  // Get shadow by component type
  static List<BoxShadow> getComponentShadow(String component) {
    switch (component) {
      case 'card':
        return AppShadows.cardShadow;
      case 'button':
        return AppShadows.buttonShadow;
      case 'fab':
        return AppShadows.fabShadow;
      case 'dialog':
        return AppShadows.dialogShadow;
      case 'bottomSheet':
        return AppShadows.bottomSheetShadow;
      case 'appBar':
        return AppShadows.appBarShadow;
      default:
        return AppShadows.shadow0;
    }
  }
}
