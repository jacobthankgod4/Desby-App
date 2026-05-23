import 'package:flutter/material.dart';

/// Desby OS Spacing System
/// 8px grid-based spacing for consistent layouts
class AppSpacing {
  AppSpacing._(); // Private constructor to prevent instantiation

  // Base unit (8px)
  static const double baseUnit = 8.0;

  // Spacing values (multiples of 8px)
  static const double xs = 4.0; // 0.5x
  static const double sm = 8.0; // 1x
  static const double md = 16.0; // 2x
  static const double lg = 24.0; // 3x
  static const double xl = 32.0; // 4x
  static const double xxl = 40.0; // 5x
  static const double xxxl = 48.0; // 6x

  // Padding values
  static const double paddingXs = 4.0;
  static const double paddingSm = 8.0;
  static const double paddingMd = 16.0;
  static const double paddingLg = 24.0;
  static const double paddingXl = 32.0;

  // Margin values
  static const double marginXs = 4.0;
  static const double marginSm = 8.0;
  static const double marginMd = 16.0;
  static const double marginLg = 24.0;
  static const double marginXl = 32.0;

  // Gap values (for Row/Column)
  static const double gapXs = 4.0;
  static const double gapSm = 8.0;
  static const double gapMd = 16.0;
  static const double gapLg = 24.0;
  static const double gapXl = 32.0;

  // Border radius values
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 24.0;
  static const double radiusCircle = 50.0; // For circular elements

  // Icon sizes
  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 40.0;
  static const double iconXxl = 48.0;

  // Button sizes
  static const double buttonHeightSm = 32.0;
  static const double buttonHeightMd = 40.0;
  static const double buttonHeightLg = 48.0;
  static const double buttonHeightXl = 56.0;

  static const double buttonPaddingHorizontalSm = 12.0;
  static const double buttonPaddingHorizontalMd = 16.0;
  static const double buttonPaddingHorizontalLg = 24.0;

  // Input field sizes
  static const double inputHeightSm = 32.0;
  static const double inputHeightMd = 40.0;
  static const double inputHeightLg = 48.0;

  static const double inputPaddingHorizontal = 12.0;
  static const double inputPaddingVertical = 8.0;

  // Card sizes
  static const double cardPaddingSm = 12.0;
  static const double cardPaddingMd = 16.0;
  static const double cardPaddingLg = 24.0;

  // Divider/Separator sizes
  static const double dividerThickness = 1.0;
  static const double dividerThicknessBold = 2.0;

  // App bar height
  static const double appBarHeight = 56.0;
  static const double appBarHeightLarge = 64.0;

  // Bottom navigation height
  static const double bottomNavHeight = 56.0;

  // Floating action button size
  static const double fabSize = 56.0;
  static const double fabSizeSmall = 40.0;
  static const double fabSizeLarge = 64.0;

  // Snackbar/Toast sizes
  static const double snackbarPadding = 16.0;
  static const double snackbarMargin = 8.0;

  // Dialog sizes
  static const double dialogPadding = 24.0;
  static const double dialogBorderRadius = 12.0;

  // Sheet sizes
  static const double sheetPadding = 16.0;
  static const double sheetBorderRadius = 16.0;

  // Avatar sizes
  static const double avatarXs = 24.0;
  static const double avatarSm = 32.0;
  static const double avatarMd = 40.0;
  static const double avatarLg = 56.0;
  static const double avatarXl = 72.0;

  // Chip sizes
  static const double chipHeight = 32.0;
  static const double chipPadding = 8.0;

  // List item height
  static const double listItemHeightSm = 40.0;
  static const double listItemHeightMd = 56.0;
  static const double listItemHeightLg = 72.0;

  // Measurement diagram sizes
  static const double measurementDiagramSize = 200.0;
  static const double measurementPointRadius = 8.0;

  // Design gallery grid
  static const double designGridSpacing = 8.0;
  static const double designGridItemSize = 160.0;

  // Fabric swatch sizes
  static const double fabricSwatchSize = 80.0;
  static const double fabricSwatchBorderRadius = 8.0;

  // Responsive breakpoints
  static const double mobileMaxWidth = 480.0;
  static const double tabletMinWidth = 600.0;
  static const double tabletMaxWidth = 840.0;
  static const double desktopMinWidth = 1200.0;

