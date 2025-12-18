import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
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
    // Simulate initialization (loading preferences, checking auth, etc.)
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    // Check if onboarding is complete
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete =
        prefs.getBool(StorageKeys.onboardingComplete) ?? false;
    final isPaired = prefs.getBool(StorageKeys.isPaired) ?? false;

    if (!mounted) return;

    if (!onboardingComplete) {
      context.go(Routes.onboardingPath);
    } else if (!isPaired) {
      // TODO: Check if user is logged in
      // For now, go to login
      context.go(Routes.loginPath);
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
              Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppGradients.heartNormal,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite,
                      size: 60,
                      color: AppColors.white,
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

              const SizedBox(height: 32),

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
