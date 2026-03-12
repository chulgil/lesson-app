import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Compact week date strip matching the weekly grid's simple style.
/// Shows 7-day row with today highlight and lesson dot indicators.
class CompactWeekStrip extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final Set<DateTime>? lessonDates;

  const CompactWeekStrip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.lessonDates,
  });

  DateTime get _weekStart {
    final weekday = selectedDate.weekday;
    return DateTime(selectedDate.year, selectedDate.month, selectedDate.day)
        .subtract(Duration(days: weekday - 1));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _hasLesson(DateTime date) {
    if (lessonDates == null) return false;
    return lessonDates!.any((d) => _isSameDay(d, date));
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    const dayNames = ['월', '화', '수', '목', '금', '토', '일'];

    return Row(
      children: List.generate(7, (index) {
        final date = _weekStart.add(Duration(days: index));
        final isSelected = _isSameDay(date, selectedDate);
        final isToday = _isSameDay(date, todayOnly);
        final hasLesson = _hasLesson(date);

        return Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onDateSelected(date),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: isSelected
                  ? BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    )
                  : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Day name
                  Text(
                    dayNames[index],
                    style: AppTypography.caption.copyWith(
                      color: isToday
                          ? AppColors.primary
                          : AppColors.textTertiaryLight,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Date number with today circle
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: isToday
                        ? BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          )
                        : isSelected
                            ? BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              )
                            : null,
                    child: Text(
                      '${date.day}',
                      style: AppTypography.bodySmall.copyWith(
                        color: (isSelected || isToday)
                            ? (isSelected ? Colors.white : AppColors.primary)
                            : AppColors.textPrimaryLight,
                        fontWeight: (isToday || isSelected)
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  // Lesson indicator dot
                  const SizedBox(height: 3),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: hasLesson
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
