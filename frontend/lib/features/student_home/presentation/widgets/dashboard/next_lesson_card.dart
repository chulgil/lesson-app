import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/utils/date_format_utils.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/notebook_typography.dart';
import '../../../../../core/booking/entities/lesson_booking.dart';
import '../../providers/student_home_booking_provider.dart';

/// Card showing the next upcoming lesson for a student.
class NextLessonCard extends ConsumerWidget {
  final String studentId;

  const NextLessonCard({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(studentHomeNextLessonProvider(studentId));

    return bookingAsync.when(
      loading: () => _buildLoadingState(),
      error: (_, __) => _buildEmptyState(context),
      data: (booking) {
        if (booking == null) {
          return _buildEmptyState(context);
        }

        return _buildContent(context, booking);
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: const Center(
        child: SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Row(
        children: [
          Icon(Icons.event_available, color: AppColors.inkTertiary, size: 32),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.studentHomeNoUpcomingLesson,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.studentHomeBookLessonSuggestion,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, LessonBooking booking) {
    final now = DateTime.now();
    // 캘린더 일자 기준 차이 (#66). difference(now) 는 시각을 포함해 오늘/내일 오표시.
    final today = DateTime(now.year, now.month, now.day);
    final lessonDay = DateTime(
      booking.lessonDate.year,
      booking.lessonDate.month,
      booking.lessonDate.day,
    );
    final daysUntil = lessonDay.difference(today).inDays;
    final isToday = daysUntil == 0;
    final isTomorrow = daysUntil == 1;

    String dDayText;
    if (isToday) {
      dDayText = AppStrings.studentLessonToday;
    } else if (isTomorrow) {
      dDayText = AppStrings.studentLessonTomorrow;
    } else {
      dDayText = 'D-$daysUntil';
    }

    final dayOfWeek = [
      AppStrings.weekdayMon,
      AppStrings.weekdayTue,
      AppStrings.weekdayWed,
      AppStrings.weekdayThu,
      AppStrings.weekdayFri,
      AppStrings.weekdaySat,
      AppStrings.weekdaySun,
    ];
    final weekdayText = dayOfWeek[booking.lessonDate.weekday - 1];
    final typeText = booking.lessonType == LessonType.regular
        ? AppStrings.lessonTypeRegular
        : AppStrings.lessonTypeTrial;

    return GestureDetector(
      onTap: () {
        context.push(
          AppRoutes.myBookings,
          extra: {
            'studentId': booking.studentId,
            'studentName': booking.studentName,
            'teacherId': booking.teacherId,
            'teacherName': booking.teacherName,
            'instrument': booking.instrument,
            'subscriptionId': null,
            'remainingReschedules': 0,
            'totalReschedules': 0,
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(color: AppColors.ink),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space2,
              ),
              decoration: BoxDecoration(
                color: AppColors.paper.withValues(alpha: 0.2),
              ),
              child: Column(
                children: [
                  Text(
                    dDayText,
                    style: AppTypography.headingSmall.copyWith(
                      color: AppColors.paper,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    weekdayText,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.paper.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 로마숫자 인덱스 — Notebook × Score 시그니처 (Phase 4c)
                      Text(
                        '${romanOf(0)}.',
                        style: NotebookTypography.roman.copyWith(
                          fontSize: 12,
                          color: AppColors.paper.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space1),
                      Text(
                        AppStrings.nextLessonLabel,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.paper.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.paper.withValues(alpha: 0.2),
                          ),
                          child: Text(
                            typeText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.paper,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    '${booking.teacherName} · ${booking.instrument}',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.paper,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${formatDateYMD(booking.lessonDate)} ($weekdayText) '
                    '${booking.startTime.hour.toString().padLeft(2, '0')}:${booking.startTime.minute.toString().padLeft(2, '0')} · '
                    '${booking.durationMinutes}분',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.paper.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.paper.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}
