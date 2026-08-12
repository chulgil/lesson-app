import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_radio.dart';
import '../../domain/entities/lesson.dart';

/// Reason for lesson not being conducted
enum LessonNonCompletionReason {
  noShow, // 무단 결석 (횟수 차감)
  studentAbsent, // 학생 사정으로 불참 (횟수 차감)
  cancelledByStudentLate, // 당일 취소 (횟수 차감)
  teacherCancelled, // 선생님 사정으로 취소 (횟수 유지)
  mutualCancelled; // 상호 합의로 취소 (횟수 유지)

  String get label {
    switch (this) {
      case LessonNonCompletionReason.noShow:
        return AppStrings.lessonNoShow;
      case LessonNonCompletionReason.studentAbsent:
        return AppStrings.lessonStudentAbsentReason;
      case LessonNonCompletionReason.cancelledByStudentLate:
        return AppStrings.lessonCancelledByStudentLateReason;
      case LessonNonCompletionReason.teacherCancelled:
        return AppStrings.lessonTeacherCancelledReason;
      case LessonNonCompletionReason.mutualCancelled:
        return AppStrings.lessonMutualCancelledReason;
    }
  }

  String get description {
    switch (this) {
      case LessonNonCompletionReason.noShow:
        return AppStrings.lessonDeductOnce;
      case LessonNonCompletionReason.studentAbsent:
        return AppStrings.lessonDeductOnce;
      case LessonNonCompletionReason.cancelledByStudentLate:
        return AppStrings.lessonDeductOnce;
      case LessonNonCompletionReason.teacherCancelled:
        return AppStrings.lessonRescheduleNoCount;
      case LessonNonCompletionReason.mutualCancelled:
        return AppStrings.lessonRescheduleNoCount;
    }
  }

  IconData get icon {
    switch (this) {
      case LessonNonCompletionReason.noShow:
        return Icons.do_not_disturb;
      case LessonNonCompletionReason.studentAbsent:
        return Icons.warning_amber;
      case LessonNonCompletionReason.cancelledByStudentLate:
        return Icons.schedule;
      case LessonNonCompletionReason.teacherCancelled:
        return Icons.calendar_today;
      case LessonNonCompletionReason.mutualCancelled:
        return Icons.calendar_today;
    }
  }

  Color get color {
    switch (this) {
      case LessonNonCompletionReason.noShow:
        return AppColors.paperAccent;
      case LessonNonCompletionReason.studentAbsent:
        return AppColors.paperAccent;
      case LessonNonCompletionReason.cancelledByStudentLate:
        return AppColors.paperAccent;
      case LessonNonCompletionReason.teacherCancelled:
        return AppColors.ink;
      case LessonNonCompletionReason.mutualCancelled:
        return AppColors.ink;
    }
  }

  /// Maps to LessonStatus
  LessonStatus get lessonStatus {
    switch (this) {
      case LessonNonCompletionReason.noShow:
        return LessonStatus.noShow;
      case LessonNonCompletionReason.studentAbsent:
        return LessonStatus.studentAbsent;
      case LessonNonCompletionReason.cancelledByStudentLate:
        return LessonStatus.cancelledByStudentLate;
      case LessonNonCompletionReason.teacherCancelled:
        return LessonStatus.cancelledByTeacher;
      case LessonNonCompletionReason.mutualCancelled:
        return LessonStatus.cancelledMutual;
    }
  }

  /// Whether this results in subscription deduction
  bool get isDeducted {
    switch (this) {
      case LessonNonCompletionReason.noShow:
      case LessonNonCompletionReason.studentAbsent:
      case LessonNonCompletionReason.cancelledByStudentLate:
        return true;
      case LessonNonCompletionReason.teacherCancelled:
      case LessonNonCompletionReason.mutualCancelled:
        return false;
    }
  }

  /// Whether this allows rescheduling
  bool get allowsReschedule => !isDeducted;
}

/// Result of lesson confirmation dialog
class LessonConfirmationResult {
  final bool completed;
  final LessonNonCompletionReason? nonCompletionReason;
  final String? note;

  /// 노쇼 표시 시 보강 크레딧을 함께 지급할지 (선생님 재량, 기본 OFF).
  /// noShow 사유일 때만 의미 있음 — 다른 사유에서는 항상 false.
  final bool grantMakeupCredit;

  const LessonConfirmationResult({
    required this.completed,
    this.nonCompletionReason,
    this.note,
    this.grantMakeupCredit = false,
  });

  LessonStatus get lessonStatus {
    if (completed) return LessonStatus.completed;
    return nonCompletionReason?.lessonStatus ?? LessonStatus.cancelled;
  }

  bool get isDeducted {
    if (completed) return true;
    return nonCompletionReason?.isDeducted ?? false;
  }
}

/// Dialog to confirm lesson completion or select non-completion reason
class LessonConfirmationDialog extends StatefulWidget {
  final Lesson lesson;

  const LessonConfirmationDialog({super.key, required this.lesson});

  /// Show the dialog and return the result
  static Future<LessonConfirmationResult?> show(
    BuildContext context, {
    required Lesson lesson,
  }) async {
    return showDialog<LessonConfirmationResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => LessonConfirmationDialog(lesson: lesson),
    );
  }

  @override
  State<LessonConfirmationDialog> createState() =>
      _LessonConfirmationDialogState();
}

