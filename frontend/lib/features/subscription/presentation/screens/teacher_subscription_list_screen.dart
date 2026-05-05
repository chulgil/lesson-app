import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/auth_facade.dart';
import '../../../schedule/schedule_facade.dart';
import '../../../students/students_facade.dart';
import '../../domain/entities/subscription.dart';
import '../providers/subscription_providers.dart';
import '../widgets/subscription_card.dart';

/// Teacher's full subscription list with status filter tabs.
class TeacherSubscriptionListScreen extends ConsumerStatefulWidget {
  const TeacherSubscriptionListScreen({super.key});

  @override
  ConsumerState<TeacherSubscriptionListScreen> createState() =>
      _TeacherSubscriptionListScreenState();
}

class _TeacherSubscriptionListScreenState
    extends ConsumerState<TeacherSubscriptionListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    _TabConfig(AppStrings.statusActive, null),
    _TabConfig(AppStrings.statusExpiringSoon, SubscriptionStatus.expiringSoon),
    _TabConfig(AppStrings.statusExpired, SubscriptionStatus.expired),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teacherId = ref.watch(currentUserIdProvider);
    final subscriptionsAsync = ref.watch(
      teacherStudentSubscriptionsProvider(teacherId),
    );

    return NotebookScreenScaffold(
      appBar: AppBar(
        title: Text(AppStrings.issuedSubscriptions),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: subscriptionsAsync.when(
            data:
                (subs) =>
                    _tabs.map((tab) {
                      final count = _filterByTab(subs, tab).length;
                      return Tab(text: '${tab.label} ($count)');
                    }).toList(),
            loading: () => _tabs.map((tab) => Tab(text: tab.label)).toList(),
            error: (_, __) => _tabs.map((tab) => Tab(text: tab.label)).toList(),
          ),
          labelColor: AppColors.paperAccent,
          unselectedLabelColor: AppColors.inkSecondary,
          indicatorColor: AppColors.paperAccent,
        ),
      ),
      body: subscriptionsAsync.when(
        data:
            (subscriptions) => TabBarView(
              controller: _tabController,
              children:
                  _tabs.map((tab) {
                    final filtered = _filterByTab(subscriptions, tab);
                    if (filtered.isEmpty) return _buildEmptyState(tab.label);
                    return _buildList(filtered);
                  }).toList(),
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, _) => Center(
              child: Text(
                AppStrings.errorOccurred,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ),
      ),
    );
  }

  List<Subscription> _filterByTab(List<Subscription> all, _TabConfig tab) {
    if (tab.status == null) {
      return all
          .where(
            (s) =>
                s.status == SubscriptionStatus.active ||
                s.status == SubscriptionStatus.expiringSoon,
          )
          .toList();
    }
    if (tab.status == SubscriptionStatus.expiringSoon) {
      return all
          .where(
            (s) =>
                s.status == SubscriptionStatus.expiringSoon || s.isExpiringSoon,
          )
          .toList();
    }
    return all.where((s) => s.status == tab.status).toList();
  }

  Widget _buildList(List<Subscription> subscriptions) {
    final studentNames = ref.watch(studentNameMapProvider);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
      itemCount: subscriptions.length,
      itemBuilder: (context, index) {
        final subscription = subscriptions[index];
        final membershipAsync = ref.watch(
          membershipProvider(subscription.membershipId),
        );

        return membershipAsync.when(
          data: (membership) {
            final instrument = membership?.instrument;
            final lessonClassAsync =
                membership != null
                    ? ref.watch(lessonClassProvider(membership.lessonClassId))
                    : null;
            final studentName = studentNames[subscription.studentId];

            return SubscriptionCard(
              compact: true,
              subscription: subscription,
              className: lessonClassAsync?.valueOrNull?.name,
              instrument: instrument,
              personName: studentName,
              onTap:
                  () => context.push(
                    AppRoutes.subscriptionDetail.replaceFirst(
                      ':id',
                      subscription.id,
                    ),
                    extra: {'viewerRole': 'teacher'},
                  ),
            );
          },
          loading:
              () => SubscriptionCard(
                compact: true,
                subscription: subscription,
                onTap:
                    () => context.push(
                      AppRoutes.subscriptionDetail.replaceFirst(
                        ':id',
                        subscription.id,
                      ),
                      extra: {'viewerRole': 'teacher'},
                    ),
              ),
          error:
              (_, __) => SubscriptionCard(
                compact: true,
                subscription: subscription,
                onTap:
                    () => context.push(
                      AppRoutes.subscriptionDetail.replaceFirst(
                        ':id',
                        subscription.id,
                      ),
                      extra: {'viewerRole': 'teacher'},
                    ),
              ),
        );
      },
    );
  }

  Widget _buildEmptyState(String tabLabel) {
    return Center(
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
            AppStrings.noSubscriptionsForStatus(tabLabel),
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabConfig {
  final String label;
  final SubscriptionStatus? status;

  const _TabConfig(this.label, this.status);
}
