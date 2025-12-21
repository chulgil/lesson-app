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
import 'student_lessons_tab.dart';
import 'student_practice_tab.dart';
import 'student_profile_tab.dart';

/// Student home screen with practice dashboard
class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: const [
            _StudentDashboardTab(),
            StudentLessonsTab(),
            StudentPracticeTab(),
            StudentProfileTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: '레슨',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center_outlined),
            activeIcon: Icon(Icons.fitness_center),
            label: '연습',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '프로필',
          ),
        ],
      ),
    );
  }
}

/// Student Dashboard Tab
class _StudentDashboardTab extends ConsumerWidget {
  const _StudentDashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final dateFormat = DateFormat('M월 d일 EEEE', 'ko');

    // TODO: Replace with actual student ID from auth
    const currentStudentId = 'student_1';
    final studentBookings = ref.watch(studentBookingsProvider(currentStudentId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '안녕하세요, 홍길동님 🎻',
                    style: AppTypography.headingLarge,
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    dateFormat.format(now),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space6),

          // Trial Lesson Section (NEW - moved to top)
          _buildTrialLessonButton(context),

          const SizedBox(height: AppSpacing.space4),

          // Trial Lesson Bookings List
          studentBookings.when(
            data: (bookings) {
              final trialBookings = bookings
                  .where((b) => b.lessonType == LessonType.trial)
                  .where((b) => b.status.isActive || b.status.canRetry)
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

              if (trialBookings.isEmpty) {
                return const SizedBox.shrink();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('내 체험레슨', style: AppTypography.headingSmall),
                  const SizedBox(height: AppSpacing.space3),
                  ...trialBookings.map((booking) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                        child: _TrialBookingCard(booking: booking),
                      )),
                  const SizedBox(height: AppSpacing.space4),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.space4),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Next Lesson Card
          _buildNextLessonCard(),

          const SizedBox(height: AppSpacing.space6),

          // Today's Practice
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('오늘의 연습', style: AppTypography.headingMedium),
              TextButton(
                onPressed: () {},
                child: const Text('전체보기'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),

          _buildPracticeChecklist(),

          const SizedBox(height: AppSpacing.space6),

          // Weekly Progress
          Text('이번 주 연습 현황', style: AppTypography.headingMedium),
          const SizedBox(height: AppSpacing.space3),

          _buildWeeklyProgress(),

          const SizedBox(height: AppSpacing.space6),

          // Teacher Feedback
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('선생님 피드백', style: AppTypography.headingMedium),
              TextButton(
                onPressed: () {},
                child: const Text('더보기'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),

          _buildTeacherFeedback(),
        ],
      ),
    );
  }

