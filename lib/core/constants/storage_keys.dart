/// Local storage keys for SharedPreferences and SecureStorage
class StorageKeys {
  StorageKeys._();

  // ═══════════════════════════════════════════════════════════════════════════
  // USER & AUTH
  // ═══════════════════════════════════════════════════════════════════════════

  static const String isAuthenticated = 'is_authenticated';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String userName = 'user_name';
  static const String userPhotoUrl = 'user_photo_url';
  static const String deviceId = 'device_id';
  static const String fcmToken = 'fcm_token';
  static const String biometricsEnabled = 'biometrics_enabled';

  // ═══════════════════════════════════════════════════════════════════════════
  // PAIRING
  // ═══════════════════════════════════════════════════════════════════════════

  static const String coupleId = 'couple_id';
  static const String partnerId = 'partner_id';
  static const String partnerName = 'partner_name';
  static const String partnerPhotoUrl = 'partner_photo_url';
  static const String isPaired = 'is_paired';
  static const String pairingCode = 'pairing_code';
  static const String pairingCodeExpiry = 'pairing_code_expiry';

  // ═══════════════════════════════════════════════════════════════════════════
  // SETTINGS
  // ═══════════════════════════════════════════════════════════════════════════

  static const String themeMode = 'theme_mode';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String heartbeatEnabled = 'heartbeat_enabled';
  static const String vibrationEnabled = 'vibration_enabled';
  static const String soundEnabled = 'sound_enabled';

  // ═══════════════════════════════════════════════════════════════════════════
  // SYNC
  // ═══════════════════════════════════════════════════════════════════════════

  static const String lastSyncTime = 'last_sync_time';
  static const String pendingSyncCount = 'pending_sync_count';
  static const String syncEnabled = 'sync_enabled';

  // ═══════════════════════════════════════════════════════════════════════════
  // ONBOARDING
  // ═══════════════════════════════════════════════════════════════════════════

  static const String onboardingComplete = 'onboarding_complete';
  static const String firstLaunch = 'first_launch';
  static const String permissionsGranted = 'permissions_granted';

  // ═══════════════════════════════════════════════════════════════════════════
  // BACKGROUND SERVICE
  // ═══════════════════════════════════════════════════════════════════════════

  static const String backgroundServiceEnabled = 'background_service_enabled';
  static const String lastHeartbeatTime = 'last_heartbeat_time';
}
