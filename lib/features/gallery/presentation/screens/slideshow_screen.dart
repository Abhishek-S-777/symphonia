import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';

/// Full-screen slideshow viewer for memories
class SlideshowScreen extends ConsumerStatefulWidget {
  final int startIndex;

  const SlideshowScreen({super.key, this.startIndex = 0});

  @override
  ConsumerState<SlideshowScreen> createState() => _SlideshowScreenState();
}

class _SlideshowScreenState extends ConsumerState<SlideshowScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _showControls = true;

  // Sample images
  final List<SlideshowItem> _items = [
    SlideshowItem(
      imageUrl: 'https://picsum.photos/800/1200?random=1',
      note: 'Our first date 💕',
      date: DateTime.now().subtract(const Duration(days: 365)),
    ),
    SlideshowItem(
      imageUrl: 'https://picsum.photos/800/1200?random=2',
      note: 'Beautiful sunset together',
      date: DateTime.now().subtract(const Duration(days: 200)),
    ),
    SlideshowItem(
      imageUrl: 'https://picsum.photos/800/1200?random=3',
      note: 'Anniversary celebration 🎉',
      date: DateTime.now().subtract(const Duration(days: 100)),
    ),
    SlideshowItem(
      imageUrl: 'https://picsum.photos/800/1200?random=4',
      date: DateTime.now().subtract(const Duration(days: 30)),
    ),
    SlideshowItem(
      imageUrl: 'https://picsum.photos/800/1200?random=5',
      note: 'Lazy Sunday morning ☕',
      date: DateTime.now().subtract(const Duration(days: 7)),
    ),
    SlideshowItem(
      imageUrl: 'https://picsum.photos/800/1200?random=6',
      note: 'Missing you today 💭',
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startIndex;
    _pageController = PageController(initialPage: widget.startIndex);

    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Image pageview
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: _items.length,
              itemBuilder: (context, index) {
                return _buildSlide(_items[index]);
              },
            ),

            // Top controls
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.close, color: AppColors.white),
                        ),
                        const Spacer(),
                        Text(
                          '${_currentIndex + 1} / ${_items.length}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppColors.white),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            // TODO: Share or download
                          },
                          icon: const Icon(Icons.share, color: AppColors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom info
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppColors.black.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_items[_currentIndex].note != null)
                            Text(
                              _items[_currentIndex].note!,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(color: AppColors.white),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            _formatDate(_items[_currentIndex].date),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.white.withValues(alpha: 0.7),
                                ),
                          ),
                          const SizedBox(height: 16),
                          // Page indicators
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _items.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                width: index == _currentIndex ? 20 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  color: index == _currentIndex
                                      ? AppColors.white
                                      : AppColors.white.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(SlideshowItem item) {
    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 3.0,
      child: Center(
        child: Image.network(
          item.imageUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
                color: AppColors.primary,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(Icons.broken_image, color: AppColors.gray, size: 64),
            );
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

/// Data class for slideshow items
class SlideshowItem {
  final String imageUrl;
  final String? note;
  final DateTime date;

  const SlideshowItem({required this.imageUrl, this.note, required this.date});
}
