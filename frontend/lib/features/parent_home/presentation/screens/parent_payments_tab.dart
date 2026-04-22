import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../../students/domain/entities/class_membership.dart';
import '../../../students/presentation/providers/lesson_class_providers.dart';
import '../../../students/presentation/providers/membership_providers.dart';
import '../../../subscription/domain/entities/subscription.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../../../subscription/presentation/widgets/subscription_ticket_card.dart';
import '../../domain/entities/child_profile.dart';
import '../providers/child_profile_provider.dart';
import 'parent_dashboard_tab.dart';

/// Parent's per-child subscription / payment status view.
///
/// Lists subscriptions of the currently selected child, grouped by status.
/// Reuses [SubscriptionTicketCard] — this tab is a parent-scoped read view,
/// not a separate data model.
class ParentPaymentsTab extends ConsumerWidget {
  const ParentPaymentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentId = ref.watch(currentUserIdProvider);
    final selectedProfile = ref.watch(selectedChildProfileProvider);
    final childrenAsync = ref.watch(childProfilesProvider(parentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('결제·수강권'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showChildSelector(context, ref, parentId),
            icon: const Icon(Icons.swap_horiz),
            tooltip: '자녀 전환',
          ),
        ],
      ),
      body: childrenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('오류가 발생했습니다.')),
        data: (profiles) {
          if (profiles.isEmpty) {
            return const _EmptyChildrenState();
          }
          final profile = selectedProfile ?? profiles.first;
          return _ChildSubscriptionsView(profile: profile);
        },
      ),
    );
  }

  void _showChildSelector(
    BuildContext context,
    WidgetRef ref,
    String parentId,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final childrenAsync = ref.read(childProfilesProvider(parentId));
        return childrenAsync.when(
          data: (profiles) => _ChildSelectorSheet(profiles: profiles),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }
}

class _ChildSubscriptionsView extends ConsumerWidget {
  const _ChildSubscriptionsView({required this.profile});

  final ChildProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linkedStudentId = profile.linkedStudentId;
    if (linkedStudentId == null) {
      return _UnlinkedChildState(profile: profile);
    }

    final membershipsAsync = ref.watch(
      activeStudentMembershipsProvider(linkedStudentId),
    );
    final subscriptionsAsync = ref.watch(
      studentSubscriptionsProvider(linkedStudentId),
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(studentSubscriptionsProvider(linkedStudentId));
        ref.invalidate(activeStudentMembershipsProvider(linkedStudentId));
      },
      child: membershipsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(message: error.toString()),
        data:
            (memberships) => subscriptionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorState(message: error.toString()),
              data:
                  (subscriptions) => _SubscriptionList(
                    profile: profile,
                    memberships: memberships,
                    subscriptions: subscriptions,
                  ),
            ),
      ),
    );
  }
}

class _SubscriptionList extends StatelessWidget {
  const _SubscriptionList({
    required this.profile,
    required this.memberships,
    required this.subscriptions,
  });

  final ChildProfile profile;
  final List<ClassMembership> memberships;
  final List<Subscription> subscriptions;

  @override
  Widget build(BuildContext context) {
    final active =
        subscriptions
            .where((s) => s.status == SubscriptionStatus.active)
            .toList();
    final expiring =
        subscriptions
            .where(
              (s) =>
                  s.status == SubscriptionStatus.expiringSoon ||
                  s.isExpiringSoon,
            )
            .toList();
    final expired =
        subscriptions
            .where((s) => s.status == SubscriptionStatus.expired)
            .toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.screenPadding),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _ChildSummaryHeader(profile: profile),
        const SizedBox(height: AppSpacing.space4),
        _SummaryStats(
          activeCount: active.length,
          expiringCount: expiring.length,
          expiredCount: expired.length,
        ),
        const SizedBox(height: AppSpacing.space5),
        if (active.isNotEmpty) ...[
          _SectionHeader(title: AppStrings.summaryActive),
          const SizedBox(height: AppSpacing.space2),
          ...active.map((s) => _buildCard(context, s)),
          const SizedBox(height: AppSpacing.space5),
        ],
        if (expiring.isNotEmpty) ...[
          _SectionHeader(
            title: AppStrings.statusExpiringSoon,
            color: AppColors.paperAccent,
          ),
          const SizedBox(height: AppSpacing.space2),
          ...expiring.map((s) => _buildCard(context, s)),
          const SizedBox(height: AppSpacing.space5),
        ],
        if (expired.isNotEmpty) ...[
          _SectionHeader(
            title: AppStrings.statusExpired,
            color: AppColors.inkTertiary,
          ),
          const SizedBox(height: AppSpacing.space2),
          ...expired.map((s) => _buildCard(context, s)),
        ],
        if (subscriptions.isEmpty) const _NoSubscriptionsState(),
      ],
    );
  }

  Widget _buildCard(BuildContext context, Subscription subscription) {
    final membership = memberships.firstWhere(
      (m) => m.id == subscription.membershipId,
      orElse:
          () => ClassMembership(
            id: subscription.membershipId,
            lessonClassId: '',
            studentId: subscription.studentId,
            instrument: profile.instrument,
            status: MembershipStatus.active,
            createdAt: DateTime.now(),
            monthlyFee: 0,
          ),
    );
    return _MembershipSubscriptionCard(
      membership: membership,
      subscription: subscription,
      personName: profile.name,
      onTap:
          () => context.push(
            AppRoutes.subscriptionDetail.replaceFirst(':id', subscription.id),
          ),
    );
  }
}

