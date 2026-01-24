import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../subscription/domain/entities/subscription.dart';
import '../../../../subscription/presentation/providers/subscription_providers.dart';
import '../../../../subscription/presentation/widgets/subscription_badge.dart';
import '../../../domain/entities/class_membership.dart';
import '../../providers/lesson_class_providers.dart';
import '../../providers/membership_providers.dart';

/// Section showing student's subscriptions for teacher view.
class StudentSubscriptionSection extends ConsumerWidget {
  final String studentId;

  const StudentSubscriptionSection({
    super.key,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membershipsAsync = ref.watch(studentMembershipsProvider(studentId));
    final subscriptionsAsync = ref.watch(studentSubscriptionsProvider(studentId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('수강권 현황', style: AppTypography.headingMedium),
            TextButton.icon(
              onPressed: () {
                context.push('${AppRoutes.issueSubscription}?studentId=$studentId');
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('발급'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),

        // Content
        membershipsAsync.when(
          data: (memberships) {
            if (memberships.isEmpty) {
              return _buildEmptyMembershipState(context);
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
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<ClassMembership> memberships,
    List<Subscription> subscriptions,
  ) {
    if (subscriptions.isEmpty) {
      return _buildNoSubscriptionState(context, memberships.first);
    }

    return Column(
      children: memberships.map((membership) {
        // Find subscription for this membership
        final subscription = subscriptions.firstWhere(
          (s) => s.membershipId == membership.id,
          orElse: () => _createEmptySubscription(membership),
        );

        return _SubscriptionMembershipCard(
          membership: membership,
          subscription: subscription,
          studentId: studentId,
        );
      }).toList(),
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

  Widget _buildEmptyMembershipState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(
            Icons.school_outlined,
            size: 40,
            color: AppColors.textTertiaryLight,
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '레슨 등록이 필요합니다',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            '학생을 레슨에 등록한 후 수강권을 발급할 수 있습니다',
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoSubscriptionState(BuildContext context, ClassMembership membership) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber,
            color: AppColors.warning,
            size: 32,
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '수강권 미등록',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
                Text(
                  '학생에게 수강권을 발급해주세요',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () {
              context.push(
                '${AppRoutes.issueSubscription}?studentId=$studentId&membershipId=${membership.id}',
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.warning,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space4,
                vertical: AppSpacing.space2,
              ),
            ),
            child: const Text('발급'),
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
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
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
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
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

/// Card showing membership with subscription status.
class _SubscriptionMembershipCard extends ConsumerWidget {
  final ClassMembership membership;
  final Subscription subscription;
  final String studentId;

  const _SubscriptionMembershipCard({
    required this.membership,
    required this.subscription,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonClassAsync = ref.watch(lessonClassProvider(membership.lessonClassId));
    final hasSubscription = subscription.id.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
      child: GestureDetector(
        onTap: hasSubscription
            ? () => context.push(
                  AppRoutes.subscriptionDetail.replaceFirst(':id', subscription.id),
                )
            : null,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space4),
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
          child: Column(
            children: [
              // Header row
              Row(
                children: [
                  // Class icon
                  lessonClassAsync.when(
                    data: (lessonClass) {
                      final isAcademy =
                          lessonClass?.type.toString().contains('academy') ?? false;
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
                    },
                    loading: () => Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondaryLight,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                      ),
                    ),
                    error: (_, __) => Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondaryLight,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                      ),
                      child: const Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),

                  // Class info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        lessonClassAsync.when(
                          data: (lessonClass) => Text(
                            lessonClass?.name ?? '개인레슨',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          loading: () => const Text('...'),
                          error: (_, __) => const Text('레슨'),
                        ),
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
                  if (hasSubscription)
                    SubscriptionBadge(subscription: subscription)
                  else
                    _buildNoSubscriptionBadge(context),
                ],
              ),

              // Subscription details (if exists)
              if (hasSubscription) ...[
                const SizedBox(height: AppSpacing.space3),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.space3),
                _buildSubscriptionDetails(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoSubscriptionBadge(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push(
          '${AppRoutes.issueSubscription}?studentId=$studentId&membershipId=${membership.id}',
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space2,
          vertical: AppSpacing.space1,
        ),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14, color: AppColors.warning),
            const SizedBox(width: 2),
            Text(
              '발급 필요',
              style: AppTypography.caption.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionDetails() {
    return Row(
      children: [
        // Type label
        _buildDetailItem(
          icon: Icons.confirmation_number_outlined,
          label: subscription.typeLabel,
        ),
        const SizedBox(width: AppSpacing.space4),

        // Status/remaining
        if (subscription.type == SubscriptionType.package)
          _buildDetailItem(
            icon: Icons.check_circle_outline,
            label: '${subscription.remainingLessons}/${subscription.totalLessons}회 남음',
            color: subscription.isExpiringSoon
                ? AppColors.warning
                : AppColors.success,
          )
        else if (subscription.type == SubscriptionType.monthly)
          _buildDetailItem(
            icon: Icons.calendar_today,
            label: subscription.daysUntilExpiration != null
                ? 'D-${subscription.daysUntilExpiration}'
                : '만료됨',
            color: subscription.isExpiringSoon
                ? AppColors.warning
                : AppColors.success,
          )
        else
          _buildDetailItem(
            icon: Icons.star,
            label: '체험중',
            color: AppColors.info,
          ),
      ],
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    final effectiveColor = color ?? AppColors.textSecondaryLight;
    return Row(
      children: [
        Icon(icon, size: 14, color: effectiveColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: effectiveColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
