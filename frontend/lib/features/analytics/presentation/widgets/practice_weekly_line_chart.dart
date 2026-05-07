// Practice weekly time line chart using CustomPaint.
// Spec: docs/specs/analytics/student_progress_dashboard_spec.md §6.2

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/analytics_models.dart';

// ignore: widget-smoke-test
/// Weekly practice time line chart showing minutes per week over a period.
class PracticeWeeklyLineChart extends StatelessWidget {
  const PracticeWeeklyLineChart({
    super.key,
    required this.data,
    this.height = 140,
  });

  final List<WeeklyPracticePoint> data;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            AppStrings.analyticsNoPracticeData,
            style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          child: CustomPaint(
            painter: _LineChartPainter(data: data),
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        // Week labels (show every other week if many)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: data.asMap().entries.map((e) {
              final show = data.length <= 6 || e.key % 2 == 0;
              return Expanded(
                child: Text(
                  show ? 'W${e.key + 1}' : '',
                  textAlign: TextAlign.center,
                  style: AppTypography.captionSmall.copyWith(
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

class _LineChartPainter extends CustomPainter {
  final List<WeeklyPracticePoint> data;

  _LineChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const topPad = 20.0;
    const bottomPad = 4.0;
    final chartH = size.height - topPad - bottomPad;

    final maxMin = data.map((d) => d.totalMinutes).reduce((a, b) => a > b ? a : b);
    if (maxMin == 0) return;

    // Grid lines
    final gridPaint = Paint()
      ..color = AppColors.inkQuaternary
      ..strokeWidth = 0.5;
    for (final frac in [0.25, 0.5, 0.75]) {
      final y = topPad + chartH * (1 - frac);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = data.length == 1
          ? size.width / 2
          : (i / (data.length - 1)) * size.width;
      final y = topPad + chartH - (data[i].totalMinutes / maxMin) * chartH * 0.9;
      points.add(Offset(x, y));
    }

    // Fill area
    final fillPath = Path()
      ..moveTo(points.first.dx, topPad + chartH)
      ..lineTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final p = points[i - 1];
      final c = points[i];
      final cpX = (p.dx + c.dx) / 2;
      fillPath.cubicTo(cpX, p.dy, cpX, c.dy, c.dx, c.dy);
    }
    fillPath
      ..lineTo(points.last.dx, topPad + chartH)
      ..close();

    canvas.drawPath(fillPath, Paint()..color = AppColors.paperAccentSoft);

    // Line
    final linePaint = Paint()
      ..color = AppColors.paperAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final p = points[i - 1];
      final c = points[i];
      final cpX = (p.dx + c.dx) / 2;
      linePath.cubicTo(cpX, p.dy, cpX, c.dy, c.dx, c.dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Dots + minute labels
    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 4, Paint()..color = AppColors.paperAccent);
      canvas.drawCircle(points[i], 2.5, Paint()..color = AppColors.paper);

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${data[i].totalMinutes}m',
          style: AppTypography.captionSmall.copyWith(
            color: AppColors.paperAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(points[i].dx - textPainter.width / 2, points[i].dy - 18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) => old.data != data;
}
