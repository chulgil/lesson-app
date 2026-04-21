import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// 7-day practice sparkline (ux_guidelines §2.7).
///
/// Shows recent practice trend as a mini bar chart.
/// Color indicates average practice level:
/// - Green (🟢): 5+ days of 7
/// - Yellow (🟡): 3~4 days
/// - Red (🔴): 0~2 days
///
/// Values: 0.0 (no practice) ~ 1.0 (full day).
class PracticeSparkline extends StatelessWidget {
  /// Practice intensity for the last 7 days. Length must be 7.
  /// Each value in range [0.0, 1.0].
  final List<double> values;

  /// Height of the sparkline (default: 16).
  final double height;

  /// Width of the sparkline (default: 56).
  final double width;

  const PracticeSparkline({
    super.key,
    required this.values,
    this.height = 16,
    this.width = 56,
  }) : assert(values.length == 7, 'Sparkline requires exactly 7 values');

  @override
  Widget build(BuildContext context) {
    final color = _trendColor;

    return SizedBox(
      width: width,
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children:
            values.map((v) {
              final normalized = v.clamp(0.0, 1.0);
              final barHeight = (height * normalized).clamp(2.0, height);
              return Container(
                width: (width / 7) - 1,
                height: barHeight,
                decoration: BoxDecoration(
                  color: normalized > 0 ? color : AppColors.inkQuaternary,
                  borderRadius: BorderRadius.circular(1),
                ),
              );
            }).toList(),
      ),
    );
  }

  /// Count days with practice (value > 0).
  int get _practiceDays => values.where((v) => v > 0).length;

  /// Determine color based on practice days out of 7.
  Color get _trendColor {
    final days = _practiceDays;
    if (days >= 5) return AppColors.success;
    if (days >= 3) return AppColors.warning;
    return AppColors.error;
  }
}
