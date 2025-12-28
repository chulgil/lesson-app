import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Time slot status for availability
enum TimeSlotStatus {
  available,    // Can be selected
  unavailable,  // Outside teacher's available hours or lesson would exceed
  booked,       // Already booked by another student
  selected,     // Currently selected
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

/// Time slot selector widget with AM/PM sections and 30-minute intervals
///
/// Displays time slots in a grid layout similar to Naver booking system:
/// - Fixed 30-minute intervals (on the hour and half hour)
/// - AM/PM section headers
/// - 4-column grid layout
/// - 12-hour time format for PM times
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

  /// Whether to show AM section (default: true)
  final bool showAmSection;

  /// Whether to show PM section (default: true)
  final bool showPmSection;

  /// Display range start (default: 9:00 AM)
  final TimeOfDay displayStart;

  /// Display range end (default: 10:00 PM)
  final TimeOfDay displayEnd;

  const TimeSlotSelector({
    super.key,
    this.selectedTime,
    this.onTimeSelected,
    required this.availableStart,
    required this.availableEnd,
    this.lessonDurationMinutes = 60,
    this.bookedSlots = const [],
    this.showAmSection = true,
    this.showPmSection = true,
    this.displayStart = const TimeOfDay(hour: 9, minute: 0),
    this.displayEnd = const TimeOfDay(hour: 22, minute: 0),
  });

  @override
  Widget build(BuildContext context) {
    final allSlots = _generateAllSlots();
    final amSlots = allSlots.where((s) => s.time.hour < 12).toList();
    final pmSlots = allSlots.where((s) => s.time.hour >= 12).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AM Section
        if (showAmSection && amSlots.isNotEmpty) ...[
          _buildSectionHeader('오전'),
          const SizedBox(height: AppSpacing.space3),
          _buildTimeGrid(amSlots),
          const SizedBox(height: AppSpacing.space5),
        ],

        // PM Section
        if (showPmSection && pmSlots.isNotEmpty) ...[
          _buildSectionHeader('오후'),
          const SizedBox(height: AppSpacing.space3),
          _buildTimeGrid(pmSlots),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.textSecondaryLight,
        fontWeight: FontWeight.w500,
      ),
    );
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
          isSelected: selectedTime != null &&
              selectedTime!.hour == slot.time.hour &&
              selectedTime!.minute == slot.time.minute,
          onTap: slot.status == TimeSlotStatus.available
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

      slots.add(SelectableTimeSlot(
        time: time,
        status: status,
        bookedBy: bookedBy,
      ));
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
        return '예약됨'; // In production, this would be the student name
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
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
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
      return AppColors.primary;
    }
    switch (slot.status) {
      case TimeSlotStatus.available:
        return Colors.transparent;
      case TimeSlotStatus.unavailable:
      case TimeSlotStatus.booked:
        return AppColors.surfaceSecondaryLight;
      case TimeSlotStatus.selected:
        return AppColors.primary;
    }
  }

  Color _getBorderColor() {
    if (isSelected) {
      return AppColors.primary;
    }
    switch (slot.status) {
      case TimeSlotStatus.available:
        return AppColors.borderLight;
      case TimeSlotStatus.unavailable:
      case TimeSlotStatus.booked:
        return Colors.transparent;
      case TimeSlotStatus.selected:
        return AppColors.primary;
    }
  }

  Color _getTextColor() {
    if (isSelected) {
      return Colors.white;
    }
    switch (slot.status) {
      case TimeSlotStatus.available:
        return AppColors.textPrimaryLight;
      case TimeSlotStatus.unavailable:
      case TimeSlotStatus.booked:
        return AppColors.textTertiaryLight;
      case TimeSlotStatus.selected:
        return Colors.white;
    }
  }

  /// Format time in 12-hour format for display
  /// AM: 10:00, 10:30, 11:00, 11:30
  /// PM: 12:00, 12:30, 1:00, 1:30, 2:00...
  String _formatTime(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');

    if (hour == 0) {
      return '12:$minute'; // Midnight
    } else if (hour < 12) {
      return '$hour:$minute'; // AM
    } else if (hour == 12) {
      return '12:$minute'; // Noon
    } else {
      return '${hour - 12}:$minute'; // PM
    }
  }
}
