import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/entities/availability_slot.dart';

/// Shared slot chip list for picking an [AvailabilitySlot] on a given day.
///
/// Renders the morning/afternoon-grouped time chips defined by
/// student_direct_booking_spec.md §7 (paperAccent selected chip,
/// paperDark+inkQuaternary unselected). Extracted from
/// `LessonBookingScreen._SlotChips` and
/// `BookingRescheduleScreen._buildSlotChips`, which previously reimplemented
/// this UI independently against the same `availableSlotsForDateProvider`
/// (schedule_change_unification_spec.md §3.4).
class AvailabilitySlotChipList extends StatelessWidget {
  /// Already status-filtered available slots. The list is grouped into
  /// morning/afternoon internally and sorted by start hour, so callers don't
  /// need to pre-sort.
  final List<AvailabilitySlot> slots;
  final String? selectedId;
  final ValueChanged<AvailabilitySlot> onSelect;

  const AvailabilitySlotChipList({
    super.key,
    required this.slots,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...slots]
      ..sort((a, b) => a.startTime.hour.compareTo(b.startTime.hour));
    final morning = sorted.where((s) => s.isMorning).toList();
    final afternoon = sorted.where((s) => s.isAfternoon).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (morning.isNotEmpty) ...[
          _GroupLabel(AppStrings.timeAM),
          const SizedBox(height: AppSpacing.space2),
          _ChipRow(slots: morning, selectedId: selectedId, onSelect: onSelect),
          if (afternoon.isNotEmpty) const SizedBox(height: AppSpacing.space4),
        ],
        if (afternoon.isNotEmpty) ...[
          _GroupLabel(AppStrings.timePM),
          const SizedBox(height: AppSpacing.space2),
          _ChipRow(
            slots: afternoon,
            selectedId: selectedId,
            onSelect: onSelect,
          ),
        ],
      ],
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String label;
  const _GroupLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.caption.copyWith(
        color: AppColors.inkTertiary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  final List<AvailabilitySlot> slots;
  final String? selectedId;
  final ValueChanged<AvailabilitySlot> onSelect;

  const _ChipRow({
    required this.slots,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      children:
          slots.map((slot) {
            final isSelected = selectedId == slot.id;
            return GestureDetector(
              onTap: () => onSelect(slot),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                constraints: const BoxConstraints(minWidth: 72, minHeight: 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space4,
                  vertical: AppSpacing.space3,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppColors.paperAccent : AppColors.paperDark,
                  border: Border.all(
                    color:
                        isSelected
                            ? AppColors.paperAccent
                            : AppColors.inkQuaternary,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (slot.isRecommended && !isSelected) ...[
                      // #530 — recommended marker as a Material icon (UI-emoji
                      // HARD-GATE: no ⭐ pictograph in UI text).
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: AppColors.paperAccent,
                      ),
                      const SizedBox(width: AppSpacing.space1),
                    ],
                    // 시스템 데이터(시간) → 산세리프. Notebook §7.130 Gaegu 이항 룰.
                    Text(
                      slot.formattedStartTime,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isSelected ? AppColors.paper : AppColors.ink,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
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
