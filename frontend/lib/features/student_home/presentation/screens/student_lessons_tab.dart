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
import '../../../../shared/widgets/collapsible_calendar.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../../lessons/presentation/providers/lesson_crud_provider.dart';
import '../widgets/student_lesson_card.dart';
import '../widgets/trial_booking_card.dart';
import '../widgets/week_calendar_widget.dart';

/// Schedule view type enum for student
enum StudentScheduleViewType {
  monthly('전체'),
  weekly('주간'),
  daily('일간');

  final String label;
  const StudentScheduleViewType(this.label);
}

/// State provider for student selected date
final studentSelectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Student lessons tab showing collapsible calendar and lesson list
class StudentLessonsTab extends ConsumerStatefulWidget {
  const StudentLessonsTab({super.key});

  @override
  ConsumerState<StudentLessonsTab> createState() => _StudentLessonsTabState();
}

class _StudentLessonsTabState extends ConsumerState<StudentLessonsTab> {
  final ScrollController _scrollController = ScrollController();
  StudentScheduleViewType _viewType = StudentScheduleViewType.monthly;
  bool _isCalendarExpanded = true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final currentStudentId = ref.watch(currentUserIdProvider);
    final selectedDate = ref.watch(studentSelectedDateProvider);
    final lessonsAsync = ref.watch(lessonsProvider);
    final studentBookings = ref.watch(studentBookingsProvider(currentStudentId));

    // Filter lessons for current student
    final studentLessons = lessonsAsync.whenOrNull(
          data: (lessons) =>
              lessons.where((l) => l.studentId == currentStudentId).toList(),
        ) ??
        [];

    // Get trial bookings for display
    final trialBookings = studentBookings.whenOrNull(
          data: (bookings) => bookings
              .where((b) => b.lessonType == LessonType.trial)
              .where((b) => b.status.isActive || b.status.canRetry)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        ) ??
        [];

    // Get marked dates from lessons
    final markedDates = studentLessons
        .map((l) => DateTime(l.date.year, l.date.month, l.date.day))
        .toSet();

    // Add booking dates to marked dates
    final bookingDates = studentBookings.whenOrNull(
          data: (bookings) => bookings
              .where((b) => b.status.isActive)
              .map((b) => DateTime(
                  b.lessonDate.year, b.lessonDate.month, b.lessonDate.day))
              .toSet(),
        ) ??
        <DateTime>{};
    markedDates.addAll(bookingDates);

    final isLoading = lessonsAsync.isLoading || studentBookings.isLoading;

