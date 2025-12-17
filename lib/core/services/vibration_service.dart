import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';

import '../constants/app_constants.dart';

/// Provider for VibrationService
final vibrationServiceProvider = Provider<VibrationService>((ref) {
  return VibrationService();
});

/// Service for haptic feedback and vibration patterns
/// Handles the romantic heartbeat vibrations and notifications
class VibrationService {
  bool _hasVibrator = false;
  bool _hasCustomVibration = false;

  /// Initialize vibration capabilities
  Future<void> initialize() async {
    _hasVibrator = await Vibration.hasVibrator();
    _hasCustomVibration = await Vibration.hasCustomVibrationsSupport();
  }

  /// Check if device supports vibration
  bool get canVibrate => _hasVibrator;

  /// Check if device supports custom vibration patterns
  bool get supportsCustomPatterns => _hasCustomVibration;

  // ═══════════════════════════════════════════════════════════════════════════
  // HEARTBEAT VIBRATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Play the signature heartbeat vibration pattern
  /// This is the core romantic interaction
  Future<void> playHeartbeat() async {
    if (!_hasVibrator) return;

    if (_hasCustomVibration) {
      // Use custom pattern for heartbeat effect
      await Vibration.vibrate(
        pattern: AppConstants.heartbeatPattern,
        // intensities: AppConstants.heartbeatIntensities,
      );
    } else {
      // Fallback: simple double vibration
      await Vibration.vibrate(duration: 100);
      await Future.delayed(const Duration(milliseconds: 100));
      await Vibration.vibrate(duration: 100);
    }
  }

  /// Play a single heartbeat (thump-thump)
  Future<void> playSingleHeartbeat() async {
    if (!_hasVibrator) return;

    if (_hasCustomVibration) {
      await Vibration.vibrate(
        pattern: AppConstants.singleHeartbeat,
        intensities: [0, 180, 0, 180],
      );
    } else {
      await Vibration.vibrate(duration: 80);
      await Future.delayed(const Duration(milliseconds: 80));
      await Vibration.vibrate(duration: 80);
    }
  }

  /// Play continuous heartbeat for background service
  /// Returns after specified number of beats
  Future<void> playContinuousHeartbeat({int beats = 3}) async {
    for (int i = 0; i < beats; i++) {
      await playHeartbeat();
      await Future.delayed(const Duration(milliseconds: 800));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NOTIFICATION VIBRATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Vibrate for message received
  Future<void> vibrateMessageReceived() async {
    if (!_hasVibrator) return;

    // Gentle double tap
    await Vibration.vibrate(duration: 50);
    await Future.delayed(const Duration(milliseconds: 100));
    await Vibration.vibrate(duration: 50);
  }

  /// Vibrate for voice note received
  Future<void> vibrateVoiceNoteReceived() async {
    if (!_hasVibrator) return;

    // Slightly longer pattern for voice notes
    if (_hasCustomVibration) {
      await Vibration.vibrate(
        pattern: [0, 80, 80, 80, 80, 80],
        intensities: [0, 150, 0, 150, 0, 150],
      );
    } else {
      await Vibration.vibrate(duration: 150);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HAPTIC FEEDBACK
  // ═══════════════════════════════════════════════════════════════════════════

  /// Light haptic feedback for button taps
  Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium haptic feedback
  Future<void> mediumImpact() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy haptic feedback
  Future<void> heavyImpact() async {
    await HapticFeedback.heavyImpact();
  }

  /// Selection tick feedback
  Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }

  /// Success feedback
  Future<void> success() async {
    if (!_hasVibrator) return;

    if (_hasCustomVibration) {
      await Vibration.vibrate(
        pattern: [0, 30, 50, 30],
        intensities: [0, 150, 0, 200],
      );
    } else {
      await HapticFeedback.mediumImpact();
    }
  }

  /// Error feedback
  Future<void> error() async {
    if (!_hasVibrator) return;

    if (_hasCustomVibration) {
      await Vibration.vibrate(
        pattern: [0, 100, 50, 100],
        intensities: [0, 255, 0, 255],
      );
    } else {
      await HapticFeedback.heavyImpact();
    }
  }

  /// Cancel any ongoing vibration
  Future<void> cancel() async {
    await Vibration.cancel();
  }
}
