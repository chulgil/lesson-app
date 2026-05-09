import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
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
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
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
                    color: AppColors.paperAccentSoft.withValues(alpha: 0.3),
                  ),
                  child: Text(
                    student.instrument,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.paperAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (onViewProfile != null)
            TextButton(
              onPressed: onViewProfile,
              child: const Text(AppStrings.viewProfileAction),
            ),
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
            icon: Icon(Icons.event_busy, color: AppColors.paperAccent),
            label: Text(
              AppStrings.actionLessonCancel,
              style: TextStyle(color: AppColors.paperAccent),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
              side: BorderSide(color: AppColors.paperAccent),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline, color: AppColors.paperAccent),
            label: Text(
              AppStrings.deleteLessonTitle,
              style: TextStyle(color: AppColors.paperAccent),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
              side: BorderSide(color: AppColors.paperAccent),
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
  showNotebookDialog(
    context: context,
    titleWidget: const Text(AppStrings.actionLessonCancel),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(AppStrings.cancelLessonConfirm),
        const SizedBox(height: AppSpacing.space4),
        Container(
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(color: AppColors.paperDark),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.studentNameSuffix(studentName),
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${formatDateMDWithDayParens(lessonDate)} ${formatLessonTime(lessonTime)}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        Text(
          AppStrings.cancelLessonNotificationNotice,
          style: AppTypography.caption.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
      ],
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
        style: TextButton.styleFrom(
          foregroundColor: AppColors.paperAccent,
        ),
        child: const Text(AppStrings.actionLessonCancel),
      ),
    ],
  );
}

/// Delete lesson confirmation dialog
void showDeleteLessonDialog({
  required BuildContext context,
  required VoidCallback onConfirm,
}) {
  showNotebookDialog(
    context: context,
    titleWidget: const Text(AppStrings.deleteLessonTitle),
    content: const Text(AppStrings.deleteLessonNoRestoreConfirm),
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
        style: TextButton.styleFrom(
          foregroundColor: AppColors.paperAccent,
        ),
        child: const Text(AppStrings.delete),
      ),
    ],
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

  showNotebookDialog(
    context: context,
    titleWidget: const Text(AppStrings.cancelChangesTitle),
    content: const Text(AppStrings.exitChangesWithoutSavingConfirm),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text(AppStrings.continueEditing),
      ),
      TextButton(
        onPressed: () {
          Navigator.pop(context);
          onExit();
        },
        style: TextButton.styleFrom(
          foregroundColor: AppColors.paperAccent,
        ),
        child: const Text(AppStrings.exitAction),
      ),
    ],
  );
}
