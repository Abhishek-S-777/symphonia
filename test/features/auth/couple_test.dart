import 'package:flutter_test/flutter_test.dart';
import 'package:symphonia/features/auth/domain/entities/couple.dart';

/// Tests for [Couple] derived values: days together, the formatted display
/// string, partner lookups, and the anniversary countdown.
///
/// `daysTogether` is anchored to "today" (midnight to midnight), so cases are
/// expressed as offsets from the current date to stay deterministic without a
/// clock injection.
void main() {
  DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  final today = dateOnly(DateTime.now());

  Couple buildCouple({DateTime? pairedAt, DateTime? anniversaryDate}) {
    return Couple(
      id: 'c1',
      user1Id: 'u1',
      user2Id: 'u2',
      user1Email: 'one@x.com',
      user2Email: 'two@x.com',
      pairedAt: pairedAt ?? today,
      anniversaryDate: anniversaryDate,
      settings: const CoupleSettings(),
    );
  }

  group('Couple.daysTogether', () {
    test('counts whole days since pairing', () {
      final couple = buildCouple(
        pairedAt: today.subtract(const Duration(days: 10)),
      );
      expect(couple.daysTogether, 10);
    });

    test('is zero on the pairing day', () {
      expect(buildCouple(pairedAt: today).daysTogether, 0);
    });

    test('counts a full year as 365 days', () {
      final couple = buildCouple(
        pairedAt: today.subtract(const Duration(days: 365)),
      );
      expect(couple.daysTogether, 365);
    });
  });

  group('Couple.daysTogetherFormatted', () {
    test('shows days below one year', () {
      final couple = buildCouple(
        pairedAt: today.subtract(const Duration(days: 10)),
      );
      expect(couple.daysTogetherFormatted, '10 days');
    });

    test('still shows days at 364', () {
      final couple = buildCouple(
        pairedAt: today.subtract(const Duration(days: 364)),
      );
      expect(couple.daysTogetherFormatted, '364 days');
    });

    test('switches to years at 365', () {
      final couple = buildCouple(
        pairedAt: today.subtract(const Duration(days: 365)),
      );
      expect(couple.daysTogetherFormatted, '1.0 years');
    });

    test('shows one decimal place of years', () {
      final couple = buildCouple(
        pairedAt: today.subtract(const Duration(days: 500)),
      );
      // 500 / 365 = 1.3698... which rounds to 1.4.
      expect(couple.daysTogetherFormatted, '1.4 years');
    });

    // The years figure divides by a flat 365, so it ignores leap days. Two
    // calendar years can be 730 or 731 days depending on leap years; both are
    // reported as "2.0 years" (731 / 365 = 2.0027 -> "2.0"). This documents the
    // current behaviour; whether to switch to a calendar-accurate calculation
    // is a product decision because it changes what users see.
    test('treats 730 days as 2.0 years (flat 365-day approximation)', () {
      final couple = buildCouple(
        pairedAt: today.subtract(const Duration(days: 730)),
      );
      expect(couple.daysTogetherFormatted, '2.0 years');
    });
  });

  group('Couple partner helpers', () {
    final couple = buildCouple();

    test('containsUser is true for members only', () {
      expect(couple.containsUser('u1'), isTrue);
      expect(couple.containsUser('u2'), isTrue);
      expect(couple.containsUser('stranger'), isFalse);
    });

    test('getPartnerId returns the other member', () {
      expect(couple.getPartnerId('u1'), 'u2');
      expect(couple.getPartnerId('u2'), 'u1');
    });

    test('getPartnerEmail returns the other member email', () {
      expect(couple.getPartnerEmail('u1'), 'two@x.com');
      expect(couple.getPartnerEmail('u2'), 'one@x.com');
    });
  });

  group('Couple.daysUntilAnniversary', () {
    test('is null when no anniversary is set', () {
      expect(buildCouple().daysUntilAnniversary, isNull);
    });

    test('is non-negative when an anniversary is set', () {
      final couple = buildCouple(anniversaryDate: DateTime(2000, 6, 15));
      final days = couple.daysUntilAnniversary;
      expect(days, isNotNull);
      expect(days, greaterThanOrEqualTo(0));
    });
  });
}
