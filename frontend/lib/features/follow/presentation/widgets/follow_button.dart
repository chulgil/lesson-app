import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/follow_target_type.dart';
import '../providers/follow_providers.dart';

/// Spec §3.2 — 팔로우/언팔로우 토글 버튼.
///
/// 상태 표시:
/// - `isFollowingProvider` 가 true → 팔로잉 (outlined, dim)
/// - false → 팔로우 (filled, accent)
///
/// 호출 위치: 선생님 프로필, 검색 결과, FollowCard 등.
class FollowButton extends ConsumerWidget {
  final String followerId;
  final String followingId;
  final FollowTargetType targetType;
  final bool compact;

  const FollowButton({
    super.key,
    required this.followerId,
    required this.followingId,
    this.targetType = FollowTargetType.teacher,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncIsFollowing = ref.watch(
      isFollowingProvider(followerId: followerId, followingId: followingId),
    );
    // Guard against double-tap: while follow/unfollow is in progress the
    // FollowNotifier state is AsyncLoading — disable the button during that time.
    final isActionInProgress =
        ref.watch(followNotifierProvider).isLoading;

    return asyncIsFollowing.when(
      loading: () => _LoadingPill(compact: compact),
      error:
          (_, _) => _ActionButton(
            label: AppStrings.followFollow,
            accent: true,
            compact: compact,
            onPressed: isActionInProgress ? () {} : () => _follow(ref),
          ),
      data:
          (isFollowing) =>
              isActionInProgress
                  ? _LoadingPill(compact: compact)
                  : isFollowing
                  ? _ActionButton(
                    label: AppStrings.followFollowing,
                    accent: false,
                    compact: compact,
                    onPressed: () => _unfollow(ref),
                  )
                  : _ActionButton(
                    label: AppStrings.followFollow,
                    accent: true,
                    compact: compact,
                    onPressed: () => _follow(ref),
                  ),
    );
  }

  Future<void> _follow(WidgetRef ref) async {
    await ref
        .read(followNotifierProvider.notifier)
        .follow(
          followerId: followerId,
          followingId: followingId,
          targetType: targetType,
        );
  }

  Future<void> _unfollow(WidgetRef ref) async {
    await ref
        .read(followNotifierProvider.notifier)
        .unfollow(
          followerId: followerId,
          followingId: followingId,
          targetType: targetType,
        );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool accent;
  final bool compact;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.accent,
    required this.compact,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final height =
        compact ? AppSpacing.buttonHeightSmall : AppSpacing.buttonHeight;
    if (accent) {
      return FilledButton(
        style: FilledButton.styleFrom(
          minimumSize: Size(0, height),
          backgroundColor: AppColors.paperAccent,
          foregroundColor: AppColors.paper,
        ),
        onPressed: onPressed,
        child: Text(label),
      );
    }
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: Size(0, height),
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.inkQuaternary),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

class _LoadingPill extends StatelessWidget {
  final bool compact;
  const _LoadingPill({required this.compact});

  @override
  Widget build(BuildContext context) {
    final height =
        compact ? AppSpacing.buttonHeightSmall : AppSpacing.buttonHeight;
    return SizedBox(
      height: height,
      width: 80,
      child: const Center(
        child: SizedBox(
          height: 14,
          width: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
