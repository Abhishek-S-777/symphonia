import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../shared/widgets/animated_gradient_background.dart';
import '../../domain/entities/memory.dart';

/// Gallery screen showing photo timeline
class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  // Sample memories for demo
  final List<Memory> _memories = [
    Memory(
      id: '1',
      creatorId: 'me',
      imageUrls: ['https://picsum.photos/400/600?random=1'],
      localPaths: const [],
      note: 'Our first date 💕',
      date: DateTime.now().subtract(const Duration(days: 365)),
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      isSynced: true,
    ),
    Memory(
      id: '2',
      creatorId: 'partner',
      imageUrls: ['https://picsum.photos/400/400?random=2'],
      localPaths: const [],
      note: 'Beautiful sunset together',
      date: DateTime.now().subtract(const Duration(days: 200)),
      createdAt: DateTime.now().subtract(const Duration(days: 200)),
      isSynced: true,
    ),
    Memory(
      id: '3',
      creatorId: 'me',
      imageUrls: [
        'https://picsum.photos/400/500?random=3',
        'https://picsum.photos/400/500?random=4',
      ],
      localPaths: const [],
      note: 'Anniversary celebration 🎉',
      date: DateTime.now().subtract(const Duration(days: 100)),
      createdAt: DateTime.now().subtract(const Duration(days: 100)),
      isSynced: true,
    ),
    Memory(
      id: '4',
      creatorId: 'partner',
      imageUrls: ['https://picsum.photos/400/600?random=5'],
      localPaths: const [],
      date: DateTime.now().subtract(const Duration(days: 30)),
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      isSynced: true,
    ),
    Memory(
      id: '5',
      creatorId: 'me',
      imageUrls: ['https://picsum.photos/400/400?random=6'],
      localPaths: const [],
      note: 'Lazy Sunday morning ☕',
      date: DateTime.now().subtract(const Duration(days: 7)),
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      isSynced: true,
    ),
    Memory(
      id: '6',
      creatorId: 'partner',
      imageUrls: ['https://picsum.photos/400/500?random=7'],
      localPaths: const [],
      note: 'Missing you today 💭',
      date: DateTime.now().subtract(const Duration(days: 1)),
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isSynced: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              _buildAppBar(),

              // Timeline header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      '${_memories.length} Memories',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.grayDark,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        // Toggle view mode
                      },
                      icon: const Icon(Icons.grid_view_rounded),
                      color: AppColors.gray,
                    ),
                  ],
                ),
              ),

              // Gallery grid
              Expanded(child: _buildGalleryGrid()),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.addMemoryPath),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_photo_alternate, color: AppColors.white),
      ).animate().scale(delay: 500.ms, curve: Curves.elasticOut),
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
          Text('Our Gallery', style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          IconButton(
            onPressed: () {
              // Start slideshow
              context.push(Routes.slideshowPath, extra: 0);
            },
            icon: const Icon(Icons.play_circle_outline),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: _memories.length,
      itemBuilder: (context, index) {
        final memory = _memories[index];
        return _buildMemoryCard(memory, index);
      },
    );
  }

  Widget _buildMemoryCard(Memory memory, int index) {
    return GestureDetector(
          onTap: () {
            // Open full view
            context.push(Routes.slideshowPath, extra: index);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.charcoal.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  Image.network(
                    memory.imageUrls.first,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: AppColors.grayLight,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.grayLight,
                        child: const Icon(
                          Icons.image_not_supported,
                          color: AppColors.gray,
                        ),
                      );
                    },
                  ),

                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.charcoal.withValues(alpha: 0.7),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),

                  // Multiple images indicator
                  if (memory.hasMultipleImages)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.charcoal.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.photo_library,
                              color: AppColors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${memory.imageCount}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.white),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Note and date
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (memory.hasNote)
                          Text(
                            memory.note!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(memory.date),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.white.withValues(alpha: 0.7),
                                fontSize: 10,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn()
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0));
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
