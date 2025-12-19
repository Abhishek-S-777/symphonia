import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../constants/firebase_collections.dart';
import '../../features/gallery/domain/entities/memory.dart';
import 'auth_service.dart';
import 'fcm_service.dart';

/// Gallery Service Provider
final galleryServiceProvider = Provider<GalleryService>((ref) {
  return GalleryService(ref);
});

/// Memories Stream Provider
/// Uses select() to only rebuild when coupleId changes
final memoriesStreamProvider = StreamProvider<List<Memory>>((ref) {
  final coupleId = ref.watch(
    currentAppUserProvider.select((asyncUser) => asyncUser.value?.coupleId),
  );
  if (coupleId == null) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection(FirebaseCollections.couples)
      .doc(coupleId)
      .collection(FirebaseCollections.memories)
      .orderBy(FirebaseCollections.memoryDate, descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => _memoryFromFirestore(doc)).toList();
      });
});

Memory _memoryFromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  return Memory(
    id: doc.id,
    creatorId: data[FirebaseCollections.memoryCreatorId] ?? '',
    imageUrls: List<String>.from(
      data[FirebaseCollections.memoryImageUrls] ?? [],
    ),
    localPaths: const [],
    note: data[FirebaseCollections.memoryNote],
    date:
        (data[FirebaseCollections.memoryDate] as Timestamp?)?.toDate() ??
        DateTime.now(),
    createdAt:
        (data[FirebaseCollections.memoryCreatedAt] as Timestamp?)?.toDate() ??
        DateTime.now(),
    isSynced: data[FirebaseCollections.memoryIsSynced] ?? true,
  );
}

/// Gallery Service for managing memories and photos
class GalleryService {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final _uuid = const Uuid();

  GalleryService(this._ref);

  /// Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    return image != null ? File(image.path) : null;
  }

  /// Pick image from camera
  Future<File?> pickImageFromCamera() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    return image != null ? File(image.path) : null;
  }

  /// Pick multiple images
  Future<List<File>> pickMultipleImages() async {
    final List<XFile> images = await _imagePicker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    return images.map((image) => File(image.path)).toList();
  }

  /// Upload image to Firebase Storage
  Future<String> _uploadImage(File file) async {
    final currentUser = _ref.read(currentAppUserProvider).value;
    if (currentUser == null || currentUser.coupleId == null) {
      throw Exception('User not authenticated or not paired');
    }

    final fileName = '${_uuid.v4()}${path.extension(file.path)}';
    final storageRef = _storage
        .ref()
        .child('couples')
        .child(currentUser.coupleId!)
        .child('memories')
        .child(fileName);

    final uploadTask = await storageRef.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await uploadTask.ref.getDownloadURL();
  }

  /// Create a new memory
  Future<Memory> createMemory({
    required List<File> images,
    String? note,
    DateTime? date,
  }) async {
    final currentUser = _ref.read(currentAppUserProvider).value;
    if (currentUser == null || currentUser.coupleId == null) {
      throw Exception('User not authenticated or not paired');
    }

    if (images.isEmpty) {
      throw Exception('At least one image is required');
    }

    // Upload all images
    final imageUrls = <String>[];
    for (final image in images) {
      final url = await _uploadImage(image);
      imageUrls.add(url);
    }

    final memoryDate = date ?? DateTime.now();

    // Create Firestore document
    final memoryRef = _firestore
        .collection(FirebaseCollections.couples)
        .doc(currentUser.coupleId)
        .collection(FirebaseCollections.memories)
        .doc();

    final memory = Memory(
      id: memoryRef.id,
      creatorId: currentUser.id,
      imageUrls: imageUrls,
      localPaths: images.map((f) => f.path).toList(),
      note: note,
      date: memoryDate,
      createdAt: DateTime.now(),
      isSynced: true,
    );

    await memoryRef.set({
      FirebaseCollections.memoryCreatorId: currentUser.id,
      FirebaseCollections.memoryImageUrls: imageUrls,
      FirebaseCollections.memoryNote: note,
      FirebaseCollections.memoryDate: Timestamp.fromDate(memoryDate),
      FirebaseCollections.memoryCreatedAt: FieldValue.serverTimestamp(),
      FirebaseCollections.memoryIsSynced: true,
    });

    // Send notification to partner
    _sendNotificationToPartner(note);

    return memory;
  }

  /// Update a memory's note
  Future<void> updateMemoryNote(String memoryId, String? note) async {
    final currentUser = _ref.read(currentAppUserProvider).value;
    if (currentUser == null || currentUser.coupleId == null) return;

    await _firestore
        .collection(FirebaseCollections.couples)
        .doc(currentUser.coupleId)
        .collection(FirebaseCollections.memories)
        .doc(memoryId)
        .update({FirebaseCollections.memoryNote: note});
  }

  /// Delete a memory
  Future<void> deleteMemory(Memory memory) async {
    final currentUser = _ref.read(currentAppUserProvider).value;
    if (currentUser == null || currentUser.coupleId == null) return;

    // Delete images from Storage
    for (final url in memory.imageUrls) {
      try {
        final ref = _storage.refFromURL(url);
        await ref.delete();
      } catch (_) {}
    }

    // Delete Firestore document
    await _firestore
        .collection(FirebaseCollections.couples)
        .doc(currentUser.coupleId)
        .collection(FirebaseCollections.memories)
        .doc(memory.id)
        .delete();
  }

  /// Add images to existing memory
  Future<void> addImagesToMemory(String memoryId, List<File> newImages) async {
    final currentUser = _ref.read(currentAppUserProvider).value;
    if (currentUser == null || currentUser.coupleId == null) return;

    // Upload new images
    final newUrls = <String>[];
    for (final image in newImages) {
      final url = await _uploadImage(image);
      newUrls.add(url);
    }

    // Update Firestore document
    await _firestore
        .collection(FirebaseCollections.couples)
        .doc(currentUser.coupleId)
        .collection(FirebaseCollections.memories)
        .doc(memoryId)
        .update({
          FirebaseCollections.memoryImageUrls: FieldValue.arrayUnion(newUrls),
        });
  }

  /// Send notification to partner
  Future<void> _sendNotificationToPartner(String? note) async {
    try {
      final currentUser = _ref.read(currentAppUserProvider).value;
      final partner = _ref.read(partnerUserProvider).value;
      final fcmService = _ref.read(fcmServiceProvider);

      if (partner?.fcmToken != null && currentUser != null) {
        await fcmService.sendNotificationToToken(
          token: partner!.fcmToken!,
          title: currentUser.displayName,
          body: note ?? '📸 Shared a new memory with you',
          data: {'type': 'memory'},
        );
      }
    } catch (_) {}
  }
}
