import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/recording.dart';
import '../../../../providers/recording/recording_provider.dart';
import '../widgets/recording_player_sheet.dart';
import '../widgets/recording_waveform.dart';

/// Screen for recording practice audio for a repertoire.
class PracticeRecordingScreen extends ConsumerStatefulWidget {
  const PracticeRecordingScreen({
    super.key,
    required this.repertoireId,
    required this.repertoireName,
    required this.studentId,
  });

  final String repertoireId;
  final String repertoireName;
  final String studentId;

  @override
  ConsumerState<PracticeRecordingScreen> createState() =>
      _PracticeRecordingScreenState();
}

class _PracticeRecordingScreenState
    extends ConsumerState<PracticeRecordingScreen> {
  Timer? _durationTimer;
  Duration _recordingDuration = Duration.zero;

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _recordingDuration = Duration.zero;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _recordingDuration += const Duration(seconds: 1);
      });
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      recordingNotifierProvider(widget.repertoireId, widget.studentId),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.repertoireName),
        actions: [
          if (state.representativeRecording != null &&
              !state.representativeRecording!.isShared)
            TextButton.icon(
              onPressed: () => _shareWithTeacher(context),
              icon: const Icon(Icons.share),
              label: const Text('공유'),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Recording section
                _RecordingSection(
                  isRecording: state.isRecording,
                  isPaused: state.isPaused,
                  duration: _recordingDuration,
                  onStart: () => _startRecording(),
                  onStop: () => _stopRecording(),
                  onCancel: () => _cancelRecording(),
                ),

                const Divider(),

                // Recordings list
                Expanded(
                  child: state.recordings.isEmpty
                      ? _EmptyRecordingsView()
                      : _RecordingsList(
                          recordings: state.recordings,
                          onPlay: (recording) => _openPlayerSheet(recording),
                          onDelete: (id) => _deleteRecording(context, id),
                          onSetRepresentative: (id) => _setRepresentative(id),
                          repertoireId: widget.repertoireId,
                          studentId: widget.studentId,
                        ),
                ),
              ],
            ),
    );
  }

  Future<void> _startRecording() async {
    final notifier = ref.read(
      recordingNotifierProvider(widget.repertoireId, widget.studentId).notifier,
    );
    final success = await notifier.startRecording();
    if (success) {
      _startDurationTimer();
    }
  }

  Future<void> _stopRecording() async {
    _stopDurationTimer();
    final notifier = ref.read(
      recordingNotifierProvider(widget.repertoireId, widget.studentId).notifier,
    );
    await notifier.stopRecording();
    setState(() {
      _recordingDuration = Duration.zero;
    });
  }

  Future<void> _cancelRecording() async {
    _stopDurationTimer();
    final notifier = ref.read(
      recordingNotifierProvider(widget.repertoireId, widget.studentId).notifier,
    );
    await notifier.cancelRecording();
    setState(() {
      _recordingDuration = Duration.zero;
    });
  }

  void _openPlayerSheet(Recording recording) {
    RecordingPlayerSheet.show(
      context,
      recording: recording,
      repertoireId: widget.repertoireId,
      studentId: widget.studentId,
    );
  }

  Future<void> _deleteRecording(BuildContext context, String recordingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('녹음 삭제'),
        content: const Text('이 녹음을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final notifier = ref.read(
        recordingNotifierProvider(widget.repertoireId, widget.studentId).notifier,
      );
      await notifier.deleteRecording(recordingId);
    }
  }

  Future<void> _setRepresentative(String recordingId) async {
    final notifier = ref.read(
      recordingNotifierProvider(widget.repertoireId, widget.studentId).notifier,
    );
    await notifier.setAsRepresentative(recordingId);
  }

  Future<void> _shareWithTeacher(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('선생님께 공유'),
        content: const Text('대표 녹음을 선생님께 공유하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('공유'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final notifier = ref.read(
        recordingNotifierProvider(widget.repertoireId, widget.studentId).notifier,
      );
      await notifier.shareWithTeacher();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('선생님께 공유되었습니다')),
        );
      }
    }
  }
}

class _RecordingSection extends StatelessWidget {
  const _RecordingSection({
    required this.isRecording,
    required this.isPaused,
    required this.duration,
    required this.onStart,
    required this.onStop,
    required this.onCancel,
  });

