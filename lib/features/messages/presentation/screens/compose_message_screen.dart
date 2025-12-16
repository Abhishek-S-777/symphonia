import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/animated_gradient_background.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Screen to compose a new message
class ComposeMessageScreen extends ConsumerStatefulWidget {
  const ComposeMessageScreen({super.key});

  @override
  ConsumerState<ComposeMessageScreen> createState() =>
      _ComposeMessageScreenState();
}

class _ComposeMessageScreenState extends ConsumerState<ComposeMessageScreen> {
  final _messageController = TextEditingController();
  bool _isScheduled = false;
  DateTime? _scheduledTime;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
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
                      'New Message',
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
                      // Message input
                      GlassCard(
                        padding: EdgeInsets.zero,
                        child: TextField(
                          controller: _messageController,
                          maxLines: 6,
                          maxLength: 500,
                          decoration: InputDecoration(
                            hintText: 'Write something sweet...',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                            counterStyle: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.gray),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Schedule option
                      GlassCard(
                        onTap: () {
                          setState(() {
                            _isScheduled = !_isScheduled;
                          });
                        },
                        child: Row(
                          children: [
                            Icon(
                              _isScheduled
                                  ? Icons.schedule
                                  : Icons.schedule_outlined,
                              color: _isScheduled
                                  ? AppColors.primary
                                  : AppColors.gray,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _isScheduled
                                    ? 'Scheduled message'
                                    : 'Schedule for later',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            Switch(
                              value: _isScheduled,
                              onChanged: (value) {
                                setState(() {
                                  _isScheduled = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      if (_isScheduled) ...[
                        const SizedBox(height: 16),
                        GlassCard(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (date != null && mounted) {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (time != null) {
                                setState(() {
                                  _scheduledTime = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    time.hour,
                                    time.minute,
                                  );
                                });
                              }
                            }
                          },
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _scheduledTime != null
                                    ? _formatDateTime(_scheduledTime!)
                                    : 'Select date and time',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Send button
              Padding(
                padding: const EdgeInsets.all(24),
                child: PrimaryButton(
                  text: _isScheduled ? 'Schedule Message' : 'Send Now',
                  icon: _isScheduled ? Icons.schedule : Icons.send,
                  onPressed: () {
                    // TODO: Send or schedule message
                    context.pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
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
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at $hour:${dt.minute.toString().padLeft(2, '0')} $period';
  }
}
