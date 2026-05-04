import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Legend for availability status colors
class AvailabilityLegend extends StatelessWidget {
  final bool showBookedByMe;

  const AvailabilityLegend({super.key, this.showBookedByMe = false});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.space4,
      runSpacing: AppSpacing.space2,
      children: [
        _LegendItem(
          icon: '🟢',
          label:
              showBookedByMe
                  ? AppStrings.scheduleAvailable
                  : AppStrings.scheduleOpen,
        ),
        if (showBookedByMe)
          const _LegendItem(icon: '🔵', label: AppStrings.scheduleMyBooking)
        else
          const _LegendItem(icon: '🔵', label: AppStrings.scheduleBooked),
        const _LegendItem(icon: '⛔', label: AppStrings.scheduleHoliday),
        const _LegendItem(icon: '⏹️', label: AppStrings.schedulePastTime),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String icon;
  final String label;

  const _LegendItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: AppTypography.bodyMedium),
        const SizedBox(width: AppSpacing.space1),
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.inkSecondary),
        ),
      ],
    );
  }
}
