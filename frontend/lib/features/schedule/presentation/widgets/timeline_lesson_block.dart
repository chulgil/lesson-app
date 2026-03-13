import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/instrument_colors.dart';
import '../../../../core/utils/name_utils.dart';
import '../../../../models/lesson.dart';

/// Height per 30-minute unit in timeline view.
const double kTimelineUnitHeight = 30.0;

/// A lesson block in the timeline view.
/// Height is proportional to lesson duration.
/// Uses left accent bar pattern (Google Calendar style).
class TimelineLessonBlock extends StatelessWidget {
  final Lesson lesson;
  final bool isNow;
  final bool isPast;
  final bool isNext;
  final bool isToday; // Whether viewing today's schedule
  final int minutesUntilNext;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const TimelineLessonBlock({
    super.key,
    required this.lesson,
    this.isNow = false,
    this.isPast = false,
    this.isNext = false,
    this.isToday = true,
    this.minutesUntilNext = 0,
    this.onTap,
    this.onLongPress,
  });

  double get blockHeight => (lesson.duration / 30.0) * kTimelineUnitHeight;

  @override
  Widget build(BuildContext context) {
    final baseColors = InstrumentColors.getColor(lesson.instrument);

    // Color logic:
    // - Today view: full instrument colors (past lessons slightly faded)
    // - Other dates: grey/muted (past/future days)
    final Color bgColor;
    final Color accentColor;

    if (!isToday) {
      // Non-today: grey muted
      bgColor = AppColors.scheduleMutedBackground;
      accentColor = AppColors.scheduleMutedAccent;
    } else if (isPast) {
      // Today, past: slightly faded instrument colors
      bgColor = baseColors.background.withValues(alpha: 0.5);
      accentColor = baseColors.accent.withValues(alpha: 0.4);
    } else {
      // Today, current/upcoming: full vivid colors
      bgColor = baseColors.background;
      accentColor = baseColors.accent;
    }
    final colors = InstrumentColorPair(bgColor, accentColor);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onLongPress?.call();
      },
      child: Container(
        height: blockHeight,
        margin: const EdgeInsets.symmetric(vertical: 1),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(8),
          border: isNow
              ? Border.all(color: baseColors.accent, width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            // Left accent bar
            _AccentBar(color: colors.accent, isNow: isNow),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
    );
  }

  /// Consistent 2-line layout:
  /// Line 1: 이름  악기  시간분
  /// Line 2: 곡명 (if available)
  Widget _buildContent(InstrumentColorPair colors) {
    final assignment = lesson.assignments?.isNotEmpty == true
        ? lesson.assignments!.first
        : lesson.pieces.isNotEmpty
            ? lesson.pieces.first.displayName
            : null;

    final bool compact = lesson.duration <= 30;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Line 1: given name · instrument · duration
        Text(
          '${NameUtils.givenName(lesson.studentName)}  ${lesson.instrument}  ${lesson.duration}분',
          style: AppTypography.caption.copyWith(
            color: colors.accent,
            fontWeight: FontWeight.w600,
            fontSize: compact ? 11 : 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // Line 2: piece/assignment (if available and space allows)
        if (assignment != null && !compact) ...[
          const SizedBox(height: 1),
          Text(
            assignment,
            style: AppTypography.caption.copyWith(
              color: colors.accent.withValues(alpha: 0.6),
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildPastBadge() {
    final isCompleted = lesson.displayStatus == LessonStatus.completed;
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
