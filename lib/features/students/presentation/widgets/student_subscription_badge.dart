import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../subscription/domain/entities/subscription.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../providers/lesson_class_providers.dart';
import '../providers/membership_providers.dart';

/// Badge showing student's class type and subscription status.
class StudentClassBadge extends ConsumerWidget {
  final String studentId;

  const StudentClassBadge({
    super.key,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membershipsAsync = ref.watch(activeStudentMembershipsProvider(studentId));

    return membershipsAsync.when(
      data: (memberships) {
        if (memberships.isEmpty) {
          return const SizedBox.shrink();
        }

        // Get the primary (first) membership
        final membership = memberships.first;
        final lessonClassAsync = ref.watch(lessonClassProvider(membership.lessonClassId));

        return lessonClassAsync.when(
          data: (lessonClass) {
            final isAcademy = lessonClass?.type.toString().contains('academy') ?? false;
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: (isAcademy ? AppColors.info : AppColors.primary)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isAcademy ? '🏫' : '👤',
                    style: const TextStyle(fontSize: 10),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    isAcademy ? '학원' : '개인',
                    style: AppTypography.caption.copyWith(
                      color: isAcademy ? AppColors.info : AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ],
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

  const StudentSubscriptionMiniBadge({
    super.key,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(activeStudentSubscriptionsProvider(studentId));

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
    final sorted = List<Subscription>.from(subscriptions)
      ..sort((a, b) {
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.textTertiaryLight.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '미등록',
        style: AppTypography.caption.copyWith(
          color: AppColors.textTertiaryLight,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildSubscriptionBadge(Subscription subscription) {
    Color backgroundColor;
    Color textColor;
    String label;

    if (subscription.status == SubscriptionStatus.expired) {
      backgroundColor = AppColors.error.withValues(alpha: 0.15);
      textColor = AppColors.error;
      label = '만료';
    } else if (subscription.isExpiringSoon) {
      backgroundColor = AppColors.warning.withValues(alpha: 0.15);
      textColor = AppColors.warning;
      if (subscription.type == SubscriptionType.package) {
        label = '${subscription.remainingLessons}회';
      } else {
        label = 'D-${subscription.daysUntilExpiration}';
      }
    } else {
      backgroundColor = AppColors.success.withValues(alpha: 0.15);
      textColor = AppColors.success;
      if (subscription.type == SubscriptionType.package) {
        label = '${subscription.remainingLessons}회';
      } else if (subscription.type == SubscriptionType.monthly) {
        label = 'D-${subscription.daysUntilExpiration}';
      } else {
        label = '체험';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
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
