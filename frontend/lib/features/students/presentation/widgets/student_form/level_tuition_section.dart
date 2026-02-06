import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../models/student.dart';
import 'frequency_option.dart';
import 'student_form_helpers.dart';

/// Level and tuition section with fee input.
class LevelAndTuitionSection extends StatelessWidget {
  final StudentLevel selectedLevel;
  final ValueChanged<StudentLevel> onLevelChanged;
  final TextEditingController feeController;
  final int lessonsPerWeek;
  final ValueChanged<int> onFrequencyChanged;
  final VoidCallback onFeeChanged;

  const LevelAndTuitionSection({
    super.key,
    required this.selectedLevel,
    required this.onLevelChanged,
    required this.feeController,
    required this.lessonsPerWeek,
    required this.onFrequencyChanged,
    required this.onFeeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Level selector
          Text(
            '레벨',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          Wrap(
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            children: StudentLevel.values.map((level) {
              final isSelected = selectedLevel == level;
              return ChoiceChip(
                label: Text(level.label),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    onLevelChanged(level);
                  }
                },
                backgroundColor: AppColors.surfaceLight,
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primary,
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.borderLight,
                ),
                labelStyle: AppTypography.bodySmall.copyWith(
                  color:
                      isSelected ? AppColors.primary : AppColors.textPrimaryLight,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppSpacing.space4),
          const Divider(),
          const SizedBox(height: AppSpacing.space4),

          // Monthly fee
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '월 수강료',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      '기본: ${formatCurrencyInMan(selectedLevel.defaultMonthlyFee)}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 140,
                    child: TextFormField(
                      controller: feeController,
                      decoration: InputDecoration(
                        suffixText: '원',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space3,
                          vertical: AppSpacing.space2,
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMedium),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMedium),
                          borderSide:
                              const BorderSide(color: AppColors.borderLight),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      textAlign: TextAlign.end,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      onChanged: (_) => onFeeChanged(),
                    ),
                  ),
                  // Preview in 만원 units
                  if (feeController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        formatCurrencyInMan(
                          int.tryParse(feeController.text) ?? 0,
                        ),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),
          const Divider(),
          const SizedBox(height: AppSpacing.space4),

          // Lesson frequency
          Text(
            '레슨 횟수',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            '주 1회는 월 4회, 주 2회는 월 8회 레슨입니다',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          Row(
            children: [
              Expanded(
                child: FrequencyOption(
                  value: 1,
                  title: '주 1회',
                  subtitle: '월 4회',
                  isSelected: lessonsPerWeek == 1,
                  onTap: () => onFrequencyChanged(1),
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: FrequencyOption(
                  value: 2,
                  title: '주 2회',
                  subtitle: '월 8회',
                  isSelected: lessonsPerWeek == 2,
                  onTap: () => onFrequencyChanged(2),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          // Info note
          Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    '수강료를 직접 수정하면 레벨 기본값과 다르게 설정됩니다',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
