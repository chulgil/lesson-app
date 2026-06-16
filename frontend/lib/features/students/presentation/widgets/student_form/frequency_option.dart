import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Frequency option button.
class FrequencyOption extends StatelessWidget {
  final int value;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const FrequencyOption({
    super.key,
    required this.value,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.paperAccentSoft : AppColors.paperDark,
          border: Border.all(
            color: isSelected ? AppColors.paperAccent : AppColors.inkQuaternary,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              Icon(Icons.check_circle, size: 20, color: AppColors.paperAccent),
              const SizedBox(width: AppSpacing.space2),
            ],
            Flexible(
              child: Column(
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.paperAccent : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color:
                          isSelected
                              ? AppColors.paperAccent
                              : AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
