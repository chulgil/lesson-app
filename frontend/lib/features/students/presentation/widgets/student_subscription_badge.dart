import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../subscription/subscription_facade.dart';
import '../../../subscription/subscription_ui_facade.dart';
import '../providers/lesson_class_providers.dart';
import '../providers/membership_providers.dart';

/// Badge showing student's class type - simplified, subtle design.
class StudentClassBadge extends ConsumerWidget {
  final String studentId;

  const StudentClassBadge({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membershipsAsync = ref.watch(
      activeStudentMembershipsProvider(studentId),
    );

    return membershipsAsync.when(
      data: (memberships) {
        if (memberships.isEmpty) {
          return const SizedBox.shrink();
        }

        // Get the primary (first) membership
        final membership = memberships.first;
        final lessonClassAsync = ref.watch(
          lessonClassProvider(membership.lessonClassId),
        );

        return lessonClassAsync.when(
          data: (lessonClass) {
            final isAcademy =
                lessonClass?.type.toString().contains('academy') ?? false;
            // Subtle text-only badge with neutral background
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppColors.paperDark),
              child: Text(
                isAcademy ? '학원' : '개인',
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.inkSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

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
      if (a.isExpiringSoon && !b.isExpiringSoon) return -1;
      if (!a.isExpiringSoon && b.isExpiringSoon) return 1;
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
