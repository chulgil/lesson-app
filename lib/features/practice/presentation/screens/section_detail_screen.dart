import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/practice_repertoire.dart';
import '../../../../models/recording.dart';
import '../../../../models/smart_recording.dart';
import '../../../../providers/metronome/metronome_provider.dart';
import '../../../../providers/practice_repertoire/practice_repertoire_crud_provider.dart';
import '../../../../providers/recording/recording_provider.dart';
import '../../../../providers/smart_recording/smart_recording_provider.dart';
import '../../../../services/audio_trimmer_service.dart';
import '../../domain/entities/recording_filter_type.dart';
import '../widgets/metronome/metronome.dart';
import '../widgets/section_detail/recording_filter_dropdown.dart';
import '../widgets/notes/note_preview_card.dart';
import '../widgets/recording_player_sheet.dart';
import '../widgets/section_detail/section_detail_widgets.dart';
import '../widgets/smart_recording/smart_recording_indicator.dart';

/// Section detail screen showing section info and recordings
class SectionDetailScreen extends ConsumerStatefulWidget {
  final String sectionId;
  final String repertoireId;
  final String studentId;
  final DateTime? selectedDate; // Filter recordings up to this date

  const SectionDetailScreen({
    super.key,
    required this.sectionId,
    required this.repertoireId,
    required this.studentId,
    this.selectedDate,
  });

  @override
  ConsumerState<SectionDetailScreen> createState() => _SectionDetailScreenState();
}

class _SectionDetailScreenState extends ConsumerState<SectionDetailScreen> {
  bool _isRecording = false;
  bool _isPaused = false;
  int _recordingSeconds = 0;
  bool _usedMetronome = false; // Track if metronome was used during recording
  RecordingFilterType _recordingFilter = RecordingFilterType.daily; // Default to daily

