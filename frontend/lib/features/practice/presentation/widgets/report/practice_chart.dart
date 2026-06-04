import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/entities/practice_report.dart';

/// Bar chart visualising daily practice minutes for a report period.
///
/// `dailyEntries` length determines bar count (7 weekly, 28-31 monthly).
class PracticeChart extends StatelessWidget {
  final List<DailyReportEntry> dailyEntries;

  const PracticeChart({super.key, required this.dailyEntries});

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
            AppStrings.practiceReportDailyChartTitle,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          if (dailyEntries.isEmpty || _maxMinutes() == 0)
            _EmptyChart()
          else
            SizedBox(
              height: 160,
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
                        reservedSize: 22,
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

  int _maxMinutes() {
    if (dailyEntries.isEmpty) return 0;
    return dailyEntries
        .map((e) => e.practiceMinutes)
        .reduce((a, b) => a > b ? a : b);
  }

  double _chartMaxY() {
    final maxMinutes = _maxMinutes();
    if (maxMinutes <= 0) return 60;
    return (maxMinutes * 1.2).clamp(30, 600).toDouble();
  }

  List<BarChartGroupData> _buildGroups() {
    final groups = <BarChartGroupData>[];
    for (var i = 0; i < dailyEntries.length; i++) {
      final entry = dailyEntries[i];
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: entry.practiceMinutes.toDouble(),
              color: entry.hasPracticed
                  ? AppColors.paperAccent
                  : AppColors.inkQuaternary,
              width: _barWidth(),
              borderRadius: BorderRadius.zero,
            ),
          ],
        ),
      );
    }
    return groups;
  }

  double _barWidth() {
    final count = dailyEntries.length;
    if (count <= 7) return 18;
    if (count <= 14) return 12;
    return 6;
  }

  Widget _bottomLabel(double value, TitleMeta meta) {
    final index = value.toInt();
    if (index < 0 || index >= dailyEntries.length) {
      return const SizedBox.shrink();
    }
    // Show one label every N days to avoid overlap on monthly view.
    final stride = dailyEntries.length <= 7
        ? 1
        : (dailyEntries.length / 7).ceil();
    if (index % stride != 0) return const SizedBox.shrink();

    final date = dailyEntries[index].date;
    final label = dailyEntries.length <= 7
        ? _weekdayLabel(date.weekday)
        : '${date.day}';

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(color: AppColors.inkSecondary),
      ),
    );
  }

  String _weekdayLabel(int weekday) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    return labels[(weekday - 1).clamp(0, 6)];
  }
}

class _EmptyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Center(
        child: Text(
          AppStrings.practiceReportEmptyChart,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
      ),
    );
  }
}
