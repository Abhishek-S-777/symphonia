import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/profile_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../shared/widgets/animated_gradient_background.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Signup screen with elegant design
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  File? _selectedImage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final profileService = ref.read(profileServiceProvider);
    final pickedImage = await profileService.pickAndCropImage(context);
    if (pickedImage != null && mounted) {
      setState(() {
        _selectedImage = pickedImage;
      });
    }
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final credential = await authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );

      // Upload profile image if selected
      if (_selectedImage != null && credential.user != null) {
        final profileService = ref.read(profileServiceProvider);
        final photoUrl = await profileService.uploadProfileImage(
          imageFile: _selectedImage!,
          userId: credential.user!.uid,
        );

        // Update profile with photo URL
        if (photoUrl != null) {
          await authService.updateProfile(photoUrl: photoUrl);
        }
      }

      if (!mounted) return;
      context.go(Routes.pairingPath);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _getErrorMessage(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('email-already-in-use')) {
      return 'An account already exists with this email';
    } else if (error.contains('invalid-email')) {
      return 'Invalid email address';
    } else if (error.contains('weak-password')) {
      return 'Password is too weak. Use at least 8 characters';
    } else if (error.contains('operation-not-allowed')) {
      return 'Signup is currently disabled';
    } else if (error.contains('network')) {
      return 'Network error. Please check your connection';
    }
    return 'Signup failed. Please try again';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: SizedBox(
            height: double.infinity,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => context.go(Routes.loginPath),
                      icon: const Icon(Icons.arrow_back_ios),
                      color: AppColors.charcoal,
                    ),
                  ),

                  // Logo and title
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,

                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 30,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/icons/app-icon-light-transparent.png',
                              width: 50,
                              height: 50,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ).animate().scale(
                          duration: 600.ms,
                          curve: Curves.elasticOut,
                        ),

                        const SizedBox(height: 24),

                        Text(
                          'Create Account',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ).animate().fadeIn(delay: 200.ms),

                        const SizedBox(height: 8),

                        Text(
                          'Begin your journey together',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.grayDark),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 300.ms),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Error message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
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

                  // Signup form
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Profile Photo Picker
                          Center(
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Column(
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: AppGradients.heartNormal,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.2),
                                              blurRadius: 15,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: ClipOval(
                                          child: _selectedImage != null
                                              ? Image.file(
                                                  _selectedImage!,
                                                  fit: BoxFit.cover,
                                                  width: 80,
                                                  height: 80,
                                                )
                                              : const Icon(
                                                  Icons.person,
                                                  color: AppColors.white,
                                                  size: 40,
                                                ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppColors.accent,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Theme.of(
                                                context,
                                              ).scaffoldBackgroundColor,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.add_a_photo,
                                            size: 14,
                                            color: AppColors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _selectedImage != null
                                        ? 'Tap to change'
                                        : 'Add profile photo',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: AppColors.gray),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Name field
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Your Name',
                              hintText: 'Enter your name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              if (value.length < 2) {
                                return 'Name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Email field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'Enter your email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@') ||
                                  !value.contains('.')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Create a password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (value.length < 8) {
                                return 'Password must be at least 8 characters';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Confirm password field
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _signup(),
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              hintText: 'Confirm your password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 32),

                          // Signup button
                          PrimaryButton(
                            text: 'Create Account',
                            isLoading: _isLoading,
                            onPressed: _signup,
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 24),

                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.grayDark,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go(Routes.loginPath),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
