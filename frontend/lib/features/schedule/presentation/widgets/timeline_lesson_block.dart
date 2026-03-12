import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/instrument_colors.dart';
import '../../../../models/lesson.dart';

/// Height per 30-minute unit in timeline view.
const double kTimelineUnitHeight = 60.0;

/// A lesson block in the timeline view.
/// Height is proportional to lesson duration.
/// Uses left accent bar pattern (Google Calendar style).
class TimelineLessonBlock extends StatelessWidget {
  final Lesson lesson;
  final bool isNow;
  final bool isPast;
  final bool isNext;
  final int minutesUntilNext;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const TimelineLessonBlock({
    super.key,
    required this.lesson,
    this.isNow = false,
    this.isPast = false,
    this.isNext = false,
    this.minutesUntilNext = 0,
    this.onTap,
    this.onLongPress,
  });

  double get blockHeight => (lesson.duration / 30.0) * kTimelineUnitHeight;

  @override
  Widget build(BuildContext context) {
    final colors = InstrumentColors.getColor(lesson.instrument);
    final opacity = isPast ? 0.5 : 1.0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onLongPress?.call();
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: opacity,
        child: Container(
          height: blockHeight,
          margin: const EdgeInsets.symmetric(vertical: 1),
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(8),
            border: isNow
                ? Border.all(color: colors.accent.withValues(alpha: 0.5), width: 1)
                : null,
          ),
          child: Row(
            children: [
              // Left accent bar
              _AccentBar(color: colors.accent, isNow: isNow),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: _buildContent(colors),
                ),
              ),
              // Badges
              if (isPast) _buildPastBadge(),
              if (isNext && minutesUntilNext > 0) _buildNextBadge(),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Progressive Disclosure: content density adapts to block height.
  Widget _buildContent(InstrumentColorPair colors) {
    if (lesson.duration <= 30) {
      // 1-line: name + instrument
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '${lesson.studentName} · ${lesson.instrument}',
          style: AppTypography.bodySmall.copyWith(
            color: colors.accent,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    if (lesson.duration <= 45) {
      // 2-line: name / instrument + duration
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            lesson.studentName,
            style: AppTypography.bodySmall.copyWith(
              color: colors.accent,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${lesson.instrument} · ${lesson.duration}분',
            style: AppTypography.caption.copyWith(
              color: colors.accent.withValues(alpha: 0.7),
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    // 3-line: name / instrument + duration / last assignment preview
    final assignment = lesson.assignments?.isNotEmpty == true
        ? lesson.assignments!.first
        : lesson.pieces.isNotEmpty
            ? lesson.pieces.first.displayName
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          lesson.studentName,
          style: AppTypography.bodySmall.copyWith(
            color: colors.accent,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '${lesson.instrument} · ${lesson.duration}분',
          style: AppTypography.caption.copyWith(
            color: colors.accent.withValues(alpha: 0.7),
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (assignment != null) ...[
          const SizedBox(height: 2),
          Text(
            assignment,
            style: AppTypography.caption.copyWith(
              color: colors.accent.withValues(alpha: 0.5),
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildPastBadge() {
    final isCompleted = lesson.status == LessonStatus.completed;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Icon(
        isCompleted ? Icons.check_circle : Icons.error_outline,
        size: 16,
        color: isCompleted
            ? AppColors.success.withValues(alpha: 0.7)
            : AppColors.warning.withValues(alpha: 0.7),
      ),
    );
  }

  Widget _buildNextBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${minutesUntilNext}분 후',
        style: AppTypography.caption.copyWith(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AccentBar extends StatelessWidget {
  final Color color;
  final bool isNow;

  const _AccentBar({required this.color, required this.isNow});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          bottomLeft: Radius.circular(8),
        ),
      ),
    );
  }
}
