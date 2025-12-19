import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import '../constants/firebase_collections.dart';
import '../../features/events/domain/entities/event.dart';
import 'auth_service.dart';

/// Event Service Provider
final eventServiceProvider = Provider<EventService>((ref) {
  return EventService(ref);
});

/// Events Stream Provider
/// Uses select() to only rebuild when coupleId changes, not on every user update
final eventsStreamProvider = StreamProvider<List<Event>>((ref) {
  // Only watch the coupleId, not the entire user object
  // This prevents rebuilds when lastActive, isOnline, etc. change
  final coupleId = ref.watch(
    currentAppUserProvider.select((asyncUser) => asyncUser.value?.coupleId),
  );

  if (coupleId == null) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection(FirebaseCollections.couples)
      .doc(coupleId)
      .collection(FirebaseCollections.events)
      .orderBy(FirebaseCollections.eventDate)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => _eventFromFirestore(doc)).toList();
      });
});

/// Upcoming Events Provider (next 7 days)
final upcomingEventsProvider = Provider<List<Event>>((ref) {
  final events = ref.watch(eventsStreamProvider).value ?? [];
  return events.where((e) => e.daysUntil >= 0 && e.daysUntil <= 7).toList()
    ..sort((a, b) => a.daysUntil.compareTo(b.daysUntil));
});

Event _eventFromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  final notifTimeData = data['notificationTime'] as Map<String, dynamic>?;

  return Event(
    id: doc.id,
    creatorId: data[FirebaseCollections.eventCreatorId] ?? '',
    title: data[FirebaseCollections.eventTitle] ?? '',
    description: data[FirebaseCollections.eventDescription],
    eventDate:
        (data[FirebaseCollections.eventDate] as Timestamp?)?.toDate() ??
        DateTime.now(),
    isRecurring: data[FirebaseCollections.eventIsRecurring] ?? false,
    recurringType: RecurringType.values.firstWhere(
      (e) => e.name == data[FirebaseCollections.eventRecurringType],
      orElse: () => RecurringType.none,
    ),
    createdAt:
        (data[FirebaseCollections.eventCreatedAt] as Timestamp?)?.toDate() ??
        DateTime.now(),
    notificationTime: notifTimeData != null
        ? TimeOfDay(
            hour: notifTimeData['hour'] ?? 9,
            minute: notifTimeData['minute'] ?? 0,
          )
        : const TimeOfDay(hour: 9, minute: 0),
    notificationsEnabled: data['notificationsEnabled'] ?? true,
  );
}

/// Event Service for managing events and countdowns
class EventService {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  EventService(this._ref) {
    tz.initializeTimeZones();
  }

  /// Create a new event
  Future<Event> createEvent({
    required String title,
    String? description,
    required DateTime eventDate,
    bool isRecurring = false,
    RecurringType recurringType = RecurringType.none,
    TimeOfDay notificationTime = const TimeOfDay(hour: 9, minute: 0),
    bool notificationsEnabled = true,
  }) async {
    final currentUser = _ref.read(currentAppUserProvider).value;
    if (currentUser == null || currentUser.coupleId == null) {
      throw Exception('User not authenticated or not paired');
    }

    final eventRef = _firestore
        .collection(FirebaseCollections.couples)
        .doc(currentUser.coupleId)
        .collection(FirebaseCollections.events)
        .doc();

    final event = Event(
      id: eventRef.id,
      creatorId: currentUser.id,
      title: title,
      description: description,
      eventDate: eventDate,
      isRecurring: isRecurring,
      recurringType: recurringType,
      createdAt: DateTime.now(),
      notificationTime: notificationTime,
      notificationsEnabled: notificationsEnabled,
    );

    // Prepare notification data for partner notification
    final notificationTitle = '📅 New Event Added';
    final notificationBody = '${currentUser.displayName} added: $title';

    await eventRef.set({
      FirebaseCollections.eventCreatorId: currentUser.id,
      FirebaseCollections.eventTitle: title,
      FirebaseCollections.eventDescription: description,
      FirebaseCollections.eventDate: Timestamp.fromDate(eventDate),
      FirebaseCollections.eventIsRecurring: isRecurring,
      FirebaseCollections.eventRecurringType: recurringType.name,
      FirebaseCollections.eventCreatedAt: FieldValue.serverTimestamp(),
      'notificationTime': {
        'hour': notificationTime.hour,
        'minute': notificationTime.minute,
      },
      'notificationsEnabled': notificationsEnabled,
      // Notification fields - Cloud Function will read and forward these
      'notificationTitle': notificationTitle,
      'notificationBody': notificationBody,
      'notificationChannelId': 'event_channel',
      'notificationType': 'event_created',
    });

    // Schedule local notifications for countdown reminders
    if (notificationsEnabled) {
      await _scheduleEventNotifications(event);
    }

    return event;
  }

