import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/firebase_collections.dart';
import '../constants/app_constants.dart';
import '../../features/auth/domain/entities/couple.dart';
import 'auth_service.dart';

/// Couple Service Provider
final coupleServiceProvider = Provider<CoupleService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return CoupleService(authService);
});

/// Current Couple Provider
final currentCoupleProvider = StreamProvider<Couple?>((ref) {
  final currentUser = ref.watch(currentAppUserProvider).value;
  if (currentUser == null || currentUser.coupleId == null) {
    return Stream.value(null);
  }

  return FirebaseFirestore.instance
      .collection(FirebaseCollections.couples)
      .doc(currentUser.coupleId)
      .snapshots()
      .map((doc) {
        if (!doc.exists) return null;
        return _coupleFromFirestore(doc);
      });
});

Couple _coupleFromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  final settingsData =
      data[FirebaseCollections.coupleSettings] as Map<String, dynamic>? ?? {};

  return Couple(
    id: doc.id,
    user1Id: data[FirebaseCollections.coupleUser1Id] ?? '',
    user2Id: data[FirebaseCollections.coupleUser2Id] ?? '',
    user1Email: data[FirebaseCollections.coupleUser1Email] ?? '',
    user2Email: data[FirebaseCollections.coupleUser2Email] ?? '',
    pairedAt:
        (data[FirebaseCollections.couplePairedAt] as Timestamp?)?.toDate() ??
        DateTime.now(),
    anniversaryDate:
        (data[FirebaseCollections.coupleAnniversaryDate] as Timestamp?)
            ?.toDate(),
    settings: CoupleSettings(
      heartbeatEnabled: settingsData['heartbeatEnabled'] ?? true,
      notificationsEnabled: settingsData['notificationsEnabled'] ?? true,
      soundEnabled: settingsData['soundEnabled'] ?? true,
      vibrationEnabled: settingsData['vibrationEnabled'] ?? true,
    ),
  );
}

/// Couple Service for pairing operations
class CoupleService {
  final AuthService _authService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CoupleService(this._authService);