  // Safe area insets (platform-specific, set at runtime)
  // These are placeholders - actual values come from MediaQuery
  static const double safeAreaTop = 0.0;
  static const double safeAreaBottom = 0.0;
  static const double safeAreaLeft = 0.0;
  static const double safeAreaRight = 0.0;
}

/// Responsive spacing utilities
class ResponsiveSpacing {
  ResponsiveSpacing._(); // Private constructor to prevent instantiation

  /// Get spacing value based on screen width
  static double getSpacing(double screenWidth, {
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    if (screenWidth < AppSpacing.tabletMinWidth) {
      return mobile;
    } else if (screenWidth < AppSpacing.desktopMinWidth) {
      return tablet;
    } else {
      return desktop;
    }
  }

  /// Get padding based on screen width
  static EdgeInsets getPadding(double screenWidth) {
    if (screenWidth < AppSpacing.tabletMinWidth) {
      return const EdgeInsets.all(AppSpacing.paddingMd);
    } else if (screenWidth < AppSpacing.desktopMinWidth) {
      return const EdgeInsets.all(AppSpacing.paddingLg);
    } else {
      return const EdgeInsets.all(AppSpacing.paddingXl);
    }
  }

  /// Get grid spacing based on screen width
  static double getGridSpacing(double screenWidth) {
    if (screenWidth < AppSpacing.tabletMinWidth) {
      return AppSpacing.gapSm;
    } else if (screenWidth < AppSpacing.desktopMinWidth) {
      return AppSpacing.gapMd;
    } else {
      return AppSpacing.gapLg;
    }
  }
}

/// EdgeInsets utilities for common spacing patterns
class EdgeInsetsUtils {
  EdgeInsetsUtils._(); // Private constructor to prevent instantiation

  /// Create symmetric padding
  static EdgeInsets symmetric({
    double horizontal = 0,
    double vertical = 0,
  }) =>
      EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);

  /// Create padding from all sides
  static EdgeInsets all(double value) => EdgeInsets.all(value);

  /// Create padding from specific sides
  static EdgeInsets only({
    double top = 0,
    double right = 0,
    double bottom = 0,
    double left = 0,
  }) =>
      EdgeInsets.only(top: top, right: right, bottom: bottom, left: left);
}

/// Common EdgeInsets presets
class AppEdgeInsets {
  AppEdgeInsets._(); // Private constructor to prevent instantiation

  // Symmetric padding
  static const EdgeInsets symmetricHorizontalSm =
      EdgeInsets.symmetric(horizontal: AppSpacing.paddingSm);
  static const EdgeInsets symmetricHorizontalMd =
      EdgeInsets.symmetric(horizontal: AppSpacing.paddingMd);
  static const EdgeInsets symmetricHorizontalLg =
      EdgeInsets.symmetric(horizontal: AppSpacing.paddingLg);

  static const EdgeInsets symmetricVerticalSm =
      EdgeInsets.symmetric(vertical: AppSpacing.paddingSm);
  static const EdgeInsets symmetricVerticalMd =
      EdgeInsets.symmetric(vertical: AppSpacing.paddingMd);
  static const EdgeInsets symmetricVerticalLg =
      EdgeInsets.symmetric(vertical: AppSpacing.paddingLg);

  // All sides padding
  static const EdgeInsets allSm = EdgeInsets.all(AppSpacing.paddingSm);
  static const EdgeInsets allMd = EdgeInsets.all(AppSpacing.paddingMd);
  static const EdgeInsets allLg = EdgeInsets.all(AppSpacing.paddingLg);
  static const EdgeInsets allXl = EdgeInsets.all(AppSpacing.paddingXl);

  // Only specific sides
  static const EdgeInsets onlyTopSm = EdgeInsets.only(top: AppSpacing.paddingSm);
  static const EdgeInsets onlyTopMd = EdgeInsets.only(top: AppSpacing.paddingMd);
  static const EdgeInsets onlyTopLg = EdgeInsets.only(top: AppSpacing.paddingLg);

  static const EdgeInsets onlyBottomSm =
      EdgeInsets.only(bottom: AppSpacing.paddingSm);
  static const EdgeInsets onlyBottomMd =
      EdgeInsets.only(bottom: AppSpacing.paddingMd);
  static const EdgeInsets onlyBottomLg =
      EdgeInsets.only(bottom: AppSpacing.paddingLg);
}
