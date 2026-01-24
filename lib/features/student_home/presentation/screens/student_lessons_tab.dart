import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.space2,
            AppSpacing.screenPadding,
            0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('내 레슨', style: AppTypography.headingLarge),
              FilledButton.icon(
                onPressed: () {
                  context.push(AppRoutes.selectTeacher);
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('레슨 신청'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space4,
                    vertical: AppSpacing.space2,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Week Calendar
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
            practicedDates: markedDates,
          ),
        ),

        const SizedBox(height: AppSpacing.space3),

        // Content list
        Expanded(
          child: _StudentLessonList(
            selectedDate: selectedDate,
            lessons: studentLessons,
            trialBookings: trialBookings,
            scrollController: _scrollController,
            isLoading: isLoading,
          ),
        ),
      ],
    );
  }
}

class _StudentLessonList extends StatelessWidget {
  final DateTime selectedDate;
  final List<Lesson> lessons;
  final List<LessonBooking> trialBookings;
  final ScrollController scrollController;
  final bool isLoading;

  const _StudentLessonList({
    required this.selectedDate,
    required this.lessons,
    required this.trialBookings,
    required this.scrollController,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
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
        // Date title
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
        if (!hasContent && !isLoading)
          Container(
            padding: const EdgeInsets.all(AppSpacing.space6),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_available,
                    size: 64,
                    color: AppColors.textTertiaryLight,
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    '이 날짜에 예정된 레슨이 없습니다',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: AppSpacing.space6),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
