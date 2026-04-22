import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/date_format_utils.dart';
import 'lesson_form_helpers.dart';

/// Date and time selection section
class LessonDateTimeSection extends StatelessWidget {
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;

  const LessonDateTimeSection({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.onDateTap,
    required this.onTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPast = isLessonDateTimeInPast(selectedDate, selectedTime);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            border: Border.all(
              color: isPast ? AppColors.paperAccent : AppColors.inkQuaternary,
            ),
          ),
          child: Column(
            children: [
              // Date picker
              InkWell(
                onTap: onDateTap,
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isPast
                            ? AppColors.paperAccent.withValues(alpha: 0.1)
                            : AppColors.primary.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMedium),
                      ),
                      child: Icon(
                        isPast ? Icons.history : Icons.calendar_today,
                        color: isPast ? AppColors.paperAccent : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '날짜',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.inkSecondary,
                            ),
                          ),
                          Text(
                            formatDateYMDWithDay(selectedDate),
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w500,
                              color: isPast ? AppColors.paperAccent : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.edit,
                      size: 18,
                      color: AppColors.inkTertiary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.space3),
              const Divider(),
              const SizedBox(height: AppSpacing.space3),

              // Time picker
              InkWell(
                onTap: onTimeTap,
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMedium),
                      ),
                      child: const Icon(
                        Icons.access_time,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '시간',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.inkSecondary,
                            ),
                          ),
                          Text(
                            formatLessonTime(selectedTime),
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.edit,
                      size: 18,
                      color: AppColors.inkTertiary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Past date/time warning banner
        if (isPast) ...[
          const SizedBox(height: AppSpacing.space2),
          Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: AppColors.paperAccent, size: 18),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    '과거 시간입니다. 이미 진행한 레슨을 기록하는 경우에만 사용해주세요.',
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
    );
  }
}
