import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../subscription/subscription_facade.dart';
import '../../../subscription/subscription_ui_facade.dart';

/// Thin wrapper — subscribes to activeStudentSubscriptionsProvider,
/// picks the most urgent subscription, and delegates rendering to
/// [SubscriptionBadge]. Owns only: data retrieval + empty-state.
class StudentSubscriptionMiniBadge extends ConsumerWidget {
  final String studentId;

  const StudentSubscriptionMiniBadge({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(
      activeStudentSubscriptionsProvider(studentId),
    );

    return subscriptionsAsync.when(
      data: (subscriptions) {
        final urgent = _mostUrgent(subscriptions);
        if (urgent == null) {
          return Text(
            AppStrings.subscriptionBadgeNone,
            style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
          );
        }
        return SubscriptionBadge(subscription: urgent);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Subscription? _mostUrgent(List<Subscription> subscriptions) {
    if (subscriptions.isEmpty) return null;
    final sorted = List<Subscription>.from(subscriptions)..sort((a, b) {
      // Primary: SubscriptionBadge 문서 우선순위 (입금대기>만료>임박>정상).
      final rank = _urgencyRank(a).compareTo(_urgencyRank(b));
      if (rank != 0) return rank;
      // Secondary(동순위): 잔여 오름차순 (적을수록 긴급).
      final aR = a.remainingLessons ?? a.daysUntilExpiration ?? 999;
      final bR = b.remainingLessons ?? b.daysUntilExpiration ?? 999;
      return aR.compareTo(bR);
    });
    return sorted.first;
  }

  /// SubscriptionBadge 상태 모델과 동일한 긴급도 순위 (낮을수록 긴급).
  /// 만료 판정은 SubscriptionBadge._isExpired 와 동일 로직으로 정합 유지.
  int _urgencyRank(Subscription s) {
    if (s.isUnpaid) return 0;
    if (s.status == SubscriptionStatus.expired ||
        (s.type == SubscriptionType.monthly &&
            (s.daysUntilExpiration ?? 0) <= 0)) {
      return 1; // 만료
    }
    if (s.isExpiringSoon) return 2;
    return 3;
  }
}

/// Filter enum for class type.
enum ClassTypeFilter {
  all('전체'),
  academy('학원'),
  private('개인');

  final String label;
  const ClassTypeFilter(this.label);
}
