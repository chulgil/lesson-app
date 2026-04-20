// Range picker button widget for section forms

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Button that shows the current range value and opens the picker
class RangePickerButton extends StatelessWidget {
  final String label;
  final int value;
  final String unit;
  final VoidCallback onTap;

  const RangePickerButton({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.space1),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$value',
                  style: AppTypography.headingLarge.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.space1),
                Text(
                  unit,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
