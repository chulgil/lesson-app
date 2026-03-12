import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/instrument_colors.dart';
import '../../../../models/lesson.dart';
import '../providers/week_lessons_provider.dart';
import '../screens/schedule_tab.dart';

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

    return weekLessonsAsync.when(
      data: (lessons) => _buildGrid(lessons),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('불러오기 실패: $e')),
    );
  }

  Widget _buildGrid(List<Lesson> lessons) {
    if (lessons.isEmpty) {
      return _buildEmptyWeek();
    }

    final (startHour, endHour) = _getVisibleRange(lessons);
    final now = DateTime.now();
    final isCurrentWeek = _weekStart.isBefore(now) &&
        _weekStart.add(const Duration(days: 7)).isAfter(now);

    // Group lessons by day and time
    final lessonMap = _buildLessonMap(lessons);

    return Column(
      children: [
        // Week range header
        _buildWeekHeader(),
        // Grid
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space2,
              ),
              child: _buildGridBody(
                lessonMap,
                startHour,
                endHour,
                now,
                isCurrentWeek,
              ),
            ),
          ),
        ),
        // Summary bar
        _buildSummaryBar(lessons),
      ],
    );
  }

  Widget _buildWeekHeader() {
    final weekEnd = _weekStart.add(const Duration(days: 6));
    final fmt = DateFormat('M/d');
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: 8,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _navigateWeek(-7),
            icon: const Icon(Icons.chevron_left, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Expanded(
            child: Text(
              '${fmt.format(_weekStart)} ~ ${fmt.format(weekEnd)}',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          _buildTodayButton(),
          IconButton(
            onPressed: () => _navigateWeek(7),
            icon: const Icon(Icons.chevron_right, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayButton() {
    final now = DateTime.now();
    final todayWeekStart = getWeekStart(now);
    if (_weekStart == todayWeekStart) return const SizedBox.shrink();

    return TextButton(
      onPressed: () {
        ref.read(teacherSelectedDateProvider.notifier).state =
            DateTime(now.year, now.month, now.day);
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 28),
      ),
      child: Text(
        '오늘',
        style: AppTypography.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildGridBody(
    Map<int, Map<int, Lesson>> lessonMap,
    int startHour,
    int endHour,
    DateTime now,
    bool isCurrentWeek,
  ) {
    final cellWidth =
        (MediaQuery.of(context).size.width - AppSpacing.space2 * 2 - 36) / 7;
    const cellHeight = 28.0;
    final dayNames = ['월', '화', '수', '목', '금', '토', '일'];
    final today = now.weekday - 1; // 0-based (0=Mon)

    return Column(
      children: [
        // Day headers with lesson count badges
        Row(
          children: [
            const SizedBox(width: 36), // Time axis width
            ...List.generate(7, (dayIndex) {
              final isToday = isCurrentWeek && dayIndex == today;
              final dayLessons = lessonMap[dayIndex]?.values.length ?? 0;

              return SizedBox(
                width: cellWidth,
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: isToday
                          ? BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            )
                          : null,
                      child: Text(
                        dayNames[dayIndex],
                        style: AppTypography.caption.copyWith(
                          color: isToday ? Colors.white : AppColors.textSecondaryLight,
                          fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (dayLessons > 0)
                      Text(
                        '$dayLessons',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiaryLight,
                          fontSize: 10,
                        ),
                      )
                    else
                      const SizedBox(height: 14),
                  ],
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 4),
        // Grid rows
        ...List.generate((endHour - startHour + 1), (hourIndex) {
          final hour = startHour + hourIndex;
          return SizedBox(
            height: cellHeight * 2, // 2 slots per hour (30-min each)
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time label
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
                // Day columns
                ...List.generate(7, (dayIndex) {
                  final isToday = isCurrentWeek && dayIndex == today;
                  return Container(
                    width: cellWidth,
                    height: cellHeight * 2,
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppColors.primary.withValues(alpha: 0.04)
                          : null,
                      border: Border(
                        top: BorderSide(
                          color: const Color(0xFFF0F0F0),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        // :00 slot
                        _buildGridCell(
                          lessonMap,
                          dayIndex,
                          hour * 60,
                          cellWidth,
                          cellHeight,
                        ),
                        // :30 slot
                        _buildGridCell(
                          lessonMap,
                          dayIndex,
                          hour * 60 + 30,
                          cellWidth,
                          cellHeight,
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGridCell(
    Map<int, Map<int, Lesson>> lessonMap,
    int dayIndex,
    int slotMinutes,
    double width,
    double height,
  ) {
    final lesson = lessonMap[dayIndex]?[slotMinutes];
    if (lesson == null) return SizedBox(width: width, height: height);

    final colors = InstrumentColors.getColor(lesson.instrument);

    // Check if this is the start slot of a lesson
    final parts = lesson.startTime.split(':');
    final lessonStartMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    final isStartSlot = slotMinutes == lessonStartMinutes;

    if (!isStartSlot) {
      // Continuation slot — show colored background only (no overflow)
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

    // Start slot — show name with colored background
    final shortName = lesson.studentName.length > 2
        ? lesson.studentName.substring(0, 2)
        : lesson.studentName;

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
    return Column(
      children: [
        _buildWeekHeader(),
        Expanded(
          child: Center(
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
          ),
        ),
      ],
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
          top: BorderSide(color: const Color(0xFFE8E8E8), width: 0.5),
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

  void _navigateWeek(int days) {
    final newDate = widget.selectedDate.add(Duration(days: days));
    ref.read(teacherSelectedDateProvider.notifier).state = newDate;
  }
}
