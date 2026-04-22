import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/entities/entities.dart';

/// Line chart showing weekly practice trend (for monthly reports)
class WeeklyTrendChart extends StatelessWidget {
  final List<WeeklyStats> weeklyStats;
  final double height;

  const WeeklyTrendChart({
    super.key,
    required this.weeklyStats,
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    if (weeklyStats.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate max value for scaling
    final maxMinutes = weeklyStats
        .map((s) => s.practiceMinutes)
        .reduce((a, b) => a > b ? a : b);
    final chartMax = (maxMinutes * 1.2).clamp(60, 1200).toInt();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: AppColors.paperAccent,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '주간 트렌드',
                style: AppTypography.headingSmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),

          SizedBox(
            height: height,
            child: CustomPaint(
              painter: _TrendLinePainter(
                weeklyStats: weeklyStats,
                maxMinutes: chartMax,
              ),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),

          // Week labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weeklyStats.map((stat) {
              return Text(
                stat.weekLabel,
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkSecondary,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TrendLinePainter extends CustomPainter {
  final List<WeeklyStats> weeklyStats;
  final int maxMinutes;

  _TrendLinePainter({
    required this.weeklyStats,
    required this.maxMinutes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (weeklyStats.isEmpty) return;

    final paint = Paint()
      ..color = AppColors.paperAccent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.paperAccent.withAlpha(50),
          AppColors.paperAccent.withAlpha(0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final dotPaint = Paint()
      ..color = AppColors.paperAccent
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();
    final points = <Offset>[];

    // Calculate points
    for (int i = 0; i < weeklyStats.length; i++) {
      final stat = weeklyStats[i];
      final x = size.width * i / (weeklyStats.length - 1);
      final y = size.height * (1 - stat.practiceMinutes / maxMinutes);
      points.add(Offset(x, y));
    }

    // Draw line
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      fillPath.moveTo(points.first.dx, size.height);
      fillPath.lineTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length; i++) {
        // Use quadratic bezier for smooth curves
        final p0 = points[i - 1];
        final p1 = points[i];
        final controlX = (p0.dx + p1.dx) / 2;

        path.quadraticBezierTo(controlX, p0.dy, controlX, (p0.dy + p1.dy) / 2);
        path.quadraticBezierTo(controlX, p1.dy, p1.dx, p1.dy);

        fillPath.quadraticBezierTo(
            controlX, p0.dy, controlX, (p0.dy + p1.dy) / 2);
        fillPath.quadraticBezierTo(controlX, p1.dy, p1.dx, p1.dy);
      }

      fillPath.lineTo(points.last.dx, size.height);
      fillPath.close();

      // Draw fill
      canvas.drawPath(fillPath, fillPaint);

      // Draw line
      canvas.drawPath(path, paint);

      // Draw dots
      for (final point in points) {
        canvas.drawCircle(point, 6, dotPaint);
        canvas.drawCircle(
          point,
          4,
          Paint()..color = Colors.white,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_TrendLinePainter oldDelegate) {
    return oldDelegate.weeklyStats != weeklyStats ||
        oldDelegate.maxMinutes != maxMinutes;
  }
}
