import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import 'chip_input_field.dart';

class PackageOptionsSection extends StatelessWidget {
  final int totalLessons;
  final int validityDays;
  final ValueChanged<int> onLessonsChanged;
  final ValueChanged<int> onValidityChanged;
  final TextEditingController lessonsController;
  final TextEditingController validityController;

  const PackageOptionsSection({
    super.key,
    required this.totalLessons,
    required this.validityDays,
    required this.onLessonsChanged,
    required this.onValidityChanged,
    required this.lessonsController,
    required this.validityController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChipInputField(
          title: AppStrings.issueFormLessonsTitle,
          options: const [4, 8, 12],
          currentValue: totalLessons,
          onChanged: onLessonsChanged,
          controller: lessonsController,
          suffix: AppStrings.issueFormLessonsSuffix,
        ),
        const SizedBox(height: AppSpacing.space4),
        ChipInputField(
          title: AppStrings.issueFormValidityTitle,
          options: const [60, 90, 180],
          currentValue: validityDays,
          onChanged: onValidityChanged,
          controller: validityController,
          suffix: AppStrings.issueFormValiditySuffix,
        ),
      ],
    );
  }
}

class MonthlyOptionsSection extends StatelessWidget {
  final int monthsCount;
  final ValueChanged<int> onChanged;

  const MonthlyOptionsSection({
    super.key,
    required this.monthsCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Notebook × Score: 폼 섹션 제목은 Playfair sectionTitle
        // 로 통일 (§7.17).
        Text(
          AppStrings.issueFormMonthlySectionTitle,
          style: NotebookTypography.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.space3),
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children:
              [1, 3, 6, 12].map((months) {
                final isSelected = monthsCount == months;
                return ChoiceChip(
                  label: Text(AppStrings.issueFormMonthsLabel(months)),
                  selected: isSelected,
                  onSelected: (_) => onChanged(months),
                  selectedColor: AppColors.paperAccentSoft,
                  checkmarkColor: AppColors.paperAccent,
                  backgroundColor: AppColors.paper,
                  side: BorderSide(
                    color:
                        isSelected
                            ? AppColors.paperAccent
                            : AppColors.inkQuaternary,
                  ),
                  labelStyle: AppTypography.bodyMedium.copyWith(
                    color:
                        isSelected
                            ? AppColors.paperAccent
                            : AppColors.inkSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}

class TrialOptionsSection extends StatelessWidget {
  const TrialOptionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(color: AppColors.paperAccentSoft),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.paperAccent),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Text(
              AppStrings.issueFormTrialNotice,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.paperAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
