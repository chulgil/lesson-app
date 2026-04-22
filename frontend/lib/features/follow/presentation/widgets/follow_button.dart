// Reusable follow/unfollow toggle button.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/follow_target_type.dart';
import '../providers/follow_providers.dart';

/// Follow/unfollow toggle button widget.
class FollowButton extends ConsumerWidget {
  final String followerId;
  final String followingId;
  final FollowTargetType targetType;
  final bool compact;

  const FollowButton({
    super.key,
    required this.followerId,
    required this.followingId,
    required this.targetType,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFollowingAsync = ref.watch(
      isFollowingProvider(
        followerId: followerId,
        followingId: followingId,
      ),
    );

    return isFollowingAsync.when(
      loading: () => const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (isFollowing) {
        if (compact) {
          return _buildCompactButton(context, ref, isFollowing);
        }
        return _buildFullButton(context, ref, isFollowing);
      },
    );
  }

  Widget _buildFullButton(
    BuildContext context,
    WidgetRef ref,
    bool isFollowing,
  ) {
    if (isFollowing) {
      return OutlinedButton.icon(
        onPressed: () => _toggleFollow(context, ref, isFollowing),
        icon: const Icon(Icons.check, size: 16),
        label: const Text('팔로잉'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          textStyle: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return FilledButton.icon(
      onPressed: () => _toggleFollow(context, ref, isFollowing),
      icon: const Icon(Icons.add, size: 16),
      label: const Text('팔로우'),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        textStyle: AppTypography.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCompactButton(
    BuildContext context,
    WidgetRef ref,
    bool isFollowing,
  ) {
    return IconButton(
      onPressed: () => _toggleFollow(context, ref, isFollowing),
      icon: Icon(
        isFollowing ? Icons.favorite : Icons.favorite_border,
        color: isFollowing ? AppColors.paperAccent : AppColors.inkTertiary,
      ),
      tooltip: isFollowing ? '팔로우 취소' : '팔로우',
    );
  }

  Future<void> _toggleFollow(
    BuildContext context,
    WidgetRef ref,
    bool isFollowing,
  ) async {
    final repo = ref.read(followRepositoryProvider);
    if (isFollowing) {
      await repo.unfollow(followerId, followingId);
    } else {
      await repo.follow(
        followerId: followerId,
        followingId: followingId,
        targetType: targetType,
      );
    }
    ref.invalidate(isFollowingProvider);
    ref.invalidate(userFollowingProvider);
    ref.invalidate(followedTeachersProvider);
    ref.invalidate(followedAcademiesProvider);
    ref.invalidate(followerCountProvider);
    ref.invalidate(followingCountProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isFollowing ? '팔로우가 취소되었습니다' : '팔로우했습니다'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
}
