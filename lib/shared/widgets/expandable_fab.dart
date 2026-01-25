import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';

/// Expandable FAB that shows options around itself
///
/// When tapped, shows options (note/event) in a radial pattern around the FAB
class ExpandableFab extends StatefulWidget {
  final VoidCallback onNotePressed;
  final VoidCallback onEventPressed;

  const ExpandableFab({
    super.key,
    required this.onNotePressed,
    required this.onEventPressed,
  });

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInBack,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _close() {
    if (_isOpen) {
      setState(() {
        _isOpen = false;
        _controller.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Scrim overlay when open
        if (_isOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              child: Container(color: Colors.transparent),
            ).animate().fadeIn(duration: 200.ms),
          ),
        // FAB and options
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Options that appear above the FAB
            _buildExpandingOptions(),
            const SizedBox(height: 16),
            // Main FAB
            _buildMainFab(),
          ],
        ),
      ],
    );
  }

  Widget _buildMainFab() {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        return FloatingActionButton(
          heroTag: 'expandable_fab',
          shape: const CircleBorder(),
          onPressed: _toggle,
          backgroundColor: _isOpen
              ? AppColors.darkCard
              : AppColors.primary.withValues(alpha: 0.8),
          elevation: _isOpen ? 8 : 4,
          child: AnimatedRotation(
            turns: _isOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 300),
            child: Icon(
              _isOpen ? Icons.close : Icons.add,
              color: AppColors.white,
              size: 28,
            ),
          ),
        );
      },
    ).animate().scale(delay: 300.ms, curve: Curves.elasticOut);
  }

  Widget _buildExpandingOptions() {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Note option
            _buildOption(
              icon: Icons.note_add_outlined,
              label: 'Note',
              color: AppColors.accent,
              delay: 0,
              onTap: () {
                _close();
                widget.onNotePressed();
              },
            ),
            const SizedBox(height: 12),
            // Event option
            _buildOption(
              icon: Icons.event,
              label: 'Event',
              color: AppColors.primary,
              delay: 50,
              onTap: () {
                _close();
                widget.onEventPressed();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    required Color color,
    required int delay,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        final scale = _expandAnimation.value.roundToDouble();
        final opacity = _expandAnimation.value.roundToDouble();

        if (scale == 0) return const SizedBox.shrink();

        return Transform.scale(
          scale: scale,
          alignment: Alignment.centerRight,
          child: Opacity(
            opacity: opacity,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Label
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Icon button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [color.withValues(alpha: 0.8), color],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: AppColors.white, size: 24),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
