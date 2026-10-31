import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:symphonia/core/providers/firebase_providers.dart';

/// Permission Service Provider
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService(messaging: ref.watch(firebaseMessagingProvider));
});

/// Service for handling app permissions
class PermissionService {
  PermissionService({required FirebaseMessaging messaging})
    : _messaging = messaging;

  final FirebaseMessaging _messaging;

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
    final messaging = _messaging;
    final settings = await messaging.requestPermission();

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

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Check current permission
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Check notification permission status
  Future<PermissionStatus> getNotificationStatus() async {
    return Permission.notification.status;
  }

  /// Check microphone permission status
  Future<PermissionStatus> getMicrophoneStatus() async {
    return Permission.microphone.status;
  }

  /// Check photos permission status
  Future<PermissionStatus> getPhotosStatus() async {
    // Check photos first (Android 13+)
    final photos = await Permission.photos.status;
    if (photos.isGranted) return photos;

    // Check storage for older versions
    return Permission.storage.status;
  }

  /// Check camera permission status
  Future<PermissionStatus> getCameraStatus() async {
    return Permission.camera.status;
  }

  /// Check location permission status
  Future<bool> getLocationStatus() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Request all essential permissions at once
  Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    final statuses = await [
      Permission.notification,
      Permission.microphone,
      Permission.camera,
      Permission.photos,
      Permission.location,
    ].request();

    // Also request FCM permission
    final messaging = _messaging;
    await messaging.requestPermission();

    return statuses;
  }

  /// Open app settings if permission is permanently denied
  Future<bool> openSettings() async {
    return openAppSettings();
  }
}
