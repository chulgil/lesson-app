// Revenue pie chart — student breakdown by revenue portion.
// Spec: docs/specs/analytics/student_progress_dashboard_spec.md §6.2

import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/analytics_models.dart';

// ignore: widget-smoke-test
/// Pie chart showing student revenue breakdown.
///
/// Uses [AppColors.paperAccent], [AppColors.paperOk], [AppColors.paperTrial],
/// and [AppColors.inkTertiary] for slices.
class RevenuePieChart extends StatelessWidget {
  const RevenuePieChart({
    super.key,
    required this.breakdown,
    this.size = 120,
  });

  final List<StudentRevenuePortion> breakdown;
  final double size;

  static const _sliceColors = [
    AppColors.paperAccent,
    AppColors.paperOk,
    AppColors.paperTrial,
    AppColors.inkTertiary,
    AppColors.paperDark,
  ];

  @override
  Widget build(BuildContext context) {
    if (breakdown.isEmpty) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CustomPaint(
          size: Size(size, size),
          painter: _PiePainter(breakdown: breakdown, colors: _sliceColors),
        ),
        const SizedBox(width: AppSpacing.space4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: breakdown.take(5).toList().asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              final color = _sliceColors[i % _sliceColors.length];
              final percent = (item.percent * 100).toStringAsFixed(0);
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space1),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      color: color,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Expanded(
                      child: Text(
                        '${item.studentName} $percent%',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.ink,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _PiePainter extends CustomPainter {
  final List<StudentRevenuePortion> breakdown;
  final List<Color> colors;

  _PiePainter({required this.breakdown, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    if (breakdown.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -pi / 2; // start at top

    for (int i = 0; i < breakdown.length; i++) {
      final slice = breakdown[i];
      final sweepAngle = slice.percent * 2 * pi;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      // Thin white separator
      final separatorPaint = Paint()
        ..color = AppColors.paper
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawArc(rect, startAngle, sweepAngle, true, separatorPaint);

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _PiePainter old) =>
      old.breakdown != breakdown;
}
