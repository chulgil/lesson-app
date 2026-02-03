import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/week_calendar_widget.dart';
import '../../../../models/lesson.dart';
import '../../../../providers/providers.dart';
import '../../../../shared/widgets/collapsible_calendar.dart';

/// Schedule view type enum
enum ScheduleViewType {
  monthly('전체'),
  weekly('주간'),
  daily('일간');

  final String label;
  const ScheduleViewType(this.label);
}

/// Calendar tab with view selection (monthly/weekly/daily)
class CalendarTab extends ConsumerStatefulWidget {
  const CalendarTab({super.key});

  @override
  ConsumerState<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends ConsumerState<CalendarTab> {
  late DateTime _selectedDate;
  ScheduleViewType _viewType = ScheduleViewType.monthly;
  bool _isCalendarExpanded = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final lessonsAsync = ref.watch(lessonsProvider);

    return Column(
      children: [
        // Header with view selector
        _buildHeader(context),

        // Calendar + Lessons based on view type
        Expanded(
          child: lessonsAsync.when(
            data: (lessons) => _buildContent(lessons),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _buildErrorState(ref, error),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final dateFormat = DateFormat('M월 d일 (E)', 'ko');
    final isToday = _isSameDay(_selectedDate, DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.screenPadding,
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
                setState(() {
                  final now = DateTime.now();
                  _selectedDate = DateTime(now.year, now.month, now.day);
                });
              },
              child: Row(
                children: [
                  Text(
                    dateFormat.format(_selectedDate),
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
          IconButton(
            onPressed: () => _navigateToAddLesson(context),
            icon: const Icon(Icons.add),
            tooltip: '레슨 추가',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
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
        child: DropdownButton<ScheduleViewType>(
          value: _viewType,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          items: ScheduleViewType.values.map((type) {
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

  Widget _buildContent(List<Lesson> lessons) {
    switch (_viewType) {
      case ScheduleViewType.monthly:
        return _buildMonthlyView(lessons);
      case ScheduleViewType.weekly:
        return _buildWeeklyView(lessons);
      case ScheduleViewType.daily:
        return _buildDailyView(lessons);
    }
  }

  // ---- Monthly View ----
  Widget _buildMonthlyView(List<Lesson> lessons) {
    final lessonDates = lessons
        .map((l) => DateTime(l.date.year, l.date.month, l.date.day))
        .toSet();

    return Column(
      children: [
        // Monthly calendar using CollapsibleCalendar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: CollapsibleCalendar(
            selectedDate: _selectedDate,
            onDateSelected: (date) {
              setState(() {
                _selectedDate = date;
              });
            },
            isExpanded: _isCalendarExpanded,
            markedDates: lessonDates,
            onToggleExpand: () {
              setState(() {
                _isCalendarExpanded = !_isCalendarExpanded;
              });
            },
          ),
        ),

        // Lesson list for selected date
        Expanded(
          child: _LessonList(
            selectedDate: _selectedDate,
            lessons: lessons,
            viewType: _viewType,
          ),
        ),
      ],
    );
  }

  // ---- Weekly View ----
  Widget _buildWeeklyView(List<Lesson> lessons) {
    final lessonDates = lessons
        .map((l) => DateTime(l.date.year, l.date.month, l.date.day))
        .toSet();

    return Column(
      children: [
        // Week calendar (same as home)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: WeekCalendarWidget(
            selectedDate: _selectedDate,
            onDateSelected: (date) {
              setState(() {
                _selectedDate = date;
              });
            },
            lessonDates: lessonDates,
          ),
        ),

        const SizedBox(height: AppSpacing.space3),

        // Lesson list for selected week
        Expanded(
          child: _LessonList(
            selectedDate: _selectedDate,
            lessons: lessons,
            viewType: _viewType,
          ),
        ),
      ],
    );
  }

  // ---- Daily View ----
  Widget _buildDailyView(List<Lesson> lessons) {
    return Column(
      children: [
        // Date navigation header
        _buildDailyDateHeader(),

        const SizedBox(height: AppSpacing.space3),

        // Lesson list for selected day only
        Expanded(
          child: _LessonList(
            selectedDate: _selectedDate,
            lessons: lessons,
            viewType: _viewType,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyDateHeader() {
    final dateFormat = DateFormat('M월 d일 EEEE', 'ko');
    final isToday = _isSameDay(_selectedDate, DateTime.now());

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
                setState(() {
                  _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                });
              },
              icon: const Icon(Icons.chevron_left),
              color: AppColors.textSecondaryLight,
            ),
            GestureDetector(
              onTap: () => _showDatePicker(),
              child: Row(
                children: [
                  Text(
                    dateFormat.format(_selectedDate),
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
                setState(() {
                  _selectedDate = _selectedDate.add(const Duration(days: 1));
                });
              },
              icon: const Icon(Icons.chevron_right),
              color: AppColors.textSecondaryLight,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ko', 'KR'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  void _navigateToAddLesson(BuildContext context) {
    final now = DateTime.now();
    int nextHour = now.hour + 1;
    if (nextHour > 23) nextHour = 9;

    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    context.push('/lessons/add?date=$dateStr&hour=$nextHour');
  }

  Widget _buildErrorState(WidgetRef ref, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            '레슨 정보를 불러오는데 실패했습니다',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.space6),
          OutlinedButton.icon(
            onPressed: () {
              ref.invalidate(lessonsProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}

class _LessonList extends StatelessWidget {
  final DateTime selectedDate;
  final List<Lesson> lessons;
  final ScheduleViewType viewType;

  const _LessonList({
    required this.selectedDate,
    required this.lessons,
    required this.viewType,
  });

  @override
  Widget build(BuildContext context) {
    switch (viewType) {
      case ScheduleViewType.monthly:
      case ScheduleViewType.daily:
        return _buildDayLessonList(context);
      case ScheduleViewType.weekly:
        return _buildWeekLessonList(context);
    }
  }

  Widget _buildDayLessonList(BuildContext context) {
    final dateFormat = DateFormat('M월 d일 EEEE', 'ko');

    // Filter lessons for selected date
    final dayLessons = lessons.where((l) =>
        l.date.year == selectedDate.year &&
        l.date.month == selectedDate.month &&
        l.date.day == selectedDate.day).toList();

    // Sort by time
    dayLessons.sort((a, b) => a.startTime.compareTo(b.startTime));

    return RefreshIndicator(
      onRefresh: () async {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Only show date title for monthly view (daily view has header)
            if (viewType == ScheduleViewType.monthly) ...[
              const SizedBox(height: AppSpacing.space3),
              Row(
                children: [
                  Text(
                    dateFormat.format(selectedDate),
                    style: AppTypography.headingSmall.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  if (_isToday(selectedDate)) ...[
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
                    '${dayLessons.length}개 레슨',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space3),
            ],

            // Lessons
            Expanded(
              child: dayLessons.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: dayLessons.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.space3),
                      itemBuilder: (context, index) {
                        return _LessonTimeCard(lesson: dayLessons[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekLessonList(BuildContext context) {
    // Get the week start (Monday)
    final weekStart = selectedDate.subtract(
      Duration(days: selectedDate.weekday - 1),
    );

    // Get lessons for the entire week
    final weekLessons = <DateTime, List<Lesson>>{};
    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final dayLessons = lessons.where((l) =>
          l.date.year == day.year &&
          l.date.month == day.month &&
          l.date.day == day.day).toList();
      dayLessons.sort((a, b) => a.startTime.compareTo(b.startTime));
      if (dayLessons.isNotEmpty) {
        weekLessons[DateTime(day.year, day.month, day.day)] = dayLessons;
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
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      itemCount: sortedDays.length,
      itemBuilder: (context, index) {
        final day = sortedDays[index];
        final dayLessons = weekLessons[day]!;
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
                  '${dayLessons.length}개',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space2),
            // Day lessons
            ...dayLessons.map((lesson) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                  child: _LessonTimeCard(lesson: lesson, compact: true),
                )),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, {String? message}) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 60),
        Center(
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
                message ?? '예정된 레슨이 없습니다',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
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

class _LessonTimeCard extends StatelessWidget {
  final Lesson lesson;
  final bool compact;

  const _LessonTimeCard({
    required this.lesson,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
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
        onTap: () {
          context.push('/lessons/${lesson.id}');
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: compact ? AppSpacing.space2 : AppSpacing.space3,
          ),
          child: Row(
            children: [
              // Time column (fixed width)
              SizedBox(
                width: 56,
                child: Text(
                  lesson.startTime,
                  style: (compact ? AppTypography.bodyMedium : AppTypography.headingSmall).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.space3),

              // Info column (flexible)
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
                    if (!compact && lesson.pieces.isNotEmpty)
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
