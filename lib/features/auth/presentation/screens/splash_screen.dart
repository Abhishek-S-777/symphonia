import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/animated_gradient_background.dart';

/// Splash screen with animated logo
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    if (!mounted) return;

    // Check SharedPreferences for auth state
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete =
        prefs.getBool(StorageKeys.onboardingComplete) ?? false;
    final isAuthenticated = prefs.getBool(StorageKeys.isAuthenticated) ?? false;
    final isPaired = prefs.getBool(StorageKeys.isPaired) ?? false;

    if (!mounted) return;

    // Navigation flow:
    // 1. Not onboarded → Onboarding
    // 2. Not authenticated → Login
    // 3. Authenticated but not paired → Pairing
    // 4. Authenticated and paired → Wait for Firebase then Home

    if (!onboardingComplete) {
      context.go(Routes.onboardingPath);
    } else if (!isAuthenticated) {
      context.go(Routes.loginPath);
    } else if (!isPaired) {
      context.go(Routes.pairingPath);
    } else {
      context.go(Routes.homePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        showPattern: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated heart logo
              Center(
                    child: Image.asset(
                      'assets/icons/app-icon-light-transparent.png',
                      width: 60,
                      height: 60,
                      fit: BoxFit.contain,
                    ),
                  )
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.15, 1.15),
                    duration: 800.ms,
                    curve: Curves.easeInOut,
                  ),

              // App name
              Text(
                    'Symphonia',
                    style: GoogleFonts.lavishlyYours(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                      letterSpacing: 2,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 600.ms)
                  .slideY(
                    begin: 0.3,
                    end: 0,
                    delay: 300.ms,
                    duration: 600.ms,
                    curve: Curves.easeOut,
                  ),

              const SizedBox(height: 8),

              // Tagline
              Text(
                'Your Love, Your Symphony',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.grayDark,
                  fontStyle: FontStyle.italic,
                ),
              ).animate().fadeIn(delay: 600.ms, duration: 600.ms),

              const SizedBox(height: 60),

              // Loading indicator
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary.withValues(alpha: 0.6),
                  ),
                ),
              ).animate().fadeIn(delay: 900.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
