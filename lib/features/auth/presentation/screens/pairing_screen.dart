import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:symphonia/shared/widgets/app_snackbar.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/couple_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../shared/widgets/animated_gradient_background.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Pairing screen for connecting two devices
class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key});

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _codeController = TextEditingController();
  String? _generatedCode;
  bool _isLoading = false;
  bool _isPairing = false;
  String? _errorMessage;
  bool _hasNavigated = false; // Prevent multiple navigations

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _createPairingCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final coupleService = ref.read(coupleServiceProvider);
      final code = await coupleService.createPairingCode();

      setState(() {
        _generatedCode = code;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to generate code. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _validateCode() async {
    final code = _codeController.text.toUpperCase().trim();
    if (code.length != AppConstants.pairingCodeLength) {
      setState(() {
        _errorMessage =
            'Please enter a valid ${AppConstants.pairingCodeLength}-character code';
      });
      return;
    }

    setState(() {
      _isPairing = true;
      _errorMessage = null;
    });

    try {
      final coupleService = ref.read(coupleServiceProvider);
      await coupleService.usePairingCode(code);

      if (!mounted) return;

      // Save paired status to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(StorageKeys.isPaired, true);

      // Show success message
      AppSnackbar.showSuccess(context, 'Successfully paired! 💕');

      context.go(Routes.permissionSetupPath);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _getErrorMessage(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPairing = false;
        });
      }
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('Invalid pairing code')) {
      return 'Invalid pairing code. Please check and try again.';
    } else if (error.contains('expired')) {
      return 'This code has expired. Ask your partner for a new one.';
    } else if (error.contains('yourself')) {
      return 'You cannot pair with yourself.';
    } else if (error.contains('already paired')) {
      return 'This partner is already paired with someone else.';
    }
    return 'Pairing failed. Please try again.';
  }

  Future<void> _showLogoutConfirmation() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      try {
        final authService = ref.read(authServiceProvider);
        await authService.signOut();
        if (mounted) {
          context.go(Routes.loginPath);
        }
      } catch (e) {
        if (mounted) {
          AppSnackbar.showError(context, 'Failed to sign out');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for when the current user gets paired
    // This handles the case where Partner A creates a code and Partner B uses it
    // Partner A will be automatically redirected when pairing is successful
    ref.listen(currentAppUserProvider, (previous, next) {
      final previousUser = previous?.value;
      final currentUser = next.value;

      // Check if user just got paired (coupleId changed from null to non-null)
      if (previousUser != null &&
          previousUser.coupleId == null &&
          currentUser != null &&
          currentUser.coupleId != null &&
          !_hasNavigated) {
        _hasNavigated = true;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.favorite, color: AppColors.white),
                SizedBox(width: 12),
                Text('Your partner connected! 💕'),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate to permissions/home
        context.go(Routes.permissionSetupPath);
      }
    });

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // Logo with logout button
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Animated app icon
                        Center(
                              child: Image.asset(
                                'assets/icons/app-icon-light-transparent.png',
                                width: 60,
                                height: 60,
                                fit: BoxFit.contain,
                              ),
                            )
                            .animate(
                              onPlay: (controller) =>
                                  controller.repeat(reverse: true),
                            )
                            .scale(
                              begin: const Offset(1.0, 1.0),
                              end: const Offset(1.1, 1.1),
                              duration: 1000.ms,
                              curve: Curves.easeInOut,
                            ),

                        // Logout button on top right
                        Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton(
                            onPressed: _showLogoutConfirmation,
                            icon: Icon(
                              Icons.logout_rounded,
                              color: AppColors.error,
                              size: 24,
                            ),
                            tooltip: 'Sign out',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Connect with Your Partner',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 8),

                    Text(
                      'Pair your devices to start sharing moments together',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.grayDark,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 300.ms),
                  ],
                ),
              ),

              // Tab bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: GlassCard(
                  child: TabBar(
                    controller: _tabController,
                    indicatorPadding: const EdgeInsets.all(4),
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.gray,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Share Code'),
                      Tab(text: 'Enter Code'),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(left: 24, right: 24, top: 12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ).animate().shake(),

              if (_errorMessage != null) const SizedBox(height: 16),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildShareCodeTab(), _buildEnterCodeTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareCodeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Generate a Code',
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 8),

            Text(
              'Share this code with your partner to connect',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.grayDark),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            if (_generatedCode != null) ...[
              // Display code
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: AppGradients.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _generatedCode!,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                            color: AppColors.primary,
                          ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _generatedCode!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Code copied to clipboard!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, color: AppColors.primary),
                    ),
                  ],
                ),
              ).animate().scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
                duration: 400.ms,
                curve: Curves.elasticOut,
              ),

              const SizedBox(height: 16),

              Text(
                'Code expires in ${AppConstants.pairingCodeExpiryMinutes} minutes',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.gray),
              ),

              const SizedBox(height: 8),

              Text(
                'Share this code with your partner. They should enter it in the "Enter Code" tab.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.grayDark,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              SecondaryButton(
                text: 'Generate New Code',
                onPressed: _createPairingCode,
                isLoading: _isLoading,
              ),
            ] else ...[
              // Generate button
              const Icon(Icons.qr_code_2, size: 80, color: AppColors.gray),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Generate Code',
                icon: Icons.qr_code,
                onPressed: _createPairingCode,
                isLoading: _isLoading,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEnterCodeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              "Enter Partner's Code",
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 8),

            Text(
              'Ask your partner to share their code with you',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.grayDark),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Code input
            TextFormField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              maxLength: AppConstants.pairingCodeLength,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: '------',
                hintStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  letterSpacing: 8,
                  color: AppColors.grayLight,
                ),
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                UpperCaseTextFormatter(),
              ],
              onChanged: (value) {
                if (_errorMessage != null) {
                  setState(() {
                    _errorMessage = null;
                  });
                }
              },
            ),

            const SizedBox(height: 24),

            // Connect button
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                text: 'Connect',
                icon: Icons.favorite,
                onPressed: _validateCode,
                isLoading: _isPairing,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Text input formatter to convert to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
