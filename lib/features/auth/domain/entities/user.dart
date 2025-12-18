import 'package:equatable/equatable.dart';

/// User entity for domain layer
class User extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String deviceId;
  final String? fcmToken;
  final String? coupleId;
  final DateTime createdAt;
  final DateTime lastActive;
  final bool isOnline;

  const User({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.deviceId,
    this.fcmToken,
    this.coupleId,
    required this.createdAt,
    required this.lastActive,
    this.isOnline = false,
  });

  /// Check if user is paired with someone
  bool get isPaired => coupleId != null;

  /// Get a human-readable "last seen" string
  String get lastSeenText {
    if (isOnline) return 'Online';

    final now = DateTime.now();
    final difference = now.difference(lastActive);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return 'A while ago';
  }

  /// Create a copy with updated fields
  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? deviceId,
    String? fcmToken,
    String? coupleId,
    DateTime? createdAt,
    DateTime? lastActive,
    bool? isOnline,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      deviceId: deviceId ?? this.deviceId,
      fcmToken: fcmToken ?? this.fcmToken,
      coupleId: coupleId ?? this.coupleId,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    photoUrl,
    deviceId,
    fcmToken,
    coupleId,
    createdAt,
    lastActive,
    isOnline,
  ];
}
