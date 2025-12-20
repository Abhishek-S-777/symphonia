import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/services/auth_service.dart';
import 'core/services/message_service.dart';
import 'core/services/vibration_service.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/app_snackbar.dart';

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
      themeMode: ThemeMode.system,

      // Router configuration
      routerConfig: router,

      // Builder for global overlays and listeners
      builder: (context, child) {
        return MediaQuery(
          // Prevent text scaling issues
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.noScaling),
          child: _GlobalHeartbeatListener(child: child!),
        );
      },
    );
  }
}

/// Global listener for heartbeats and online/offline status
/// Handles app lifecycle to update online status
class _GlobalHeartbeatListener extends ConsumerStatefulWidget {
  final Widget child;

  const _GlobalHeartbeatListener({required this.child});

  @override
  ConsumerState<_GlobalHeartbeatListener> createState() =>
      _GlobalHeartbeatListenerState();
}

class _GlobalHeartbeatListenerState
    extends ConsumerState<_GlobalHeartbeatListener>
    with WidgetsBindingObserver {
  String? _lastProcessedHeartbeatId;
  bool _isInitialized = false;
  bool _isInForeground = true;
  DateTime? _lastResumedAt;

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
    // Unregister lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    // Set offline when widget is disposed
    _setOffline();
    super.dispose();
  }

  Future<void> _initialize() async {
    // Initialize vibration service
    final vibrationService = ref.read(vibrationServiceProvider);
    await vibrationService.initialize();

    // Set online status immediately when app starts
    _setOnline();

    setState(() => _isInitialized = true);
    debugPrint('✅ GlobalHeartbeatListener initialized - Set ONLINE');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    debugPrint('🔄 App lifecycle changed to: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        // App is in foreground - set online
        debugPrint('📱 App RESUMED - Setting ONLINE');
        _isInForeground = true;
        _lastResumedAt = DateTime.now();
        _setOnline();
        break;
      case AppLifecycleState.inactive:
        // App is transitioning (switching apps, phone call)
        // Set offline early while network is still available
        debugPrint('📱 App INACTIVE - Setting OFFLINE');
        _isInForeground = false;
        _setOffline();
        break;
      case AppLifecycleState.paused:
        // App is in background
        debugPrint('📱 App PAUSED - Confirming OFFLINE');
        _isInForeground = false;
        _setOffline();
        break;
      case AppLifecycleState.hidden:
        // App is hidden
        debugPrint('📱 App HIDDEN');
        _isInForeground = false;
        break;
      case AppLifecycleState.detached:
        // App is being terminated
        debugPrint('📱 App DETACHED');
        _isInForeground = false;
        _setOffline();
        break;
    }
  }

  void _setOnline() {
    try {
      final authService = ref.read(authServiceProvider);
      authService.setOnlineStatus(true);
    } catch (e) {
      debugPrint('Error setting online: $e');
    }
  }

  void _setOffline() {
    try {
      final authService = ref.read(authServiceProvider);
      authService.setOnlineStatus(false);
    } catch (e) {
      debugPrint('Error setting offline: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for incoming heartbeats globally
    // This is ONLY for foreground - background is handled by FCM
    ref.listen(latestReceivedHeartbeatProvider, (previous, next) {
      final currentUser = ref.watch(currentAppUserProvider).value;

      debugPrint('💓 Heartbeat provider update: ${next.value?.id}');

      if (!_isInitialized) {
        debugPrint('⚠️ Not initialized yet');
        return;
      }

      // Only process if app is in foreground
      if (!_isInForeground) {
        debugPrint(
          '⚠️ App not in foreground, skipping (FCM handles background)',
        );
        return;
      }

      final heartbeat = next.value;
      if (heartbeat == null) {
        debugPrint('⚠️ Heartbeat is null');
        return;
      }

      // Only process if this is a new heartbeat we haven't seen
      if (heartbeat.id == _lastProcessedHeartbeatId) {
        debugPrint('⚠️ Already processed this heartbeat');
        return;
      }

      // Only process heartbeats that arrived AFTER app resumed
      // This prevents cached/stale heartbeats from triggering
      if (_lastResumedAt != null &&
          heartbeat.sentAt.isBefore(_lastResumedAt!)) {
        debugPrint('⚠️ Heartbeat is older than last resume time, skipping');
        _lastProcessedHeartbeatId =
            heartbeat.id; // Mark as processed to avoid future checks
        return;
      }

      _lastProcessedHeartbeatId = heartbeat.id;

      debugPrint('🎉 NEW HEARTBEAT! Playing vibration...');

      // Play the heartbeat vibration pattern!
      final vibrationService = ref.read(vibrationServiceProvider);
      vibrationService.playHeartbeat();

      // Show a snackbar notification if we have a valid context
      final navigatorContext = rootNavigatorKey.currentContext;
      if (navigatorContext != null) {
        AppSnackbar.showSuccess(
          navigatorContext,
          '${currentUser?.displayName} sent you love! ❤️',
        );
      }
    });

    return widget.child;
  }
}
