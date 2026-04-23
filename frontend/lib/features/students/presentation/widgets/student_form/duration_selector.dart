import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Duration selector buttons.
class DurationSelector extends StatelessWidget {
  final int selectedDuration;
  final ValueChanged<int> onChanged;
  final List<int> durations;

  const DurationSelector({
    super.key,
    required this.selectedDuration,
    required this.onChanged,
    this.durations = const [30, 45, 60, 90, 120],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paperDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children:
            durations.map((duration) {
              final isSelected = selectedDuration == duration;
              return GestureDetector(
                onTap: () => onChanged(duration),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppColors.paperAccent : Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                  ),
                  child: Text(
                    '$duration',
                    style: AppTypography.bodySmall.copyWith(
                      // Notebook × Score §7.50: Vermillion selected chip foreground = paper.
                      color:
                          isSelected ? AppColors.paper : AppColors.inkSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
