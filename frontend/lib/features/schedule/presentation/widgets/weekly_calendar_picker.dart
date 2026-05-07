import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../students/presentation/providers/teacher_announcement_providers.dart';
import '../../domain/entities/teacher_availability.dart';
import '../../domain/entities/unified_lesson_request.dart';
import '../providers/teacher_availability_providers.dart' hide SelectedSlot;
import 'slot_selection_logic.dart';

/// Weekly calendar picker with prev/next navigation and 3-slot selection.
///
/// Replaces ScheduleSlotPicker for unified lesson request v2.0.
/// Supports trial (specific date) and regular (weekday-only) modes.
class WeeklyCalendarPicker extends ConsumerStatefulWidget {
  final String teacherId;

  /// Lesson type determines display format:
  /// - trial/perSession: show specific date in selection list
  /// - regular: show "매주 X요일" in selection list
  final LessonRequestType lessonType;

  /// Called when selection changes with updated slot list.
  final ValueChanged<List<PreferredTimeSlot>> onSlotsChanged;

  /// First visible hour (inclusive, default 9).
  final int startHour;

  /// Last visible hour (exclusive, default 21).
  final int endHour;

  /// Maximum weeks ahead from today (default 4).
  final int maxWeeksAhead;

  const WeeklyCalendarPicker({
    super.key,
    required this.teacherId,
    required this.lessonType,
    required this.onSlotsChanged,
    this.startHour = 9,
    this.endHour = 21,
    this.maxWeeksAhead = 4,
  });

  @override
  ConsumerState<WeeklyCalendarPicker> createState() =>
      _WeeklyCalendarPickerState();
}

class _WeeklyCalendarPickerState extends ConsumerState<WeeklyCalendarPicker> {
  static const _dayLabels = ['월', '화', '수', '목', '금', '토', '일'];
  static const _timeColumnWidth = 40.0;
  static const _cellHeight = 44.0;
  static const _headerHeight = 48.0;

  late DateTime _weekStart;
  late DateTime _now;
  late Map<int, List<WeeklySchedule>> _schedulesByDay;
  final _selectionLogic = SlotSelectionLogic(maxSlots: 3);

  @override
  void initState() {
    super.initState();
    _weekStart = _currentWeekStart();
    _now = DateTime.now();
  }

