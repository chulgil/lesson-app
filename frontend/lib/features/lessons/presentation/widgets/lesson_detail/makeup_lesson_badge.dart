import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../subscription/subscription_facade.dart';

/// 보강 배지 — 크레딧 연결(`MakeupCredit.usedLessonId`)로 식별한다
/// (spec §2.6.6: 레슨 유형 enum 을 두지 않는 간접 표현. 체험 배지는 기존
/// `SubscriptionBadge`/수강권 타입이 담당).
///
/// Teacher-scoped lookup — render only on teacher surfaces.
class MakeupLessonBadge extends ConsumerWidget {
  const MakeupLessonBadge({
    super.key,
    required this.lessonId,
    required this.studentId,
  });

  final String lessonId;
  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credits =
        ref.watch(teacherMakeupCreditsProvider(studentId)).valueOrNull;
    final creditFunded =
        credits?.any((c) => c.usedLessonId == lessonId) ?? false;
    if (!creditFunded) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(border: Border.all(color: AppColors.paperOk)),
      child: Text(
        AppStrings.lessonMakeupBadge,
        style: AppTypography.caption.copyWith(
          color: AppColors.paperOk,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
