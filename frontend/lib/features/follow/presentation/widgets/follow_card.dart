// Follow card widget for follow list items.

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/follow.dart';
import '../../domain/entities/follow_target_type.dart';

/// Card widget for displaying a follow item in the list.
class FollowCard extends StatelessWidget {
  final Follow follow;
  final VoidCallback onUnfollow;
  final VoidCallback onToggleNotification;

  const FollowCard({
    super.key,
    required this.follow,
    required this.onUnfollow,
    required this.onToggleNotification,
  });

  @override
  Widget build(BuildContext context) {
    final isTeacher = follow.targetType == FollowTargetType.teacher;
    final displayName = follow.followingId; // TODO: Resolve to actual name

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor:
                isTeacher
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.secondary.withValues(alpha: 0.1),
            child: Icon(
              isTeacher ? Icons.person : Icons.business,
              color: isTeacher ? AppColors.primary : AppColors.secondary,
            ),
          ),

          const SizedBox(width: AppSpacing.space3),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isTeacher
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMedium,
                        ),
                      ),
                      child: Text(
                        follow.targetType.displayName,
                        style: AppTypography.caption.copyWith(
                          color:
                              isTeacher
                                  ? AppColors.primary
                                  : AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(follow.createdAt),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ),

          // Notification toggle
          IconButton(
            onPressed: onToggleNotification,
            icon: Icon(
              follow.notificationEnabled
                  ? Icons.notifications_active
                  : Icons.notifications_off_outlined,
              color:
                  follow.notificationEnabled
                      ? AppColors.primary
                      : AppColors.textTertiaryLight,
              size: 20,
            ),
            tooltip: follow.notificationEnabled ? '알림 끄기' : '알림 켜기',
          ),

          // Unfollow button
          IconButton(
            onPressed: onUnfollow,
            icon: Icon(
              Icons.person_remove_outlined,
              color: AppColors.textTertiaryLight,
              size: 20,
            ),
            tooltip: '팔로우 취소',
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}부터 팔로우';
  }
}
