import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/practice/domain/entities/recording.dart';
import '../../../../features/practice/practice_facade.dart';
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

    // Show recovery message as snackbar
    if (state.recoveryMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.recoveryMessage!),
            backgroundColor: AppColors.paperAccent,
            duration: const Duration(seconds: 3),
          ),
        );
        ref
            .read(
              recordingNotifierProvider(
                widget.repertoireId,
                widget.studentId,
              ).notifier,
            )
            .clearRecoveryMessage();
      });
    }

    return NotebookScreenScaffold(
      appBar: AppBar(
        title: Text(widget.repertoireName),
        actions: [
          if (state.representativeRecording != null &&
              !state.representativeRecording!.isShared)
            TextButton.icon(
              onPressed: _shareWithTeacher,
              icon: const Icon(Icons.share),
              label: const Text(AppStrings.practiceShare),
            ),
        ],
      ),
      body:
          state.isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    if (state.isRecovering) ...[
                      SizedBox(height: AppSpacing.space3),
                      Text(
                        '녹음 파일 복구 중...',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.inkSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              )
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
                    child:
                        state.recordings.isEmpty
                            ? _EmptyRecordingsView()
                            : _RecordingsList(
                              recordings: state.recordings,
                              onPlay:
                                  (recording) => _openPlayerSheet(recording),
                              onDelete: (id) => _deleteRecording(context, id),
                              onSetRepresentative:
                                  (id) => _setRepresentative(id),
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

  Future<void> _deleteRecording(
    BuildContext context,
    String recordingId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => NotebookAlertDialog(
            title: const Text(AppStrings.practiceRecordingDeleteTitle),
            content: const Text(AppStrings.practiceRecordingDeleteConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(AppStrings.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.paperAccent,
                ),
                child: const Text(AppStrings.delete),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final notifier = ref.read(
        recordingNotifierProvider(
          widget.repertoireId,
          widget.studentId,
        ).notifier,
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

  Future<void> _shareWithTeacher() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => NotebookAlertDialog(
            title: const Text(AppStrings.practiceShareToTeacherTitle),
            content: const Text(AppStrings.practiceShareToTeacherConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text(AppStrings.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text(AppStrings.practiceShare),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final notifier = ref.read(
        recordingNotifierProvider(
          widget.repertoireId,
          widget.studentId,
        ).notifier,
      );
      await notifier.shareWithTeacher();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.practiceSharedToTeacherSnack)),
      );
    }
  }
}

class _RecordingSection extends ConsumerStatefulWidget {
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

  @override
  ConsumerState<_RecordingSection> createState() => _RecordingSectionState();
}

class _RecordingSectionState extends ConsumerState<_RecordingSection> {
  // Thresholds for amplitude detection
  static const _noInputThreshold = 0.05;
  static const _quietThreshold = 0.40; // Updated for smart recording
  static const _micCheckDuration = Duration(milliseconds: 1500);

  bool _hasMicInput = true;
  bool _isQuiet = false;
  StreamSubscription<double>? _micCheckSubscription;
  DateTime? _recordingStartTime;

  @override
  void didUpdateWidget(covariant _RecordingSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isRecording && !oldWidget.isRecording) {
      _startMicInputCheck();
    }

    if (!widget.isRecording && oldWidget.isRecording) {
      _stopMicInputCheck();
      setState(() {
        _hasMicInput = true;
        _isQuiet = false;
      });
    }
  }

  void _startMicInputCheck() {
    _micCheckSubscription?.cancel();
    _recordingStartTime = DateTime.now();

    final recorder = ref.read(audioRecorderServiceProvider);
    _micCheckSubscription = recorder.normalizedAmplitudeStream.listen((
      amplitude,
    ) {
      final now = DateTime.now();

      // Strong input detected (amplitude >= quiet threshold)
      if (amplitude >= _quietThreshold) {
        if (!_hasMicInput || _isQuiet) {
          setState(() {
            _hasMicInput = true;
            _isQuiet = false;
          });
        }
        return;
      }

      // Quiet input (between noInput and quiet threshold)
      if (amplitude >= _noInputThreshold && amplitude < _quietThreshold) {
        if (_recordingStartTime != null &&
            now.difference(_recordingStartTime!) >= _micCheckDuration) {
          if (!_isQuiet && widget.isRecording) {
            setState(() {
              _hasMicInput = true;
              _isQuiet = true;
            });
          }
        }
        return;
      }

      // No input detected (amplitude < noInput threshold)
      if (_recordingStartTime != null &&
          now.difference(_recordingStartTime!) >= _micCheckDuration) {
        if (_hasMicInput && widget.isRecording) {
          setState(() {
            _hasMicInput = false;
            _isQuiet = false;
          });
        }
      }
    });
  }

  void _stopMicInputCheck() {
    _micCheckSubscription?.cancel();
    _micCheckSubscription = null;
    _recordingStartTime = null;
  }

  @override
  void dispose() {
    _stopMicInputCheck();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final waveformStyle =
        widget.isRecording ? WaveformStyle.amplitude : WaveformStyle.wave;
    final waveformIsActive = widget.isRecording && !widget.isPaused;

    // Get amplitude stream only when recording - this ensures fresh stream each time
    final amplitudeStream =
        widget.isRecording
            ? ref.read(audioRecorderServiceProvider).normalizedAmplitudeStream
            : null;

    // Check microphone permission
    final micPermissionAsync = ref.watch(microphonePermissionProvider);
    final hasMicPermission = micPermissionAsync.valueOrNull ?? false;

    return Container(
      padding: EdgeInsets.all(AppSpacing.space6),
      child: Column(
        children: [
          // Warning banner for no input or quiet
          if (widget.isRecording && (!_hasMicInput || _isQuiet)) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space2,
              ),
              decoration: BoxDecoration(color: AppColors.paperAccent),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    !_hasMicInput ? Icons.mic_external_off : Icons.volume_down,
                    size: 16,
                    color: AppColors.paper,
                  ),
                  const SizedBox(width: AppSpacing.space1),
                  Text(
                    !_hasMicInput ? '입력 없음' : '소리가 약함',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.paper,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.space2),
          ],

          // Waveform visualization
          Container(
            height: 100,
            decoration: BoxDecoration(
              color:
                  widget.isRecording ? AppColors.paperAccent : AppColors.paper,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.zero,
              child: RecordingWaveform(
                style: waveformStyle,
                isActive: waveformIsActive,
                height: 100,
                waveColor:
                    widget.isRecording
                        ? AppColors.paper
                        : AppColors.paperAccent,
                amplitudeStream: amplitudeStream,
              ),
            ),
          ),
          SizedBox(height: AppSpacing.space4),

          // Duration display
          Text(
            _formatDuration(widget.duration),
            style: AppTypography.displayMedium.copyWith(
              fontWeight: FontWeight.bold,
              color:
                  widget.isRecording
                      ? AppColors.paperAccent
                      : AppColors.inkSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.space2),

          // Max duration hint
          Text(
            widget.isRecording ? '녹음 중...' : '최대 3분',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.space4),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isRecording) ...[
                // Cancel button
                IconButton.outlined(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    foregroundColor: AppColors.paperAccent,
                    side: const BorderSide(color: AppColors.paperAccent),
                  ),
                  tooltip: '취소',
                ),
                SizedBox(width: AppSpacing.space4),

                // Stop button
                SizedBox(
                  width: 72,
                  height: 72,
                  child: IconButton.filled(
                    onPressed: widget.onStop,
                    icon: const Icon(Icons.stop, size: 36),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.paperAccent,
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
                    onPressed:
                        hasMicPermission
                            ? widget.onStart
                            : () async {
                              // Request permission when mic is not available
                              final granted =
                                  await ref
                                      .read(audioRecorderServiceProvider)
                                      .requestPermission();
                              if (granted) {
                                ref.invalidate(microphonePermissionProvider);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        '마이크 권한이 필요합니다. 설정에서 권한을 허용해주세요.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                    icon: Icon(
                      hasMicPermission ? Icons.mic : Icons.mic_off,
                      size: 36,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          hasMicPermission
                              ? AppColors.paperAccent
                              : AppColors.inkSecondary,
                    ),
                    tooltip: hasMicPermission ? '녹음 시작' : '마이크 권한 필요',
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
          Icon(Icons.mic_none, size: 64, color: AppColors.inkSecondary),
          SizedBox(height: AppSpacing.space4),
          Text(
            '녹음이 없습니다',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.space2),
          Text(
            '위의 마이크 버튼을 눌러 녹음을 시작하세요',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
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

  Future<void> _shareToExternal(BuildContext context, String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.practiceRecordingFileNotFound),
          ),
        );
      }
      return;
    }
    await SharePlus.instance.share(ShareParams(files: [XFile(filePath)]));
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return NotebookCard(
      elevation: recording.isRepresentative ? 2 : 0,
      color:
          recording.isRepresentative
              ? AppColors.paperAccentSoft
              : AppColors.paper,
      child: ListTile(
        leading: IconButton.filled(
          onPressed: onPlay,
          icon: const Icon(Icons.play_arrow),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.paperAccent,
            foregroundColor: AppColors.paper,
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
                decoration: const BoxDecoration(color: AppColors.paperAccent),
                child: Text(
                  '대표',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.paper,
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
                color: AppColors.inkSecondary,
              ),
            ),
            if (recording.isShared) ...[
              SizedBox(width: AppSpacing.space2),
              Icon(Icons.check_circle, size: 14, color: AppColors.paperOk),
              SizedBox(width: AppSpacing.space1),
              Text(
                '공유됨',
                style: AppTypography.caption.copyWith(color: AppColors.paperOk),
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
              case 'share_external':
                _shareToExternal(context, recording.localPath);
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder:
              (context) => [
                if (!recording.isRepresentative)
                  const PopupMenuItem(
                    value: 'representative',
                    child: Row(
                      children: [
                        Icon(Icons.star_outline),
                        SizedBox(width: AppSpacing.space2),
                        Text(AppStrings.practiceSelectAsRepresentative),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'share_external',
                  child: Row(
                    children: [
                      Icon(Icons.share),
                      SizedBox(width: AppSpacing.space2),
                      Text(AppStrings.practiceShareExternal),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: AppColors.paperAccent),
                      SizedBox(width: AppSpacing.space2),
                      Text(
                        '삭제',
                        style: TextStyle(color: AppColors.paperAccent),
                      ),
                    ],
                  ),
                ),
              ],
        ),
      ),
    );
  }
}
