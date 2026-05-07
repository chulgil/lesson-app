import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/widgets/notebook/notebook_masthead.dart';
import '../../../../features/lessons/domain/entities/lesson.dart';
import '../../../../core/booking/entities/lesson_booking.dart';
import '../providers/student_home_booking_provider.dart';
import '../providers/student_home_session_provider.dart';
import '../providers/student_lessons_tab_state_provider.dart';
import '../widgets/student_lesson_card.dart';
import '../widgets/trial_booking_card.dart';
import '../../../../core/widgets/compact_week_strip.dart';

/// Student lessons tab with WeekCalendar and lesson list
class StudentLessonsTab extends ConsumerWidget {
  const StudentLessonsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStudentId = ref.watch(studentHomeCurrentStudentIdProvider);
    final selectedDate = ref.watch(studentSelectedDateProvider);
    final sortType = ref.watch(studentLessonSortTypeProvider);
    final scheduleAsync = ref.watch(
      studentHomeLessonsScheduleProvider(currentStudentId),
    );
    final schedule = scheduleAsync.valueOrNull;

    final studentLessons = schedule?.lessons ?? <Lesson>[];
    final trialBookings = schedule?.trialBookings ?? <LessonBooking>[];
    final markedDates = schedule?.markerDates ?? <DateTime>{};

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

    final isLoading = scheduleAsync.isLoading;
    final totalCount = dayLessons.length + dayTrialBookings.length;

    return Column(
      children: [
        // Header: title + action button
        _buildHeader(context),

        // Compact week strip (unified with teacher schedule)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.space2,
            AppSpacing.screenPadding,
            0,
          ),
          child: CompactWeekStrip(
            selectedDate: selectedDate,
            onDateSelected: (date) {
              ref.read(studentSelectedDateProvider.notifier).state = date;
            },
            markerDates: markedDates,
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
    final now = DateTime.now();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.space2),
          NotebookMasthead(
            eyebrow: 'LESSON',
            meta: 'VOL. ${romanOf(now.month - 1)} · NO. ${now.day}',
            trailing: IconButton(
              onPressed: () => context.push(AppRoutes.selectTeacher),
              icon: const Icon(Icons.add, color: AppColors.ink, size: 22),
              tooltip: AppStrings.studentHomeBookAction,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
            formatDateMDWithDayLong(selectedDate),
            style: AppTypography.headingSmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          if (isToday) ...[
            const SizedBox(width: AppSpacing.space2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.paperAccentSoft),
              // "오늘" = 시스템 자동 인디케이터 → Tier 4 Pretendard italic
              // (README §1.1 4계층, §7.127 Gaegu 회피).
              child: Text(
                AppStrings.todayLabel,
                style: NotebookTypography.indicatorLabel,
              ),
            ),
          ],
          const Spacer(),
          Text(
            '$totalCount개 레슨',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkTertiary,
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
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
                              color: AppColors.paperAccent,
                            )
                          else
                            const SizedBox(width: AppSpacing.space4),
                          const SizedBox(width: AppSpacing.space2),
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
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(width: 2),
          Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: AppColors.inkSecondary,
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
            // §7.132: round → 사각 empty state 아이콘 컨테이너.
            Container(
              padding: const EdgeInsets.all(AppSpacing.space4),
              decoration: BoxDecoration(color: AppColors.paperDark),
              child: Icon(
                Icons.event_available,
                size: 48,
                color: AppColors.inkTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              AppStrings.studentHomeNoUpcomingLesson,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              AppStrings.studentHomeBookNewLesson,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.teacherSearch),
              icon: const Icon(Icons.search, size: 18),
              label: const Text(AppStrings.studentHomeFindTeacher),
              style: OutlinedButton.styleFrom(
                minimumSize: Size(0, AppSpacing.buttonHeight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
