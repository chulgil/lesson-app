import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/debug_role_switcher.dart';
import '../../../../main.dart' show getStartupRecoveryResult, clearStartupRecoveryResult;
import '../../../../models/lesson_booking.dart';
import '../../../../providers/booking/booking_providers.dart';
import '../../../practice/presentation/widgets/goal/goal_progress_widget.dart';
import '../../../practice/presentation/widgets/practice_streak_card.dart';
import '../../../practice/presentation/widgets/practice_tools_modal.dart';
import '../widgets/weekly_practice_widget.dart';
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
  void initState() {
    super.initState();
    // Show recording recovery message if any recordings were recovered at startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final result = getStartupRecoveryResult();
      if (result != null && mounted) {
        // Always show diagnostic message if there are recordings in DB
        if (result.total > 0) {
          String message;
          Color bgColor;

          if (result.recovered > 0 || result.cleanedUp > 0) {
            final parts = <String>[];
            if (result.recovered > 0) {
              parts.add('${result.recovered}개 복구');
            }
            if (result.cleanedUp > 0) {
              parts.add('${result.cleanedUp}개 정리');
            }
            message = '녹음 파일: ${parts.join(', ')} (전체 ${result.total}개)';
            bgColor = AppColors.success;
          } else {
            message = '녹음 파일 ${result.total}개 확인됨 (복구 불필요)';
            bgColor = AppColors.info;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              duration: const Duration(seconds: 4),
              backgroundColor: bgColor,
            ),
          );
        }
        clearStartupRecoveryResult();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DebugWrapper(
      child: Scaffold(
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
        // Show metronome/tuner button on home and lessons tabs
        floatingActionButton: (_currentIndex == 0 || _currentIndex == 1)
            ? FloatingActionButton(
                onPressed: () => PracticeToolsModal.show(context),
                child: const Icon(Icons.music_note),
              )
            : null,
        bottomNavigationBar: _buildBottomNavigation(),
      ),
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
              Row(
                children: [
                  // Invite button
                  IconButton(
                    onPressed: () => context.push(AppRoutes.invite),
                    icon: const Icon(Icons.person_add_outlined),
                    tooltip: '선생님 초대',
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_outlined),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space6),

          // Practice Streak Card (NEW)
          const PracticeStreakCard(studentId: currentStudentId),

          const SizedBox(height: AppSpacing.space4),

          // Practice Goal Widget
          GoalProgressWidget(
            studentId: currentStudentId,
            onSettingsTap: () {
              context.push(
                '${AppRoutes.practiceGoalSettings}?studentId=$currentStudentId',
              );
            },
          ),

          const SizedBox(height: AppSpacing.space4),

          // Next Lesson Card
          _buildNextLessonCard(context),

          const SizedBox(height: AppSpacing.space6),

          // My Trial Lessons Section
          _TrialBookingsSection(studentId: currentStudentId),

          const SizedBox(height: AppSpacing.space6),

          // This Week's Practice (from teacher assignments)
          WeeklyPracticeWidget(
            studentId: currentStudentId,
            showHeader: true,
            onViewAll: () {
              // TODO: Navigate to full practice list
            },
          ),

          const SizedBox(height: AppSpacing.space6),

          // Weekly Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('이번 주 연습 현황', style: AppTypography.headingMedium),
              TextButton(
                onPressed: () {
                  context.push(
                    '${AppRoutes.practiceStats}?studentId=$currentStudentId',
                  );
                },
                child: const Text('통계 보기'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),

          _buildWeeklyProgress(context, currentStudentId),

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

  Widget _buildNextLessonCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to lesson detail or lessons tab
        // TODO: Connect to actual next lesson data
      },
      child: Container(
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
      ),
    );
  }

  Widget _buildWeeklyProgress(BuildContext context, String studentId) {
    final days = ['월', '화', '수', '목', '금', '토', '일'];
    final progress = [1.0, 0.8, 0.6, 0.0, 0.0, 0.0, 0.0]; // 0-1 scale
    final today = DateTime.now().weekday - 1; // 0-indexed

    return GestureDetector(
      onTap: () {
        context.push('${AppRoutes.practiceStats}?studentId=$studentId');
      },
      child: Container(
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

/// Trial bookings section for student dashboard
class _TrialBookingsSection extends ConsumerWidget {
  final String studentId;

  const _TrialBookingsSection({required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(studentBookingsProvider(studentId));

    return bookingsAsync.when(
      data: (bookings) {
        // Filter for active trial bookings
        final trialBookings = bookings
            .where((b) => b.lessonType == LessonType.trial)
            .where((b) => b.status.isActive || b.status.canRetry)
            .toList()
          ..sort((a, b) => a.lessonDate.compareTo(b.lessonDate));

        if (trialBookings.isEmpty) {
          return _buildEmptyState(context);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('내 체험레슨', style: AppTypography.headingMedium),
                TextButton.icon(
                  onPressed: () => context.push(AppRoutes.selectTeacher),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('신청'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space3),

            // Booking cards (show max 2)
            ...trialBookings.take(2).map((booking) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                  child: _CompactTrialBookingCard(booking: booking),
                )),

            // View all button if more than 2
            if (trialBookings.length > 2)
              Center(
                child: TextButton(
                  onPressed: () {
                    // Switch to lessons tab - this is a workaround
                    // In a real app, we'd use a callback or state management
                  },
                  child: Text('${trialBookings.length - 2}개 더보기'),
                ),
              ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(
          color: AppColors.borderLight,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.school_outlined,
            size: 40,
            color: AppColors.textTertiaryLight,
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            '새로운 선생님과 레슨을 시작해보세요',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          FilledButton.icon(
            onPressed: () => context.push(AppRoutes.selectTeacher),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('체험레슨 신청'),
          ),
        ],
      ),
    );
  }
}

/// Compact trial booking card for dashboard
class _CompactTrialBookingCard extends StatelessWidget {
  final LessonBooking booking;

  const _CompactTrialBookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: InkWell(
        onTap: () {
          context.push(AppRoutes.bookingDetail.replaceFirst(':id', booking.id));
        },
        child: Row(
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

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        booking.teacherName,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (booking.instrument != null) ...[
                        const SizedBox(width: AppSpacing.space2),
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
                  const SizedBox(height: 2),
                  Text(
                    booking.timeRange,
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
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: booking.status.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                booking.status.label,
                style: AppTypography.caption.copyWith(
                  color: booking.status.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
