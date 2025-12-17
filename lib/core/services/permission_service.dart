import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Permission Service Provider
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

/// Service for handling app permissions
class PermissionService {
  /// Check if all required permissions are granted
  Future<bool> hasAllRequiredPermissions() async {
    final notification = await Permission.notification.isGranted;
    return notification;
  }

  /// Request notification permission
  Future<bool> requestNotificationPermission() async {
    // For Android 13+ (API 33), need to request POST_NOTIFICATIONS
    final status = await Permission.notification.request();

    // Also request FCM permission
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    return status.isGranted ||
        settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Request microphone permission for voice notes
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Request storage/photos permission for gallery
  Future<bool> requestPhotosPermission() async {
    // For Android 13+, use photos permission
    if (await Permission.photos.isGranted) return true;

    // Try photos first (Android 13+)
    var status = await Permission.photos.request();
    if (status.isGranted) return true;

    // Fallback to storage for older Android versions
    status = await Permission.storage.request();
    return status.isGranted;
  }

  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Check notification permission status
  Future<PermissionStatus> getNotificationStatus() async {
    return await Permission.notification.status;
  }

  /// Check microphone permission status
  Future<PermissionStatus> getMicrophoneStatus() async {
    return await Permission.microphone.status;
  }

  /// Check photos permission status
  Future<PermissionStatus> getPhotosStatus() async {
    // Check photos first (Android 13+)
    final photos = await Permission.photos.status;
    if (photos.isGranted) return photos;

    // Check storage for older versions
    return await Permission.storage.status;
  }

  /// Check camera permission status
  Future<PermissionStatus> getCameraStatus() async {
    return await Permission.camera.status;
  }

  /// Request all essential permissions at once
  Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    final statuses = await [
      Permission.notification,
      Permission.microphone,
      Permission.camera,
      Permission.photos,
    ].request();

    // Also request FCM permission
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    return statuses;
  }

  /// Open app settings if permission is permanently denied
  Future<bool> openSettings() async {
    return await openAppSettings();
  }
}
