import 'package:equatable/equatable.dart';

/// Couple entity representing a paired couple
class Couple extends Equatable {
  final String id;
  final String user1Id;
  final String user2Id;
  final String user1Email;
  final String user2Email;
  final DateTime pairedAt;
  final DateTime? anniversaryDate;
  final CoupleSettings settings;

  const Couple({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.user1Email,
    required this.user2Email,
    required this.pairedAt,
    this.anniversaryDate,
    required this.settings,
  });

  /// Check if user is part of this couple
  bool containsUser(String userId) {
    return user1Id == userId || user2Id == userId;
  }

  /// Get partner's user ID
  String getPartnerId(String myUserId) {
    return myUserId == user1Id ? user2Id : user1Id;
  }

  /// Get partner's email
  String getPartnerEmail(String myUserId) {
    return myUserId == user1Id ? user2Email : user1Email;
  }

  /// Days since pairing
  int get daysTogether {
    return DateTime.now().difference(pairedAt).inDays;
  }

  /// Days until anniversary (if set)
  int? get daysUntilAnniversary {
    if (anniversaryDate == null) return null;

    final now = DateTime.now();
    var nextAnniversary = DateTime(
      now.year,
      anniversaryDate!.month,
      anniversaryDate!.day,
    );

    if (nextAnniversary.isBefore(now)) {
      nextAnniversary = DateTime(
        now.year + 1,
        anniversaryDate!.month,
        anniversaryDate!.day,
      );
    }

    return nextAnniversary.difference(now).inDays;
  }

  Couple copyWith({
    String? id,
    String? user1Id,
    String? user2Id,
    String? user1Email,
    String? user2Email,
    DateTime? pairedAt,
    DateTime? anniversaryDate,
    CoupleSettings? settings,
  }) {
    return Couple(
      id: id ?? this.id,
      user1Id: user1Id ?? this.user1Id,
      user2Id: user2Id ?? this.user2Id,
      user1Email: user1Email ?? this.user1Email,
      user2Email: user2Email ?? this.user2Email,
      pairedAt: pairedAt ?? this.pairedAt,
      anniversaryDate: anniversaryDate ?? this.anniversaryDate,
      settings: settings ?? this.settings,
    );
  }

  @override
  List<Object?> get props => [
    id,
    user1Id,
    user2Id,
    user1Email,
    user2Email,
    pairedAt,
    anniversaryDate,
    settings,
  ];
}

/// Settings for a couple
class CoupleSettings extends Equatable {
  final bool heartbeatEnabled;
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;

  const CoupleSettings({
    this.heartbeatEnabled = true,
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  });

  CoupleSettings copyWith({
    bool? heartbeatEnabled,
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return CoupleSettings(
      heartbeatEnabled: heartbeatEnabled ?? this.heartbeatEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }

  @override
  List<Object> get props => [
    heartbeatEnabled,
    notificationsEnabled,
    soundEnabled,
    vibrationEnabled,
  ];
}