  @override
  Widget build(BuildContext context) {
    final sectionAsync = ref.watch(sectionProvider(widget.sectionId));

    // Listen for metronome state changes during recording
    ref.listen<MetronomeState>(metronomeProvider, (previous, next) {
      if (_isRecording && next.isPlaying && !_usedMetronome) {
        setState(() {
          _usedMetronome = true;
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('섹션 상세'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                context.push(
                  '${AppRoutes.editSection.replaceFirst(':id', widget.sectionId)}'
                  '?repertoireId=${widget.repertoireId}&studentId=${widget.studentId}',
                );
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
    // Sort recordings by date (newest first)
    final sortedRecordings = List.of(section.recordings)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Apply recording filter based on selected filter type and date
    final filteredRecordings = _filterRecordings(
      recordings: sortedRecordings,
      filter: _recordingFilter,
      selectedDate: widget.selectedDate,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section info card
          SectionInfoCard(section: section),

          const SizedBox(height: AppSpacing.space4),

          // Practice notes preview
          Row(
            children: [
              Text(
                '연습노트',
                style: AppTypography.headingSmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          NotePreviewCard(
            sectionId: section.id,
            onTap: () => _navigateToNotes(section),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Practice stats
          PracticeStatsCard(section: section),

          const SizedBox(height: AppSpacing.space6),

          // Completion toggle (moved above recording section)
          CompletionToggle(
            section: section,
            onToggle: () => _toggleCompletion(section),
            selectedDate: widget.selectedDate,
          ),

          const SizedBox(height: AppSpacing.space6),

          // Recording section
          Text(
            '녹음',
            style: AppTypography.headingSmall,
          ),
          const SizedBox(height: AppSpacing.space3),

          // Recording button
          RecordingControl(
            isRecording: _isRecording,
            isPaused: _isPaused,
            recordingSeconds: _recordingSeconds,
            onStartRecording: _startRecording,
            onPauseRecording: _pauseRecording,
            onResumeRecording: _resumeRecording,
            onStopRecording: () => _stopRecording(section),
            onResetRecording: _resetRecording,
          ),

          const SizedBox(height: AppSpacing.space6),

          // Recordings list
          if (section.recordings.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '녹음 기록 (${filteredRecordings.length})',
                  style: AppTypography.headingSmall,
                ),
                // Recording filter dropdown (replaces "대표 녹음 있음" badge)
                RecordingFilterDropdown(
                  selectedFilter: _recordingFilter,
                  onFilterChanged: (filter) {
                    setState(() {
                      _recordingFilter = filter;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space3),

            // Recordings list or empty filter message
            if (filteredRecordings.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredRecordings.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.space2),
                itemBuilder: (context, index) {
                  final recording = filteredRecordings[index];
                  return SectionRecordingListItem(
                    recording: recording,
                    sectionId: section.id,
                    repertoireId: widget.repertoireId,
                    onSetRepresentative: () => _setRepresentative(recording.id),
                    onDelete: () => _deleteRecording(recording.id),
                    onPlay: () => _playRecording(recording),
                  );
                },
              )
            else
              // Empty filtered result (but recordings exist)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.space4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondaryLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                child: Text(
                  '${_recordingFilter.displayLabel} 녹음이 없습니다',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
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
        ],
      ),
    );
  }

  /// Filter recordings based on filter type and selected date
  List<PracticeRecording> _filterRecordings({
    required List<PracticeRecording> recordings,
    required RecordingFilterType filter,
    required DateTime? selectedDate,
  }) {
    final referenceDate = selectedDate ?? DateTime.now();

    switch (filter) {
      case RecordingFilterType.all:
        // Show all recordings up to selected date (if set)
        if (selectedDate != null) {
          return recordings.where((r) {
            final recordingDate = DateTime(
              r.createdAt.year,
              r.createdAt.month,
              r.createdAt.day,
            );
            final selectedDateOnly = DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
            );
            return !recordingDate.isAfter(selectedDateOnly);
          }).toList();
        }
        return recordings;

      case RecordingFilterType.weekly:
        // Show recordings from the week containing the reference date (Mon-Sun)
        final weekday = referenceDate.weekday; // 1=Mon, 7=Sun
        final monday = referenceDate.subtract(Duration(days: weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        final weekStart = DateTime(monday.year, monday.month, monday.day);
        final weekEnd = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);

        return recordings.where((r) {
          return r.createdAt.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
              r.createdAt.isBefore(weekEnd.add(const Duration(seconds: 1)));
        }).toList();

      case RecordingFilterType.daily:
        // Show recordings from the reference date only
        return recordings.where((r) {
          return r.createdAt.year == referenceDate.year &&
              r.createdAt.month == referenceDate.month &&
              r.createdAt.day == referenceDate.day;
        }).toList();
    }
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

    // Start actual recording FIRST (this resets amplitude stream cache)
    final path = await recorder.startRecording(repertoireId: widget.repertoireId);
    if (path != null) {
      // Start smart recording monitoring AFTER recording started
      // (must be after startRecording to get fresh amplitude stream)
      ref.read(smartRecordingNotifierProvider.notifier).startMonitoring();

      // Track if metronome was playing when recording started
      final metronomeState = ref.read(metronomeProvider);

      setState(() {
        _isRecording = true;
        _isPaused = false;
        _recordingSeconds = 0;
        _usedMetronome = metronomeState.isPlaying;
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

  /// Reset recording - cancel current and restart from now
  Future<void> _resetRecording() async {
    final recorder = ref.read(audioRecorderServiceProvider);

    // Cancel current recording
    await recorder.cancelRecording();

    // Reset smart recording state
    ref.read(smartRecordingNotifierProvider.notifier).reset();

    // Reset UI state
    setState(() {
      _isRecording = false;
      _isPaused = false;
      _recordingSeconds = 0;
      _usedMetronome = false;
    });

    // Wait a moment then start new recording
    await Future.delayed(const Duration(milliseconds: 100));
    await _startRecording();
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

    // Stop smart recording monitoring and get trim info
    final smartRecordingState = ref.read(smartRecordingNotifierProvider.notifier).stopMonitoring();

    if (_recordingSeconds < 3) {
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
        _isRecording = false;
        _isPaused = false;
        _recordingSeconds = 0;
        _usedMetronome = false;
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
        _recordingSeconds = 0;
        _usedMetronome = false;
      });
      return;
    }

    // Capture metronome BPM only if metronome was used during recording
    final metronomeBpm = _usedMetronome
        ? ref.read(metronomeProvider).settings.bpm
        : null;
    final totalDuration = Duration(seconds: _recordingSeconds);

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

    // Calculate actual duration after trimming (start/end + middle silence)
    int actualDuration = _recordingSeconds;
    if (trimResult?.hasTrimming == true) {
      actualDuration -= trimResult!.trimmedStart.inSeconds;
      actualDuration -= trimResult.trimmedEnd.inSeconds;
    }
    // Also subtract middle silence periods
    if (smartRecordingState.silencePeriods.isNotEmpty) {
      final middleSilenceSeconds = smartRecordingState.silencePeriods
          .fold<int>(0, (sum, period) => sum + period.duration.inSeconds);
      actualDuration -= middleSilenceSeconds;
    }
    // Ensure duration is at least 1 second
    if (actualDuration < 1) actualDuration = 1;

    try {
      await ref.read(recordingCrudProvider.notifier).createRecording(
            sectionId: widget.sectionId,
            filePath: filePath, // Use actual file path from recorder
            durationSeconds: actualDuration,
            bpm: metronomeBpm, // Save metronome BPM
            isRepresentative: section.recordings.isEmpty, // First recording is representative
          );

      // Also increment practice count
      await ref.read(sectionCrudProvider.notifier).incrementPractice(
            widget.sectionId,
            widget.repertoireId,
            actualDuration,
          );

      ref.invalidate(sectionProvider(widget.sectionId));
      ref.invalidate(studentRepertoiresProvider(widget.studentId));

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
            content: Text('녹음 저장 실패: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    ref.read(smartRecordingNotifierProvider.notifier).reset();
    setState(() {
      _recordingSeconds = 0;
      _usedMetronome = false;
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
      // Use toggleDailyCompletion for N회 반복 sections, toggleComplete for standard
      if (section.hasRepeatCount) {
        final today = widget.selectedDate ?? DateTime.now();
        await ref.read(sectionCrudProvider.notifier).toggleDailyCompletion(
              section.id,
              widget.repertoireId,
              widget.studentId,
              today,
            );
      } else {
        await ref.read(sectionCrudProvider.notifier).toggleComplete(
              section.id,
              widget.repertoireId,
              studentId: widget.studentId,
            );
      }
      ref.invalidate(sectionProvider(widget.sectionId));
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

  void _navigateToNotes(PracticeSection section) {
    final sectionName = '${section.pieceName} ${section.measureRangeText}';
    context.push(
      '${AppRoutes.practiceNotes.replaceFirst(':sectionId', section.id)}'
      '?name=${Uri.encodeComponent(sectionName)}',
    );
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
