import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/widgets/notebook/notebook_alert_dialog.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_screen_scaffold.dart';
import '../../../academy/domain/entities/bulk_closure.dart';
import 'makeup_conflict.dart';

/// 일괄 휴강 적용 후 강사가 보강 일정을 입력하는 화면 (G15).
///
/// Spec: `docs/specs/web/academy/owner_bulk_closure_spec.md` §5.3
///
/// 강사가 각 영향 레슨에 보강 시각을 입력하고 저장한다.
/// 의견 윈도우(§5.2)는 별도 ClosureDetailScreen 에서 표시.
class MakeupLessonInputScreen extends StatefulWidget {
  final BulkClosure closure;

  /// 보강 일정 저장 콜백. 키: lessonId, 값: 입력된 시각.
  final Future<void> Function(Map<String, DateTime>) onSaveAll;

  const MakeupLessonInputScreen({
    super.key,
    required this.closure,
    required this.onSaveAll,
  });

  @override
  State<MakeupLessonInputScreen> createState() =>
      _MakeupLessonInputScreenState();
}

class _MakeupLessonInputScreenState extends State<MakeupLessonInputScreen> {
  /// 입력 중인 보강 시각. lessonId -> DateTime.
  late final Map<String, DateTime?> _drafts;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _drafts = {
      for (final l in widget.closure.affectedLessons) l.lessonId: l.makeupAt,
    };
  }

  @override
  Widget build(BuildContext context) {
    final closureDateText = formatDateYMD(widget.closure.closureDate);
    final completedCount = _drafts.values.whereType<DateTime>().length;
    final totalCount = widget.closure.affectedLessons.length;
    final conflicts = detectMakeupConflicts(
      widget.closure.affectedLessons,
      _drafts,
    );

    return NotebookScreenScaffold(
      backgroundColor: AppColors.paper,
      appBar: const NotebookDetailAppBar(title: '보강 일정 입력'),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(closureDateText, completedCount, totalCount),
            Expanded(
              child:
                  widget.closure.affectedLessons.isEmpty
                      ? _buildEmptyState()
                      : _buildLessonsList(conflicts),
            ),
            _buildBottomBar(completedCount, totalCount, conflicts),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String closureDateText, int completed, int total) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(bottom: BorderSide(color: AppColors.inkQuaternary)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.makeupInputTitle(closureDateText),
            style: AppTypography.headingSmall,
          ),
          if (total > 0) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(
              AppStrings.makeupInputProgress(completed, total),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        AppStrings.makeupInputEmptyState,
        style: AppTypography.bodyMedium.copyWith(color: AppColors.inkSecondary),
      ),
    );
  }

  Widget _buildLessonsList(Set<String> conflicts) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.space4),
      itemCount: widget.closure.affectedLessons.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.space3),
      itemBuilder: (context, i) {
        final lesson = widget.closure.affectedLessons[i];
        return _MakeupLessonRow(
          lesson: lesson,
          draft: _drafts[lesson.lessonId],
          hasConflict: conflicts.contains(lesson.lessonId),
          onPick: () => _pickMakeupTime(lesson),
        );
      },
    );
  }

  Widget _buildBottomBar(int completed, int total, Set<String> conflicts) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.inkQuaternary)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (conflicts.isNotEmpty) ...[
              Text(
                AppStrings.makeupInputConflictNotice(conflicts.length),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.paperAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
            ],
            Text(
              AppStrings.makeupInputNoticeConfirm,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space1),
            Text(
              AppStrings.makeupInputNoticeNotify,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => _save(confirm: false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, AppSpacing.buttonHeight),
                      shape: const RoundedRectangleBorder(),
                      side: const BorderSide(color: AppColors.inkQuaternary),
                    ),
                    child: Text(
                      AppStrings.makeupInputDraftSave,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: FilledButton(
                    onPressed:
                        (completed == 0 || _isSaving)
                            ? null
                            : () => _showConfirmSummary(conflicts),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.paperAccent,
                      minimumSize: const Size(0, AppSpacing.buttonHeight),
                      shape: const RoundedRectangleBorder(),
                    ),
                    child: Text(
                      AppStrings.makeupInputBulkConfirm,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.paper,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickMakeupTime(AffectedLesson lesson) async {
    final initial =
        _drafts[lesson.lessonId] ??
        lesson.originalStartAt.add(const Duration(days: 7));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    setState(() {
      _drafts[lesson.lessonId] = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _showConfirmSummary(Set<String> conflicts) async {
    final filled = widget.closure.affectedLessons
        .where((l) => _drafts[l.lessonId] != null)
        .toList();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => NotebookAlertDialog(
        title: AppStrings.makeupInputSummaryTitle,
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (conflicts.isNotEmpty) ...[
              Text(
                AppStrings.makeupInputConflictNotice(conflicts.length),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.paperAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
            ],
            for (final l in filled)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.space1,
                ),
                child: Text(
                  AppStrings.makeupInputSummaryRow(
                    l.studentName,
                    _formatSummary(_drafts[l.lessonId]!),
                  ),
                  style: AppTypography.bodySmall.copyWith(
                    color: conflicts.contains(l.lessonId)
                        ? AppColors.paperAccent
                        : AppColors.ink,
                  ),
                ),
              ),
          ],
        ),
        cancelLabel: AppStrings.cancel,
        onCancel: () => Navigator.pop(dialogContext, false),
        confirmLabel: AppStrings.makeupInputBulkConfirm,
        onConfirm: () => Navigator.pop(dialogContext, true),
      ),
    );
    if (result == true) await _save(confirm: true);
  }

  String _formatSummary(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$mm/$dd $hh:$mi';
  }

  Future<void> _save({required bool confirm}) async {
    final filled = <String, DateTime>{
      for (final e in _drafts.entries)
        if (e.value != null) e.key: e.value!,
    };
    setState(() => _isSaving = true);
    try {
      await widget.onSaveAll(filled);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.makeupInputSavedToast)),
      );
      if (confirm) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _MakeupLessonRow extends StatelessWidget {
  final AffectedLesson lesson;
  final DateTime? draft;
  final bool hasConflict;
  final VoidCallback onPick;

  const _MakeupLessonRow({
    required this.lesson,
    required this.draft,
    required this.hasConflict,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final originalText = _formatOriginal(lesson.originalStartAt);
    final draftText =
        draft != null
            ? _formatDraft(draft!)
            : AppStrings.makeupInputPickerEmpty;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(
          color: hasConflict ? AppColors.paperAccent : AppColors.inkQuaternary,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.makeupInputLessonRow(lesson.studentName, originalText),
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Row(
            children: [
              Text(
                '→ ${AppStrings.makeupInputPickerLabel}: ',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
              Expanded(
                child: OutlinedButton(
                  onPressed: onPick,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
                    shape: const RoundedRectangleBorder(),
                    side: const BorderSide(color: AppColors.inkQuaternary),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      draftText,
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            draft != null
                                ? AppColors.ink
                                : AppColors.inkTertiary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (hasConflict) ...[
            const SizedBox(height: AppSpacing.space1),
            Text(
              AppStrings.makeupInputConflictBadge,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.paperAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatOriginal(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$mm/$dd $hh:$mi';
  }

  String _formatDraft(DateTime d) {
    final yy = d.year.toString();
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$yy-$mm-$dd $hh:$mi';
  }
}
