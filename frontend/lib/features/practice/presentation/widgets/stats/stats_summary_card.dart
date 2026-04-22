import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/entities/entities.dart';

/// Summary card displaying key statistics
class StatsSummaryCard extends StatelessWidget {
  final PracticeStatsReport report;

  const StatsSummaryCard({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.inkQuaternary),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights,
                color: AppColors.paperAccent,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '요약',
                style: AppTypography.headingSmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),

          // Stats grid
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.timer,
                  label: '연습 시간',
                  value: report.totalTimeText,
                  color: AppColors.paperAccent,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.calendar_today,
                  label: '연습일',
                  value: '${report.practiceDayCount}일',
                  color: AppColors.paperOk,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.check_circle,
                  label: '완료율',
                  value: '${report.completionPercent}%',
                  color: AppColors.paperAccent,
                ),
              ),
            ],
          ),

          // Additional stats for monthly report
          if (report.type == ReportType.monthly) ...[
            const SizedBox(height: AppSpacing.space4),
            const Divider(),
            const SizedBox(height: AppSpacing.space3),
            Row(
              children: [
                Expanded(
                  child: _buildMiniStat(
                    label: '일평균',
                    value: report.avgDailyTimeText,
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: _buildMiniStat(
                    label: '현재 스트릭',
                    value: '${report.currentStreak}일',
                    icon: Icons.local_fire_department,
                    iconColor: AppColors.paperAccent,
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: _buildMiniStat(
                    label: '최대 스트릭',
                    value: '${report.maxStreak}일',
                    icon: Icons.emoji_events,
                    iconColor: AppColors.amber,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.space2),
          Text(
            value,
            style: AppTypography.headingSmall.copyWith(
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required String label,
    required String value,
    IconData? icon,
    Color? iconColor,
  }) {
    return Column(
      children: [
        if (icon != null) ...[
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: AppSpacing.space1),
        ],
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
      ],
    );
  }
}
