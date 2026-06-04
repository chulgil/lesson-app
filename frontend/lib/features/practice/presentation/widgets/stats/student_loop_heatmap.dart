import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/entities/practice_loop_stats.dart';

/// Per-section heatmap (#512).
///
/// Each section becomes a tinted row whose intensity scales with the
/// student's repeat count — darker = more repeats = a section the student
/// likely finds difficult. Spec §4.4 "구간별 히트맵".
class StudentLoopHeatmap extends StatelessWidget {
  final List<PracticeLoopStats> rows;

  const StudentLoopHeatmap({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }
    final maxRepeats = rows
        .map((r) => r.repeatCount)
        .fold<int>(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.teacherStatsHardestSections,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          ...rows.map((row) => _HeatmapRow(row: row, maxRepeats: maxRepeats)),
        ],
      ),
    );
  }
}

class _HeatmapRow extends StatelessWidget {
  final PracticeLoopStats row;
  final int maxRepeats;

  const _HeatmapRow({required this.row, required this.maxRepeats});

  @override
  Widget build(BuildContext context) {
    final intensity = maxRepeats == 0
        ? 0.0
        : (row.repeatCount / maxRepeats).clamp(0.0, 1.0);
    // Accent at full intensity, very light cream when empty. Border stays
    // constant for grid feel.
    final background = Color.lerp(
      AppColors.paper,
      AppColors.paperAccent,
      intensity,
    );
    final textColor = intensity > 0.55 ? AppColors.paper : AppColors.ink;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: background,
          border: Border.all(color: AppColors.inkQuaternary),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                row.displayLabel,
                style: AppTypography.bodyMedium.copyWith(color: textColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            Text(
              '${row.repeatCount}${AppStrings.teacherStatsRepeatsUnit}',
              style: AppTypography.bodyMedium.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
