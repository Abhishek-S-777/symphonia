/// Firebase Firestore collection and field names
class FirebaseCollections {
  FirebaseCollections._();

  // ═══════════════════════════════════════════════════════════════════════════
  // COLLECTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  static const String users = 'users';
  static const String couples = 'couples';
  static const String pairingCodes = 'pairingCodes';

  // ═══════════════════════════════════════════════════════════════════════════
  // SUBCOLLECTIONS (under couples)
  // ═══════════════════════════════════════════════════════════════════════════

  static const String messages = 'messages';
  static const String voiceNotes = 'voiceNotes';
  static const String memories = 'memories';
  static const String journal = 'journal';
  static const String events = 'events';

  // ═══════════════════════════════════════════════════════════════════════════
  // USER FIELDS
  // ═══════════════════════════════════════════════════════════════════════════

  static const String userEmail = 'email';
  static const String userDisplayName = 'displayName';
  static const String userPhotoUrl = 'photoUrl';
  static const String userDeviceId = 'deviceId';
  static const String userFcmToken = 'fcmToken';
  static const String userCoupleId = 'coupleId';
  static const String userCreatedAt = 'createdAt';
  static const String userLastActive = 'lastActive';

  // ═══════════════════════════════════════════════════════════════════════════
  // COUPLE FIELDS
  // ═══════════════════════════════════════════════════════════════════════════

  static const String coupleUser1Id = 'user1Id';
  static const String coupleUser2Id = 'user2Id';
  static const String coupleUser1Email = 'user1Email';
  static const String coupleUser2Email = 'user2Email';
  static const String couplePairedAt = 'pairedAt';
  static const String coupleAnniversaryDate = 'anniversaryDate';
  static const String coupleSettings = 'settings';

  // ═══════════════════════════════════════════════════════════════════════════
  // MESSAGE FIELDS
  // ═══════════════════════════════════════════════════════════════════════════

  static const String messageSenderId = 'senderId';
  static const String messageContent = 'content';
  static const String messageType = 'type';
  static const String messageScheduledFor = 'scheduledFor';
  static const String messageSentAt = 'sentAt';
  static const String messageReadAt = 'readAt';
  static const String messageIsDelivered = 'isDelivered';

  // ═══════════════════════════════════════════════════════════════════════════
  // VOICE NOTE FIELDS
  // ═══════════════════════════════════════════════════════════════════════════

  static const String voiceNoteSenderId = 'senderId';
  static const String voiceNoteDuration = 'duration';
  static const String voiceNoteStorageUrl = 'storageUrl';
  static const String voiceNoteLocalPath = 'localPath';
  static const String voiceNoteCreatedAt = 'createdAt';
  static const String voiceNotePlayedAt = 'playedAt';
  static const String voiceNoteIsSynced = 'isSynced';

  // ═══════════════════════════════════════════════════════════════════════════
  // MEMORY FIELDS
  // ═══════════════════════════════════════════════════════════════════════════

  static const String memoryCreatorId = 'creatorId';
  static const String memoryImageUrls = 'imageUrls';
  static const String memoryNote = 'note';
  static const String memoryDate = 'date';
  static const String memoryCreatedAt = 'createdAt';
  static const String memoryIsSynced = 'isSynced';

  // ═══════════════════════════════════════════════════════════════════════════
  // JOURNAL FIELDS
  // ═══════════════════════════════════════════════════════════════════════════

  static const String journalAuthorId = 'authorId';
  static const String journalTitle = 'title';
  static const String journalContent = 'content';
  static const String journalCreatedAt = 'createdAt';
  static const String journalIsImmutable = 'isImmutable';

  // ═══════════════════════════════════════════════════════════════════════════
  // EVENT FIELDS
  // ═══════════════════════════════════════════════════════════════════════════

  static const String eventCreatorId = 'creatorId';
  static const String eventTitle = 'title';
  static const String eventDescription = 'description';
  static const String eventDate = 'eventDate';
  static const String eventIsRecurring = 'isRecurring';
  static const String eventRecurringType = 'recurringType';
  static const String eventCreatedAt = 'createdAt';

  // ═══════════════════════════════════════════════════════════════════════════
  // PAIRING CODE FIELDS
  // ═══════════════════════════════════════════════════════════════════════════

  static const String pairingCodeCreatorId = 'creatorId';
  static const String pairingCodeCreatedAt = 'createdAt';
  static const String pairingCodeExpiresAt = 'expiresAt';
}
