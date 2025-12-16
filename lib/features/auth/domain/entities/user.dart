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
  });

  /// Check if user is paired with someone
  bool get isPaired => coupleId != null;

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
  ];
}
