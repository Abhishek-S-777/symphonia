import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/vibration_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';

/// The signature Big Heart Button - Central CTA
/// Plays heartbeat vibration with beautiful animations
class HeartButton extends ConsumerStatefulWidget {
  final VoidCallback? onPressed;
  final double size;

  const HeartButton({super.key, this.onPressed, this.size = 180});

  @override
  ConsumerState<HeartButton> createState() => _HeartButtonState();
}

class _HeartButtonState extends ConsumerState<HeartButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _pressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _pressAnimation;
  late Animation<double> _glowAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    // Continuous pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Press animation
    _pressController = AnimationController(
      duration: AppConstants.heartAnimationDuration,
      vsync: this,
    );

    _pressAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.85,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.85,
          end: 1.15,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.15,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_pressController);

    // Start idle pulse
    _startIdlePulse();
  }

  void _startIdlePulse() {
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    setState(() {
      _isPressed = true;
    });

    // Play press animation
    _pulseController.stop();
    _pressController.forward(from: 0);

    // Play vibration
    final vibrationService = ref.read(vibrationServiceProvider);
    await vibrationService.playHeartbeat();

    // Callback
    widget.onPressed?.call();

    // Reset after animation
    await Future.delayed(AppConstants.heartAnimationDuration);

    if (mounted) {
      setState(() {
        _isPressed = false;
      });
      _startIdlePulse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handlePress,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _pressController]),
        builder: (context, child) {
          final scale = _isPressed
              ? _pressAnimation.value
              : _pulseAnimation.value;
          final glowOpacity = _glowAnimation.value;

          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow rings
              ...List.generate(3, (index) {
                final ringScale = 1.0 + (index + 1) * 0.15;
                final ringOpacity = glowOpacity * (1 - index * 0.3);

                return Transform.scale(
                  scale: scale * ringScale,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.heartRed.withValues(
                          alpha: ringOpacity * 0.3,
                        ),
                        width: 2 - index * 0.5,
                      ),
                    ),
                  ),
                );
              }),

              // Glow effect
              Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.size * 1.3,
                  height: widget.size * 1.3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.heartGlow.withValues(alpha: glowOpacity),
                        AppColors.heartGlow.withValues(
                          alpha: glowOpacity * 0.5,
                        ),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // Main heart button
              Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _isPressed
                        ? AppGradients.heartPressed
                        : AppGradients.heartNormal,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.heartRed.withValues(alpha: 0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                      BoxShadow(
                        color: AppColors.heartRed.withValues(alpha: 0.2),
                        blurRadius: 60,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.favorite,
                      size: widget.size * 0.5,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),

              // Sparkle effects on press
              if (_isPressed)
                ...List.generate(8, (index) {
                  final angle = index * (math.pi * 2 / 8);
                  final distance = widget.size * 0.8;
                  return Positioned(
                    left:
                        widget.size / 2 +
                        distance *
                            0.5 *
                            (1 + _pressAnimation.value) *
                            math.cos(angle) -
                        4,
                    top:
                        widget.size / 2 +
                        distance *
                            0.5 *
                            (1 + _pressAnimation.value) *
                            math.sin(angle) -
                        4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.heartGlow.withValues(
                          alpha: (1 - _pressAnimation.value).clamp(0.0, 1.0),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

/// Smaller heart button for quick access
class MiniHeartButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double size;

  const MiniHeartButton({super.key, this.onPressed, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
          onTap: onPressed,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.primary,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.favorite,
              size: size * 0.5,
              color: AppColors.white,
            ),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.05, 1.05),
          duration: 800.ms,
          curve: Curves.easeInOut,
        );
  }
}
