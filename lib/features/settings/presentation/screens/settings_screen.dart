import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/couple_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/animated_gradient_background.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Settings screen for app configuration
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _vibrationEnabled = true;
  bool _soundEnabled = true;
  bool _heartbeatEnabled = true;
  bool _darkMode = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;
      _soundEnabled = prefs.getBool('soundEnabled') ?? true;
      _heartbeatEnabled = prefs.getBool('heartbeatEnabled') ?? true;
      _darkMode = prefs.getBool('darkMode') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await prefs.setBool('vibrationEnabled', _vibrationEnabled);
    await prefs.setBool('soundEnabled', _soundEnabled);
    await prefs.setBool('heartbeatEnabled', _heartbeatEnabled);
    await prefs.setBool('darkMode', _darkMode);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentAppUserProvider).value;
    final couple = ref.watch(currentCoupleProvider).value;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              _buildAppBar(),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile section
                      _buildProfileSection(currentUser)
                          .animate()
                          .fadeIn(delay: 100.ms)
                          .slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 32),

                      // Notifications section
                      _buildSectionTitle('Notifications'),
                      const SizedBox(height: 12),
                      _buildSettingsCard([
                            _buildSwitchTile(
                              icon: Icons.notifications_outlined,
                              title: 'Push Notifications',
                              subtitle: 'Receive alerts from your partner',
                              value: _notificationsEnabled,
                              onChanged: (value) {
                                setState(() => _notificationsEnabled = value);
                                _saveSettings();
                              },
                            ),
                            _buildDivider(),
                            _buildSwitchTile(
                              icon: Icons.vibration,
                              title: 'Vibration',
                              subtitle: 'Haptic feedback for interactions',
                              value: _vibrationEnabled,
                              onChanged: (value) {
                                setState(() => _vibrationEnabled = value);
                                _saveSettings();
                              },
                            ),
                            _buildDivider(),
                            _buildSwitchTile(
                              icon: Icons.volume_up_outlined,
                              title: 'Sound',
                              subtitle: 'Notification sounds',
                              value: _soundEnabled,
                              onChanged: (value) {
                                setState(() => _soundEnabled = value);
                                _saveSettings();
                              },
                            ),
                          ])
                          .animate()
                          .fadeIn(delay: 200.ms)
                          .slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 24),

                      // Features section
                      _buildSectionTitle('Features'),
                      const SizedBox(height: 12),
                      _buildSettingsCard([
                            _buildSwitchTile(
                              icon: Icons.favorite,
                              title: 'Background Heartbeat',
                              subtitle:
                                  'Send heartbeats even when app is closed',
                              value: _heartbeatEnabled,
                              onChanged: (value) {
                                setState(() => _heartbeatEnabled = value);
                                _saveSettings();
                              },
                            ),
                          ])
                          .animate()
                          .fadeIn(delay: 300.ms)
                          .slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 24),

                      // Appearance section
                      _buildSectionTitle('Appearance'),
                      const SizedBox(height: 12),
                      _buildSettingsCard([
                            _buildSwitchTile(
                              icon: Icons.dark_mode_outlined,
                              title: 'Dark Mode',
                              subtitle: 'Switch to dark theme',
                              value: _darkMode,
                              onChanged: (value) {
                                setState(() => _darkMode = value);
                                _saveSettings();
                                // TODO: Implement theme switching
                              },
                            ),
                          ])
                          .animate()
                          .fadeIn(delay: 400.ms)
                          .slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 24),

                      // Account section
                      _buildSectionTitle('Account'),
                      const SizedBox(height: 12),
                      _buildSettingsCard([
                            _buildActionTile(
                              icon: Icons.person_outline,
                              title: 'Edit Profile',
                              onTap: () => _showEditProfileDialog(currentUser),
                            ),
                            _buildDivider(),
                            _buildActionTile(
                              icon: Icons.lock_outline,
                              title: 'Change Password',
                              onTap: () => _showChangePasswordDialog(),
                            ),
                            _buildDivider(),
                            _buildActionTile(
                              icon: Icons.link_off,
                              title: 'Unpair Device',
                              color: AppColors.warning,
                              onTap: () => _showUnpairDialog(couple?.id),
                            ),
                          ])
                          .animate()
                          .fadeIn(delay: 500.ms)
                          .slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 24),

                      // About section
                      _buildSectionTitle('About'),
                      const SizedBox(height: 12),
                      _buildSettingsCard([
                            _buildActionTile(
                              icon: Icons.info_outline,
                              title: 'About Symphonia',
                              onTap: () => _showAboutDialog(),
                            ),
                            _buildDivider(),
                            _buildActionTile(
                              icon: Icons.privacy_tip_outlined,
                              title: 'Privacy Policy',
                              onTap: () {
                                // TODO: Open privacy policy
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Privacy Policy coming soon'),
                                  ),
                                );
                              },
                            ),
                            _buildDivider(),
                            _buildActionTile(
                              icon: Icons.description_outlined,
                              title: 'Terms of Service',
                              onTap: () {
                                // TODO: Open terms
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Terms of Service coming soon',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ])
                          .animate()
                          .fadeIn(delay: 600.ms)
                          .slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 32),

                      // Logout button
                      Center(
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : TextButton.icon(
                                onPressed: () => _showLogoutDialog(),
                                icon: const Icon(
                                  Icons.logout,
                                  color: AppColors.error,
                                ),
                                label: Text(
                                  'Sign Out',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(color: AppColors.error),
                                ),
                              ),
                      ).animate().fadeIn(delay: 700.ms),

                      const SizedBox(height: 16),

                      // Version
                      Center(
                        child: Text(
                          'Version 1.0.0',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.gray),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios),
          ),
          const Spacer(),
          Text('Settings', style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildProfileSection(dynamic user) {
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
            ),
            child: user?.photoUrl != null
                ? ClipOval(
                    child: Image.network(
                      user.photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        color: AppColors.white,
                        size: 32,
                      ),
                    ),
                  )
                : const Icon(Icons.person, color: AppColors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? 'Your Name',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'you@email.com',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.gray),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showEditProfileDialog(user),
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(color: AppColors.grayDark),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.gray),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color ?? AppColors.primary),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: color),
      ),
      trailing: Icon(Icons.chevron_right, color: color ?? AppColors.gray),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 56, color: AppColors.grayLight);
  }

  void _showEditProfileDialog(dynamic user) {
    final nameController = TextEditingController(text: user?.displayName ?? '');
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  hintText: 'Enter your name',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(content: Text('Please enter a name')),
                        );
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      try {
                        final authService = ref.read(authServiceProvider);
                        await authService.updateProfile(
                          displayName: nameController.text.trim(),
                        );

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile updated!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      } finally {
                        if (dialogContext.mounted) {
                          setDialogState(() => isLoading = false);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password change link sent to your email'),
        backgroundColor: AppColors.success,
      ),
    );

    // Send password reset email
    final authService = ref.read(authServiceProvider);
    final email = authService.currentUser?.email;
    if (email != null) {
      authService.sendPasswordResetEmail(email);
    }
  }

  void _showUnpairDialog(String? coupleId) {
    if (coupleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are not currently paired')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Unpair Device?'),
        content: const Text(
          'This will disconnect you from your partner. Your messages and memories will be preserved. You can pair again with a new code.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              setState(() => _isLoading = true);

              try {
                final coupleService = ref.read(coupleServiceProvider);
                await coupleService.unpair(coupleId);

                if (mounted) {
                  context.go(Routes.pairingPath);
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Unpair',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text(
          'You will need to sign in again to access your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              setState(() => _isLoading = true);

              try {
                final authService = ref.read(authServiceProvider);
                await authService.signOut();

                if (mounted) {
                  context.go(Routes.loginPath);
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
              ),
              child: const Icon(
                Icons.favorite,
                color: AppColors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Symphonia'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Love, Your Symphony',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            const Text(
              'An intimate companion app designed for couples to stay connected through heartbeats, messages, and shared memories.',
            ),
            const SizedBox(height: 16),
            Text(
              'Version 1.0.0',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.gray),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
