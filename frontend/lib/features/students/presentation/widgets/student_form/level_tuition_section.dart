import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../features/students/domain/entities/student.dart';
import 'frequency_option.dart';
import 'student_form_helpers.dart';

/// Level and tuition section with fee input.
/// When [isLinked] is true (student has class memberships),
/// the fee field becomes read-only with a notice.
class LevelAndTuitionSection extends StatelessWidget {
  final StudentLevel selectedLevel;
  final ValueChanged<StudentLevel> onLevelChanged;
  final TextEditingController feeController;
  final int lessonsPerWeek;
  final ValueChanged<int> onFrequencyChanged;
  final VoidCallback onFeeChanged;
  final bool isLinked;
  final VoidCallback? onManageSubscription;

  const LevelAndTuitionSection({
    super.key,
    required this.selectedLevel,
    required this.onLevelChanged,
    required this.feeController,
    required this.lessonsPerWeek,
    required this.onFrequencyChanged,
    required this.onFeeChanged,
    this.isLinked = false,
    this.onManageSubscription,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.inkQuaternary),
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
                backgroundColor: AppColors.paper,
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primary,
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.inkQuaternary,
                ),
                labelStyle: AppTypography.bodySmall.copyWith(
                  color:
                      isSelected ? AppColors.primary : AppColors.ink,
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
                    if (isLinked)
                      Text(
                        '수강권으로 관리 중',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.ink,
                        ),
                      )
                    else
                      Text(
                        '기본: ${formatCurrencyInMan(selectedLevel.defaultMonthlyFee)}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.inkSecondary,
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
                      enabled: !isLinked,
                      decoration: InputDecoration(
                        suffixText: '원',
                        filled: isLinked,
                        fillColor: isLinked
                            ? AppColors.paperDark
                            : null,
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
                              const BorderSide(color: AppColors.inkQuaternary),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMedium),
                          borderSide:
                              const BorderSide(color: AppColors.inkQuaternary),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      textAlign: TextAlign.end,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isLinked
                            ? AppColors.inkTertiary
                            : null,
                      ),
                      onChanged: (_) => onFeeChanged(),
                    ),
                  ),
                  // Preview in 만원 units
                  if (feeController.text.isNotEmpty && !isLinked)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.space1),
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

          // Linked student: show subscription management shortcut
          if (isLinked && onManageSubscription != null) ...[
            const SizedBox(height: AppSpacing.space3),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onManageSubscription,
                icon: const Icon(Icons.confirmation_number_outlined, size: 18),
                label: const Text('수강권 관리'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  side: BorderSide(
                      color: AppColors.ink.withValues(alpha: 0.4)),
                ),
              ),
            ),
          ],

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
              color: AppColors.inkSecondary,
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
              color: (isLinked ? AppColors.ink : AppColors.primary)
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: isLinked ? AppColors.ink : AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    isLinked
                        ? '수강권이 발급된 학생은 수강료가 수강권에서 관리됩니다'
                        : '수강료를 직접 수정하면 레벨 기본값과 다르게 설정됩니다',
                    style: AppTypography.caption.copyWith(
                      color: isLinked ? AppColors.ink : AppColors.primary,
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
