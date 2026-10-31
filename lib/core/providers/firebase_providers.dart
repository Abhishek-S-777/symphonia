import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared providers for the Firebase SDK singletons.
///
/// Every repository and service reads its Firebase dependencies from these
/// providers instead of touching `FirebaseFirestore.instance` (and friends)
/// directly. The runtime value is identical to the singleton, but routing it
/// through providers gives a single override point: tests replace these with
/// fakes (for example `fake_cloud_firestore`) via `ProviderScope.overrides`.
final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final firebaseStorageProvider = Provider<FirebaseStorage>(
  (ref) => FirebaseStorage.instance,
);

final firebaseMessagingProvider = Provider<FirebaseMessaging>(
  (ref) => FirebaseMessaging.instance,
);
