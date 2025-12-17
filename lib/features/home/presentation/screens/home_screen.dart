import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/couple_service.dart';
import '../../../../core/services/message_service.dart';
import '../../../../core/services/quote_service.dart';
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
  String? _lastHeartbeatId;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Initialize vibration service
    final vibrationService = ref.read(vibrationServiceProvider);
    await vibrationService.initialize();

    // Update last active
    final authService = ref.read(authServiceProvider);
    await authService.updateLastActive();
  }

  /// Listen for incoming heartbeats and vibrate
  void _handleIncomingHeartbeat(AsyncValue<dynamic> heartbeatAsync) {
    final heartbeat = heartbeatAsync.value;
    if (heartbeat != null && heartbeat.id != _lastHeartbeatId) {
      _lastHeartbeatId = heartbeat.id;

      // Play the heartbeat vibration pattern for the receiver!
      final vibrationService = ref.read(vibrationServiceProvider);
      vibrationService.playHeartbeat();

      // Show a snackbar notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
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
          ),
        );
      }
    }
  }

  Future<void> _onHeartPressed() async {
    try {
      // Light haptic feedback for sender only
      final vibrationService = ref.read(vibrationServiceProvider);
      await vibrationService.lightImpact();

      final messageService = ref.read(messageServiceProvider);
      await messageService.sendHeartbeat();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.favorite, color: AppColors.white),
              SizedBox(width: 12),
              Text('Heartbeat sent!'),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send heartbeat: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final partner = ref.watch(partnerUserProvider);
    final couple = ref.watch(currentCoupleProvider);
    final dailyQuote = ref.watch(dailyQuoteProvider);
    final unreadCount = ref.watch(unreadMessagesCountProvider);

    // Listen for incoming heartbeats from partner
    ref.listen(latestReceivedHeartbeatProvider, (previous, next) {
      _handleIncomingHeartbeat(next);
    });

    return GradientBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // App bar
            _buildAppBar(unreadCount.value ?? 0),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Partner status card
                    _buildPartnerCard(partner.value, couple.value)
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
                    _buildDailyMessageCard(dailyQuote)
                        .animate()
                        .fadeIn(delay: 800.ms)
                        .slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(int unreadCount) {
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
            onPressed: () => context.go(Routes.messagesPath),
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined),
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                      child: Center(
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

  Widget _buildPartnerCard(dynamic partner, dynamic couple) {
    final isOnline =
        partner != null &&
        DateTime.now().difference(partner.lastActive as DateTime).inMinutes < 5;

    final daysTogether = couple?.daysTogether ?? 0;
    final partnerName = partner?.displayName ?? 'Your Partner';

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
            child: partner?.photoUrl != null
                ? ClipOval(
                    child: Image.network(
                      partner.photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        color: AppColors.white,
                        size: 28,
                      ),
                    ),
                  )
                : const Icon(Icons.person, color: AppColors.white, size: 28),
          ),

          const SizedBox(width: 16),

          // Partner info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partnerName,
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
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline ? AppColors.success : AppColors.gray,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOnline ? 'Online now' : 'Offline',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isOnline ? AppColors.success : AppColors.gray,
                      ),
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
                  '$daysTogether days',
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
          icon: Icons.mic,
          label: 'Voice',
          color: AppColors.accent,
          onTap: () => context.push(Routes.voiceNotesPath),
        ),
        _buildQuickActionButton(
          icon: Icons.event,
          label: 'Events',
          color: AppColors.secondary,
          onTap: () => context.go(Routes.eventsPath),
        ),
        _buildQuickActionButton(
          icon: Icons.settings,
          label: 'Settings',
          color: AppColors.grayDark,
          onTap: () => context.push(Routes.settingsPath),
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

  Widget _buildDailyMessageCard(AsyncValue<DailyQuote> quoteAsync) {
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
          quoteAsync.when(
            data: (quote) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"${quote.quote}"',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '— ${quote.author}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.gray),
                  ),
                ),
              ],
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => Text(
              '"Love is not about how many days, months, or years you have been together. Love is about how much you love each other every single day."',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
