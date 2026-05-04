import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Recurring lesson section
class LessonRecurringSection extends StatelessWidget {
  final bool isRecurring;
  final ValueChanged<bool> onRecurringChanged;
  final Set<int> selectedDays;
  final ValueChanged<int> onDayToggle;

  const LessonRecurringSection({
    super.key,
    required this.isRecurring,
    required this.onRecurringChanged,
    required this.selectedDays,
    required this.onDayToggle,
  });

  static const List<String> dayNames = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle recurring
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '정기 레슨',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '매주 같은 요일/시간에 레슨 예약',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(value: isRecurring, onChanged: onRecurringChanged),
            ],
          ),

          // Recurring days selector
          if (isRecurring) ...[
            const SizedBox(height: AppSpacing.space4),
            const Divider(),
            const SizedBox(height: AppSpacing.space3),
            Text(
              '반복 요일',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                final isSelected = selectedDays.contains(index);
                return GestureDetector(
                  onTap: () => onDayToggle(index),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? AppColors.paperAccent
                              : AppColors.paperDark,
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Center(
                      child: Text(
                        dayNames[index],
                        style: AppTypography.bodySmall.copyWith(
                          // Notebook × Score §7.50: selected day circle = paper (Vermillion bg).
                          color:
                              isSelected
                                  ? AppColors.paper
                                  : AppColors.inkSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.space3),
            Container(
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(color: AppColors.paperAccentSoft),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppColors.paperAccent,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      '4주간의 레슨이 자동으로 예약됩니다',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.paperAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
