import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Beautiful gradients for Symphonia
/// Creates the premium, romantic feel throughout the app
class AppGradients {
  AppGradients._();

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIMARY GRADIENTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Main romantic gradient - Rose to Coral
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B8A), Color(0xFFE85A7A), Color(0xFFD44D6E)],
  );

  /// Soft primary for backgrounds
  static const LinearGradient primarySoft = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF5F7), Color(0xFFFFE8EC)],
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // ROMANTIC GRADIENTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sunset romance - Uses for special moments
  static const LinearGradient sunset = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFB347), Color(0xFFFF6B8A), Color(0xFFE85A7A)],
  );

  /// Twilight - Deep romantic mood
  static const LinearGradient twilight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB47ED8), Color(0xFFE85A7A), Color(0xFFFF8FA3)],
  );

  /// Aurora - Mystical romantic feel
  static const LinearGradient aurora = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF667EEA), Color(0xFFB47ED8), Color(0xFFFF6B8A)],
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // HEART BUTTON GRADIENTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Heart button normal state
  static const RadialGradient heartNormal = RadialGradient(
    center: Alignment.center,
    radius: 0.8,
    colors: [Color(0xFFFF6B8A), Color(0xFFE85A7A), Color(0xFFC43D5C)],
  );

  /// Heart button pressed state
  static const RadialGradient heartPressed = RadialGradient(
    center: Alignment.center,
    radius: 1.0,
    colors: [Color(0xFFFF8FA3), Color(0xFFFF6B8A), Color(0xFFE85A7A)],
  );

  /// Heart glow effect
  static const RadialGradient heartGlow = RadialGradient(
    center: Alignment.center,
    radius: 1.2,
    colors: [Color(0x40FF6B8A), Color(0x20FF8FA3), Color(0x00FFFFFF)],
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // BACKGROUND GRADIENTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Light mode background
  static const LinearGradient backgroundLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFBFA), Color(0xFFFFF8F6), Color(0xFFFFF5F3)],
  );

  /// Dark mode background
  static const LinearGradient backgroundDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A1517), Color(0xFF221A1D), Color(0xFF2A2023)],
  );

  /// Glass effect overlay
  static const LinearGradient glassOverlay = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x30FFFFFF), Color(0x10FFFFFF)],
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // CARD GRADIENTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Message card sent
  static const LinearGradient messageSent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE85A7A), Color(0xFFD44D6E)],
  );

  /// Message card received
  static const LinearGradient messageReceived = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF5F0EE), Color(0xFFEDE8E6)],
  );

  /// Voice note gradient
  static const LinearGradient voiceNote = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFB47ED8), Color(0xFF8B5CB8)],
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // SHIMMER GRADIENTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Shimmer loading effect
  static const LinearGradient shimmer = LinearGradient(
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
    colors: [Color(0xFFF5F0EE), Color(0xFFFFFFFF), Color(0xFFF5F0EE)],
    stops: [0.0, 0.5, 1.0],
  );
}
