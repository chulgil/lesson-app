import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/notebook_typography.dart';
import '../../../domain/entities/entities.dart';

/// List widget showing repertoire-level statistics
class RepertoireStatsList extends StatelessWidget {
  final List<RepertoireStats> repertoireStats;

  const RepertoireStatsList({super.key, required this.repertoireStats});

  @override
  Widget build(BuildContext context) {
    if (repertoireStats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.paper,
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
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.library_music, color: AppColors.paperAccent, size: 20),
              const SizedBox(width: AppSpacing.space2),
              // Notebook × Score: 카드 섹션 제목은 Playfair sectionTitle 로 통일 (§7.17 패턴).
              Text('레퍼토리별 연습', style: NotebookTypography.sectionTitle),
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
                  color: AppColors.paperAccent.withAlpha(20),
                  ),
                child: Text(
                  stat.practiceTimeText,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.paperAccent,
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
                        ),
                    ),
                    FractionallySizedBox(
                      widthFactor: stat.completionRate.clamp(0.0, 1.0),
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.paperAccent,
                              AppColors.paperAccent,
                            ],
                          ),
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
            style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
          ),
        ],
      ),
    );
  }
}
