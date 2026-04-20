import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
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
        return '무단 결석';
      case LessonNonCompletionReason.studentAbsent:
        return '학생 사정으로 불참';
      case LessonNonCompletionReason.cancelledByStudentLate:
        return '당일 취소 (24시간 이내)';
      case LessonNonCompletionReason.teacherCancelled:
        return '선생님 사정으로 취소';
      case LessonNonCompletionReason.mutualCancelled:
        return '상호 합의로 취소';
    }
  }

  String get description {
    switch (this) {
      case LessonNonCompletionReason.noShow:
        return '횟수 1회 차감';
      case LessonNonCompletionReason.studentAbsent:
        return '횟수 1회 차감';
      case LessonNonCompletionReason.cancelledByStudentLate:
        return '횟수 1회 차감';
      case LessonNonCompletionReason.teacherCancelled:
        return '다른 날짜로 변경 (횟수 유지)';
      case LessonNonCompletionReason.mutualCancelled:
        return '다른 날짜로 변경 (횟수 유지)';
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
        return AppColors.error;
      case LessonNonCompletionReason.studentAbsent:
        return AppColors.warning;
      case LessonNonCompletionReason.cancelledByStudentLate:
        return AppColors.warning;
      case LessonNonCompletionReason.teacherCancelled:
        return AppColors.info;
      case LessonNonCompletionReason.mutualCancelled:
        return AppColors.info;
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

  const LessonConfirmationResult({
    required this.completed,
    this.nonCompletionReason,
    this.note,
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

  const LessonConfirmationDialog({
    super.key,
    required this.lesson,
  });

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
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child: _showReasonSelection
            ? _buildReasonSelection()
            : _buildInitialConfirmation(),
      ),
    );
  }

  Widget _buildInitialConfirmation() {
    final lesson = widget.lesson;
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
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
              const Icon(Icons.fact_check, color: AppColors.primary),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '레슨 확인',
                style: AppTypography.headingMedium,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          // Lesson info
          Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondaryLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
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
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.space4),

          Text(
            '이 레슨이 진행되었나요?',
            style: AppTypography.bodyLarge,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.space4),

          // Completed button
          _buildOptionButton(
            icon: Icons.check_circle,
            label: '레슨 완료',
            description: '횟수 1회 차감',
            color: AppColors.success,
            onTap: () {
              Navigator.of(context).pop(
                const LessonConfirmationResult(completed: true),
              );
            },
          ),

          const SizedBox(height: AppSpacing.space3),

          // Not completed button
          _buildOptionButton(
            icon: Icons.cancel,
            label: '레슨 미진행',
            description: '사유 선택 필요',
            color: AppColors.error,
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
              '나중에',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
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
                  });
                },
                icon: const Icon(Icons.arrow_back),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '레슨 미진행 사유',
                style: AppTypography.headingMedium,
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
                  });
                },
              ),
            );
          }),

          const SizedBox(height: AppSpacing.space3),

          // Note field
          Text(
            '메모 (선택)',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: '추가 메모를 입력하세요',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
              contentPadding: const EdgeInsets.all(AppSpacing.space3),
            ),
          ),

          const SizedBox(height: AppSpacing.space4),

          // Confirm button
          ElevatedButton(
            onPressed: _selectedReason == null
                ? null
                : () {
                    Navigator.of(context).pop(
                      LessonConfirmationResult(
                        completed: false,
                        nonCompletionReason: _selectedReason,
                        note: _noteController.text.isEmpty
                            ? null
                            : _noteController.text,
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
            ),
            child: const Text('확인'),
          ),
        ],
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
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
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
                    style: AppTypography.caption.copyWith(
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textTertiaryLight),
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
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? reason.color : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          color: isSelected ? reason.color.withValues(alpha: 0.05) : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? reason.color : AppColors.textTertiaryLight,
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
