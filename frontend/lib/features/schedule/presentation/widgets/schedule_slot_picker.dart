import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/teacher_availability.dart';
import '../providers/teacher_availability_providers.dart';

/// Read-only weekly schedule slot picker for selecting an available time slot.
///
/// Shows a simplified weekly grid (Mon-Sun columns, hour rows).
/// Available slots are tappable; booked slots show as occupied (no student info).
/// Selected slot is highlighted with primary color.
class ScheduleSlotPicker extends ConsumerStatefulWidget {
  final String teacherId;

  /// Currently selected day (0=Mon...6=Sun), null if none selected
  final int? selectedDay;

  /// Currently selected time in HH:mm format, null if none selected
  final String? selectedTime;

  /// Callback when a slot is selected
  final ValueChanged<({int dayOfWeek, String startTime, String endTime})>
  onSlotSelected;

  /// First visible hour (inclusive, default 9)
  final int startHour;

  /// Last visible hour (exclusive, default 21)
  final int endHour;

  const ScheduleSlotPicker({
    super.key,
    required this.teacherId,
    this.selectedDay,
    this.selectedTime,
    required this.onSlotSelected,
    this.startHour = 9,
    this.endHour = 21,
  });

  @override
  ConsumerState<ScheduleSlotPicker> createState() => _ScheduleSlotPickerState();
}

class _ScheduleSlotPickerState extends ConsumerState<ScheduleSlotPicker> {
  static const _dayLabels = ['월', '화', '수', '목', '금', '토', '일'];
  static const _timeColumnWidth = 40.0;
  static const _cellHeight = 44.0;
  static const _headerHeight = 32.0;

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
                '스케줄을 불러올 수 없습니다',
                style: TextStyle(color: AppColors.inkSecondary),
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

    final slotMap = _buildSlotMap(availability);
    final hours = List.generate(
      widget.endHour - widget.startHour,
      (i) => widget.startHour + i,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDayHeaders(),
        const Divider(height: 1, color: AppColors.scheduleGridLine),
        ...hours.map((hour) => _buildHourRow(hour, slotMap, availability)),
      ],
    );
  }

  Widget _buildDayHeaders() {
    return SizedBox(
      height: _headerHeight,
      child: Row(
        children: [
          SizedBox(width: _timeColumnWidth, child: const SizedBox.shrink()),
          ..._dayLabels.map(
            (label) => Expanded(
              child: Center(
                child: Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourRow(
    int hour,
    Map<_SlotKey, _SlotState> slotMap,
    TeacherAvailability availability,
  ) {
    final timeLabel = '${hour.toString().padLeft(2, '0')}:00';

    return SizedBox(
      height: _cellHeight,
      child: Row(
        children: [
          // Time label column
          SizedBox(
            width: _timeColumnWidth,
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.space1),
              child: Align(
                alignment: Alignment.topRight,
                child: Text(
                  timeLabel,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                ),
              ),
            ),
          ),
          // Day cells
          ...List.generate(7, (dayIndex) {
            final key = _SlotKey(dayOfWeek: dayIndex, hour: hour);
            final slotState = slotMap[key] ?? _SlotState.unavailable;
            return Expanded(
              child: _buildCell(dayIndex, hour, slotState, availability),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCell(
    int dayOfWeek,
    int hour,
    _SlotState slotState,
    TeacherAvailability availability,
  ) {
    final isSelected =
        widget.selectedDay == dayOfWeek &&
        _matchesHour(widget.selectedTime, hour);

    final cellConfig = _getCellConfig(slotState, isSelected);
    final isTappable = slotState == _SlotState.available;

    return GestureDetector(
      onTap:
          isTappable
              ? () => _handleSlotTap(dayOfWeek, hour, availability)
              : null,
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: cellConfig.backgroundColor,
          border:
              isSelected
                  ? Border.all(color: AppColors.paperAccent, width: 1.5)
                  : null,
        ),
        child: Center(
          child:
              cellConfig.icon != null
                  ? Icon(cellConfig.icon, size: 14, color: cellConfig.textColor)
                  : const SizedBox.shrink(),
        ),
      ),
    );
  }

  _CellConfig _getCellConfig(_SlotState slotState, bool isSelected) {
    if (isSelected) {
      return const _CellConfig(
        backgroundColor: AppColors.paperAccent,
        textColor: AppColors.paper,
        icon: Icons.check,
      );
    }

    switch (slotState) {
      case _SlotState.available:
        return _CellConfig(
          backgroundColor: AppColors.paperAccentSoft.withValues(alpha: 0.2),
          textColor: AppColors.paperAccent,
        );
      case _SlotState.booked:
        return const _CellConfig(
          backgroundColor: AppColors.scheduleMutedBackground,
          textColor: AppColors.scheduleMutedAccent,
          icon: Icons.block,
        );
      case _SlotState.unavailable:
        return const _CellConfig(
          backgroundColor: Colors.transparent,
          textColor: Colors.transparent,
        );
    }
  }

  void _handleSlotTap(
    int dayOfWeek,
    int hour,
    TeacherAvailability availability,
  ) {
    final startTime = '${hour.toString().padLeft(2, '0')}:00';
    final endMinutes = hour * 60 + availability.slotDurationMinutes;
    final endHour = endMinutes ~/ 60;
    final endMinute = endMinutes % 60;
    final endTime =
        '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';

    widget.onSlotSelected((
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
    ));
  }

  /// Build a map of (dayOfWeek, hour) -> slot state from weekly schedules
  /// and booked slots.
  Map<_SlotKey, _SlotState> _buildSlotMap(TeacherAvailability availability) {
    final Map<_SlotKey, _SlotState> result = {};

    // Mark available slots from weekly schedules
    for (final schedule in availability.weeklySchedules) {
      if (!schedule.isActive) continue;

      final startHour = _parseHour(schedule.startTime);
      final endHour = _parseHour(schedule.endTime);

      for (var h = startHour; h < endHour; h++) {
        if (h >= widget.startHour && h < widget.endHour) {
          final key = _SlotKey(dayOfWeek: schedule.dayOfWeek, hour: h);
          result[key] = _SlotState.available;
        }
      }
    }

    return result;
  }

  int _parseHour(String timeStr) {
    final parts = timeStr.split(':');
    return int.tryParse(parts[0]) ?? 0;
  }

  bool _matchesHour(String? timeStr, int hour) {
    if (timeStr == null) return false;
    return _parseHour(timeStr) == hour;
  }
}

// -- Private helper types --

/// Key for identifying a slot in the weekly grid
class _SlotKey {
  final int dayOfWeek;
  final int hour;

  const _SlotKey({required this.dayOfWeek, required this.hour});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SlotKey && dayOfWeek == other.dayOfWeek && hour == other.hour;

  @override
  int get hashCode => dayOfWeek.hashCode ^ (hour.hashCode << 3);
}

/// Visual state of a slot cell
enum _SlotState { available, booked, unavailable }

/// Configuration for rendering a cell
class _CellConfig {
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const _CellConfig({
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });
}
