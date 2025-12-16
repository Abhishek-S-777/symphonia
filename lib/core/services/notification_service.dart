import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../theme/app_colors.dart';

/// Provider for NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Service for local and push notifications
class NotificationService {
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz_data.initializeTimeZones();

    // Android initialization
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization (for future use)
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _isInitialized = true;
  }

  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap based on payload
    final payload = response.payload;
    if (payload != null) {
      // Navigate based on payload type
      // This will be connected to the router
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NOTIFICATION CHANNELS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Love messages channel
  static const AndroidNotificationChannel _messagesChannel =
      AndroidNotificationChannel(
        'symphonia_messages',
        'Love Messages',
        description: 'Notifications for love messages from your partner',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

  /// Voice notes channel
  static const AndroidNotificationChannel _voiceNotesChannel =
      AndroidNotificationChannel(
        'symphonia_voice_notes',
        'Voice Notes',
        description: 'Notifications for voice notes from your partner',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

  /// Heartbeat channel (for background service)
  static const AndroidNotificationChannel _heartbeatChannel =
      AndroidNotificationChannel(
        'symphonia_heartbeat',
        'Heartbeat Service',
        description: 'Background service for heartbeat feature',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      );

  /// Reminders channel
  static const AndroidNotificationChannel _remindersChannel =
      AndroidNotificationChannel(
        'symphonia_reminders',
        'Reminders',
        description: 'Scheduled reminders and event notifications',
        importance: Importance.defaultImportance,
        playSound: true,
        enableVibration: true,
      );

  /// Create notification channels (Android 8+)
  Future<void> createChannels() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_messagesChannel);
      await androidPlugin.createNotificationChannel(_voiceNotesChannel);
      await androidPlugin.createNotificationChannel(_heartbeatChannel);
      await androidPlugin.createNotificationChannel(_remindersChannel);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHOW NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Show a love message notification
  Future<void> showMessageNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'symphonia_messages',
      'Love Messages',
      channelDescription: 'Notifications for love messages from your partner',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: AppColors.primary,
      category: AndroidNotificationCategory.message,
    );

    final details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Show a voice note notification
  Future<void> showVoiceNoteNotification({
    required String senderName,
    required int durationSeconds,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'symphonia_voice_notes',
      'Voice Notes',
      channelDescription: 'Notifications for voice notes from your partner',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: AppColors.accent,
      category: AndroidNotificationCategory.message,
    );

    final details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '🎤 Voice Note from $senderName',
      '${durationSeconds}s voice note - Tap to listen',
      details,
      payload: payload,
    );
  }

  /// Show a heartbeat notification (when partner sends heartbeat)
  Future<void> showHeartbeatNotification({required String senderName}) async {
    final androidDetails = AndroidNotificationDetails(
      'symphonia_messages',
      'Love Messages',
      channelDescription: 'Notifications for love messages from your partner',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: AppColors.heartRed,
      category: AndroidNotificationCategory.message,
    );

    final details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '💓 $senderName sent you a heartbeat',
      'They\'re thinking of you right now',
      details,
    );
  }

  /// Show reminder notification
  Future<void> showReminderNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'symphonia_reminders',
      'Reminders',
      channelDescription: 'Scheduled reminders and event notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: AppColors.secondary,
    );

    final details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  /// Show foreground service notification (for background heartbeat)
  Future<void> showForegroundServiceNotification() async {
    final androidDetails = AndroidNotificationDetails(
      'symphonia_heartbeat',
      'Heartbeat Service',
      channelDescription: 'Background service for heartbeat feature',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      icon: '@mipmap/ic_launcher',
      color: AppColors.primary,
    );

    final details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      1,
      'Symphonia',
      'Sharing heartbeats with your partner',
      details,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SCHEDULED NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Schedule a notification for later
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'symphonia_reminders',
      'Reminders',
      channelDescription: 'Scheduled reminders and event notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: AppColors.primary,
    );

    final details = NotificationDetails(android: androidDetails);

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      _convertToTZDateTime(scheduledTime),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  /// Cancel a scheduled notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Convert DateTime to TZDateTime
  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.local);
  }
}
