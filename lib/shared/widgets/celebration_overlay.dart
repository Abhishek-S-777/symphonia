import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

/// A celebration overlay with confetti and animated text
/// Shows when user taps on "days together"
class CelebrationOverlay extends StatefulWidget {
  final String daysTogetherFormatted;
  final VoidCallback onDismiss;

  const CelebrationOverlay({
    super.key,
    required this.daysTogetherFormatted,
    required this.onDismiss,
  });

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    // Start confetti immediately
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.85),
                AppColors.black.withValues(alpha: 1),
                Colors.black.withValues(alpha: 0.85),
              ],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Confetti from top center
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: pi / 2, // downward
                  maxBlastForce: 5,
                  minBlastForce: 2,
                  emissionFrequency: 0.05,
                  numberOfParticles: 20,
                  gravity: 0.1,
                  shouldLoop: false,
                  colors: const [
                    AppColors.primary,
                    AppColors.primaryLight,
                    AppColors.secondary,
                    AppColors.accent,
                    AppColors.heartRed,
                    AppColors.heartGlow,
                    Colors.white,
                  ],
                ),
              ),

              // Confetti from left
              Align(
                alignment: Alignment.centerLeft,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: 0, // right
                  maxBlastForce: 15,
                  minBlastForce: 8,
                  emissionFrequency: 0.08,
                  numberOfParticles: 10,
                  gravity: 0.2,
                  shouldLoop: false,
                  colors: const [
                    AppColors.primary,
                    AppColors.accent,
                    AppColors.secondary,
                  ],
                ),
              ),

              // Confetti from right
              Align(
                alignment: Alignment.centerRight,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: pi, // left
                  maxBlastForce: 15,
                  minBlastForce: 8,
                  emissionFrequency: 0.08,
                  numberOfParticles: 10,
                  gravity: 0.2,
                  shouldLoop: false,
                  colors: const [
                    AppColors.primary,
                    AppColors.accent,
                    AppColors.secondary,
                  ],
                ),
              ),

              // Main celebration content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Days together
                  Row(
                        mainAxisSize: MainAxisSize.min,

                        children: [
                          Text(
                            '${widget.daysTogetherFormatted} of pure love',
                            style: GoogleFonts.fleurDeLeah(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                          const Text(' 💕', style: TextStyle(fontSize: 28)),
                        ],
                      )
                      .animate(delay: 600.ms)
                      .fadeIn(duration: 400.ms)
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1, 1),
                        curve: Curves.easeOutBack,
                      ),
                  // Cheers message
                  Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🥂', style: TextStyle(fontSize: 28)),
                          const SizedBox(width: 8),
                          Text(
                            'Cheers to us!',
                            style: GoogleFonts.fleurDeLeah(
                              fontSize: 32,
                              fontWeight: FontWeight.normal,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(' 🎉', style: TextStyle(fontSize: 28)),
                        ],
                      )
                      .animate(delay: 600.ms)
                      .fadeIn(duration: 400.ms)
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1, 1),
                        curve: Curves.easeOutBack,
                      ),

                  const SizedBox(height: 24),

                  Text(
                        'Tap anywhere to close!',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.normal,
                          color: AppColors.gray,
                        ),
                      )
                      .animate(delay: 600.ms)
                      .fadeIn(duration: 400.ms)
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1, 1),
                        curve: Curves.easeOutBack,
                      ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the celebration overlay
void showCelebration(BuildContext context, String daysTogetherFormatted) {
  // Light haptic feedback for tap
  HapticFeedback.lightImpact();
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Celebration',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return CelebrationOverlay(
        daysTogetherFormatted: daysTogetherFormatted,
        onDismiss: () => Navigator.of(dialogContext).pop(),
      );
    },
  );
}
