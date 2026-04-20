import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/practice/domain/entities/practice_repertoire.dart';
import '../../../../features/practice/presentation/providers/metronome_provider.dart';
import '../../../../features/practice/presentation/providers/practice_repertoire_crud_provider.dart';
import '../widgets/metronome/metronome.dart';
import '../widgets/notes/note_preview_card.dart';
import '../widgets/practice_tools_modal.dart';
import '../widgets/section_detail/section_detail_widgets.dart';
import '../widgets/recording_comparison_sheet.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.selectedDate != null
              ? '섹션 · ${_formatDateForTitle(widget.selectedDate!)}'
              : '섹션',
        ),
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
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: AppSpacing.space2),
                        Text('수정'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: AppColors.error),
                        SizedBox(width: AppSpacing.space2),
                        Text('삭제', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      bottomNavigationBar: MetronomeControllerBar(
        onExpand: () => PracticeToolsModal.show(context),
      ),
      body: sectionAsync.when(
        data: (section) {
          if (section == null) {
            return const Center(child: Text('섹션을 찾을 수 없습니다'));
          }
          return _buildContent(context, section);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Text('오류가 발생했습니다', style: AppTypography.bodyLarge),
                  const SizedBox(height: AppSpacing.space2),
                  TextButton(
                    onPressed:
                        () => ref.invalidate(sectionProvider(widget.sectionId)),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
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

          const SizedBox(height: AppSpacing.space4),

          // Practice stats section (moved above notes)
          Text('연습기록', style: AppTypography.headingSmall),
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
              Text('녹음', style: AppTypography.headingSmall),
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
                    color: AppColors.primary,
                  ),
                  label: Text(
                    '비교',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
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
            selectedDate: widget.selectedDate,
          ),
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
            content: const Text('상태 변경에 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: AppColors.error,
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
            content: Text('연습 기록이 수정되었습니다'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('수정에 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: AppColors.error,
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

  void _showDeleteConfirmation(BuildContext context) {
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('섹션 삭제'),
            content: const Text('이 섹션과 모든 녹음을 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text(AppStrings.cancel),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  await ref
                      .read(sectionCrudProvider.notifier)
                      .deleteSection(widget.sectionId, widget.repertoireId);
                  ref.invalidate(studentRepertoiresProvider(widget.studentId));
                  if (mounted) {
                    navigator.pop();
                  }
                },
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                child: const Text('삭제'),
              ),
            ],
          ),
    );
  }
}
