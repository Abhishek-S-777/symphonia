import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/animated_gradient_background.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Screen to add a new memory to the gallery
class AddMemoryScreen extends ConsumerStatefulWidget {
  const AddMemoryScreen({super.key});

  @override
  ConsumerState<AddMemoryScreen> createState() => _AddMemoryScreenState();
}

class _AddMemoryScreenState extends ConsumerState<AddMemoryScreen> {
  final _noteController = TextEditingController();
  final List<String> _selectedImages = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    // TODO: Implement image picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image picker will be implemented')),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _saveMemory() {
    // TODO: Save memory
    context.pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Memory saved! 💕'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.close),
                    ),
                    const Spacer(),
                    Text(
                      'Add Memory',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image picker
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: AppColors.grayLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: _selectedImages.isEmpty
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 48,
                                      color: AppColors.primary.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Tap to add photos',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: AppColors.gray),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Up to 10 photos',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: AppColors.gray),
                                    ),
                                  ],
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: GridView.count(
                                    crossAxisCount: 3,
                                    children: _selectedImages
                                        .map(
                                          (path) => Image.asset(
                                            path,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Date picker
                      GlassCard(
                        onTap: _selectDate,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: AppColors.gray),
                                  ),
                                  Text(
                                    _formatDate(_selectedDate),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.gray,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Note input
                      GlassCard(
                        padding: EdgeInsets.zero,
                        child: TextField(
                          controller: _noteController,
                          maxLines: 4,
                          maxLength: 300,
                          decoration: InputDecoration(
                            hintText: 'Add a note about this memory...',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                            counterStyle: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.gray),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Info text
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'This memory will be shared with your partner and saved to your timeline.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Save button
              Padding(
                padding: const EdgeInsets.all(24),
                child: PrimaryButton(
                  text: 'Save Memory',
                  icon: Icons.favorite,
                  onPressed: _saveMemory,
                ),
              ),
            ],
          ),
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
