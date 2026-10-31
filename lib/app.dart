import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:symphonia/core/logging/app_logger.dart';
import 'package:symphonia/core/router/app_router.dart';
import 'package:symphonia/core/router/routes.dart';
import 'package:symphonia/core/services/auth_service.dart';
import 'package:symphonia/core/services/vibration_service.dart';
import 'package:symphonia/core/theme/app_theme.dart';
import 'package:symphonia/features/auth/presentation/screens/biometrics_lock_screen.dart';
import 'package:symphonia/features/messages/data/message_repository.dart';
import 'package:symphonia/shared/widgets/app_snackbar.dart';

/// Global navigator key for accessing root context
/// Use this to show bottom sheets that appear over the navigation bar
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Root widget for Symphonia app
class SymphoniaApp extends ConsumerWidget {
  const SymphoniaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Symphonia',
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      // Localization for flutter_quill
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],

      // Router configuration
      routerConfig: router,

      // Builder for global overlays and listeners
      builder: (context, child) {
        return MediaQuery(
          // Prevent text scaling issues
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.noScaling),
          // Biometrics lock for returning from background
          child: BiometricsLockScreen(
            child: _GlobalHeartbeatListener(child: child!),
          ),
        );
      },
    );
  }
}

/// Global listener for heartbeats and online/offline status
/// Handles app lifecycle to update online status
class _GlobalHeartbeatListener extends ConsumerStatefulWidget {
  const _GlobalHeartbeatListener({required this.child});
  final Widget child;

  @override
  ConsumerState<_GlobalHeartbeatListener> createState() =>
      _GlobalHeartbeatListenerState();
}

class _GlobalHeartbeatListenerState
    extends ConsumerState<_GlobalHeartbeatListener>
    with WidgetsBindingObserver {
  String? _lastProcessedHeartbeatId;
  String? _lastProcessedHugsId;
  bool _isInitialized = false;
  bool _isInForeground = true;
  DateTime? _lastResumedAt;
  String? _previousCoupleId; // Track previous coupleId to detect unpair

  // Store reference to authService for use in dispose
  AuthService? _authService;

  @override
  void initState() {
    super.initState();
    // Register lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    _lastResumedAt = DateTime.now();
    _initialize();
  }

  @override
  void dispose() {
    // Set offline when widget is disposed
    _setOffline();
    // Unregister lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initialize() async {
    // Initialize vibration service
    final vibrationService = ref.read(vibrationServiceProvider);
    await vibrationService.initialize();

    // Set online status immediately when app starts
    _setOnline();

    if (!mounted) {
      return;
    }

    // Refresh FCM token on every app launch
    // This ensures notifications work even after reinstall
    _authService = ref.read(authServiceProvider);
    await _authService!.refreshFcmToken();

    if (!mounted) {
      return;
    }

    setState(() => _isInitialized = true);
    AppLogger.info(
      'GlobalHeartbeatListener initialized; set online and refreshed FCM token',
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    AppLogger.debug('App lifecycle changed to: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        // App is in foreground - set online
        AppLogger.debug('App resumed; setting online');
        _isInForeground = true;
        _lastResumedAt = DateTime.now();
        _setOnline();
      case AppLifecycleState.inactive:
        // App is transitioning (switching apps, phone call)
        // Set offline early while network is still available
        AppLogger.debug('App inactive; setting offline');
        _isInForeground = false;
        _setOffline();
      case AppLifecycleState.paused:
        // App is in background
        AppLogger.debug('App paused; confirming offline');
        _isInForeground = false;
        _setOffline();
      case AppLifecycleState.hidden:
        // App is hidden
        AppLogger.debug('App hidden');
        _isInForeground = false;
      case AppLifecycleState.detached:
        // App is being terminated
        AppLogger.debug('App detached');
        _isInForeground = false;
        _setOffline();
    }
  }

  void _setOnline() {
    try {
      final authService = ref.read(authServiceProvider);
      authService.setOnlineStatus(true);
    } catch (e) {
      AppLogger.error('Error setting online', error: e);
    }
  }

  void _setOffline() {
    try {
      final authService = ref.read(authServiceProvider);
      authService.setOnlineStatus(false);
    } catch (e) {
      AppLogger.error('Error setting offline', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch current user to detect unpair
    final currentUser = ref.watch(currentAppUserProvider).value;
    final currentCoupleId = currentUser?.coupleId;

    // Detect when user was paired but is now unpaired (partner unpaired them)
    if (_isInitialized &&
        _previousCoupleId != null &&
        currentCoupleId == null &&
        currentUser != null) {
      // Partner unpaired! Navigate to pairing screen
      AppLogger.warning(
        'Partner unpaired; coupleId changed from $_previousCoupleId to null',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navigatorContext = rootNavigatorKey.currentContext;
        if (navigatorContext != null) {
          AppSnackbar.showInfo(navigatorContext, 'Your partner has unpaired');
          GoRouter.of(navigatorContext).go(Routes.pairingPath);
        }
      });
    }

    // Update previous coupleId
    _previousCoupleId = currentCoupleId;

    // Listen for incoming heartbeats globally
    // This is ONLY for foreground - background is handled by FCM
    ref.listen(latestReceivedHeartbeatProvider, (previous, next) {
      if (!_isInitialized || !_isInForeground) return;

      final heartbeat = next.value;
      if (heartbeat == null) return;

      // Only process if this is a new heartbeat we haven't seen
      if (heartbeat.id == _lastProcessedHeartbeatId) return;

      // Only process heartbeats that arrived AFTER app resumed
      if (_lastResumedAt != null &&
          heartbeat.sentAt.isBefore(_lastResumedAt!)) {
        _lastProcessedHeartbeatId = heartbeat.id;
        return;
      }

      _lastProcessedHeartbeatId = heartbeat.id;

      // Play the heartbeat vibration pattern!
      final vibrationService = ref.read(vibrationServiceProvider);
      vibrationService.playHeartbeat();

      // Show a snackbar notification if we have a valid context
      final navigatorContext = rootNavigatorKey.currentContext;
      if (navigatorContext != null) {
        AppSnackbar.show(
          navigatorContext,
          message: 'Your partner sent you love! ❤️',
          type: SnackBarType.success,
          duration: const Duration(milliseconds: 1500),
        );
      }
    });

    // Listen for incoming hugs globally
    ref.listen(latestReceivedHugsProvider, (previous, next) {
      if (!_isInitialized || !_isInForeground) return;

      final hugs = next.value;
      if (hugs == null) return;

      // Only process if this is a new hug we haven't seen
      if (hugs.id == _lastProcessedHugsId) return;

      // Only process hugs that arrived AFTER app resumed
      if (_lastResumedAt != null && hugs.sentAt.isBefore(_lastResumedAt!)) {
        _lastProcessedHugsId = hugs.id;
        return;
      }

      _lastProcessedHugsId = hugs.id;

      // Play the hugs vibration pattern!
      final vibrationService = ref.read(vibrationServiceProvider);
      vibrationService.playHugs();

      // Show a snackbar notification
      final navigatorContext = rootNavigatorKey.currentContext;
      if (navigatorContext != null) {
        AppSnackbar.show(
          navigatorContext,
          message: 'Your partner sent you 🤗 hugs and kisses! 😘',
          type: SnackBarType.success,
          duration: const Duration(milliseconds: 1500),
        );
      }
    });

    return widget.child;
  }
}
