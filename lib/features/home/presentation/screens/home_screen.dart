import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/services/vibration_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../shared/widgets/animated_gradient_background.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../widgets/heart_button.dart';

/// Home screen with the Big Heart Button as central CTA
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Initialize vibration service
    final vibrationService = ref.read(vibrationServiceProvider);
    await vibrationService.initialize();
  }

  void _onHeartPressed() {
    // TODO: Send heartbeat to partner via Firebase
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.favorite, color: AppColors.white),
            const SizedBox(width: 12),
            const Text('Heartbeat sent! 💓'),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              _buildAppBar(),

              // Main content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Partner status card
                      _buildPartnerCard()
                          .animate()
                          .fadeIn(delay: 200.ms)
                          .slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 40),

                      // Big Heart Button
                      HeartButton(
                        onPressed: _onHeartPressed,
                        size: 180,
                      ).animate().scale(
                        delay: 400.ms,
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                      ),

                      const SizedBox(height: 16),

                      // Instruction text
                      Text(
                        'Tap to send a heartbeat',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.gray,
                          fontStyle: FontStyle.italic,
                        ),
                      ).animate().fadeIn(delay: 600.ms),

                      const SizedBox(height: 40),

                      // Quick actions
                      _buildQuickActions()
                          .animate()
                          .fadeIn(delay: 700.ms)
                          .slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 24),

                      // Daily message card
                      _buildDailyMessageCard()
                          .animate()
                          .fadeIn(delay: 800.ms)
                          .slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 100), // Space for nav bar
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Logo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.primary,
            ),
            child: const Icon(Icons.favorite, color: AppColors.white, size: 20),
          ),

          const SizedBox(width: 12),

          // App name
          Text(
            'Symphonia',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),

          const Spacer(),

          // Notifications
          IconButton(
            onPressed: () {
              // TODO: Show notifications
            },
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Settings
          IconButton(
            onPressed: () => context.push(Routes.settingsPath),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerCard() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Partner avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.sunset,
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.person, color: AppColors.white, size: 28),
          ),

          const SizedBox(width: 16),

          // Partner info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Partner', // TODO: Get partner name
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Online now',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.success),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Days together badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  '365 days', // TODO: Calculate days together
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildQuickActionButton(
          icon: Icons.message,
          label: 'Message',
          color: AppColors.primary,
          onTap: () => context.push(Routes.messagesPath),
        ),
        _buildQuickActionButton(
          icon: Icons.mic,
          label: 'Voice',
          color: AppColors.accent,
          onTap: () => context.push(Routes.voiceNotesPath),
        ),
        _buildQuickActionButton(
          icon: Icons.photo_library,
          label: 'Gallery',
          color: AppColors.secondary,
          onTap: () => context.push(Routes.galleryPath),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.charcoal),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyMessageCard() {
    return GradientGlassCard(
      borderGradient: AppGradients.twilight,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Daily Love Note',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: AppColors.accent),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"In all the world, there is no heart for me like yours. In all the world, there is no love for you like mine."',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '— Maya Angelou',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.gray),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: 'Messages',
                index: 1,
                onTap: () => context.push(Routes.messagesPath),
              ),
              _buildNavItem(
                icon: Icons.photo_library_outlined,
                activeIcon: Icons.photo_library,
                label: 'Gallery',
                index: 2,
                onTap: () => context.push(Routes.galleryPath),
              ),
              _buildNavItem(
                icon: Icons.event_outlined,
                activeIcon: Icons.event,
                label: 'Events',
                index: 3,
                onTap: () {
                  // TODO: Navigate to events
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    VoidCallback? onTap,
  }) {
    final isActive = _selectedIndex == index;

    return GestureDetector(
      onTap:
          onTap ??
          () {
            setState(() {
              _selectedIndex = index;
            });
          },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primary : AppColors.gray,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isActive ? AppColors.primary : AppColors.gray,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
