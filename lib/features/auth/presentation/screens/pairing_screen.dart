import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/router/routes.dart';
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

  String _generatePairingCode() {
    final random = Random.secure();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(
      AppConstants.pairingCodeLength,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  Future<void> _createPairingCode() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Generate a unique code
      final code = _generatePairingCode();

      // TODO: Save to Firebase with user ID and expiry
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _generatedCode = code;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to generate code: $e')));
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _validateCode() async {
    final code = _codeController.text.toUpperCase().trim();
    if (code.length != AppConstants.pairingCodeLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-character code')),
      );
      return;
    }

    setState(() {
      _isPairing = true;
    });

    try {
      // TODO: Validate code in Firebase and create couple
      await Future.delayed(const Duration(seconds: 1));

      // Mark as paired
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(StorageKeys.isPaired, true);

      if (!mounted) return;
      context.go(Routes.homePath);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Invalid or expired code: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isPairing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    // Animated heart icon
                    Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppGradients.twilight,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.favorite,
                            size: 50,
                            color: AppColors.white,
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
                  color: AppColors.grayLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.charcoal.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorPadding: const EdgeInsets.all(4),
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.gray,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Share Code'),
                    Tab(text: 'Enter Code'),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 24),

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
                          const SnackBar(content: Text('Code copied!')),
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

              const SizedBox(height: 24),

              SecondaryButton(
                text: 'Generate New Code',
                onPressed: _createPairingCode,
                isLoading: _isLoading,
              ),
            ] else ...[
              // Generate button
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
              'Enter Partner\'s Code',
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
