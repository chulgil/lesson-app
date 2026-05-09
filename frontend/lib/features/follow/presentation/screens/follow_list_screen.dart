// Follow list screen with tabs for all/teachers/academies.

import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../auth/auth_facade.dart';
import '../../domain/entities/follow.dart';
import '../../domain/entities/follow_target_type.dart';
import '../providers/follow_providers.dart';
import '../widgets/follow_card.dart';

/// Follow list screen with filter tabs.
class FollowListScreen extends ConsumerWidget {
  const FollowListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);

    return DefaultTabController(
      length: 3,
      child: NotebookScreenScaffold(
        appBar: const NotebookDetailAppBar(
          title: AppStrings.followTitle,
          bottom: TabBar(
            labelColor: AppColors.paperAccent,
            unselectedLabelColor: AppColors.inkSecondary,
            indicatorColor: AppColors.paperAccent,
            tabs: [Tab(text: AppStrings.followTabAll), Tab(text: AppStrings.teacher), Tab(text: AppStrings.followTabAcademy)],
          ),
        ),
        body: TabBarView(
          children: [
            _FollowTab(userId: userId),
            _FollowTab(userId: userId, filterType: FollowTargetType.teacher),
            _FollowTab(userId: userId, filterType: FollowTargetType.academy),
          ],
        ),
      ),
    );
  }
}

class _FollowTab extends ConsumerWidget {
  final String userId;
  final FollowTargetType? filterType;

  const _FollowTab({required this.userId, this.filterType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followsAsync =
        filterType == null
            ? ref.watch(userFollowingProvider(userId))
            : filterType == FollowTargetType.teacher
            ? ref.watch(followedTeachersProvider(userId))
            : ref.watch(followedAcademiesProvider(userId));

    return followsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text(AppStrings.errorOccurred)),
      data: (follows) {
        if (follows.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.person_add_outlined,
            title:
                filterType == null
                    ? AppStrings.followEmptyAll
                    : filterType == FollowTargetType.teacher
                    ? AppStrings.followEmptyTeacher
                    : AppStrings.followEmptyAcademy,
            subtitle: AppStrings.followEmptySubtitle,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          itemCount: follows.length,
          separatorBuilder:
              (_, __) => const SizedBox(height: AppSpacing.space2),
          itemBuilder: (context, index) {
            return FollowCard(
              follow: follows[index],
              onUnfollow: () => _handleUnfollow(context, ref, follows[index]),
              onToggleNotification:
                  () => _handleToggleNotification(ref, follows[index]),
            );
          },
        );
      },
    );
  }

  Future<void> _handleUnfollow(
    BuildContext context,
    WidgetRef ref,
    Follow follow,
  ) async {
    final confirmed = await showNotebookDialog<bool>(
      context: context,
      title: AppStrings.followCancelTitle,
      content: Text('${follow.followingId}의 팔로우를 취소하시겠습니까?'),
      confirmLabel: AppStrings.followCancelConfirmLabel,
      cancelLabel: AppStrings.cancel,
      isDestructive: true,
      onConfirm: () => Navigator.pop(context, true),
      onCancel: () => Navigator.pop(context, false),
    );

    if (confirmed == true) {
      final repo = ref.read(followRepositoryProvider);
      await repo.unfollow(follow.followerId, follow.followingId);
      ref.invalidate(userFollowingProvider);
      ref.invalidate(followedTeachersProvider);
      ref.invalidate(followedAcademiesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.followUnfollowed)),
        );
      }
    }
  }

  Future<void> _handleToggleNotification(WidgetRef ref, Follow follow) async {
    final repo = ref.read(followRepositoryProvider);
    await repo.updateNotification(follow.id, !follow.notificationEnabled);
    ref.invalidate(userFollowingProvider);
    ref.invalidate(followedTeachersProvider);
    ref.invalidate(followedAcademiesProvider);
  }
}
