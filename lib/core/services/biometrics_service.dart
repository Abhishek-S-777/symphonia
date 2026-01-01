import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/firebase_collections.dart';
import '../constants/storage_keys.dart';

/// Biometrics Service Provider
final biometricsServiceProvider = Provider<BiometricsService>((ref) {
  return BiometricsService();
});

/// Provider for biometrics enabled setting
final biometricsEnabledProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(biometricsServiceProvider);
  return service.isBiometricsEnabled();
});

/// Biometrics Service for app lock
/// Stores biometrics preference in both SharedPreferences (cache) and Firestore (sync)
class BiometricsService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if device supports biometrics
  Future<bool> isBiometricsAvailable() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheckBiometrics && isDeviceSupported;
    } catch (e) {
      debugPrint('Error checking biometrics availability: $e');
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Check if any biometrics are enrolled on the device
  Future<bool> hasBiometricsEnrolled() async {
    try {
      final availableBiometrics = await getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Check if biometrics is enabled
  /// First checks SharedPreferences (cache), if null fetches from Firestore
  Future<bool> isBiometricsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check cache first
      final cachedValue = prefs.getBool(StorageKeys.biometricsEnabled);
      if (cachedValue != null) {
        return cachedValue;
      }

      // If not in cache, fetch from Firestore
      final user = fb.FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final doc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(user.uid)
          .get();

      final firestoreValue =
          doc.data()?[FirebaseCollections.userBiometricsEnabled] as bool? ??
          false;

      // Cache the value
      await prefs.setBool(StorageKeys.biometricsEnabled, firestoreValue);

      return firestoreValue;
    } catch (e) {
      debugPrint('Error checking biometrics enabled: $e');
      return false;
    }
  }

  /// Enable or disable biometrics
  /// Updates both SharedPreferences (cache) and Firestore (sync)
  Future<bool> setBiometricsEnabled(bool enabled) async {
    try {
      // If enabling, verify biometrics first
      if (enabled) {
        final hasEnrolled = await hasBiometricsEnrolled();
        if (!hasEnrolled) {
          return false; // Can't enable if no biometrics enrolled
        }

        // Authenticate to confirm
        final authenticated = await authenticate(
          reason: 'Authenticate to enable biometric lock',
        );
        if (!authenticated) {
          return false;
        }
      }

      // Update SharedPreferences (cache)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(StorageKeys.biometricsEnabled, enabled);

      // Update Firestore (sync)
      final user = fb.FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore
            .collection(FirebaseCollections.users)
            .doc(user.uid)
            .update({FirebaseCollections.userBiometricsEnabled: enabled});
      }

      return true;
    } catch (e) {
      debugPrint('Error setting biometrics enabled: $e');
      return false;
    }
  }

  /// Authenticate using biometrics
  Future<bool> authenticate({
    String reason = 'Authenticate to access Symphonia',
  }) async {
    try {
      final isAvailable = await isBiometricsAvailable();
      if (!isAvailable) {
        debugPrint('Biometrics not available');
        return true; // Allow access if biometrics not available
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow device PIN/pattern as fallback
        ),
      );

      return authenticated;
    } catch (e) {
      debugPrint('Biometric authentication error: $e');
      return false;
    }
  }

  /// Get biometric type name for display
  Future<String> getBiometricTypeName() async {
    final types = await getAvailableBiometrics();

    if (types.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (types.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (types.contains(BiometricType.iris)) {
      return 'Iris';
    } else if (types.contains(BiometricType.strong) ||
        types.contains(BiometricType.weak)) {
      return 'Biometrics';
    }
    return 'Device Lock';
  }
}
