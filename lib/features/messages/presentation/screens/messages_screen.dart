import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/message_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../shared/widgets/animated_gradient_background.dart';
import '../../domain/entities/message.dart';

/// Messages screen showing conversation with partner
class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  bool _hasScrolledToUnread = false;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  Future<void> _markMessagesAsRead() async {
    // Small delay to ensure the screen is fully loaded
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      final messageService = ref.read(messageServiceProvider);
      await messageService.markAllAsRead();
    } catch (e) {
      // Ignore errors when marking as read
    }
  }

  void _scrollToFirstUnread(List<Message> messages, String currentUserId) {
    if (_hasScrolledToUnread) return;
    _hasScrolledToUnread = true;

    // Messages are ordered newest first (reverse: true in ListView)
    // Find first unread message from partner (searching from oldest to newest)
    int firstUnreadIndex = -1;
    for (int i = messages.length - 1; i >= 0; i--) {
      final message = messages[i];
      if (message.senderId != currentUserId && message.readAt == null) {
        firstUnreadIndex = i;
        break;
      }
    }

    // If no unread, stay at bottom (default with reverse: true)
    if (firstUnreadIndex == -1) return;

    // With reverse: true, index 0 is at bottom
    // Scroll to show the first unread message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // Estimate position (each message ~80px height)
        final estimatedOffset = firstUnreadIndex * 80.0;
        _scrollController.animateTo(
          estimatedOffset.clamp(0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(
    String content, {
    MessageType type = MessageType.text,
  }) async {
    if (content.trim().isEmpty) return;

    setState(() => _isSending = true);

    try {
      final messageService = ref.read(messageServiceProvider);
      await messageService.sendMessage(content: content.trim(), type: type);
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesStreamProvider);
    final partner = ref.watch(partnerUserProvider).value;
    final currentUser = ref.watch(currentAppUserProvider).value;

    final isOnline = partner?.isOnline ?? false;

    final partnerName = partner?.displayName ?? 'Your Partner';

    return GradientBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // App bar
            _buildAppBar(partnerName, isOnline, partner?.photoUrl),

            // Messages list
            Expanded(
              child: messagesAsync.when(
                data: (messages) {
                  if (messages.isEmpty) {
                    return _buildEmptyState();
                  }
                  // Scroll to first unread after build
                  if (!_hasScrolledToUnread && currentUser != null) {
                    _scrollToFirstUnread(messages, currentUser.id);
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == currentUser?.id;
                      return _buildMessageBubble(message, partnerName, isMe);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.gray,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Unable to load messages',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref.refresh(messagesStreamProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Quick messages
            _buildQuickMessages(),

            // Input area
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.primarySoft,
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Messages Yet',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Send the first message to your partner!',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.grayDark),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(String partnerName, bool isOnline, String? photoUrl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white),
            ),
            child: photoUrl != null
                ? ClipOval(
                    child: Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        color: AppColors.white,
                        size: 22,
                      ),
                    ),
                  )
                : const Icon(Icons.person, color: AppColors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partnerName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline ? AppColors.success : AppColors.gray,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isOnline ? AppColors.success : AppColors.gray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Mic icon with badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () => context.push(Routes.voiceNotesPath),
                icon: const Icon(Icons.mic_outlined),
              ),
              // Badge for unread voice notes
              Consumer(
                builder: (context, ref, _) {
                  final unreadCount = ref.watch(unreadVoiceNotesCountProvider);
                  if (unreadCount == 0) return const SizedBox.shrink();
                  return Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Center(
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, String partnerName, bool isMe) {
    final isHeartbeat = message.type == MessageType.heartbeat;

    if (isHeartbeat) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite, color: AppColors.heartRed, size: 18)
                    .animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    )
                    .scale(
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.2, 1.2),
                      duration: 600.ms,
                    ),
                const SizedBox(width: 8),
                Text(
                  isMe
                      ? 'You sent a heartbeat'
                      : '$partnerName sent you a heartbeat',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.gray),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isMe
                    ? AppGradients.messageSent.withOpacity(0.6)
                    : null,
                color: isMe
                    ? null
                    : AppColors.darkElevated.withValues(alpha: 0.7),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.charcoal.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.content,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.white),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.sentAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.gray,
                    fontSize: 11,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.readAt != null ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.readAt != null
                        ? AppColors.primary
                        : AppColors.gray,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMessages() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: AppConstants.predefinedMessages.length,
        itemBuilder: (context, index) {
          final message = AppConstants.predefinedMessages[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _sendMessage(message, type: MessageType.predefined),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.white),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                maxLength: AppConstants.messageMaxLength,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.gray),
                  border: InputBorder.none,
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
                ),
                onSubmitted: (value) => _sendMessage(value),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.messageSent.withOpacity(0.6),
              ),
              child: _isSending
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      ),
                    )
                  : IconButton(
                      onPressed: () => _sendMessage(_messageController.text),
                      icon: const Icon(Icons.send, color: AppColors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
