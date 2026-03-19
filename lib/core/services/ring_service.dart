import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';

import '../constants/firebase_collections.dart';
import 'auth_service.dart';

/// Ring service provider
final ringServiceProvider = Provider<RingService>((ref) {
  return RingService(ref);
});

/// Notifier for ring state
class RingingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void startRinging() => state = true;
  void stopRinging() => state = false;
}

/// Provider for ring state
final isRingingProvider = NotifierProvider<RingingNotifier, bool>(() {
  return RingingNotifier();
});

/// Service for handling phone ringing feature
class RingService {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Timer? _ringTimer;
  Timer? _vibrationTimer;
  StreamSubscription? _ringRequestSubscription;

  static const int maxRingDurationSeconds = 30;

  RingService(this._ref);

  /// Initialize and listen for ring requests
  Future<void> initialize() async {
    final currentUser = _ref.read(currentAppUserProvider).value;
    if (currentUser == null || currentUser.coupleId == null) {
      debugPrint('🔔 RingService: No user or coupleId, cannot initialize');
      return;
    }

    debugPrint(
      '🔔 RingService: Initializing for couple ${currentUser.coupleId}',
    );

    // Cancel existing subscription if any
    await _ringRequestSubscription?.cancel();

    // Listen for ring requests - use orderBy to get latest requests
    _ringRequestSubscription = _firestore
        .collection(FirebaseCollections.couples)
        .doc(currentUser.coupleId)
        .collection('ring_requests')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen(
          (snapshot) {
            for (final change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added ||
                  change.type == DocumentChangeType.modified) {
                final data = change.doc.data();
                if (data == null) continue;

                final requesterId = data['requesterId'] as String?;
                final type = data['type'] as String?;
                final timestamp = data['timestamp'] as Timestamp?;

                // Only process recent requests (within last 30 seconds)
                if (timestamp != null) {
                  final requestTime = timestamp.toDate();
                  final now = DateTime.now();
                  if (now.difference(requestTime).inSeconds > 30) {
                    debugPrint('🔔 RingService: Ignoring old request');
                    continue;
                  }
                }

                // Only process requests from partner (not self)
                if (requesterId != null && requesterId != currentUser.id) {
                  debugPrint(
                    '🔔 RingService: Got request type=$type from $requesterId',
                  );
                  if (type == 'ring_phone') {
                    startRinging();
                  } else if (type == 'stop_ring') {
                    stopRinging();
                  }
                }
              }
            }
          },
          onError: (error) {
            debugPrint(
              '🔔 RingService: Error listening to ring requests: $error',
            );
          },
        );

    debugPrint('🔔 RingService: Initialized and listening for ring requests');
  }

  /// Start ringing the phone
  Future<void> startRinging() async {
    debugPrint('🔔 Starting ring...');

    _ref.read(isRingingProvider.notifier).startRinging();

    try {
      // Play alarm sound at max volume (overrides silent mode)
      await FlutterRingtonePlayer().playAlarm(
        volume: 1.0, // Max volume
        looping: true, // Keep playing until stopped
        asAlarm: true, // This makes it play even in silent mode
      );

      // Start vibration pattern (simple: vibrate, pause, vibrate)
      _startVibrationPattern();

      // Auto-stop after max duration
      _ringTimer?.cancel();
      _ringTimer = Timer(Duration(seconds: maxRingDurationSeconds), () {
        stopRinging();
      });
    } catch (e) {
      debugPrint('🔔 Error starting ring: $e');
    }
  }

  /// Start continuous vibration pattern
  void _startVibrationPattern() async {
    _vibrationTimer?.cancel();

    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator != true) return;

    // Initial vibration
    await Vibration.vibrate(
      pattern: [0, 1000, 500, 1000],
      intensities: [0, 255, 0, 255],
    );

    // Repeat vibration every 2.5 seconds
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 2500), (
      timer,
    ) async {
      if (!_ref.read(isRingingProvider)) {
        timer.cancel();
        return;
      }

      // Simple pattern: vibrate 1s, pause 500ms, vibrate 1s
      await Vibration.vibrate(
        pattern: [0, 1000, 500, 1000],
        intensities: [0, 255, 0, 255],
      );
    });
  }

  /// Stop ringing
  Future<void> stopRinging() async {
    debugPrint('🔔 Stopping ring...');

    _ref.read(isRingingProvider.notifier).stopRinging();

    _ringTimer?.cancel();
    _ringTimer = null;

    _vibrationTimer?.cancel();
    _vibrationTimer = null;

    // Stop ringtone
    await FlutterRingtonePlayer().stop();

    // Cancel vibration
    await Vibration.cancel();
  }

  /// Notify that ring was dismissed (for partner to know)
  Future<void> notifyRingDismissed() async {
    final currentUser = _ref.read(currentAppUserProvider).value;
    if (currentUser == null || currentUser.coupleId == null) return;

    await _firestore
        .collection(FirebaseCollections.couples)
        .doc(currentUser.coupleId)
        .collection('ring_requests')
        .add({
          'requesterId': currentUser.id,
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'ring_dismissed',
        });
  }

  /// Dispose resources
  void dispose() {
    _ringRequestSubscription?.cancel();
    _ringTimer?.cancel();
    _vibrationTimer?.cancel();
    FlutterRingtonePlayer().stop();
  }
}
