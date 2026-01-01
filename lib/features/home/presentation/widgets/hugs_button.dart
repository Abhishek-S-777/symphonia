import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:symphonia/core/theme/app_colors.dart';

/// Hugs & Kisses Button - Amber themed, long press to build up hugs duration
/// Vibration pattern: long vibrations + short kiss at the end
class HugsButton extends ConsumerStatefulWidget {
  final Function(int seconds)? onHugsSent;
  final double size;

  const HugsButton({super.key, this.onHugsSent, this.size = 180});

  @override
  ConsumerState<HugsButton> createState() => _HugsButtonState();
}

class _HugsButtonState extends ConsumerState<HugsButton>
    with TickerProviderStateMixin {
  late AnimationController _idlePulseController;
  late AnimationController _buildUpController;
  late AnimationController _releaseController;
  late AnimationController _particleSpinController;

  late Animation<double> _idlePulseAnimation;
  late Animation<double> _glowAnimation;

  bool _isHolding = false;
  bool _isReleasing = false;
  int _hugSeconds = 0;
  Timer? _hugTimer;

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

    // Build up animation (grows as user holds)
    _buildUpController = AnimationController(
      duration: const Duration(seconds: 10), // Max 10 seconds
      vsync: this,
    );

    // Release celebration animation
    _releaseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Particle spin animation - keeps particles moving continuously
    _particleSpinController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Start idle pulse
    _idlePulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _idlePulseController.dispose();
    _buildUpController.dispose();
    _releaseController.dispose();
    _particleSpinController.dispose();
    _hugTimer?.cancel();
    super.dispose();
  }

  void _startHolding() {
    if (_isHolding || _isReleasing) return;

    setState(() {
      _isHolding = true;
      _hugSeconds = 0;
    });

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Stop idle pulse
    _idlePulseController.stop();

    // Start build up animation
    _buildUpController.forward(from: 0);

    // Start particle spin animation (continuous)
    _particleSpinController.repeat();

    // Start timer to count seconds
    _hugTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isHolding) {
        setState(() {
          _hugSeconds++;
        });
        // Periodic haptic feedback
        HapticFeedback.lightImpact();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _stopHolding() async {
    if (!_isHolding) return;

    _hugTimer?.cancel();
    _buildUpController.stop();
    _particleSpinController.stop();

    final seconds = _hugSeconds;

    setState(() {
      _isHolding = false;
      _isReleasing = true;
    });

    if (seconds >= 1) {
      // Play release vibration pattern: long vibrations + short kiss
      await _playReleaseVibration(seconds);

      // Trigger callback
      widget.onHugsSent?.call(seconds);
    }

    // Play release animation
    await _releaseController.forward(from: 0);

    if (mounted) {
      setState(() {
        _isReleasing = false;
        _hugSeconds = 0;
      });

      // Resume idle pulse
      _idlePulseController.repeat(reverse: true);
    }
  }

  /// Vibration pattern: long vibrations based on seconds + final short "kiss"
  Future<void> _playReleaseVibration(int seconds) async {
    // Long vibrations (proportional to seconds held, max 3)
    final longVibs = math.min(seconds, 3);

    for (int i = 0; i < longVibs; i++) {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // Short pause
    await Future.delayed(const Duration(milliseconds: 100));

    // Final short "kiss" vibration
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onLongPressStart: (_) => _startHolding(),
        onLongPressEnd: (_) => _stopHolding(),
        onLongPressCancel: () {
          _hugTimer?.cancel();
          if (_isHolding) {
            setState(() {
              _isHolding = false;
              _hugSeconds = 0;
            });
            _buildUpController.stop();
            _particleSpinController.stop();
            _idlePulseController.repeat(reverse: true);
          }
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _idlePulseController,
            _buildUpController,
            _releaseController,
            _particleSpinController,
          ]),
          builder: (context, child) {
            double scale;
            double glowOpacity;

            if (_isHolding) {
              // Growing scale as user holds
              final buildUp = _buildUpController.value;
              scale = 1.0 + (buildUp * 0.3); // Grows up to 1.3x
              glowOpacity = 0.4 + (buildUp * 0.4); // Glow intensifies
            } else if (_isReleasing) {
              // Release celebration - quick pulse
              final release = _releaseController.value;
              final releaseCurve = Curves.elasticOut.transform(release);
              scale = 1.3 - (0.3 * releaseCurve);
              glowOpacity = 0.8 - (0.5 * release);
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
                  // Outer glow rings
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
                            color: AppColors.hugAmber.withValues(
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
                            AppColors.hugAmberGlow.withValues(
                              alpha: glowOpacity * 0.8,
                            ),
                            AppColors.hugAmberGlow.withValues(
                              alpha: glowOpacity * 0.3,
                            ),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Main button
                  Transform.scale(
                    scale: scale,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.hugAmber.withValues(alpha: 0.5),
                            blurRadius: 25 * scale,
                            spreadRadius: 3,
                          ),
                          BoxShadow(
                            color: AppColors.hugAmberDark.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 50 * scale,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Center(
                              child: Image.asset(
                                'assets/icons/app-icon-light-transparent.png',
                                width: widget.size * 0.5,
                                height: widget.size * 0.5,
                                fit: BoxFit.contain,
                              ),
                            ),
                            if (_isHolding && _hugSeconds > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${_hugSeconds}s',
                                style: TextStyle(
                                  fontSize: widget.size * 0.12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Build up particles during hold
                  if (_isHolding)
                    ...List.generate(8, (index) {
                      final angle = index * (math.pi * 2 / 8);
                      final buildUp = _buildUpController.value;
                      final spin =
                          _particleSpinController.value; // 0-1 continuous
                      final distance =
                          widget.size *
                          0.4 *
                          (1 + math.min(buildUp, 0.8) * 0.3);
                      final particleOpacity =
                          0.3 + math.min(buildUp, 0.8) * 0.5;
                      // Use spin for continuous rotation (full circle = 2*pi)
                      final rotation = spin * math.pi * 2;

                      return Positioned(
                        left:
                            widget.size * 0.75 +
                            distance * math.cos(angle + rotation) -
                            5,
                        top:
                            widget.size * 0.75 +
                            distance * math.sin(angle + rotation) -
                            5,
                        child: Opacity(
                          opacity: particleOpacity,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.hugAmberGlow,
                                  AppColors.hugAmberGlow.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                  // Release sparkles
                  if (_isReleasing && _releaseController.value < 0.8)
                    ...List.generate(12, (index) {
                      final angle = index * (math.pi * 2 / 12);
                      final progress = _releaseController.value;
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
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.hugAmberGlow,
                                  AppColors.hugAmberGlow.withValues(alpha: 0),
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
