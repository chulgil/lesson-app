import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/lesson.dart';
import '../../../../models/student.dart';
import '../../../../providers/providers.dart';
import '../../../calendar/presentation/screens/calendar_tab.dart';
import '../../../profile/presentation/screens/profile_tab.dart';
import '../../../students/presentation/screens/students_tab.dart';

/// Home screen (Teacher Dashboard)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: const [
            _DashboardTab(),
            CalendarTab(),
            StudentsTab(),
            ProfileTab(),
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
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: '캘린더',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: '학생',
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

/// Dashboard Tab with Riverpod
class _DashboardTab extends ConsumerWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final dateFormat = DateFormat('M월 d일 EEEE', 'ko');

    final todayLessonsAsync = ref.watch(todayLessonsProvider);
    final studentsAsync = ref.watch(studentsNotifierProvider);
    final lessonStatsAsync = ref.watch(lessonStatsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(todayLessonsProvider);
        ref.invalidate(studentsNotifierProvider);
        ref.invalidate(lessonStatsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                      '안녕하세요, 김선생님 👋',
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
                    // Pending bookings button with badge
                    _buildPendingBookingsButton(context, ref),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.notifications_outlined),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.space6),

            // Today's Lessons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('오늘의 레슨', style: AppTypography.headingMedium),
                todayLessonsAsync.when(
                  data: (lessons) => Text(
                    '${lessons.length}개',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space3),

            todayLessonsAsync.when(
              data: (lessons) => _buildTodayLessons(context, lessons),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.space4),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => _buildErrorCard('레슨을 불러올 수 없습니다'),
            ),

            const SizedBox(height: AppSpacing.space3),

            // Add Lesson Button
            OutlinedButton.icon(
              onPressed: () {
                context.push('/lessons/add');
              },
              icon: const Icon(Icons.add),
              label: const Text('레슨 추가'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),

            const SizedBox(height: AppSpacing.space8),

            // Student Overview
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('학생 현황', style: AppTypography.headingMedium),
                TextButton(
                  onPressed: () {
                    // Navigate to students tab would require state lifting
                  },
                  child: const Text('더보기'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space3),

            studentsAsync.when(
              data: (students) => _buildStudentOverview(context, students),
              loading: () => const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => _buildErrorCard('학생 정보를 불러올 수 없습니다'),
            ),

            const SizedBox(height: AppSpacing.space8),

            // Weekly Stats
            Text('이번 주 통계', style: AppTypography.headingMedium),
            const SizedBox(height: AppSpacing.space3),

            lessonStatsAsync.when(
              data: (stats) => _buildWeeklyStats(stats),
              loading: () => const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => _buildErrorCard('통계를 불러올 수 없습니다'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayLessons(BuildContext context, List<Lesson> lessons) {
    if (lessons.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondaryLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        child: Row(
          children: [
            Icon(Icons.event_available, color: AppColors.textTertiaryLight),
            const SizedBox(width: AppSpacing.space3),
            Text(
              '오늘 예정된 레슨이 없습니다',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: lessons.map((lesson) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.space3),
          child: _LessonCard(
            lesson: lesson,
            onTap: () => context.push('/lessons/${lesson.id}'),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStudentOverview(BuildContext context, List<Student> students) {
    if (students.isEmpty) {
      return Container(
        height: 100,
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondaryLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, color: AppColors.textTertiaryLight),
              const SizedBox(height: AppSpacing.space2),
              Text(
                '등록된 학생이 없습니다',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: students.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.space3),
        itemBuilder: (context, index) {
          final student = students[index];
          return _StudentThumbnail(
            student: student,
            onTap: () => context.push('/students/${student.id}'),
          );
        },
      ),
    );
  }

  Widget _buildWeeklyStats(Map<String, int> stats) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: '레슨 완료',
            value: '${stats['completed'] ?? 0}회',
            icon: Icons.check_circle_outline,
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: _StatCard(
            label: '이번 주 레슨',
            value: '${stats['thisWeek'] ?? 0}회',
            icon: Icons.calendar_today,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: AppSpacing.space3),
          Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingBookingsButton(BuildContext context, WidgetRef ref) {
    // TODO: Replace with actual teacher ID from auth provider
    const teacherId = 'teacher_1';
    final pendingCountAsync = ref.watch(pendingBookingsCountProvider(teacherId));

    return pendingCountAsync.when(
      data: (count) {
        if (count == 0) return const SizedBox.shrink();

        return Stack(
          children: [
            IconButton(
              onPressed: () => context.push(AppRoutes.pendingBookings),
              icon: const Icon(Icons.event_note),
              tooltip: '승인 대기',
            ),
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ---- Widgets ----

class _LessonCard extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback onTap;

  const _LessonCard({
    required this.lesson,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border(
          left: BorderSide(
            color: AppColors.primary,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Row(
            children: [
              // Time and Icon
              Column(
                children: [
                  const Icon(Icons.music_note, color: AppColors.primary),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    lesson.startTime,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.space4),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${lesson.studentName} | ${lesson.instrument}',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (lesson.pieces.isNotEmpty)
                      Text(
                        lesson.pieces.first.displayName,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                  ],
                ),
              ),

              // Status badge
              if (lesson.status == LessonStatus.completed)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.practiceGood.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '완료',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.practiceGood,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              const SizedBox(width: AppSpacing.space2),

              // Arrow
              const Icon(
                Icons.chevron_right,
                color: AppColors.textTertiaryLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentThumbnail extends StatelessWidget {
  final Student student;
  final VoidCallback onTap;

  const _StudentThumbnail({
    required this.student,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(AppSpacing.space3),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status dot
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: student.practiceStatus.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),

            // Name
            Text(
              student.name,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.space1),

            // Practice count
            Text(
              '${student.practiceRate}/7',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              Icon(icon, color: AppColors.primary, size: 20),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTypography.headingLarge,
            ),
          ),
        ],
      ),
    );
  }
}
