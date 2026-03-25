import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/schedule/domain/entities/lesson_booking.dart';

/// Widget for selecting schedule type (fixed/flexible)
class ScheduleTypeSelector extends StatelessWidget {
  final ScheduleType selectedType;
  final ValueChanged<ScheduleType> onTypeSelected;

  const ScheduleTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ScheduleTypeCard(
          type: ScheduleType.fixed,
          isSelected: selectedType == ScheduleType.fixed,
          isRecommended: true,
          onTap: () => onTypeSelected(ScheduleType.fixed),
        ),
        const SizedBox(height: AppSpacing.space3),
        _ScheduleTypeCard(
          type: ScheduleType.flexible,
          isSelected: selectedType == ScheduleType.flexible,
          isRecommended: false,
          onTap: () => onTypeSelected(ScheduleType.flexible),
        ),
      ],
    );
  }
}

class _ScheduleTypeCard extends StatelessWidget {
  final ScheduleType type;
  final bool isSelected;
  final bool isRecommended;
  final VoidCallback onTap;

  const _ScheduleTypeCard({
    required this.type,
    required this.isSelected,
    required this.isRecommended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppColors.primary.withValues(alpha: 0.08)
          : AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.borderLight,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.surfaceSecondaryLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                child: Icon(
                  type == ScheduleType.fixed
                      ? Icons.event_repeat
                      : Icons.event_note,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          type.label,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        if (isRecommended) ...[
                          const SizedBox(width: AppSpacing.space2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.practiceGood.withValues(alpha: 0.15),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusSmall),
                            ),
                            child: Text(
                              '권장',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.practiceGood,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      type.description,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Radio<ScheduleType>(
                value: type,
                groupValue: isSelected ? type : null,
                onChanged: (_) => onTap(),
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget for selecting lesson goal
class LessonGoalSelector extends StatelessWidget {
  final LessonGoal selectedGoal;
  final ValueChanged<LessonGoal> onGoalSelected;

  const LessonGoalSelector({
    super.key,
    required this.selectedGoal,
    required this.onGoalSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      children: LessonGoal.values.map((goal) {
        final isSelected = selectedGoal == goal;
        return ChoiceChip(
          label: Text(goal.label),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) onGoalSelected(goal);
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

/// Widget for selecting experience level
class ExperienceLevelSelector extends StatelessWidget {
  final ExperienceLevel selectedLevel;
  final ValueChanged<ExperienceLevel> onLevelSelected;

  const ExperienceLevelSelector({
    super.key,
    required this.selectedLevel,
    required this.onLevelSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      children: ExperienceLevel.values.map((level) {
        final isSelected = selectedLevel == level;
        return ChoiceChip(
          label: Text(level.label),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) onLevelSelected(level);
          },
          backgroundColor: AppColors.surfaceLight,
          selectedColor: AppColors.secondary.withValues(alpha: 0.15),
          checkmarkColor: AppColors.secondary,
          side: BorderSide(
            color: isSelected ? AppColors.secondary : AppColors.borderLight,
          ),
          labelStyle: AppTypography.bodySmall.copyWith(
            color: isSelected ? AppColors.secondary : AppColors.textPrimaryLight,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
}
