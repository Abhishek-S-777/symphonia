import 'package:equatable/equatable.dart';

/// Event entity for countdowns and special dates
class Event extends Equatable {
  final String id;
  final String creatorId;
  final String title;
  final String? description;
  final DateTime eventDate;
  final bool isRecurring;
  final RecurringType recurringType;
  final DateTime createdAt;
  final TimeOfDay? notificationTime;
  final bool notificationsEnabled;

  const Event({
    required this.id,
    required this.creatorId,
    required this.title,
    this.description,
    required this.eventDate,
    this.isRecurring = false,
    this.recurringType = RecurringType.none,
    required this.createdAt,
    this.notificationTime,
    this.notificationsEnabled = true,
  });

  /// Days until the event
  int get daysUntil {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime targetDate = DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
    );

    if (isRecurring && targetDate.isBefore(today)) {
      // Calculate next occurrence
      switch (recurringType) {
        case RecurringType.yearly:
          targetDate = DateTime(now.year, eventDate.month, eventDate.day);
          if (targetDate.isBefore(today)) {
            targetDate = DateTime(now.year + 1, eventDate.month, eventDate.day);
          }
          break;
        case RecurringType.monthly:
          targetDate = DateTime(now.year, now.month, eventDate.day);
          if (targetDate.isBefore(today)) {
            targetDate = DateTime(now.year, now.month + 1, eventDate.day);
          }
          break;
        case RecurringType.weekly:
          final daysUntilNext = (eventDate.weekday - now.weekday + 7) % 7;
          targetDate = today.add(
            Duration(days: daysUntilNext == 0 ? 7 : daysUntilNext),
          );
          break;
        case RecurringType.none:
          break;
      }
    }

    return targetDate.difference(today).inDays;
  }

  /// Check if event is today
  bool get isToday => daysUntil == 0;

  /// Check if event is past (for non-recurring events)
  bool get isPast => !isRecurring && daysUntil < 0;

  /// Get next occurrence date
  DateTime get nextOccurrence {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime targetDate = DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
    );

    if (isRecurring && targetDate.isBefore(today)) {
      switch (recurringType) {
        case RecurringType.yearly:
          targetDate = DateTime(now.year, eventDate.month, eventDate.day);
          if (targetDate.isBefore(today)) {
            targetDate = DateTime(now.year + 1, eventDate.month, eventDate.day);
          }
          break;
        case RecurringType.monthly:
          targetDate = DateTime(now.year, now.month, eventDate.day);
          if (targetDate.isBefore(today)) {
            targetDate = DateTime(now.year, now.month + 1, eventDate.day);
          }
          break;
        case RecurringType.weekly:
          final daysUntilNext = (eventDate.weekday - now.weekday + 7) % 7;
          targetDate = today.add(
            Duration(days: daysUntilNext == 0 ? 7 : daysUntilNext),
          );
          break;
        case RecurringType.none:
          break;
      }
    }

    return targetDate;
  }

  Event copyWith({
    String? id,
    String? creatorId,
    String? title,
    String? description,
    DateTime? eventDate,
    bool? isRecurring,
    RecurringType? recurringType,
    DateTime? createdAt,
    TimeOfDay? notificationTime,
    bool? notificationsEnabled,
  }) {
    return Event(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      title: title ?? this.title,
      description: description ?? this.description,
      eventDate: eventDate ?? this.eventDate,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringType: recurringType ?? this.recurringType,
      createdAt: createdAt ?? this.createdAt,
      notificationTime: notificationTime ?? this.notificationTime,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  @override
  List<Object?> get props => [
    id,
    creatorId,
    title,
    description,
    eventDate,
    isRecurring,
    recurringType,
    createdAt,
    notificationTime,
    notificationsEnabled,
  ];
}

/// Recurring type for events
enum RecurringType { none, weekly, monthly, yearly }

/// Time of day for notifications
class TimeOfDay extends Equatable {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  String get formatted {
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  @override
  List<Object> get props => [hour, minute];
}
