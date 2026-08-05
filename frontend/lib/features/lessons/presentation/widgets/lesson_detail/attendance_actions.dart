import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/notebook/notebook_alert_dialog.dart';
import '../../../domain/entities/lesson.dart';
import '../../providers/lesson_confirmation_provider.dart';
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
    // Use LessonConfirmationNotifier which records subscription usage (1 deduction).
    // The previous updateLesson path skipped deduction — this is the correct route.
    await ref
        .read(lessonConfirmationNotifierProvider.notifier)
        .confirmLessonCompleted(lesson);
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
    await ref
        .read(lessonsNotifierProvider.notifier)
        .updateLessonStatus(lesson, LessonStatus.cancelledByTeacher);
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

/// #1240 — 출결 처리 되돌리기. 완료/노쇼로 차감된 회차를 백엔드가 복구한다.
///
/// 오탭으로 완료 처리하면 앱 안에 복구 진입점이 없어 학생이 회차를 영구히
/// 잃었다. 상태 전이 엔드포인트가 차감 해제까지 수행하므로 여기서는 예정
/// 상태로 되돌리기만 하면 된다.
Future<void> revertAttendance(
  BuildContext context,
  WidgetRef ref,
  Lesson lesson,
) async {
  final confirmed = await showNotebookDialog<bool>(
    context: context,
    title: AppStrings.attendanceRevertDialogTitle,
    message:
        lesson.status.isDeducted
            ? AppStrings.attendanceRevertDialogMessage
            : AppStrings.attendanceRevertDialogMessageNoDeduction,
    confirmLabel: AppStrings.attendanceRevertAction,
    cancelLabel: AppStrings.cancel,
  );
  if (confirmed != true || !context.mounted) return;

  try {
    await ref
        .read(lessonsNotifierProvider.notifier)
        .updateLessonStatus(lesson, LessonStatus.scheduled);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.attendanceRevertedSnack)),
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
