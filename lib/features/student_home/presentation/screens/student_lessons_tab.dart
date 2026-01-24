import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/lesson_booking.dart';
import '../../../../providers/booking/booking_providers.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
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
    final studentBookings = ref.watch(studentBookingsProvider(currentStudentId));

    // Get trial bookings for display
    final trialBookings = studentBookings.whenOrNull(
          data: (bookings) => bookings
              .where((b) => b.lessonType == LessonType.trial)
              .where((b) => b.status.isActive || b.status.canRetry)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        ) ??
        [];

    // Get mock lessons and filter by selected date
    final allLessons = [..._mockUpcomingLessons(), ..._mockPastLessons()];
    final markedDates = allLessons
        .map((l) => DateTime(l.dateTime.year, l.dateTime.month, l.dateTime.day))
        .toSet();

    // Add booking dates to marked dates
    final bookingDates = studentBookings.whenOrNull(
          data: (bookings) => bookings
              .where((b) => b.status.isActive)
              .map((b) => DateTime(b.lessonDate.year, b.lessonDate.month, b.lessonDate.day))
              .toSet(),
        ) ??
        <DateTime>{};
    markedDates.addAll(bookingDates);

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
            trialBookings: trialBookings,
            scrollController: _scrollController,
            isLoading: studentBookings.isLoading,
          ),
        ),
      ],
    );
  }
}

class _StudentLessonList extends StatelessWidget {
  final DateTime selectedDate;
  final List<LessonBooking> trialBookings;
  final ScrollController scrollController;
  final bool isLoading;

