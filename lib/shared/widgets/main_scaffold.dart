import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:symphonia/shared/widgets/animated_gradient_background.dart';

import '../../../core/services/message_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/router/routes.dart';

/// Main scaffold with persistent bottom navigation bar
class MainScaffold extends ConsumerStatefulWidget {
  final Widget child;
  final String currentPath;

  const MainScaffold({
    super.key,
    required this.child,
    required this.currentPath,
  });

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _getSelectedIndex() {
    if (widget.currentPath.startsWith(Routes.homePath)) return 0;
    if (widget.currentPath.startsWith(Routes.messagesPath)) return 1;
    if (widget.currentPath.startsWith(Routes.galleryPath)) return 2;
    if (widget.currentPath.startsWith(Routes.eventsPath)) return 3;
    return 0;
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        context.go(Routes.homePath);
        break;
      case 1:
        context.go(Routes.messagesPath);
        break;
      case 2:
        context.go(Routes.galleryPath);
        break;
      case 3:
        context.go(Routes.eventsPath);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex();
    final unreadCount = ref.watch(unreadMessagesCountProvider).value ?? 0;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: widget.child,
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_outlined,
                  index: 0,
                  isSelected: selectedIndex == 0,
                ),
                _buildNavItem(
                  icon: Icons.chat,
                  activeIcon: Icons.chat,
                  index: 1,
                  isSelected: selectedIndex == 1,
                  badge: unreadCount,
                ),
                // _buildNavItem(
                //   icon: Icons.photo_library_outlined,
                //   activeIcon: Icons.photo_library_rounded,
                //   index: 2,
                //   isSelected: selectedIndex == 2,
                // ),
                _buildNavItem(
                  icon: Icons.event_outlined,
                  activeIcon: Icons.event_rounded,
                  index: 3,
                  isSelected: selectedIndex == 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required int index,
    required bool isSelected,
    String? label,
    int badge = 0,
  }) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    key: ValueKey(isSelected),
                    color: isSelected ? AppColors.white : AppColors.grayDark,
                    size: isSelected ? 26 : 24,
                  ),
                ),
                if (badge > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: AppGradients.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        badge > 9 ? '9+' : badge.toString(),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            if (label != null) const SizedBox(height: 4),
            if (label != null)
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: isSelected ? 12 : 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppColors.white : AppColors.grayDark,
                ),
                child: Text(label),
              ),
          ],
        ),
      ),
    );
  }
}
