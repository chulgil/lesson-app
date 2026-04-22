import 'package:flutter/material.dart';

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
          title: '할인',
          isOptional: true,
          options: const [0, 5, 10, 20],
          currentValue: discountPercent,
          onChanged: onChanged,
          controller: controller,
          suffix: '%',
          maxValue: 100,
          selectedColor: AppColors.paperAccent,
          zeroLabel: '없음',
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
          title: '보너스',
          isOptional: true,
          options: const [0, 1, 2, 3],
          currentValue: bonusLessons,
          onChanged: onBonusLessonsChanged,
          controller: bonusController,
          suffix: '회',
          zeroLabel: '없음',
          labelFormatter: (value) => value == 0 ? '없음' : '+$value회',
        ),
        if (bonusLessons > 0) ...[
          const SizedBox(height: AppSpacing.space3),
          Wrap(
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            children: [
              _buildBonusReasonChip('대량 구매'),
              _buildBonusReasonChip('5주차'),
              _buildBonusReasonChip('추천'),
              _buildBonusReasonChip('재등록'),
              _buildBonusReasonChip('기타'),
            ],
          ),
          if (bonusReason == '기타') ...[
            const SizedBox(height: AppSpacing.space3),
            TextFormField(
              controller: customBonusReasonController,
              decoration: InputDecoration(
                hintText: '사유를 직접 입력해주세요',
                filled: true,
                fillColor: AppColors.paper,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  borderSide: BorderSide(color: AppColors.inkQuaternary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
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
      selectedColor: AppColors.paperAccent.withValues(alpha: 0.15),
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
