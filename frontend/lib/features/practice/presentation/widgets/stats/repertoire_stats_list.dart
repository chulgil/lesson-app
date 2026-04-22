import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/entities/entities.dart';

/// List widget showing repertoire-level statistics
class RepertoireStatsList extends StatelessWidget {
  final List<RepertoireStats> repertoireStats;

  const RepertoireStatsList({
    super.key,
    required this.repertoireStats,
  });

  @override
  Widget build(BuildContext context) {
    if (repertoireStats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          border: Border.all(color: AppColors.inkQuaternary),
        ),
        child: Center(
          child: Text(
            '연습한 레퍼토리가 없습니다',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.library_music,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '레퍼토리별 연습',
                style: AppTypography.headingSmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),

          ...repertoireStats.asMap().entries.map((entry) {
            final index = entry.key;
            final stat = entry.value;
            return Column(
              children: [
                _buildRepertoireItem(stat),
                if (index < repertoireStats.length - 1) ...[
                  const SizedBox(height: AppSpacing.space3),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRepertoireItem(RepertoireStats stat) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paperDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and time
          Row(
            children: [
              Expanded(
                child: Text(
                  stat.repertoireName,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Text(
                  stat.practiceTimeText,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),

          // Progress bar
          Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.inkQuaternary,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: stat.completionRate.clamp(0.0, 1.0),
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '${stat.completionPercent}%',
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space1),

          // Section count
          Text(
            '${stat.completedSections}/${stat.totalSections} 섹션 완료',
            style: AppTypography.caption.copyWith(
              color: AppColors.inkTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
