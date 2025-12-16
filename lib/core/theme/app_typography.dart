import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Symphonia Typography System
/// Uses system fonts with Material Design 3 styling
/// for a modern, elegant feel with clear hierarchy
class AppTypography {
  AppTypography._();

  // Font family - using system default which is Roboto on Android
  // This gives a clean, modern Material Design look
  static const String _fontFamily = 'Roboto';

  // ═══════════════════════════════════════════════════════════════════════════
  // BASE TEXT THEME
  // ═══════════════════════════════════════════════════════════════════════════

  static TextTheme get textTheme {
    return TextTheme(
      // Display styles - For hero text and large headings
      displayLarge: _displayLarge,
      displayMedium: _displayMedium,
      displaySmall: _displaySmall,

      // Headline styles - For section headers
      headlineLarge: _headlineLarge,
      headlineMedium: _headlineMedium,
      headlineSmall: _headlineSmall,

      // Title styles - For cards and list items
      titleLarge: _titleLarge,
      titleMedium: _titleMedium,
      titleSmall: _titleSmall,

      // Body styles - For content text
      bodyLarge: _bodyLarge,
      bodyMedium: _bodyMedium,
      bodySmall: _bodySmall,

      // Label styles - For buttons and chips
      labelLarge: _labelLarge,
      labelMedium: _labelMedium,
      labelSmall: _labelSmall,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DISPLAY STYLES
  // ═══════════════════════════════════════════════════════════════════════════

  static TextStyle get _displayLarge => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 57,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    height: 1.12,
    color: AppColors.charcoal,
  );

  static TextStyle get _displayMedium => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 45,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.16,
    color: AppColors.charcoal,
  );

  static TextStyle get _displaySmall => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.22,
    color: AppColors.charcoal,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADLINE STYLES
  // ═══════════════════════════════════════════════════════════════════════════

  static TextStyle get _headlineLarge => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.25,
    color: AppColors.charcoal,
  );

  static TextStyle get _headlineMedium => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.29,
    color: AppColors.charcoal,
  );

  static TextStyle get _headlineSmall => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.33,
    color: AppColors.charcoal,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // TITLE STYLES
  // ═══════════════════════════════════════════════════════════════════════════

  static TextStyle get _titleLarge => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.27,
    color: AppColors.charcoal,
  );

  static TextStyle get _titleMedium => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.5,
    color: AppColors.charcoal,
  );

  static TextStyle get _titleSmall => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
    color: AppColors.charcoal,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // BODY STYLES
  // ═══════════════════════════════════════════════════════════════════════════

  static TextStyle get _bodyLarge => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.5,
    color: AppColors.charcoal,
  );

  static TextStyle get _bodyMedium => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
    color: AppColors.charcoal,
  );

  static TextStyle get _bodySmall => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
    color: AppColors.grayDark,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // LABEL STYLES
  // ═══════════════════════════════════════════════════════════════════════════

  static TextStyle get _labelLarge => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
    color: AppColors.charcoal,
  );

  static TextStyle get _labelMedium => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.33,
    color: AppColors.charcoal,
  );

  static TextStyle get _labelSmall => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.45,
    color: AppColors.grayDark,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // SPECIAL STYLES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Romantic quote style
  static TextStyle get romantic => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    fontStyle: FontStyle.italic,
    letterSpacing: 0.15,
    height: 1.6,
    color: AppColors.primary,
  );

  /// Message bubble text
  static TextStyle get message => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    height: 1.47,
    color: AppColors.charcoal,
  );

  /// Time stamp style
  static TextStyle get timestamp => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.3,
    height: 1.27,
    color: AppColors.gray,
  );

  /// Button text
  static TextStyle get button => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.5,
    color: AppColors.white,
  );

  /// Caption for images
  static TextStyle get caption => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.38,
    color: AppColors.grayDark,
  );
}
