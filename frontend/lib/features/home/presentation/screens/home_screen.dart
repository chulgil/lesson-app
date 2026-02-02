import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/debug_role_switcher.dart';
import '../../../../core/widgets/quick_tool_button.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../core/widgets/week_calendar_widget.dart';
import '../../../../models/lesson.dart';
import '../../../../providers/providers.dart';
import '../../../schedule/presentation/providers/lesson_request_providers.dart';
import '../../../calendar/presentation/screens/calendar_tab.dart';
import '../../../practice/presentation/widgets/metronome/metronome_full_screen_modal.dart';
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
    return DebugWrapper(
      child: Scaffold(
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
class _DashboardTab extends ConsumerStatefulWidget {
  const _DashboardTab();

  @override
  ConsumerState<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<_DashboardTab> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final lessonsAsync = ref.watch(lessonsProvider);
    final lessonStatsAsync = ref.watch(lessonStatsProvider);
    final paymentSummaryAsync = ref.watch(paymentSummaryProvider);

    // Get lessons for selected date
    final selectedDateLessons = lessonsAsync.whenData((lessons) {
      return lessons.where((lesson) {
        final lessonDate = lesson.date;
        return lessonDate.year == _selectedDate.year &&
            lessonDate.month == _selectedDate.month &&
            lessonDate.day == _selectedDate.day;
      }).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    });

    // Get all lesson dates for calendar markers
    final lessonDates = lessonsAsync.whenData((lessons) {
      return lessons
          .map((l) => DateTime(l.date.year, l.date.month, l.date.day))
          .toSet();
    });

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(lessonsProvider);
        ref.invalidate(lessonStatsProvider);
        ref.invalidate(paymentSummaryProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context),

            const SizedBox(height: AppSpacing.space4),

            // Week Calendar
            lessonDates.when(
              data: (dates) => WeekCalendarWidget(
                selectedDate: _selectedDate,
                onDateSelected: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                lessonDates: dates,
              ),
              loading: () => WeekCalendarWidget(
                selectedDate: _selectedDate,
                onDateSelected: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
              ),
              error: (_, __) => WeekCalendarWidget(
                selectedDate: _selectedDate,
                onDateSelected: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
              ),
            ),

            const SizedBox(height: AppSpacing.space6),

            // Selected Date Lessons
            _buildSelectedDateHeader(),
            const SizedBox(height: AppSpacing.space3),

            selectedDateLessons.when(
              data: (lessons) => _buildLessonsList(context, lessons),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.space4),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => _buildErrorCard('레슨을 불러올 수 없습니다'),
            ),

            const SizedBox(height: AppSpacing.space6),

            // Stats Row
            StatCardRow(
              cards: [
                lessonStatsAsync.when(
                  data: (stats) => StatCard(
                    title: '이번 달',
                    value: '${stats['completed'] ?? 0}회',
                    subtitle: '${stats['thisWeek'] ?? 0}회 예정',
                    color: AppColors.primary,
                    icon: Icons.calendar_today,
                  ),
                  loading: () => StatCard(
                    title: '이번 달',
                    value: '-',
                    color: AppColors.primary,
                    icon: Icons.calendar_today,
                  ),
                  error: (_, __) => StatCard(
                    title: '이번 달',
                    value: '-',
                    color: AppColors.primary,
                  ),
                ),
                paymentSummaryAsync.when(
                  data: (summary) => StatCard(
                    title: '미수금',
                    value: summary.formattedTotalPending,
                    subtitle: '${summary.unpaidStudents}명',
                    color: summary.unpaidStudents > 0
                        ? AppColors.warning
                        : AppColors.success,
                    icon: Icons.account_balance_wallet_outlined,
                    onTap: () => context.push(AppRoutes.paymentManagement),
                  ),
                  loading: () => StatCard(
                    title: '미수금',
                    value: '-',
                    color: AppColors.textSecondaryLight,
                  ),
                  error: (_, __) => StatCard(
                    title: '미수금',
                    value: '-',
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.space6),

            // Quick Tools
            Text('빠른 도구', style: AppTypography.headingMedium),
            const SizedBox(height: AppSpacing.space3),

            Row(
              children: [
                Expanded(
                  child: QuickToolButton(
                    icon: Icons.speed,
                    label: '메트로놈',
                    onTap: () => MetronomeFullScreenModal.show(context),
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: QuickToolButton(
                    icon: Icons.music_note,
                    label: '튜너',
                    onTap: () => context.push(AppRoutes.tuner),
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: QuickToolButton(
                    icon: Icons.folder_outlined,
                    label: '녹음 관리',
                    onTap: () => context.push(AppRoutes.allRecordings),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.space6),

            // Subscription Management (TEST)
            Text('수강권 관리', style: AppTypography.headingMedium),
            const SizedBox(height: AppSpacing.space3),

            Row(
              children: [
                Expanded(
                  child: QuickToolButton(
                    icon: Icons.inventory_2_outlined,
                    label: '템플릿 관리',
                    onTap: () => context.push(
                      '${AppRoutes.subscriptionTemplates}?teacherId=teacher_1',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: QuickToolButton(
                    icon: Icons.send_outlined,
                    label: '제안 보내기',
                    onTap: () => context.push(
                      '${AppRoutes.proposalCreate}?teacherId=teacher_1',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: QuickToolButton(
                    icon: Icons.check_circle_outline,
                    label: '입금 확인',
                    onTap: () => context.push(
                      '${AppRoutes.proposalConfirm}?teacherId=teacher_1',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.space8),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'lesson-app',
          style: AppTypography.headingLarge.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            _buildLessonRequestsButton(context),
            _buildPendingBookingsButton(context),
            IconButton(
              onPressed: () => context.push(AppRoutes.notifications),
              icon: const Icon(Icons.notifications_outlined),
              tooltip: '알림',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectedDateHeader() {
    final isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;

    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[_selectedDate.weekday - 1];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isToday
              ? '오늘의 레슨'
              : '${_selectedDate.month}/${_selectedDate.day} ($weekday) 레슨',
          style: AppTypography.headingMedium,
        ),
        TextButton.icon(
          onPressed: () => context.push('/lessons/add'),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('추가'),
        ),
      ],
    );
  }

  Widget _buildLessonRequestsButton(BuildContext context) {
    final teacherId = ref.watch(currentUserIdProvider);
    final pendingCountAsync =
        ref.watch(pendingLessonRequestCountProvider(teacherId));

    return pendingCountAsync.when(
      data: (count) {
        return Stack(
          children: [
            IconButton(
              onPressed: () => context.push(
                AppRoutes.lessonRequests,
                extra: {'teacherId': teacherId},
              ),
              icon: const Icon(Icons.person_add_outlined),
              tooltip: '레슨 요청',
            ),
            if (count > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: const TextStyle(
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
      loading: () => IconButton(
        onPressed: () => context.push(
          AppRoutes.lessonRequests,
          extra: {'teacherId': teacherId},
        ),
        icon: const Icon(Icons.person_add_outlined),
        tooltip: '레슨 요청',
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildPendingBookingsButton(BuildContext context) {
    final teacherId = ref.watch(currentUserIdProvider);
    final pendingCountAsync = ref.watch(pendingBookingsCountProvider(teacherId));

    return pendingCountAsync.when(
      data: (count) {
        return Stack(
          children: [
            IconButton(
              onPressed: () => context.push(AppRoutes.pendingBookings),
              icon: const Icon(Icons.event_note_outlined),
              tooltip: '승인 대기',
            ),
            if (count > 0)
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
      loading: () => IconButton(
        onPressed: () => context.push(AppRoutes.pendingBookings),
        icon: const Icon(Icons.event_note_outlined),
        tooltip: '승인 대기',
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildLessonsList(BuildContext context, List<Lesson> lessons) {
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
              '예정된 레슨이 없습니다',
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
}

// ---- Widgets ----

class _LessonCard extends ConsumerWidget {
  final Lesson lesson;
  final VoidCallback onTap;

  const _LessonCard({
    required this.lesson,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border(
          left: BorderSide(
            color: _getStatusColor(),
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space3,
          ),
          child: Row(
            children: [
              // Time column (fixed width)
              SizedBox(
                width: 56,
                child: Text(
                  lesson.startTime,
                  style: AppTypography.headingSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.space3),

              // Info section (flexible)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${lesson.studentName} · ${lesson.instrument}',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (lesson.pieces.isNotEmpty)
                      Text(
                        lesson.pieces.first.displayName,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Status (fixed width)
              SizedBox(
                width: 36,
                child: Text(
                  _getStatusLabel(),
                  style: AppTypography.caption.copyWith(
                    color: _getStatusColor(),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),

              const SizedBox(width: AppSpacing.space1),

              // Arrow
              const Icon(
                Icons.chevron_right,
                color: AppColors.textTertiaryLight,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusLabel() {
    switch (lesson.status) {
      case LessonStatus.scheduled:
      case LessonStatus.reschedulePending:
        return '예정';
      case LessonStatus.completed:
        return '완료';
      case LessonStatus.cancelled:
      case LessonStatus.cancelledByStudentAdvance:
      case LessonStatus.cancelledByTeacher:
      case LessonStatus.cancelledMutual:
        return '취소';
      case LessonStatus.noShow:
      case LessonStatus.cancelledByStudentLate:
      case LessonStatus.studentAbsent:
        return '결석';
    }
  }

  Color _getStatusColor() {
    switch (lesson.status) {
      case LessonStatus.scheduled:
      case LessonStatus.reschedulePending:
        return AppColors.primary;
      case LessonStatus.completed:
        return AppColors.success;
      case LessonStatus.cancelled:
      case LessonStatus.cancelledByStudentAdvance:
      case LessonStatus.cancelledByTeacher:
      case LessonStatus.cancelledMutual:
        return AppColors.textTertiaryLight;
      case LessonStatus.noShow:
      case LessonStatus.cancelledByStudentLate:
      case LessonStatus.studentAbsent:
        return AppColors.error;
    }
  }
}