  /// Update an event
  Future<void> updateEvent(Event event) async {
    final currentUser = _ref.read(currentAppUserProvider).value;
    if (currentUser == null || currentUser.coupleId == null) return;

    await _firestore
        .collection(FirebaseCollections.couples)
        .doc(currentUser.coupleId)
        .collection(FirebaseCollections.events)
        .doc(event.id)
        .update({
          FirebaseCollections.eventTitle: event.title,
          FirebaseCollections.eventDescription: event.description,
          FirebaseCollections.eventDate: Timestamp.fromDate(event.eventDate),
          FirebaseCollections.eventIsRecurring: event.isRecurring,
          FirebaseCollections.eventRecurringType: event.recurringType.name,
          'notificationTime': event.notificationTime != null
              ? {
                  'hour': event.notificationTime!.hour,
                  'minute': event.notificationTime!.minute,
                }
              : null,
          'notificationsEnabled': event.notificationsEnabled,
        });

    // Cancel and reschedule notifications
    await _cancelEventNotifications(event.id);
    if (event.notificationsEnabled) {
      await _scheduleEventNotifications(event);
    }
  }

  /// Delete an event
  Future<void> deleteEvent(String eventId) async {
    final currentUser = _ref.read(currentAppUserProvider).value;
    if (currentUser == null || currentUser.coupleId == null) return;

    await _firestore
        .collection(FirebaseCollections.couples)
        .doc(currentUser.coupleId)
        .collection(FirebaseCollections.events)
        .doc(eventId)
        .delete();

    await _cancelEventNotifications(eventId);
  }

  /// Schedule notifications for an event
  Future<void> _scheduleEventNotifications(Event event) async {
    if (!event.notificationsEnabled || event.notificationTime == null) return;

    final now = DateTime.now();
    final nextOccurrence = event.nextOccurrence;

    // Schedule daily countdown notifications
    for (int i = 0; i <= event.daysUntil && i <= 30; i++) {
      final notificationDate = nextOccurrence.subtract(Duration(days: i));
      final scheduledTime = DateTime(
        notificationDate.year,
        notificationDate.month,
        notificationDate.day,
        event.notificationTime!.hour,
        event.notificationTime!.minute,
      );

      if (scheduledTime.isAfter(now)) {
        final daysLeft = i;
        String body;
        if (daysLeft == 0) {
          body = '🎉 Today is ${event.title}!';
        } else if (daysLeft == 1) {
          body = '⏰ Tomorrow is ${event.title}!';
        } else {
          body = '📅 $daysLeft days until ${event.title}!';
        }

        await _notifications.zonedSchedule(
          event.id.hashCode + i,
          'Symphonia Countdown',
          body,
          tz.TZDateTime.from(scheduledTime, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'events',
              'Events',
              channelDescription: 'Event countdown notifications',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    }
  }

  /// Cancel notifications for an event
  Future<void> _cancelEventNotifications(String eventId) async {
    // Cancel all potential notifications for this event
    for (int i = 0; i <= 30; i++) {
      await _notifications.cancel(eventId.hashCode + i);
    }
  }

  /// Reschedule all notifications (call on app start)
  Future<void> rescheduleAllNotifications() async {
    final events = _ref.read(eventsStreamProvider).value ?? [];
    for (final event in events) {
      if (event.notificationsEnabled) {
        await _scheduleEventNotifications(event);
      }
    }
  }
}
