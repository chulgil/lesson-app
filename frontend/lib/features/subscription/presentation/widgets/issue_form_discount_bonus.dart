import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_utils.dart';
import 'chip_input_field.dart';

class DiscountSection extends StatelessWidget {
  final int discountPercent;
  final int originalAmount;
  final int finalAmount;
  final ValueChanged<int> onChanged;
  final TextEditingController controller;

  const DiscountSection({
    super.key,
    required this.discountPercent,
    required this.originalAmount,
    required this.finalAmount,
    required this.onChanged,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChipInputField(
          title: AppStrings.issueFormDiscountTitle,
          isOptional: true,
          options: const [0, 5, 10, 20],
          currentValue: discountPercent,
          onChanged: onChanged,
          controller: controller,
          suffix: AppStrings.issueFormPercentSuffix,
          maxValue: 100,
          selectedColor: AppColors.paperAccent,
          zeroLabel: AppStrings.issueFormZeroLabel,
        ),
        if (discountPercent > 0 && originalAmount > 0) ...[
          const SizedBox(height: AppSpacing.space2),
          Text(
            '${formatWonWithComma(originalAmount)} → ${formatWonWithComma(finalAmount)} (-${formatWonWithComma(originalAmount - finalAmount)})',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.paperAccent,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class BonusSection extends StatelessWidget {
  final int bonusLessons;
  final String? bonusReason;
  final String customBonusReason;
  final ValueChanged<int> onBonusLessonsChanged;
  final ValueChanged<String> onBonusReasonChanged;
  final ValueChanged<String> onCustomBonusReasonChanged;
  final TextEditingController bonusController;
  final TextEditingController customBonusReasonController;

  const BonusSection({
    super.key,
    required this.bonusLessons,
    required this.bonusReason,
    required this.customBonusReason,
    required this.onBonusLessonsChanged,
    required this.onBonusReasonChanged,
    required this.onCustomBonusReasonChanged,
    required this.bonusController,
    required this.customBonusReasonController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChipInputField(
          title: AppStrings.issueFormBonusTitle,
          isOptional: true,
          options: const [0, 1, 2, 3],
          currentValue: bonusLessons,
          onChanged: onBonusLessonsChanged,
          controller: bonusController,
          suffix: AppStrings.issueFormLessonsSuffix,
          zeroLabel: AppStrings.issueFormZeroLabel,
          labelFormatter: AppStrings.issueFormBonusFormatter,
        ),
        if (bonusLessons > 0) ...[
          const SizedBox(height: AppSpacing.space3),
          Wrap(
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            children: [
              _buildBonusReasonChip(AppStrings.issueFormBonusReasonBulk),
              _buildBonusReasonChip(AppStrings.issueFormBonusReasonFifthWeek),
              _buildBonusReasonChip(AppStrings.issueFormBonusReasonReferral),
              _buildBonusReasonChip(AppStrings.issueFormBonusReasonRenewal),
              _buildBonusReasonChip(AppStrings.issueFormBonusReasonOther),
            ],
          ),
          if (bonusReason == AppStrings.issueFormBonusReasonOther) ...[
            const SizedBox(height: AppSpacing.space3),
            TextFormField(
              controller: customBonusReasonController,
              decoration: InputDecoration(
                hintText: AppStrings.issueFormBonusReasonCustomHint,
                filled: true,
                fillColor: AppColors.paper,
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.inkQuaternary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.inkQuaternary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space4,
                  vertical: AppSpacing.space3,
                ),
              ),
              onChanged: onCustomBonusReasonChanged,
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildBonusReasonChip(String reason) {
    final isSelected = bonusReason == reason;
    return ChoiceChip(
      label: Text(reason),
      selected: isSelected,
      onSelected: (_) => onBonusReasonChanged(reason),
      selectedColor: AppColors.paperAccentSoft,
      checkmarkColor: AppColors.paperAccent,
      backgroundColor: AppColors.paper,
      side: BorderSide(
        color: isSelected ? AppColors.paperAccent : AppColors.inkQuaternary,
      ),
      labelStyle: AppTypography.bodySmall.copyWith(
        color: isSelected ? AppColors.paperAccent : AppColors.inkSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}
