import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../lessons/lessons_facade.dart' hide teacherAvailabilityProvider;
import 'lesson_action_sheet.dart';
import '../../domain/entities/teacher_availability.dart';
import '../providers/teacher_availability_providers.dart';
import '../utils/schedule_visual_helpers.dart';
import 'timeline_lesson_block.dart';

/// Height per 30-minute unit.
const double _unitHeight = kTimelineUnitHeight;

/// Timeline view showing lessons as time-proportional blocks.
/// Features: now indicator, auto-scroll, context-aware summary bar,
/// gap collapse, progressive disclosure.
class ScheduleTimelineView extends ConsumerStatefulWidget {
  final List<Lesson> lessons;
  final DateTime selectedDate;

  const ScheduleTimelineView({
    super.key,
    required this.lessons,
    required this.selectedDate,
  });

  @override
  ConsumerState<ScheduleTimelineView> createState() =>
      _ScheduleTimelineViewState();
}

class _ScheduleTimelineViewState extends ConsumerState<ScheduleTimelineView> {
  final ScrollController _scrollController = ScrollController();
  Timer? _nowTimer;
  DateTime _now = DateTime.now();

  bool get _isToday =>
      widget.selectedDate.year == _now.year &&
      widget.selectedDate.month == _now.month &&
      widget.selectedDate.day == _now.day;

