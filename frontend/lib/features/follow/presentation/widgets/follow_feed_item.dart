import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/teacher_post.dart';

/// A single feed item card in FollowFeedScreen.
class FollowFeedItem extends StatelessWidget {
  final TeacherPost post;

  const FollowFeedItem({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: author + time
          Row(
            children: [
              // Author avatar placeholder
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.paperAccentSoft,
                child: Text(
                  post.authorName.isNotEmpty
                      ? post.authorName[0]
                      : '?',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.paperAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              // Author name
              Expanded(
                child: Text(
                  post.authorName,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Relative time
              Text(
                _formatTime(post.createdAt),
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),

          // Type badge + title
          Row(
            children: [
              Text(post.typeEmoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: AppSpacing.space1),
              Text(
                post.typeLabel,
                style: AppTypography.caption.copyWith(
                  color: AppColors.paperAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space1),

          // Title
          Text(
            post.title,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),

          // Content (truncated)
          Text(
            post.content,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return '방금';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}분 전';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}시간 전';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }
}