  const _StudentLessonList({
    required this.selectedDate,
    required this.trialBookings,
    required this.scrollController,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('M월 d일 EEEE', 'ko');

    // Get all lessons
    final upcomingLessons = _mockUpcomingLessons();
    final pastLessons = _mockPastLessons();

    // Filter lessons for selected date
    final dayLessons = [...upcomingLessons, ...pastLessons].where((l) =>
        l.dateTime.year == selectedDate.year &&
        l.dateTime.month == selectedDate.month &&
        l.dateTime.day == selectedDate.day).toList();

    // Filter trial bookings for selected date
    final dayTrialBookings = trialBookings.where((b) =>
        b.lessonDate.year == selectedDate.year &&
        b.lessonDate.month == selectedDate.month &&
        b.lessonDate.day == selectedDate.day).toList();

    final hasContent = dayLessons.isNotEmpty || dayTrialBookings.isNotEmpty;

    return ListView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      children: [
        // Date title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              dateFormat.format(selectedDate),
              style: AppTypography.headingSmall.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
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
          ...dayLessons.map((lesson) => _LessonCard(
                lesson: lesson,
                isUpcoming: lesson.dateTime.isAfter(DateTime.now()),
              )),
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
}

/// Lesson card widget
class _LessonCard extends StatelessWidget {
  final _StudentLessonData lesson;
  final bool isUpcoming;

  const _LessonCard({
    required this.lesson,
    required this.isUpcoming,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    final daysUntil = lesson.dateTime.difference(DateTime.now()).inDays;

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
          context.push('/lessons/${lesson.id}');
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
                          timeFormat.format(lesson.dateTime),
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
                              lesson.teacherName,
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
                        if (lesson.piece != null) ...[
                          const SizedBox(height: AppSpacing.space1),
                          Text(
                            lesson.piece!,
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
            if (!isUpcoming && lesson.feedback != null) ...[
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

/// Student lesson data model
class _StudentLessonData {
  final String id;
  final DateTime dateTime;
  final int duration;
  final String teacherName;
  final String instrument;
  final String? piece;
  final String? feedback;

  _StudentLessonData({
    required this.id,
    required this.dateTime,
    required this.duration,
    required this.teacherName,
    required this.instrument,
    this.piece,
    this.feedback,
  });
}

List<_StudentLessonData> _mockUpcomingLessons() {
  final now = DateTime.now();
  return [
    _StudentLessonData(
      id: 'lesson_upcoming_1',
      dateTime: now.add(const Duration(days: 2, hours: 2)),
      duration: 60,
      teacherName: '김선생님',
      instrument: '바이올린',
      piece: '바흐 파르티타 2번 - Allemande, Sarabande',
    ),
    _StudentLessonData(
      id: 'lesson_upcoming_2',
      dateTime: now.add(const Duration(days: 9, hours: 3)),
      duration: 60,
      teacherName: '김선생님',
      instrument: '바이올린',
      piece: '크로이처 에튀드 3번',
    ),
    _StudentLessonData(
      id: 'lesson_upcoming_3',
      dateTime: now.add(const Duration(days: 16, hours: 1)),
      duration: 60,
      teacherName: '김선생님',
      instrument: '바이올린',
    ),
  ];
}

List<_StudentLessonData> _mockPastLessons() {
  final now = DateTime.now();
  return [
    _StudentLessonData(
      id: 'lesson_past_1',
      dateTime: now.subtract(const Duration(days: 5)),
      duration: 60,
      teacherName: '김선생님',
      instrument: '바이올린',
      piece: '바흐 파르티타 2번 - Allemande',
      feedback: '보잉이 많이 좋아졌습니다. 다음 시간에 Sarabande 시작합시다.',
    ),
    _StudentLessonData(
      id: 'lesson_past_2',
      dateTime: now.subtract(const Duration(days: 12)),
      duration: 60,
      teacherName: '김선생님',
      instrument: '바이올린',
      piece: '크로이처 에튀드 2번',
      feedback: '에튀드 마무리 잘 했어요. 다음 곡으로 넘어갑시다.',
    ),
    _StudentLessonData(
      id: 'lesson_past_3',
      dateTime: now.subtract(const Duration(days: 19)),
      duration: 60,
      teacherName: '김선생님',
      instrument: '바이올린',
      piece: '바흐 파르티타 2번 - Chaconne',
      feedback: '샤콘느 1부 완성! 정말 대단해요.',
    ),
    _StudentLessonData(
      id: 'lesson_past_4',
      dateTime: now.subtract(const Duration(days: 40)),
      duration: 60,
      teacherName: '김선생님',
      instrument: '바이올린',
      piece: 'G Major 스케일, 크로이처 1번',
    ),
    _StudentLessonData(
      id: 'lesson_past_5',
      dateTime: now.subtract(const Duration(days: 47)),
      duration: 60,
      teacherName: '김선생님',
      instrument: '바이올린',
      feedback: '스케일 연습 방법 지도. 3옥타브까지 연습해오기.',
    ),
  ];
}

/// Trial Booking Card - displays a single trial lesson booking with status and actions
class TrialBookingCard extends ConsumerWidget {
  final LessonBooking booking;

  const TrialBookingCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Teacher info & status
          Row(
            children: [
              // Teacher avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary,
                child: Text(
                  booking.teacherName.isNotEmpty ? booking.teacherName[0] : 'T',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space3),

              // Teacher name & instrument
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '체험레슨',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.info,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.teacherName,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: booking.status.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      booking.status.icon,
                      size: 14,
                      color: booking.status.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      booking.status.label,
                      style: AppTypography.caption.copyWith(
                        color: booking.status.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space3),

          // Lesson time
          Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondaryLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.textSecondaryLight,
                ),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  booking.timeRange,
                  style: AppTypography.bodyMedium,
                ),
                if (booking.instrument != null) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      booking.instrument!,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Change request info (if any)
          if (booking.hasChangeRequest) ...[
            const SizedBox(height: AppSpacing.space3),
            Container(
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.swap_horiz,
                    size: 16,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Text(
                    '변경 요청: ${booking.formattedRequestedDate} ${booking.requestedTimeRange}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Unavailable message (for unavailable/expired)
          if (booking.unavailableMessage != null) ...[
            const SizedBox(height: AppSpacing.space3),
            Container(
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: booking.status.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: booking.status.color,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      booking.unavailableMessage!,
                      style: AppTypography.bodySmall.copyWith(
                        color: booking.status.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action buttons
          if (booking.status.canStudentModify ||
              booking.status.canCancel ||
              booking.status.canRequestChange) ...[
            const SizedBox(height: AppSpacing.space3),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.space2,
              runSpacing: AppSpacing.space2,
              children: [
                if (booking.status.canStudentModify)
                  OutlinedButton.icon(
                    onPressed: () => _onModify(context),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('수정'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                if (booking.status.canRequestChange)
                  OutlinedButton.icon(
                    onPressed: () => _onRequestChange(context),
                    icon: const Icon(Icons.swap_horiz, size: 16),
                    label: const Text('일정 변경'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.info,
                      side: const BorderSide(color: AppColors.info),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                if (booking.status.canCancel)
                  OutlinedButton.icon(
                    onPressed: () => _onCancel(context, ref),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('취소'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
              ],
            ),
          ],

          // Retry button for unavailable/expired statuses
          if (booking.status.canRetry) ...[
            const SizedBox(height: AppSpacing.space3),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _onRetry(context),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('다른 시간으로 다시 신청'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _onModify(BuildContext context) {
    context.push(
      '${AppRoutes.trialLessonRequest}?teacherId=${booking.teacherId}&teacherName=${booking.teacherName}&bookingId=${booking.id}',
    );
  }

  void _onRequestChange(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('일정 변경 요청 기능 준비 중입니다'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('체험레슨 취소'),
        content: const Text('체험레슨 신청을 취소하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('취소하기'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(bookingsNotifierProvider.notifier).cancelBooking(
              booking.id,
              null,
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('체험레슨 신청이 취소되었습니다'),
              backgroundColor: AppColors.practiceGood,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('취소 처리 중 오류가 발생했습니다: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _onRetry(BuildContext context) {
    context.push(
      '/schedule/trial/request?teacherId=${booking.teacherId}&teacherName=${Uri.encodeComponent(booking.teacherName)}',
    );
  }
}
