import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
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
  final _messageFocusNode = FocusNode();
  bool _isScheduled = false;
  DateTime? _scheduledTime;
  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    _messageFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_messageFocusNode.hasFocus && _showEmojiPicker) {
      setState(() => _showEmojiPicker = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.removeListener(_onFocusChange);
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _toggleEmojiPicker() {
    if (_showEmojiPicker) {
      // Hide emoji picker, show keyboard
      setState(() => _showEmojiPicker = false);
      _messageFocusNode.requestFocus();
    } else {
      // Hide keyboard, show emoji picker
      _messageFocusNode.unfocus();
      setState(() => _showEmojiPicker = true);
    }
  }

  void _onEmojiSelected(Category? category, Emoji emoji) {
    final text = _messageController.text;
    final selection = _messageController.selection;
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      emoji.emoji,
    );
    final newOffset = selection.start + emoji.emoji.length;

    _messageController.text = newText;
    _messageController.selection = TextSelection.collapsed(offset: newOffset);
  }

  void _onBackspacePressed() {
    final text = _messageController.text;
    final selection = _messageController.selection;

    if (text.isNotEmpty && selection.start > 0) {
      final newText = text.replaceRange(
        selection.start - 1,
        selection.start,
        '',
      );
      _messageController.text = newText;
      _messageController.selection = TextSelection.collapsed(
        offset: selection.start - 1,
      );
    }
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
                      // Message input with emoji button on the left (WhatsApp style)
                      GlassCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Emoji toggle button (left side like WhatsApp)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: IconButton(
                                onPressed: _toggleEmojiPicker,
                                icon: Icon(
                                  _showEmojiPicker
                                      ? Icons.keyboard_alt_outlined
                                      : Icons.emoji_emotions_outlined,
                                  color: _showEmojiPicker
                                      ? AppColors.primary
                                      : AppColors.gray,
                                  size: 26,
                                ),
                                tooltip: _showEmojiPicker
                                    ? 'Show keyboard'
                                    : 'Show emojis',
                              ),
                            ),
                            // Text field (expanded)
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                focusNode: _messageFocusNode,
                                maxLines: 6,
                                maxLength: 500,
                                decoration: InputDecoration(
                                  hintText: 'Write something sweet...',
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 12,
                                  ),
                                  counterStyle: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppColors.gray),
                                ),
                              ),
                            ),
                          ],
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: PrimaryButton(
                  text: _isScheduled ? 'Schedule Message' : 'Send Now',
                  icon: _isScheduled ? Icons.schedule : Icons.send,
                  onPressed: () {
                    // TODO: Send or schedule message
                    context.pop();
                  },
                ),
              ),

              // Emoji Picker (WhatsApp style - appears from bottom)
              if (_showEmojiPicker)
                SizedBox(
                  height: 280,
                  child: EmojiPicker(
                    onEmojiSelected: _onEmojiSelected,
                    onBackspacePressed: _onBackspacePressed,
                    textEditingController: _messageController,
                    config: Config(
                      height: 280,
                      checkPlatformCompatibility: true,
                      emojiViewConfig: EmojiViewConfig(
                        emojiSizeMax:
                            28 *
                            (foundation.defaultTargetPlatform ==
                                    TargetPlatform.iOS
                                ? 1.20
                                : 1.0),
                        backgroundColor: AppColors.darkCard,
                        columns: 8,
                        verticalSpacing: 0,
                        horizontalSpacing: 0,
                      ),
                      viewOrderConfig: const ViewOrderConfig(
                        top: EmojiPickerItem.categoryBar,
                        middle: EmojiPickerItem.emojiView,
                        bottom: EmojiPickerItem.searchBar,
                      ),
                      skinToneConfig: const SkinToneConfig(),
                      categoryViewConfig: CategoryViewConfig(
                        backgroundColor: AppColors.darkCard,
                        indicatorColor: AppColors.primary,
                        iconColor: AppColors.gray,
                        iconColorSelected: AppColors.primary,
                        tabIndicatorAnimDuration: kTabScrollDuration,
                        dividerColor: AppColors.gray.withValues(alpha: 0.2),
                        customCategoryView:
                            (config, state, tabController, pageController) {
                              return DefaultCategoryView(
                                config,
                                state,
                                tabController,
                                pageController,
                              );
                            },
                        categoryIcons: const CategoryIcons(),
                      ),
                      bottomActionBarConfig: BottomActionBarConfig(
                        backgroundColor: AppColors.darkCard,
                        buttonIconColor: AppColors.white,
                        showBackspaceButton: true,
                        showSearchViewButton: true,
                      ),
                      searchViewConfig: SearchViewConfig(
                        backgroundColor: AppColors.darkCard,
                        buttonIconColor: AppColors.white,
                        hintText: 'Search emoji...',
                      ),
                    ),
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
