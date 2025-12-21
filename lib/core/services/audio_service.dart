import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../constants/firebase_collections.dart';
import '../../features/voice_notes/domain/entities/voice_note.dart';
import 'auth_service.dart';

// =============================================================================
// STATE NOTIFIERS (Modern Riverpod 2.x pattern)
// =============================================================================

/// Notifier for the currently playing voice note ID
class CurrentlyPlayingIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setPlaying(String? id) => state = id;
  void clear() => state = null;
}

final currentlyPlayingIdProvider =
    NotifierProvider<CurrentlyPlayingIdNotifier, String?>(() {
      return CurrentlyPlayingIdNotifier();
    });

/// Notifier for pending (not yet synced) voice notes
class PendingVoiceNotesNotifier extends Notifier<List<VoiceNote>> {
  @override
  List<VoiceNote> build() => [];

  void add(VoiceNote note) => state = [...state, note];
  void remove(String id) => state = state.where((n) => n.id != id).toList();
  void removeMultiple(Set<String> ids) =>
      state = state.where((n) => !ids.contains(n.id)).toList();
  void clear() => state = [];
}

final pendingVoiceNotesProvider =
    NotifierProvider<PendingVoiceNotesNotifier, List<VoiceNote>>(() {
      return PendingVoiceNotesNotifier();
    });

// =============================================================================
// AUDIO SERVICE
// =============================================================================

/// Audio Service Provider
final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});

/// Firebase Voice Notes Stream Provider (internal)
final _firebaseVoiceNotesProvider = StreamProvider<List<VoiceNote>>((ref) {
  final coupleId = ref.watch(
    currentAppUserProvider.select((asyncUser) => asyncUser.value?.coupleId),
  );

  if (coupleId == null) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection(FirebaseCollections.couples)
      .doc(coupleId)
      .collection(FirebaseCollections.voiceNotes)
      .orderBy(FirebaseCollections.voiceNoteCreatedAt, descending: false)
      .limit(50)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => _voiceNoteFromFirestore(doc))
            .toList();
      });
});

/// Combined Voice Notes Provider
/// Reactively combines pending (local) notes with Firebase notes
/// Pending notes appear IMMEDIATELY, no waiting for upload
final voiceNotesStreamProvider = Provider<AsyncValue<List<VoiceNote>>>((ref) {
  final firebaseNotesAsync = ref.watch(_firebaseVoiceNotesProvider);
  final pendingNotes = ref.watch(pendingVoiceNotesProvider);

  return firebaseNotesAsync.when(
    data: (firebaseNotes) {
      final firebaseIds = firebaseNotes.map((n) => n.id).toSet();

      // Filter out notes that are now synced to Firebase
      final stillPending = pendingNotes
          .where((n) => !firebaseIds.contains(n.id))
          .toList();

      // Clean up synced notes from pending provider (single batch update)
      if (stillPending.length != pendingNotes.length) {
        final syncedIds = pendingNotes
            .where((n) => firebaseIds.contains(n.id))
            .map((n) => n.id)
            .toSet();
        if (syncedIds.isNotEmpty) {
          Future.microtask(() {
            ref
                .read(pendingVoiceNotesProvider.notifier)
                .removeMultiple(syncedIds);
          });
        }
      }

      // Combine: firebase first (oldest), then pending at the end (newest)
      return AsyncValue.data([...firebaseNotes, ...stillPending]);
    },
    loading: () {
      // While loading Firebase, still show pending notes
      if (pendingNotes.isNotEmpty) {
        return AsyncValue.data(pendingNotes);
      }
      return const AsyncValue.loading();
    },
    error: (e, st) => AsyncValue.error(e, st),
  );
});

