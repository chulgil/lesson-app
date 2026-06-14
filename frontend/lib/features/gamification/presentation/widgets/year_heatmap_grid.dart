import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/growth_heatmap.dart';

/// 1년 히트맵 — GitHub contribution graph 스타일 7×52 그리드.
///
/// 스펙 §4.4 / 플랜 Job 6 Task 6.1 / AC-6.1. 가로 스크롤 + 5단계 색 농도 +
/// L3+ inset dot 마커 (색맹 친화).
class YearHeatmapGrid extends StatelessWidget {
  const YearHeatmapGrid({
    super.key,
    required this.heatmap,
    required this.asOf,
    this.onDayTap,
    this.cellSize = 12.0,
    this.cellGap = 2.0,
  });

  final GrowthHeatmap heatmap;
  final DateTime asOf;
  final ValueChanged<DateTime>? onDayTap;
  final double cellSize;
  final double cellGap;

  /// 총 표시일 = 7행 × 52열 = 364일 (1년 근사).
  static const int _totalDays = 7 * 52;

  /// 5단계 임계값 매핑 — 0 / 1-15 / 16-30 / 31-60 / 61+ 분.
  static int minutesToLevel(int totalMinutes) {
    if (totalMinutes <= 0) return 0;
    if (totalMinutes <= 15) return 1;
    if (totalMinutes <= 30) return 2;
    if (totalMinutes <= 60) return 3;
    return 4;
  }

  /// 명도 단계 → AppColors heatmap 팔레트.
  static Color levelToColor(int level) {
    switch (level) {
      case 0:
        return AppColors.heatmapL0;
      case 1:
        return AppColors.heatmapL1;
      case 2:
        return AppColors.heatmapL2;
      case 3:
        return AppColors.heatmapL3;
      case 4:
        return AppColors.heatmapL4;
      default:
        return AppColors.heatmapL0;
    }
  }

  /// 그리드 시작 날짜 — `asOf` 에서 `_totalDays - 1` 일 전.
  ///
  /// 일요일 시작 정렬을 위해 추가 보정. weekday: Mon=1, ..., Sun=7.
  DateTime _gridStart() {
    final asOfDate = DateTime.utc(asOf.year, asOf.month, asOf.day);
    final raw = asOfDate.subtract(const Duration(days: _totalDays - 1));
    // raw 의 weekday 가 일요일 (7) 이 되도록 보정 (앞으로 며칠 당김)
    final daysToSunday = raw.weekday % 7;
    return raw.subtract(Duration(days: daysToSunday));
  }

  @override
  Widget build(BuildContext context) {
    final start = _gridStart();
    final asOfDate = DateTime.utc(asOf.year, asOf.month, asOf.day);
    // 그리드 너비: 7행 × 52열 + cap (시작 요일 보정으로 최대 53열)
    final columnCount =
        ((_totalDays + asOfDate.difference(start).inDays) / 7).ceil() + 1;

    return SingleChildScrollView(
      key: const ValueKey('year_heatmap_grid'),
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.all(AppSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(7, (row) {
          return Padding(
            padding: EdgeInsets.only(bottom: cellGap),
            child: Row(
              children: List.generate(columnCount, (col) {
                final dayIndex = col * 7 + row;
                final date = start.add(Duration(days: dayIndex));
                // asOf 이후 날짜는 hide
                if (date.isAfter(asOfDate)) {
                  return SizedBox(width: cellSize + cellGap);
                }
                return _HeatmapCell(
                  date: date,
                  daily: heatmap.days[date],
                  size: cellSize,
                  gap: cellGap,
                  onTap: onDayTap,
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

class _HeatmapCell extends StatelessWidget {
  const _HeatmapCell({
    required this.date,
    required this.daily,
    required this.size,
    required this.gap,
    this.onTap,
  });

  final DateTime date;
  final dynamic daily; // DailyPractice? — null 시 빈칸
  final double size;
  final double gap;
  final ValueChanged<DateTime>? onTap;

  @override
  Widget build(BuildContext context) {
    final minutes = daily?.totalMinutes ?? 0;
    final level = YearHeatmapGrid.minutesToLevel(minutes as int);
    final color = YearHeatmapGrid.levelToColor(level);
    final isoKey = date.toIso8601String();

    return GestureDetector(
      onTap: onTap == null ? null : () => onTap!(date),
      child: Container(
        key: ValueKey('heatmap_cell_$isoKey'),
        width: size,
        height: size,
        margin: EdgeInsets.only(right: gap),
        decoration: BoxDecoration(color: color),
        // L3+ inset dot 마커 (색맹 친화)
        child: level >= 3
            ? Center(
                child: Container(
                  key: ValueKey('heatmap_dot_$isoKey'),
                  width: size * 0.25,
                  height: size * 0.25,
                  decoration: const BoxDecoration(
                    color: AppColors.paper,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
