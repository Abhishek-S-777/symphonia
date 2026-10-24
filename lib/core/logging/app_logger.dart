import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Severity levels understood by [AppLogger].
enum LogLevel { debug, info, warning, error }

/// Small logging wrapper around `dart:developer`.
///
/// Replaces ad-hoc `print`/`debugPrint` calls across the app. Debug and info
/// messages are suppressed in release builds so verbose tracing never ships to
/// users. Nothing is written with `print`, so the `avoid_print` lint stays
/// satisfied. Messages are plain text, without emoji.
///
/// Usage:
/// ```dart
/// AppLogger.info('FCM token refreshed');
/// AppLogger.error('Failed to upload voice note', error: e, stackTrace: st);
/// ```
class AppLogger {
  const AppLogger._();

  /// Default source tag attached to each log line.
  static const String _defaultName = 'Symphonia';

  /// Logs a verbose tracing message. Suppressed in release builds.
  static void debug(String message, {String name = _defaultName}) {
    _log(LogLevel.debug, message, name: name);
  }

  /// Logs an informational message. Suppressed in release builds.
  static void info(String message, {String name = _defaultName}) {
    _log(LogLevel.info, message, name: name);
  }

  /// Logs a warning. Kept in release builds.
  static void warning(
    String message, {
    String name = _defaultName,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.warning,
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Logs an error. Kept in release builds.
  static void error(
    String message, {
    String name = _defaultName,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.error,
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void _log(
    LogLevel level,
    String message, {
    required String name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Keep release builds quiet for routine tracing.
    if (kReleaseMode && (level == LogLevel.debug || level == LogLevel.info)) {
      return;
    }

    developer.log(
      message,
      name: name,
      level: _severity(level),
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Maps a [LogLevel] to a `dart:developer` severity value, matching the
  /// conventional `package:logging` levels.
  static int _severity(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }
}
