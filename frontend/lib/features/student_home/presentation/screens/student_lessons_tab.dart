import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/lesson.dart';
import '../../../../models/lesson_booking.dart';
import '../../../../providers/booking/booking_providers.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../../lessons/presentation/providers/lesson_crud_provider.dart';
import '../widgets/student_lesson_card.dart';
import '../widgets/trial_booking_card.dart';
import '../widgets/week_calendar_widget.dart';

/// Lesson sort type for schedule views
enum LessonSortType {
  timeAsc('시간순'),
  nameAsc('이름순');

  final String displayName;
  const LessonSortType(this.displayName);
}

/// State provider for student selected date
final studentSelectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// State provider for student lesson sort type
final studentLessonSortTypeProvider = StateProvider<LessonSortType>(
  (ref) => LessonSortType.timeAsc,
);

/// Student lessons tab with WeekCalendar and lesson list
class StudentLessonsTab extends ConsumerWidget {
  const StudentLessonsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStudentId = ref.watch(currentUserIdProvider);
    final selectedDate = ref.watch(studentSelectedDateProvider);
    final sortType = ref.watch(studentLessonSortTypeProvider);
    final lessonsAsync = ref.watch(lessonsProvider);
    final studentBookings = ref.watch(
      studentBookingsProvider(currentStudentId),
    );

    // Filter lessons for current student
    final studentLessons =
        lessonsAsync.whenOrNull(
          data:
              (lessons) =>
                  lessons
                      .where((l) => l.studentId == currentStudentId)
                      .toList(),
        ) ??
        [];

    // Get trial bookings for display
    final trialBookings =
        studentBookings.whenOrNull(
          data:
              (bookings) =>
                  bookings
                      .where((b) => b.lessonType == LessonType.trial)
                      .where((b) => b.status.isActive || b.status.canRetry)
                      .toList()
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        ) ??
        [];

    // Get marked dates from lessons
    final markedDates =
        studentLessons
            .map((l) => DateTime(l.date.year, l.date.month, l.date.day))
            .toSet();

    // Add booking dates to marked dates
    final bookingDates =
        studentBookings.whenOrNull(
          data:
              (bookings) =>
                  bookings
                      .where((b) => b.status.isActive)
                      .map(
                        (b) => DateTime(
                          b.lessonDate.year,
                          b.lessonDate.month,
                          b.lessonDate.day,
                        ),
                      )
                      .toSet(),
        ) ??
        <DateTime>{};
    markedDates.addAll(bookingDates);

    // Filter lessons for selected date
    final dayLessons =
        studentLessons
            .where(
              (l) =>
                  l.date.year == selectedDate.year &&
                  l.date.month == selectedDate.month &&
                  l.date.day == selectedDate.day,
            )
            .toList();

    // Sort lessons
    switch (sortType) {
      case LessonSortType.timeAsc:
        dayLessons.sort((a, b) => a.startTime.compareTo(b.startTime));
      case LessonSortType.nameAsc:
        dayLessons.sort(
          (a, b) => (a.teacherName ?? '').compareTo(b.teacherName ?? ''),
        );
    }

    // Filter trial bookings for selected date
    final dayTrialBookings =
        trialBookings
            .where(
              (b) =>
                  b.lessonDate.year == selectedDate.year &&
                  b.lessonDate.month == selectedDate.month &&
                  b.lessonDate.day == selectedDate.day,
            )
            .toList();

    final isLoading = lessonsAsync.isLoading || studentBookings.isLoading;
    final totalCount = dayLessons.length + dayTrialBookings.length;

    return Column(
      children: [
        // Header: title + action button
        _buildHeader(context),

        // WeekCalendarWidget
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.space3,
            AppSpacing.screenPadding,
            0,
          ),
          child: WeekCalendarWidget(
            selectedDate: selectedDate,
            onDateSelected: (date) {
              ref.read(studentSelectedDateProvider.notifier).state = date;
            },
            lessonDates: markedDates,
          ),
        ),

        const SizedBox(height: AppSpacing.space3),

        // Date header with count and sort
        _buildDateHeader(ref, selectedDate, totalCount, sortType),

        const SizedBox(height: AppSpacing.space3),

        // Lesson list for selected date
        Expanded(
          child: _buildLessonList(
            context,
            dayLessons,
            dayTrialBookings,
            isLoading,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.space2,
        AppSpacing.screenPadding,
        0,
      ),
      child: Row(
        children: [
          Text(
            '스케줄',
            style: AppTypography.headingMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: () {
              context.push(AppRoutes.teacherSearch);
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('예약'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(
    WidgetRef ref,
    DateTime selectedDate,
    int totalCount,
    LessonSortType sortType,
  ) {
    final dateFormat = DateFormat('M월 d일 EEEE', 'ko');
    final now = DateTime.now();
    final isToday =
        selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        children: [
          Text(
            dateFormat.format(selectedDate),
            style: AppTypography.headingSmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          if (isToday) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Text(
                '오늘',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const Spacer(),
          Text(
            '$totalCount개 레슨',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiaryLight,
            ),
          ),
          const SizedBox(width: 12),
          _buildSortDropdown(ref, sortType),
        ],
      ),
    );
  }

  Widget _buildSortDropdown(WidgetRef ref, LessonSortType sortType) {
    return PopupMenuButton<LessonSortType>(
      onSelected: (value) {
        ref.read(studentLessonSortTypeProvider.notifier).state = value;
      },
      itemBuilder:
          (context) =>
              LessonSortType.values
                  .map(
                    (type) => PopupMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          if (type == sortType)
                            Icon(
                              Icons.check,
                              size: 16,
                              color: AppColors.primary,
                            )
                          else
                            const SizedBox(width: 16),
                          const SizedBox(width: 8),
                          Text(type.displayName),
                        ],
                      ),
                    ),
                  )
                  .toList(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            sortType.displayName,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(width: 2),
          Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: AppColors.textSecondaryLight,
          ),
        ],
      ),
    );
  }

  Widget _buildLessonList(
    BuildContext context,
    List<Lesson> dayLessons,
    List<LessonBooking> dayTrialBookings,
    bool isLoading,
  ) {
    final hasContent = dayLessons.isNotEmpty || dayTrialBookings.isNotEmpty;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      children: [
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.space4),
              child: CircularProgressIndicator(),
            ),
          ),

        // Trial bookings
        if (dayTrialBookings.isNotEmpty) ...[
          ...dayTrialBookings.map(
            (booking) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space3),
              child: TrialBookingCard(booking: booking),
            ),
          ),
        ],

        // Regular lessons
        if (dayLessons.isNotEmpty) ...[
          ...dayLessons.map((lesson) => StudentLessonCard(lesson: lesson)),
        ],

        // Empty state
        if (!hasContent && !isLoading) _buildEmptyState(context),

        const SizedBox(height: AppSpacing.space6),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space6),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.space4),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_available,
                size: 48,
                color: AppColors.textTertiaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              '예정된 레슨이 없습니다',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              '새로운 레슨을 예약해보세요',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.teacherSearch),
              icon: const Icon(Icons.search, size: 18),
              label: const Text('선생님 찾기'),
            ),
          ],
        ),
      ),
    );
  }
}
