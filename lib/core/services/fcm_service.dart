import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vibration/vibration.dart';

import '../constants/app_constants.dart';
import '../constants/firebase_collections.dart';

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

    debugPrint('📩 FCM Foreground message received: type=${data['type']}');

    // Handle location request - show notification AND share location
    if (data['type'] == 'request_location') {
      debugPrint('📍 Location request received in foreground');
      await _handleLocationRequest();
      // Show notification for location request
      // Use notification payload if available, otherwise use data payload
      final title =
          notification?.title ??
          data['notificationTitle'] ??
          '📍 Location Requested';
      final body =
          notification?.body ??
          data['notificationBody'] ??
          'Your partner wants to know where you are';
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'location_channel',
            'Location Requests',
            channelDescription: 'Location request notifications',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
          ),
        ),
      );
      return;
    }

    // Handle ring request - start ringing AND show notification
    if (data['type'] == 'ring_phone') {
      debugPrint('🔔 Ring request received in foreground');
      await _handleRingRequest();
      // Show notification for ring request
      // Use notification payload if available, otherwise use data payload
      final title =
          notification?.title ??
          data['notificationTitle'] ??
          '📍 Your partner is looking for you!';
      final body =
          notification?.body ??
          data['notificationBody'] ??
          'Tap to open the app';
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'ring_channel',
            'Ring Phone',
            channelDescription: 'Ring phone notifications',
            importance: Importance.max,
            priority: Priority.max,
            icon: '@drawable/ic_notification',
          ),
        ),
      );
      return;
    }

    // Handle stop ring request
    if (data['type'] == 'stop_ring') {
      debugPrint('🔔 Stop ring request received');
      await _handleStopRing();
      return;
    }

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

  /// Handle location request from partner - auto share location
  Future<void> _handleLocationRequest() async {
    debugPrint('📍 Location requested by partner - attempting auto-share');
    await _autoShareLocationForCurrentUser();
  }

  /// Handle ring request from partner - play alarm in foreground
  Future<void> _handleRingRequest() async {
    debugPrint('🔔 Ring requested by partner - playing alarm');
    try {
      // Start vibration pattern
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(
          pattern: [0, 1000, 500, 1000, 500, 1000],
          intensities: [0, 255, 0, 255, 0, 255],
        );
      }

      // Play alarm sound at max volume
      await FlutterRingtonePlayer().playAlarm(
        volume: 1.0,
        looping: true,
        asAlarm: true,
      );

      // Auto-stop after 30 seconds
      Future.delayed(const Duration(seconds: 30), () async {
        await FlutterRingtonePlayer().stop();
        await Vibration.cancel();
      });
    } catch (e) {
      debugPrint('🔔 Error playing alarm: $e');
    }
  }

  /// Handle stop ring request
  Future<void> _handleStopRing() async {
    debugPrint('🔔 Stop ring requested by partner');
    try {
      await FlutterRingtonePlayer().stop();
      await Vibration.cancel();
    } catch (e) {
      debugPrint('🔔 Error stopping ring: $e');
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
    final data = message.data;

    // Execute action payloads on tap/open so foreground and background
    // behavior are aligned.
    final type = data['type'];
    if (type == 'request_location') {
      unawaited(_handleLocationRequest());
    } else if (type == 'stop_ring') {
      unawaited(_handleStopRing());
    }

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
  await Firebase.initializeApp();

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

  // If it's a ring phone request, play ringtone and vibrate
  // Data-only message - we need to show notification AND play alarm
  if (messageType == 'ring_phone') {
    debugPrint('🔔 Background: Ring phone request received');

    // Show notification first
    final notificationTitle =
        data['notificationTitle'] ?? '📍 Your partner is looking for you!';
    final notificationBody = data['notificationBody'] ?? 'Tap to open the app';

    await _showLocalNotification(
      title: notificationTitle,
      body: notificationBody,
      channelId: 'ring_channel',
      channelName: 'Ring Phone',
      playSound: true,
    );

    // Play ringtone at max volume and vibrate
    await _playRingtoneInBackground();
  }

  // If it's a location request - show notification
  // Data-only message - we need to show notification
  if (messageType == 'request_location') {
    debugPrint('📍 Background: Location request received');

    // Try to auto-share location even in background isolate.
    await _autoShareLocationForCurrentUser();

    final notificationTitle =
        data['notificationTitle'] ?? '📍 Location Requested';
    final notificationBody =
        data['notificationBody'] ?? 'Your partner wants to know where you are';

    await _showLocalNotification(
      title: notificationTitle,
      body: notificationBody,
      channelId: 'location_channel',
      channelName: 'Location Requests',
      playSound: true,
    );
  }
}

/// Auto-share current user's location to couples/{coupleId}/locations/{userId}.
/// Returns true when location was successfully written to Firestore.
Future<bool> _autoShareLocationForCurrentUser() async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('📍 Location services disabled, cannot auto-share');
      return false;
    }

    final permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      debugPrint('📍 Location permission not granted, cannot auto-share');
      return false;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      debugPrint('📍 No authenticated user, cannot auto-share');
      return false;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection(FirebaseCollections.users)
        .doc(currentUser.uid)
        .get();

    final coupleId =
        userDoc.data()?[FirebaseCollections.userCoupleId] as String?;
    if (coupleId == null || coupleId.isEmpty) {
      debugPrint('📍 No coupleId found, cannot auto-share');
      return false;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    await FirebaseFirestore.instance
        .collection(FirebaseCollections.couples)
        .doc(coupleId)
        .collection('locations')
        .doc(currentUser.uid)
        .set({
          'userId': currentUser.uid,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    debugPrint(
      '📍 Location auto-shared successfully: ${position.latitude}, ${position.longitude}',
    );
    return true;
  } catch (e) {
    debugPrint('📍 Error auto-sharing location: $e');
    return false;
  }
}

/// Helper to show local notification in background
Future<void> _showLocalNotification({
  required String title,
  required String body,
  required String channelId,
  required String channelName,
  bool playSound = true,
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
        playSound: playSound,
      ),
    ),
  );
}

/// Helper to play ringtone at max volume in background
Future<void> _playRingtoneInBackground() async {
  try {
    // Start vibration pattern (simple pattern: vibrate, pause, repeat)
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      // Simple strong vibration pattern - vibrate for 1 second, pause 500ms, repeat
      await Vibration.vibrate(
        pattern: [0, 1000, 500, 1000, 500, 1000],
        intensities: [0, 255, 0, 255, 0, 255],
      );
    }

    // Play alarm/ringtone using flutter_ringtone_player
    // This will play at max volume even if phone is on silent
    await FlutterRingtonePlayer().playAlarm(
      volume: 1.0, // Max volume
      looping: true, // Keep playing until stopped
      asAlarm: true, // This makes it play even in silent mode
    );

    // Auto-stop after 30 seconds
    Future.delayed(const Duration(seconds: 30), () async {
      await FlutterRingtonePlayer().stop();
      await Vibration.cancel();
    });
  } catch (e) {
    // Fallback: just vibrate if ringtone fails
    debugPrint('Error playing ringtone in background: $e');
    await Vibration.vibrate(duration: 2000);
  }
}
