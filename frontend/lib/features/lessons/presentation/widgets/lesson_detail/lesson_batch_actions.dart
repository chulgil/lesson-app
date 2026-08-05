import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/notebook/notebook_alert_dialog.dart';
import '../../../domain/entities/lesson.dart';
import '../../providers/lesson_confirmation_provider.dart';
import '../../providers/lesson_crud_provider.dart';

/// #768 ① — 선택한 여러 레슨을 한 번에 출석 확인(완료) 처리.
///
/// 단일 [confirmAttendance] 와 달리 확인 다이얼로그는 **1회**(전체 N건 + 차감 고지)만
/// 띄우고, 각 레슨을 [LessonConfirmationNotifier.confirmLessonCompleted] 로 순차
/// 처리한다. 레슨당 정확히 1회 차감(`addUsage`)이 발생한다 — 이중/누락 금지가 본
/// 액션의 데이터 무결성 계약. 부분 실패는 집계해 스낵바로 보고하고, 처리 후
/// [onDone](선택 해제 등)을 호출한다.
Future<void> batchConfirmAttendance(
  BuildContext context,
  WidgetRef ref,
  List<Lesson> lessons, {
  VoidCallback? onDone,
}) async {
  if (lessons.isEmpty) return;
  final confirmed = await showNotebookDialog<bool>(
    context: context,
    title: AppStrings.batchCompleteDialogTitle,
    message: AppStrings.batchCompleteDialogMessage(lessons.length),
    confirmLabel: AppStrings.completeAction,
    cancelLabel: AppStrings.cancel,
  );
  if (confirmed != true || !context.mounted) return;

  final notifier = ref.read(lessonConfirmationNotifierProvider.notifier);
  var success = 0;
  for (final lesson in lessons) {
    final result = await notifier.confirmLessonCompleted(lesson);
    if (result.success) success++;
  }
  onDone?.call();
  if (!context.mounted) return;
  final failed = lessons.length - success;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        failed == 0
            ? AppStrings.batchCompleteDoneSnack(success)
            : AppStrings.batchPartialSnack(success, failed),
      ),
      backgroundColor: failed == 0 ? null : AppColors.paperAccent,
    ),
  );
}

/// #768 ① — 선택한 여러 레슨을 한 번에 휴강(cancelledByTeacher) 처리. 차감 없음.
Future<void> batchMarkDayOff(
  BuildContext context,
  WidgetRef ref,
  List<Lesson> lessons, {
  VoidCallback? onDone,
}) async {
  if (lessons.isEmpty) return;
  final confirmed = await showNotebookDialog<bool>(
    context: context,
    title: AppStrings.batchDayOffDialogTitle,
    message: AppStrings.batchDayOffDialogMessage(lessons.length),
    confirmLabel: AppStrings.confirm,
    cancelLabel: AppStrings.cancel,
  );
  if (confirmed != true || !context.mounted) return;

  final notifier = ref.read(lessonsNotifierProvider.notifier);
  var success = 0;
  for (final lesson in lessons) {
    try {
      await notifier.updateLessonStatus(
        lesson,
        LessonStatus.cancelledByTeacher,
      );
      success++;
    } catch (_) {
      // tallied via failed count below
    }
  }
  onDone?.call();
  if (!context.mounted) return;
  final failed = lessons.length - success;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        failed == 0
            ? AppStrings.batchDayOffDoneSnack(success)
            : AppStrings.batchPartialSnack(success, failed),
      ),
      backgroundColor: failed == 0 ? null : AppColors.paperAccent,
    ),
  );
}
