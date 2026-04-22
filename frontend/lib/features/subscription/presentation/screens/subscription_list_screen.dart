import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../../students/domain/entities/class_membership.dart';
import '../../../students/presentation/providers/lesson_class_providers.dart';
import '../../../students/presentation/providers/membership_providers.dart';
import '../../domain/entities/subscription.dart';
import '../providers/subscription_providers.dart';
import '../widgets/subscription_ticket_card.dart';

/// Screen showing list of student's subscriptions.
class SubscriptionListScreen extends ConsumerWidget {
  final String? studentId;

  const SubscriptionListScreen({super.key, this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use provided studentId or get from auth (currentUserIdProvider always returns non-null)
    final String effectiveStudentId =
        studentId ?? ref.watch(currentUserIdProvider);
    final membershipsAsync = ref.watch(
      activeStudentMembershipsProvider(effectiveStudentId),
    );
    final subscriptionsAsync = ref.watch(
      studentSubscriptionsProvider(effectiveStudentId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('내 수강권'), centerTitle: true),
      body: membershipsAsync.when(
        data: (memberships) {
          if (memberships.isEmpty) {
            return _buildEmptyState(context);
          }

          return subscriptionsAsync.when(
            data:
                (subscriptions) => _buildContent(
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
    final activeSubscriptions =
        subscriptions
            .where((s) => s.status == SubscriptionStatus.active)
            .toList();
    final expiringSoonSubscriptions =
        subscriptions
            .where(
              (s) =>
                  s.status == SubscriptionStatus.expiringSoon ||
                  s.isExpiringSoon,
            )
            .toList();
    final expiredSubscriptions =
        subscriptions
            .where((s) => s.status == SubscriptionStatus.expired)
            .toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.screenPadding),
      children: [
        // Summary stat cards
        _buildSummarySection(
          activeCount: activeSubscriptions.length,
          expiringCount: expiringSoonSubscriptions.length,
          expiredCount: expiredSubscriptions.length,
        ),
        const SizedBox(height: AppSpacing.space4),

        // Pending requests section
        _buildPendingSection(ref, studentId),

        // Active subscriptions
        if (activeSubscriptions.isNotEmpty) ...[
          _buildSectionHeader(AppStrings.summaryActive),
          const SizedBox(height: AppSpacing.space3),
          ...activeSubscriptions.map((subscription) {
            final membership = memberships.firstWhere(
              (m) => m.id == subscription.membershipId,
              orElse:
                  () => _createPlaceholderMembership(subscription.membershipId),
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
          _buildSectionHeader(
            AppStrings.statusExpiringSoon,
            color: AppColors.paperAccent,
          ),
          const SizedBox(height: AppSpacing.space3),
          ...expiringSoonSubscriptions.map((subscription) {
            final membership = memberships.firstWhere(
              (m) => m.id == subscription.membershipId,
              orElse:
                  () => _createPlaceholderMembership(subscription.membershipId),
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
          _buildSectionHeader(
            AppStrings.statusExpired,
            color: AppColors.inkTertiary,
          ),
          const SizedBox(height: AppSpacing.space3),
          ...expiredSubscriptions.map((subscription) {
            final membership = memberships.firstWhere(
              (m) => m.id == subscription.membershipId,
              orElse:
                  () => _createPlaceholderMembership(subscription.membershipId),
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

  Widget _buildSummarySection({
    required int activeCount,
    required int expiringCount,
    required int expiredCount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        children: [
          Expanded(
            child: _SummaryStatCard(
              label: AppStrings.summaryActive,
              count: activeCount,
              color: AppColors.paperAccent,
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: _SummaryStatCard(
              label: AppStrings.statusExpiringSoon,
              count: expiringCount,
              color: AppColors.paperAccent,
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: _SummaryStatCard(
              label: AppStrings.statusExpired,
              count: expiredCount,
              color: AppColors.inkTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingSection(WidgetRef ref, String studentId) {
    final pendingAsync = ref.watch(
      pendingScheduleChangeRequestsProvider(studentId),
    );

    return pendingAsync.when(
      data: (requests) {
        if (requests.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.screenPadding,
            right: AppSpacing.screenPadding,
            bottom: AppSpacing.space4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.pendingRequests,
                style: AppTypography.headingSmall,
              ),
              const SizedBox(height: AppSpacing.space2),
              ...requests.map(
                (r) => Card(
                  child: ListTile(
                    leading: Icon(Icons.schedule, color: AppColors.paperAccent),
                    title: Text(
                      r.message ?? AppStrings.pendingRequests,
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSectionHeader(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      // Notebook × Score: 페이지 섹션 제목은 Playfair sectionTitle 로 통일 (§7.17 패턴).
      // color 파라미터는 상태별 강조(expiringSoon=Vermillion, expired=inkTertiary)를 보존하기 위해 그대로 유지.
      child: Text(
        title,
        style: NotebookTypography.sectionTitle.copyWith(
          color: color ?? AppColors.ink,
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, String subscriptionId) {
    context.push(
      AppRoutes.subscriptionDetail.replaceFirst(':id', subscriptionId),
    );
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

  Widget _buildNoSubscriptionsState(
    BuildContext context,
    List<ClassMembership> memberships,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 64,
            color: AppColors.inkTertiary,
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            '등록된 수강권이 없습니다',
            style: AppTypography.headingSmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '${memberships.length}개의 레슨에 등록되어 있습니다.\n선생님에게 수강권 발급을 요청하세요.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkTertiary,
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
            Icon(Icons.school_outlined, size: 64, color: AppColors.inkTertiary),
            const SizedBox(height: AppSpacing.space4),
            Text(
              '등록된 레슨이 없습니다',
              style: AppTypography.headingSmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              '선생님에게 초대를 요청하거나\n체험 레슨을 신청하세요.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space6),
            FilledButton.icon(
              onPressed: () => context.push(AppRoutes.teacherSearch),
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
            Icon(Icons.error_outline, size: 48, color: AppColors.paperAccent),
            const SizedBox(height: AppSpacing.space3),
            Text('오류가 발생했습니다', style: AppTypography.headingSmall),
            const SizedBox(height: AppSpacing.space2),
            Text(
              error,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
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
    final lessonClassAsync = ref.watch(
      lessonClassProvider(membership.lessonClassId),
    );

    return lessonClassAsync.when(
      data:
          (lessonClass) => SubscriptionTicketCard(
            subscription: subscription,
            className: lessonClass?.name ?? '개인레슨',
            instrument: membership.instrument,
            onTap: onTap,
          ),
      loading:
          () => SubscriptionTicketCard(
            subscription: subscription,
            className: '...',
            instrument: membership.instrument,
            onTap: onTap,
          ),
      error:
          (_, __) => SubscriptionTicketCard(
            subscription: subscription,
            className: '레슨',
            instrument: membership.instrument,
            onTap: onTap,
          ),
    );
  }
}

/// Summary stat card for subscription count by status.
class _SummaryStatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SummaryStatCard({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.space3),
      ),
      child: Column(
        children: [
          Text(label, style: AppTypography.caption.copyWith(color: color)),
          const SizedBox(height: AppSpacing.space1),
          Text(
            '$count',
            style: AppTypography.headingLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
