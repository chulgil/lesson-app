import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/notebook_typography.dart';
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
    final actualMax =
        dailyStats.isEmpty
            ? maxMinutes
            : dailyStats
                .map((s) => s.practiceMinutes)
                .reduce((a, b) => a > b ? a : b);
    final chartMax = (actualMax * 1.2).clamp(30, 300).toInt();

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
              Icon(Icons.bar_chart, color: AppColors.paperAccent, size: 20),
              const SizedBox(width: AppSpacing.space2),
              // Notebook × Score: 카드 섹션 제목은 Playfair sectionTitle 로 통일 (§7.17 패턴).
              Text('일별 연습 시간', style: NotebookTypography.sectionTitle),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),

          SizedBox(
            height: barHeight + 40, // Extra space for labels
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children:
                  dailyStats.map((stat) {
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
    final isToday =
        stat.date.year == now.year &&
        stat.date.month == now.month &&
        stat.date.day == now.day;
    final isFuture = stat.date.isAfter(now);

    // Calculate bar height percentage
    final heightPercent =
        chartMax > 0 ? (stat.practiceMinutes / chartMax).clamp(0.0, 1.0) : 0.0;

    // Determine bar color
    Color barColor;
    if (isFuture) {
      barColor = AppColors.paperDark;
    } else if (!stat.hasPracticed) {
      barColor = AppColors.inkQuaternary;
    } else if (stat.practiceMinutes >= 45) {
      barColor = AppColors.paperOk;
    } else if (stat.practiceMinutes >= 20) {
      barColor = AppColors.practiceNormal;
    } else {
      barColor = AppColors.paperAccent;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Time label (only if practiced)
        if (stat.hasPracticed)
          Text(
            '${stat.practiceMinutes}분',
            style: AppTypography.caption.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        const SizedBox(height: AppSpacing.space1),

        // Bar
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32,
          height: stat.hasPracticed ? barHeight * heightPercent : 4,
          decoration: BoxDecoration(
            color: barColor,
            ),
        ),
        const SizedBox(height: AppSpacing.space2),

        // Day label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isToday ? AppColors.paperAccent : Colors.transparent,
            ),
          child: Text(
            stat.dayLabel,
            style: AppTypography.caption.copyWith(
              color: isToday ? Colors.white : AppColors.inkSecondary,
              fontWeight: isToday ? FontWeight.w600 : null,
            ),
          ),
        ),
      ],
    );
  }
}
