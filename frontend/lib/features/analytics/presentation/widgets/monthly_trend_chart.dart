// Custom monthly trend line chart using Canvas.

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../domain/entities/teacher_stats.dart';

/// Monthly trend chart showing 6-month lesson count trend.
class MonthlyTrendChart extends StatelessWidget {
  final List<MonthlyTrend> trendData;

  const MonthlyTrendChart({super.key, required this.trendData});

  @override
  Widget build(BuildContext context) {
    if (trendData.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Notebook × Score: 차트 카드 섹션 헤더도 Playfair sectionTitle 로 통일.
        Text('레슨 추이', style: NotebookTypography.sectionTitle),
        const SizedBox(height: AppSpacing.space3),
        Container(
          height: 180,
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.inkQuaternary),
          ),
          child: CustomPaint(
            size: const Size(double.infinity, 120),
            painter: _TrendChartPainter(
              data: trendData,
              lineColor: AppColors.paperAccent,
              fillColor: AppColors.paperAccent.withValues(alpha: 0.1),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        // Month labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:
                trendData.map((t) {
                  return Text(
                    '${t.month.month}월',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.inkTertiary,
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<MonthlyTrend> data;
  final Color lineColor;
  final Color fillColor;

  _TrendChartPainter({
    required this.data,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxValue = data
        .map((d) => d.lessonCount)
        .reduce((a, b) => a > b ? a : b);
    final minValue = data
        .map((d) => d.lessonCount)
        .reduce((a, b) => a < b ? a : b);
    final range = (maxValue - minValue).clamp(1, double.infinity);

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y =
          size.height -
          ((data[i].lessonCount - minValue) / range) * size.height * 0.8 -
          size.height * 0.1;
      points.add(Offset(x, y));
    }

    // Fill area
    final fillPath =
        Path()
          ..moveTo(points.first.dx, size.height)
          ..lineTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final cpX = (prev.dx + curr.dx) / 2;
      fillPath.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
    }
    fillPath
      ..lineTo(points.last.dx, size.height)
      ..close();

    canvas.drawPath(fillPath, Paint()..color = fillColor);

    // Line
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final cpX = (prev.dx + curr.dx) / 2;
      linePath.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Dots
    for (final point in points) {
      canvas.drawCircle(point, 4, Paint()..color = lineColor);
      canvas.drawCircle(point, 2.5, Paint()..color = Colors.white);
    }

    // Value labels
    for (int i = 0; i < points.length; i++) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${data[i].lessonCount}',
          style: AppTypography.captionSmall.copyWith(
            color: lineColor,
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
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
