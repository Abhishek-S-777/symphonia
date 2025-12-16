import 'package:equatable/equatable.dart';

/// Voice note entity
class VoiceNote extends Equatable {
  final String id;
  final String senderId;
  final int durationSeconds;
  final String? storageUrl;
  final String? localPath;
  final DateTime createdAt;
  final DateTime? playedAt;
  final bool isSynced;

  const VoiceNote({
    required this.id,
    required this.senderId,
    required this.durationSeconds,
    this.storageUrl,
    this.localPath,
    required this.createdAt,
    this.playedAt,
    this.isSynced = false,
  });

  /// Check if voice note is from me
  bool isFromMe(String myUserId) => senderId == myUserId;

  /// Check if voice note has been played
  bool get isPlayed => playedAt != null;

  /// Check if voice note is available locally
  bool get isAvailableLocally => localPath != null;

  /// Check if voice note needs to be uploaded
  bool get needsUpload => storageUrl == null && localPath != null;

  /// Check if voice note needs to be downloaded
  bool get needsDownload => localPath == null && storageUrl != null;

  /// Formatted duration string (e.g., "0:15")
  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  VoiceNote copyWith({
    String? id,
    String? senderId,
    int? durationSeconds,
    String? storageUrl,
    String? localPath,
    DateTime? createdAt,
    DateTime? playedAt,
    bool? isSynced,
  }) {
    return VoiceNote(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      storageUrl: storageUrl ?? this.storageUrl,
      localPath: localPath ?? this.localPath,
      createdAt: createdAt ?? this.createdAt,
      playedAt: playedAt ?? this.playedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  List<Object?> get props => [
    id,
    senderId,
    durationSeconds,
    storageUrl,
    localPath,
    createdAt,
    playedAt,
    isSynced,
  ];
}
