import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/services/biometrics_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Biometrics lock screen - shows on cold start AND when returning from background
class BiometricsLockScreen extends ConsumerStatefulWidget {
  final Widget child;

  const BiometricsLockScreen({super.key, required this.child});

  @override
  ConsumerState<BiometricsLockScreen> createState() =>
      _BiometricsLockScreenState();
}

class _BiometricsLockScreenState extends ConsumerState<BiometricsLockScreen>
    with WidgetsBindingObserver {
  bool _isLocked = false;
  bool _isAuthenticating = false;
  bool _wasInBackground = false;
  bool _justUnlocked = false;
  bool _initialCheckDone = false;
  String _biometricType = 'Biometrics';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadBiometricType();
    // Check biometrics on cold start after a small delay to let the app initialize
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialLock();
    });
  }

  Future<void> _loadBiometricType() async {
    final biometricsService = ref.read(biometricsServiceProvider);
    final typeName = await biometricsService.getBiometricTypeName();
    if (mounted) {
      setState(() {
        _biometricType = typeName;
      });
    }
  }

  /// Check if we should lock on cold start
  Future<void> _checkInitialLock() async {
    if (_initialCheckDone) return;
    _initialCheckDone = true;

    debugPrint('BiometricsLock: Checking initial lock...');

    // Check if user is authenticated (using SharedPreferences since Firebase might not be ready)
    final prefs = await SharedPreferences.getInstance();
    final isAuthenticated = prefs.getBool(StorageKeys.isAuthenticated) ?? false;

    if (!isAuthenticated) {
      debugPrint('BiometricsLock: Not authenticated, skipping initial lock');
      return;
    }

    // Check if biometrics is enabled
    final biometricsService = ref.read(biometricsServiceProvider);
    final isEnabled = await biometricsService.isBiometricsEnabled();

    if (!isEnabled) {
      debugPrint(
        'BiometricsLock: Biometrics not enabled, skipping initial lock',
      );
      return;
    }

    debugPrint('BiometricsLock: Locking on cold start');

    if (mounted) {
      setState(() {
        _isLocked = true;
      });
    }

    // Small delay then authenticate
    await Future.delayed(const Duration(milliseconds: 500));
    await _authenticate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint(
      'BiometricsLock: Lifecycle = $state, wasInBackground=$_wasInBackground, justUnlocked=$_justUnlocked',
    );

    if (state == AppLifecycleState.paused) {
      // Going to background
      _wasInBackground = true;
      _justUnlocked = false;
    } else if (state == AppLifecycleState.resumed) {
      // Coming back from background
      if (_wasInBackground && !_justUnlocked) {
        _wasInBackground = false;
        _checkAndLock();
      }
    }
  }

  Future<void> _checkAndLock() async {
    debugPrint('BiometricsLock: Checking if should lock on resume...');

    // Check if user is authenticated
    final prefs = await SharedPreferences.getInstance();
    final isAuthenticated = prefs.getBool(StorageKeys.isAuthenticated) ?? false;

    if (!isAuthenticated) {
      debugPrint('BiometricsLock: Not authenticated, skipping');
      return;
    }

    // Check if biometrics is enabled
    final biometricsService = ref.read(biometricsServiceProvider);
    final isEnabled = await biometricsService.isBiometricsEnabled();

    if (!isEnabled) {
      debugPrint('BiometricsLock: Biometrics not enabled');
      return;
    }

    debugPrint('BiometricsLock: Locking screen');

    if (mounted) {
      setState(() {
        _isLocked = true;
      });
    }

    // Small delay then authenticate
    await Future.delayed(const Duration(milliseconds: 300));
    await _authenticate();
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    if (mounted) {
      setState(() {
        _isAuthenticating = true;
      });
    }

    try {
      final biometricsService = ref.read(biometricsServiceProvider);
      final authenticated = await biometricsService.authenticate(
        reason: 'Authenticate to access Symphonia',
      );

      debugPrint('BiometricsLock: Auth result = $authenticated');

      if (mounted) {
        setState(() {
          _isLocked = !authenticated;
          _isAuthenticating = false;
          if (authenticated) {
            _justUnlocked = true;
          }
        });
      }
    } catch (e) {
      debugPrint('BiometricsLock: Auth error: $e');
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocked) {
      return widget.child;
    }

    // Dark lock screen
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/icons/app-icon-light-transparent.png',
                  width: 100,
                  height: 100,
                ).animate().fadeIn().scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                  duration: 500.ms,
                  curve: Curves.easeOutBack,
                ),

                Text(
                  'Symphonia',
                  style: GoogleFonts.lavishlyYours(
                    fontSize: 42,
                    fontWeight: FontWeight.normal,
                    color: AppColors.white,
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 8),

                Text(
                  'Unlock with $_biometricType',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.gray),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 48),

                GestureDetector(
                      onTap: _isAuthenticating ? null : _authenticate,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: _isAuthenticating
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                _getBiometricIcon(),
                                color: Colors.white,
                                size: 40,
                              ),
                      ),
                    )
                    .animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    )
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.05, 1.05),
                      duration: 1500.ms,
                      curve: Curves.easeInOut,
                    ),

                const SizedBox(height: 24),

                Text(
                  'Tap to unlock',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.gray),
                ).animate().fadeIn(delay: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getBiometricIcon() {
    if (_biometricType.contains('Face')) {
      return Icons.face;
    } else if (_biometricType.contains('Fingerprint')) {
      return Icons.fingerprint;
    } else {
      return Icons.lock_open;
    }
  }
}
