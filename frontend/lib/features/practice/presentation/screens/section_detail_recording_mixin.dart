import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../features/practice/domain/entities/practice_repertoire.dart';
import '../../../../features/practice/domain/entities/recording.dart';
import '../../domain/entities/smart_recording.dart';
import '../../../../features/practice/presentation/providers/metronome_provider.dart';
import '../../../../features/practice/presentation/providers/practice_repertoire_crud_provider.dart';
import '../../../../features/practice/presentation/providers/recording_provider.dart';
import '../../../../features/practice/presentation/providers/smart_recording_provider.dart';
import '../../../../core/audio/audio_trimmer_service.dart';
import '../widgets/recording_player_sheet.dart';
import '../widgets/smart_recording/smart_recording_indicator.dart';

/// Mixin that encapsulates recording-related actions for SectionDetailScreen.
///
/// Extracted from SectionDetailScreen to keep the main screen file focused
/// on layout and navigation logic.
mixin SectionDetailRecordingMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  bool isRecording = false;
  bool isPaused = false;
  int recordingSeconds = 0;
  bool usedMetronome = false;

  /// Subclass must provide these values
  String get sectionId;
  String get repertoireId;
  String get studentId;

  Future<void> startRecording() async {
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

    // Start actual recording FIRST (this resets amplitude stream cache)
    final path = await recorder.startRecording(repertoireId: repertoireId);
    if (path != null) {
      // Start smart recording monitoring AFTER recording started
      // (must be after startRecording to get fresh amplitude stream)
      ref.read(smartRecordingNotifierProvider.notifier).startMonitoring();

      // Track if metronome was playing when recording started
      final metronomeState = ref.read(metronomeProvider);

      setState(() {
        isRecording = true;
        isPaused = false;
        recordingSeconds = 0;
        usedMetronome = metronomeState.isPlaying;
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

  Future<void> pauseRecording() async {
    final recorder = ref.read(audioRecorderServiceProvider);
    await recorder.pauseRecording();
    setState(() {
      isPaused = true;
    });
  }

  /// Reset recording - cancel current and restart from now
  Future<void> resetRecording() async {
    final recorder = ref.read(audioRecorderServiceProvider);

    // Cancel current recording
    await recorder.cancelRecording();

    // Reset smart recording state
    ref.read(smartRecordingNotifierProvider.notifier).reset();

    // Reset UI state
    setState(() {
      isRecording = false;
      isPaused = false;
      recordingSeconds = 0;
      usedMetronome = false;
    });

    // Wait a moment then start new recording
    await Future.delayed(const Duration(milliseconds: 100));
    await startRecording();
  }

  Future<void> resumeRecording() async {
    final recorder = ref.read(audioRecorderServiceProvider);
    await recorder.resumeRecording();
    setState(() {
      isPaused = false;
    });
    _startTimer();
  }

  void _startTimer() {
    Future.doWhile(() async {
      if (!isRecording || isPaused) return false;
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && isRecording && !isPaused) {
        setState(() {
          recordingSeconds++;
        });
        return true;
      }
      return false;
    });
  }

  /// Get actual audio file duration using just_audio.
  /// Returns null if file cannot be read.
  Future<Duration?> _getActualFileDuration(String filePath) async {
    try {
      final player = AudioPlayer();
      await player.setFilePath(filePath);
      final duration = player.duration;
      await player.dispose();
      return duration;
    } catch (e) {
      return null;
    }
  }

  Future<void> stopRecording(PracticeSection section) async {
    final recorder = ref.read(audioRecorderServiceProvider);

    // Stop smart recording monitoring and get trim info
    final smartRecordingState =
        ref.read(smartRecordingNotifierProvider.notifier).stopMonitoring();

    if (recordingSeconds < 3) {
      // Cancel recording if too short
      await recorder.cancelRecording();
      ref.read(smartRecordingNotifierProvider.notifier).reset();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('녹음 시간이 너무 짧습니다 (최소 3초)'),
          backgroundColor: AppColors.warning,
        ),
      );
      setState(() {
        isRecording = false;
        isPaused = false;
        recordingSeconds = 0;
        usedMetronome = false;
      });
      return;
    }

    // Stop actual recording and get file path
    final filePath = await recorder.stopRecording();

    setState(() {
      isRecording = false;
      isPaused = false;
    });

    if (filePath == null) {
      ref.read(smartRecordingNotifierProvider.notifier).reset();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('녹음 저장에 실패했습니다'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() {
        recordingSeconds = 0;
        usedMetronome = false;
      });
      return;
    }

    // Capture metronome BPM only if metronome was used during recording
    final metronomeBpm =
        usedMetronome ? ref.read(metronomeProvider).settings.bpm : null;

    // Get actual file duration (Android UI timer can be inaccurate)
    final audioDuration = await _getActualFileDuration(filePath);
    final totalDuration =
        audioDuration ?? Duration(seconds: recordingSeconds);

    // Apply smart recording trimming if enabled (including middle silence)
    TrimResult? trimResult;
    final needsTrimming = smartRecordingState.isEnabled &&
        (smartRecordingState.hasTrimming || smartRecordingState.hasMiddleSilence);
    if (needsTrimming) {
      trimResult = await AudioTrimmerService.instance.trimAudio(
        inputPath: filePath,
        trimStart: smartRecordingState.trimmedStart,
        trimEnd: smartRecordingState.trimmedEnd,
        totalDuration: totalDuration,
        silencePeriods: smartRecordingState.silencePeriods,
      );
    }

    // Calculate actual duration after trimming using milliseconds for accuracy
    int actualDurationMs = totalDuration.inMilliseconds;
    if (trimResult?.hasTrimming == true) {
      actualDurationMs -= trimResult!.trimmedStart.inMilliseconds;
      actualDurationMs -= trimResult.trimmedEnd.inMilliseconds;
    }
    // Also subtract middle silence periods
    if (smartRecordingState.silencePeriods.isNotEmpty) {
      final middleSilenceMs = smartRecordingState.silencePeriods
          .fold<int>(0, (sum, period) => sum + period.duration.inMilliseconds);
      actualDurationMs -= middleSilenceMs;
    }
    // Convert to seconds with rounding, ensure at least 1 second
    int actualDuration = (actualDurationMs / 1000).round();
    if (actualDuration < 1) actualDuration = 1;

    try {
      await ref.read(recordingCrudProvider.notifier).createRecording(
            sectionId: sectionId,
            filePath: filePath, // Use actual file path from recorder
            durationSeconds: actualDuration,
            bpm: metronomeBpm, // Save metronome BPM
            isRepresentative:
                section.recordings.isEmpty, // First recording is representative
          );

      // Also increment practice count
      await ref.read(sectionCrudProvider.notifier).incrementPractice(
            sectionId,
            repertoireId,
            actualDuration,
          );

      ref.invalidate(sectionProvider(sectionId));
      ref.invalidate(studentRepertoiresProvider(studentId));

      // Show smart recording result dialog if trimming or middle silence was applied
      final hasTrimOrSilence = trimResult?.hasTrimming == true ||
          smartRecordingState.silencePeriods.isNotEmpty;
      if (mounted && hasTrimOrSilence) {
        // Calculate middle silence total duration
        final middleSilenceDuration = smartRecordingState.silencePeriods.fold(
          Duration.zero,
          (sum, period) => sum + period.duration,
        );
        await showSmartRecordingResult(
          context,
          trimmedStart: trimResult?.trimmedStart ?? Duration.zero,
          trimmedEnd: trimResult?.trimmedEnd ?? Duration.zero,
          totalDuration: totalDuration,
          middleSilenceCount: smartRecordingState.silencePeriods.length,
          middleSilenceDuration: middleSilenceDuration,
          onRestore: trimResult?.originalFilePath != null
              ? () async {
                  await AudioTrimmerService.instance.restoreOriginal(
                    originalPath: trimResult!.originalFilePath!,
                    trimmedPath: filePath,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('원본 파일이 복구되었습니다'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                }
              : null,
        );
      } else if (mounted) {
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
            content: const Text('녹음 저장에 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    ref.read(smartRecordingNotifierProvider.notifier).reset();
    setState(() {
      recordingSeconds = 0;
      usedMetronome = false;
    });
  }

  Future<void> setRepresentative(String recordingId) async {
    try {
      await ref.read(recordingCrudProvider.notifier).setRepresentative(
            sectionId,
            recordingId,
            repertoireId,
          );
      ref.invalidate(sectionProvider(sectionId));

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
            content: const Text('설정에 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> deleteRecording(String recordingId) async {
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
            sectionId,
          );
      ref.invalidate(sectionProvider(sectionId));

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
            content: const Text('삭제에 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void playRecording(PracticeRecording practiceRecording) {
    // Convert PracticeRecording to Recording model for the player sheet
    final recording = Recording(
      id: practiceRecording.id,
      repertoireId: repertoireId,
      studentId: studentId,
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
      repertoireId: repertoireId,
      studentId: studentId,
    );
  }
}
