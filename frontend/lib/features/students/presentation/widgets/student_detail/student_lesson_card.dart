// Student lesson card widget

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/notebook_typography.dart';
import '../../../../../core/utils/date_format_utils.dart';
import '../../../../../features/lessons/domain/entities/lesson.dart';
import '../../../../../features/lessons/presentation/extensions/lesson_visuals.dart';

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
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(
          color: isUpcoming ? AppColors.paperAccent : AppColors.inkQuaternary,
        ),
      ),
      child: InkWell(
        onTap: () {
          context.push(AppRoutes.lessonDetail.replaceFirst(':id', lesson.id));
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Row(
            children: [
              // Date badge — fixed size for consistent card height
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      isUpcoming
                          ? AppColors.paperAccentSoft
                          : AppColors.paperDark,
                ),
                child: Column(
                  children: [
                    Text(
                      '${lesson.date.day}',
                      style: AppTypography.headingSmall.copyWith(
                        color:
                            isUpcoming ? AppColors.paperAccent : AppColors.ink,
                      ),
                    ),
                    Text(
                      formatWeekdayShort(lesson.date),
                      style: AppTypography.caption.copyWith(
                        color:
                            isUpcoming
                                ? AppColors.paperAccent
                                : AppColors.inkSecondary,
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
                          color: AppColors.inkSecondary,
                        ),
                      ),
                    if (!isUpcoming && lesson.feedback != null) ...[
                      const SizedBox(height: AppSpacing.space2),
                      Row(
                        children: [
                          Icon(
                            Icons.comment,
                            size: 14,
                            color: AppColors.inkTertiary,
                          ),
                          const SizedBox(width: AppSpacing.space1),
                          Expanded(
                            // Notebook × Score: 피드백 프리뷰도 손글씨 주석 느낌으로.
                            child: Text(
                              lesson.feedback!,
                              style: NotebookTypography.hand.copyWith(
                                fontSize: 13,
                                height: 1.3,
                                color: AppColors.paperPencil,
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
                    Icon(Icons.mic, size: 18, color: AppColors.paperAccent),
                  if (lesson.hasFeedback)
                    Icon(Icons.note, size: 18, color: AppColors.paperAccent),
                ],
              ),

              const SizedBox(width: AppSpacing.space2),
              const Icon(Icons.chevron_right, color: AppColors.inkTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
