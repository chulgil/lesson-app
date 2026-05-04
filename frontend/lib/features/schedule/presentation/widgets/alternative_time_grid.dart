import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/booking/entities/time_slot.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';

import '../../../../core/utils/name_utils.dart';
import '../../../lessons/domain/entities/lesson.dart';

/// Weekly grid for selecting alternative time slots.
///
/// Shows existing lessons as colored cells and allows tapping
/// empty cells to suggest alternative times.
class AlternativeTimeGrid extends StatefulWidget {
  final DateTime weekStart;
  final List<Lesson> lessons;
  final List<TimeSlot> suggestedSlots;
  final int maxSlots;
  final ValueChanged<({DateTime date, int hour, int minute})> onEmptyCellTap;

  /// When true, hides student names in lesson cells (student view privacy).
  final bool hideStudentNames;

  /// Selected student's preferred slot to highlight on the grid.
  /// Shows where the selected time falls on the weekly schedule.
  final PreferredTimeSlotHighlight? highlightedSlot;

  const AlternativeTimeGrid({
    super.key,
    required this.weekStart,
    required this.lessons,
    required this.suggestedSlots,
    this.maxSlots = 3,
    required this.onEmptyCellTap,
    this.hideStudentNames = false,
    this.highlightedSlot,
  });

  @override
  State<AlternativeTimeGrid> createState() => _AlternativeTimeGridState();
}

class _AlternativeTimeGridState extends State<AlternativeTimeGrid> {
  final ScrollController _scrollController = ScrollController();
  PreferredTimeSlotHighlight? _lastScrolledSlot;

  // Delegate properties for cleaner access
  DateTime get weekStart => widget.weekStart;
  List<Lesson> get lessons => widget.lessons;
  List<TimeSlot> get suggestedSlots => widget.suggestedSlots;
  int get maxSlots => widget.maxSlots;
  ValueChanged<({DateTime date, int hour, int minute})> get onEmptyCellTap =>
      widget.onEmptyCellTap;
  bool get hideStudentNames => widget.hideStudentNames;
  PreferredTimeSlotHighlight? get highlightedSlot => widget.highlightedSlot;

