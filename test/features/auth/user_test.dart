import 'package:flutter_test/flutter_test.dart';
import 'package:symphonia/features/auth/domain/entities/user.dart';

/// Tests for [User] derived values: pairing status and the "last seen" label.
///
/// `lastSeenText` is relative to `DateTime.now()`, so each case sets
/// `lastActive` as an offset from now. The thresholds floor to whole
/// minutes/hours/days, so the small delay between building the user and reading
/// the getter does not change the bucket.
void main() {
  User buildUser({
    String? coupleId,
    bool isOnline = false,
    DateTime? lastActive,
  }) {
    final now = DateTime.now();
    return User(
      id: 'u1',
      email: 'u@x.com',
      displayName: 'User',
      deviceId: 'd1',
      createdAt: now,
      lastActive: lastActive ?? now,
      coupleId: coupleId,
      isOnline: isOnline,
    );
  }

  group('User.isPaired', () {
    test('is false without a coupleId', () {
      expect(buildUser().isPaired, isFalse);
    });

    test('is true with a coupleId', () {
      expect(buildUser(coupleId: 'c1').isPaired, isTrue);
    });
  });

  group('User.lastSeenText', () {
    test('reports Online when flagged online', () {
      expect(buildUser(isOnline: true).lastSeenText, 'Online');
    });

    test('reports Just now within the last minute', () {
      final user = buildUser(
        lastActive: DateTime.now().subtract(const Duration(seconds: 30)),
      );
      expect(user.lastSeenText, 'Just now');
    });

    test('reports minutes within the hour', () {
      final user = buildUser(
        lastActive: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      expect(user.lastSeenText, '5m ago');
    });

    test('reports hours within the day', () {
      final user = buildUser(
        lastActive: DateTime.now().subtract(const Duration(hours: 2)),
      );
      expect(user.lastSeenText, '2h ago');
    });

    test('reports days within the week', () {
      final user = buildUser(
        lastActive: DateTime.now().subtract(const Duration(days: 3)),
      );
      expect(user.lastSeenText, '3d ago');
    });

    test('reports a while ago beyond a week', () {
      final user = buildUser(
        lastActive: DateTime.now().subtract(const Duration(days: 10)),
      );
      expect(user.lastSeenText, 'A while ago');
    });
  });
}
