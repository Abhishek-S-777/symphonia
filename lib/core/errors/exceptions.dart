/// Base exception class for data layer errors
sealed class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'AppException(message: $message, code: $code)';
}

// ═══════════════════════════════════════════════════════════════════════════
// AUTHENTICATION EXCEPTIONS
// ═══════════════════════════════════════════════════════════════════════════

class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// SERVER EXCEPTIONS
// ═══════════════════════════════════════════════════════════════════════════

class ServerException extends AppException {
  const ServerException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// CACHE EXCEPTIONS
// ═══════════════════════════════════════════════════════════════════════════

class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// NETWORK EXCEPTIONS
// ═══════════════════════════════════════════════════════════════════════════

class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// STORAGE EXCEPTIONS
// ═══════════════════════════════════════════════════════════════════════════

class StorageException extends AppException {
  const StorageException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// PERMISSION EXCEPTIONS
// ═══════════════════════════════════════════════════════════════════════════

class PermissionException extends AppException {
  const PermissionException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// AUDIO EXCEPTIONS
// ═══════════════════════════════════════════════════════════════════════════

class AudioException extends AppException {
  const AudioException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// VALIDATION EXCEPTIONS
// ═══════════════════════════════════════════════════════════════════════════

class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}
