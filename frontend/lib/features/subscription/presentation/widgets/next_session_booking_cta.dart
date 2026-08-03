import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../lessons/lessons_facade.dart';
import '../../domain/entities/subscription.dart';

/// §8 (subscription_schedule_management_spec) — 미정 회차 예약 진입점.
///
/// 수강권 상세는 일정 "변경"만 가능했고 미정 회차를 "새로 잡는" 길이 없었다
/// (`sessionBookingRequired` 는 사용처 0건인 死문자열이었다). 이 배너가 그
/// 배선을 완성한다: 회차권(package/trial)에서 잔여 > 스케줄된 회차일 때만
/// 노출. 정규권(monthly)은 주간 자동 생성이라 미정 회차가 없는 것이 정상.
class NextSessionBookingCta extends ConsumerWidget {
  const NextSessionBookingCta({
    super.key,
    required this.subscription,
    required this.onBook,
  });

  final Subscription subscription;

  /// [nextSession] — 예약할 회차 번호 (1-based). 라우팅은 호출 화면 몫
  /// (선생님: 레슨 추가 프리필 / 학생: 직접 예약).
  final ValueChanged<int> onBook;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (subscription.type == SubscriptionType.monthly) {
      return const SizedBox.shrink();
    }
    final remaining = subscription.remainingLessons ?? 0;
    if (remaining <= 0) return const SizedBox.shrink();

    final lessons =
        ref.watch(lessonsByStudentProvider(subscription.studentId)).valueOrNull;
    if (lessons == null) return const SizedBox.shrink();

    // Preview lessons wait for renewal confirmation — they don't occupy a slot.
    final scheduledCount =
        lessons
            .where(
              (l) =>
                  l.subscriptionId == subscription.id &&
                  l.status == LessonStatus.scheduled &&
                  !l.isPreview,
            )
            .length;
    final unscheduled = remaining - scheduledCount;
    if (unscheduled <= 0) return const SizedBox.shrink();

    final nextSession = subscription.usedLessons + scheduledCount + 1;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.space2,
        AppSpacing.screenPadding,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: AppColors.paperAccentSoft,
        border: Border.all(color: AppColors.paperAccent),
      ),
      child: Row(
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 18,
            color: AppColors.paperAccent,
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              AppStrings.sessionBookingRequired(nextSession),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          OutlinedButton(
            onPressed: () => onBook(nextSession),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
              ),
              side: const BorderSide(color: AppColors.paperAccent),
            ),
            child: Text(
              AppStrings.bookAction,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.paperAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
