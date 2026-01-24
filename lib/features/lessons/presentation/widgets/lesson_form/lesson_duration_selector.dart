import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Lesson duration selector
class LessonDurationSelector extends StatelessWidget {
  final int selectedDuration;
  final ValueChanged<int> onDurationChanged;

  const LessonDurationSelector({
    super.key,
    required this.selectedDuration,
    required this.onDurationChanged,
  });

  static const List<(int, String)> durations = [
    (30, '30분'),
    (45, '45분'),
    (60, '1시간'),
    (90, '1시간 30분'),
    (120, '2시간'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      children: durations.map((d) {
        final isSelected = selectedDuration == d.$1;
        return ChoiceChip(
          label: Text(d.$2),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              onDurationChanged(d.$1);
            }
          },
          backgroundColor: AppColors.surfaceLight,
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
          checkmarkColor: AppColors.primary,
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
          ),
          labelStyle: AppTypography.bodySmall.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textPrimaryLight,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
}
