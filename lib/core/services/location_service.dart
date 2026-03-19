import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../constants/firebase_collections.dart';
import 'auth_service.dart';

/// Location service provider
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService(ref);
});

/// Entity representing a partner's location
class PartnerLocation {
  final String userId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final String? address;

  const PartnerLocation({
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    this.address,
  });

  factory PartnerLocation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PartnerLocation(
      userId: data['userId'] as String,
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      accuracy: (data['accuracy'] as num?)?.toDouble() ?? 0,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      address: data['address'] as String?,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins ${mins == 1 ? 'min' : 'mins'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    }
  }
}

/// Provider for partner's last known location
final partnerLocationProvider = StreamProvider<PartnerLocation?>((ref) {
  final currentUser = ref.watch(currentAppUserProvider).value;
  if (currentUser == null || currentUser.coupleId == null) {
    return Stream.value(null);
  }

  return FirebaseFirestore.instance
      .collection(FirebaseCollections.couples)
      .doc(currentUser.coupleId)
      .collection('locations')
      .where('userId', isNotEqualTo: currentUser.id)
      .orderBy('userId')
      .orderBy('timestamp', descending: true)
      .limit(1)
      .snapshots()
      .map((snapshot) {
        if (snapshot.docs.isEmpty) return null;
        return PartnerLocation.fromFirestore(snapshot.docs.first);
      });
});

/// Provider for own last known location
final myLocationProvider = StreamProvider<PartnerLocation?>((ref) {
  final currentUser = ref.watch(currentAppUserProvider).value;
  if (currentUser == null || currentUser.coupleId == null) {
    return Stream.value(null);
  }

  return FirebaseFirestore.instance
      .collection(FirebaseCollections.couples)
      .doc(currentUser.coupleId)
      .collection('locations')
      .where('userId', isEqualTo: currentUser.id)
      .orderBy('timestamp', descending: true)
      .limit(1)
      .snapshots()
      .map((snapshot) {
        if (snapshot.docs.isEmpty) return null;
        return PartnerLocation.fromFirestore(snapshot.docs.first);
      });
});

/// Service for handling location tracking
class LocationService {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  LocationService(this._ref);

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Check if we have location permission
  Future<bool> hasLocationPermission() async {
    final permission = await checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      // Check if service is enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('📍 Location services disabled');
        return null;
      }

      // Check permission
      var permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('📍 Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('📍 Location permission permanently denied');
        return null;
      }

      // Get position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      debugPrint(
        '📍 Got position: ${position.latitude}, ${position.longitude}',
      );
      return position;
    } catch (e) {
      debugPrint('📍 Error getting position: $e');
      return null;
    }
  }

  /// Share current location to Firestore
  Future<bool> shareMyLocation() async {
    try {
      final currentUser = _ref.read(currentAppUserProvider).value;
      if (currentUser == null || currentUser.coupleId == null) {
        debugPrint('📍 No user or coupleId');
        return false;
      }

      final position = await getCurrentPosition();
      if (position == null) {
        return false;
      }

      // Save to Firestore
      await _firestore
          .collection(FirebaseCollections.couples)
          .doc(currentUser.coupleId)
          .collection('locations')
          .doc(currentUser.id)
          .set({
            'userId': currentUser.id,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'accuracy': position.accuracy,
            'timestamp': FieldValue.serverTimestamp(),
          });

      debugPrint('📍 Location shared successfully');
      return true;
    } catch (e) {
      debugPrint('📍 Error sharing location: $e');
      return false;
    }
  }

  /// Request partner's location via FCM
  Future<void> requestPartnerLocation() async {
    final currentUser = _ref.read(currentAppUserProvider).value;
    if (currentUser == null || currentUser.coupleId == null) return;

    // Create a location request document that triggers Cloud Function
    await _firestore
        .collection(FirebaseCollections.couples)
        .doc(currentUser.coupleId)
        .collection('location_requests')
        .add({
          'requesterId': currentUser.id,
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'request_location',
        });

    debugPrint('📍 Location request sent');
  }

  /// Request partner's phone to ring via FCM
  Future<void> requestPartnerRing() async {
    final currentUser = _ref.read(currentAppUserProvider).value;
    if (currentUser == null || currentUser.coupleId == null) return;

    // Create a ring request document that triggers Cloud Function
    await _firestore
        .collection(FirebaseCollections.couples)
        .doc(currentUser.coupleId)
        .collection('ring_requests')
        .add({
          'requesterId': currentUser.id,
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'ring_phone',
        });

    debugPrint('🔔 Ring request sent');
  }

  /// Stop partner's phone ringing via FCM
  Future<void> stopPartnerRing() async {
    final currentUser = _ref.read(currentAppUserProvider).value;
    if (currentUser == null || currentUser.coupleId == null) return;

    await _firestore
        .collection(FirebaseCollections.couples)
        .doc(currentUser.coupleId)
        .collection('ring_requests')
        .add({
          'requesterId': currentUser.id,
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'stop_ring',
        });

    debugPrint('🔔 Stop ring request sent');
  }

  /// Calculate distance between two points in km
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  /// Format distance for display
  String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceKm.round()} km';
    }
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }
}
