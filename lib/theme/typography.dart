import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Desby OS Typography System
/// Premium, modern fonts with fashion-forward hierarchy
class AppTypography {
  AppTypography._(); // Private constructor to prevent instantiation

  // Font families
  static const String primaryFont = 'Poppins';
  static const String secondaryFont = 'Inter';

  // Text Styles - Light Theme
  static TextStyle get headline1 => GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        height: 1.2,
      );

  static TextStyle get headline2 => GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.25,
        height: 1.3,
      );

  static TextStyle get headline3 => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.3,
      );

  static TextStyle get headline4 => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.4,
      );

  static TextStyle get headline5 => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.4,
      );

  static TextStyle get headline6 => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.5,
      );

  // Body Text Styles
  static TextStyle get body1 => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.5,
      );

  static TextStyle get body2 => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.5,
      );

  static TextStyle get body3 => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.5,
      );

  // Label/Button Styles
  static TextStyle get button => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.4,
      );

  static TextStyle get buttonSmall => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.3,
      );

  static TextStyle get buttonLarge => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.5,
      );

  // Caption/Helper Text Styles
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.4,
      );

  static TextStyle get captionSmall => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.3,
        height: 1.3,
      );

  static TextStyle get overline => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        height: 1.2,
      );

  // Subtitle Styles
  static TextStyle get subtitle1 => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        height: 1.5,
      );

  static TextStyle get subtitle2 => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.5,
      );

  // Display Styles (Large headlines)
  static TextStyle get display1 => GoogleFonts.poppins(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        letterSpacing: -1,
        height: 1.1,
      );

  static TextStyle get display2 => GoogleFonts.poppins(
        fontSize: 40,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.75,
        height: 1.2,
      );

  static TextStyle get display3 => GoogleFonts.poppins(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        height: 1.2,
      );

  // Special Styles
  static TextStyle get error => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.4,
        color: const Color(0xFFF44336),
      );

  static TextStyle get hint => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.5,
        color: const Color(0xFF999999),
      );

  static TextStyle get disabled => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.5,
        color: const Color(0xFFBDBDBD),
      );

  // Fashion-specific Styles
  static TextStyle get fabricName => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.5,
      );

  static TextStyle get measurementLabel => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        height: 1.4,
      );

  static TextStyle get measurementValue => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.3,
      );

  static TextStyle get designTitle => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.4,
      );

  static TextStyle get designDescription => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.6,
      );

  static TextStyle get priceTag => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: 0,
        height: 1.2,
      );

  static TextStyle get orderStatus => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.3,
      );
}

/// Text style utilities and extensions
extension TextStyleExtension on TextStyle {
  /// Create a copy with custom color
  TextStyle withColor(Color color) => copyWith(color: color);

  /// Create a copy with custom size
  TextStyle withSize(double size) => copyWith(fontSize: size);

  /// Create a copy with custom weight
  TextStyle withWeight(FontWeight weight) => copyWith(fontWeight: weight);

  /// Create a copy with custom height
  TextStyle withHeight(double height) => copyWith(height: height);

  /// Create a copy with custom letter spacing
  TextStyle withLetterSpacing(double spacing) =>
      copyWith(letterSpacing: spacing);

  /// Create a bold variant
  TextStyle get bold => copyWith(fontWeight: FontWeight.bold);

  /// Create a semi-bold variant
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);

  /// Create a medium variant
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);

  /// Create a light variant
  TextStyle get light => copyWith(fontWeight: FontWeight.w300);

  /// Create an italic variant
  TextStyle get italic => copyWith(fontStyle: FontStyle.italic);
}
