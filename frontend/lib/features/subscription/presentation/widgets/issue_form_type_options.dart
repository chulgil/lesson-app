import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
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
          title: '회차',
          options: const [4, 8, 12],
          currentValue: totalLessons,
          onChanged: onLessonsChanged,
          controller: lessonsController,
          suffix: '회',
        ),
        const SizedBox(height: AppSpacing.space4),
        ChipInputField(
          title: '유효기간',
          options: const [60, 90, 180],
          currentValue: validityDays,
          onChanged: onValidityChanged,
          controller: validityController,
          suffix: '일',
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
        Text('기간 선택', style: AppTypography.headingSmall),
        const SizedBox(height: AppSpacing.space3),
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children:
              [1, 3, 6, 12].map((months) {
                final isSelected = monthsCount == months;
                return ChoiceChip(
                  label: Text('$months개월'),
                  selected: isSelected,
                  onSelected: (_) => onChanged(months),
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  checkmarkColor: AppColors.primary,
                  backgroundColor: AppColors.surfaceLight,
                  side: BorderSide(
                    color:
                        isSelected ? AppColors.primary : AppColors.borderLight,
                  ),
                  labelStyle: AppTypography.bodyMedium.copyWith(
                    color:
                        isSelected
                            ? AppColors.primary
                            : AppColors.textSecondaryLight,
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
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Text(
              '체험 레슨은 1회 수강권이 발급됩니다.\n무료 또는 할인된 금액으로 설정할 수 있습니다.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
