import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../subscription/subscription_facade.dart';
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

/// Mini badge showing subscription remaining count/days.
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
        if (subscriptions.isEmpty) {
          return _buildNoSubscriptionBadge();
        }

        // Get the subscription with lowest remaining (most urgent)
        final urgentSubscription = _getMostUrgentSubscription(subscriptions);
        if (urgentSubscription == null) {
          return _buildNoSubscriptionBadge();
        }

        return _buildSubscriptionBadge(urgentSubscription);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Subscription? _getMostUrgentSubscription(List<Subscription> subscriptions) {
    if (subscriptions.isEmpty) return null;

    // Sort by urgency (expiring soon first, then by remaining)
    final sorted = List<Subscription>.from(subscriptions)..sort((a, b) {
      // Expiring soon first
      if (a.isExpiringSoon && !b.isExpiringSoon) return -1;
      if (!a.isExpiringSoon && b.isExpiringSoon) return 1;

      // Then by remaining count/days
      final aRemaining = a.remainingLessons ?? a.daysUntilExpiration ?? 999;
      final bRemaining = b.remainingLessons ?? b.daysUntilExpiration ?? 999;
      return aRemaining.compareTo(bRemaining);
    });

    return sorted.first;
  }

  Widget _buildNoSubscriptionBadge() {
    return Text(
      '수강권 없음',
      style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
    );
  }

  Widget _buildSubscriptionBadge(Subscription subscription) {
    Color textColor;
    String label;
    IconData? icon;

    // Unpaid takes highest priority
    if (subscription.isUnpaid) {
      textColor = AppColors.paperAccent;
      label = '미수금';
      icon = Icons.warning_amber_rounded;
    } else if (subscription.status == SubscriptionStatus.expired) {
      textColor = AppColors.paperAccent;
      label = '만료됨';
      icon = Icons.warning_amber_rounded;
    } else if (subscription.isExpiringSoon) {
      textColor = AppColors.paperAccent;
      label = _formatBadgeLabel(subscription);
      icon = Icons.access_time;
    } else {
      textColor = AppColors.paperOk;
      label = _formatBadgeLabel(subscription);
    }

    // Clean inline style - icon + text only, no background box
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 2),
        ],
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Format badge label by subscription type.
  /// Package: [used/total], Monthly: 월정액, Trial: 체험중
  String _formatBadgeLabel(Subscription subscription) {
    switch (subscription.type) {
      case SubscriptionType.package:
        final total = subscription.totalLessonsForDisplay ?? 0;
        return '[${subscription.usedLessons}/$total]';
      case SubscriptionType.monthly:
        return '월정액';
      case SubscriptionType.trial:
        return '체험중';
    }
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
