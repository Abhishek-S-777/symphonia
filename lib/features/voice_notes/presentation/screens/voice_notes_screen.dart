import 'dart:async';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/vibration_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../shared/widgets/animated_gradient_background.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/entities/voice_note.dart';

/// Voice notes screen for recording and listening to voice messages
class VoiceNotesScreen extends ConsumerStatefulWidget {
  const VoiceNotesScreen({super.key});

  @override
  ConsumerState<VoiceNotesScreen> createState() => _VoiceNotesScreenState();
}

class _VoiceNotesScreenState extends ConsumerState<VoiceNotesScreen>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  late AnimationController _pulseController;
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToUnread = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      final audioService = ref.read(audioServiceProvider);
      await audioService.startRecording();

      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });

      _pulseController.repeat(reverse: true);

      // Start timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingSeconds++;
        });

        // Auto-stop at max duration
        if (_recordingSeconds >= AppConstants.voiceNoteMaxDuration) {
          _stopRecording();
        }
      });

      // Light vibration feedback
      ref.read(vibrationServiceProvider).lightImpact();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    _pulseController.stop();
    _pulseController.reset();

    setState(() {
      _isRecording = false;
    });

    try {
      final audioService = ref.read(audioServiceProvider);
      final voiceNote = await audioService.stopRecording();

      // Confirmation vibration
      ref.read(vibrationServiceProvider).success();

      if (voiceNote != null &&
          _recordingSeconds >= AppConstants.voiceNoteMinDuration) {
        if (mounted) {
          AppSnackbar.showSuccess(
            context,
            'Voice note sent! (${_recordingSeconds}s)',
          );
        }
      } else if (_recordingSeconds < AppConstants.voiceNoteMinDuration) {
        if (mounted) {
          AppSnackbar.showInfo(context, 'Recording too short');
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, 'Failed to save recording: $e');
      }
    }
  }

  Future<void> _playVoiceNote(VoiceNote note) async {
    try {
      final audioService = ref.read(audioServiceProvider);
      final currentPlayingId = ref.read(currentlyPlayingIdProvider);

      if (currentPlayingId == note.id) {
        // Stop if already playing this note
        await audioService.stopPlaying();
      } else {
        // Play the new note (service handles stopping current playback)
        await audioService.playVoiceNote(note);
        ref.read(vibrationServiceProvider).vibrateVoiceNoteReceived();
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, 'Failed to play voice note');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final voiceNotesAsync = ref.watch(voiceNotesStreamProvider);
    final currentUser = ref.watch(currentAppUserProvider).value;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              _buildAppBar(),

              // Recording area
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Content
                    if (!_isRecording)
                      Expanded(
                        child: voiceNotesAsync.when(
                          data: (notes) {
                            if (notes.isEmpty) {
                              return _buildEmptyState();
                            }
                            return _buildVoiceNotesList(notes, currentUser?.id);
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
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
                                Text('Unable to load voice notes'),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () =>
                                      ref.invalidate(voiceNotesStreamProvider),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Recording UI
                    if (_isRecording) Expanded(child: _buildRecordingUI()),

                    // Record button
                    _buildRecordButton(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
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
                gradient: AppGradients.voiceNote,
              ),
              child: const Icon(Icons.mic, size: 48, color: AppColors.white),
            ).animate().scale(curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              'No Voice Notes Yet',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Record your first voice note to send to your partner!',
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
          Text('Voice Notes', style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildVoiceNotesList(
    List<VoiceNote> voiceNotes,
    String? currentUserId,
  ) {
    // Auto-scroll to first unread message after build
    if (!_hasScrolledToUnread &&
        voiceNotes.isNotEmpty &&
        currentUserId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToFirstUnread(voiceNotes, currentUserId);
      });
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: voiceNotes.length,
      itemBuilder: (context, index) {
        final note = voiceNotes[index];
        final isMe = note.senderId == currentUserId;

        return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildVoiceNoteItem(note, isMe),
            )
            .animate(delay: Duration(milliseconds: 100 * index))
            .fadeIn()
            .slideX(begin: isMe ? 0.1 : -0.1, end: 0);
      },
    );
  }

  void _scrollToFirstUnread(List<VoiceNote> voiceNotes, String currentUserId) {
    if (_hasScrolledToUnread) return;
    _hasScrolledToUnread = true;

    // Find first unread message (not from me and not played)
    int firstUnreadIndex = -1;
    for (int i = 0; i < voiceNotes.length; i++) {
      final note = voiceNotes[i];
      if (note.senderId != currentUserId && note.playedAt == null) {
        firstUnreadIndex = i;
        break;
      }
    }

    // If no unread, scroll to bottom (latest)
    if (firstUnreadIndex == -1) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      return;
    }

    // Scroll to first unread (approximate position based on item height ~100)
    final estimatedOffset = firstUnreadIndex * 100.0;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        estimatedOffset.clamp(0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildVoiceNoteItem(VoiceNote note, bool isMe) {
    final playingId = ref.watch(currentlyPlayingIdProvider);
    final isPlaying = playingId == note.id;
    final audioService = ref.read(audioServiceProvider);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: GlassCard(
          backgroundColor: isMe
              ? AppColors.primary.withValues(alpha: 0.1)
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Skip backward button (only when playing)
                  if (isPlaying)
                    IconButton(
                      onPressed: () => audioService.seekBackward(
                        duration: const Duration(seconds: 5),
                      ),
                      icon: Icon(
                        Icons.replay_5,
                        color: isMe ? AppColors.primary : AppColors.accent,
                        size: 22,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),

                  // Play/Stop button
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isMe
                          ? AppGradients.primary
                          : AppGradients.voiceNote,
                    ),
                    child: IconButton(
                      onPressed: () => _playVoiceNote(note),
                      icon: Icon(
                        isPlaying
                            ? Icons.stop
                            : (note.isPlayed ? Icons.replay : Icons.play_arrow),
                        color: AppColors.white,
                      ),
                    ),
                  ),

                  // Skip forward button (only when playing)
                  if (isPlaying)
                    IconButton(
                      onPressed: () => audioService.seekForward(
                        duration: const Duration(seconds: 5),
                      ),
                      icon: Icon(
                        Icons.forward_5,
                        color: isMe ? AppColors.primary : AppColors.accent,
                        size: 22,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),

                  const SizedBox(width: 8),

                  // Progress bar & duration
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Interactive progress bar when playing
                        if (isPlaying)
                          StreamBuilder<Duration>(
                            stream: audioService.positionStream,
                            builder: (context, snapshot) {
                              final position = snapshot.data ?? Duration.zero;
                              final total = Duration(
                                seconds: note.durationSeconds,
                              );
                              return ProgressBar(
                                progress: position,
                                total: total,
                                buffered: total,
                                onSeek: (duration) =>
                                    audioService.seekTo(duration),
                                barHeight: 4,
                                thumbRadius: 6,
                                thumbGlowRadius: 12,
                                baseBarColor:
                                    (isMe
                                            ? AppColors.primary
                                            : AppColors.accent)
                                        .withValues(alpha: 0.2),
                                progressBarColor: isMe
                                    ? AppColors.primary
                                    : AppColors.accent,
                                bufferedBarColor:
                                    (isMe
                                            ? AppColors.primary
                                            : AppColors.accent)
                                        .withValues(alpha: 0.3),
                                thumbColor: isMe
                                    ? AppColors.primary
                                    : AppColors.accent,
                                thumbGlowColor:
                                    (isMe
                                            ? AppColors.primary
                                            : AppColors.accent)
                                        .withValues(alpha: 0.3),
                                timeLabelLocation: TimeLabelLocation.none,
                              );
                            },
                          )
                        else
                          // Static waveform visualization when not playing
                          Container(
                            height: 24,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: List.generate(
                                20,
                                (i) => Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 1,
                                    ),
                                    height: 4 + (i % 5) * 4.0,
                                    decoration: BoxDecoration(
                                      color:
                                          (isMe
                                                  ? AppColors.primary
                                                  : AppColors.accent)
                                              .withValues(
                                                alpha: note.isPlayed
                                                    ? 0.3
                                                    : 0.6,
                                              ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 4),

                        Row(
                          children: [
                            // Show current position when playing, otherwise show total duration
                            if (isPlaying)
                              StreamBuilder<Duration>(
                                stream: audioService.positionStream,
                                builder: (context, snapshot) {
                                  final position =
                                      snapshot.data ?? Duration.zero;
                                  final posStr = _formatDuration(position);
                                  final totalStr = note.formattedDuration;
                                  return Text(
                                    '$posStr / $totalStr',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: AppColors.gray),
                                  );
                                },
                              )
                            else
                              Text(
                                note.formattedDuration,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.gray),
                              ),
                            const Spacer(),
                            // Sync status indicator for pending notes
                            if (!note.isSynced)
                              const Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            Text(
                              _formatTime(note.createdAt),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.gray,
                                    fontSize: 10,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated recording indicator
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 1.0 + _pulseController.value * 0.2;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.error.withValues(alpha: 0.2),
                  ),
                  child: Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.error,
                      ),
                      child: const Icon(
                        Icons.mic,
                        color: AppColors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // Recording time
          Text(
            _formatRecordingTime(_recordingSeconds),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Recording...',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.error),
          ),

          const SizedBox(height: 8),

          Text(
            'Max ${AppConstants.voiceNoteMaxDuration} seconds',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.gray),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordButton() {
    return GestureDetector(
      onTap: _isRecording ? _stopRecording : _startRecording,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _isRecording ? 80 : 72,
        height: _isRecording ? 80 : 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: _isRecording ? null : AppGradients.voiceNote,
          color: _isRecording ? AppColors.error : null,
          boxShadow: [
            BoxShadow(
              color: (_isRecording ? AppColors.error : AppColors.accent)
                  .withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          _isRecording ? Icons.stop : Icons.mic,
          color: AppColors.white,
          size: 32,
        ),
      ),
    );
  }

  String _formatRecordingTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final mins = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
