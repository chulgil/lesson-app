import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/entities/lesson.dart';
import 'attendance_action_card.dart';
import 'attendance_actions.dart';
import 'attendance_status_banners.dart';

/// #473: Teacher attendance surface for the lesson detail screen.
///
/// Composes three pieces based on the lesson state:
/// - Unconfirmed (scheduled + past end): 사전 안내 배너(24h 이내) + 출석 확인/휴강 액션 카드.
/// - Processed (status != scheduled): 차감 결과 칩.
///
/// Renders nothing for students or for not-yet-ended scheduled lessons.
class AttendanceSection extends ConsumerWidget {
  final Lesson lesson;
  final bool isTeacher;

  /// Called after a successful 출석 확인(completed) — e.g. to fire auto-proposal.
  final VoidCallback? onCompleted;

  const AttendanceSection({
    super.key,
    required this.lesson,
    required this.isTeacher,
    this.onCompleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isTeacher) return const SizedBox.shrink();

    if (lesson.isUnconfirmed) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (lesson.isWithinAutoCompleteWindow) ...[
            const AttendanceAutoCompleteBanner(),
            const SizedBox(height: AppSpacing.space3),
          ],
          AttendanceActionCard(
            onConfirm:
                () => confirmAttendance(
                  context,
                  ref,
                  lesson,
                  onCompleted: onCompleted,
                ),
            onDayOff: () => markDayOff(context, ref, lesson),
          ),
          const SizedBox(height: AppSpacing.space4),
        ],
      );
    }

    if (lesson.status != LessonStatus.scheduled) {
      // #1240 — 되돌리기 진입점. 이게 없으면 완료 오탭이 영구 확정되고
      // 차감된 회차를 앱 안에서 복구할 방법이 없다.
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.space4),
        child: Row(
          children: [
            AttendanceDeductionResultChip(deducted: lesson.status.isDeducted),
            const Spacer(),
            TextButton.icon(
              onPressed: () => revertAttendance(context, ref, lesson),
              icon: const Icon(Icons.undo, size: 16),
              label: const Text(AppStrings.attendanceRevertAction),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
