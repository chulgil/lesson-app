import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_routes.dart';
import '../../../../../core/utils/date_format_utils.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/notebook_typography.dart';
import '../../../../../core/booking/entities/lesson_booking.dart';
import '../../../../../features/lessons/presentation/providers/booking_providers.dart';

/// Card showing the next upcoming lesson for a student.
class NextLessonCard extends ConsumerWidget {
  final String studentId;

  const NextLessonCard({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(studentBookingsProvider(studentId));

    return bookingsAsync.when(
      loading: () => _buildLoadingState(),
      error: (_, __) => _buildEmptyState(context),
      data: (bookings) {
        final now = DateTime.now();
        final upcomingBookings =
            bookings
                .where((b) => b.status.isActive && b.lessonDate.isAfter(now))
                .toList()
              ..sort((a, b) => a.lessonDate.compareTo(b.lessonDate));

        if (upcomingBookings.isEmpty) {
          return _buildEmptyState(context);
        }

        return _buildContent(context, upcomingBookings.first);
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
                  '예정된 레슨이 없습니다',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '선생님을 찾아 레슨을 예약해보세요',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push(AppRoutes.teacherSearch),
            child: const Text('선생님 찾기'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, LessonBooking booking) {
    final now = DateTime.now();
    final daysUntil = booking.lessonDate.difference(now).inDays;
    final isToday = daysUntil == 0;
    final isTomorrow = daysUntil == 1;

    String dDayText;
    if (isToday) {
      dDayText = '오늘';
    } else if (isTomorrow) {
      dDayText = '내일';
    } else {
      dDayText = 'D-$daysUntil';
    }

    final dayOfWeek = ['월', '화', '수', '목', '금', '토', '일'];
    final weekdayText = dayOfWeek[booking.lessonDate.weekday - 1];
    final typeText = booking.lessonType == LessonType.regular ? '정기' : '체험';

    return GestureDetector(
      onTap: () {
        context.push(AppRoutes.bookingDetail.replaceFirst(':id', booking.id));
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
                        '다음 레슨',
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
