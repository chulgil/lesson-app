import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/notebook/notebook_alert_dialog.dart';
import '../../../domain/entities/lesson.dart';
import '../../providers/lesson_crud_provider.dart';

/// #473: 출석 확인 → 레슨 완료(completed) 처리. 수강권 1회 차감.
///
/// 확인 다이얼로그(1회 차감 고지) → 상태 갱신 → 스낵바. 실패 시 에러 스낵바.
/// 성공 시 [onCompleted] 콜백(자동 제안 트리거 등)을 호출한다.
Future<void> confirmAttendance(
  BuildContext context,
  WidgetRef ref,
  Lesson lesson, {
  VoidCallback? onCompleted,
}) async {
  final confirmed = await showNotebookDialog<bool>(
    context: context,
    title: AppStrings.attendanceConfirmDialogTitle,
    message: AppStrings.attendanceConfirmDialogMessage,
    confirmLabel: AppStrings.completeAction,
    cancelLabel: AppStrings.cancel,
  );
  if (confirmed != true || !context.mounted) return;

  try {
    final updatedLesson = lesson.copyWith(status: LessonStatus.completed);
    await ref.read(lessonsNotifierProvider.notifier).updateLesson(updatedLesson);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.attendanceConfirmedSnack)),
      );
    }
    onCompleted?.call();
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppStrings.attendanceActionFailed),
          backgroundColor: AppColors.paperAccent,
        ),
      );
    }
  }
}

/// #473: 휴강 → cancelledByTeacher 처리. 수강권 차감 없음.
Future<void> markDayOff(
  BuildContext context,
  WidgetRef ref,
  Lesson lesson,
) async {
  final confirmed = await showNotebookDialog<bool>(
    context: context,
    title: AppStrings.attendanceDayOffDialogTitle,
    message: AppStrings.attendanceDayOffDialogMessage,
    confirmLabel: AppStrings.confirm,
    cancelLabel: AppStrings.cancel,
  );
  if (confirmed != true || !context.mounted) return;

  try {
    final updatedLesson = lesson.copyWith(
      status: LessonStatus.cancelledByTeacher,
    );
    await ref.read(lessonsNotifierProvider.notifier).updateLesson(updatedLesson);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.attendanceDayOffSnack)),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppStrings.attendanceActionFailed),
          backgroundColor: AppColors.paperAccent,
        ),
      );
    }
  }
}
