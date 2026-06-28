import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/value_objects/clock_time.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/notebook/thin_rule.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../features/lessons/domain/entities/lesson.dart';
import '../../../../features/lessons/presentation/extensions/lesson_visuals.dart';

/// Lesson card widget for student view
class StudentLessonCard extends StatelessWidget {
  final Lesson lesson;

  const StudentLessonCard({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    // Parse startTime (format: "HH:mm") to DateTime for display.
    // ClockTime.parse is total (#64) — malformed remote startTime falls back to
    // 00:00 instead of crashing the whole student home (IndexedStack).
    final startClock = ClockTime.parse(lesson.startTime);
    final lessonDateTime = DateTime(
      lesson.date.year,
      lesson.date.month,
      lesson.date.day,
      startClock.hour,
      startClock.minute,
    );
    final daysUntil = lesson.daysFromNow;
    final isUpcoming = lesson.isUpcoming;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: InkWell(
        onTap: () {
          context.push(
            AppRoutes.lessonDetail.replaceFirst(':id', lesson.id),
            extra: {'viewerRole': 'student'},
          );
        },
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
                          ? AppColors.paperAccentSoft
                          : AppColors.paperDark,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          formatTimeHM(lessonDateTime),
                          style: AppTypography.bodyLarge.copyWith(
                            color: isUpcoming
                                ? AppColors.paperAccent
                                : AppColors.inkSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${lesson.duration}분',
                          style: AppTypography.caption.copyWith(
                            color: isUpcoming
                                ? AppColors.paperAccent
                                : AppColors.inkTertiary,
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
                            Flexible(
                              child: Text(
                                lesson.teacherName ??
                                    AppStrings.studentLessonDefaultTeacher,
                                style: AppTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
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
                                color: AppColors.paperDark,
                              ),
                              child: Text(
                                lesson.instrument,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.ink,
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
                                color: AppColors.inkTertiary,
                              ),
                              const SizedBox(width: AppSpacing.space1),
                              Expanded(
                                child: Text(
                                  lesson.location!.name,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.inkSecondary,
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
                              color: AppColors.inkSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Status badge: 휴강 > D-day > chevron
                  if (lesson.status == LessonStatus.cancelledByTeacher)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.paperAccentSoft,
                        border: Border.all(color: AppColors.paperAccent),
                      ),
                      child: Text(
                        AppStrings.studentLessonCancelled,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.paperAccent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else if (isUpcoming && daysUntil >= 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: daysUntil <= 1
                            ? AppColors.ink
                            : AppColors.paperDark,
                      ),
                      child: Text(
                        daysUntil == 0
                            ? AppStrings.studentLessonToday
                            : daysUntil == 1
                            ? AppStrings.studentLessonTomorrow
                            : 'D-$daysUntil',
                        style: AppTypography.caption.copyWith(
                          color: daysUntil <= 1
                              ? AppColors.paper
                              : AppColors.inkSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Icon(Icons.chevron_right, color: AppColors.inkTertiary),
                ],
              ),
            ),

            // Feedback preview (for past lessons)
            if (!isUpcoming && lesson.hasFeedback) ...[
              const ThinRule(),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.space3),
                child: Row(
                  children: [
                    Icon(
                      Icons.comment_outlined,
                      size: 16,
                      color: AppColors.inkTertiary,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Expanded(
                      // Notebook × Score: 피드백 프리뷰는 손글씨 주석처럼 Gaegu로.,
                      child: Text(
                        lesson.feedback!,
                        style: NotebookTypography.handSmall.copyWith(
                          color: AppColors.paperPencil,
                          height: 1.3,
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
