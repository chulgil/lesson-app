import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import 'timeline_lesson_block.dart' show kTimelineUnitHeight;

/// An availability (open slot) block in the timeline view.
/// Dashed border, light background, tappable.
class TimelineAvailabilityBlock extends StatelessWidget {
  final int durationMinutes;
  final VoidCallback? onTap;

  const TimelineAvailabilityBlock({
    super.key,
    required this.durationMinutes,
    this.onTap,
  });

  double get blockHeight => (durationMinutes / 30.0) * kTimelineUnitHeight;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: blockHeight,
        margin: const EdgeInsets.symmetric(vertical: 1),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 1,
            // Dashed border is simulated via CustomPaint or just solid thin
            // Using solid thin for simplicity — dashed is hard in Flutter without CustomPainter
          ),
        ),
        child: Center(
          child: Text(
            '가용',
            style: AppTypography.caption.copyWith(
              color: const Color(0xFFBDBDBD),
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