/// Unread Voice Notes Count Provider
/// Counts voice notes that are not from the current user and haven't been played
final unreadVoiceNotesCountProvider = Provider<int>((ref) {
  final voiceNotesAsync = ref.watch(voiceNotesStreamProvider);
  final currentUser = ref.watch(currentAppUserProvider).value;

  if (currentUser == null) return 0;

  return voiceNotesAsync.when(
    data: (notes) {
      return notes
          .where(
            (note) => note.senderId != currentUser.id && note.playedAt == null,
          )
          .length;
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});

VoiceNote _voiceNoteFromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  return VoiceNote(
    id: doc.id,
    senderId: data[FirebaseCollections.voiceNoteSenderId] ?? '',
    storageUrl: data[FirebaseCollections.voiceNoteStorageUrl],
    localPath: data[FirebaseCollections.voiceNoteLocalPath],
    durationSeconds: data[FirebaseCollections.voiceNoteDuration] ?? 0,
    createdAt:
        (data[FirebaseCollections.voiceNoteCreatedAt] as Timestamp?)
            ?.toDate() ??
        DateTime.now(),
    playedAt: (data[FirebaseCollections.voiceNotePlayedAt] as Timestamp?)
        ?.toDate(),
    isSynced: data[FirebaseCollections.voiceNoteIsSynced] ?? true,
  );
}

/// Audio Service for recording, playing, and managing voice notes
class AudioService {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final _uuid = const Uuid();

  bool _isRecording = false;
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  AudioService(this._ref) {
    // Set up a SINGLE listener for player state changes
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _ref.read(currentlyPlayingIdProvider.notifier).clear();
      }
    });
  }

  bool get isRecording => _isRecording;

  /// Check if microphone permission is granted
  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  /// Start recording a voice note with compression
  Future<void> startRecording() async {
    if (_isRecording) return;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw Exception('Microphone permission not granted');
    }

    final appDir = await getApplicationDocumentsDirectory();
    final voiceNotesDir = Directory('${appDir.path}/voice_notes');
    if (!await voiceNotesDir.exists()) {
      await voiceNotesDir.create(recursive: true);
    }

    final fileName = 'voice_${_uuid.v4()}.m4a';
    _currentRecordingPath = '${voiceNotesDir.path}/$fileName';
    _recordingStartTime = DateTime.now();

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: _currentRecordingPath!,
    );

    _isRecording = true;
  }

  /// Stop recording and save the voice note
  /// Uses OPTIMISTIC LOCAL-FIRST approach:
  /// 1. Immediately creates a local voice note and shows it
  /// 2. Uploads to Firebase in background
  /// 3. Updates Firestore when upload completes
  Future<VoiceNote?> stopRecording() async {
    if (!_isRecording || _currentRecordingPath == null) return null;

    final recordPath = await _recorder.stop();
    _isRecording = false;

    if (recordPath == null || _recordingStartTime == null) return null;

    final duration = DateTime.now().difference(_recordingStartTime!).inSeconds;

    // Minimum duration check
    if (duration < 1) {
      try {
        await File(recordPath).delete();
      } catch (_) {}
      return null;
    }

    final currentUser = _ref.read(currentAppUserProvider).value;
    if (currentUser == null || currentUser.coupleId == null) {
      return null;
    }

    // Generate ID ahead of time
    final voiceNoteId = _uuid.v4();

    // STEP 1: Create LOCAL voice note immediately (optimistic)
    final localVoiceNote = VoiceNote(
      id: voiceNoteId,
      senderId: currentUser.id,
      storageUrl: null, // Not uploaded yet
      localPath: recordPath,
      durationSeconds: duration,
      createdAt: DateTime.now(),
      isSynced: false, // Mark as not synced
    );

    // Add to pending list for immediate display
    _ref.read(pendingVoiceNotesProvider.notifier).add(localVoiceNote);

    // STEP 2: Upload to Firebase in BACKGROUND
    _uploadVoiceNoteInBackground(
      voiceNoteId: voiceNoteId,
      recordPath: recordPath,
      duration: duration,
      coupleId: currentUser.coupleId!,
      senderId: currentUser.id,
    );

    _currentRecordingPath = null;
    _recordingStartTime = null;

    return localVoiceNote;
  }

  /// Background upload task
  Future<void> _uploadVoiceNoteInBackground({
    required String voiceNoteId,
    required String recordPath,
    required int duration,
    required String coupleId,
    required String senderId,
  }) async {
    try {
      // Get sender display name for notification
      final currentUser = _ref.read(currentAppUserProvider).value;
      final senderName = currentUser?.displayName ?? 'Your partner';

      // Upload to Firebase Storage
      final file = File(recordPath);
      final fileName = path.basename(recordPath);
      final storageRef = _storage
          .ref()
          .child('couples')
          .child(coupleId)
          .child('voice_notes')
          .child(fileName);

      final uploadTask = await storageRef.putFile(
        file,
        SettableMetadata(contentType: 'audio/mp4'),
      );
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Create Firestore document with the same ID
      // Include notification fields for Cloud Function to use
      final voiceNoteRef = _firestore
          .collection(FirebaseCollections.couples)
          .doc(coupleId)
          .collection(FirebaseCollections.voiceNotes)
          .doc(voiceNoteId);

      await voiceNoteRef.set({
        FirebaseCollections.voiceNoteSenderId: senderId,
        FirebaseCollections.voiceNoteStorageUrl: downloadUrl,
        FirebaseCollections.voiceNoteLocalPath: recordPath,
        FirebaseCollections.voiceNoteDuration: duration,
        FirebaseCollections.voiceNoteCreatedAt: FieldValue.serverTimestamp(),
        FirebaseCollections.voiceNotePlayedAt: null,
        FirebaseCollections.voiceNoteIsSynced: true,
        // Notification fields for Cloud Function
        'notificationTitle': senderName,
        'notificationBody': '🎤 Sent you a ${duration}s voice note',
        'notificationChannelId': 'voice_note_channel',
      });

      // Remove from pending list (Firestore stream will add the synced version)
      _ref.read(pendingVoiceNotesProvider.notifier).remove(voiceNoteId);

      debugPrint('VoiceNote uploaded successfully: $voiceNoteId');
    } catch (e) {
      debugPrint('Failed to upload voice note: $e');
      // Mark the pending note as failed (could show error UI)
      // For now, we'll just leave it in pending
    }
  }

  /// Cancel recording
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    await _recorder.stop();
    _isRecording = false;

    if (_currentRecordingPath != null) {
      try {
        await File(_currentRecordingPath!).delete();
      } catch (_) {}
    }

    _currentRecordingPath = null;
    _recordingStartTime = null;
  }

  /// Play a voice note
  Future<void> playVoiceNote(VoiceNote voiceNote) async {
    // Stop any currently playing audio first
    await stopPlaying();

    // Update the state provider
    _ref.read(currentlyPlayingIdProvider.notifier).setPlaying(voiceNote.id);

    try {
      // Try local path first, then URL
      if (voiceNote.localPath != null &&
          await File(voiceNote.localPath!).exists()) {
        await _player.setFilePath(voiceNote.localPath!);
      } else if (voiceNote.storageUrl != null) {
        await _player.setUrl(voiceNote.storageUrl!);
      } else {
        throw Exception('No audio source available');
      }

      await _player.play();

      // Mark as played if not from current user
      final currentUser = _ref.read(currentAppUserProvider).value;
      if (currentUser != null &&
          voiceNote.senderId != currentUser.id &&
          voiceNote.playedAt == null &&
          currentUser.coupleId != null &&
          voiceNote.isSynced) {
        // Only mark synced notes
        await _firestore
            .collection(FirebaseCollections.couples)
            .doc(currentUser.coupleId)
            .collection(FirebaseCollections.voiceNotes)
            .doc(voiceNote.id)
            .update({
              FirebaseCollections.voiceNotePlayedAt:
                  FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      _ref.read(currentlyPlayingIdProvider.notifier).clear();
      rethrow;
    }
  }

  /// Stop playing
  Future<void> stopPlaying() async {
    await _player.stop();
    _ref.read(currentlyPlayingIdProvider.notifier).clear();
  }

  /// Pause playing
  Future<void> pausePlaying() async {
    await _player.pause();
  }

  /// Resume playing
  Future<void> resumePlaying() async {
    await _player.play();
  }

  /// Seek forward by specified duration (default 5 seconds)
  Future<void> seekForward({
    Duration duration = const Duration(seconds: 5),
  }) async {
    final currentPosition = _player.position;
    final totalDuration = _player.duration;
    if (totalDuration != null) {
      final newPosition = currentPosition + duration;
      if (newPosition < totalDuration) {
        await _player.seek(newPosition);
      } else {
        await _player.seek(totalDuration);
      }
    }
  }

  /// Seek backward by specified duration (default 5 seconds)
  Future<void> seekBackward({
    Duration duration = const Duration(seconds: 5),
  }) async {
    final currentPosition = _player.position;
    final newPosition = currentPosition - duration;
    if (newPosition > Duration.zero) {
      await _player.seek(newPosition);
    } else {
      await _player.seek(Duration.zero);
    }
  }

  /// Seek to a specific position
  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  /// Get player streams
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  /// Get current position
  Duration get position => _player.position;

  /// Get total duration
  Duration? get duration => _player.duration;

  /// Delete a voice note
  Future<void> deleteVoiceNote(VoiceNote voiceNote) async {
    final currentUser = _ref.read(currentAppUserProvider).value;
    if (currentUser == null || currentUser.coupleId == null) return;

    // Delete from Storage
    if (voiceNote.storageUrl != null) {
      try {
        final ref = _storage.refFromURL(voiceNote.storageUrl!);
        await ref.delete();
      } catch (_) {}
    }

    // Delete local file
    if (voiceNote.localPath != null) {
      try {
        await File(voiceNote.localPath!).delete();
      } catch (_) {}
    }

    // Delete Firestore document
    await _firestore
        .collection(FirebaseCollections.couples)
        .doc(currentUser.coupleId)
        .collection(FirebaseCollections.voiceNotes)
        .doc(voiceNote.id)
        .delete();
  }

  /// Dispose resources
  void dispose() {
    _playerStateSubscription?.cancel();
    _recorder.dispose();
    _player.dispose();
  }
}
