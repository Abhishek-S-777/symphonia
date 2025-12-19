import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';

/// The signature Big Heart Button - Central CTA
/// Plays heartbeat vibration with beautiful lub-dub animations
class HeartButton extends ConsumerStatefulWidget {
  final VoidCallback? onPressed;
  final double size;

  const HeartButton({super.key, this.onPressed, this.size = 180});

  @override
  ConsumerState<HeartButton> createState() => _HeartButtonState();
}

class _HeartButtonState extends ConsumerState<HeartButton>
    with TickerProviderStateMixin {
  late AnimationController _idlePulseController;
  late AnimationController _heartbeatController;

  late Animation<double> _idlePulseAnimation;
  late Animation<double> _glowAnimation;

  bool _isBeating = false;

  @override
  void initState() {
    super.initState();

    // Gentle idle pulse animation
    _idlePulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _idlePulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _idlePulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.5).animate(
      CurvedAnimation(parent: _idlePulseController, curve: Curves.easeInOut),
    );

    // Heartbeat animation controller (for lub-dub effect)
    _heartbeatController = AnimationController(
      duration: const Duration(milliseconds: 2700), // 3 beats × 900ms each
      vsync: this,
    );

    // Start idle pulse
    _idlePulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _idlePulseController.dispose();
    _heartbeatController.dispose();
    super.dispose();
  }

  /// Calculate lub-dub scale for a given animation value
  /// Creates realistic heartbeat: quick expand (lub), quick contract (dub), pause
  double _getHeartbeatScale(double t) {
    // Each beat takes ~0.333 of the total animation (3 beats)
    final beatProgress = (t * 3) % 1.0;

    if (beatProgress < 0.15) {
      // LUB - quick expansion
      final lubProgress = beatProgress / 0.15;
      return 1.0 + 0.25 * Curves.easeOut.transform(lubProgress);
    } else if (beatProgress < 0.30) {
      // Brief pause at peak
      return 1.25;
    } else if (beatProgress < 0.45) {
      // DUB - quick contraction (smaller bounce)
      final dubProgress = (beatProgress - 0.30) / 0.15;
      return 1.25 - 0.15 * Curves.easeIn.transform(dubProgress);
    } else if (beatProgress < 0.55) {
      // Small secondary expansion
      final bounceProgress = (beatProgress - 0.45) / 0.10;
      return 1.10 + 0.08 * Curves.easeOut.transform(bounceProgress);
    } else if (beatProgress < 0.70) {
      // Return to normal
      final returnProgress = (beatProgress - 0.55) / 0.15;
      return 1.18 - 0.18 * Curves.easeInOut.transform(returnProgress);
    } else {
      // Rest period between beats
      return 1.0;
    }
  }

  Future<void> _handlePress() async {
    if (_isBeating) return; // Prevent multiple taps during animation

    setState(() {
      _isBeating = true;
    });

    // Light haptic feedback for tap
    HapticFeedback.lightImpact();

    // Stop idle pulse and play heartbeat
    _idlePulseController.stop();

    // Play the heartbeat animation (3 beats)
    _heartbeatController.forward(from: 0);

    // Trigger callback
    widget.onPressed?.call();

    // Wait for animation to complete
    await _heartbeatController.forward(from: 0);

    if (mounted) {
      setState(() {
        _isBeating = false;
      });
      // Resume idle pulse
      _idlePulseController.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handlePress,
        splashColor: Colors.transparent, // Remove splash
        highlightColor: Colors.transparent, // Remove highlight box
        hoverColor: Colors.transparent,
        borderRadius: BorderRadius.circular(widget.size),
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _idlePulseController,
            _heartbeatController,
          ]),
          builder: (context, child) {
            // Calculate scale based on which animation is active
            double scale;
            double glowOpacity;

            if (_isBeating) {
              scale = _getHeartbeatScale(_heartbeatController.value);
              glowOpacity =
                  0.4 + 0.3 * (scale - 1.0); // Glow intensifies with scale
            } else {
              scale = _idlePulseAnimation.value;
              glowOpacity = _glowAnimation.value;
            }

            return SizedBox(
              width: widget.size * 1.5,
              height: widget.size * 1.5,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow rings (pulse with heartbeat)
                  ...List.generate(3, (index) {
                    final ringScale = 1.0 + (index + 1) * 0.12;
                    final ringOpacity = glowOpacity * (1 - index * 0.25);

                    return Transform.scale(
                      scale: scale * ringScale,
                      child: Container(
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.heartRed.withValues(
                              alpha: ringOpacity * 0.4,
                            ),
                            width: 2 - index * 0.5,
                          ),
                        ),
                      ),
                    );
                  }),

                  // Soft glow effect
                  Transform.scale(
                    scale: scale,
                    child: Container(
                      width: widget.size * 1.2,
                      height: widget.size * 1.2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.heartGlow.withValues(
                              alpha: glowOpacity * 0.8,
                            ),
                            AppColors.heartGlow.withValues(
                              alpha: glowOpacity * 0.3,
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
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.heartRed.withValues(alpha: 0.5),
                            blurRadius: 25 * scale,
                            spreadRadius: 3,
                          ),
                          BoxShadow(
                            color: AppColors.heartRed.withValues(alpha: 0.3),
                            blurRadius: 50 * scale,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/icons/app-icon-light-transparent.png',
                          width: widget.size * 0.5,
                          height: widget.size * 0.5,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  // Sparkle effects during heartbeat
                  if (_isBeating && _heartbeatController.value > 0.05)
                    ...List.generate(6, (index) {
                      final angle = index * (math.pi * 2 / 6) + (math.pi / 6);
                      final progress = _heartbeatController.value;
                      final distance = widget.size * 0.7 * progress;
                      final sparkleOpacity = (1 - progress).clamp(0.0, 1.0);

                      return Positioned(
                        left:
                            widget.size * 0.75 + distance * math.cos(angle) - 5,
                        top:
                            widget.size * 0.75 + distance * math.sin(angle) - 5,
                        child: Opacity(
                          opacity: sparkleOpacity * 0.8,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.heartGlow,
                                  AppColors.heartGlow.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        ),
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
