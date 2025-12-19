import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../constants/firebase_collections.dart';
import '../../features/voice_notes/domain/entities/voice_note.dart';
import 'auth_service.dart';
import 'fcm_service.dart';

/// Audio Service Provider
final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService(ref);
});

/// Voice Notes Stream Provider
/// Uses select() to only rebuild when coupleId changes
final voiceNotesStreamProvider = StreamProvider<List<VoiceNote>>((ref) {
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
      .orderBy(FirebaseCollections.voiceNoteCreatedAt, descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => _voiceNoteFromFirestore(doc))
            .toList();
      });
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
  String? _currentlyPlayingId;

  AudioService(this._ref);

  bool get isRecording => _isRecording;
  String? get currentlyPlayingId => _currentlyPlayingId;

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

    final fileName = 'voice_note_${_uuid.v4()}.m4a';
    _currentRecordingPath = '${voiceNotesDir.path}/$fileName';
    _recordingStartTime = DateTime.now();

    // Use AAC encoder for compression (smaller file size)
    await _recorder.start(
      RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000, // 64 kbps for good quality with compression
        sampleRate: 22050, // Lower sample rate for voice
      ),
      path: _currentRecordingPath!,
    );

    _isRecording = true;
  }

  /// Stop recording and save the voice note
  Future<VoiceNote?> stopRecording() async {
    if (!_isRecording || _currentRecordingPath == null) return null;

    final recordPath = await _recorder.stop();
    _isRecording = false;

    if (recordPath == null || _recordingStartTime == null) return null;

    final duration = DateTime.now().difference(_recordingStartTime!).inSeconds;

    // Minimum duration check
    if (duration < 1) {
      // Delete the file if too short
      try {
        await File(recordPath).delete();
      } catch (_) {}
      return null;
    }

    final currentUser = _ref.read(currentAppUserProvider).value;
    if (currentUser == null || currentUser.coupleId == null) {
      return null;
    }

    // Upload to Firebase Storage
    final file = File(recordPath);
    final fileName = path.basename(recordPath);
    final storageRef = _storage
        .ref()
        .child('couples')
        .child(currentUser.coupleId!)
        .child('voice_notes')
        .child(fileName);

    final uploadTask = await storageRef.putFile(
      file,
      SettableMetadata(contentType: 'audio/mp4'),
    );
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    // Create Firestore document
    final voiceNoteRef = _firestore
        .collection(FirebaseCollections.couples)
        .doc(currentUser.coupleId)
        .collection(FirebaseCollections.voiceNotes)
        .doc();

    final voiceNote = VoiceNote(
      id: voiceNoteRef.id,
      senderId: currentUser.id,
      storageUrl: downloadUrl,
      localPath: recordPath,
      durationSeconds: duration,
      createdAt: DateTime.now(),
      isSynced: true,
    );

    await voiceNoteRef.set({
      FirebaseCollections.voiceNoteSenderId: currentUser.id,
      FirebaseCollections.voiceNoteStorageUrl: downloadUrl,
      FirebaseCollections.voiceNoteLocalPath: recordPath,
      FirebaseCollections.voiceNoteDuration: duration,
      FirebaseCollections.voiceNoteCreatedAt: FieldValue.serverTimestamp(),
      FirebaseCollections.voiceNotePlayedAt: null,
      FirebaseCollections.voiceNoteIsSynced: true,
    });

    // Send notification to partner
    _sendNotificationToPartner(duration);

    _currentRecordingPath = null;
    _recordingStartTime = null;

    return voiceNote;
  }

  /// Cancel recording
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    await _recorder.stop();
    _isRecording = false;

    // Delete the file
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
    // Stop any currently playing audio
    await stopPlaying();

    _currentlyPlayingId = voiceNote.id;

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

      _player.play();

      // Mark as played if not from current user
      final currentUser = _ref.read(currentAppUserProvider).value;
      if (currentUser != null &&
          voiceNote.senderId != currentUser.id &&
          voiceNote.playedAt == null &&
          currentUser.coupleId != null) {
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

      // Listen for completion
      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _currentlyPlayingId = null;
        }
      });
    } catch (e) {
      _currentlyPlayingId = null;
      rethrow;
    }
  }

  /// Stop playing
  Future<void> stopPlaying() async {
    await _player.stop();
    _currentlyPlayingId = null;
  }

  /// Pause playing
  Future<void> pausePlaying() async {
    await _player.pause();
  }

  /// Resume playing
  Future<void> resumePlaying() async {
    await _player.play();
  }

  /// Get player stream
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

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

  /// Send notification to partner
  Future<void> _sendNotificationToPartner(int duration) async {
    try {
      final currentUser = _ref.read(currentAppUserProvider).value;
      final partner = _ref.read(partnerUserProvider).value;
      final fcmService = _ref.read(fcmServiceProvider);

      if (partner?.fcmToken != null && currentUser != null) {
        await fcmService.sendNotificationToToken(
          token: partner!.fcmToken!,
          title: currentUser.displayName,
          body: '🎤 Sent you a ${duration}s voice note',
          data: {'type': 'voice_note'},
        );
      }
    } catch (_) {}
  }

  /// Dispose resources
  void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}
