// Simple vertical bar chart using CustomPaint.
// Spec: docs/specs/analytics/student_progress_dashboard_spec.md §6.2

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Vertical bar chart for revenue / lesson trend data.
///
/// Bars are drawn with [barColor] over a [AppColors.paper] background.
/// Grid lines use [AppColors.inkQuaternary].
class SimpleBarChart extends StatelessWidget {
  const SimpleBarChart({
    super.key,
    required this.data,
    this.barColor = AppColors.paperAccent,
    this.height = 160,
  });

  final List<({String label, int value})> data;
  final Color barColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          child: CustomPaint(
            painter: _BarChartPainter(data: data, barColor: barColor),
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        // Month labels row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
          child: Row(
            children: data.map((d) {
              return Expanded(
                child: Text(
                  d.label,
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<({String label, int value})> data;
  final Color barColor;

  _BarChartPainter({required this.data, required this.barColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxValue = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) return;

    const topPadding = 20.0; // space for value labels
    const bottomPadding = 4.0;
    final chartHeight = size.height - topPadding - bottomPadding;
    final barAreaWidth = size.width / data.length;
    final barWidth = barAreaWidth * 0.55;

    final gridPaint = Paint()
      ..color = AppColors.inkQuaternary
      ..strokeWidth = 0.5;

    // Horizontal grid lines (3 lines at 25%, 50%, 75%)
    for (final fraction in [0.25, 0.50, 0.75]) {
      final y = topPadding + chartHeight * (1 - fraction);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final barPaint = Paint()..color = barColor;

    for (int i = 0; i < data.length; i++) {
      final value = data[i].value;
      final barHeight = (value / maxValue) * chartHeight;
      final left = i * barAreaWidth + (barAreaWidth - barWidth) / 2;
      final top = topPadding + chartHeight - barHeight;

      final rect = Rect.fromLTWH(left, top, barWidth, barHeight);
      canvas.drawRect(rect, barPaint);

      // Value label above bar
      final textPainter = TextPainter(
        text: TextSpan(
          text: _formatValue(value),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: barColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: barAreaWidth);

      textPainter.paint(
        canvas,
        Offset(
          left + barWidth / 2 - textPainter.width / 2,
          top - textPainter.height - 2,
        ),
      );
    }
  }

  String _formatValue(int value) {
    if (value >= 1000000) {
      final m = value / 1000000;
      return '${m.toStringAsFixed(m % 1 == 0 ? 0 : 1)}M';
    }
    if (value >= 1000) {
      final k = value / 1000;
      return '${k.toStringAsFixed(k % 1 == 0 ? 0 : 1)}K';
    }
    return '$value';
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter old) =>
      old.data != data || old.barColor != barColor;
}
