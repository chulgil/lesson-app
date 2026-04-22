// Follow list screen with tabs for all/teachers/academies.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
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
      child: Scaffold(
        appBar: AppBar(
          title: const Text('팔로우'),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.inkSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [Tab(text: '전체'), Tab(text: '선생님'), Tab(text: '학원')],
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
      error: (_, __) => const Center(child: Text('오류가 발생했습니다.')),
      data: (follows) {
        if (follows.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.person_add_outlined,
            title:
                filterType == null
                    ? '팔로우한 계정이 없습니다'
                    : filterType == FollowTargetType.teacher
                    ? '팔로우한 선생님이 없습니다'
                    : '팔로우한 학원이 없습니다',
            subtitle: '선생님이나 학원을 팔로우하면\n소식을 받아볼 수 있습니다',
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('팔로우 취소'),
            content: Text('${follow.followingId}의 팔로우를 취소하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(AppStrings.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('팔로우 취소', style: TextStyle(color: AppColors.paperAccent)),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final repo = ref.read(followRepositoryProvider);
      await repo.unfollow(follow.followerId, follow.followingId);
      ref.invalidate(userFollowingProvider);
      ref.invalidate(followedTeachersProvider);
      ref.invalidate(followedAcademiesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('팔로우가 취소되었습니다')));
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
