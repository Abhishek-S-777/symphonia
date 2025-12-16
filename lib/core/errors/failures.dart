import 'package:equatable/equatable.dart';

/// Base failure class for domain layer errors
/// Uses sealed class for exhaustive pattern matching
sealed class Failure extends Equatable {
  final String message;
  final String? code;
  final StackTrace? stackTrace;

  const Failure({required this.message, this.code, this.stackTrace});

  @override
  List<Object?> get props => [message, code];
}

// ═══════════════════════════════════════════════════════════════════════════
// AUTHENTICATION FAILURES
// ═══════════════════════════════════════════════════════════════════════════

/// Authentication related failures
class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code, super.stackTrace});

  factory AuthFailure.invalidCredentials() => const AuthFailure(
    message: 'Invalid email or password. Please try again.',
    code: 'invalid-credentials',
  );

  factory AuthFailure.userNotFound() => const AuthFailure(
    message: 'No account found with this email.',
    code: 'user-not-found',
  );

  factory AuthFailure.emailAlreadyInUse() => const AuthFailure(
    message: 'An account already exists with this email.',
    code: 'email-already-in-use',
  );

  factory AuthFailure.weakPassword() => const AuthFailure(
    message: 'Password is too weak. Please use a stronger password.',
    code: 'weak-password',
  );

  factory AuthFailure.invalidEmail() => const AuthFailure(
    message: 'Please enter a valid email address.',
    code: 'invalid-email',
  );

  factory AuthFailure.tooManyRequests() => const AuthFailure(
    message: 'Too many attempts. Please try again later.',
    code: 'too-many-requests',
  );

  factory AuthFailure.notAuthenticated() => const AuthFailure(
    message: 'Please sign in to continue.',
    code: 'not-authenticated',
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// PAIRING FAILURES
// ═══════════════════════════════════════════════════════════════════════════

/// Pairing related failures
class PairingFailure extends Failure {
  const PairingFailure({required super.message, super.code, super.stackTrace});

  factory PairingFailure.invalidCode() => const PairingFailure(
    message: 'Invalid pairing code. Please check and try again.',
    code: 'invalid-code',
  );

  factory PairingFailure.codeExpired() => const PairingFailure(
    message: 'This pairing code has expired. Please request a new one.',
    code: 'code-expired',
  );

  factory PairingFailure.alreadyPaired() => const PairingFailure(
    message: 'You are already paired with someone.',
    code: 'already-paired',
  );

  factory PairingFailure.cannotPairWithSelf() => const PairingFailure(
    message: 'You cannot pair with yourself.',
    code: 'self-pairing',
  );

  factory PairingFailure.partnerAlreadyPaired() => const PairingFailure(
    message: 'This person is already paired with someone else.',
    code: 'partner-already-paired',
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// STORAGE FAILURES
// ═══════════════════════════════════════════════════════════════════════════

/// Storage related failures (Firebase Storage, local storage)
class StorageFailure extends Failure {
  const StorageFailure({required super.message, super.code, super.stackTrace});

  factory StorageFailure.uploadFailed() => const StorageFailure(
    message: 'Failed to upload file. Please try again.',
    code: 'upload-failed',
  );

  factory StorageFailure.downloadFailed() => const StorageFailure(
    message: 'Failed to download file. Please try again.',
    code: 'download-failed',
  );

  factory StorageFailure.fileNotFound() =>
      const StorageFailure(message: 'File not found.', code: 'file-not-found');

  factory StorageFailure.storageFull() => const StorageFailure(
    message: 'Storage is full. Please free some space.',
    code: 'storage-full',
  );

  factory StorageFailure.permissionDenied() => const StorageFailure(
    message: 'Storage permission denied.',
    code: 'permission-denied',
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// DATABASE FAILURES
// ═══════════════════════════════════════════════════════════════════════════

/// Database related failures (Firestore, SQLite)
class DatabaseFailure extends Failure {
  const DatabaseFailure({required super.message, super.code, super.stackTrace});

  factory DatabaseFailure.notFound() =>
      const DatabaseFailure(message: 'Data not found.', code: 'not-found');

  factory DatabaseFailure.saveFailed() => const DatabaseFailure(
    message: 'Failed to save data. Please try again.',
    code: 'save-failed',
  );

  factory DatabaseFailure.deleteFailed() => const DatabaseFailure(
    message: 'Failed to delete data. Please try again.',
    code: 'delete-failed',
  );

  factory DatabaseFailure.readFailed() => const DatabaseFailure(
    message: 'Failed to read data. Please try again.',
    code: 'read-failed',
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// NETWORK FAILURES
// ═══════════════════════════════════════════════════════════════════════════

/// Network related failures
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code, super.stackTrace});

  factory NetworkFailure.noConnection() => const NetworkFailure(
    message: 'No internet connection. Please check your network.',
    code: 'no-connection',
  );

  factory NetworkFailure.timeout() => const NetworkFailure(
    message: 'Connection timed out. Please try again.',
    code: 'timeout',
  );

  factory NetworkFailure.serverError() => const NetworkFailure(
    message: 'Server error. Please try again later.',
    code: 'server-error',
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// PERMISSION FAILURES
// ═══════════════════════════════════════════════════════════════════════════

/// Permission related failures
class PermissionFailure extends Failure {
  const PermissionFailure({
    required super.message,
    super.code,
    super.stackTrace,
  });

  factory PermissionFailure.microphoneDenied() => const PermissionFailure(
    message: 'Microphone permission is required to record voice notes.',
    code: 'microphone-denied',
  );

  factory PermissionFailure.storageDenied() => const PermissionFailure(
    message: 'Storage permission is required to save files.',
    code: 'storage-denied',
  );

  factory PermissionFailure.notificationDenied() => const PermissionFailure(
    message: 'Notification permission is required to receive messages.',
    code: 'notification-denied',
  );

  factory PermissionFailure.locationDenied() => const PermissionFailure(
    message: 'Location permission is required for geo-triggered greetings.',
    code: 'location-denied',
  );

  factory PermissionFailure.permanentlyDenied() => const PermissionFailure(
    message: 'Permission permanently denied. Please enable in settings.',
    code: 'permanently-denied',
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// AUDIO FAILURES
// ═══════════════════════════════════════════════════════════════════════════

/// Audio recording/playback failures
class AudioFailure extends Failure {
  const AudioFailure({required super.message, super.code, super.stackTrace});

  factory AudioFailure.recordingFailed() => const AudioFailure(
    message: 'Failed to start recording. Please try again.',
    code: 'recording-failed',
  );

  factory AudioFailure.playbackFailed() => const AudioFailure(
    message: 'Failed to play audio. Please try again.',
    code: 'playback-failed',
  );

  factory AudioFailure.tooShort() => const AudioFailure(
    message: 'Voice note is too short. Please record at least 1 second.',
    code: 'too-short',
  );

  factory AudioFailure.tooLong() => const AudioFailure(
    message: 'Voice note is too long. Maximum 30 seconds allowed.',
    code: 'too-long',
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// GENERIC FAILURES
// ═══════════════════════════════════════════════════════════════════════════

/// Unexpected/unknown failures
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unexpected error occurred. Please try again.',
    super.code = 'unknown',
    super.stackTrace,
  });
}

/// Cache failures
class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code, super.stackTrace});

  factory CacheFailure.notFound() =>
      const CacheFailure(message: 'No cached data found.', code: 'not-found');

  factory CacheFailure.expired() =>
      const CacheFailure(message: 'Cached data has expired.', code: 'expired');
}
