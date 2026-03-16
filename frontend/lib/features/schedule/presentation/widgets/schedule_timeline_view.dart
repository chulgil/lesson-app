import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/lesson.dart';
import '../../../../providers/providers.dart'
    hide teacherAvailabilityProvider;
import '../../domain/entities/teacher_availability.dart';
import '../providers/teacher_availability_providers.dart';
import 'timeline_break_block.dart';
import 'timeline_lesson_block.dart';
import 'travel_time_edit_sheet.dart';

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
      _scrollController.jumpTo(offset.clamp(0, _scrollController.position.maxScrollExtent));
    } else if (widget.lessons.isNotEmpty) {
      // Scroll to first lesson with 40px top margin
      final sortedLessons = List<Lesson>.from(widget.lessons)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      final parts = sortedLessons.first.startTime.split(':');
      final minutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      final offset = _minutesToOffset(minutes) - 40;
      _scrollController.jumpTo(offset.clamp(0, _scrollController.position.maxScrollExtent));
    } else {
      // No lessons: scroll to 9am
      final offset = _minutesToOffset(9 * 60) - 40;
      _scrollController.jumpTo(offset.clamp(0, _scrollController.position.maxScrollExtent));
    }
  }

  double _minutesToOffset(int minutes) {
    // Each 30min = _unitHeight
    return (minutes / 30.0) * _unitHeight;
  }

  @override
  Widget build(BuildContext context) {
    final availabilityAsync =
        ref.watch(teacherAvailabilityProvider('teacher_1'));
    final availability = availabilityAsync.valueOrNull;

    return Column(
      children: [
        // Timeline body
        Expanded(
          child: _buildTimeline(availability),
        ),
        // Context-aware summary bar
        _buildSummaryBar(),
      ],
    );
  }

  Widget _buildTimeline(TeacherAvailability? availability) {
    final sortedLessons = List<Lesson>.from(widget.lessons)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // Visible range based on teacher's available time for this day
    final (startHour, endHour) =
        _getVisibleRange(availability, sortedLessons);

    final globalBreakTime = availability?.breakTimeBetweenLessons ?? 0;

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
            globalBreakTime,
          );
        },
        child: SizedBox(
          height: ((endHour - startHour + 1) * 2) * _unitHeight + topPadding,
          child: Stack(
            children: [
              // Hour grid lines and labels
              ..._buildHourGrid(startHour, endHour, topPadding),
              // Break/travel time blocks (rendered behind lesson blocks)
              ..._buildBreakBlocks(
                sortedLessons, startHour, topPadding, globalBreakTime,
              ),
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
  /// Checks lesson blocks and break/travel blocks before navigating.
  void _onTimelineTap(
    double tapY,
    int startHour,
    double topPadding,
    List<Lesson> lessons,
    int globalBreakTime,
  ) {
    // Convert Y offset to minutes
    final adjustedY = tapY - topPadding;
    if (adjustedY < 0) return;

    final totalMinutes = (adjustedY / _unitHeight) * 30 + startHour * 60;
    final hour = (totalMinutes ~/ 60).clamp(0, 23);
    final minute = ((totalMinutes % 60) ~/ 30) * 30; // Snap to 30-min
    final tappedMinutes = hour * 60 + minute;

    // Check if tap is on an existing lesson (lesson blocks handle their own tap)
    for (final lesson in lessons) {
      final parts = lesson.startTime.split(':');
      final lessonStart = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      final lessonEnd = lessonStart + lesson.duration;
      if (tappedMinutes >= lessonStart && tappedMinutes < lessonEnd) {
        return; // Lesson block's onTap will handle this
      }
    }

    // Check if tap is on a break/travel time block.
    // The break block's own GestureDetector handles the action;
    // here we only return early to prevent "add lesson" navigation.
    for (int i = 0; i < lessons.length - 1; i++) {
      final current = lessons[i];

      final currentParts = current.startTime.split(':');
      final currentEnd =
          int.parse(currentParts[0]) * 60 + int.parse(currentParts[1]) + current.duration;

      final breakDuration = current.travelTimeAfter ?? globalBreakTime;
      if (breakDuration > 0 && tappedMinutes >= currentEnd && tappedMinutes < currentEnd + breakDuration) {
        return; // Break block's own onTap will handle this
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

    // Consider teacher's availability for this day of week
    final dayOfWeek = widget.selectedDate.weekday - 1; // 0=Mon
    if (availability != null) {
      for (final schedule in availability.weeklySchedules) {
        if (schedule.isActive && schedule.dayOfWeek == dayOfWeek) {
          final startParts = schedule.startTime.split(':');
          final endParts = schedule.endTime.split(':');
          final startH = int.parse(startParts[0]);
          final endH = int.parse(endParts[0]);
          if (startH < earliest) earliest = startH;
          if (endH > latest) latest = endH;
        }
      }
    }

    // Consider lesson times (some lessons may be outside availability)
    for (final lesson in sortedLessons) {
      final parts = lesson.startTime.split(':');
      final hour = int.parse(parts[0]);
      final endMinutes = hour * 60 + int.parse(parts[1]) + lesson.duration;
      final endHour = (endMinutes / 60).ceil();
      if (hour < earliest) earliest = hour;
      if (endHour > latest) latest = endHour;
    }

    // Default range if nothing found
    if (earliest > latest) {
      return (8, 18);
    }

    // Add 1-hour margin on each side
    return ((earliest - 1).clamp(0, 23), (latest + 1).clamp(0, 23));
  }



  /// Build break/travel time blocks between consecutive lessons.
  List<Widget> _buildBreakBlocks(
    List<Lesson> lessons,
    int startHour,
    double topPadding,
    int globalBreakTime,
  ) {
    if (lessons.length < 2) return [];

    final widgets = <Widget>[];

    for (int i = 0; i < lessons.length - 1; i++) {
      final current = lessons[i];
      final next = lessons[i + 1];

      final currentParts = current.startTime.split(':');
      final currentEndMinutes =
          int.parse(currentParts[0]) * 60 + int.parse(currentParts[1]) + current.duration;

      final nextParts = next.startTime.split(':');
      final nextStartMinutes = int.parse(nextParts[0]) * 60 + int.parse(nextParts[1]);

      // Determine break duration: per-lesson travel time or global break time
      final breakDuration = current.travelTimeAfter ?? globalBreakTime;
      if (breakDuration <= 0) continue;

      // Clamp to actual gap between lessons
      final actualGap = nextStartMinutes - currentEndMinutes;
      if (actualGap <= 0) continue;
      final displayDuration = breakDuration.clamp(0, actualGap);
      if (displayDuration <= 0) continue;

      final isTravelTime = current.travelTimeAfter != null;
      final top = ((currentEndMinutes - startHour * 60) / 30.0) * _unitHeight + topPadding;

      widgets.add(
        Positioned(
          top: top,
          left: 52,
          right: 0,
          child: TimelineBreakBlock(
            type: isTravelTime ? BreakBlockType.travelTime : BreakBlockType.breakTime,
            durationMinutes: displayDuration,
            fromStudentName: current.studentName,
            toStudentName: next.studentName,
            fromLocation: current.location?.name,
            toLocation: next.location?.name,
            onTap: () => _showTravelTimeEditSheet(current, next, globalBreakTime),
          ),
        ),
      );
    }

    return widgets;
  }

  /// Show travel time edit bottom sheet.
  void _showTravelTimeEditSheet(
    Lesson fromLesson,
    Lesson toLesson,
    int globalBreakTime,
  ) {
    final currentMinutes = fromLesson.travelTimeAfter ?? globalBreakTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: TravelTimeEditSheet(
          currentMinutes: currentMinutes,
          globalBreakTime: globalBreakTime,
          fromStudentName: fromLesson.studentName,
          toStudentName: toLesson.studentName,
          fromLocation: fromLesson.location?.name,
          toLocation: toLesson.location?.name,
          onSave: (minutes, applyGlobally) {
            _saveTravelTime(fromLesson, minutes, applyGlobally);
          },
        ),
      ),
    );
  }

  Future<void> _saveTravelTime(
    Lesson lesson,
    int minutes,
    bool applyGlobally,
  ) async {
    try {
      if (applyGlobally) {
        // Update global break time — need current settings for other fields
        final availability =
            await ref.read(teacherAvailabilityProvider('teacher_1').future);
        await ref
            .read(teacherAvailabilityNotifierProvider('teacher_1').notifier)
            .updateLessonSettings(
              slotDurationMinutes: availability?.slotDurationMinutes ?? 60,
              breakTimeBetweenLessons: minutes,
              slotStartInterval: availability?.slotStartInterval ?? 30,
            );
      } else {
        // Update per-lesson travel time
        final updated = lesson.copyWith(travelTimeAfter: minutes);
        await ref.read(lessonsNotifierProvider.notifier).updateLesson(updated);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장에 실패했습니다. 다시 시도해주세요.')),
        );
      }
    }
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
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiaryLight,
              fontSize: 11,
            ),
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
          child: Container(
            height: 0.5,
            color: const Color(0xFFE8E8E8),
          ),
        ),
      );
    }
    return widgets;
  }

  List<Widget> _buildLessonBlocks(List<Lesson> lessons, int startHour, double topPadding) {
    final nowMinutes = _now.hour * 60 + _now.minute;

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

    return lessons.map((lesson) {
      final parts = lesson.startTime.split(':');
      final lessonMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      final endMinutes = lessonMinutes + lesson.duration;
      final top = ((lessonMinutes - startHour * 60) / 30.0) * _unitHeight + topPadding;

      final isPast = _isToday && endMinutes <= nowMinutes;
      final isNow = _isToday &&
          lessonMinutes <= nowMinutes &&
          endMinutes > nowMinutes;
      final isNext = nextLesson?.id == lesson.id && nextMinutesUntil <= 60;

      return Positioned(
        top: top,
        left: 52,
        right: 0,
        child: TimelineLessonBlock(
          lesson: lesson,
          isToday: _isToday,
          isNow: isNow,
          isPast: isPast,
          isNext: isNext,
          minutesUntilNext: isNext ? nextMinutesUntil : 0,
          onTap: () {
            context.push(
              AppRoutes.lessonDetail.replaceFirst(':id', lesson.id),
            );
          },
          onLongPress: () => _showLessonActions(lesson),
        ),
      );
    }).toList();
  }

  Widget _buildNowIndicator(int startHour, double topPadding) {
    final nowMinutes = _now.hour * 60 + _now.minute;
    final top = ((nowMinutes - startHour * 60) / 30.0) * _unitHeight + topPadding;

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
              style: AppTypography.caption.copyWith(
                color: const Color(0xFFE53935),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 4),
          // Red circle node
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFE53935),
              shape: BoxShape.circle,
            ),
          ),
          // Red line
          Expanded(
            child: Container(
              height: 1,
              color: const Color(0xFFE53935).withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar() {
    final totalMinutes =
        widget.lessons.fold<int>(0, (sum, l) => sum + l.duration);
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Context line (today only)
          if (_isToday) ...[
            Text(
              _getContextLine(),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primary,
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
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiaryLight,
            ),
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
        return '진행 중: ${lesson.studentName} · ${lesson.instrument} · ${remaining}분 남음';
      }
    }

    // Find next lesson
    for (final lesson in sortedLessons) {
      final parts = lesson.startTime.split(':');
      final start = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      if (start > nowMinutes) {
        final until = start - nowMinutes;
        if (until <= 60) {
          return '다음: ${lesson.studentName} · ${lesson.instrument} · ${until}분 후';
        }
        return '다음: ${lesson.studentName} · ${lesson.instrument} · ${lesson.startTime}';
      }
    }

    // All lessons done
    return '오늘 레슨 완료 🎵';
  }

  void _showLessonActions(Lesson lesson) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle, color: AppColors.success),
              title: const Text('완료 처리'),
              onTap: () {
                Navigator.of(ctx).pop();
                _completeLesson(lesson);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_calendar, color: AppColors.info),
              title: const Text('일정 변경'),
              onTap: () {
                Navigator.of(ctx).pop();
                context.push(
                  AppRoutes.editLesson.replaceFirst(':id', lesson.id),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: AppColors.error),
              title: const Text('취소'),
              onTap: () {
                Navigator.of(ctx).pop();
                _cancelLesson(lesson);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeLesson(Lesson lesson) async {
    try {
      final updated = lesson.copyWith(status: LessonStatus.completed);
      await ref.read(lessonsNotifierProvider.notifier).updateLesson(updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('완료 처리 실패: $e')),
        );
      }
    }
  }

  Future<void> _cancelLesson(Lesson lesson) async {
    try {
      await ref.read(lessonsNotifierProvider.notifier).cancelLesson(lesson.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('취소 실패: $e')),
        );
      }
    }
  }
}
