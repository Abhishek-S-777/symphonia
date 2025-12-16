import 'package:flutter/material.dart';
import 'dart:ui';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';

/// A beautiful glassmorphism card widget
/// Used throughout the app for a premium, elegant feel
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadows;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.blur = 10,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1,
    this.onTap,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                color:
                    backgroundColor ??
                    (isDark
                        ? AppColors.darkCard.withValues(alpha: 0.7)
                        : AppColors.white.withValues(alpha: 0.8)),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color:
                      borderColor ??
                      (isDark
                          ? AppColors.white.withValues(alpha: 0.1)
                          : AppColors.white.withValues(alpha: 0.5)),
                  width: borderWidth,
                ),
                boxShadow:
                    shadows ??
                    [
                      BoxShadow(
                        color: AppColors.charcoal.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                gradient: AppGradients.glassOverlay,
              ),
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Glass card with gradient border
class GradientGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Gradient? borderGradient;
  final double borderWidth;
  final VoidCallback? onTap;

  const GradientGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.blur = 10,
    this.borderGradient,
    this.borderWidth = 2,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: borderGradient ?? AppGradients.primary,
          ),
          padding: EdgeInsets.all(borderWidth),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius - borderWidth),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCard.withValues(alpha: 0.9)
                      : AppColors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(
                    borderRadius - borderWidth,
                  ),
                ),
                padding: padding ?? const EdgeInsets.all(16),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
