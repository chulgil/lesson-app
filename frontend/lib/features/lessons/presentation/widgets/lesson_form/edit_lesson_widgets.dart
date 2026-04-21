import 'package:flutter/material.dart';
import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/date_format_utils.dart';
import 'lesson_form_helpers.dart';

/// Simple student info model for edit screen (without currentPiece)
class EditLessonStudentInfo {
  final String id;
  final String name;
  final String instrument;
  final Color color;

  const EditLessonStudentInfo({
    required this.id,
    required this.name,
    required this.instrument,
    required this.color,
  });
}

/// Read-only student info card for edit screen
class EditLessonStudentCard extends StatelessWidget {
  final EditLessonStudentInfo student;
  final VoidCallback? onViewProfile;

  const EditLessonStudentCard({
    super.key,
    required this.student,
    this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: student.color.withValues(alpha: 0.2),
            child: Text(
              student.name[0],
              style: AppTypography.headingSmall.copyWith(color: student.color),
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: Text(
                    student.instrument,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (onViewProfile != null)
            TextButton(onPressed: onViewProfile, child: const Text('프로필 보기')),
        ],
      ),
    );
  }
}

/// Action buttons for edit lesson screen (cancel/delete)
class LessonActionButtons extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  const LessonActionButtons({
    super.key,
    required this.onCancel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onCancel,
            icon: Icon(Icons.event_busy, color: AppColors.warning),
            label: Text('레슨 취소', style: TextStyle(color: AppColors.warning)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
              side: BorderSide(color: AppColors.warning.withValues(alpha: 0.5)),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline, color: AppColors.error),
            label: Text('레슨 삭제', style: TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Cancel lesson dialog
void showCancelLessonDialog({
  required BuildContext context,
  required String studentName,
  required DateTime lessonDate,
  required TimeOfDay lessonTime,
  required VoidCallback onConfirm,
}) {
  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('레슨 취소'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('이 레슨을 취소하시겠습니까?'),
              const SizedBox(height: AppSpacing.space4),
              Container(
                padding: const EdgeInsets.all(AppSpacing.space3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondaryLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$studentName 학생',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${formatDateMDWithDayParens(lessonDate)} ${formatLessonTime(lessonTime)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                '학생에게 레슨 취소 알림이 전송됩니다.',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.warning),
              child: const Text('레슨 취소'),
            ),
          ],
        ),
  );
}

/// Delete lesson confirmation dialog
void showDeleteLessonDialog({
  required BuildContext context,
  required VoidCallback onConfirm,
}) {
  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('레슨 삭제'),
          content: const Text(
            '이 레슨을 삭제하시겠습니까?\n\n'
            '삭제된 레슨은 복구할 수 없습니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppStrings.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text(AppStrings.delete),
            ),
          ],
        ),
  );
}

/// Edit exit confirmation dialog
void showEditLessonExitConfirmation({
  required BuildContext context,
  required bool hasChanges,
  required VoidCallback onExit,
}) {
  if (!hasChanges) {
    onExit();
    return;
  }

  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('변경사항 취소'),
          content: const Text('변경한 내용이 저장되지 않습니다.\n정말 나가시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('계속 수정'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onExit();
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('나가기'),
            ),
          ],
        ),
  );
}
