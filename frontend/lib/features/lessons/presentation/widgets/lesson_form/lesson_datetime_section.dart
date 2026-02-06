import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
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
    final dateFormat = DateFormat('yyyy년 M월 d일 (E)', 'ko');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
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
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: AppColors.primary,
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
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      Text(
                        dateFormat.format(selectedDate),
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
                  color: AppColors.textTertiaryLight,
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
                          color: AppColors.textSecondaryLight,
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
                  color: AppColors.textTertiaryLight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
