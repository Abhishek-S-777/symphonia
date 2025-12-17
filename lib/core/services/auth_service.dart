import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../constants/firebase_collections.dart';
import '../../features/auth/domain/entities/user.dart' as app;

/// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Auth State Provider - Stream of current user
final authStateChangesProvider = StreamProvider<fb.User?>((ref) {
  return fb.FirebaseAuth.instance.authStateChanges();
});

/// Current App User Provider
final currentAppUserProvider = StreamProvider<app.User?>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return authState.when(
    data: (fbUser) {
      if (fbUser == null) return Stream.value(null);
      return FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .doc(fbUser.uid)
          .snapshots()
          .map((doc) {
            if (!doc.exists) return null;
            return _userFromFirestore(doc);
          });
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

/// Partner User Provider
final partnerUserProvider = StreamProvider<app.User?>((ref) {
  final currentUser = ref.watch(currentAppUserProvider).value;
  if (currentUser == null || currentUser.coupleId == null) {
    return Stream.value(null);
  }

  return FirebaseFirestore.instance
      .collection(FirebaseCollections.couples)
      .doc(currentUser.coupleId)
      .snapshots()
      .asyncMap((coupleDoc) async {
        if (!coupleDoc.exists) return null;

        final data = coupleDoc.data()!;
        final partnerId =
            data[FirebaseCollections.coupleUser1Id] == currentUser.id
            ? data[FirebaseCollections.coupleUser2Id]
            : data[FirebaseCollections.coupleUser1Id];

        final partnerDoc = await FirebaseFirestore.instance
            .collection(FirebaseCollections.users)
            .doc(partnerId)
            .get();

        if (!partnerDoc.exists) return null;
        return _userFromFirestore(partnerDoc);
      });
});

app.User _userFromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  return app.User(
    id: doc.id,
    email: data[FirebaseCollections.userEmail] ?? '',
    displayName: data[FirebaseCollections.userDisplayName] ?? 'User',
    photoUrl: data[FirebaseCollections.userPhotoUrl],
    deviceId: data[FirebaseCollections.userDeviceId] ?? '',
    fcmToken: data[FirebaseCollections.userFcmToken],
    coupleId: data[FirebaseCollections.userCoupleId],
    createdAt:
        (data[FirebaseCollections.userCreatedAt] as Timestamp?)?.toDate() ??
        DateTime.now(),
    lastActive:
        (data[FirebaseCollections.userLastActive] as Timestamp?)?.toDate() ??
        DateTime.now(),
  );
}

/// Authentication Service
class AuthService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final _uuid = const Uuid();

  fb.User? get currentUser => _auth.currentUser;

  /// Sign up with email and password
  Future<fb.UserCredential> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Update display name in Firebase Auth
    await credential.user?.updateDisplayName(displayName);

    // Get FCM token
    String? fcmToken;
    try {
      fcmToken = await _messaging.getToken();
    } catch (_) {}

    // Create user document in Firestore
    await _firestore
        .collection(FirebaseCollections.users)
        .doc(credential.user!.uid)
        .set({
          FirebaseCollections.userEmail: email,
          FirebaseCollections.userDisplayName: displayName,
          FirebaseCollections.userPhotoUrl: null,
          FirebaseCollections.userDeviceId: _uuid.v4(),
          FirebaseCollections.userFcmToken: fcmToken,
          FirebaseCollections.userCoupleId: null,
          FirebaseCollections.userCreatedAt: FieldValue.serverTimestamp(),
          FirebaseCollections.userLastActive: FieldValue.serverTimestamp(),
        });

    return credential;
  }

  /// Sign in with email and password
  Future<fb.UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Update FCM token and last active
    String? fcmToken;
    try {
      fcmToken = await _messaging.getToken();
    } catch (_) {}

    // Use set with merge to create document if it doesn't exist
    await _firestore
        .collection(FirebaseCollections.users)
        .doc(credential.user!.uid)
        .set({
          FirebaseCollections.userEmail: email,
          FirebaseCollections.userDisplayName:
              credential.user!.displayName ?? 'User',
          FirebaseCollections.userFcmToken: fcmToken,
          FirebaseCollections.userLastActive: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    return credential;
  }

  /// Sign out
  Future<void> signOut() async {
    // Clear FCM token before signing out
    if (currentUser != null) {
      try {
        await _firestore
            .collection(FirebaseCollections.users)
            .doc(currentUser!.uid)
            .update({FirebaseCollections.userFcmToken: null});
      } catch (_) {}
    }
    await _auth.signOut();
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Update user profile
  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    if (currentUser == null) return;

    final updates = <String, dynamic>{};
    if (displayName != null) {
      updates[FirebaseCollections.userDisplayName] = displayName;
      await currentUser!.updateDisplayName(displayName);
    }
    if (photoUrl != null) {
      updates[FirebaseCollections.userPhotoUrl] = photoUrl;
      await currentUser!.updatePhotoURL(photoUrl);
    }

    if (updates.isNotEmpty) {
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(currentUser!.uid)
          .set(updates, SetOptions(merge: true));
    }
  }

  /// Update last active timestamp
  Future<void> updateLastActive() async {
    if (currentUser == null) return;

    try {
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(currentUser!.uid)
          .set({
            FirebaseCollections.userLastActive: FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Check if user is paired
  Future<bool> isPaired() async {
    if (currentUser == null) return false;

    final doc = await _firestore
        .collection(FirebaseCollections.users)
        .doc(currentUser!.uid)
        .get();

    if (!doc.exists) return false;
    return doc.data()?[FirebaseCollections.userCoupleId] != null;
  }

  /// Get current user's couple ID
  Future<String?> getCoupleId() async {
    if (currentUser == null) return null;

    final doc = await _firestore
        .collection(FirebaseCollections.users)
        .doc(currentUser!.uid)
        .get();

    if (!doc.exists) return null;
    return doc.data()?[FirebaseCollections.userCoupleId];
  }
}
