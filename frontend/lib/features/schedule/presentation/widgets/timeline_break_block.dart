import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/name_utils.dart';
import 'timeline_lesson_block.dart';

/// Type of break between lessons
enum BreakBlockType {
  /// Global break time from teacher settings
  breakTime,

  /// Per-lesson travel time (set by teacher)
  travelTime,
}

/// A break/travel time block between lessons in the timeline view.
/// Visually distinct from lesson blocks — dashed border, muted color.
class TimelineBreakBlock extends StatelessWidget {
  final BreakBlockType type;
  final int durationMinutes;

  /// Previous lesson's student name (for context)
  final String? fromStudentName;

  /// Next lesson's student name (for context)
  final String? toStudentName;

  /// Previous lesson's location name
  final String? fromLocation;

  /// Next lesson's location name
  final String? toLocation;

  final VoidCallback? onTap;

  const TimelineBreakBlock({
    super.key,
    required this.type,
    required this.durationMinutes,
    this.fromStudentName,
    this.toStudentName,
    this.fromLocation,
    this.toLocation,
    this.onTap,
  });

  double get blockHeight =>
      ((durationMinutes / 30.0) * kTimelineUnitHeight).clamp(20.0, double.infinity);

  @override
  Widget build(BuildContext context) {
    final isTravelTime = type == BreakBlockType.travelTime;
    final bgColor = isTravelTime
        ? AppColors.scheduleTravelBackground
        : AppColors.scheduleBreakBackground;
    final borderColor = isTravelTime
        ? AppColors.scheduleTravelBorder
        : AppColors.scheduleBreakBorder;
    final iconColor = isTravelTime
        ? AppColors.scheduleTravelIcon
        : AppColors.scheduleBreakIcon;

    return GestureDetector(
      onTap: onTap != null
          ? () {
              HapticFeedback.lightImpact();
              onTap!.call();
            }
          : null,
      child: Container(
        height: blockHeight,
        margin: const EdgeInsets.symmetric(vertical: 1),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: borderColor,
            width: 1,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Icon(
              isTravelTime ? Icons.directions_car : Icons.coffee,
              size: 14,
              color: iconColor,
            ),
            const SizedBox(width: 6),
            Expanded(child: _buildContent(iconColor, isTravelTime)),
            // Edit hint
            Icon(
              Icons.edit_outlined,
              size: 12,
              color: iconColor.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Color textColor, bool isTravelTime) {
    final bool compact = durationMinutes <= 10;

    final label = isTravelTime
        ? '이동 ${durationMinutes}분'
        : '쉬는 시간 ${durationMinutes}분';

    if (compact) {
      return Text(
        label,
        style: AppTypography.caption.copyWith(
          color: textColor,
          fontSize: 10,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Show location info for travel time if available
    final locationInfo = isTravelTime && toLocation != null
        ? '→ ${toStudentName != null ? NameUtils.givenName(toStudentName!) : ''} ($toLocation)'
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: textColor,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (locationInfo != null) ...[
          const SizedBox(height: 1),
          Text(
            locationInfo,
            style: AppTypography.caption.copyWith(
              color: textColor.withValues(alpha: 0.6),
              fontSize: 9,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
