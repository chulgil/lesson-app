import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/booking/entities/time_slot.dart';

/// Widget for picking available time slots
class TimeSlotPicker extends StatelessWidget {
  final List<TimeSlot> availableSlots;
  final TimeSlot? selectedSlot;
  final ValueChanged<TimeSlot> onSlotSelected;
  final bool isLoading;

  const TimeSlotPicker({
    super.key,
    required this.availableSlots,
    this.selectedSlot,
    required this.onSlotSelected,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.space6),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (availableSlots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy,
              size: 48,
              color: AppColors.inkTertiary,
            ),
            const SizedBox(height: AppSpacing.space3),
            Text(
              '가능한 시간이 없습니다',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              '다른 날짜를 선택해주세요',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      children: availableSlots.map((slot) {
        final isSelected = selectedSlot?.id == slot.id;
        return _TimeSlotChip(
          slot: slot,
          isSelected: isSelected,
          onTap: () => onSlotSelected(slot),
        );
      }).toList(),
    );
  }
}

class _TimeSlotChip extends StatelessWidget {
  final TimeSlot slot;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeSlotChip({
    required this.slot,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppColors.paperAccent
          : AppColors.paper,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space3,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(
              color: isSelected ? AppColors.paperAccent : AppColors.inkQuaternary,
            ),
          ),
          child: Text(
            slot.timeRange,
            style: AppTypography.bodySmall.copyWith(
              color: isSelected ? Colors.white : AppColors.ink,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget for selecting a date with available dates highlighted
class DatePickerWithAvailability extends StatelessWidget {
  final DateTime selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final List<DateTime> availableDates;
  final ValueChanged<DateTime> onDateSelected;

  const DatePickerWithAvailability({
    super.key,
    required this.selectedDate,
    required this.firstDate,
    required this.lastDate,
    required this.availableDates,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return CalendarDatePicker(
      initialDate: selectedDate,
      firstDate: firstDate,
      lastDate: lastDate,
      onDateChanged: onDateSelected,
      selectableDayPredicate: (date) {
        // Check if date is in available dates
        return availableDates.any((d) =>
            d.year == date.year &&
            d.month == date.month &&
            d.day == date.day);
      },
    );
  }
}

/// A simple horizontal day selector for the week
class WeekDaySelector extends StatelessWidget {
  final DateTime startDate;
  final DateTime selectedDate;
  final Set<int> availableDays; // 1 = Monday, 7 = Sunday
  final ValueChanged<DateTime> onDateSelected;

  const WeekDaySelector({
    super.key,
    required this.startDate,
    required this.selectedDate,
    required this.availableDays,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final days = List.generate(7, (index) {
      return startDate.add(Duration(days: index));
    });

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days.map((date) {
        final isSelected = date.year == selectedDate.year &&
            date.month == selectedDate.month &&
            date.day == selectedDate.day;
        final isAvailable = availableDays.contains(date.weekday);
        final dayNames = ['월', '화', '수', '목', '금', '토', '일'];

        return GestureDetector(
          onTap: isAvailable ? () => onDateSelected(date) : null,
          child: Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.paperAccent
                  : isAvailable
                      ? Colors.transparent
                      : AppColors.paperDark,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Column(
              children: [
                Text(
                  dayNames[date.weekday - 1],
                  style: AppTypography.caption.copyWith(
                    color: isSelected
                        ? Colors.white
                        : isAvailable
                            ? AppColors.inkSecondary
                            : AppColors.inkTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  '${date.day}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isSelected
                        ? Colors.white
                        : isAvailable
                            ? AppColors.ink
                            : AppColors.inkTertiary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
