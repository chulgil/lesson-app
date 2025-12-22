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

/// Student lessons tab showing upcoming and past lessons
class StudentLessonsTab extends ConsumerWidget {
  const StudentLessonsTab({super.key});

  // TODO: Replace with actual student ID from auth
  static const _currentStudentId = 'student_1';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentBookings = ref.watch(studentBookingsProvider(_currentStudentId));

    final trialBookings = studentBookings.whenOrNull(
          data: (bookings) => bookings
              .where((b) => b.lessonType == LessonType.trial)
              .where((b) => b.status.isActive || b.status.canRetry)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        ) ??
        [];

    final upcomingLessons = _mockUpcomingLessons();
    final pastLessons = _mockPastLessons();

    // Group past lessons by month
    final groupedPastLessons = <String, List<_StudentLessonData>>{};
    for (final lesson in pastLessons) {
      final monthKey = DateFormat('yyyy년 M월', 'ko').format(lesson.dateTime);
      groupedPastLessons.putIfAbsent(monthKey, () => []).add(lesson);
    }

    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.space4,
              AppSpacing.screenPadding,
              0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('내 레슨', style: AppTypography.headingLarge),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.calendar_month_outlined),
                  tooltip: '캘린더 보기',
                ),
              ],
            ),
          ),
        ),

        // Trial Lesson Button
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.space3,
              AppSpacing.screenPadding,
              0,
            ),
            child: _buildTrialLessonButton(context),
          ),
        ),

        // Trial Lesson Bookings Section
        if (trialBookings.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.space4,
                AppSpacing.screenPadding,
                AppSpacing.space3,
              ),
              child: Text('내 체험레슨', style: AppTypography.headingSmall),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                  child: TrialBookingCard(booking: trialBookings[index]),
                ),
                childCount: trialBookings.length,
              ),
            ),
          ),
        ],

        // Loading state for bookings
        if (studentBookings.isLoading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.space4),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),

        // Upcoming Lessons Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.space4,
              AppSpacing.screenPadding,
              AppSpacing.space3,
            ),
            child: Text('예정된 레슨', style: AppTypography.headingSmall),
          ),
        ),

        if (upcomingLessons.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.space4,
              ),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.space4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondaryLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_available,
                      size: 32,
                      color: AppColors.textTertiaryLight,
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Expanded(
                      child: Text(
                        '예정된 레슨이 없습니다',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _LessonCard(
                  lesson: upcomingLessons[index],
                  isUpcoming: true,
                ),
                childCount: upcomingLessons.length,
              ),
            ),
          ),

        // Past Lessons Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.space4,
              AppSpacing.screenPadding,
              AppSpacing.space3,
            ),
            child: Text('지난 레슨', style: AppTypography.headingSmall),
          ),
        ),

        if (pastLessons.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.space4,
              ),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.space4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondaryLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.history,
                      size: 32,
                      color: AppColors.textTertiaryLight,
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Expanded(
                      child: Text(
                        '지난 레슨이 없습니다',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...groupedPastLessons.entries.expand((entry) => [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPadding,
                      AppSpacing.space2,
                      AppSpacing.screenPadding,
                      AppSpacing.space2,
                    ),
                    child: Text(
                      entry.key,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _LessonCard(
                        lesson: entry.value[index],
                        isUpcoming: false,
                      ),
                      childCount: entry.value.length,
                    ),
                  ),
                ),
              ]),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: AppSpacing.space6),
        ),
      ],
    );
  }

  /// Build trial lesson button
  Widget _buildTrialLessonButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: () {
          context.push(AppRoutes.selectTeacher);
        },
        icon: const Icon(Icons.add),
        label: const Text('새로운 선생님과 레슨하기'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          ),
        ),
      ),
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
                  // Date column
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
                          '${lesson.dateTime.day}',
                          style: AppTypography.headingMedium.copyWith(
                            color:
                                isUpcoming ? AppColors.primary : AppColors.textSecondaryLight,
                          ),
                        ),
                        Text(
                          DateFormat('E', 'ko').format(lesson.dateTime),
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
                        const SizedBox(height: AppSpacing.space1),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: AppColors.textTertiaryLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${timeFormat.format(lesson.dateTime)} (${lesson.duration}분)',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // D-day or status
                  if (isUpcoming)
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

            // Lesson content preview (for upcoming)
            if (isUpcoming && lesson.piece != null) ...[
              Divider(
                height: 1,
                color: AppColors.borderLight,
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.space3),
                child: Row(
                  children: [
                    Icon(
                      Icons.music_note,
                      size: 16,
                      color: AppColors.textTertiaryLight,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Expanded(
                      child: Text(
                        lesson.piece!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

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
                    Text(
                      booking.teacherName,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (booking.instrument != null)
                      Text(
                        booking.instrument!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondaryLight,
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

          // Lesson date/time
          Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondaryLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppColors.textSecondaryLight,
                ),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  booking.formattedDate,
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(width: AppSpacing.space3),
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

          // Unavailable message (for unavailable/expired - softer display)
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
          if (booking.status.canStudentModify || booking.status.canCancel || booking.status.canRequestChange) ...[
            const SizedBox(height: AppSpacing.space3),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.space2,
              runSpacing: AppSpacing.space2,
              children: [
                // Modify button (pending only)
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

                // Request schedule change (confirmed only)
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

                // Cancel button
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
    // Navigate to trial lesson request screen with existing data
    context.push(
      '${AppRoutes.trialLessonRequest}?teacherId=${booking.teacherId}&teacherName=${booking.teacherName}&bookingId=${booking.id}',
    );
  }

  void _onRequestChange(BuildContext context) {
    // TODO: Implement schedule change request screen
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
    // Navigate to trial lesson request with teacher pre-selected
    context.push(
      '/schedule/trial/request?teacherId=${booking.teacherId}&teacherName=${Uri.encodeComponent(booking.teacherName)}',
    );
  }
}
