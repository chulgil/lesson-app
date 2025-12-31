import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/practice_repertoire.dart';
import '../../../../models/recording.dart';
import '../../../../providers/metronome/metronome_provider.dart';
import '../../../../providers/practice_repertoire/practice_repertoire_crud_provider.dart';
import '../../../../providers/recording/recording_provider.dart';
import '../widgets/metronome/metronome.dart';
import '../widgets/recording_player_sheet.dart';
import '../widgets/recording_waveform.dart';

/// Section detail screen showing section info and recordings
class SectionDetailScreen extends ConsumerStatefulWidget {
  final String sectionId;
  final String repertoireId;
  final String studentId;

  const SectionDetailScreen({
    super.key,
    required this.sectionId,
    required this.repertoireId,
    required this.studentId,
  });

  @override
  ConsumerState<SectionDetailScreen> createState() => _SectionDetailScreenState();
}

class _SectionDetailScreenState extends ConsumerState<SectionDetailScreen> {
  bool _isRecording = false;
  bool _isPaused = false;
  int _recordingSeconds = 0;

  @override
  Widget build(BuildContext context) {
    final sectionAsync = ref.watch(sectionProvider(widget.sectionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('섹션 상세'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                // TODO: Edit section
              } else if (value == 'delete') {
                _showDeleteConfirmation(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('수정'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('삭제', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: MetronomeControllerBar(
        onExpand: () => MetronomeFullScreenModal.show(context),
      ),
      body: sectionAsync.when(
        data: (section) {
          if (section == null) {
            return const Center(child: Text('섹션을 찾을 수 없습니다'));
          }
          return _buildContent(context, section);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.space4),
              Text('오류가 발생했습니다', style: AppTypography.bodyLarge),
              const SizedBox(height: AppSpacing.space2),
              TextButton(
                onPressed: () => ref.invalidate(sectionProvider(widget.sectionId)),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PracticeSection section) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section info card
          _SectionInfoCard(section: section),

          const SizedBox(height: AppSpacing.space6),

          // Practice stats
          _PracticeStatsCard(section: section),

          const SizedBox(height: AppSpacing.space6),

          // Recording section
          Text(
            '녹음',
            style: AppTypography.headingSmall,
          ),
          const SizedBox(height: AppSpacing.space3),

          // Recording button
          _RecordingControl(
            isRecording: _isRecording,
            isPaused: _isPaused,
            recordingSeconds: _recordingSeconds,
            onStartRecording: _startRecording,
            onPauseRecording: _pauseRecording,
            onResumeRecording: _resumeRecording,
            onStopRecording: () => _stopRecording(section),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Recordings list
          if (section.recordings.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '녹음 기록 (${section.recordings.length})',
                  style: AppTypography.headingSmall,
                ),
                if (section.representativeRecording != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space2,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 14,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '대표 녹음 있음',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.space3),

            // Recordings list
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: section.recordings.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.space2),
              itemBuilder: (context, index) {
                final recording = section.recordings[index];
                return _RecordingListItem(
                  recording: recording,
                  sectionId: section.id,
                  repertoireId: widget.repertoireId,
                  onSetRepresentative: () => _setRepresentative(recording.id),
                  onDelete: () => _deleteRecording(recording.id),
                  onPlay: () => _playRecording(recording),
                );
              },
            ),
          ] else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.space6),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondaryLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.mic_none,
                    size: 48,
                    color: AppColors.textTertiaryLight,
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  Text(
                    '아직 녹음이 없습니다',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    '위의 녹음 버튼을 눌러 연습을 기록해보세요',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: AppSpacing.space8),

          // Completion toggle
          _CompletionToggle(
            section: section,
            onToggle: () => _toggleCompletion(section),
          ),
        ],
      ),
    );
  }

  Future<void> _startRecording() async {
    final recorder = ref.read(audioRecorderServiceProvider);

    // Check permission first
    if (!await recorder.hasPermission()) {
      final granted = await recorder.requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('마이크 권한이 필요합니다'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
    }

    // Start actual recording
    final path = await recorder.startRecording(repertoireId: widget.repertoireId);
    if (path != null) {
      setState(() {
        _isRecording = true;
        _isPaused = false;
        _recordingSeconds = 0;
      });
      _startTimer();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('녹음을 시작할 수 없습니다'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pauseRecording() async {
    final recorder = ref.read(audioRecorderServiceProvider);
    await recorder.pauseRecording();
    setState(() {
      _isPaused = true;
    });
  }

  Future<void> _resumeRecording() async {
    final recorder = ref.read(audioRecorderServiceProvider);
    await recorder.resumeRecording();
    setState(() {
      _isPaused = false;
    });
    _startTimer();
  }

  void _startTimer() {
    Future.doWhile(() async {
      if (!_isRecording || _isPaused) return false;
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _isRecording && !_isPaused) {
        setState(() {
          _recordingSeconds++;
        });
        return true;
      }
      return false;
    });
  }

  Future<void> _stopRecording(PracticeSection section) async {
    final recorder = ref.read(audioRecorderServiceProvider);

    if (_recordingSeconds < 3) {
      // Cancel recording if too short
      await recorder.cancelRecording();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('녹음 시간이 너무 짧습니다 (최소 3초)'),
          backgroundColor: AppColors.warning,
        ),
      );
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _recordingSeconds = 0;
      });
      return;
    }

    // Stop actual recording and get file path
    final filePath = await recorder.stopRecording();

    setState(() {
      _isRecording = false;
      _isPaused = false;
    });

    if (filePath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('녹음 저장에 실패했습니다'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() {
        _recordingSeconds = 0;
      });
      return;
    }

    // Capture current metronome BPM
    final metronomeBpm = ref.read(metronomeProvider).settings.bpm;

    try {
      await ref.read(recordingCrudProvider.notifier).createRecording(
            sectionId: widget.sectionId,
            filePath: filePath, // Use actual file path from recorder
            durationSeconds: _recordingSeconds,
            bpm: metronomeBpm, // Save metronome BPM
            isRepresentative: section.recordings.isEmpty, // First recording is representative
          );

      // Also increment practice count
      await ref.read(sectionCrudProvider.notifier).incrementPractice(
            widget.sectionId,
            widget.repertoireId,
            _recordingSeconds,
          );

      ref.invalidate(sectionProvider(widget.sectionId));
      ref.invalidate(studentRepertoiresProvider(widget.studentId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('녹음이 저장되었습니다'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('녹음 저장 실패: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    setState(() {
      _recordingSeconds = 0;
    });
  }

  Future<void> _setRepresentative(String recordingId) async {
    try {
      await ref.read(recordingCrudProvider.notifier).setRepresentative(
            widget.sectionId,
            recordingId,
            widget.repertoireId,
          );
      ref.invalidate(sectionProvider(widget.sectionId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('대표 녹음으로 설정되었습니다'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('설정 실패: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteRecording(String recordingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('녹음 삭제'),
        content: const Text('이 녹음을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(recordingCrudProvider.notifier).deleteRecording(
            recordingId,
            widget.sectionId,
          );
      ref.invalidate(sectionProvider(widget.sectionId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('녹음이 삭제되었습니다'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('삭제 실패: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _playRecording(PracticeRecording practiceRecording) {
    // Convert PracticeRecording to Recording model for the player sheet
    final recording = Recording(
      id: practiceRecording.id,
      repertoireId: widget.repertoireId,
      studentId: widget.studentId,
      type: RecordingType.student,
      localPath: practiceRecording.filePath,
      durationSeconds: practiceRecording.durationSeconds,
      recordedAt: practiceRecording.createdAt,
      isRepresentative: practiceRecording.isRepresentative,
    );

    // Show the recording player bottom sheet
    RecordingPlayerSheet.show(
      context,
      recording: recording,
      repertoireId: widget.repertoireId,
      studentId: widget.studentId,
    );
  }

  Future<void> _toggleCompletion(PracticeSection section) async {
    try {
      await ref.read(sectionCrudProvider.notifier).toggleComplete(
            section.id,
            widget.repertoireId,
          );
      ref.invalidate(sectionProvider(widget.sectionId));
      ref.invalidate(studentRepertoiresProvider(widget.studentId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('상태 변경 실패: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('섹션 삭제'),
        content: const Text('이 섹션과 모든 녹음을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref.read(sectionCrudProvider.notifier).deleteSection(
                    widget.sectionId,
                    widget.repertoireId,
                  );
              ref.invalidate(studentRepertoiresProvider(widget.studentId));
              if (mounted) {
                navigator.pop();
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}

/// Section info card showing piece name and measure range
class _SectionInfoCard extends StatelessWidget {
  final PracticeSection section;

  const _SectionInfoCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                  child: const Icon(
                    Icons.music_note,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppSpacing.space4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.pieceName,
                        style: AppTypography.headingMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        section.measureRangeText,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      if (section.sectionName != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.space2,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondaryLight,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSmall),
                          ),
                          child: Text(
                            section.sectionName!,
                            style: AppTypography.caption,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Practice stats card
class _PracticeStatsCard extends StatelessWidget {
  final PracticeSection section;

  const _PracticeStatsCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Row(
          children: [
            Expanded(
              child: _StatItem(
                icon: Icons.repeat,
                label: '연습 횟수',
                value: '${section.practiceCount}회',
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: AppColors.borderLight,
            ),
            Expanded(
              child: _StatItem(
                icon: Icons.timer,
                label: '총 연습 시간',
                value: section.formattedTotalTime,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: AppColors.borderLight,
            ),
            Expanded(
              child: _StatItem(
                icon: Icons.mic,
                label: '녹음',
                value: '${section.recordings.length}개',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.headingSmall.copyWith(
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

/// Recording control widget
class _RecordingControl extends StatelessWidget {
  final bool isRecording;
  final bool isPaused;
  final int recordingSeconds;
  final VoidCallback onStartRecording;
  final VoidCallback onPauseRecording;
  final VoidCallback onResumeRecording;
  final VoidCallback onStopRecording;

  const _RecordingControl({
    required this.isRecording,
    required this.isPaused,
    required this.recordingSeconds,
    required this.onStartRecording,
    required this.onPauseRecording,
    required this.onResumeRecording,
    required this.onStopRecording,
  });

  String get _formattedTime {
    final minutes = recordingSeconds ~/ 60;
    final seconds = recordingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Container(
          decoration: BoxDecoration(
            color: isRecording
                ? AppColors.error.withValues(alpha: 0.15)
                : AppColors.surfaceSecondaryLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: isRecording
                ? Border.all(color: AppColors.error.withValues(alpha: 0.3))
                : null,
          ),
          child: Stack(
          children: [
            // Background waveform overlay (only when recording)
            if (isRecording)
              Positioned.fill(
                child: RecordingWaveform(
                  isActive: !isPaused,
                  height: 200,
                  waveColor: Colors.white,
                  waveCount: 3,
                ),
              ),
            // Foreground content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Column(
                children: [
                  if (isRecording) ...[
                    // Recording indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isPaused ? AppColors.warning : AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isPaused ? '일시정지' : '녹음 중',
                          style: AppTypography.bodyMedium.copyWith(
                            color: isPaused ? AppColors.warning : AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    // Timer
                    Text(
                      _formattedTime,
                      style: AppTypography.headingLarge.copyWith(
                        fontSize: 36,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    // Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Pause/Resume button (2x size)
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: IconButton.filled(
                            onPressed: isPaused ? onResumeRecording : onPauseRecording,
                            icon: Icon(
                              isPaused ? Icons.play_arrow : Icons.pause,
                              size: 40,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.warning,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space4),
                        // Stop button (2x size)
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: IconButton.filled(
                            onPressed: onStopRecording,
                            icon: const Icon(Icons.stop, size: 40),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Start recording button (2x size, 60% width, centered)
                    const SizedBox(height: AppSpacing.space4),
                    Center(
                      child: FractionallySizedBox(
                        widthFactor: 0.6,
                        child: FilledButton.icon(
                          onPressed: onStartRecording,
                          icon: const Icon(Icons.mic, size: 28),
                          label: Text(
                            '녹음 시작',
                            style: AppTypography.bodyLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.error,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.space8,
                              vertical: AppSpacing.space5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space4),
                  ],
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

/// Recording list item
class _RecordingListItem extends StatelessWidget {
  final PracticeRecording recording;
  final String sectionId;
  final String repertoireId;
  final VoidCallback onSetRepresentative;
  final VoidCallback onDelete;
  final VoidCallback onPlay;

  const _RecordingListItem({
    required this.recording,
    required this.sectionId,
    required this.repertoireId,
    required this.onSetRepresentative,
    required this.onDelete,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onPlay,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space3),
          child: Row(
            children: [
              // Play button
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          recording.formattedDuration,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (recording.bpm != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusSmall),
                            ),
                            child: Text(
                              '${recording.bpm} BPM',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        if (recording.isRepresentative) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusSmall),
                            ),
                            child: Text(
                              '대표',
                              style: AppTypography.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(recording.createdAt),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              // Menu
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'representative') {
                    onSetRepresentative();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => [
                  if (!recording.isRepresentative)
                    const PopupMenuItem(
                      value: 'representative',
                      child: Row(
                        children: [
                          Icon(Icons.star_outline, size: 20),
                          SizedBox(width: 8),
                          Text('대표 녹음으로 설정'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('삭제', style: TextStyle(color: AppColors.error)),
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

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Completion toggle widget
class _CompletionToggle extends StatelessWidget {
  final PracticeSection section;
  final VoidCallback onToggle;

  const _CompletionToggle({
    required this.section,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: section.isCompleted
          ? AppColors.success.withValues(alpha: 0.1)
          : null,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Row(
            children: [
              Icon(
                section.isCompleted
                    ? Icons.check_circle
                    : Icons.check_circle_outline,
                color: section.isCompleted
                    ? AppColors.success
                    : AppColors.textTertiaryLight,
                size: 32,
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.isCompleted ? '연습 완료!' : '연습 완료로 표시',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: section.isCompleted
                            ? AppColors.success
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      section.isCompleted
                          ? '탭하여 완료 취소'
                          : '탭하여 이 섹션을 완료로 표시하세요',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
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
}