  @override
  void initState() {
    super.initState();
    // Update "now" every 30 seconds
    _nowTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    // Auto-scroll to "now" after build
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoScroll());
  }

  @override
  void didUpdateWidget(covariant ScheduleTimelineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoScroll());
    }
  }

  @override
  void dispose() {
    _nowTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _autoScroll() {
    if (!_scrollController.hasClients) return;

    if (_isToday) {
      // Scroll to "now" position with 80px top margin
      final nowMinutes = _now.hour * 60 + _now.minute;
      final offset = _minutesToOffset(nowMinutes) - 80;
      _scrollController.jumpTo(
        offset.clamp(0, _scrollController.position.maxScrollExtent),
      );
    } else if (widget.lessons.isNotEmpty) {
      // Scroll to first lesson with 40px top margin
      final sortedLessons = List<Lesson>.from(widget.lessons)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      final parts = sortedLessons.first.startTime.split(':');
      final minutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      final offset = _minutesToOffset(minutes) - 40;
      _scrollController.jumpTo(
        offset.clamp(0, _scrollController.position.maxScrollExtent),
      );
    } else {
      // No lessons: scroll to 9am
      final offset = _minutesToOffset(9 * 60) - 40;
      _scrollController.jumpTo(
        offset.clamp(0, _scrollController.position.maxScrollExtent),
      );
    }
  }

  double _minutesToOffset(int minutes) {
    // Each 30min = _unitHeight
    return (minutes / 30.0) * _unitHeight;
  }

  @override
  Widget build(BuildContext context) {
    final availabilityAsync = ref.watch(
      teacherAvailabilityProvider('teacher_1'),
    );
    final availability = availabilityAsync.valueOrNull;
    final isRestDay = isTeacherRestDay(
      availability: availability,
      date: widget.selectedDate,
    );

    return Column(
      children: [
        if (isRestDay) _buildRestDayBanner(),
        // Timeline body — §7.121: rest day muted tint matches weekly grid.
        Expanded(
          child: ColoredBox(
            color:
                isRestDay
                    ? AppColors.scheduleMutedBackground.withValues(alpha: 0.5)
                    : Colors.transparent,
            child: _buildTimeline(availability),
          ),
        ),
        // Context-aware summary bar
        _buildSummaryBar(),
      ],
    );
  }

  Widget _buildRestDayBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: AppColors.scheduleMutedBackground.withValues(alpha: 0.6),
        border: Border(
          bottom: BorderSide(color: AppColors.scheduleGridLine, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.weekend_outlined,
            size: 16,
            color: AppColors.scheduleMutedAccent,
          ),
          const SizedBox(width: AppSpacing.space2),
          Text(
            '쉬는 날',
            style: AppTypography.caption.copyWith(
              color: AppColors.scheduleMutedAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              '예정된 레슨이 있다면 보강·예외 처리 건입니다',
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.inkTertiary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(TeacherAvailability? availability) {
    final sortedLessons = List<Lesson>.from(widget.lessons)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // Visible range based on teacher's available time for this day
    final (startHour, endHour) = _getVisibleRange(availability, sortedLessons);

    const topPadding = 16.0;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapUp: (details) {
          _onTimelineTap(
            details.localPosition.dy,
            startHour,
            topPadding,
            sortedLessons,
          );
        },
        child: SizedBox(
          height: ((endHour - startHour + 1) * 2) * _unitHeight + topPadding,
          child: Stack(
            children: [
              // Hour grid lines and labels
              ..._buildHourGrid(startHour, endHour, topPadding),
              // Lesson blocks
              ..._buildLessonBlocks(sortedLessons, startHour, topPadding),
              // "Now" indicator
              if (_isToday) _buildNowIndicator(startHour, topPadding),
            ],
          ),
        ),
      ),
    );
  }

  /// Convert tap Y position to time and navigate to add lesson.
  void _onTimelineTap(
    double tapY,
    int startHour,
    double topPadding,
    List<Lesson> lessons,
  ) {
    // Convert Y offset to minutes
    final adjustedY = tapY - topPadding;
    if (adjustedY < 0) return;

    final totalMinutes = (adjustedY / _unitHeight) * 30 + startHour * 60;
    final hour = (totalMinutes ~/ 60).clamp(0, 23);
    final minute = ((totalMinutes % 60) ~/ 30) * 30; // Snap to 30-min

    // Check if tap is on an existing lesson or travel time block
    for (final lesson in lessons) {
      final parts = lesson.startTime.split(':');
      final lessonStart = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      final lessonEnd = lessonStart + lesson.duration;
      final travelStart = lessonStart - lesson.travelTimeMinutes;
      final tappedMinutes = hour * 60 + minute;
      if (tappedMinutes >= lessonStart && tappedMinutes < lessonEnd) {
        return; // Lesson block's onTap will handle this
      }
      if (lesson.travelTimeMinutes > 0 &&
          tappedMinutes >= travelStart &&
          tappedMinutes < lessonStart) {
        // 이동 블록 탭 → 해당 레슨 상세로 이동
        context.push(AppRoutes.lessonDetail.replaceFirst(':id', lesson.id));
        return;
      }
    }

    _navigateToAddLesson(widget.selectedDate, hour, minute);
  }

  void _navigateToAddLesson(DateTime date, int hour, int minute) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    context.push(
      '${AppRoutes.addLesson}?date=$dateStr&hour=$hour&minute=$minute',
    );
  }

  /// Determine visible hour range from teacher availability + lessons.
  /// Shows from earliest available/lesson time - 1h to latest + 1h.
  (int, int) _getVisibleRange(
    TeacherAvailability? availability,
    List<Lesson> sortedLessons,
  ) {
    int earliest = 23;
    int latest = 0;

    // Consider teacher's availability across ALL active days (global min/max)
    // This ensures consistent time range regardless of which day is selected
    if (availability != null) {
      for (final schedule in availability.weeklySchedules) {
        if (schedule.isActive) {
          final startParts = schedule.startTime.split(':');
          final endParts = schedule.endTime.split(':');
          final startH = int.parse(startParts[0]);
          final endH = int.parse(endParts[0]);
          if (startH < earliest) earliest = startH;
          if (endH > latest) latest = endH;
        }
      }
    }

    // Consider lesson times + travel time BEFORE lesson (some lessons may be outside availability)
    for (final lesson in sortedLessons) {
      final parts = lesson.startTime.split(':');
      final startMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      final travelStartMinutes = startMinutes - lesson.travelTimeMinutes;
      final travelStartHour = (travelStartMinutes / 60).floor();
      final endMinutes = startMinutes + lesson.duration;
      final endHour = (endMinutes / 60).ceil();
      if (travelStartHour < earliest) earliest = travelStartHour;
      if (endHour > latest) latest = endHour;
    }

    // Default range if nothing found
    if (earliest > latest) {
      return (8, 18);
    }

    // Add 1-hour margin on each side
    return ((earliest - 1).clamp(0, 23), (latest + 1).clamp(0, 23));
  }

  List<Widget> _buildHourGrid(int startHour, int endHour, double topPadding) {
    final widgets = <Widget>[];

    for (int hour = startHour; hour <= endHour; hour++) {
      final top = ((hour - startHour) * 2) * _unitHeight + topPadding;
      // Hour label
      widgets.add(
        Positioned(
          top: top - 8,
          left: 0,
          width: 40,
          child: Text(
            '${hour.toString().padLeft(2, '0')}:00',
            style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
            textAlign: TextAlign.right,
          ),
        ),
      );
      // Grid line
      widgets.add(
        Positioned(
          top: top,
          left: 48,
          right: 0,
          child: Container(height: 0.5, color: AppColors.scheduleGridLine),
        ),
      );
    }
    return widgets;
  }

  List<Widget> _buildLessonBlocks(
    List<Lesson> lessons,
    int startHour,
    double topPadding,
  ) {
    final nowMinutes = _now.hour * 60 + _now.minute;
    final todayDate = DateTime(_now.year, _now.month, _now.day);
    final selectedDateOnly = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
    );
    final isFutureDate = selectedDateOnly.isAfter(todayDate);

    // Find the next upcoming lesson
    Lesson? nextLesson;
    int nextMinutesUntil = 0;
    if (_isToday) {
      for (final lesson in lessons) {
        final parts = lesson.startTime.split(':');
        final lessonMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
        if (lessonMinutes > nowMinutes) {
          nextLesson = lesson;
          nextMinutesUntil = lessonMinutes - nowMinutes;
          break;
        }
      }
    }

    final widgets = <Widget>[];

    for (final lesson in lessons) {
      final parts = lesson.startTime.split(':');
      final lessonMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      final endMinutes = lessonMinutes + lesson.duration;
      final top =
          ((lessonMinutes - startHour * 60) / 30.0) * _unitHeight + topPadding;

      final isPast = _isToday && endMinutes <= nowMinutes;
      final isNow =
          _isToday && lessonMinutes <= nowMinutes && endMinutes > nowMinutes;
      final isNext = nextLesson?.id == lesson.id && nextMinutesUntil <= 60;

      // Lesson block
      widgets.add(
        Positioned(
          top: top,
          left: 52,
          right: 0,
          child: TimelineLessonBlock(
            lesson: lesson,
            isToday: _isToday,
            isFuture: isFutureDate,
            isNow: isNow,
            isPast: isPast,
            isNext: isNext,
            minutesUntilNext: isNext ? nextMinutesUntil : 0,
            onTap: () {
              context.push(
                AppRoutes.lessonDetail.replaceFirst(':id', lesson.id),
              );
            },
            onLongPress: () => showLessonActionSheet(
              context: context,
              ref: ref,
              lesson: lesson,
            ),
          ),
        ),
      );

      // Travel time block BEFORE lesson
      if (lesson.travelTimeMinutes > 0) {
        final travelStartMinutes = lessonMinutes - lesson.travelTimeMinutes;
        final travelTop =
            ((travelStartMinutes - startHour * 60) / 30.0) * _unitHeight +
            topPadding;
        final travelHeight = (lesson.travelTimeMinutes / 30.0) * _unitHeight;

        widgets.add(
          Positioned(
            top: travelTop, // No gap — travel ends where lesson starts
            left: 52,
            right: 0,
            child: _TravelTimeBlock(
              travelMinutes: lesson.travelTimeMinutes,
              height: travelHeight,
            ),
          ),
        );
      }
    }

    return widgets;
  }

  Widget _buildNowIndicator(int startHour, double topPadding) {
    final nowMinutes = _now.hour * 60 + _now.minute;
    final top =
        ((nowMinutes - startHour * 60) / 30.0) * _unitHeight + topPadding;

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Row(
        children: [
          // Time label
          SizedBox(
            width: 40,
            child: Text(
              '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}',
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.scheduleNowIndicator,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: AppSpacing.space1),
          // Red circle node
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.scheduleNowIndicator,
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

  Widget _buildSummaryBar() {
    final totalMinutes = widget.lessons.fold<int>(
      0,
      (sum, l) => sum + l.duration,
    );
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
          top: BorderSide(color: AppColors.scheduleGridLine, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Context line (today only)
          if (_isToday) ...[
            Text(
              _getContextLine(),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.paperAccent,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
          ],
          // Stats line
          Text(
            '${_isToday ? "오늘" : ""} ${widget.lessons.length}레슨 · $timeStr',
            style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
          ),
        ],
      ),
    );
  }

  String _getContextLine() {
    if (widget.lessons.isEmpty) return '오늘은 레슨이 없습니다';

    final nowMinutes = _now.hour * 60 + _now.minute;
    final sortedLessons = List<Lesson>.from(widget.lessons)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // Check if any lesson is in progress
    for (final lesson in sortedLessons) {
      final parts = lesson.startTime.split(':');
      final start = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      final end = start + lesson.duration;
      if (start <= nowMinutes && end > nowMinutes) {
        final remaining = end - nowMinutes;
        return '진행 중: ${lesson.studentName} · ${lesson.instrument} · $remaining분 남음';
      }
    }

    // Find next lesson
    for (final lesson in sortedLessons) {
      final parts = lesson.startTime.split(':');
      final start = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      if (start > nowMinutes) {
        final until = start - nowMinutes;
        if (until <= 60) {
          return '다음: ${lesson.studentName} · ${lesson.instrument} · $until분 후';
        }
        return '다음: ${lesson.studentName} · ${lesson.instrument} · ${lesson.startTime}';
      }
    }

    // All lessons done
    return '오늘 레슨 완료 🎵';
  }

}

/// Travel time block displayed before a lesson in the timeline.
class _TravelTimeBlock extends StatelessWidget {
  final int travelMinutes;
  final double height;

  const _TravelTimeBlock({required this.travelMinutes, required this.height});

  @override
  Widget build(BuildContext context) {
    // Notebook × Score: 둥근 모서리 6px 제거 → 직사각 + 좌 3px 세로선만 유지
    return Container(
      height: height.clamp(18.0, double.infinity),
      decoration: BoxDecoration(
        color: AppColors.scheduleTravelBackground,
        border: Border(
          left: BorderSide(color: AppColors.scheduleTravelAccent, width: 3),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2),
      alignment: Alignment.centerLeft,
      child: Text(
        '이동 $travelMinutes분',
        style: AppTypography.captionSmall.copyWith(
          color: AppColors.scheduleTravelAccent,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

