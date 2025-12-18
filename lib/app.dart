import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/services/auth_service.dart';
import 'core/services/message_service.dart';
import 'core/services/vibration_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';

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

/// Global listener for heartbeats ONLY
/// Simplified version without online/offline status to debug
class _GlobalHeartbeatListener extends ConsumerStatefulWidget {
  final Widget child;

  const _GlobalHeartbeatListener({required this.child});

  @override
  ConsumerState<_GlobalHeartbeatListener> createState() =>
      _GlobalHeartbeatListenerState();
}

class _GlobalHeartbeatListenerState
    extends ConsumerState<_GlobalHeartbeatListener> {
  String? _lastProcessedHeartbeatId;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Initialize vibration service
    final vibrationService = ref.read(vibrationServiceProvider);
    await vibrationService.initialize();

    // Update last active
    final authService = ref.read(authServiceProvider);
    await authService.updateLastActive();

    setState(() => _isInitialized = true);
    debugPrint('✅ GlobalHeartbeatListener initialized');
  }

  @override
  Widget build(BuildContext context) {
    // Listen for incoming heartbeats globally
    ref.listen(latestReceivedHeartbeatProvider, (previous, next) {
      debugPrint('💓 Heartbeat provider update: ${next.value?.id}');

      if (!_isInitialized) {
        debugPrint('⚠️ Not initialized yet');
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
      _lastProcessedHeartbeatId = heartbeat.id;

      debugPrint('🎉 NEW HEARTBEAT! Playing vibration...');

      // Play the heartbeat vibration pattern!
      final vibrationService = ref.read(vibrationServiceProvider);
      vibrationService.playHeartbeat();

      // Show a snackbar notification if we have a valid context
      final navigatorContext = rootNavigatorKey.currentContext;
      if (navigatorContext != null) {
        ScaffoldMessenger.of(navigatorContext).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.favorite, color: AppColors.white),
                SizedBox(width: 12),
                Text('Your partner sent you a heartbeat!'),
              ],
            ),
            backgroundColor: AppColors.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });

    return widget.child;
  }
}
