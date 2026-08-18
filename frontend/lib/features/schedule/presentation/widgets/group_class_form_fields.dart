// Chip-style field widgets for the group class form.
//
// These mirror the student form's ChoiceChip convention but live in the
// schedule feature: presentation code must not import another feature's
// widgets directly (feature_dependency_contract).

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/group_class.dart';
import '../extensions/no_show_policy_visuals.dart';

/// Single-select chip used across the group class form.
class GroupClassFormChip extends StatelessWidget {
  const GroupClassFormChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (isSelected) {
        if (isSelected) onSelected();
      },
      backgroundColor: AppColors.paper,
      selectedColor: AppColors.paperAccentSoft,
      checkmarkColor: AppColors.paperAccent,
      side: BorderSide(
        color: selected ? AppColors.paperAccent : AppColors.inkQuaternary,
      ),
      labelStyle: AppTypography.bodySmall.copyWith(
        color: selected ? AppColors.paperAccent : AppColors.ink,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

/// Instrument chips. Selecting the active chip again clears the choice.
class GroupClassInstrumentChips extends StatelessWidget {
  const GroupClassInstrumentChips({
    super.key,
    required this.selectedInstrument,
    required this.onChanged,
    this.instruments = const [
      '바이올린',
      '피아노',
      '첼로',
      '플루트',
      '클라리넷',
      '비올라',
      '기타',
      '성악',
      '드럼',
    ],
  });

  final String? selectedInstrument;
  final ValueChanged<String?> onChanged;
  final List<String> instruments;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      children: instruments.map((instrument) {
        final isSelected = selectedInstrument == instrument;
        return GroupClassFormChip(
          label: instrument,
          selected: isSelected,
          onSelected: () => onChanged(isSelected ? null : instrument),
        );
      }).toList(),
    );
  }
}

/// Weekday toggles for a regular class. Values are 1=Mon … 7=Sun, matching the
/// `repeat_days_of_week` wire contract.
class GroupClassWeekdayChips extends StatelessWidget {
  const GroupClassWeekdayChips({
    super.key,
    required this.selectedDays,
    required this.onToggle,
  });

  final Set<int> selectedDays;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      children: List.generate(7, (index) {
        final weekday = index + 1;
        return GroupClassFormChip(
          label: LessonDateUtils.getWeekdayNameKorean(weekday),
          selected: selectedDays.contains(weekday),
          onSelected: () => onToggle(weekday),
        );
      }),
    );
  }
}

/// Capacity chips. Capacity is owned by the class, never by a session (P1-0).
class GroupClassCapacityChips extends StatelessWidget {
  const GroupClassCapacityChips({
    super.key,
    required this.selectedCapacity,
    required this.onChanged,
    this.presets = const [2, 3, 4, 5, 6, 8, 10],
  });

  final int selectedCapacity;
  final ValueChanged<int> onChanged;
  final List<int> presets;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      children: presets.map((capacity) {
        return GroupClassFormChip(
          label: AppStrings.groupClassFormCapacityValue(capacity),
          selected: selectedCapacity == capacity,
          onSelected: () => onChanged(capacity),
        );
      }).toList(),
    );
  }
}

/// No-show policy chips — all four backend values (P2-3 SSOT).
class GroupClassNoShowPolicyChips extends StatelessWidget {
  const GroupClassNoShowPolicyChips({
    super.key,
    required this.selectedPolicy,
    required this.onChanged,
  });

  final NoShowPolicy selectedPolicy;
  final ValueChanged<NoShowPolicy> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children:
              // halfCredit retired 2026-08-18 (Obsidian 54) — no market precedent
              // and the integer session ledger cannot execute 0.5. The enum value
              // stays for legacy rows; it is just no longer selectable.
              NoShowPolicy.values
                  .where((policy) => policy != NoShowPolicy.halfCredit)
                  .map((policy) {
                    return GroupClassFormChip(
                      label: policy.label,
                      selected: selectedPolicy == policy,
                      onSelected: () => onChanged(policy),
                    );
                  })
                  .toList(),
        ),
        const SizedBox(height: AppSpacing.space2),
        Text(
          selectedPolicy.description,
          style: AppTypography.caption.copyWith(color: AppColors.inkSecondary),
        ),
      ],
    );
  }
}

/// Booking / cancellation deadline chips, in hours before the session.
///
/// Stored as minutes on the class; enforcement is backend-side (P2-1).
class GroupClassDeadlineChips extends StatelessWidget {
  const GroupClassDeadlineChips({
    super.key,
    required this.selectedMinutes,
    required this.onChanged,
    this.presetHours = const [0, 1, 3, 12, 24, 48],
  });

  final int selectedMinutes;
  final ValueChanged<int> onChanged;
  final List<int> presetHours;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      children: presetHours.map((hours) {
        return GroupClassFormChip(
          label: hours == 0
              ? AppStrings.groupClassFormDeadlineNone
              : AppStrings.groupClassFormDeadlineHours(hours),
          selected: selectedMinutes == hours * 60,
          onSelected: () => onChanged(hours * 60),
        );
      }).toList(),
    );
  }
}
