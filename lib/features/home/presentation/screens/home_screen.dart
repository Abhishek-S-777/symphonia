import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/couple_service.dart';
import '../../../../core/services/message_service.dart';
import '../../../../core/services/quote_service.dart';
import '../../../../core/services/vibration_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../shared/widgets/animated_gradient_background.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/celebration_overlay.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../widgets/heart_button.dart';

/// Home screen with the Big Heart Button as central CTA
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _updateLastActive();
  }

  Future<void> _updateLastActive() async {
    // Update last active
    final authService = ref.read(authServiceProvider);
    await authService.updateLastActive();
  }

  Future<void> _onHeartPressed() async {
    try {
      // Light haptic feedback for sender only
      final vibrationService = ref.read(vibrationServiceProvider);
      await vibrationService.lightImpact();

      final messageService = ref.read(messageServiceProvider);
      await messageService.sendHeartbeat();

      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'You sent love! ❤️');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, 'Failed to send heartbeat');
    }
  }

  @override
  Widget build(BuildContext context) {
    final partner = ref.watch(partnerUserProvider);
    final couple = ref.watch(currentCoupleProvider);
    final dailyQuote = ref.watch(dailyQuoteProvider);
    final unreadCount = ref.watch(unreadMessagesCountProvider);

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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          // App name
          Text(
            'Symphonia',
            style: GoogleFonts.lavishlyYours(
              fontSize: 38,
              fontWeight: FontWeight.normal,
              color: AppColors.white,
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
    // Use the actual isOnline field from Firestore
    final isOnline = partner?.isOnline ?? false;

    final daysTogetherFormatted = couple?.daysTogetherFormatted ?? '0 days';
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
              border: Border.all(color: AppColors.white),
            ),
            child: partner?.photoUrl != null
                ? ClipOval(
                    child: Image.network(
                      partner.photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
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

          // Days together badge - tappable for celebration!
          GestureDetector(
            onTap: () => showCelebration(context, daysTogetherFormatted),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.white),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.favorite,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    daysTogetherFormatted,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
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
    return _DailyMessageCardWidget(quoteAsync: quoteAsync);
  }
}

/// Separate widget for daily message card to manage editing state
class _DailyMessageCardWidget extends ConsumerStatefulWidget {
  final AsyncValue<DailyQuote> quoteAsync;

  const _DailyMessageCardWidget({required this.quoteAsync});

  @override
  ConsumerState<_DailyMessageCardWidget> createState() =>
      _DailyMessageCardWidgetState();
}

class _DailyMessageCardWidgetState
    extends ConsumerState<_DailyMessageCardWidget> {
  bool _isEditing = false;
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    final currentQuote = widget.quoteAsync.value;
    _textController.text = currentQuote?.isCustom == true
        ? currentQuote!.quote
        : '';
    setState(() {
      _isEditing = true;
    });
    // Focus after next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
    });
    _textController.clear();
  }

  Future<void> _saveQuote() async {
    if (_textController.text.trim().isEmpty) {
      _cancelEditing();
      return;
    }

    final notifier = ref.read(dailyQuoteProvider.notifier);
    await notifier.setCustomQuote(_textController.text.trim());

    setState(() {
      _isEditing = false;
    });
    _textController.clear();
  }

  Future<void> _clearCustomQuote() async {
    final notifier = ref.read(dailyQuoteProvider.notifier);
    await notifier.clearCustomQuote();
  }

  @override
  Widget build(BuildContext context) {
    return GradientGlassCard(
      borderGradient: AppGradients.twilight,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with title and edit button
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Colors.amberAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Daily Love Note',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: Colors.amberAccent),
                ),
              ),
              // Edit/Clear button
              if (!_isEditing) ...[
                if (widget.quoteAsync.value?.isCustom == true)
                  GestureDetector(
                    onTap: _clearCustomQuote,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.white,
                      ),
                    ),
                  ),

                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _startEditing,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.amberAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.amberAccent,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Content: either editing or displaying
          if (_isEditing) ...[
            // Editing mode
            TextField(
              controller: _textController,
              focusNode: _focusNode,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Write a love note for your partner...',
                hintStyle: TextStyle(
                  color: AppColors.gray.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.accent.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.accent.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.accent,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _cancelEditing,
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.gray),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveQuote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ] else ...[
            // Display mode
            widget.quoteAsync.when(
              data: (quote) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Custom quote indicator
                  if (quote.isCustom)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.favorite,
                              size: 12,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Custom Note',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: quote.isCustom
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
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
        ],
      ),
    );
  }
}
