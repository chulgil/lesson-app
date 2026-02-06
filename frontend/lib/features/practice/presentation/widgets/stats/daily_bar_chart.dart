import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/entities/entities.dart';

/// Bar chart showing daily practice time
class DailyBarChart extends StatelessWidget {
  final List<DailyStats> dailyStats;
  final int maxMinutes;
  final double barHeight;

  const DailyBarChart({
    super.key,
    required this.dailyStats,
    this.maxMinutes = 60,
    this.barHeight = 120,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate max value for scaling
    final actualMax = dailyStats.isEmpty
        ? maxMinutes
        : dailyStats
            .map((s) => s.practiceMinutes)
            .reduce((a, b) => a > b ? a : b);
    final chartMax = (actualMax * 1.2).clamp(30, 300).toInt();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '일별 연습 시간',
                style: AppTypography.headingSmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),

          SizedBox(
            height: barHeight + 40, // Extra space for labels
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: dailyStats.map((stat) {
                return _buildBar(stat, chartMax);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(DailyStats stat, int chartMax) {
    final now = DateTime.now();
    final isToday = stat.date.year == now.year &&
        stat.date.month == now.month &&
        stat.date.day == now.day;
    final isFuture = stat.date.isAfter(now);

    // Calculate bar height percentage
    final heightPercent =
        chartMax > 0 ? (stat.practiceMinutes / chartMax).clamp(0.0, 1.0) : 0.0;

    // Determine bar color
    Color barColor;
    if (isFuture) {
      barColor = AppColors.surfaceSecondaryLight;
    } else if (!stat.hasPracticed) {
      barColor = AppColors.borderLight;
    } else if (stat.practiceMinutes >= 45) {
      barColor = AppColors.practiceGood;
    } else if (stat.practiceMinutes >= 20) {
      barColor = AppColors.practiceNormal;
    } else {
      barColor = AppColors.practicePoor;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Time label (only if practiced)
        if (stat.hasPracticed)
          Text(
            '${stat.practiceMinutes}분',
            style: AppTypography.caption.copyWith(
              fontSize: 10,
              color: AppColors.textSecondaryLight,
            ),
          ),
        const SizedBox(height: 4),

        // Bar
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32,
          height: stat.hasPracticed ? barHeight * heightPercent : 4,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: AppSpacing.space2),

        // Day label
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: isToday ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            stat.dayLabel,
            style: AppTypography.caption.copyWith(
              color: isToday ? Colors.white : AppColors.textSecondaryLight,
              fontWeight: isToday ? FontWeight.w600 : null,
            ),
          ),
        ),
      ],
    );
  }
}
