import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/booking/entities/time_slot.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/instrument_colors.dart';
import '../../../../core/utils/name_utils.dart';
import '../../../lessons/domain/entities/lesson.dart';

/// Weekly grid for selecting alternative time slots.
///
/// Shows existing lessons as colored cells and allows tapping
/// empty cells to suggest alternative times.
class AlternativeTimeGrid extends StatelessWidget {
  final DateTime weekStart;
  final List<Lesson> lessons;
  final List<TimeSlot> suggestedSlots;
  final int maxSlots;
  final ValueChanged<({DateTime date, int hour, int minute})> onEmptyCellTap;

  /// When true, hides student names in lesson cells (student view privacy).
  final bool hideStudentNames;

  const AlternativeTimeGrid({
    super.key,
    required this.weekStart,
    required this.lessons,
    required this.suggestedSlots,
    this.maxSlots = 3,
    required this.onEmptyCellTap,
    this.hideStudentNames = false,
  });

  int _parseTimeMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  int _lessonEndMinutes(Lesson lesson) =>
      _parseTimeMinutes(lesson.startTime) + lesson.duration;

  @override
  Widget build(BuildContext context) {
    int startHour = 9;
    int endHour = 21;
    if (lessons.isNotEmpty) {
      final minHour = lessons
          .map((l) => int.parse(l.startTime.split(':')[0]))
          .reduce((a, b) => a < b ? a : b);
      final maxHour = lessons.map((l) {
        final end = _lessonEndMinutes(l);
        return end ~/ 60 + (end % 60 > 0 ? 1 : 0);
      }).reduce((a, b) => a > b ? a : b);
      startHour = minHour < startHour ? minHour : startHour;
      endHour = maxHour > endHour ? maxHour : endHour;
    }

    const dayLabels = ['월', '화', '수', '목', '금', '토', '일'];
    const cellHeight = 28.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth = (constraints.maxWidth - 36) / 7;

          return Column(
            children: [
              // Day headers
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
                              color: isToday
                                  ? AppColors.primary
                                  : AppColors.textSecondaryLight,
                              fontWeight: isToday ? FontWeight.bold : null,
                            ),
                          ),
                          Text(
                            '${date.day}',
                            style: AppTypography.caption.copyWith(
                              color: isToday
                                  ? AppColors.primary
                                  : AppColors.textTertiaryLight,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 4),

              // Grid body
              ...List.generate(
                (endHour - startHour) * 2,
                (slotIndex) {
                  final slotMinutes = startHour * 60 + slotIndex * 30;
                  final hour = slotMinutes ~/ 60;
                  final minute = slotMinutes % 60;
                  final isHourBoundary = minute == 0;

                  return Row(
                    children: [
                      SizedBox(
                        width: 36,
                        height: cellHeight,
                        child: isHourBoundary
                            ? Text(
                                '$hour:00',
                                style: AppTypography.caption.copyWith(
                                  fontSize: 10,
                                  color: AppColors.textTertiaryLight,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      ...List.generate(7, (dayIndex) {
                        final date =
                            weekStart.add(Duration(days: dayIndex));
                        return _buildCell(
                          date: date,
                          slotMinutes: slotMinutes,
                          width: cellWidth,
                          height: cellHeight,
                        );
                      }),
                    ],
                  );
                },
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
  }) {
    final hour = slotMinutes ~/ 60;
    final minute = slotMinutes % 60;

    // Check if this cell has a lesson
    final lesson = _findLessonAt(date, slotMinutes);
    if (lesson != null) {
      final lessonStartMinutes = _parseTimeMinutes(lesson.startTime);
      final isStart = lessonStartMinutes == slotMinutes;
      final baseColors = InstrumentColors.getColor(lesson.instrument);
      final colors = lesson.isPreview
          ? InstrumentColorPair(
              baseColors.background.withValues(alpha: 0.15),
              baseColors.accent.withValues(alpha: 0.25),
            )
          : baseColors;
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colors.background,
          border: Border(
            top: isStart
                ? BorderSide(
                    color: colors.accent,
                    width: lesson.isPreview ? 2.5 : 2,
                  )
                : BorderSide.none,
          ),
        ),
        child: isStart
            ? Padding(
                padding: const EdgeInsets.only(left: 2, top: 1),
                child: Text(
                  hideStudentNames ? '레슨' : NameUtils.givenName(lesson.studentName),
                  style: AppTypography.caption.copyWith(
                    fontSize: 9,
                    fontWeight:
                        lesson.isPreview ? FontWeight.w400 : FontWeight.w600,
                    color: lesson.isPreview ? colors.accent : null,
                  ),
                  overflow: TextOverflow.clip,
                  maxLines: 1,
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
          color: AppColors.primary.withValues(alpha: 0.2),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        child: Center(
          child: Text(
            ['❶', '❷', '❸'][suggestedIndex.clamp(0, 2)],
            style: AppTypography.caption.copyWith(
              fontSize: 10,
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // Empty cell — tappable (past cells disabled)
    final cellDateTime = DateTime(date.year, date.month, date.day, hour, minute);
    final isPast = cellDateTime.isBefore(DateTime.now());

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: !isPast && suggestedSlots.length < maxSlots
          ? () {
              HapticFeedback.lightImpact();
              onEmptyCellTap((date: date, hour: hour, minute: minute));
            }
          : null,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isPast ? AppColors.scheduleMutedBackground : null,
          border: Border.all(
            color: AppColors.borderLight.withValues(alpha: 0.3),
            width: 0.5,
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

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
