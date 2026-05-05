import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class ScheduleSlotChoice {
  const ScheduleSlotChoice({
    required this.priority,
    required this.label,
    this.supportingText,
  });

  final int priority;
  final String label;
  final String? supportingText;
}

class ScheduleSlotChoiceList extends StatelessWidget {
  const ScheduleSlotChoiceList({
    super.key,
    required this.choices,
    required this.selectedIndex,
    required this.onSelected,
    this.title = AppStrings.availableSchedules,
    this.description = AppStrings.slotSelectionHint,
    this.emptyText = AppStrings.noAvailableSchedules,
  });

  final List<ScheduleSlotChoice> choices;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;
  final String title;
  final String description;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          description,
          style: AppTypography.caption.copyWith(color: AppColors.inkSecondary),
        ),
        const SizedBox(height: AppSpacing.space2),
        if (choices.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: AppColors.scheduleMutedBackground,
              border: Border.all(color: AppColors.inkQuaternary),
            ),
            child: Text(
              emptyText,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          )
        else
          ...choices.asMap().entries.map((entry) {
            final index = entry.key;
            final choice = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space2),
              child: ScheduleSlotChoiceTile(
                choice: choice,
                selected: selectedIndex == index,
                onTap: () => onSelected(index),
              ),
            );
          }),
      ],
    );
  }
}

class ScheduleSlotChoiceTile extends StatelessWidget {
  const ScheduleSlotChoiceTile({
    super.key,
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final ScheduleSlotChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${choice.priority}${AppStrings.prioritySuffix}, ${choice.label}'
          '${selected ? ', ${AppStrings.selected}' : ''}',
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space3,
            vertical: AppSpacing.space2,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.paperAccentSoft : AppColors.paper,
            border: Border.all(
              color: selected ? AppColors.paperAccent : AppColors.inkQuaternary,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 32),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space2,
                  vertical: AppSpacing.space1,
                ),
                decoration: BoxDecoration(
                  color:
                      selected
                          ? AppColors.paperAccent
                          : AppColors.scheduleMutedBackground,
                  border: Border.all(
                    color:
                        selected
                            ? AppColors.paperAccent
                            : AppColors.inkQuaternary,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${choice.priority}${AppStrings.prioritySuffix}',
                  style: AppTypography.caption.copyWith(
                    color: selected ? AppColors.paper : AppColors.inkSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      choice.label,
                      style: AppTypography.bodySmall.copyWith(
                        color: selected ? AppColors.paperAccent : AppColors.ink,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (choice.supportingText != null &&
                        choice.supportingText!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.space1),
                      Text(
                        choice.supportingText!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.inkSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color:
                    selected ? AppColors.paperAccent : AppColors.inkQuaternary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