    return Column(
      children: [
        // Header with date and view selector
        _buildHeader(context, selectedDate),

        // Content based on view type
        Expanded(
          child: _buildContent(
            context,
            selectedDate,
            studentLessons,
            trialBookings,
            markedDates,
            isLoading,
            currentStudentId,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, DateTime selectedDate) {
    final dateFormat = DateFormat('M월 d일 (E)', 'ko');
    final isToday = _isSameDay(selectedDate, DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.space2,
        AppSpacing.screenPadding,
        AppSpacing.space3,
      ),
      child: Row(
        children: [
          // Date display with today indicator
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Tap to go to today
                final now = DateTime.now();
                ref.read(studentSelectedDateProvider.notifier).state =
                    DateTime(now.year, now.month, now.day);
              },
              child: Row(
                children: [
                  Text(
                    dateFormat.format(selectedDate),
                    style: AppTypography.headingMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(width: AppSpacing.space2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
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
                ],
              ),
            ),
          ),
          // View selector dropdown
          _buildViewDropdown(),
          const SizedBox(width: AppSpacing.space2),
          // Add lesson button
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

  Widget _buildViewDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<StudentScheduleViewType>(
          value: _viewType,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          items: StudentScheduleViewType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(
                type.label,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _viewType = value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    DateTime selectedDate,
    List<Lesson> studentLessons,
    List<LessonBooking> trialBookings,
    Set<DateTime> markedDates,
    bool isLoading,
    String studentId,
  ) {
    switch (_viewType) {
      case StudentScheduleViewType.monthly:
        return _buildMonthlyView(
          context,
          selectedDate,
          studentLessons,
          trialBookings,
          markedDates,
          isLoading,
          studentId,
        );
      case StudentScheduleViewType.weekly:
        return _buildWeeklyView(
          context,
          selectedDate,
          studentLessons,
          trialBookings,
          markedDates,
          isLoading,
          studentId,
        );
      case StudentScheduleViewType.daily:
        return _buildDailyView(
          context,
          selectedDate,
          studentLessons,
          trialBookings,
          isLoading,
          studentId,
        );
    }
  }

  Widget _buildMonthlyView(
    BuildContext context,
    DateTime selectedDate,
    List<Lesson> studentLessons,
    List<LessonBooking> trialBookings,
    Set<DateTime> markedDates,
    bool isLoading,
    String studentId,
  ) {
    return Column(
      children: [
        // Monthly calendar using CollapsibleCalendar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: CollapsibleCalendar(
            selectedDate: selectedDate,
            onDateSelected: (date) {
              ref.read(studentSelectedDateProvider.notifier).state = date;
            },
            isExpanded: _isCalendarExpanded,
            markedDates: markedDates,
            onToggleExpand: () {
              setState(() {
                _isCalendarExpanded = !_isCalendarExpanded;
              });
            },
          ),
        ),

        // Lesson list for selected date
        Expanded(
          child: _StudentLessonList(
            selectedDate: selectedDate,
            lessons: studentLessons,
            trialBookings: trialBookings,
            scrollController: _scrollController,
            isLoading: isLoading,
            studentId: studentId,
            viewType: _viewType,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyView(
    BuildContext context,
    DateTime selectedDate,
    List<Lesson> studentLessons,
    List<LessonBooking> trialBookings,
    Set<DateTime> markedDates,
    bool isLoading,
    String studentId,
  ) {
    return Column(
      children: [
        // Week calendar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: WeekCalendarWidget(
            selectedDate: selectedDate,
            onDateSelected: (date) {
              ref.read(studentSelectedDateProvider.notifier).state = date;
            },
            practicedDates: markedDates,
          ),
        ),

        const SizedBox(height: AppSpacing.space3),

        // Lesson list for selected week
        Expanded(
          child: _StudentLessonList(
            selectedDate: selectedDate,
            lessons: studentLessons,
            trialBookings: trialBookings,
            scrollController: _scrollController,
            isLoading: isLoading,
            studentId: studentId,
            viewType: _viewType,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyView(
    BuildContext context,
    DateTime selectedDate,
    List<Lesson> studentLessons,
    List<LessonBooking> trialBookings,
    bool isLoading,
    String studentId,
  ) {
    return Column(
      children: [
        // Date navigation header
        _buildDailyDateHeader(selectedDate),

        const SizedBox(height: AppSpacing.space3),

        // Lesson list for selected day only
        Expanded(
          child: _StudentLessonList(
            selectedDate: selectedDate,
            lessons: studentLessons,
            trialBookings: trialBookings,
            scrollController: _scrollController,
            isLoading: isLoading,
            studentId: studentId,
            viewType: _viewType,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyDateHeader(DateTime selectedDate) {
    final dateFormat = DateFormat('M월 d일 EEEE', 'ko');
    final isToday = _isSameDay(selectedDate, DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                final newDate = selectedDate.subtract(const Duration(days: 1));
                ref.read(studentSelectedDateProvider.notifier).state = newDate;
              },
              icon: const Icon(Icons.chevron_left),
              color: AppColors.textSecondaryLight,
            ),
            GestureDetector(
              onTap: () => _showDatePicker(selectedDate),
              child: Row(
                children: [
                  Text(
                    dateFormat.format(selectedDate),
                    style: AppTypography.headingSmall,
                  ),
                  if (isToday) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
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
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                final newDate = selectedDate.add(const Duration(days: 1));
                ref.read(studentSelectedDateProvider.notifier).state = newDate;
              },
              icon: const Icon(Icons.chevron_right),
              color: AppColors.textSecondaryLight,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDatePicker(DateTime selectedDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ko', 'KR'),
    );
    if (picked != null) {
      ref.read(studentSelectedDateProvider.notifier).state =
          DateTime(picked.year, picked.month, picked.day);
    }
  }
}

class _StudentLessonList extends StatelessWidget {
  final DateTime selectedDate;
  final List<Lesson> lessons;
  final List<LessonBooking> trialBookings;
  final ScrollController scrollController;
  final bool isLoading;
  final String studentId;
  final StudentScheduleViewType viewType;

  const _StudentLessonList({
    required this.selectedDate,
    required this.lessons,
    required this.trialBookings,
    required this.scrollController,
    required this.isLoading,
    required this.studentId,
    required this.viewType,
  });

  @override
  Widget build(BuildContext context) {
    switch (viewType) {
      case StudentScheduleViewType.monthly:
      case StudentScheduleViewType.daily:
        return _buildDayLessonList(context);
      case StudentScheduleViewType.weekly:
        return _buildWeekLessonList(context);
    }
  }

  Widget _buildDayLessonList(BuildContext context) {
    final dateFormat = DateFormat('M월 d일 EEEE', 'ko');

    // Filter lessons for selected date
    final dayLessons = lessons
        .where((l) =>
            l.date.year == selectedDate.year &&
            l.date.month == selectedDate.month &&
            l.date.day == selectedDate.day)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // Filter trial bookings for selected date
    final dayTrialBookings = trialBookings
        .where((b) =>
            b.lessonDate.year == selectedDate.year &&
            b.lessonDate.month == selectedDate.month &&
            b.lessonDate.day == selectedDate.day)
        .toList();

    final hasContent = dayLessons.isNotEmpty || dayTrialBookings.isNotEmpty;
    final isToday = _isToday(selectedDate);

    return ListView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      children: [
        // Only show date title for monthly view (daily view has header)
        if (viewType == StudentScheduleViewType.monthly) ...[
          Row(
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
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
                '${dayLessons.length + dayTrialBookings.length}개',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
        ],

        // Loading indicator
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.space4),
              child: CircularProgressIndicator(),
            ),
          ),

        // Trial bookings for selected date
        if (dayTrialBookings.isNotEmpty) ...[
          ...dayTrialBookings.map((booking) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                child: TrialBookingCard(booking: booking),
              )),
        ],

        // Regular lessons for selected date
        if (dayLessons.isNotEmpty) ...[
          ...dayLessons.map((lesson) => StudentLessonCard(lesson: lesson)),
        ],

        // Empty state
        if (!hasContent && !isLoading) _buildEmptyState(context),

        const SizedBox(height: AppSpacing.space6),
      ],
    );
  }

  Widget _buildWeekLessonList(BuildContext context) {
    // Get the week start (Monday)
    final weekStart = selectedDate.subtract(
      Duration(days: selectedDate.weekday - 1),
    );

    // Get lessons and bookings for the entire week
    final weekLessons = <DateTime, List<dynamic>>{};
    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final normalizedDay = DateTime(day.year, day.month, day.day);

      final dayLessons = lessons.where((l) =>
          l.date.year == day.year &&
          l.date.month == day.month &&
          l.date.day == day.day).toList();

      final dayTrialBookings = trialBookings.where((b) =>
          b.lessonDate.year == day.year &&
          b.lessonDate.month == day.month &&
          b.lessonDate.day == day.day).toList();

      if (dayLessons.isNotEmpty || dayTrialBookings.isNotEmpty) {
        weekLessons[normalizedDay] = [...dayTrialBookings, ...dayLessons];
      }
    }

    if (weekLessons.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        child: _buildEmptyState(context, message: '이번 주 예정된 레슨이 없습니다'),
      );
    }

    final sortedDays = weekLessons.keys.toList()..sort();

    return ListView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      itemCount: sortedDays.length,
      itemBuilder: (context, index) {
        final day = sortedDays[index];
        final dayItems = weekLessons[day]!;
        final dateFormat = DateFormat('M/d (E)', 'ko');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) const SizedBox(height: AppSpacing.space4),
            // Day header
            Row(
              children: [
                Text(
                  dateFormat.format(day),
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _isToday(day)
                        ? AppColors.primary
                        : AppColors.textSecondaryLight,
                  ),
                ),
                if (_isToday(day)) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '오늘',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  '${dayItems.length}개',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space2),
            // Day items
            ...dayItems.map((item) {
              if (item is LessonBooking) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                  child: TrialBookingCard(booking: item),
                );
              } else if (item is Lesson) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                  child: StudentLessonCard(lesson: item),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, {String? message}) {
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
              message ??
                  (_isToday(selectedDate)
                      ? '오늘 예정된 레슨이 없습니다'
                      : '이 날짜에 예정된 레슨이 없습니다'),
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

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
