// Student lesson card widget

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../models/lesson.dart';

/// Lesson card for student detail screen
class StudentLessonCard extends StatelessWidget {
  final Lesson lesson;
  final bool isUpcoming;

  const StudentLessonCard({
    super.key,
    required this.lesson,
    required this.isUpcoming,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(
          color: isUpcoming
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.borderLight,
        ),
      ),
      child: InkWell(
        onTap: () {
          context.push(AppRoutes.lessonDetail.replaceFirst(':id', lesson.id));
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Row(
            children: [
              // Date badge
              Container(
                width: 48,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
                decoration: BoxDecoration(
                  color: isUpcoming
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.surfaceSecondaryLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                child: Column(
                  children: [
                    Text(
                      '${lesson.date.day}',
                      style: AppTypography.headingSmall.copyWith(
                        color: isUpcoming
                            ? AppColors.primary
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      DateFormat('E', 'ko').format(lesson.date),
                      style: AppTypography.caption.copyWith(
                        color: isUpcoming
                            ? AppColors.primary
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.space3),

              // Lesson info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${lesson.startTime} (${lesson.duration}분)',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (lesson.pieces.isNotEmpty)
                      Text(
                        lesson.pieces.first.displayName,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    if (!isUpcoming && lesson.feedback != null) ...[
                      const SizedBox(height: AppSpacing.space2),
                      Row(
                        children: [
                          Icon(
                            Icons.comment,
                            size: 14,
                            color: AppColors.textTertiaryLight,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              lesson.feedback!,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textTertiaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Indicators
              Column(
                children: [
                  if (lesson.hasRecordings)
                    Icon(
                      Icons.mic,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  if (lesson.hasFeedback)
                    Icon(
                      Icons.note,
                      size: 18,
                      color: AppColors.secondary,
                    ),
                ],
              ),

              const SizedBox(width: AppSpacing.space2),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textTertiaryLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
