import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../subscription/subscription_facade.dart';
import '../../../../subscription/presentation/widgets/subscription_ticket_card.dart';
import '../../../domain/entities/class_membership.dart';
import '../../providers/lesson_class_providers.dart';
import '../../providers/membership_providers.dart';

/// Section showing student's subscriptions for teacher view.
///
/// When [membershipId] is provided, shows only the subscription for that
/// specific membership (단일 수강 컨텍스트). Otherwise, shows all memberships.
class StudentSubscriptionSection extends ConsumerWidget {
  final String studentId;
  final String? membershipId;

  const StudentSubscriptionSection({
    super.key,
    required this.studentId,
    this.membershipId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membershipsAsync = ref.watch(studentMembershipsProvider(studentId));
    final subscriptionsAsync = ref.watch(
      studentSubscriptionsProvider(studentId),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header (바깥)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('수강권 현황', style: AppTypography.headingMedium),
            TextButton.icon(
              onPressed: () {
                final query =
                    membershipId != null
                        ? '?studentId=$studentId&membershipId=$membershipId'
                        : '?studentId=$studentId';
                context.push('${AppRoutes.issueSubscription}$query');
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('발급'),
            ),
          ],
        ),

        // Status summary (바깥) — 멤버십 필터링 시 숨김
        if (membershipId == null)
          subscriptionsAsync.when(
            data: (subs) => _buildStatusSummary(subs),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        const SizedBox(height: AppSpacing.space3),

        // Content (카드들만)
        membershipsAsync.when(
          data: (memberships) {
            // 멤버십 필터링: membershipId가 있으면 해당 멤버십만
            final filteredMemberships =
                membershipId != null
                    ? memberships.where((m) => m.id == membershipId).toList()
                    : memberships;

            if (filteredMemberships.isEmpty) {
              return _buildEmptyMembershipState(context);
            }

            return subscriptionsAsync.when(
              data:
                  (subscriptions) => _buildContent(
                    context,
                    ref,
                    filteredMemberships,
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
      children:
          memberships.map((membership) {
            // Find subscriptions for this membership, sorted by createdAt desc
            final membershipSubs =
                subscriptions
                    .where((s) => s.membershipId == membership.id)
                    .toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            // Show only the latest (most recent) subscription
            final subscription =
                membershipSubs.isNotEmpty
                    ? membershipSubs.first
                    : _createEmptySubscription(membership);

            if (subscription.id.isEmpty) {
              return _buildNoSubscriptionState(context, membership);
            }

            final lessonClassAsync = ref.watch(
              lessonClassProvider(membership.lessonClassId),
            );
            final className = lessonClassAsync.valueOrNull?.name;

            return SubscriptionTicketCard(
              subscription: subscription,
              className: className,
              instrument: membership.instrument,
              onTap:
                  () => context.push(
                    AppRoutes.subscriptionDetail.replaceFirst(
                      ':id',
                      subscription.id,
                    ),
                    extra: {'viewerRole': 'teacher'},
                  ),
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

  Widget _buildNoSubscriptionState(
    BuildContext context,
    ClassMembership membership,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: AppColors.warning, size: 32),
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
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildStatusSummary(List<Subscription> subscriptions) {
    if (subscriptions.isEmpty) return const SizedBox.shrink();

    final activeCount =
        subscriptions
            .where((s) => s.status == SubscriptionStatus.active)
            .length;
    final expiringCount = subscriptions.where((s) => s.isExpiringSoon).length;
    final expiredCount =
        subscriptions
            .where((s) => s.status == SubscriptionStatus.expired)
            .length;

    final parts = <String>[];
    if (activeCount > 0) parts.add('활성 $activeCount');
    if (expiringCount > 0) parts.add('만료예정 $expiringCount');
    if (expiredCount > 0) parts.add('만료 $expiredCount');

    if (parts.isEmpty) return const SizedBox.shrink();

    return Text(
      parts.join(' · '),
      style: AppTypography.caption.copyWith(color: AppColors.textTertiaryLight),
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
