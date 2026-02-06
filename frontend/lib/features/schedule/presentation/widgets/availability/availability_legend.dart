import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Legend for availability status colors
class AvailabilityLegend extends StatelessWidget {
  final bool showBookedByMe;

  const AvailabilityLegend({
    super.key,
    this.showBookedByMe = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.space4,
      runSpacing: AppSpacing.space2,
      children: [
        _LegendItem(
          icon: '🟢',
          label: showBookedByMe ? '예약가능' : '가용',
        ),
        if (showBookedByMe)
          const _LegendItem(
            icon: '🔵',
            label: '내 예약',
          )
        else
          const _LegendItem(
            icon: '🔵',
            label: '예약됨',
          ),
        const _LegendItem(
          icon: '⛔',
          label: '휴무',
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String icon;
  final String label;

  const _LegendItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}
