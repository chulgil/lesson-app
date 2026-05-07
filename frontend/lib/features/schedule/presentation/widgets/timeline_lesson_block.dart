import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/instrument_colors.dart';
import '../../../../core/utils/name_utils.dart';
import '../../../../features/lessons/domain/entities/lesson.dart';
import '../../../../features/lessons/presentation/extensions/lesson_visuals.dart';

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
  final bool isFuture; // Whether viewing a future date (not today)
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
    this.isFuture = false,
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

    if (!isToday && isFuture) {
      // Future date: visibly lightened instrument colors
      bgColor = Color.lerp(baseColors.background, AppColors.paper, 0.5)!;
      accentColor = baseColors.accent.withValues(alpha: 0.45);
    } else if (!isToday) {
      // Past date: grey muted
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
      // Notebook × Score: 둥근 모서리 제거 + 하단 1px 잉크 라인으로 블록 구분
      // (§7.112 주간 스케쥴 — 악보 템포 마디선 은유)
      child: Container(
        height: blockHeight,
        margin: const EdgeInsets.symmetric(vertical: 1),
        decoration: BoxDecoration(
          color: colors.background,
          border: Border(
            left: BorderSide(
              color: isNow ? baseColors.accent : Colors.transparent,
              width: isNow ? 1.5 : 0,
            ),
            top:
                isNow
                    ? BorderSide(color: baseColors.accent, width: 1.5)
                    : BorderSide.none,
            right:
                isNow
                    ? BorderSide(color: baseColors.accent, width: 1.5)
                    : BorderSide.none,
            bottom: BorderSide(
              color: isNow ? baseColors.accent : AppColors.inkQuaternary,
              width: isNow ? 1.5 : 0.5,
            ),
          ),
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
            const SizedBox(width: AppSpacing.space2),
          ],
        ),
      ),
    );
  }

  /// Consistent 2-line layout:
  /// Line 1: 이름  악기  시간분
  /// Line 2: 곡명 (if available)
  Widget _buildContent(InstrumentColorPair colors) {
    final assignment =
        lesson.assignments?.isNotEmpty == true
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
          style: (compact ? AppTypography.caption : AppTypography.bodySmall)
              .copyWith(color: colors.accent, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // Line 2: piece/assignment (if available and space allows)
        if (assignment != null && !compact) ...[
          const SizedBox(height: 1),
          Text(
            assignment,
            style: AppTypography.captionSmall.copyWith(
              color: colors.accent.withValues(alpha: 0.6),
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
      padding: const EdgeInsets.only(right: AppSpacing.space1),
      child: Icon(
        isCompleted ? Icons.check_circle : Icons.error_outline,
        size: 16,
        color:
            isCompleted
                ? AppColors.paperOk.withValues(alpha: 0.7)
                : AppColors.paperAccent.withValues(alpha: 0.7),
      ),
    );
  }

  Widget _buildNextBadge() {
    // Notebook × Score: 둥근 뱃지 → 평문 + 언더라인 (악보 temp 마커)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
      child: Text(
        '$minutesUntilNext분 후',
        style: AppTypography.captionSmall.copyWith(
          color: AppColors.paperAccent,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.paperAccent,
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
    // Notebook × Score: 둥근 accent bar → 직사각 3px 세로선 (§3 3px 규칙)
    return Container(width: 3, color: color);
  }
}
