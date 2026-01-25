import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/firebase_collections.dart';
import '../../features/notes/domain/entities/note.dart';
import 'auth_service.dart';

/// Note Service Provider
final noteServiceProvider = Provider<NoteService>((ref) {
  return NoteService(ref);
});

/// Notes Stream Provider
/// Uses select() to only rebuild when coupleId changes
final notesStreamProvider = StreamProvider<List<Note>>((ref) {
  final coupleId = ref.watch(
    currentAppUserProvider.select((asyncUser) => asyncUser.value?.coupleId),
  );

  if (coupleId == null) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection(FirebaseCollections.couples)
      .doc(coupleId)
      .collection(FirebaseCollections.notes)
      .orderBy(FirebaseCollections.noteUpdatedAt, descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => _noteFromFirestore(doc)).toList();
      });
});

Note _noteFromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;

  return Note(
    id: doc.id,
    creatorId: data[FirebaseCollections.noteCreatorId] ?? '',
    title: data[FirebaseCollections.noteTitle] ?? 'Untitled',
    content: data[FirebaseCollections.noteContent] ?? '[]',
    createdAt:
        (data[FirebaseCollections.noteCreatedAt] as Timestamp?)?.toDate() ??
        DateTime.now(),
    updatedAt:
        (data[FirebaseCollections.noteUpdatedAt] as Timestamp?)?.toDate() ??
        DateTime.now(),
  );
}

/// Note Service for managing rich text notes
class NoteService {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  NoteService(this._ref);

  /// Create a new note
  Future<Note> createNote({
    required String title,
    required String content,
  }) async {
    final currentUser = _ref.read(currentAppUserProvider).value;
    if (currentUser == null || currentUser.coupleId == null) {
      throw Exception('User not authenticated or not paired');
    }

    final noteRef = _firestore
        .collection(FirebaseCollections.couples)
        .doc(currentUser.coupleId)
        .collection(FirebaseCollections.notes)
        .doc();

    final now = DateTime.now();
    final note = Note(
      id: noteRef.id,
      creatorId: currentUser.id,
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
    );

    await noteRef.set({
      FirebaseCollections.noteCreatorId: currentUser.id,
      FirebaseCollections.noteTitle: title,
      FirebaseCollections.noteContent: content,
      FirebaseCollections.noteCreatedAt: FieldValue.serverTimestamp(),
      FirebaseCollections.noteUpdatedAt: FieldValue.serverTimestamp(),
    });

    return note;
  }

  /// Update an existing note
  Future<void> updateNote(Note note) async {
    final currentUser = _ref.read(currentAppUserProvider).value;
    if (currentUser == null || currentUser.coupleId == null) return;

    await _firestore
        .collection(FirebaseCollections.couples)
        .doc(currentUser.coupleId)
        .collection(FirebaseCollections.notes)
        .doc(note.id)
        .update({
          FirebaseCollections.noteTitle: note.title,
          FirebaseCollections.noteContent: note.content,
          FirebaseCollections.noteUpdatedAt: FieldValue.serverTimestamp(),
        });
  }

  /// Delete a note
  Future<void> deleteNote(String noteId) async {
    final currentUser = _ref.read(currentAppUserProvider).value;
    if (currentUser == null || currentUser.coupleId == null) return;

    await _firestore
        .collection(FirebaseCollections.couples)
        .doc(currentUser.coupleId)
        .collection(FirebaseCollections.notes)
        .doc(noteId)
        .delete();
  }

  /// Get a single note by ID
  Future<Note?> getNoteById(String noteId) async {
    final currentUser = _ref.read(currentAppUserProvider).value;
    if (currentUser == null || currentUser.coupleId == null) return null;

    final doc = await _firestore
        .collection(FirebaseCollections.couples)
        .doc(currentUser.coupleId)
        .collection(FirebaseCollections.notes)
        .doc(noteId)
        .get();

    if (!doc.exists) return null;
    return _noteFromFirestore(doc);
  }
}
