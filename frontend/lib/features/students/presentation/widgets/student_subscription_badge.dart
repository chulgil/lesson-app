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
    final sorted = List<Subscription>.from(subscriptions)
      ..sort((a, b) {
        // Primary: 공유 긴급도 모델(badgeUrgency) — enum 순서 = 우선순위
        // (미수금>만료>임박>정상). SubscriptionBadge 와 단일 SSOT 공유.
        final rank = a.badgeUrgency.index.compareTo(b.badgeUrgency.index);
        if (rank != 0) return rank;
        // Secondary(동순위): 잔여 오름차순 (적을수록 긴급).
        final aR = a.remainingLessons ?? a.daysUntilExpiration ?? 999;
        final bR = b.remainingLessons ?? b.daysUntilExpiration ?? 999;
        return aR.compareTo(bR);
      });
    return sorted.first;
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
