import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Snackbar types for consistent styling
enum SnackBarType { success, error, info, warning }

/// Custom Snackbar Helper for consistent styling across the app
///
/// Usage:
/// ```dart
/// AppSnackbar.show(context, message: 'Success!', type: SnackBarType.success);
/// AppSnackbar.showSuccess(context, 'Profile updated!');
/// AppSnackbar.showError(context, 'Something went wrong');
/// ```
class AppSnackbar {
  AppSnackbar._();

  /// Snackbar background color - dark surface that contrasts with app background
  static const Color _backgroundColor = Color(0xFF2D2529); // darkSurface

  /// Text color - always white for visibility
  static const Color _textColor = AppColors.white;

  /// Icon color - always white
  static const Color _iconColor = AppColors.white;

  /// Show a styled snackbar
  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(_getIcon(type), color: _iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: _backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: duration,
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: AppColors.primary,
              onPressed: onAction ?? () {},
            )
          : null,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Show success snackbar
  static void showSuccess(BuildContext context, String message) {
    show(context, message: message, type: SnackBarType.success);
  }

  /// Show error snackbar
  static void showError(BuildContext context, String message) {
    show(context, message: message, type: SnackBarType.error);
  }

  /// Show info snackbar
  static void showInfo(BuildContext context, String message) {
    show(context, message: message, type: SnackBarType.info);
  }

  /// Show warning snackbar
  static void showWarning(BuildContext context, String message) {
    show(context, message: message, type: SnackBarType.warning);
  }

  /// Get icon for snackbar type
  static IconData _getIcon(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return Icons.check_circle_outline;
      case SnackBarType.error:
        return Icons.error_outline;
      case SnackBarType.info:
        return Icons.info_outline;
      case SnackBarType.warning:
        return Icons.warning_amber_outlined;
    }
  }
}