  final bool isRecording;
  final bool isPaused;
  final Duration duration;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onCancel;

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.space6),
      child: Column(
        children: [
          // Waveform visualization
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: isRecording ? AppColors.primary : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: RecordingWaveform(
                isActive: isRecording && !isPaused,
                height: 100,
                waveColor: isRecording ? Colors.white : AppColors.primary,
              ),
            ),
          ),
          SizedBox(height: AppSpacing.space4),

          // Duration display
          Text(
            _formatDuration(duration),
            style: AppTypography.displayMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: isRecording ? AppColors.primary : AppColors.textSecondaryLight,
            ),
          ),
          SizedBox(height: AppSpacing.space2),

          // Max duration hint
          Text(
            isRecording ? '녹음 중...' : '최대 3분',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          SizedBox(height: AppSpacing.space4),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isRecording) ...[
                // Cancel button
                IconButton.outlined(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  tooltip: '취소',
                ),
                SizedBox(width: AppSpacing.space4),

                // Stop button
                SizedBox(
                  width: 72,
                  height: 72,
                  child: IconButton.filled(
                    onPressed: onStop,
                    icon: const Icon(Icons.stop, size: 36),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    tooltip: '녹음 완료',
                  ),
                ),
              ] else ...[
                // Start button
                SizedBox(
                  width: 72,
                  height: 72,
                  child: IconButton.filled(
                    onPressed: onStart,
                    icon: const Icon(Icons.mic, size: 36),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    tooltip: '녹음 시작',
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyRecordingsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mic_none,
            size: 64,
            color: AppColors.textSecondaryLight,
          ),
          SizedBox(height: AppSpacing.space4),
          Text(
            '녹음이 없습니다',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          SizedBox(height: AppSpacing.space2),
          Text(
            '위의 마이크 버튼을 눌러 녹음을 시작하세요',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordingsList extends StatelessWidget {
  const _RecordingsList({
    required this.recordings,
    required this.onPlay,
    required this.onDelete,
    required this.onSetRepresentative,
    required this.repertoireId,
    required this.studentId,
  });

  final List<Recording> recordings;
  final void Function(Recording) onPlay;
  final void Function(String) onDelete;
  final void Function(String) onSetRepresentative;
  final String repertoireId;
  final String studentId;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.all(AppSpacing.space4),
      itemCount: recordings.length,
      separatorBuilder: (_, __) => SizedBox(height: AppSpacing.space2),
      itemBuilder: (context, index) {
        final recording = recordings[index];

        return _RecordingItem(
          recording: recording,
          onPlay: () => onPlay(recording),
          onDelete: () => onDelete(recording.id),
          onSetRepresentative: () => onSetRepresentative(recording.id),
        );
      },
    );
  }
}

class _RecordingItem extends StatelessWidget {
  const _RecordingItem({
    required this.recording,
    required this.onPlay,
    required this.onDelete,
    required this.onSetRepresentative,
  });

  final Recording recording;
  final VoidCallback onPlay;
  final VoidCallback onDelete;
  final VoidCallback onSetRepresentative;

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: recording.isRepresentative ? 2 : 0,
      color: recording.isRepresentative
          ? AppColors.primaryLight
          : AppColors.surfaceLight,
      child: ListTile(
        leading: IconButton.filled(
          onPressed: onPlay,
          icon: const Icon(Icons.play_arrow),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
        title: Row(
          children: [
            if (recording.isRepresentative)
              Container(
                margin: EdgeInsets.only(right: AppSpacing.space2),
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.space2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '대표',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Text(
              _formatDate(recording.recordedAt),
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Text(
              recording.formattedDuration,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            if (recording.isShared) ...[
              SizedBox(width: AppSpacing.space2),
              Icon(
                Icons.check_circle,
                size: 14,
                color: Colors.green,
              ),
              SizedBox(width: 4),
              Text(
                '공유됨',
                style: AppTypography.caption.copyWith(
                  color: Colors.green,
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'representative':
                onSetRepresentative();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => [
            if (!recording.isRepresentative)
              const PopupMenuItem(
                value: 'representative',
                child: Row(
                  children: [
                    Icon(Icons.star_outline),
                    SizedBox(width: 8),
                    Text('대표로 선택'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Text('삭제', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