  @override
  void initState() {
    super.initState();
    // Initial scroll to highlighted slot
    if (widget.highlightedSlot != null) {
      _scrollToHighlightedSlot();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AlternativeTimeGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-scroll when highlighted slot changes
    if (widget.highlightedSlot != oldWidget.highlightedSlot &&
        widget.highlightedSlot != null &&
        widget.highlightedSlot != _lastScrolledSlot) {
      _scrollToHighlightedSlot();
    }
  }

  void _scrollToHighlightedSlot() {
    final h = highlightedSlot;
    if (h == null) return;
    _lastScrolledSlot = h;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final startHour = _computeStartHour();
      const cellHeight = 28.0;
      final targetOffset =
          (h.startMinutes - startHour * 60) / 30 * cellHeight - 2 * cellHeight;
      final clampedOffset = targetOffset.clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  int _computeStartHour() {
    int startHour = 9;
    if (lessons.isNotEmpty) {
      final minHour = lessons
          .map((l) => int.parse(l.startTime.split(':')[0]))
          .reduce((a, b) => a < b ? a : b);
      startHour = minHour < startHour ? minHour : startHour;
    }
    return startHour;
  }

  int _parseTimeMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  int _lessonEndMinutes(Lesson lesson) =>
      _parseTimeMinutes(lesson.startTime) + lesson.duration;

  double get _gridLabelFontSize =>
      (AppTypography.captionXSmall.fontSize ?? 10) * 2;

  Border _cellBorder({
    Color? color,
    bool includeTop = false,
    bool includeLeft = false,
  }) {
    final side = BorderSide(
      color: color ?? AppColors.inkQuaternary.withValues(alpha: 0.3),
      width: 1,
    );
    return Border(
      top: includeTop ? side : BorderSide.none,
      left: includeLeft ? side : BorderSide.none,
      right: side,
      bottom: side,
    );
  }

  Widget _buildCenteredGridLabel(
    String label, {
    required TextStyle style,
    double verticalOffset = 0,
  }) {
    return Center(
      child: Transform.translate(
        offset: Offset(0, verticalOffset),
        child: Text(
          label,
          style: style.copyWith(fontSize: _gridLabelFontSize, height: 1),
          strutStyle: StrutStyle(
            fontSize: _gridLabelFontSize,
            height: 1,
            forceStrutHeight: true,
          ),
          textHeightBehavior: const TextHeightBehavior(
            applyHeightToFirstAscent: false,
            applyHeightToLastDescent: false,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int startHour = 9;
    int endHour = 21;
    if (lessons.isNotEmpty) {
      final minHour = lessons
          .map((l) => int.parse(l.startTime.split(':')[0]))
          .reduce((a, b) => a < b ? a : b);
      final maxHour = lessons
          .map((l) {
            final end = _lessonEndMinutes(l);
            return end ~/ 60 + (end % 60 > 0 ? 1 : 0);
          })
          .reduce((a, b) => a > b ? a : b);
      startHour = minHour < startHour ? minHour : startHour;
      endHour = maxHour > endHour ? maxHour : endHour;
    }

    const dayLabels = ['월', '화', '수', '목', '금', '토', '일'];
    const cellHeight = 28.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth = (constraints.maxWidth - 36) / 7;

          return Column(
            children: [
              // Day headers (fixed, not scrollable)
              Row(
                children: [
                  const SizedBox(width: 36),
                  ...List.generate(7, (i) {
                    final date = weekStart.add(Duration(days: i));
                    final isToday = _isToday(date);
                    return SizedBox(
                      width: cellWidth,
                      child: Column(
                        children: [
                          Text(
                            dayLabels[i],
                            style: AppTypography.caption.copyWith(
                              color:
                                  isToday
                                      ? AppColors.paperAccent
                                      : AppColors.inkSecondary,
                              fontWeight: isToday ? FontWeight.bold : null,
                            ),
                          ),
                          Text(
                            '${date.day}',
                            style: AppTypography.caption.copyWith(
                              color:
                                  isToday
                                      ? AppColors.paperAccent
                                      : AppColors.inkTertiary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: AppSpacing.space1),

              // Grid body (scrollable, auto-scrolls to highlighted slot)
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: List.generate((endHour - startHour) * 2, (
                      slotIndex,
                    ) {
                      final slotMinutes = startHour * 60 + slotIndex * 30;
                      final hour = slotMinutes ~/ 60;
                      final minute = slotMinutes % 60;
                      final isHourBoundary = minute == 0;

                      return Row(
                        children: [
                          SizedBox(
                            width: 36,
                            height: cellHeight,
                            child:
                                isHourBoundary
                                    ? Text(
                                      '$hour:00',
                                      style: AppTypography.captionSmall
                                          .copyWith(
                                            color: AppColors.inkTertiary,
                                          ),
                                    )
                                    : const SizedBox.shrink(),
                          ),
                          ...List.generate(7, (dayIndex) {
                            final date = weekStart.add(
                              Duration(days: dayIndex),
                            );
                            return _buildCell(
                              date: date,
                              slotMinutes: slotMinutes,
                              width: cellWidth,
                              height: cellHeight,
                              includeTopBoundary: slotIndex == 0,
                              includeLeftBoundary: dayIndex == 0,
                            );
                          }),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCell({
    required DateTime date,
    required int slotMinutes,
    required double width,
    required double height,
    required bool includeTopBoundary,
    required bool includeLeftBoundary,
  }) {
    final hour = slotMinutes ~/ 60;
    final minute = slotMinutes % 60;

    // Check if this cell has a lesson
    final lesson = _findLessonAt(date, slotMinutes);
    if (lesson != null) {
      final lessonStartMinutes = _parseTimeMinutes(lesson.startTime);
      final isStart = lessonStartMinutes == slotMinutes;
      final isPreview = lesson.isPreview;

      // Check if this lesson cell overlaps with the highlighted preferred slot
      final isOverlapWithHighlight = _isHighlightedSlot(date, slotMinutes);
      final isHighlightStart = _isHighlightedSlotStart(date, slotMinutes);
      final shouldShowLabel = isStart || isHighlightStart;

      // Warning color for preview + highlight overlap
      final Color bgColor;
      final Color accentColor;
      final Color textColor;

      if (isOverlapWithHighlight) {
        bgColor = AppColors.paperAccentSoft;
        accentColor = AppColors.paperAccent;
        textColor = AppColors.paperAccent;
      } else if (isPreview) {
        bgColor = AppColors.scheduleMutedBackground.withValues(alpha: 0.4);
        accentColor = AppColors.scheduleMutedAccent;
        textColor = AppColors.inkTertiary;
      } else {
        bgColor = AppColors.scheduleMutedBackground;
        accentColor = AppColors.inkTertiary;
        textColor = AppColors.inkSecondary;
      }

      return CustomPaint(
        painter:
            (isPreview || isOverlapWithHighlight) && isStart
                ? _DashedTopBorderPainter(color: accentColor, width: 2)
                : null,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: bgColor,
            border:
                !isPreview && !isOverlapWithHighlight
                    ? Border(
                      top:
                          isStart
                              ? BorderSide(color: accentColor, width: 1)
                              : BorderSide.none,
                    )
                    : null,
          ),
          child:
              shouldShowLabel
                  ? _buildCenteredGridLabel(
                    isHighlightStart
                        ? AppStrings.preferredSlotLabel
                        : hideStudentNames
                        ? AppStrings.lessonPrivateLabel
                        : NameUtils.givenName(lesson.studentName),
                    style:
                        isHighlightStart
                            ? AppTypography.captionXSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.paperAccent,
                            )
                            : NotebookTypography.hand.copyWith(
                              fontWeight:
                                  isOverlapWithHighlight
                                      ? FontWeight.w700
                                      : isPreview
                                      ? FontWeight.w400
                                      : FontWeight.w700,
                              color: textColor,
                            ),
                    verticalOffset: isHighlightStart ? 0 : 1,
                  )
                  : null,
        ),
      );
    }

    // Check if this cell is the highlighted student slot
    if (_isHighlightedSlot(date, slotMinutes)) {
      final isStart = _isHighlightedSlotStart(date, slotMinutes);
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.paperOk.withValues(alpha: 0.15),
          border: _cellBorder(
            color: AppColors.paperOk.withValues(alpha: 0.45),
            includeTop: includeTopBoundary || isStart,
            includeLeft: includeLeftBoundary,
          ),
        ),
        child:
            isStart
                ? _buildCenteredGridLabel(
                  AppStrings.preferredSlotLabel,
                  style: AppTypography.captionXSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.paperOk,
                  ),
                )
                : null,
      );
    }

    // Check if this cell is a suggested slot
    final suggestedIndex = _findSuggestedSlotAt(date, slotMinutes);
    if (suggestedIndex >= 0) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.paperAccentSoft,
          border: _cellBorder(
            color: AppColors.paperAccent,
            includeTop: includeTopBoundary,
            includeLeft: includeLeftBoundary,
          ),
        ),
        child: Center(
          child: Text(
            ['❶', '❷', '❸'][suggestedIndex.clamp(0, 2)],
            style: AppTypography.captionSmall.copyWith(
              color: AppColors.paperAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // Empty cell — tappable (past cells disabled)
    final cellDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
    final isPast = cellDateTime.isBefore(DateTime.now());

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap:
          !isPast && suggestedSlots.length < maxSlots
              ? () {
                HapticFeedback.lightImpact();
                onEmptyCellTap((date: date, hour: hour, minute: minute));
              }
              : null,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color:
              isPast ? AppColors.inkQuaternary.withValues(alpha: 0.15) : null,
          border: _cellBorder(
            includeTop: includeTopBoundary,
            includeLeft: includeLeftBoundary,
          ),
        ),
      ),
    );
  }

  Lesson? _findLessonAt(DateTime date, int cellMinutes) {
    for (final lesson in lessons) {
      if (lesson.date.year == date.year &&
          lesson.date.month == date.month &&
          lesson.date.day == date.day) {
        final lessonStart = _parseTimeMinutes(lesson.startTime);
        final lessonEnd = _lessonEndMinutes(lesson);
        if (cellMinutes >= lessonStart && cellMinutes < lessonEnd) {
          return lesson;
        }
      }
    }
    return null;
  }

  int _findSuggestedSlotAt(DateTime date, int cellMinutes) {
    for (int i = 0; i < suggestedSlots.length; i++) {
      final slot = suggestedSlots[i];
      if (slot.specificDate != null &&
          slot.specificDate!.year == date.year &&
          slot.specificDate!.month == date.month &&
          slot.specificDate!.day == date.day) {
        final slotStart = slot.startTime.hour * 60 + slot.startTime.minute;
        final slotEnd = slot.endTime.hour * 60 + slot.endTime.minute;
        if (cellMinutes >= slotStart && cellMinutes < slotEnd) {
          return i;
        }
      }
    }
    return -1;
  }

  bool _isHighlightedSlot(DateTime date, int cellMinutes) {
    final h = highlightedSlot;
    if (h == null) return false;
    if (h.date.year != date.year ||
        h.date.month != date.month ||
        h.date.day != date.day) {
      return false;
    }
    return cellMinutes >= h.startMinutes && cellMinutes < h.endMinutes;
  }

  bool _isHighlightedSlotStart(DateTime date, int cellMinutes) {
    final h = highlightedSlot;
    if (h == null) return false;
    if (h.date.year != date.year ||
        h.date.month != date.month ||
        h.date.day != date.day) {
      return false;
    }
    return cellMinutes == h.startMinutes;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

/// Data class for highlighting a student's preferred slot on the grid.
class PreferredTimeSlotHighlight {
  final DateTime date;
  final int startMinutes;
  final int endMinutes;

  const PreferredTimeSlotHighlight({
    required this.date,
    required this.startMinutes,
    required this.endMinutes,
  });
}

/// Dashed top border painter for preview lessons.
class _DashedTopBorderPainter extends CustomPainter {
  final Color color;
  final double width;

  _DashedTopBorderPainter({required this.color, required this.width});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = width
          ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashGap = 3.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, width / 2),
        Offset((startX + dashWidth).clamp(0, size.width), width / 2),
        paint,
      );
      startX += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
