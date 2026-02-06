import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../students/domain/entities/class_membership.dart';
import '../../../students/domain/entities/lesson_class.dart';
import '../../../students/presentation/providers/lesson_class_providers.dart';
import '../../../students/presentation/providers/membership_providers.dart';
import '../../../subscription/domain/entities/subscription.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';

/// Widget showing student's subscription summary on dashboard.
class StudentSubscriptionSummary extends ConsumerWidget {
  final String studentId;
  final VoidCallback? onViewAll;

  const StudentSubscriptionSummary({
    super.key,
    required this.studentId,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membershipsAsync = ref.watch(activeStudentMembershipsProvider(studentId));
    final subscriptionsAsync = ref.watch(activeStudentSubscriptionsProvider(studentId));

    return membershipsAsync.when(
      data: (memberships) {
        if (memberships.isEmpty) {
          return _buildEmptyState(context);
        }

        return subscriptionsAsync.when(
          data: (subscriptions) => _buildContent(
            context,
            ref,
            memberships,
            subscriptions,
          ),
          loading: () => _buildLoadingState(),
          error: (_, __) => _buildErrorState(),
        );
      },
      loading: () => _buildLoadingState(),
      error: (_, __) => _buildErrorState(),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<ClassMembership> memberships,
    List<Subscription> subscriptions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('내 수강권', style: AppTypography.headingMedium),
            if (onViewAll != null)
              TextButton(
                onPressed: onViewAll,
                child: const Text('전체 보기'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),

        // Subscription cards
        ...memberships.map((membership) {
          final subscription = subscriptions.firstWhere(
            (s) => s.membershipId == membership.id,
            orElse: () => _createEmptySubscription(membership),
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space3),
            child: _SubscriptionMiniCard(
              membership: membership,
              subscription: subscription,
              onTap: subscription.id.isNotEmpty
                  ? () {
                      context.push(
                        AppRoutes.subscriptionDetail.replaceFirst(':id', subscription.id),
                      );
                    }
                  : null,
            ),
          );
        }),
      ],
    );
  }

  Subscription _createEmptySubscription(ClassMembership membership) {
    return Subscription(
      id: '',
      studentId: studentId,
      membershipId: membership.id,
      type: SubscriptionType.monthly,
      amount: 0,
      status: SubscriptionStatus.expired,
      createdAt: DateTime.now(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 48,
            color: AppColors.textTertiaryLight,
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '등록된 수강권이 없습니다',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            '선생님에게 수강권 발급을 요청하세요',
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Text(
        '수강권 정보를 불러올 수 없습니다',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondaryLight,
        ),
      ),
    );
  }
}

/// Mini card showing subscription info for a membership.
class _SubscriptionMiniCard extends ConsumerWidget {
  final ClassMembership membership;
  final Subscription subscription;
  final VoidCallback? onTap;

  const _SubscriptionMiniCard({
    required this.membership,
    required this.subscription,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get lesson class info
    final lessonClassAsync = ref.watch(lessonClassProvider(membership.lessonClassId));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: subscription.isExpiringSoon
                ? AppColors.warning
                : AppColors.borderLight,
            width: subscription.isExpiringSoon ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Class type icon
            lessonClassAsync.when(
              data: (lessonClass) => _buildClassIcon(lessonClass),
              loading: () => _buildClassIconPlaceholder(),
              error: (_, __) => _buildClassIconPlaceholder(),
            ),
            const SizedBox(width: AppSpacing.space3),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Class name and instrument
                  Row(
                    children: [
                      lessonClassAsync.when(
                        data: (lessonClass) => Text(
                          lessonClass?.icon ?? '👤',
                          style: const TextStyle(fontSize: 14),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: lessonClassAsync.when(
                          data: (lessonClass) => Text(
                            lessonClass?.name ?? '개인레슨',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          loading: () => const Text('...'),
                          error: (_, __) => const Text('레슨'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${membership.instrument} · ${membership.level ?? ''}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),

            // Subscription status
            _buildSubscriptionBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildClassIcon(LessonClass? lessonClass) {
    final isAcademy = lessonClass?.type == LessonClassType.academy;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: (isAcademy ? AppColors.info : AppColors.primary)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Center(
        child: Text(
          isAcademy ? '🏫' : '👤',
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  Widget _buildClassIconPlaceholder() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
    );
  }

  Widget _buildSubscriptionBadge() {
    if (subscription.id.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space2,
          vertical: AppSpacing.space1,
        ),
        decoration: BoxDecoration(
          color: AppColors.textTertiaryLight.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        ),
        child: Text(
          '미등록',
          style: AppTypography.caption.copyWith(
            color: AppColors.textTertiaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    Color backgroundColor;
    Color textColor;

    if (subscription.status == SubscriptionStatus.expired) {
      backgroundColor = AppColors.error.withValues(alpha: 0.1);
      textColor = AppColors.error;
    } else if (subscription.isExpiringSoon) {
      backgroundColor = AppColors.warning.withValues(alpha: 0.1);
      textColor = AppColors.warning;
    } else {
      backgroundColor = AppColors.success.withValues(alpha: 0.1);
      textColor = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Text(
        subscription.summaryText,
        style: AppTypography.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
