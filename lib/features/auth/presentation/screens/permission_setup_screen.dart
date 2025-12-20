import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/services/vibration_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../shared/widgets/animated_gradient_background.dart';
import '../../../../shared/widgets/custom_button.dart';

/// Screen for requesting app permissions
class PermissionSetupScreen extends ConsumerStatefulWidget {
  const PermissionSetupScreen({super.key});

  @override
  ConsumerState<PermissionSetupScreen> createState() =>
      _PermissionSetupScreenState();
}

class _PermissionSetupScreenState extends ConsumerState<PermissionSetupScreen> {
  bool _notificationsGranted = false;
  bool _microphoneGranted = false;
  bool _cameraGranted = false;
  bool _photosGranted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final service = ref.read(permissionServiceProvider);

    final notificationStatus = await service.getNotificationStatus();
    final microphoneStatus = await service.getMicrophoneStatus();
    final cameraStatus = await service.getCameraStatus();
    final photosStatus = await service.getPhotosStatus();

    setState(() {
      _notificationsGranted = notificationStatus.isGranted;
      _microphoneGranted = microphoneStatus.isGranted;
      _cameraGranted = cameraStatus.isGranted;
      _photosGranted = photosStatus.isGranted;
      _isLoading = false;
    });
  }

  Future<void> _requestNotifications() async {
    final service = ref.read(permissionServiceProvider);
    final granted = await service.requestNotificationPermission();
    setState(() => _notificationsGranted = granted);

    if (granted) {
      ref.read(vibrationServiceProvider).success();
    }
  }

  Future<void> _requestMicrophone() async {
    final service = ref.read(permissionServiceProvider);
    final granted = await service.requestMicrophonePermission();
    setState(() => _microphoneGranted = granted);

    if (granted) {
      ref.read(vibrationServiceProvider).success();
    }
  }

  Future<void> _requestCamera() async {
    final service = ref.read(permissionServiceProvider);
    final granted = await service.requestCameraPermission();
    setState(() => _cameraGranted = granted);

    if (granted) {
      ref.read(vibrationServiceProvider).success();
    }
  }

  Future<void> _requestPhotos() async {
    final service = ref.read(permissionServiceProvider);
    final granted = await service.requestPhotosPermission();
    setState(() => _photosGranted = granted);

    if (granted) {
      ref.read(vibrationServiceProvider).success();
    }
  }

  Future<void> _requestAllPermissions() async {
    final service = ref.read(permissionServiceProvider);
    await service.requestAllPermissions();
    await _checkPermissions();

    // Initialize vibration service after permissions
    await ref.read(vibrationServiceProvider).initialize();
  }

  void _continue() {
    // Initialize vibration service
    ref.read(vibrationServiceProvider).initialize();

    // Navigate to home
    context.go(Routes.homePath);
  }

  bool get _allGranted =>
      _notificationsGranted; // Only notifications is essential

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      const SizedBox(height: 40),

                      // Header
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppGradients.primary,
                        ),
                        child: const Icon(
                          Icons.security,
                          size: 48,
                          color: AppColors.white,
                        ),
                      ).animate().scale(curve: Curves.elasticOut),

                      const SizedBox(height: 24),

                      Text(
                        'App Permissions',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Grant these permissions for the best experience',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.grayDark,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 40),

                      // Permission items
                      Expanded(
                        child: ListView(
                          children: [
                            _buildPermissionItem(
                              icon: Icons.notifications_active,
                              title: 'Notifications',
                              description:
                                  'Get notified when your partner sends you heartbeats and messages',
                              isGranted: _notificationsGranted,
                              isRequired: true,
                              onRequest: _requestNotifications,
                            ),
                            const SizedBox(height: 16),
                            _buildPermissionItem(
                              icon: Icons.mic,
                              title: 'Microphone',
                              description:
                                  'Record and send voice notes to your partner',
                              isGranted: _microphoneGranted,
                              onRequest: _requestMicrophone,
                            ),
                            // const SizedBox(height: 16),
                            // _buildPermissionItem(
                            //   icon: Icons.camera_alt,
                            //   title: 'Camera',
                            //   description:
                            //       'Take photos to add to your shared gallery',
                            //   isGranted: _cameraGranted,
                            //   onRequest: _requestCamera,
                            // ),
                            // const SizedBox(height: 16),
                            // _buildPermissionItem(
                            //   icon: Icons.photo_library,
                            //   title: 'Photos',
                            //   description:
                            //       'Access your photos to share memories together',
                            //   isGranted: _photosGranted,
                            //   onRequest: _requestPhotos,
                            // ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Grant all button
                      if (!_allGranted)
                        OutlinedButton.icon(
                          onPressed: _requestAllPermissions,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Grant All Permissions'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Continue button
                      PrimaryButton(
                        text: _allGranted ? 'Continue' : 'Skip for Now',
                        onPressed: _continue,
                        icon: Icons.arrow_forward,
                      ),

                      if (!_allGranted) ...[
                        const SizedBox(height: 8),
                        Text(
                          'You can grant permissions later in Settings',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.gray),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onRequest,
    bool isRequired = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted
              ? AppColors.success.withValues(alpha: 0.5)
              : (isRequired
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : AppColors.grayLight),
          width: isGranted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isGranted
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.primarySoft,
            ),
            child: Icon(
              isGranted ? Icons.check : icon,
              color: isGranted ? AppColors.success : AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.grayDark,
                      ),
                    ),
                    if (isRequired) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Required',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.grayDark),
                ),
              ],
            ),
          ),
          if (!isGranted)
            TextButton(onPressed: onRequest, child: const Text('Grant'))
          else
            const Icon(Icons.check_circle, color: AppColors.success),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }
}
