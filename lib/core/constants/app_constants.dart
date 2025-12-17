/// Application-wide constants
class AppConstants {
  AppConstants._();

  // ═══════════════════════════════════════════════════════════════════════════
  // APP INFO
  // ═══════════════════════════════════════════════════════════════════════════

  static const String appName = 'Symphonia';
  static const String appTagline = 'Your Love, Your Symphony';
  static const String appVersion = '1.0.0';

  // ═══════════════════════════════════════════════════════════════════════════
  // VOICE NOTES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Minimum voice note duration in seconds
  static const int voiceNoteMinDuration = 1;

  /// Maximum voice note duration in seconds
  static const int voiceNoteMaxDuration = 30;

  // ═══════════════════════════════════════════════════════════════════════════
  // MESSAGES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Maximum message length
  static const int messageMaxLength = 500;

  /// Predefined love messages
  static const List<String> predefinedMessages = [
    'I love you ❤️',
    'Thinking of you 💭',
    'Missing you right now 🥺',
    'You make me smile 😊',
    'Can\'t wait to see you! 🤗',
    'You\'re my everything 💕',
    'Sending hugs 🤗',
    'You\'re amazing 🌟',
    'My heart is yours 💝',
    'Forever and always 💫',
    'Good morning, love ☀️',
    'Sweet dreams 🌙',
    'Have a great day! 🌈',
    'I\'m grateful for you 🙏',
    'You\'re my best friend 👫',
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // HEARTBEAT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Heartbeat vibration pattern (in milliseconds)
  /// Mimics: lub-dub... lub-dub...lub-dub
  static const List<int> heartbeatPattern = [
    0, // Initial delay
    // Beat 1
    80, // LUB
    140, // short pause
    50, // DUB
    900, // long pause
    // Beat 2
    80,
    140,
    50,
    900,

    // Beat 3
    80,
    140,
    50,
  ];

  static const List<int> heartbeatIntensities = [
    0, // delay
    // Beat 1
    220, // LUB (strong)
    0,
    140, // DUB (weaker)
    0,

    // Beat 2
    220,
    0,
    140,
    0,

    // Beat 3
    220,
    0,
    140,
  ];

  /// Single heartbeat vibration
  static const List<int> singleHeartbeat = [
    0, // Initial delay
    // Beat 1
    80, // LUB
    140, // short pause
    50, // DUB
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // PAIRING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Pairing code length
  static const int pairingCodeLength = 6;

  /// Pairing code expiry in minutes
  static const int pairingCodeExpiryMinutes = 30;

  // ═══════════════════════════════════════════════════════════════════════════
  // ANIMATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Standard animation duration
  static const Duration animationDuration = Duration(milliseconds: 300);

  /// Fast animation duration
  static const Duration animationFast = Duration(milliseconds: 150);

  /// Slow animation duration
  static const Duration animationSlow = Duration(milliseconds: 500);

  /// Heart button animation duration
  static const Duration heartAnimationDuration = Duration(milliseconds: 600);

  // ═══════════════════════════════════════════════════════════════════════════
  // SYNC
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sync interval in minutes
  static const int syncIntervalMinutes = 5;

  /// Maximum retry attempts for sync
  static const int maxSyncRetries = 3;

  // ═══════════════════════════════════════════════════════════════════════════
  // GALLERY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Maximum number of images per memory
  static const int maxImagesPerMemory = 10;

  /// Image quality for compression (0-100)
  static const int imageQuality = 85;

  /// Thumbnail size
  static const int thumbnailSize = 300;

  // ═══════════════════════════════════════════════════════════════════════════
  // JOURNAL
  // ═══════════════════════════════════════════════════════════════════════════

  /// Maximum journal entry length
  static const int journalMaxLength = 5000;

  /// Journal title max length
  static const int journalTitleMaxLength = 100;
}
