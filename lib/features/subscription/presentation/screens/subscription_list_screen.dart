import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../../students/domain/entities/class_membership.dart';
import '../../../students/presentation/providers/lesson_class_providers.dart';
import '../../../students/presentation/providers/membership_providers.dart';
import '../../domain/entities/subscription.dart';
import '../providers/subscription_providers.dart';
import '../widgets/subscription_card.dart';

/// Screen showing list of student's subscriptions.
class SubscriptionListScreen extends ConsumerWidget {
  final String? studentId;

  const SubscriptionListScreen({
    super.key,
    this.studentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use provided studentId or get from auth (currentUserIdProvider always returns non-null)
    final String effectiveStudentId = studentId ?? ref.watch(currentUserIdProvider);
    final membershipsAsync = ref.watch(activeStudentMembershipsProvider(effectiveStudentId));
    final subscriptionsAsync = ref.watch(studentSubscriptionsProvider(effectiveStudentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 수강권'),
        centerTitle: true,
      ),
      body: membershipsAsync.when(
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
              effectiveStudentId,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _buildErrorState(error.toString()),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<ClassMembership> memberships,
    List<Subscription> subscriptions,
    String studentId,
  ) {
    // Group subscriptions by status
    final activeSubscriptions = subscriptions
        .where((s) => s.status == SubscriptionStatus.active)
        .toList();
    final expiringSoonSubscriptions = subscriptions
        .where((s) => s.status == SubscriptionStatus.expiringSoon || s.isExpiringSoon)
        .toList();
    final expiredSubscriptions = subscriptions
        .where((s) => s.status == SubscriptionStatus.expired)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        // Active subscriptions
        if (activeSubscriptions.isNotEmpty) ...[
          _buildSectionHeader('이용중인 수강권'),
          const SizedBox(height: AppSpacing.space3),
          ...activeSubscriptions.map((subscription) {
            final membership = memberships.firstWhere(
              (m) => m.id == subscription.membershipId,
              orElse: () => _createPlaceholderMembership(subscription.membershipId),
            );
            return _SubscriptionCardWithClass(
              membership: membership,
              subscription: subscription,
              ref: ref,
              onTap: () => _navigateToDetail(context, subscription.id),
            );
          }),
          const SizedBox(height: AppSpacing.space6),
        ],

        // Expiring soon
        if (expiringSoonSubscriptions.isNotEmpty) ...[
          _buildSectionHeader('만료 임박', color: AppColors.warning),
          const SizedBox(height: AppSpacing.space3),
          ...expiringSoonSubscriptions.map((subscription) {
            final membership = memberships.firstWhere(
              (m) => m.id == subscription.membershipId,
              orElse: () => _createPlaceholderMembership(subscription.membershipId),
            );
            return _SubscriptionCardWithClass(
              membership: membership,
              subscription: subscription,
              ref: ref,
              onTap: () => _navigateToDetail(context, subscription.id),
            );
          }),
          const SizedBox(height: AppSpacing.space6),
        ],

        // Expired
        if (expiredSubscriptions.isNotEmpty) ...[
          _buildSectionHeader('만료된 수강권', color: AppColors.textTertiaryLight),
          const SizedBox(height: AppSpacing.space3),
          ...expiredSubscriptions.map((subscription) {
            final membership = memberships.firstWhere(
              (m) => m.id == subscription.membershipId,
              orElse: () => _createPlaceholderMembership(subscription.membershipId),
            );
            return _SubscriptionCardWithClass(
              membership: membership,
              subscription: subscription,
              ref: ref,
              onTap: () => _navigateToDetail(context, subscription.id),
            );
          }),
        ],

        // Empty sections notice
        if (activeSubscriptions.isEmpty &&
            expiringSoonSubscriptions.isEmpty &&
            expiredSubscriptions.isEmpty) ...[
          _buildNoSubscriptionsState(context, memberships),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, {Color? color}) {
    return Text(
      title,
      style: AppTypography.headingSmall.copyWith(
        color: color ?? AppColors.textPrimaryLight,
      ),
    );
  }

  void _navigateToDetail(BuildContext context, String subscriptionId) {
    context.push(AppRoutes.subscriptionDetail.replaceFirst(':id', subscriptionId));
  }

  ClassMembership _createPlaceholderMembership(String id) {
    return ClassMembership(
      id: id,
      lessonClassId: '',
      studentId: '',
      instrument: '악기',
      status: MembershipStatus.active,
      createdAt: DateTime.now(),
      monthlyFee: 0,
    );
  }

  Widget _buildNoSubscriptionsState(BuildContext context, List<ClassMembership> memberships) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 64,
            color: AppColors.textTertiaryLight,
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            '등록된 수강권이 없습니다',
            style: AppTypography.headingSmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '${memberships.length}개의 레슨에 등록되어 있습니다.\n선생님에게 수강권 발급을 요청하세요.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: AppColors.textTertiaryLight,
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              '등록된 레슨이 없습니다',
              style: AppTypography.headingSmall.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              '선생님에게 초대를 요청하거나\n체험 레슨을 신청하세요.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space6),
            FilledButton.icon(
              onPressed: () => context.push(AppRoutes.selectTeacher),
              icon: const Icon(Icons.search),
              label: const Text('선생님 찾기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.space3),
            Text(
              '오류가 발생했습니다',
              style: AppTypography.headingSmall,
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              error,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Subscription card with lesson class info.
class _SubscriptionCardWithClass extends StatelessWidget {
  final ClassMembership membership;
  final Subscription subscription;
  final WidgetRef ref;
  final VoidCallback? onTap;

  const _SubscriptionCardWithClass({
    required this.membership,
    required this.subscription,
    required this.ref,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lessonClassAsync = ref.watch(lessonClassProvider(membership.lessonClassId));

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
      child: lessonClassAsync.when(
        data: (lessonClass) => SubscriptionCard(
          subscription: subscription,
          className: lessonClass?.name ?? '개인레슨',
          instrument: membership.instrument,
          onTap: onTap,
        ),
        loading: () => SubscriptionCard(
          subscription: subscription,
          className: '...',
          instrument: membership.instrument,
          onTap: onTap,
        ),
        error: (_, __) => SubscriptionCard(
          subscription: subscription,
          className: '레슨',
          instrument: membership.instrument,
          onTap: onTap,
        ),
      ),
    );
  }
}
