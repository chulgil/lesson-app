import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/entities/practice_loop_stats.dart';

/// Bar chart visualising per-section repeat counts for the teacher view (#512).
///
/// One bar per section. Tallest bar = most-repeated section. Empty input
/// renders a placeholder card rather than an empty chart frame.
class StudentRepeatChart extends StatelessWidget {
  final List<PracticeLoopStats> rows;

  const StudentRepeatChart({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
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
            AppStrings.teacherStatsChartTitle,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          if (rows.isEmpty || _maxRepeats() == 0)
            const _EmptyChart()
          else
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _chartMaxY(),
                  minY: 0,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: _bottomLabel,
                      ),
                    ),
                  ),
                  barGroups: _buildGroups(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  int _maxRepeats() {
    if (rows.isEmpty) return 0;
    return rows.map((r) => r.repeatCount).reduce((a, b) => a > b ? a : b);
  }

  double _chartMaxY() {
    final maxR = _maxRepeats();
    if (maxR <= 0) return 10;
    return (maxR * 1.2).clamp(5, 1000).toDouble();
  }

  List<BarChartGroupData> _buildGroups() {
    return [
      for (var i = 0; i < rows.length; i++)
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: rows[i].repeatCount.toDouble(),
              color: AppColors.paperAccent,
              width: _barWidth(),
              borderRadius: BorderRadius.zero,
            ),
          ],
        ),
    ];
  }

  double _barWidth() {
    final count = rows.length;
    if (count <= 5) return 22;
    if (count <= 10) return 14;
    return 8;
  }

  Widget _bottomLabel(double value, TitleMeta meta) {
    final index = value.toInt();
    if (index < 0 || index >= rows.length) return const SizedBox.shrink();
    final stride = rows.length <= 5 ? 1 : (rows.length / 5).ceil();
    if (index % stride != 0) return const SizedBox.shrink();
    // Use compact index labels — full names appear in the row list below.
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '#${index + 1}',
        style: AppTypography.caption.copyWith(color: AppColors.inkSecondary),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Center(
        child: Text(
          AppStrings.teacherStatsStudentEmpty,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
      ),
    );
  }
}