  /// Build trial lesson button (at top)
  Widget _buildTrialLessonButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: () {
          // TODO: Replace with teacher selection screen
          context.push(
            '${AppRoutes.trialLessonRequest}?teacherId=teacher_1&teacherName=김선생님',
          );
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

  Widget _buildNextLessonCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '다음 레슨',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'D-2',
                style: AppTypography.headingMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  '김',
                  style: AppTypography.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '김선생님',
                      style: AppTypography.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '바이올린',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space3),

          Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  '12월 23일 (월) 14:00',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeChecklist() {
    final tasks = [
      _PracticeTask(
        title: '스케일 연습',
        subtitle: 'G Major, 3옥타브',
        duration: '15분',
        isCompleted: true,
      ),
      _PracticeTask(
        title: '에튀드',
        subtitle: '크로이처 2번 - 1~16마디',
        duration: '20분',
        isCompleted: true,
      ),
      _PracticeTask(
        title: '바흐 파르티타 2번',
        subtitle: 'Allemande - 느린 템포로',
        duration: '30분',
        isCompleted: false,
      ),
      _PracticeTask(
        title: '바흐 파르티타 2번',
        subtitle: 'Sarabande - 보잉 연습',
        duration: '20분',
        isCompleted: false,
      ),
    ];

    final completedCount = tasks.where((t) => t.isCompleted).length;

    return Container(
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
      child: Column(
        children: [
          // Progress header
          Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondaryLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.radiusLarge),
                topRight: Radius.circular(AppSpacing.radiusLarge),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '진행률',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const Spacer(),
                Text(
                  '$completedCount/${tasks.length}',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
                SizedBox(
                  width: 100,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: completedCount / tasks.length,
                      backgroundColor: AppColors.borderLight,
                      valueColor: AlwaysStoppedAnimation(
                        completedCount == tasks.length
                            ? AppColors.practiceGood
                            : AppColors.primary,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tasks
          ...tasks.map((task) => _PracticeTaskTile(task: task)),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgress() {
    final days = ['월', '화', '수', '목', '금', '토', '일'];
    final progress = [1.0, 0.8, 0.6, 0.0, 0.0, 0.0, 0.0]; // 0-1 scale
    final today = DateTime.now().weekday - 1; // 0-indexed

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
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
      child: Column(
        children: [
          // Stats row
          Row(
            children: [
              _buildStatItem('연습한 날', '3일'),
              const SizedBox(width: AppSpacing.space4),
              _buildStatItem('총 연습 시간', '4시간 30분'),
              const SizedBox(width: AppSpacing.space4),
              _buildStatItem('달성률', '75%'),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),
          const Divider(),
          const SizedBox(height: AppSpacing.space4),

          // Weekly bar chart
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final isToday = index == today;
              final isFuture = index > today;
              final value = progress[index];

              return Column(
                children: [
                  // Bar
                  Container(
                    width: 32,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondaryLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 32,
                      height: 80 * value,
                      decoration: BoxDecoration(
                        color: isFuture
                            ? AppColors.borderLight
                            : value >= 0.8
                                ? AppColors.practiceGood
                                : value >= 0.5
                                    ? AppColors.practiceNormal
                                    : value > 0
                                        ? AppColors.practicePoor
                                        : AppColors.borderLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space2),

                  // Day label
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      days[index],
                      style: AppTypography.caption.copyWith(
                        color: isToday
                            ? Colors.white
                            : AppColors.textSecondaryLight,
                        fontWeight: isToday ? FontWeight.w600 : null,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.headingSmall.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherFeedback() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  '김',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '김선생님',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '12월 18일',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space3),

          Text(
            '이번 주 바흐 파르티타 연습 잘 하고 있어요! '
            'Allemande 부분에서 보잉이 많이 좋아졌습니다. '
            '다음 레슨까지 Sarabande 첫 페이지 천천히 읽어오세요.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
              height: 1.5,
            ),
          ),

          const SizedBox(height: AppSpacing.space3),

          // Tags
          Wrap(
            spacing: AppSpacing.space2,
            children: [
              _buildTag('보잉 개선', AppColors.practiceGood),
              _buildTag('Sarabande 예습', AppColors.info),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _PracticeTask {
  final String title;
  final String subtitle;
  final String duration;
  final bool isCompleted;

  _PracticeTask({
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.isCompleted,
  });
}

class _PracticeTaskTile extends StatefulWidget {
  final _PracticeTask task;

  const _PracticeTaskTile({required this.task});

  @override
  State<_PracticeTaskTile> createState() => _PracticeTaskTileState();
}

class _PracticeTaskTileState extends State<_PracticeTaskTile> {
  late bool _isCompleted;

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.task.isCompleted;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() => _isCompleted = !_isCompleted);
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.borderLight, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _isCompleted
                    ? AppColors.practiceGood
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isCompleted
                      ? AppColors.practiceGood
                      : AppColors.borderLight,
                  width: 2,
                ),
              ),
              child: _isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),

            const SizedBox(width: AppSpacing.space3),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.task.title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration:
                          _isCompleted ? TextDecoration.lineThrough : null,
                      color: _isCompleted
                          ? AppColors.textTertiaryLight
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    widget.task.subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),

            // Duration
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondaryLight,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.task.duration,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Trial Booking Card - displays a single trial lesson booking with status and actions
class _TrialBookingCard extends ConsumerWidget {
  final LessonBooking booking;

  const _TrialBookingCard({required this.booking});

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

