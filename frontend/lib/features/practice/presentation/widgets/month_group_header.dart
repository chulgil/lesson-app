// Month group header widget for repertoire timeline

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/repertoire_timeline.dart';

/// Divider-style header for a month group in the timeline
class MonthGroupHeader extends StatelessWidget {
  final MonthGroup monthGroup;

  const MonthGroupHeader({super.key, required this.monthGroup});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space3,
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.paperAccent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          Text(
            monthGroup.label,
            style: AppTypography.headingSmall.copyWith(
              color: AppColors.ink,
            ),
          ),
          if (monthGroup.hasInProgress) ...[
            const SizedBox(width: AppSpacing.space2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Text(
                '진행 중',
                style: AppTypography.caption.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(width: AppSpacing.space2),
          Expanded(child: Container(height: 1, color: AppColors.inkQuaternary)),
        ],
      ),
    );
  }
}
