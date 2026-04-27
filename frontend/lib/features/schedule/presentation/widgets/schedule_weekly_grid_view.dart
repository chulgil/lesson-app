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
import '../../../../features/lessons/domain/entities/lesson.dart';
import '../../domain/entities/teacher_availability.dart';
import '../providers/teacher_availability_providers.dart';
import '../providers/week_lessons_provider.dart';
import '../utils/schedule_visual_helpers.dart';

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
    final availabilityAsync = ref.watch(
      teacherAvailabilityProvider('teacher_1'),
    );

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

    final (startHour, endHour) = _getVisibleRange(lessons, availability);
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);

    // Group lessons by day and time
    final lessonMap = _buildLessonMap(lessons);

    // Build travel time slot map
    final travelSlotMap = _buildTravelSlotMap(lessons);

    // Count unique lessons per day (not slots)
    final uniqueLessonCounts = _countUniqueLessons(lessons);

    // §7.123 — Determine column rest kind per day (vacation > holiday > regular > none)
    final restKinds = _getRestKinds(availability);

    // Check if current week contains today
    final isCurrentWeek =
        _weekStart.isBefore(now.add(const Duration(days: 1))) &&
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
                    // §7.125 — 헤더 CompactWeekStrip 의 screenPadding 과 정렬.
                    // weeklyGrid 좌측 36px 시간 라벨 + 본문 7컬럼이
                    // 헤더 7컬럼과 동일 X·동일 너비로 떨어지게 통일.
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    child: _buildGridBody(
                      lessonMap,
                      uniqueLessonCounts,
                      startHour,
                      endHour,
                      todayDate,
                      restKinds,
                      availability: availability,
                      travelSlotMap: travelSlotMap,
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
    Map<int, ColumnRestKind> restKinds, {
    TeacherAvailability? availability,
    Map<int, Set<int>> travelSlotMap = const {},
    int todayIndex = -1,
    DateTime? now,
  }) {
    // §7.125 — 외부 screenPadding(16) × 2 + 좌측 시간 라벨(36) 제외한 너비를
    // 7 등분. 헤더 CompactWeekStrip 7컬럼 (screenPadding + 36 시작 / 동일 너비)
    // 과 정확히 정렬.
    final cellWidth =
        (MediaQuery.of(context).size.width -
            AppSpacing.screenPadding * 2 -
            36) /
        7;
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
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.inkTertiary,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            ...List.generate(7, (dayIndex) {
              final dayDate = _weekStart.add(Duration(days: dayIndex));
              final dayType = _getDayType(dayDate, todayDate);
              final restKind = restKinds[dayIndex] ?? ColumnRestKind.none;
              final columnBg = weeklyColumnBackground(
                dayType: _toScheduleDayType(dayType),
                restKind: restKind,
              );

              // §7.122 — 컬럼 사이 1px 수직 디바이더로 경계 명확화.
              // dayIndex 0(월) 은 시간 라벨과 인접해 디바이더 생략.
              // strokeAlignInside: 부분 Border paint assertion 방지.
              return SizedBox(
                width: cellWidth,
                height: cellHeight * 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: columnBg,
                    border:
                        dayIndex > 0
                            ? Border(
                              left: BorderSide(
                                color: AppColors.scheduleWeeklyGridLine,
                                width: 0.5,
                                strokeAlign: BorderSide.strokeAlignInside,
                              ),
                            )
                            : null,
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 0.5,
                        color: AppColors.scheduleWeeklyGridLine,
                      ),
                      Expanded(
                        child: _buildGridCell(
                          lessonMap,
                          dayIndex,
                          hour * 60,
                          cellWidth,
                          cellHeight,
                          dayType: dayType,
                          travelSlots: travelSlotMap,
                          availability: availability,
                          restKind: restKind,
                        ),
                      ),
                      Expanded(
                        child: _buildGridCell(
                          lessonMap,
                          dayIndex,
                          hour * 60 + 30,
                          cellWidth,
                          cellHeight,
                          dayType: dayType,
                          travelSlots: travelSlotMap,
                          availability: availability,
                          restKind: restKind,
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
          // §7.123 — 휴가/휴무 라벨 칩 (컬럼 상단)
          ..._buildRestChips(restKinds, cellWidth),
          // Now indicator (red line on today's column)
          if (todayIndex >= 0 && now != null)
            _buildNowIndicator(
              now,
              startHour,
              cellWidth,
              cellHeight,
              todayIndex,
            ),
        ],
      ),
    );
  }

  /// §7.123 — 휴가/휴무 컬럼에 라벨 칩 오버레이.
  ///
  /// 위치: 시간 그리드 첫 행 위, 컬럼 가로 가운데.
  /// regular(정기 휴무일) 와 none 은 라벨 없음.
  List<Widget> _buildRestChips(
    Map<int, ColumnRestKind> restKinds,
    double cellWidth,
  ) {
    final chips = <Widget>[];
    for (final entry in restKinds.entries) {
      final label = entry.value.chipLabel;
      if (label == null) continue;
      final dayIndex = entry.key;
      final leftOffset = 36.0 + dayIndex * cellWidth;
      chips.add(
        Positioned(
          top: 2,
          left: leftOffset,
          width: cellWidth,
          child: Center(
            child: Text(
              label,
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.inkSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }
    return chips;
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
    Map<int, Set<int>> travelSlots = const {},
    TeacherAvailability? availability,
    ColumnRestKind restKind = ColumnRestKind.none,
  }) {
    final lesson = lessonMap[dayIndex]?[slotMinutes];
    if (lesson == null) {
      // Check if this is a travel time slot
      final isTravelSlot =
          travelSlots[dayIndex]?.contains(slotMinutes) ?? false;
      if (isTravelSlot) {
        return Container(
          width: width - 2,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: AppColors.scheduleTravelBackground,
            border: Border(
              left: BorderSide(color: AppColors.scheduleTravelAccent, width: 2),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '이동',
            style: TextStyle(
              color: AppColors.scheduleTravelAccent,
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
          ),
        );
      }

      // Empty slot — tap to add lesson at this time (past slots disabled)
      final date = _weekStart.add(Duration(days: dayIndex));
      final hour = slotMinutes ~/ 60;
      final minute = slotMinutes % 60;
      final cellDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        hour,
        minute,
      );
      final isPast = cellDateTime.isBefore(DateTime.now());

      // §7.123 (Mode A+) — 휴일 컬럼 위 additionalSlot 만 흰색 override.
      // regular(주말) 은 컬럼이 이미 평일 톤이라 override 불필요.
      final isAdditional = isAdditionalOpenSlot(
        availability: availability,
        slotStart: cellDateTime,
      );
      final Color? cellOverlay =
          (isAdditional && restKind.isTeacherSetRest) ? AppColors.paper : null;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap:
            isPast
                ? null
                : () {
                  HapticFeedback.lightImpact();
                  _navigateToAddLesson(date, hour, minute);
                },
        child:
            cellOverlay == null
                ? SizedBox(width: width, height: height)
                : Container(width: width, height: height, color: cellOverlay),
      );
    }

    final baseColors = InstrumentColors.getColor(lesson.instrument);

    // Preview lessons: ultra-light with distinct border
    final InstrumentColorPair colors;
    if (lesson.isPreview) {
      colors = InstrumentColorPair(
        baseColors.background.withValues(alpha: 0.15),
        baseColors.accent.withValues(alpha: 0.25),
      );
    } else {
      // Color logic by day type:
      // - today → vivid instrument colors
      // - past → grey muted
      // - future → instrument colors (slightly muted)
      switch (dayType) {
        case _DayType.today:
          colors = baseColors;
        case _DayType.past:
          colors = const InstrumentColorPair(
            AppColors.scheduleMutedBackground,
            AppColors.scheduleMutedAccent,
          );
        case _DayType.future:
          // §7.123 Mode A++ — white lerp 0.35 → 0.15.
          // 이전 0.35 는 컬럼(#F2ECDD) 위에서 명도 차이 거의 없어 구분 약함.
          // 0.15 는 악기 색을 살려 컬럼/다른 학생 레슨과 명확히 변별.
          colors = InstrumentColorPair(
            Color.lerp(baseColors.background, Colors.white, 0.15)!,
            baseColors.accent.withValues(alpha: 0.55),
          );
      }
    }

    // Check if this is the start slot of a lesson
    final parts = lesson.startTime.split(':');
    final lessonStartMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    final isStartSlot = slotMinutes == lessonStartMinutes;

    // Preview lessons navigate to student detail; normal lessons to lesson detail
    final tapRoute =
        lesson.isPreview
            ? AppRoutes.studentDetail.replaceFirst(':id', lesson.studentId)
            : AppRoutes.lessonDetail.replaceFirst(':id', lesson.id);

    // Preview border: wider dashed-like accent border
    // Flutter 3.29: strokeAlign != strokeAlignInside 는 uniform border 에서만 허용됨.
    // Border(left: ...) 는 한 변만 있는 non-uniform border 이므로 반드시 strokeAlignInside.
    final leftBorder = BorderSide(
      color: colors.accent,
      width: lesson.isPreview ? 2.5 : 2,
      strokeAlign: BorderSide.strokeAlignInside,
    );

    if (!isStartSlot) {
      // Continuation slot — show colored background only
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          context.push(tapRoute);
        },
        child: Container(
          width: width - 2,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: colors.background,
            border: Border(left: leftBorder),
          ),
        ),
      );
    }

    // Start slot — show given name with colored background
    final shortName = NameUtils.givenName(lesson.studentName);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(tapRoute);
      },
      // Notebook × Score: 시작 셀 topLeft/topRight 4px 라운드 제거 → 직사각
      child: Container(
        width: width - 2,
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: colors.background,
          border: Border(left: leftBorder),
        ),
        alignment: Alignment.center,
        child: Text(
          shortName,
          style: AppTypography.captionSmall.copyWith(
            color: colors.accent,
            fontWeight: lesson.isPreview ? FontWeight.w400 : FontWeight.w600,
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
          Icon(Icons.event_available, size: 48, color: AppColors.inkTertiary),
          const SizedBox(height: AppSpacing.space3),
          Text(
            '이번 주는 레슨이 없습니다',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
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
        hours > 0 ? (mins > 0 ? '$hours시간 $mins분' : '$hours시간') : '$mins분';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: AppColors.scheduleWeeklyGridLine, width: 0.5),
        ),
      ),
      child: Text(
        '이번 주: ${lessons.length}레슨 · 총 $timeStr',
        style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
        textAlign: TextAlign.center,
      ),
    );
  }

  (int, int) _getVisibleRange(
    List<Lesson> lessons,
    TeacherAvailability? availability,
  ) {
    int earliest = 23;
    int latest = 0;

    // Include availability hours
    if (availability != null) {
      for (final schedule in availability.weeklySchedules) {
        if (!schedule.isActive) continue;
        final startH = int.parse(schedule.startTime.split(':')[0]);
        final endH = int.parse(schedule.endTime.split(':')[0]);
        if (startH < earliest) earliest = startH;
        if (endH > latest) latest = endH;
      }
    }

    // Include actual lesson hours (+ travel time BEFORE lesson)
    for (final lesson in lessons) {
      final parts = lesson.startTime.split(':');
      final startMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      final travelStartMinutes = startMinutes - lesson.travelTimeMinutes;
      final travelStartHour = (travelStartMinutes / 60).floor();
      final endMinutes = startMinutes + lesson.duration;
      final endHour = (endMinutes / 60).ceil();
      if (travelStartHour < earliest) earliest = travelStartHour;
      if (endHour > latest) latest = endHour;
    }

    if (earliest > latest) return (8, 18);
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

  /// Build a map: dayIndex (0-6) → Set of slotMinutes that are travel time
  Map<int, Set<int>> _buildTravelSlotMap(List<Lesson> lessons) {
    final map = <int, Set<int>>{};

    for (final lesson in lessons) {
      if (lesson.travelTimeMinutes <= 0) continue;

      final dayIndex = lesson.date.weekday - 1;
      final parts = lesson.startTime.split(':');
      final startMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      final travelStartMinutes = startMinutes - lesson.travelTimeMinutes;

      map.putIfAbsent(dayIndex, () => {});

      // Fill 30-min slots that travel time covers BEFORE lesson start
      final travelSlotCount = (lesson.travelTimeMinutes / 30.0).ceil();
      for (int i = 0; i < travelSlotCount; i++) {
        final slotMinutes = travelStartMinutes + i * 30;
        // Snap to nearest 30-min boundary
        final snapped = (slotMinutes ~/ 30) * 30;
        map[dayIndex]!.add(snapped);
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

  /// §7.123 — 7일 컬럼 각각의 휴식 종류 판정.
  ///
  /// 우선순위: vacation > holiday > regular > none.
  /// availability null 또는 weeklySchedules 비었으면 모두 none (휴무 미표시).
  Map<int, ColumnRestKind> _getRestKinds(TeacherAvailability? availability) {
    if (availability == null) return const {};
    final hasAnyWorkDay = availability.weeklySchedules.any((s) => s.isActive);
    if (!hasAnyWorkDay && availability.exceptions.isEmpty) {
      return const {};
    }
    final result = <int, ColumnRestKind>{};
    for (var dayIndex = 0; dayIndex < 7; dayIndex++) {
      final date = _weekStart.add(Duration(days: dayIndex));
      final kind = columnRestKindForDate(
        availability: availability,
        date: date,
      );
      result[dayIndex] = kind;
    }
    return result;
  }

  /// Determine day type relative to today
  _DayType _getDayType(DateTime dayDate, DateTime todayDate) {
    final day = DateTime(dayDate.year, dayDate.month, dayDate.day);
    if (day.isBefore(todayDate)) return _DayType.past;
    if (day.isAtSameMomentAs(todayDate)) return _DayType.today;
    return _DayType.future;
  }

  ScheduleDayType _toScheduleDayType(_DayType type) {
    switch (type) {
      case _DayType.past:
        return ScheduleDayType.past;
      case _DayType.today:
        return ScheduleDayType.today;
      case _DayType.future:
        return ScheduleDayType.future;
    }
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