  @override
  void didUpdateWidget(WeeklyCalendarPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.teacherId != widget.teacherId ||
        oldWidget.lessonType != widget.lessonType) {
      _selectionLogic.clear();
      _notifyParent();
    }
  }

  /// Monday of the current week.
  DateTime _currentWeekStart() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(Duration(days: today.weekday - 1));
  }

  /// Earliest allowed week start (current week).
  DateTime get _minWeekStart => _currentWeekStart();

  /// Latest allowed week start.
  DateTime get _maxWeekStart =>
      _currentWeekStart().add(Duration(days: 7 * (widget.maxWeeksAhead - 1)));

  bool get _canGoPrev => _weekStart.isAfter(_minWeekStart);

  bool get _canGoNext => _weekStart.isBefore(_maxWeekStart);

  void _goToPrevWeek() {
    if (!_canGoPrev) return;
    setState(() {
      _weekStart = _weekStart.subtract(const Duration(days: 7));
    });
  }

  void _goToNextWeek() {
    if (!_canGoNext) return;
    setState(() {
      _weekStart = _weekStart.add(const Duration(days: 7));
    });
  }

  bool _isPastSlot(int dayIndex, int hour) {
    final slotDate = _weekStart.add(Duration(days: dayIndex));
    final slotDateTime = DateTime(
      slotDate.year,
      slotDate.month,
      slotDate.day,
      hour,
    );
    return slotDateTime.isBefore(_now);
  }

  /// v3: 휴강일인지 확인 (TeacherAnnouncement 기반)
  bool _isDayOff(int dayIndex, Set<DateTime> dayOffSet) {
    final date = _weekStart.add(Duration(days: dayIndex));
    return dayOffSet.contains(DateTime(date.year, date.month, date.day));
  }

  void _onSlotTapped(int dayIndex, int hour) {
    final date = _weekStart.add(Duration(days: dayIndex));
    final startTime = '${hour.toString().padLeft(2, '0')}:00';
    final endTime = '${(hour + 1).toString().padLeft(2, '0')}:00';

    _selectionLogic.handleTap(
      date: date,
      dayOfWeek: dayIndex,
      startTime: startTime,
      endTime: endTime,
    );

    _notifyParent();
    setState(() {});
  }

  void _onSlotRemoved(int index) {
    _selectionLogic.removeAt(index);
    _notifyParent();
    setState(() {});
  }

  void _notifyParent() {
    final slots =
        _selectionLogic.slots.map((s) {
          if (widget.lessonType == LessonRequestType.regular) {
            // Regular: weekday only, no specific date
            return PreferredTimeSlot(
              priority: s.priority,
              dayOfWeek: s.dayOfWeek,
              startTime: s.startTime,
              endTime: s.endTime,
            );
          } else {
            // Trial / perSession: specific date
            return PreferredTimeSlot(
              priority: s.priority,
              date: s.date,
              dayOfWeek: s.dayOfWeek,
              startTime: s.startTime,
              endTime: s.endTime,
            );
          }
        }).toList();
    widget.onSlotsChanged(slots);
  }

  String get _weekLabel {
    final weekEnd = _weekStart.add(const Duration(days: 6));
    return '${_weekStart.month}/${_weekStart.day} ~ '
        '${weekEnd.month}/${weekEnd.day}';
  }

  @override
  Widget build(BuildContext context) {
    final availabilityAsync = ref.watch(
      teacherAvailabilityProvider(widget.teacherId),
    );

    return availabilityAsync.when(
      data: (availability) => _buildContent(availability),
      loading:
          () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
      error:
          (e, _) => SizedBox(
            height: 200,
            child: Center(
              child: Text(
                AppStrings.cannotLoadData,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildContent(TeacherAvailability? availability) {
    if (availability == null) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text(AppStrings.scheduleNoTeacherSchedule)),
      );
    }

    // Cache for this build cycle
    _now = DateTime.now();
    _schedulesByDay = {};
    for (var i = 0; i < 7; i++) {
      _schedulesByDay[i] =
          availability.weeklySchedules
              .where((s) => s.dayOfWeek == i && s.isActive)
              .toList();
    }

    final isRegular = widget.lessonType == LessonRequestType.regular;

    // v3: 휴강일 조회
    final weekEnd = _weekStart.add(const Duration(days: 6));
    final dayOffsAsync = ref.watch(
      teacherDayOffsProvider(
        teacherId: widget.teacherId,
        fromDate: _weekStart,
        toDate: weekEnd,
      ),
    );
    final dayOffSet = {
      for (final d in dayOffsAsync.valueOrNull ?? const <DateTime>[])
        DateTime(d.year, d.month, d.day),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Regular: no week navigation (weekday-only selection)
        if (!isRegular) _buildWeekNavigation(),
        _buildDayHeaders(showDate: !isRegular),
        const Divider(height: 1, color: AppColors.scheduleGridLine),
        ..._buildHourRows(availability, dayOffSet: dayOffSet),
        const SizedBox(height: AppSpacing.space3),
        _buildSelectionList(),
      ],
    );
  }

  Widget _buildWeekNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _canGoPrev ? _goToPrevWeek : null,
            icon: const Icon(Icons.chevron_left),
            iconSize: 24,
            color: AppColors.paperAccent,
            disabledColor: AppColors.scheduleMutedAccent,
          ),
          Text(
            _weekLabel,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            onPressed: _canGoNext ? _goToNextWeek : null,
            icon: const Icon(Icons.chevron_right),
            iconSize: 24,
            color: AppColors.paperAccent,
            disabledColor: AppColors.scheduleMutedAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildDayHeaders({bool showDate = true}) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    return SizedBox(
      height: showDate ? _headerHeight : _headerHeight * 0.6,
      child: Row(
        children: [
          SizedBox(width: _timeColumnWidth),
          ...List.generate(7, (i) {
            final date = _weekStart.add(Duration(days: i));
            final isToday =
                showDate &&
                date.year == todayOnly.year &&
                date.month == todayOnly.month &&
                date.day == todayOnly.day;

            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _dayLabels[i],
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color:
                          isToday
                              ? AppColors.paperAccent
                              : AppColors.inkSecondary,
                    ),
                  ),
                  if (showDate) ...[
                    const SizedBox(height: 2),
                    Container(
                      width: 22,
                      height: 22,
                      decoration:
                          isToday
                              ? const BoxDecoration(
                                color: AppColors.paperAccent,
                              )
                              : null,
                      child: Center(
                        child: Text(
                          '${date.day}',
                          style: AppTypography.caption.copyWith(
                            fontWeight:
                                isToday ? FontWeight.bold : FontWeight.normal,
                            color:
                                isToday
                                    ? AppColors.paper
                                    : AppColors.inkSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  List<Widget> _buildHourRows(
    TeacherAvailability availability, {
    Set<DateTime> dayOffSet = const {},
  }) {
    final hours = List.generate(
      widget.endHour - widget.startHour,
      (i) => widget.startHour + i,
    );

    return hours.map((hour) {
      final timeLabel = '${hour.toString().padLeft(2, '0')}:00';

      return SizedBox(
        height: _cellHeight,
        child: Row(
          children: [
            SizedBox(
              width: _timeColumnWidth,
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.space1),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Text(
                    timeLabel,
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.inkTertiary,
                    ),
                  ),
                ),
              ),
            ),
            ...List.generate(7, (dayIndex) {
              return Expanded(
                child: _buildCell(
                  dayIndex,
                  hour,
                  availability,
                  dayOffSet: dayOffSet,
                ),
              );
            }),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildCell(
    int dayIndex,
    int hour,
    TeacherAvailability availability, {
    Set<DateTime> dayOffSet = const {},
  }) {
    final startTime = '${hour.toString().padLeft(2, '0')}:00';
    // Regular lessons: no past-date restriction (weekday-only selection)
    final isPast =
        widget.lessonType == LessonRequestType.regular
            ? false
            : _isPastSlot(dayIndex, hour);
    // v3: 휴강일 비활성화
    final isDayOff = _isDayOff(dayIndex, dayOffSet);
    final isAvailable =
        _isSlotAvailable(dayIndex, hour, availability) && !isPast && !isDayOff;
    final priority = _selectionLogic.priorityFor(dayIndex, startTime);

    if (!isAvailable && priority == 0) {
      // Unavailable / past
      return Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(color: AppColors.scheduleMutedBackground),
      );
    }

    // Selected slot
    if (priority > 0) {
      return GestureDetector(
        onTap: () => _onSlotTapped(dayIndex, hour),
        child: Container(
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(color: _priorityColor(priority)),
          child: Center(
            child: Text(
              _priorityLabel(priority),
              style: AppTypography.bodyMedium.copyWith(
                fontSize: AppTypography.bodyMedium.fontSize! * 2,
                height: 1,
                fontWeight: FontWeight.bold,
                color: AppColors.paper,
              ),
            ),
          ),
        ),
      );
    }

    // Available slot
    return GestureDetector(
      onTap: () => _onSlotTapped(dayIndex, hour),
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: AppColors.paperAccentSoft,
          border: Border.all(color: AppColors.inkQuaternary, width: 1),
        ),
      ),
    );
  }

  bool _isSlotAvailable(
    int dayIndex,
    int hour,
    TeacherAvailability availability,
  ) {
    final daySchedules = _schedulesByDay[dayIndex] ?? [];

    for (final schedule in daySchedules) {
      final schedStart = int.tryParse(schedule.startTime.split(':').first) ?? 0;
      final schedEnd = int.tryParse(schedule.endTime.split(':').first) ?? 0;
      if (hour >= schedStart && hour < schedEnd) {
        return true;
      }
    }
    return false;
  }

  Color _priorityColor(int priority) {
    return AppColors.paperAccent;
  }

  String _priorityLabel(int priority) {
    const labels = ['', '❶', '❷', '❸'];
    return labels[priority.clamp(0, 3)];
  }

  Widget _buildSelectionList() {
    final maxSlots = _selectionLogic.maxSlots;
    final slots = _selectionLogic.slots;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(maxSlots, (i) {
        if (i < slots.length) {
          final slot = slots[i];
          final label = _slotDisplayLabel(slot);
          return Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 2,
              horizontal: AppSpacing.space1,
            ),
            child: Row(
              children: [
                Text(
                  '${slot.priority}순위: ',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.paperAccent,
                  ),
                ),
                Expanded(child: Text(label, style: AppTypography.bodySmall)),
                GestureDetector(
                  onTap: () => _onSlotRemoved(i),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        // Empty slot placeholder
        return Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 2,
            horizontal: AppSpacing.space1,
          ),
          child: Row(
            children: [
              Text(
                '${i + 1}순위: ',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.scheduleMutedAccent,
                ),
              ),
              Text(
                '(미선택)',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.scheduleMutedAccent,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  String _slotDisplayLabel(SelectedSlot slot) {
    final dayLabel = _dayLabels[slot.dayOfWeek.clamp(0, 6)];

    if (widget.lessonType == LessonRequestType.regular) {
      return '매주 $dayLabel요일 ${slot.startTime}';
    }

    // Trial / perSession: show specific date
    if (slot.date != null) {
      final d = slot.date!;
      return '${d.month}/${d.day}($dayLabel) ${slot.startTime}';
    }
    return '$dayLabel ${slot.startTime}';
  }
}
