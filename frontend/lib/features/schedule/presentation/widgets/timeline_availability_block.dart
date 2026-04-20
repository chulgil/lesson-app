import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'timeline_lesson_block.dart' show kTimelineUnitHeight;

/// An availability (open slot) block in the timeline view.
/// Dashed border, light background, tappable.
class TimelineAvailabilityBlock extends StatelessWidget {
  final int durationMinutes;
  final VoidCallback? onTap;

  const TimelineAvailabilityBlock({
    super.key,
    required this.durationMinutes,
    this.onTap,
  });

  double get blockHeight => (durationMinutes / 30.0) * kTimelineUnitHeight;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: blockHeight,
        margin: const EdgeInsets.symmetric(vertical: 1),
        decoration: BoxDecoration(
          color: AppColors.availabilityEmpty,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(color: AppColors.availabilityBorder, width: 1),
        ),
        child: Center(
          child: Text(
            '가용',
            style: AppTypography.caption.copyWith(
              color: AppColors.availabilityText,
            ),
          ),
        ),
      ),
    );
  }
}
