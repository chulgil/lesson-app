import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/entities/availability_slot.dart';
import 'availability_date_navigator.dart';
import 'availability_booking_preview.dart';
import 'empty_slots_suggestion.dart';

/// Chip-based time slot selector for students
///
/// Displays available time slots as chips that students can tap to select.
/// Features:
/// - Date navigation with swipe
/// - Time grouping (morning/afternoon) when 5+ slots
/// - Smart recommendation (⭐) for usual lesson times
/// - Empty state with alternative date suggestions
class AvailabilityChipSelector extends StatelessWidget {
  final DateTime selectedDate;
  final List<AvailabilitySlot> availableSlots;
  final AvailabilitySlot? selectedSlot;
  final List<DateSuggestion>? alternativeDates;
  final String teacherName;
  final String instrument;
  final int? remainingLessons;
  final int? totalLessons;
  final int? lessonFee;
  final int? remainingReschedules;
  final int? totalReschedules;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<AvailabilitySlot> onSlotSelected;
  final VoidCallback? onBook;
  final bool isLoading;

  const AvailabilityChipSelector({
    super.key,
    required this.selectedDate,
    required this.availableSlots,
    this.selectedSlot,
    this.alternativeDates,
    required this.teacherName,
    required this.instrument,
    this.remainingLessons,
    this.totalLessons,
    this.lessonFee,
    this.remainingReschedules,
    this.totalReschedules,
    required this.onDateChanged,
    required this.onSlotSelected,
    this.onBook,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final selectableSlots = availableSlots.where(
      (s) =>
          s.status == AvailabilitySlotStatus.available ||
          s.status == AvailabilitySlotStatus.myBooking,
    ).toList();

    return Column(
      children: [
        // Date navigation
        AvailabilityDateNavigator(
          selectedDate: selectedDate,
          onDateChanged: onDateChanged,
        ),

        // Content
        Expanded(
          child: selectableSlots.isEmpty
              ? _buildEmptyState()
              : _buildSlotChips(selectableSlots),
        ),

        // Booking preview (when slot selected)
        if (selectedSlot != null)
          AvailabilityBookingPreview(
            selectedSlot: selectedSlot!,
            teacherName: teacherName,
            instrument: instrument,
            remainingLessons: remainingLessons,
            totalLessons: totalLessons,
            lessonFee: lessonFee,
            remainingReschedules: remainingReschedules,
            totalReschedules: totalReschedules,
            onBook: onBook,
            isLoading: isLoading,
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: EmptySlotsSuggestion(
        selectedDate: selectedDate,
        suggestions: alternativeDates ?? [],
        onDateSelected: onDateChanged,
      ),
    );
  }

  Widget _buildSlotChips(List<AvailabilitySlot> slots) {
    // Group by morning/afternoon if 5+ slots
    final shouldGroup = slots.length >= 5;
    final morningSlots = slots.where((s) => s.isMorning).toList();
    final afternoonSlots = slots.where((s) => s.isAfternoon).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            '예약 가능한 시간',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: AppSpacing.space3),

          if (shouldGroup && morningSlots.isNotEmpty) ...[
            // Morning section
            _buildTimeSection('🌅 오전', morningSlots),
            const SizedBox(height: AppSpacing.space4),
          ],

          if (shouldGroup && afternoonSlots.isNotEmpty) ...[
            // Afternoon section
            _buildTimeSection('🌆 오후', afternoonSlots),
          ] else if (!shouldGroup) ...[
            // No grouping - flat list
            _buildChipGrid(slots),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeSection(String label, List<AvailabilitySlot> slots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        _buildChipGrid(slots),
      ],
    );
  }

  Widget _buildChipGrid(List<AvailabilitySlot> slots) {
    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      children: slots.map((slot) {
        final isSelected = selectedSlot?.id == slot.id;
        return _TimeChip(
          slot: slot,
          isSelected: isSelected,
          onTap: () => onSlotSelected(slot),
        );
      }).toList(),
    );
  }
}

/// Individual time chip
class _TimeChip extends StatelessWidget {
  final AvailabilitySlot slot;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeChip({
    required this.slot,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onTap, // Double tap also selects (could trigger immediate booking)
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(
          minWidth: 72,
          minHeight: 44,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: _borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (slot.isRecommended && !isSelected) ...[
              const Text(
                '⭐',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(width: AppSpacing.space1),
            ],
            Text(
              slot.formattedStartTime,
              style: AppTypography.bodyMedium.copyWith(
                color: _textColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color get _backgroundColor {
    if (isSelected) {
      return AppColors.paperAccent;
    }
    if (slot.isRecommended) {
      return AppColors.paperAccentSoft; // Light orange
    }
    return AppColors.paperDark; // #FFFAF5
  }

  Color get _borderColor {
    if (isSelected) {
      return AppColors.paperAccent;
    }
    if (slot.isRecommended) {
      return AppColors.paperAccent; // #F4A460
    }
    return AppColors.inkQuaternary;
  }

  Color get _textColor {
    if (isSelected) {
      return Colors.white;
    }
    return AppColors.ink;
  }
}
