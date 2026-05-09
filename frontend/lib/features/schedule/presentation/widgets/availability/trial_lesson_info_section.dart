import 'package:flutter/material.dart';

import '../../../../../core/booking/presentation/extensions/lesson_booking_visual_extensions.dart';
import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/notebook/thin_rule.dart';
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
        const ThinRule(),
        const SizedBox(height: AppSpacing.space4),

        // Lesson goal
        Text(
          '레슨 목표',
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        Wrap(
          spacing: AppSpacing.space2,
          children:
              LessonGoal.values.map((goal) {
                final isSelected = goal == selectedGoal;
                return ChoiceChip(
                  label: Text(goal.label),
                  selected: isSelected,
                  onSelected: (_) => onGoalChanged(goal),
                  selectedColor: AppColors.paperAccent,
                  backgroundColor: AppColors.paper,
                  labelStyle: AppTypography.bodySmall.copyWith(
                    color: isSelected ? AppColors.paper : AppColors.ink,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color:
                        isSelected
                            ? AppColors.paperAccent
                            : AppColors.inkQuaternary,
                  ),
                  shape: RoundedRectangleBorder(),
                );
              }).toList(),
        ),

        const SizedBox(height: AppSpacing.space4),

        // Experience level
        Text(
          '악기 경험',
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        Wrap(
          spacing: AppSpacing.space2,
          children:
              ExperienceLevel.values.map((level) {
                final isSelected = level == selectedExperience;
                return ChoiceChip(
                  label: Text(level.label),
                  selected: isSelected,
                  onSelected: (_) => onExperienceChanged(level),
                  selectedColor: AppColors.paperAccent,
                  backgroundColor: AppColors.paper,
                  labelStyle: AppTypography.bodySmall.copyWith(
                    color: isSelected ? AppColors.paper : AppColors.ink,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color:
                        isSelected
                            ? AppColors.paperAccent
                            : AppColors.inkQuaternary,
                  ),
                  shape: RoundedRectangleBorder(),
                );
              }).toList(),
        ),

        const SizedBox(height: AppSpacing.space4),

        // Message (optional)
        Text(
          '선생님께 전달할 메시지',
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '선택사항',
          style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
        ),
        const SizedBox(height: AppSpacing.space2),
        TextField(
          controller: messageController,
          maxLines: 3,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: AppStrings.scheduleTrialLessonHint,
            hintStyle: AppTypography.bodySmall.copyWith(
              color: AppColors.inkTertiary,
            ),
            filled: true,
            fillColor: AppColors.paper,
            border: OutlineInputBorder(
              borderSide: const BorderSide(color: AppColors.inkQuaternary),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AppColors.inkQuaternary),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                color: AppColors.paperAccent,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.all(AppSpacing.space3),
            counterStyle: AppTypography.caption.copyWith(
              color: AppColors.inkTertiary,
            ),
          ),
          style: AppTypography.bodySmall.copyWith(color: AppColors.ink),
        ),

        const SizedBox(height: AppSpacing.space4),
      ],
    );
  }
}
