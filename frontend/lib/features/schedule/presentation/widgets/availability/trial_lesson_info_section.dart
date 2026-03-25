import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/booking/entities/lesson_booking.dart';

/// Trial lesson info section — collects goal, experience, and optional message.
///
/// Displayed inline within [LessonBookingScreen] when `isTrialLesson=true`.
/// Uses chip-based selection for quick, low-friction input.
class TrialLessonInfoSection extends StatelessWidget {
  final LessonGoal selectedGoal;
  final ExperienceLevel selectedExperience;
  final TextEditingController messageController;
  final ValueChanged<LessonGoal> onGoalChanged;
  final ValueChanged<ExperienceLevel> onExperienceChanged;

  const TrialLessonInfoSection({
    super.key,
    required this.selectedGoal,
    required this.selectedExperience,
    required this.messageController,
    required this.onGoalChanged,
    required this.onExperienceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, color: AppColors.borderLight),
        const SizedBox(height: AppSpacing.space4),

        // Lesson goal
        Text(
          '레슨 목표',
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        Wrap(
          spacing: AppSpacing.space2,
          children: LessonGoal.values.map((goal) {
            final isSelected = goal == selectedGoal;
            return ChoiceChip(
              label: Text(goal.label),
              selected: isSelected,
              onSelected: (_) => onGoalChanged(goal),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceLight,
              labelStyle: AppTypography.bodySmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimaryLight,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.borderLight,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: AppSpacing.space4),

        // Experience level
        Text(
          '악기 경험',
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        Wrap(
          spacing: AppSpacing.space2,
          children: ExperienceLevel.values.map((level) {
            final isSelected = level == selectedExperience;
            return ChoiceChip(
              label: Text(level.label),
              selected: isSelected,
              onSelected: (_) => onExperienceChanged(level),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceLight,
              labelStyle: AppTypography.bodySmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimaryLight,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.borderLight,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: AppSpacing.space4),

        // Message (optional)
        Text(
          '선생님께 전달할 메시지',
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '선택사항',
          style: AppTypography.caption.copyWith(
            color: AppColors.textTertiaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        TextField(
          controller: messageController,
          maxLines: 3,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: '배우고 싶은 곡이나 궁금한 점을 적어주세요',
            hintStyle: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiaryLight,
            ),
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(AppSpacing.space3),
            counterStyle: AppTypography.caption.copyWith(
              color: AppColors.textTertiaryLight,
            ),
          ),
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textPrimaryLight,
          ),
        ),

        const SizedBox(height: AppSpacing.space4),
      ],
    );
  }
}
