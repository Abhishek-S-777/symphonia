import 'package:flutter_test/flutter_test.dart';
import 'package:symphonia/features/events/domain/entities/event.dart';

/// Tests for [Event] date logic (daysUntil, nextOccurrence, recurrence).
///
/// The entity reads `DateTime.now()` internally, so every case is anchored to
/// "today" rather than a hard-coded calendar date. That keeps the assertions
/// deterministic without having to inject a clock: the logic works on
/// midnight-normalised dates, so the time of day the test runs at does not
/// affect the expected day counts.
void main() {
  DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  final today = dateOnly(DateTime.now());

  Event buildEvent({
    required DateTime eventDate,
    bool isRecurring = false,
    RecurringType recurringType = RecurringType.none,
  }) {
    return Event(
      id: 'e1',
      creatorId: 'u1',
      title: 'Test',
      eventDate: eventDate,
      createdAt: today,
      isRecurring: isRecurring,
      recurringType: recurringType,
    );
  }

  group('Event.daysUntil (non-recurring)', () {
    test('future event returns the number of days away', () {
      final event = buildEvent(eventDate: today.add(const Duration(days: 5)));
      expect(event.daysUntil, 5);
      expect(event.isToday, isFalse);
      expect(event.isPast, isFalse);
    });

    test('event today returns zero and isToday is true', () {
      final event = buildEvent(eventDate: today);
      expect(event.daysUntil, 0);
      expect(event.isToday, isTrue);
      expect(event.isPast, isFalse);
    });

    test('past event returns a negative count and isPast is true', () {
      final event = buildEvent(
        eventDate: today.subtract(const Duration(days: 3)),
      );
      expect(event.daysUntil, -3);
      expect(event.isPast, isTrue);
      expect(event.isToday, isFalse);
    });

    test('nextOccurrence of a non-recurring event is its own date', () {
      final date = today.add(const Duration(days: 12));
      final event = buildEvent(eventDate: date);
      expect(event.nextOccurrence, date);
    });
  });

  group('Event.daysUntil (recurring)', () {
    test('yearly event whose month/day is today recurs today', () {
      final event = buildEvent(
        eventDate: DateTime(2000, today.month, today.day),
        isRecurring: true,
        recurringType: RecurringType.yearly,
      );
      expect(event.daysUntil, 0);
      expect(event.isToday, isTrue);
      // A recurring event is never reported as "past".
      expect(event.isPast, isFalse);
    });

    test('monthly event whose day is today recurs today', () {
      final event = buildEvent(
        eventDate: DateTime(2000, 1, today.day),
        isRecurring: true,
        recurringType: RecurringType.monthly,
      );
      expect(event.daysUntil, 0);
      expect(event.isToday, isTrue);
    });

    test('weekly event on the same weekday recurs in seven days', () {
      final event = buildEvent(
        eventDate: today.subtract(const Duration(days: 7)),
        isRecurring: true,
        recurringType: RecurringType.weekly,
      );
      expect(event.daysUntil, 7);
    });

    test('weekly event from six days ago recurs tomorrow', () {
      final event = buildEvent(
        eventDate: today.subtract(const Duration(days: 6)),
        isRecurring: true,
        recurringType: RecurringType.weekly,
      );
      expect(event.daysUntil, 1);
    });

    test(
      'recurring event with a future original date is not rolled forward',
      () {
        final future = DateTime(2100, 6, 15);
        final event = buildEvent(
          eventDate: future,
          isRecurring: true,
          recurringType: RecurringType.yearly,
        );
        expect(event.nextOccurrence, future);
      },
    );
  });

  group('TimeOfDay.formatted', () {
    test('formats midnight as 12 AM', () {
      expect(const TimeOfDay(hour: 0, minute: 0).formatted, '12:00 AM');
    });

    test('formats noon as 12 PM', () {
      expect(const TimeOfDay(hour: 12, minute: 0).formatted, '12:00 PM');
    });

    test('formats an afternoon time with zero-padded minutes', () {
      expect(const TimeOfDay(hour: 13, minute: 5).formatted, '1:05 PM');
    });

    test('formats a morning time', () {
      expect(const TimeOfDay(hour: 9, minute: 30).formatted, '9:30 AM');
    });

    test('formats one minute before midnight', () {
      expect(const TimeOfDay(hour: 23, minute: 59).formatted, '11:59 PM');
    });
  });
}
