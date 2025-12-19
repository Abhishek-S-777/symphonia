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
import '../../../../shared/widgets/custom_button.dart';

/// Onboarding screen with beautiful illustrations
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      image: Image.asset(
        'assets/icons/app-icon-light-transparent.png',
        width: 80,
        height: 80,
        fit: BoxFit.contain,
      ),
      title: 'Share Your Heartbeat',
      description:
          'Send a gentle heartbeat to your partner with one tap. Let them feel your love, no matter the distance.',
      gradient: AppGradients.primary,
    ),
    OnboardingPage(
      icon: Icons.chat_bubble,
      title: 'Messages',
      description:
          'Send your heartfelt messages or record sweet voice messages and let your partner hear your voice whenever they miss you.',
      gradient: AppGradients.voiceNote,
    ),
    OnboardingPage(
      icon: Icons.auto_awesome,
      title: 'Special Moments',
      description:
          'Create special events with countdowns and let your partner know when it is time to celebrate the special moments.',
      gradient: AppGradients.specialMoments,
    ),
    // OnboardingPage(
    //   icon: Icons.photo_library,
    //   title: 'Memory Timeline',
    //   description:
    //       'Capture and cherish your special moments together in a beautiful shared gallery.',
    //   gradient: AppGradients.sunset,
    // ),
    OnboardingPage(
      icon: Icons.lock,
      title: 'Just You Two',
      description:
          'Your intimate space. Secure, private, and designed exclusively for the two of you.',
      gradient: AppGradients.twilight,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.onboardingComplete, true);

    if (!mounted) return;
    context.go(Routes.loginPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      'Skip',
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(color: AppColors.gray),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return _buildPage(page, index);
                  },
                ),
              ),

              // Page indicators and buttons
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Page indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => _buildPageIndicator(index),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Next / Get Started button
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        text: _currentPage == _pages.length - 1
                            ? 'Get Started'
                            : 'Next',
                        onPressed: () {
                          if (_currentPage == _pages.length - 1) {
                            _completeOnboarding();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon with gradient circle
          Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: page.gradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: page.icon != null
                    ? Icon(page.icon!, size: 70, color: AppColors.white)
                    : Center(child: page.image),
              )
              .animate(delay: 200.ms)
              .scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1.0, 1.0),
                duration: 500.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 48),

          // Title
          Text(
                page.title,
                style: GoogleFonts.lavishlyYours(
                  fontSize: 42,
                  fontWeight: FontWeight.normal,
                  color: AppColors.white,
                ),
                textAlign: TextAlign.center,
              )
              .animate(delay: 300.ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.2, end: 0),

          const SizedBox(height: 16),

          // Description
          Text(
                page.description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.gray,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              )
              .animate(delay: 400.ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    final isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: isActive ? AppColors.primary : AppColors.grayLight,
      ),
    );
  }
}

/// Data class for onboarding pages
class OnboardingPage {
  final IconData? icon;
  final Image? image;
  final String title;
  final String description;
  final Gradient gradient;

  const OnboardingPage({
    this.icon,
    this.image,
    required this.title,
    required this.description,
    required this.gradient,
  });
}
