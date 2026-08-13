import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../features/practice/practice_facade.dart';
import '../extensions/practice_section_visuals.dart';
import '../widgets/metronome/metronome.dart';
import '../widgets/notes/note_preview_card.dart';
import '../widgets/practice_tools_modal.dart';
import '../widgets/section_detail/section_detail_widgets.dart';
import '../widgets/recording_comparison_sheet.dart';
import '../widgets/youtube/practice_youtube_player.dart';
import 'section_detail_recording_mixin.dart';

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
  ConsumerState<SectionDetailScreen> createState() =>
      _SectionDetailScreenState();
}

class _SectionDetailScreenState extends ConsumerState<SectionDetailScreen>
    with SectionDetailRecordingMixin {
  @override
  String get sectionId => widget.sectionId;

  @override
  String get repertoireId => widget.repertoireId;

  @override
  String get studentId => widget.studentId;

  @override
  Widget build(BuildContext context) {
    final sectionAsync = ref.watch(sectionProvider(widget.sectionId));

    // Listen for metronome state changes during recording
    ref.listen<MetronomeState>(metronomeProvider, (previous, next) {
      if (isRecording && next.isPlaying && !usedMetronome) {
        setState(() {
          usedMetronome = true;
        });
      }
    });

    return NotebookScreenScaffold(
      appBar: NotebookDetailAppBar(
        title:
            widget.selectedDate != null
                ? '섹션 · ${_formatDateForTitle(widget.selectedDate!)}'
                : '섹션',
        customActions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
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
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: AppSpacing.space2),
                        Text(AppStrings.modify),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete,
                          size: 20,
                          color: AppColors.paperAccent,
                        ),
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
        ],
      ),
      bottomNavigationBar: MetronomeControllerBar(
        // studentId + sectionId 전달 — stop 시 logMetronome 실행 + 그 곡에 시간
        // 크레딧 (#932, 선택적 곡 연결 practice_master §1.2)
        onExpand:
            () => PracticeToolsModal.show(
              context,
              studentId: widget.studentId,
              sectionId: widget.sectionId,
            ),
      ),
      body: sectionAsync.when(
        data: (section) {
          if (section == null) {
            return const Center(
              child: Text(AppStrings.practiceSectionNotFound),
            );
          }
          return _buildContent(context, section);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) => ErrorStateWidget(
              title: AppStrings.practiceErrorOccurred,
              actionLabel: AppStrings.retry,
              onAction: () => ref.invalidate(sectionProvider(widget.sectionId)),
            ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PracticeSection section) {
    // Get repertoire to access its name and start date
    final repertoireAsync = ref.watch(repertoireProvider(widget.repertoireId));
    final repertoireName = repertoireAsync.valueOrNull?.name;
    final repertoireStartDate = repertoireAsync.valueOrNull?.startDate;

    // Sort recordings by date (newest first)
    final sortedRecordings = List.of(section.recordings)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section info card
          SectionInfoCard(
            section: section,
            repertoireName: repertoireName,
            repertoireStartDate: repertoireStartDate,
            selectedDate: widget.selectedDate,
          ),

          // §3.5 YouTube loop player — only when teacher attached a video.
          if (section.youtubeVideoId != null &&
              section.youtubeVideoId!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space4),
            Text(
              AppStrings.youtubeLoopVideoHeading,
              style: NotebookTypography.sectionTitle,
            ),
            const SizedBox(height: AppSpacing.space2),
            PracticeYoutubePlayer(
              videoId: section.youtubeVideoId!,
              sectionId: section.id,
              teacherStartSeconds: section.youtubeStartSeconds,
              teacherEndSeconds: section.youtubeEndSeconds,
            ),
          ],

          const SizedBox(height: AppSpacing.space4),

          // Practice stats section (moved above notes)
          // Notebook × Score: 스크린 섹션 제목은 Playfair sectionTitle
          // 로 통일 (§7.17).
          Text(
            AppStrings.practicePracticeRecordTitle,
            style: NotebookTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.space2),
          PracticeStatsEditor(
            section: section,
            onUpdate:
                (count, seconds) =>
                    _updatePracticeStats(section, count, seconds),
          ),

          const SizedBox(height: AppSpacing.space4),

          // Practice notes preview
          NotePreviewCard(
            sectionId: section.id,
            onTap: () => _navigateToNotes(section),
          ),

          const SizedBox(height: AppSpacing.space4),

          // Recording section
          Row(
            children: [
              // Notebook × Score: 스크린 섹션 제목은 Playfair sectionTitle
              // 로 통일 (§7.17).
              Text(
                AppStrings.practiceRecordingTitle,
                style: NotebookTypography.sectionTitle,
              ),
              const Spacer(),
              if (sortedRecordings.length >= 2)
                TextButton.icon(
                  onPressed: () {
                    final chronological = List.of(sortedRecordings)
                      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
                    showRecordingComparisonSheet(context, chronological);
                  },
                  icon: Icon(
                    Icons.compare_arrows,
                    size: 18,
                    color: AppColors.paperAccent,
                  ),
                  label: Text(
                    '비교',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.paperAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),

          // Recording button
          RecordingControl(
            isRecording: isRecording,
            isPaused: isPaused,
            recordingSeconds: recordingSeconds,
            onStartRecording: startRecording,
            onPauseRecording: pauseRecording,
            onResumeRecording: resumeRecording,
            onStopRecording: () => stopRecording(section),
            onResetRecording: resetRecording,
          ),

          const SizedBox(height: AppSpacing.space6),

          // Recordings list
          SectionRecordingsSection(
            section: section,
            repertoireId: widget.repertoireId,
            recordings: sortedRecordings,
            onSetRepresentative: setRepresentative,
            onDelete: deleteRecording,
            onPlay: playRecording,
          ),

          const SizedBox(height: AppSpacing.space6),

          // Completion toggle (below recording list)
          CompletionToggle(
            section: section,
            onToggle: () => _toggleCompletion(section),
            studentId: widget.studentId,
            selectedDate: widget.selectedDate,
          ),

          // Notebook × Score: "Fine." 종지부
          const SizedBox(height: AppSpacing.space6),
          Center(child: Text('Fine.', style: NotebookTypography.fine)),
          const SizedBox(height: AppSpacing.space8),
        ],
      ),
    );
  }

  Future<void> _toggleCompletion(PracticeSection section) async {
    try {
      // Use toggleDailyCompletion for N회 반복 sections, toggleComplete for standard
      if (section.hasRepeatCount) {
        final today = widget.selectedDate ?? DateTime.now();
        await ref
            .read(sectionCrudProvider.notifier)
            .toggleDailyCompletion(
              section.id,
              widget.repertoireId,
              widget.studentId,
              today,
            );
      } else {
        await ref
            .read(sectionCrudProvider.notifier)
            .toggleComplete(
              section.id,
              widget.repertoireId,
              studentId: widget.studentId,
              date: widget.selectedDate,
            );
      }
      ref.invalidate(sectionProvider(widget.sectionId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.practiceStatusChangeFailedRetry),
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    }
  }

  /// Update practice count and time manually
  Future<void> _updatePracticeStats(
    PracticeSection section,
    int newCount,
    int newSeconds,
  ) async {
    try {
      // Create updated section
      final updatedSection = section.copyWith(
        practiceCount: newCount,
        totalPracticeSeconds: newSeconds,
      );

      await ref
          .read(sectionCrudProvider.notifier)
          .updateSection(updatedSection, studentId: widget.studentId);

      ref.invalidate(sectionProvider(widget.sectionId));
      ref.invalidate(studentRepertoiresProvider(widget.studentId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.practiceStatsUpdatedSnack),
            backgroundColor: AppColors.paperOk,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.practiceUpdateFailedRetry),
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    }
  }

  void _navigateToNotes(PracticeSection section) {
    final sectionName = '${section.pieceName} ${section.rangeText}';
    context.push(
      '${AppRoutes.practiceNotes.replaceFirst(':sectionId', section.id)}'
      '?name=${Uri.encodeComponent(sectionName)}',
    );
  }

  String _formatDateForTitle(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(date.year, date.month, date.day);
    final difference = today.difference(selected).inDays;

    final dateStr = '${date.month}월 ${date.day}일';

    if (difference == 0) {
      return '$dateStr (오늘)';
    } else if (difference == 1) {
      return '$dateStr (어제)';
    } else if (difference == -1) {
      return '$dateStr (내일)';
    }
    return dateStr;
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final navigator = Navigator.of(context);
    final confirmed = await showNotebookDialog(
      context: context,
      title: AppStrings.practiceSectionDeleteTitle,
      message: AppStrings.practiceSectionDeleteConfirm,
      confirmLabel: AppStrings.delete,
      cancelLabel: AppStrings.cancel,
      isDestructive: true,
    );

    if (confirmed == true) {
      await ref
          .read(sectionCrudProvider.notifier)
          .deleteSection(widget.sectionId, widget.repertoireId);
      ref.invalidate(studentRepertoiresProvider(widget.studentId));
      if (mounted) {
        navigator.pop();
      }
    }
  }
}