  /// Generate a pairing code
  String _generatePairingCode() {
    final random = Random.secure();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(
      AppConstants.pairingCodeLength,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  /// Create a pairing code and store in Firestore
  Future<String> createPairingCode() async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final code = _generatePairingCode();
    final expiresAt = DateTime.now().add(
      Duration(minutes: AppConstants.pairingCodeExpiryMinutes),
    );

    // Delete any existing pairing codes for this user
    final existingCodes = await _firestore
        .collection(FirebaseCollections.pairingCodes)
        .where(FirebaseCollections.pairingCodeCreatorId, isEqualTo: user.uid)
        .get();

    for (final doc in existingCodes.docs) {
      await doc.reference.delete();
    }

    // Create new pairing code
    await _firestore.collection(FirebaseCollections.pairingCodes).doc(code).set(
      {
        FirebaseCollections.pairingCodeCreatorId: user.uid,
        FirebaseCollections.pairingCodeCreatedAt: FieldValue.serverTimestamp(),
        FirebaseCollections.pairingCodeExpiresAt: Timestamp.fromDate(expiresAt),
      },
    );

    return code;
  }

  /// Validate and use a pairing code
  Future<String> usePairingCode(String code) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final codeDoc = await _firestore
        .collection(FirebaseCollections.pairingCodes)
        .doc(code.toUpperCase())
        .get();

    if (!codeDoc.exists) {
      throw Exception('Invalid pairing code');
    }

    final codeData = codeDoc.data()!;
    final creatorId =
        codeData[FirebaseCollections.pairingCodeCreatorId] as String;
    final expiresAt =
        (codeData[FirebaseCollections.pairingCodeExpiresAt] as Timestamp)
            .toDate();

    // Check if code is expired
    if (DateTime.now().isAfter(expiresAt)) {
      await codeDoc.reference.delete();
      throw Exception('Pairing code has expired');
    }

    // Check if trying to pair with self
    if (creatorId == user.uid) {
      throw Exception('Cannot pair with yourself');
    }

    // Get creator's user document
    final creatorDoc = await _firestore
        .collection(FirebaseCollections.users)
        .doc(creatorId)
        .get();

    if (!creatorDoc.exists) {
      throw Exception('Partner not found');
    }

    // Check if creator is already paired
    if (creatorDoc.data()?[FirebaseCollections.userCoupleId] != null) {
      throw Exception('Partner is already paired with someone else');
    }

    // Get current user's document
    final currentUserDoc = await _firestore
        .collection(FirebaseCollections.users)
        .doc(user.uid)
        .get();

    // Create couple document
    final coupleRef = _firestore.collection(FirebaseCollections.couples).doc();

    await _firestore.runTransaction((transaction) async {
      // Create couple
      transaction.set(coupleRef, {
        FirebaseCollections.coupleUser1Id: creatorId,
        FirebaseCollections.coupleUser2Id: user.uid,
        FirebaseCollections.coupleUser1Email: creatorDoc
            .data()?[FirebaseCollections.userEmail],
        FirebaseCollections.coupleUser2Email: currentUserDoc
            .data()?[FirebaseCollections.userEmail],
        FirebaseCollections.couplePairedAt: FieldValue.serverTimestamp(),
        FirebaseCollections.coupleAnniversaryDate: null,
        FirebaseCollections.coupleSettings: {
          'heartbeatEnabled': true,
          'notificationsEnabled': true,
          'soundEnabled': true,
          'vibrationEnabled': true,
        },
      });

      // Update both users with couple ID
      transaction.update(
        _firestore.collection(FirebaseCollections.users).doc(creatorId),
        {FirebaseCollections.userCoupleId: coupleRef.id},
      );
      transaction.update(
        _firestore.collection(FirebaseCollections.users).doc(user.uid),
        {FirebaseCollections.userCoupleId: coupleRef.id},
      );

      // Delete the pairing code
      transaction.delete(codeDoc.reference);
    });

    return coupleRef.id;
  }

  /// Update couple settings
  Future<void> updateSettings(String coupleId, CoupleSettings settings) async {
    await _firestore
        .collection(FirebaseCollections.couples)
        .doc(coupleId)
        .update({
          FirebaseCollections.coupleSettings: {
            'heartbeatEnabled': settings.heartbeatEnabled,
            'notificationsEnabled': settings.notificationsEnabled,
            'soundEnabled': settings.soundEnabled,
            'vibrationEnabled': settings.vibrationEnabled,
          },
        });
  }

  /// Update anniversary date
  Future<void> updateAnniversaryDate(String coupleId, DateTime date) async {
    await _firestore
        .collection(FirebaseCollections.couples)
        .doc(coupleId)
        .update({
          FirebaseCollections.coupleAnniversaryDate: Timestamp.fromDate(date),
        });
  }

  /// Unpair (delete couple relationship)
  Future<void> unpair(String coupleId) async {
    final coupleDoc = await _firestore
        .collection(FirebaseCollections.couples)
        .doc(coupleId)
        .get();

    if (!coupleDoc.exists) return;

    final data = coupleDoc.data()!;
    final user1Id = data[FirebaseCollections.coupleUser1Id] as String;
    final user2Id = data[FirebaseCollections.coupleUser2Id] as String;

    await _firestore.runTransaction((transaction) async {
      // Remove couple ID from both users
      transaction.update(
        _firestore.collection(FirebaseCollections.users).doc(user1Id),
        {FirebaseCollections.userCoupleId: null},
      );
      transaction.update(
        _firestore.collection(FirebaseCollections.users).doc(user2Id),
        {FirebaseCollections.userCoupleId: null},
      );

      // Delete couple document
      transaction.delete(coupleDoc.reference);
    });
  }
}
