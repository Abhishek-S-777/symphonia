import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/services/fcm_service.dart';
import 'core/services/notification_service.dart';

/// Main entry point for Symphonia
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (portrait only for intimate experience)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Firebase
  await Firebase.initializeApp();

  // DEBUG: Check auth state immediately after Firebase init
  final currentUser = fb.FirebaseAuth.instance.currentUser;
  debugPrint(
    'MAIN: After Firebase.initializeApp(), currentUser = ${currentUser?.email ?? "NULL"}',
  );

  // DEBUG: Listen to auth state changes to see what happens
  fb.FirebaseAuth.instance.authStateChanges().listen((user) {
    debugPrint(
      'MAIN: authStateChanges emitted user = ${user?.email ?? "NULL"}',
    );
  });

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.createChannels();

  // Initialize FCM service
  final fcmService = FCMService();
  await fcmService.initialize();

  runApp(const ProviderScope(child: SymphoniaApp()));
}