class _MembershipSubscriptionCard extends ConsumerWidget {
  const _MembershipSubscriptionCard({
    required this.membership,
    required this.subscription,
    required this.personName,
    required this.onTap,
  });

  final ClassMembership membership;
  final Subscription subscription;
  final String personName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonClassAsync = ref.watch(
      lessonClassProvider(membership.lessonClassId),
    );
    return lessonClassAsync.when(
      data:
          (lessonClass) => SubscriptionTicketCard(
            subscription: subscription,
            className: lessonClass?.name ?? '개인레슨',
            instrument: membership.instrument,
            personName: personName,
            onTap: onTap,
          ),
      loading:
          () => SubscriptionTicketCard(
            subscription: subscription,
            className: '...',
            instrument: membership.instrument,
            personName: personName,
            onTap: onTap,
          ),
      error:
          (_, __) => SubscriptionTicketCard(
            subscription: subscription,
            className: '레슨',
            instrument: membership.instrument,
            personName: personName,
            onTap: onTap,
          ),
    );
  }
}

class _ChildSummaryHeader extends StatelessWidget {
  const _ChildSummaryHeader({required this.profile});

  final ChildProfile profile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: profile.profileColor,
            child: Text(
              profile.initial,
              style: AppTypography.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.name, style: AppTypography.headingSmall),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  '${profile.instrumentLabel} · ${profile.levelLabel}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStats extends StatelessWidget {
  const _SummaryStats({
    required this.activeCount,
    required this.expiringCount,
    required this.expiredCount,
  });

  final int activeCount;
  final int expiringCount;
  final int expiredCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: AppStrings.summaryActive,
              count: activeCount,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: _StatCard(
              label: AppStrings.statusExpiringSoon,
              count: expiringCount,
              color: AppColors.paperAccent,
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: _StatCard(
              label: AppStrings.statusExpired,
              count: expiredCount,
              color: AppColors.inkTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.color});

  final String title;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Text(
        title,
        style: AppTypography.headingSmall.copyWith(
          color: color ?? AppColors.ink,
        ),
      ),
    );
  }
}

class _ChildSelectorSheet extends ConsumerWidget {
  const _ChildSelectorSheet({required this.profiles});

  final List<ChildProfile> profiles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.4,
      minChildSize: 0.3,
      maxChildSize: 0.7,
      builder:
          (context, controller) => Container(
            decoration: const BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const BottomSheetHandle(
                  margin: EdgeInsets.symmetric(vertical: AppSpacing.space3),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  child: Text('자녀 선택', style: AppTypography.headingSmall),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: profiles.length,
                    itemBuilder: (_, i) {
                      final p = profiles[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: p.profileColor,
                          child: Text(
                            p.initial,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(p.name),
                        subtitle: Text(
                          '${p.instrumentLabel} · ${p.levelLabel}',
                        ),
                        onTap: () {
                          ref
                              .read(selectedChildProfileProvider.notifier)
                              .select(p);
                          ref.read(selectedChildIdProvider.notifier).state =
                              p.id;
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

class _EmptyChildrenState extends StatelessWidget {
  const _EmptyChildrenState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.child_care_outlined,
              size: 64,
              color: AppColors.inkTertiary,
            ),
            const SizedBox(height: AppSpacing.space3),
            Text(
              '등록된 자녀가 없습니다',
              style: AppTypography.headingSmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnlinkedChildState extends StatelessWidget {
  const _UnlinkedChildState({required this.profile});

  final ChildProfile profile;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.link_off,
              size: 56,
              color: AppColors.inkTertiary,
            ),
            const SizedBox(height: AppSpacing.space3),
            Text(
              '${profile.name}은(는) 아직 선생님과 연결되지 않았습니다',
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              '선생님 연결 후 수강권 정보가 표시됩니다',
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: AppColors.inkTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoSubscriptionsState extends StatelessWidget {
  const _NoSubscriptionsState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space6),
      child: Column(
        children: [
          const Icon(
            Icons.confirmation_number_outlined,
            size: 56,
            color: AppColors.inkTertiary,
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            '등록된 수강권이 없습니다',
            style: AppTypography.headingSmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '선생님에게 수강권 발급을 요청하세요',
            style: AppTypography.caption.copyWith(
              color: AppColors.inkTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.paperAccent),
            const SizedBox(height: AppSpacing.space2),
            Text('오류가 발생했습니다', style: AppTypography.headingSmall),
            const SizedBox(height: AppSpacing.space2),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
