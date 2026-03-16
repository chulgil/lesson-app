import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/instrument_colors.dart';
import '../../../../core/utils/name_utils.dart';
import '../../../../models/lesson.dart';
import '../../domain/entities/teacher_availability.dart';
import '../providers/teacher_availability_providers.dart';
import '../providers/week_lessons_provider.dart';

/// Weekly summary grid showing 7-day overview of lessons.
/// Bird's eye view with instrument-colored cells, today highlight,
/// and drill-down to timeline view.
class ScheduleWeeklyGridView extends ConsumerStatefulWidget {
  final DateTime selectedDate;

  const ScheduleWeeklyGridView({super.key, required this.selectedDate});

  @override
  ConsumerState<ScheduleWeeklyGridView> createState() =>
      _ScheduleWeeklyGridViewState();
}

class _ScheduleWeeklyGridViewState
    extends ConsumerState<ScheduleWeeklyGridView> {
  final ScrollController _scrollController = ScrollController();

  DateTime get _weekStart => getWeekStart(widget.selectedDate);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weekLessonsAsync = ref.watch(weekLessonsProvider(_weekStart));
    final availabilityAsync =
        ref.watch(teacherAvailabilityProvider('teacher_1'));

    return weekLessonsAsync.when(
      data: (lessons) {
        final availability = availabilityAsync.valueOrNull;
        return _buildGrid(lessons, availability);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('불러오기 실패: $e')),
    );
  }

  Widget _buildGrid(List<Lesson> lessons, TeacherAvailability? availability) {
    if (lessons.isEmpty) {
      return _buildEmptyWeek();
    }

    final (startHour, endHour) = _getVisibleRange(lessons);
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);

    // Group lessons by day and time
    final lessonMap = _buildLessonMap(lessons);

    // Count unique lessons per day (not slots)
    final uniqueLessonCounts = _countUniqueLessons(lessons);

    // Determine rest days from teacher availability
    final restDays = _getRestDays(availability);

    // Check if current week contains today
    final isCurrentWeek = _weekStart.isBefore(now.add(const Duration(days: 1))) &&
        _weekStart.add(const Duration(days: 7)).isAfter(now);
    final todayIndex = isCurrentWeek ? (now.weekday - 1) : -1;

    return Column(
      children: [
        // Grid + Summary
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space2,
                    ),
                    child: _buildGridBody(
                      lessonMap,
                      uniqueLessonCounts,
                      startHour,
                      endHour,
                      todayDate,
                      restDays,
                      todayIndex: todayIndex,
                      now: now,
                    ),
                  ),
                ),
              ),
              // Summary bar (fixed at bottom)
              _buildSummaryBar(lessons),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGridBody(
    Map<int, Map<int, Lesson>> lessonMap,
    Map<int, int> uniqueLessonCounts,
    int startHour,
    int endHour,
    DateTime todayDate,
    Set<int> restDays, {
    int todayIndex = -1,
    DateTime? now,
  }) {
    final cellWidth =
        (MediaQuery.of(context).size.width - AppSpacing.space2 * 2 - 36) / 7;
    const cellHeight = 28.0;
    final totalGridRows = endHour - startHour + 1;
    final gridHeight = totalGridRows * cellHeight * 2;

    // No day headers here — CompactWeekStrip already shows days

    // Build the grid rows
    final gridRows = List.generate(totalGridRows, (hourIndex) {
      final hour = startHour + hourIndex;
      return SizedBox(
        height: cellHeight * 2,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 36,
              child: Text(
                '$hour',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiaryLight,
                  fontSize: 10,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            ...List.generate(7, (dayIndex) {
              final dayDate = _weekStart.add(Duration(days: dayIndex));
              final dayType = _getDayType(dayDate, todayDate);
              final isRestDay = restDays.contains(dayIndex);
              final columnBg = _getColumnBackground(dayType, isRestDay);

              return SizedBox(
                width: cellWidth,
                height: cellHeight * 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: columnBg),
                  child: Column(
                    children: [
                      Container(
                        height: 0.5,
                        color: AppColors.scheduleGridLine,
                      ),
                      Expanded(
                        child: _buildGridCell(
                          lessonMap, dayIndex, hour * 60,
                          cellWidth, cellHeight,
                          dayType: dayType,
                        ),
                      ),
                      Expanded(
                        child: _buildGridCell(
                          lessonMap, dayIndex, hour * 60 + 30,
                          cellWidth, cellHeight,
                          dayType: dayType,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      );
    });

    // Use Stack to overlay the now indicator on the grid
    return SizedBox(
      height: gridHeight,
      child: Stack(
        children: [
          // Grid content
          Column(children: gridRows),
          // Now indicator (red line on today's column)
          if (todayIndex >= 0 && now != null)
            _buildNowIndicator(
              now, startHour, cellWidth, cellHeight, todayIndex,
            ),
        ],
      ),
    );
  }

  /// Build a "now" indicator line on today's column in the weekly grid.
  Widget _buildNowIndicator(
    DateTime now,
    int startHour,
    double cellWidth,
    double cellHeight,
    int todayIndex,
  ) {
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = startHour * 60;
    final top = ((nowMinutes - startMinutes) / 30.0) * cellHeight;

    // Only show if within grid range
    if (top < 0) return const SizedBox.shrink();

    final leftOffset = 36.0 + todayIndex * cellWidth;

    return Positioned(
      top: top,
      left: leftOffset,
      width: cellWidth,
      child: Row(
        children: [
          // Red circle node
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.scheduleNowIndicator,
              shape: BoxShape.circle,
            ),
          ),
          // Red line
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.scheduleNowIndicator.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCell(
    Map<int, Map<int, Lesson>> lessonMap,
    int dayIndex,
    int slotMinutes,
    double width,
    double height, {
    _DayType dayType = _DayType.future,
  }) {
    final lesson = lessonMap[dayIndex]?[slotMinutes];
    if (lesson == null) {
      // Empty slot — tap to add lesson at this time
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          final date = _weekStart.add(Duration(days: dayIndex));
          final hour = slotMinutes ~/ 60;
          final minute = slotMinutes % 60;
          _navigateToAddLesson(date, hour, minute);
        },
        child: SizedBox(width: width, height: height),
      );
    }

    final baseColors = InstrumentColors.getColor(lesson.instrument);

    // Color logic by day type:
    // - today → vivid instrument colors
    // - past → grey muted
    // - future → instrument colors (slightly muted)
    final InstrumentColorPair colors;
    switch (dayType) {
      case _DayType.today:
        colors = baseColors;
      case _DayType.past:
        colors = const InstrumentColorPair(
          AppColors.scheduleMutedBackground,
          AppColors.scheduleMutedAccent,
        );
      case _DayType.future:
        colors = InstrumentColorPair(
          baseColors.background.withValues(alpha: 0.7),
          baseColors.accent.withValues(alpha: 0.7),
        );
    }

    // Check if this is the start slot of a lesson
    final parts = lesson.startTime.split(':');
    final lessonStartMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    final isStartSlot = slotMinutes == lessonStartMinutes;

    if (!isStartSlot) {
      // Continuation slot — show colored background only
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          context.push(AppRoutes.lessonDetail.replaceFirst(':id', lesson.id));
        },
        child: Container(
          width: width - 2,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: colors.background,
            border: Border(
              left: BorderSide(color: colors.accent, width: 2),
            ),
          ),
        ),
      );
    }

    // Start slot — show given name with colored background
    final shortName = NameUtils.givenName(lesson.studentName);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(AppRoutes.lessonDetail.replaceFirst(':id', lesson.id));
      },
      child: Container(
        width: width - 2,
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
          border: Border(
            left: BorderSide(color: colors.accent, width: 2),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          shortName,
          style: TextStyle(
            color: colors.accent,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildEmptyWeek() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_available,
            size: 48,
            color: AppColors.textTertiaryLight,
          ),
          const SizedBox(height: 12),
          Text(
            '이번 주는 레슨이 없습니다',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(List<Lesson> lessons) {
    final totalMinutes = lessons.fold<int>(0, (sum, l) => sum + l.duration);
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    final timeStr =
        hours > 0 ? (mins > 0 ? '$hours시간 ${mins}분' : '$hours시간') : '${mins}분';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: AppColors.scheduleGridLine, width: 0.5),
        ),
      ),
      child: Text(
        '이번 주: ${lessons.length}레슨 · 총 $timeStr',
        style: AppTypography.caption.copyWith(
          color: AppColors.textTertiaryLight,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  (int, int) _getVisibleRange(List<Lesson> lessons) {
    if (lessons.isEmpty) return (8, 18);

    int earliest = 23;
    int latest = 0;

    for (final lesson in lessons) {
      final parts = lesson.startTime.split(':');
      final hour = int.parse(parts[0]);
      final endMinutes = hour * 60 + int.parse(parts[1]) + lesson.duration;
      final endHour = (endMinutes / 60).ceil();
      if (hour < earliest) earliest = hour;
      if (endHour > latest) latest = endHour;
    }

    return ((earliest - 1).clamp(0, 23), latest.clamp(0, 23));
  }

  /// Build a map: dayIndex (0-6) → slotMinutes → Lesson
  Map<int, Map<int, Lesson>> _buildLessonMap(List<Lesson> lessons) {
    final map = <int, Map<int, Lesson>>{};

    for (final lesson in lessons) {
      final dayIndex = lesson.date.weekday - 1; // 1=Mon → 0
      final parts = lesson.startTime.split(':');
      final startMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);

      map.putIfAbsent(dayIndex, () => {});

      // Fill all 30-min slots this lesson occupies
      final slotCount = (lesson.duration / 30.0).ceil();
      for (int i = 0; i < slotCount; i++) {
        map[dayIndex]![startMinutes + i * 30] = lesson;
      }
    }

    return map;
  }

  /// Count unique lessons per day (not slots)
  Map<int, int> _countUniqueLessons(List<Lesson> lessons) {
    final counts = <int, Set<String>>{};
    for (final lesson in lessons) {
      final dayIndex = lesson.date.weekday - 1;
      counts.putIfAbsent(dayIndex, () => {});
      counts[dayIndex]!.add(lesson.id);
    }
    return counts.map((key, value) => MapEntry(key, value.length));
  }

  /// Get rest days from teacher availability (days without WeeklySchedule)
  Set<int> _getRestDays(TeacherAvailability? availability) {
    if (availability == null) return {};

    final workDays = <int>{};
    for (final schedule in availability.weeklySchedules) {
      if (schedule.isActive) {
        workDays.add(schedule.dayOfWeek);
      }
    }

    // If no schedules defined, no rest days to show
    if (workDays.isEmpty) return {};

    // Days not in workDays are rest days
    return {0, 1, 2, 3, 4, 5, 6}.difference(workDays);
  }

  /// Determine day type relative to today
  _DayType _getDayType(DateTime dayDate, DateTime todayDate) {
    final day = DateTime(dayDate.year, dayDate.month, dayDate.day);
    if (day.isBefore(todayDate)) return _DayType.past;
    if (day.isAtSameMomentAs(todayDate)) return _DayType.today;
    return _DayType.future;
  }

  /// Column background color — only today highlighted, everything else default
  Color? _getColumnBackground(_DayType dayType, bool isRestDay) {
    if (dayType == _DayType.today) {
      return AppColors.primary.withValues(alpha: 0.04);
    }
    return null;
  }

  void _navigateToAddLesson(DateTime date, int hour, int minute) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    context.push(
      '${AppRoutes.addLesson}?date=$dateStr&hour=$hour&minute=$minute',
    );
  }
}

/// Day type for visual distinction in weekly grid
enum _DayType { past, today, future }
