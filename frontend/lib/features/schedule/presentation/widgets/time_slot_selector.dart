import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Time slot status for availability
enum TimeSlotStatus {
  available, // Can be selected
  unavailable, // Outside teacher's available hours or lesson would exceed
  booked, // Already booked by another student
  selected, // Currently selected
}

/// Model for a time slot with status
class SelectableTimeSlot {
  final TimeOfDay time;
  final TimeSlotStatus status;
  final String? bookedBy; // Student name if booked

  const SelectableTimeSlot({
    required this.time,
    this.status = TimeSlotStatus.available,
    this.bookedBy,
  });

  SelectableTimeSlot copyWith({
    TimeOfDay? time,
    TimeSlotStatus? status,
    String? bookedBy,
  }) {
    return SelectableTimeSlot(
      time: time ?? this.time,
      status: status ?? this.status,
      bookedBy: bookedBy ?? this.bookedBy,
    );
  }
}

/// Time slot selector widget with 30-minute intervals
///
/// Displays time slots in a grid layout:
/// - Fixed 30-minute intervals (on the hour and half hour)
/// - 4-column grid layout
/// - 24-hour time format (14:00, 16:00)
/// - Disabled slots shown in gray
class TimeSlotSelector extends StatelessWidget {
  /// Selected time (null if none selected)
  final TimeOfDay? selectedTime;

  /// Callback when a time slot is selected
  final ValueChanged<TimeOfDay>? onTimeSelected;

  /// Teacher's available start time for this day
  final TimeOfDay availableStart;

  /// Teacher's available end time for this day
  final TimeOfDay availableEnd;

  /// Lesson duration in minutes (to check if lesson fits before end time)
  final int lessonDurationMinutes;

  /// Already booked time slots (by other students)
  final List<TimeOfDay> bookedSlots;

  /// Display range start (default: 9:00)
  final TimeOfDay displayStart;

  /// Display range end (default: 22:00)
  final TimeOfDay displayEnd;

  const TimeSlotSelector({
    super.key,
    this.selectedTime,
    this.onTimeSelected,
    required this.availableStart,
    required this.availableEnd,
    this.lessonDurationMinutes = 60,
    this.bookedSlots = const [],
    this.displayStart = const TimeOfDay(hour: 9, minute: 0),
    this.displayEnd = const TimeOfDay(hour: 22, minute: 0),
  });

  @override
  Widget build(BuildContext context) {
    final allSlots = _generateAllSlots();

    return _buildTimeGrid(allSlots);
  }

  Widget _buildTimeGrid(List<SelectableTimeSlot> slots) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 2.2,
        crossAxisSpacing: AppSpacing.space2,
        mainAxisSpacing: AppSpacing.space2,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        return _TimeSlotButton(
          slot: slot,
          isSelected:
              selectedTime != null &&
              selectedTime!.hour == slot.time.hour &&
              selectedTime!.minute == slot.time.minute,
          onTap:
              slot.status == TimeSlotStatus.available
                  ? () => onTimeSelected?.call(slot.time)
                  : null,
        );
      },
    );
  }

  List<SelectableTimeSlot> _generateAllSlots() {
    final slots = <SelectableTimeSlot>[];

    final startMinutes = displayStart.hour * 60 + displayStart.minute;
    final endMinutes = displayEnd.hour * 60 + displayEnd.minute;

    // Generate slots at 30-minute intervals
    for (var minutes = startMinutes; minutes < endMinutes; minutes += 30) {
      final hour = minutes ~/ 60;
      final minute = minutes % 60;
      final time = TimeOfDay(hour: hour, minute: minute);

      final status = _getSlotStatus(time);
      final bookedBy = _getBookedBy(time);

      slots.add(
        SelectableTimeSlot(time: time, status: status, bookedBy: bookedBy),
      );
    }

    return slots;
  }

  TimeSlotStatus _getSlotStatus(TimeOfDay time) {
    final timeMinutes = time.hour * 60 + time.minute;
    final availStartMinutes = availableStart.hour * 60 + availableStart.minute;
    final availEndMinutes = availableEnd.hour * 60 + availableEnd.minute;
    final lessonEndMinutes = timeMinutes + lessonDurationMinutes;

    // Check if booked
    for (final booked in bookedSlots) {
      if (booked.hour == time.hour && booked.minute == time.minute) {
        return TimeSlotStatus.booked;
      }
    }

    // Check if outside available hours
    if (timeMinutes < availStartMinutes) {
      return TimeSlotStatus.unavailable;
    }

    // Check if lesson would exceed available end time
    if (lessonEndMinutes > availEndMinutes) {
      return TimeSlotStatus.unavailable;
    }

    return TimeSlotStatus.available;
  }

  String? _getBookedBy(TimeOfDay time) {
    for (final booked in bookedSlots) {
      if (booked.hour == time.hour && booked.minute == time.minute) {
        return AppStrings
            .scheduleBooked; // In production, this would be the student name
      }
    }
    return null;
  }
}

/// Individual time slot button
class _TimeSlotButton extends StatelessWidget {
  final SelectableTimeSlot slot;
  final bool isSelected;
  final VoidCallback? onTap;

  const _TimeSlotButton({
    required this.slot,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _getBackgroundColor(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: _getBorderColor(),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              _formatTime(slot.time),
              style: AppTypography.bodyMedium.copyWith(
                color: _getTextColor(),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (isSelected) {
      return AppColors.paperAccent;
    }
    switch (slot.status) {
      case TimeSlotStatus.available:
        return Colors.transparent;
      case TimeSlotStatus.unavailable:
      case TimeSlotStatus.booked:
        return AppColors.paperDark;
      case TimeSlotStatus.selected:
        return AppColors.paperAccent;
    }
  }

  Color _getBorderColor() {
    if (isSelected) {
      return AppColors.paperAccent;
    }
    switch (slot.status) {
      case TimeSlotStatus.available:
        return AppColors.inkQuaternary;
      case TimeSlotStatus.unavailable:
      case TimeSlotStatus.booked:
        return Colors.transparent;
      case TimeSlotStatus.selected:
        return AppColors.paperAccent;
    }
  }

  Color _getTextColor() {
    if (isSelected) {
      return AppColors.paper;
    }
    switch (slot.status) {
      case TimeSlotStatus.available:
        return AppColors.ink;
      case TimeSlotStatus.unavailable:
      case TimeSlotStatus.booked:
        return AppColors.inkTertiary;
      case TimeSlotStatus.selected:
        return AppColors.paper;
    }
  }

  /// Format time in 24-hour format for display (14:00, 16:30)
  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