class _LessonConfirmationDialogState extends State<LessonConfirmationDialog> {
  bool _showReasonSelection = false;
  LessonNonCompletionReason? _selectedReason;
  bool _grantMakeupCredit = false;
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child:
            _showReasonSelection
                ? _buildReasonSelection()
                : _buildInitialConfirmation(),
      ),
    );
  }

  Widget _buildInitialConfirmation() {
    final lesson = widget.lesson;
    final weekdays = [
      AppStrings.mon,
      AppStrings.tue,
      AppStrings.wed,
      AppStrings.thu,
      AppStrings.fri,
      AppStrings.sat,
      AppStrings.sun,
    ];
    final weekday = weekdays[lesson.date.weekday - 1];
    final dateStr =
        '${lesson.date.month}/${lesson.date.day}($weekday) ${lesson.startTime}';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.fact_check, color: AppColors.paperAccent),
              const SizedBox(width: AppSpacing.space2),
              // Notebook × Score §7.27: 다이얼로그 제목 Playfair.
              Text(
                AppStrings.lessonConfirmation,
                style: NotebookTypography.sectionTitle,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          // Lesson info
          Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(color: AppColors.paperDark),
            child: Column(
              children: [
                Text(
                  dateStr,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  '${lesson.studentName} ${lesson.instrument}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.space4),

          Text(
            AppStrings.lessonConductedQuestion,
            style: AppTypography.bodyLarge,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.space4),

          // Completed button
          _buildOptionButton(
            icon: Icons.check_circle,
            label: AppStrings.lessonComplete,
            description: AppStrings.lessonDeductOnce,
            color: AppColors.paperOk,
            onTap: () {
              Navigator.of(
                context,
              ).pop(const LessonConfirmationResult(completed: true));
            },
          ),

          const SizedBox(height: AppSpacing.space3),

          // Not completed button
          _buildOptionButton(
            icon: Icons.cancel,
            label: AppStrings.lessonNotCompleted,
            description: AppStrings.selectReason,
            color: AppColors.paperAccent,
            onTap: () {
              setState(() {
                _showReasonSelection = true;
              });
            },
          ),

          const SizedBox(height: AppSpacing.space4),

          // Cancel button
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              AppStrings.later,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonSelection() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space5),
      // 노쇼 보강 크레딧 체크박스(#no-show-credit)가 늘어나며 5개 사유 옵션 +
      // 메모 입력까지 합친 총 높이가 작은 화면에서 세로 오버플로우를 낸다 —
      // 스크롤 가능하게 감싸 잘림 없이 전체 콘텐츠에 도달할 수 있게 한다.
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with back button
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showReasonSelection = false;
                      _selectedReason = null;
                      _grantMakeupCredit = false;
                    });
                  },
                  icon: const Icon(Icons.arrow_back),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: AppSpacing.space2),
                // Notebook × Score §7.27: 다이얼로그 서브 헤더 Playfair.
                Text(
                  AppStrings.nonCompletionReason,
                  style: NotebookTypography.sectionTitle,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.space4),

            // Reason options
            ...LessonNonCompletionReason.values.map((reason) {
              final isSelected = _selectedReason == reason;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                child: _buildReasonOption(
                  reason: reason,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedReason = reason;
                      if (reason != LessonNonCompletionReason.noShow) {
                        _grantMakeupCredit = false;
                      }
                    });
                  },
                ),
              );
            }),

            if (_selectedReason == LessonNonCompletionReason.noShow) ...[
              const SizedBox(height: AppSpacing.space1),
              _buildGrantMakeupCreditOption(),
            ],

            const SizedBox(height: AppSpacing.space3),

            // Note field
            Text(
              AppStrings.memoOptional,
              style: AppTypography.caption.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: AppStrings.memoHint,
                border: OutlineInputBorder(),
                contentPadding: const EdgeInsets.all(AppSpacing.space3),
              ),
            ),

            const SizedBox(height: AppSpacing.space4),

            // Confirm button
            ElevatedButton(
              onPressed:
                  _selectedReason == null
                      ? null
                      : () {
                        Navigator.of(context).pop(
                          LessonConfirmationResult(
                            completed: false,
                            nonCompletionReason: _selectedReason,
                            note:
                                _noteController.text.isEmpty
                                    ? null
                                    : _noteController.text,
                            grantMakeupCredit:
                                _selectedReason ==
                                    LessonNonCompletionReason.noShow &&
                                _grantMakeupCredit,
                          ),
                        );
                      },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.space3,
                ),
              ),
              child: const Text(AppStrings.confirm),
            ),
          ],
        ),
      ),
    );
  }

  /// 노쇼 사유 선택 시에만 노출되는 보강 크레딧 지급 체크박스 (선생님 재량, 기본 OFF).
  Widget _buildGrantMakeupCreditOption() {
    return InkWell(
      onTap: () => setState(() => _grantMakeupCredit = !_grantMakeupCredit),
      borderRadius: BorderRadius.zero,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          border: Border.all(
            color:
                _grantMakeupCredit
                    ? AppColors.paperOk
                    : AppColors.inkQuaternary,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _grantMakeupCredit,
                onChanged:
                    (checked) =>
                        setState(() => _grantMakeupCredit = checked ?? false),
                activeColor: AppColors.paperOk,
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.lessonNoShowGrantMakeupCreditLabel,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    AppStrings.lessonNoShowGrantMakeupCreditDescription,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    description,
                    style: AppTypography.caption.copyWith(color: color),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.inkTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonOption({
    required LessonNonCompletionReason reason,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? reason.color : AppColors.inkQuaternary,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? reason.color.withValues(alpha: 0.05) : null,
        ),
        child: Row(
          children: [
            NotebookRadio<LessonNonCompletionReason>(
              value: reason,
              groupValue: isSelected ? reason : null,
              onChanged: (_) => onTap(),
              activeColor: reason.color,
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reason.label,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : null,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(reason.icon, size: 14, color: reason.color),
                      const SizedBox(width: AppSpacing.space1),
                      Text(
                        reason.description,
                        style: AppTypography.caption.copyWith(
                          color: reason.color,
                        ),
                      ),
                    ],
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
