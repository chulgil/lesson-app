import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/lessons/domain/entities/lesson.dart';

/// Lesson card widget for student view
class StudentLessonCard extends StatelessWidget {
  final Lesson lesson;

  const StudentLessonCard({
    super.key,
    required this.lesson,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    // Parse startTime (format: "HH:mm") to DateTime for display
    final timeParts = lesson.startTime.split(':');
    final lessonDateTime = DateTime(
      lesson.date.year,
      lesson.date.month,
      lesson.date.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
    final daysUntil = lesson.daysFromNow;
    final isUpcoming = lesson.isUpcoming;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          context.push(AppRoutes.lessonDetail.replaceFirst(':id', lesson.id));
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        child: Column(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Row(
                children: [
                  // Time column
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isUpcoming
                          ? AppColors.primaryLight.withValues(alpha: 0.2)
                          : AppColors.surfaceSecondaryLight,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMedium),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          timeFormat.format(lessonDateTime),
                          style: AppTypography.bodyLarge.copyWith(
                            color: isUpcoming
                                ? AppColors.primary
                                : AppColors.textSecondaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${lesson.duration}분',
                          style: AppTypography.caption.copyWith(
                            color: isUpcoming
                                ? AppColors.primary
                                : AppColors.textTertiaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: AppSpacing.space3),

                  // Info column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              lesson.teacherName ?? '선생님',
                              style: AppTypography.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.space2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryLight
                                    .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                lesson.instrument,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (lesson.location != null) ...[
                          const SizedBox(height: AppSpacing.space1),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: AppColors.textTertiaryLight,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  lesson.location!.name,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondaryLight,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (lesson.pieces.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.space1),
                          Text(
                            lesson.pieces.first.displayName,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // D-day or status
                  if (isUpcoming && daysUntil >= 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: daysUntil <= 1
                            ? AppColors.primary
                            : AppColors.surfaceSecondaryLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        daysUntil == 0
                            ? '오늘'
                            : daysUntil == 1
                                ? '내일'
                                : 'D-$daysUntil',
                        style: AppTypography.caption.copyWith(
                          color: daysUntil <= 1
                              ? Colors.white
                              : AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textTertiaryLight,
                    ),
                ],
              ),
            ),

            // Feedback preview (for past lessons)
            if (!isUpcoming && lesson.hasFeedback) ...[
              Divider(
                height: 1,
                color: AppColors.borderLight,
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.space3),
                child: Row(
                  children: [
                    Icon(
                      Icons.comment_outlined,
                      size: 16,
                      color: AppColors.textTertiaryLight,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Expanded(
                      child: Text(
                        lesson.feedback!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
