import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';

import '../constants/app_constants.dart';

/// FCM Service Provider
final fcmServiceProvider = Provider<FCMService>((ref) {
  return FCMService();
});

/// FCM Service for push notifications
class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize FCM
  Future<void> initialize() async {
    // Request permissions
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Initialize local notifications
      await _initializeLocalNotifications();

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages (already handled in main.dart)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Handle initial message (app opened from terminated state)
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@drawable/ic_notification',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;
    final data = message.data;

    if (notification != null) {
      // Use channel IDs that match what Cloud Functions send
      String channelId = 'message_channel';
      String channelName = 'Messages';
      bool enableVibration = true;

      // Determine channel based on message type
      if (data['type'] == 'heartbeat') {
        channelId = 'heartbeat_channel';
        channelName = 'Heartbeat';
        // DON'T play vibration here - Firestore listener in app.dart handles it
        // This prevents double vibration
        enableVibration = false; // Also disable notification vibration
      } else if (data['type'] == 'hugs') {
        channelId = 'heartbeat_channel';
        channelName = 'Hugs & Kisses';
        // DON'T play vibration here - Firestore listener in app.dart handles it
        enableVibration = false;
      } else if (data['type'] == 'message') {
        channelId = 'message_channel';
        channelName = 'Messages';
        // Play message vibration
        _playMessageVibration();
      } else if (data['type'] == 'voice_note') {
        channelId = 'symphonia_voice_notes';
        channelName = 'Voice Notes';
        // Play voice note vibration
        _playVoiceNoteVibration();
      } else if (data['type'] == 'event_created') {
        channelId = 'event_channel';
        channelName = 'Events';
      } else if (data['type'] == 'event_countdown' ||
          data['type'] == 'event_today') {
        channelId = 'reminder_channel';
        channelName = 'Reminders';
      }

      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: 'Symphonia $channelName notifications',
            importance: Importance.high,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@drawable/ic_notification',
            enableVibration: enableVibration,
            vibrationPattern:
                null, // Don't use channel vibration, we handle it manually
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: json.encode(data),
      );
    }
  }

  /// Play message vibration
  Future<void> _playMessageVibration() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator != true) return;

    await Vibration.vibrate(duration: 50);
    await Future.delayed(const Duration(milliseconds: 100));
    await Vibration.vibrate(duration: 50);
  }

  /// Play voice note vibration
  Future<void> _playVoiceNoteVibration() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator != true) return;

    await Vibration.vibrate(duration: 150);
  }

  /// Handle message opened app
  void _handleMessageOpenedApp(RemoteMessage message) {
    // Handle navigation based on message type
    final data = message.data;

    // Store for later navigation (handled by router)
    _pendingNotificationData = data;
  }

  /// Handle notification tapped
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!) as Map<String, dynamic>;
        _pendingNotificationData = data;
      } catch (_) {}
    }
  }

  /// Pending notification data for navigation
  Map<String, dynamic>? _pendingNotificationData;

  Map<String, dynamic>? consumePendingNotificationData() {
    final data = _pendingNotificationData;
    _pendingNotificationData = null;
    return data;
  }

  /// Get FCM token
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  /// Send notification to a specific token (via Cloud Function or HTTP)
  /// Note: In production, this should go through a Cloud Function
  Future<void> sendNotificationToToken({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // This is a placeholder - in production, you'd call a Cloud Function
    // For now, we'll just log it
    // The actual sending would be done via Firebase Admin SDK on server side
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
  // This is called when app is in background or terminated

  final data = message.data;
  final messageType = data['type'];

  // If it's a heartbeat, trigger vibration and show notification
  if (messageType == 'heartbeat') {
    // Play heartbeat vibration pattern
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      final hasCustom = await Vibration.hasCustomVibrationsSupport();
      if (hasCustom == true) {
        await Vibration.vibrate(pattern: AppConstants.heartbeatPattern);
      } else {
        // Fallback: simple double vibration
        await Vibration.vibrate(duration: 100);
        await Future.delayed(const Duration(milliseconds: 100));
        await Vibration.vibrate(duration: 100);
      }
    }

    // Show local notification (since data-only messages don't auto-show)
    final notificationTitle =
        data['notificationTitle'] ?? 'My 💓 beats for you';
    final notificationBody =
        data['notificationBody'] ?? 'You received a heartbeat!';

    await _showLocalNotification(
      title: notificationTitle,
      body: notificationBody,
      channelId: 'heartbeat_channel',
      channelName: 'Heartbeat',
    );
  }

  // If it's hugs, trigger hugs vibration and show notification
  if (messageType == 'hugs') {
    // Play hugs vibration pattern: long + short (hug + kiss)
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      final hasCustom = await Vibration.hasCustomVibrationsSupport();
      if (hasCustom == true) {
        // Long hug + pause + short kiss
        await Vibration.vibrate(
          pattern: [0, 600, 200, 100],
          intensities: [0, 200, 0, 255],
        );
      } else {
        // Fallback: long vibration then short
        await Vibration.vibrate(duration: 600);
        await Future.delayed(const Duration(milliseconds: 200));
        await Vibration.vibrate(duration: 100);
      }
    }

    // Show local notification
    final notificationTitle = data['notificationTitle'] ?? '🤗 Hugs & Kisses!';
    final notificationBody =
        data['notificationBody'] ?? 'You received hugs and kisses!';

    await _showLocalNotification(
      title: notificationTitle,
      body: notificationBody,
      channelId: 'heartbeat_channel',
      channelName: 'Hugs & Kisses',
    );
  }
}

/// Helper to show local notification in background
Future<void> _showLocalNotification({
  required String title,
  required String body,
  required String channelId,
  required String channelName,
}) async {
  final localNotifications = FlutterLocalNotificationsPlugin();
  await localNotifications.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_notification'),
    ),
  );

  await localNotifications.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: '$channelName notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@drawable/ic_notification',
        enableVibration: false, // We already vibrated manually
      ),
    ),
  );
}
