import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:symphonia/core/constants/app_constants.dart';
import 'package:symphonia/core/constants/firebase_collections.dart';
import 'package:symphonia/features/auth/data/auth_repository.dart';
import 'package:symphonia/features/auth/data/couple_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUser extends Mock implements fb.User {}

/// Tests for [CoupleRepository], the security-critical pairing flow, backed by
/// an in-memory [FakeFirebaseFirestore]. The repository reads the signed-in
/// user through [AuthRepository.currentUser], which is mocked to return a user
/// whose only relevant field is `uid`.
void main() {
  late FakeFirebaseFirestore firestore;
  late MockAuthRepository auth;
  late MockUser user;
  late CoupleRepository repo;

  // The current (redeeming) user in every test.
  const myUid = 'alice';

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = MockAuthRepository();
    user = MockUser();
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn(myUid);
    repo = CoupleRepository(auth, firestore: firestore);
  });

  Future<void> seedUser(String id, {String? coupleId, String? email}) {
    return firestore.collection(FirebaseCollections.users).doc(id).set({
      FirebaseCollections.userEmail: email ?? '$id@x.com',
      FirebaseCollections.userCoupleId: coupleId,
    });
  }

  Future<void> seedCode(
    String code, {
    required String creatorId,
    required DateTime expiresAt,
  }) {
    return firestore.collection(FirebaseCollections.pairingCodes).doc(code).set(
      {
        FirebaseCollections.pairingCodeCreatorId: creatorId,
        FirebaseCollections.pairingCodeExpiresAt: Timestamp.fromDate(
          expiresAt,
        ),
      },
    );
  }

  DocumentReference<Map<String, dynamic>> userDoc(String id) =>
      firestore.collection(FirebaseCollections.users).doc(id);

  final future = DateTime.now().add(const Duration(minutes: 10));
  final past = DateTime.now().subtract(const Duration(minutes: 10));

  group('createPairingCode', () {
    test('creates a code of the configured length owned by the user', () async {
      await seedUser(myUid);

      final code = await repo.createPairingCode();

      expect(code.length, AppConstants.pairingCodeLength);
      final codes = await firestore
          .collection(FirebaseCollections.pairingCodes)
          .get();
      expect(codes.docs, hasLength(1));
      expect(codes.docs.first.id, code);
      expect(
        codes.docs.first.data()[FirebaseCollections.pairingCodeCreatorId],
        myUid,
      );
    });

    test('replaces any existing code for the same user', () async {
      await seedUser(myUid);
      await seedCode('OLD123', creatorId: myUid, expiresAt: future);

      final code = await repo.createPairingCode();

      final codes = await firestore
          .collection(FirebaseCollections.pairingCodes)
          .get();
      expect(codes.docs, hasLength(1));
      expect(codes.docs.first.id, code);
    });
  });

  group('usePairingCode', () {
    test('creates a new couple and links both users', () async {
      await seedUser('bob');
      await seedUser(myUid);
      await seedCode('CODE12', creatorId: 'bob', expiresAt: future);

      final coupleId = await repo.usePairingCode('CODE12');

      final couple = await firestore
          .collection(FirebaseCollections.couples)
          .doc(coupleId)
          .get();
      expect(couple.exists, isTrue);
      expect(couple.data()![FirebaseCollections.coupleUser1Id], 'bob');
      expect(couple.data()![FirebaseCollections.coupleUser2Id], myUid);

      expect(
        (await userDoc('bob').get()).data()![FirebaseCollections.userCoupleId],
        coupleId,
      );
      expect(
        (await userDoc(myUid).get()).data()![FirebaseCollections.userCoupleId],
        coupleId,
      );

      // The pairing code is consumed.
      final code = await firestore
          .collection(FirebaseCollections.pairingCodes)
          .doc('CODE12')
          .get();
      expect(code.exists, isFalse);
    });

    test('reuses an existing couple document to preserve history', () async {
      await seedUser('bob');
      await seedUser(myUid);
      await firestore
          .collection(FirebaseCollections.couples)
          .doc('existingCouple')
          .set({
            FirebaseCollections.coupleUser1Id: 'bob',
            FirebaseCollections.coupleUser2Id: myUid,
          });
      await seedCode('CODE12', creatorId: 'bob', expiresAt: future);

      final coupleId = await repo.usePairingCode('CODE12');

      expect(coupleId, 'existingCouple');
      expect(
        (await userDoc(myUid).get()).data()![FirebaseCollections.userCoupleId],
        'existingCouple',
      );
    });

    test('rejects and removes an expired code', () async {
      await seedCode('CODE12', creatorId: 'bob', expiresAt: past);

      await expectLater(
        repo.usePairingCode('CODE12'),
        throwsA(isA<Exception>()),
      );
      final code = await firestore
          .collection(FirebaseCollections.pairingCodes)
          .doc('CODE12')
          .get();
      expect(code.exists, isFalse);
    });

    test('rejects pairing with yourself', () async {
      await seedCode('CODE12', creatorId: myUid, expiresAt: future);

      await expectLater(
        repo.usePairingCode('CODE12'),
        throwsA(isA<Exception>()),
      );
    });

    test('rejects a creator who is already paired', () async {
      await seedUser('bob', coupleId: 'anotherCouple');
      await seedCode('CODE12', creatorId: 'bob', expiresAt: future);

      await expectLater(
        repo.usePairingCode('CODE12'),
        throwsA(isA<Exception>()),
      );
    });

    test('rejects an unknown code', () async {
      await expectLater(
        repo.usePairingCode('NOPE12'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('unpair', () {
    test('clears the couple id on both users', () async {
      await firestore.collection(FirebaseCollections.couples).doc('c1').set({
        FirebaseCollections.coupleUser1Id: 'bob',
        FirebaseCollections.coupleUser2Id: myUid,
      });
      await seedUser('bob', coupleId: 'c1');
      await seedUser(myUid, coupleId: 'c1');

      await repo.unpair('c1');

      expect(
        (await userDoc('bob').get()).data()![FirebaseCollections.userCoupleId],
        isNull,
      );
      expect(
        (await userDoc(myUid).get()).data()![FirebaseCollections.userCoupleId],
        isNull,
      );
    });
  });
}
