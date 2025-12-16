import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

/// Provider for PermissionManager
final permissionManagerProvider = Provider<PermissionManager>((ref) {
  return PermissionManager();
});

/// Centralized permission management
/// Handles all permission requests with clear explanations
class PermissionManager {
  // ═══════════════════════════════════════════════════════════════════════════
  // PERMISSION STATUS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Check all required permissions
  Future<PermissionStatus> checkAllPermissions() async {
    final statuses = await Future.wait([
      Permission.notification.status,
      Permission.microphone.status,
      Permission.storage.status,
    ]);

    // Return the worst status
    if (statuses.any((s) => s.isPermanentlyDenied)) {
      return PermissionStatus.permanentlyDenied;
    }
    if (statuses.any((s) => s.isDenied)) {
      return PermissionStatus.denied;
    }
    if (statuses.every((s) => s.isGranted)) {
      return PermissionStatus.granted;
    }
    return PermissionStatus.limited;
  }

  /// Check notification permission
  Future<bool> hasNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Check microphone permission
  Future<bool> hasMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Check storage permission
  Future<bool> hasStoragePermission() async {
    final status = await Permission.storage.status;
    return status.isGranted || status.isLimited;
  }

  /// Check location permission
  Future<bool> hasLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REQUEST PERMISSIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Request all essential permissions at once
  Future<Map<Permission, PermissionStatus>>
  requestEssentialPermissions() async {
    return await [
      Permission.notification,
      Permission.microphone,
      Permission.storage,
    ].request();
  }

  /// Request notification permission
  Future<PermissionResult> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return PermissionResult(
      permission: Permission.notification,
      status: status,
      explanation: _notificationExplanation,
    );
  }

  /// Request microphone permission
  Future<PermissionResult> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return PermissionResult(
      permission: Permission.microphone,
      status: status,
      explanation: _microphoneExplanation,
    );
  }

  /// Request storage permission
  Future<PermissionResult> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return PermissionResult(
      permission: Permission.storage,
      status: status,
      explanation: _storageExplanation,
    );
  }

  /// Request location permission (for geo-triggers)
  Future<PermissionResult> requestLocationPermission() async {
    final status = await Permission.location.request();
    return PermissionResult(
      permission: Permission.location,
      status: status,
      explanation: _locationExplanation,
    );
  }

  /// Request background location (for geo-triggers while app is closed)
  Future<PermissionResult> requestBackgroundLocationPermission() async {
    // First ensure we have regular location permission
    final locationStatus = await Permission.location.status;
    if (!locationStatus.isGranted) {
      await Permission.location.request();
    }

    final status = await Permission.locationAlways.request();
    return PermissionResult(
      permission: Permission.locationAlways,
      status: status,
      explanation: _backgroundLocationExplanation,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OPEN SETTINGS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Open app settings for manually granting permissions
  Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXPLANATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  static const String _notificationExplanation = '''
Notifications let you know when your partner sends you a love message or voice note. 

You'll receive gentle alerts even when the app isn't open, so you never miss a moment of connection.''';

  static const String _microphoneExplanation = '''
The microphone is needed to record voice notes for your partner.

Share sweet messages, sing a song, or just say "I love you" in your own voice.''';

  static const String _storageExplanation = '''
Storage access lets you save photos and voice notes to your device.

Your memories are stored safely and can be accessed even offline.''';

  static const String _locationExplanation = '''
Location access enables geo-triggered greetings.

Send your partner an automatic "I'm home!" message when you arrive at saved locations.''';

  static const String _backgroundLocationExplanation = '''
Background location allows geo-triggers to work even when the app is closed.

This uses more battery, but ensures your partner always knows when you've arrived safely.''';

  /// Get explanation for a permission
  String getExplanation(Permission permission) {
    switch (permission) {
      case Permission.notification:
        return _notificationExplanation;
      case Permission.microphone:
        return _microphoneExplanation;
      case Permission.storage:
        return _storageExplanation;
      case Permission.location:
        return _locationExplanation;
      case Permission.locationAlways:
        return _backgroundLocationExplanation;
      default:
        return 'This permission is required for the app to function properly.';
    }
  }

  /// Get user-friendly name for a permission
  String getPermissionName(Permission permission) {
    switch (permission) {
      case Permission.notification:
        return 'Notifications';
      case Permission.microphone:
        return 'Microphone';
      case Permission.storage:
        return 'Storage';
      case Permission.location:
        return 'Location';
      case Permission.locationAlways:
        return 'Background Location';
      default:
        return permission.toString();
    }
  }

  /// Get icon for a permission
  String getPermissionIcon(Permission permission) {
    switch (permission) {
      case Permission.notification:
        return '🔔';
      case Permission.microphone:
        return '🎤';
      case Permission.storage:
        return '💾';
      case Permission.location:
        return '📍';
      case Permission.locationAlways:
        return '🗺️';
      default:
        return '⚙️';
    }
  }
}

/// Result of a permission request
class PermissionResult {
  final Permission permission;
  final PermissionStatus status;
  final String explanation;

  const PermissionResult({
    required this.permission,
    required this.status,
    required this.explanation,
  });

  bool get isGranted => status.isGranted;
  bool get isDenied => status.isDenied;
  bool get isPermanentlyDenied => status.isPermanentlyDenied;
  bool get isLimited => status.isLimited;
}
