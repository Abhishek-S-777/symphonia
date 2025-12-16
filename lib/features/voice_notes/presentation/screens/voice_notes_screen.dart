import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/vibration_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../shared/widgets/animated_gradient_background.dart';
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

  // Sample voice notes
  final List<VoiceNote> _voiceNotes = [
    VoiceNote(
      id: '1',
      senderId: 'partner',
      durationSeconds: 15,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      isSynced: true,
    ),
    VoiceNote(
      id: '2',
      senderId: 'me',
      durationSeconds: 8,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      playedAt: DateTime.now().subtract(const Duration(hours: 1)),
      isSynced: true,
    ),
    VoiceNote(
      id: '3',
      senderId: 'partner',
      durationSeconds: 22,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      playedAt: DateTime.now().subtract(const Duration(hours: 12)),
      isSynced: true,
    ),
  ];

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
    super.dispose();
  }

  void _startRecording() {
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

    // TODO: Start actual recording
  }

  void _stopRecording() {
    _recordingTimer?.cancel();
    _pulseController.stop();
    _pulseController.reset();

    setState(() {
      _isRecording = false;
    });

    // Confirmation vibration
    ref.read(vibrationServiceProvider).success();

    // TODO: Stop recording and save

    if (_recordingSeconds >= AppConstants.voiceNoteMinDuration) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Voice note recorded! (${_recordingSeconds}s) Sending to partner...',
          ),
          backgroundColor: AppColors.success,
        ),
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
              _buildAppBar(),

              // Recording area
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Recent voice notes
                    if (!_isRecording) Expanded(child: _buildVoiceNotesList()),

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

  Widget _buildVoiceNotesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _voiceNotes.length,
      itemBuilder: (context, index) {
        final note = _voiceNotes[index];
        final isMe = note.senderId == 'me';

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

  Widget _buildVoiceNoteItem(VoiceNote note, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: GlassCard(
          backgroundColor: isMe
              ? AppColors.primary.withValues(alpha: 0.1)
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Play button
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
                  onPressed: () {
                    // TODO: Play voice note
                    ref
                        .read(vibrationServiceProvider)
                        .vibrateVoiceNoteReceived();
                  },
                  icon: Icon(
                    note.isPlayed ? Icons.replay : Icons.play_arrow,
                    color: AppColors.white,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Waveform placeholder & duration
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Waveform visualization placeholder
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
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              height: 4 + (i % 5) * 4.0,
                              decoration: BoxDecoration(
                                color:
                                    (isMe
                                            ? AppColors.primary
                                            : AppColors.accent)
                                        .withValues(
                                          alpha: note.isPlayed ? 0.3 : 0.6,
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
                        Text(
                          note.formattedDuration,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.gray),
                        ),
                        const Spacer(),
                        Text(
                          _formatTime(note.createdAt),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.gray, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
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
