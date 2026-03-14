import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Compact week date strip matching the weekly grid's simple style.
/// Shows 7-day row with today highlight, lesson dot indicators,
/// swipe gesture for week navigation, and "오늘" jump button.
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

  bool get _isCurrentWeek {
    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);
    final weekEnd = _weekStart.add(const Duration(days: 6));
    return !todayOnly.isBefore(_weekStart) && !todayOnly.isAfter(weekEnd);
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    const dayNames = ['월', '화', '수', '목', '금', '토', '일'];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Week header with navigation
        _buildWeekHeader(todayOnly),
        const SizedBox(height: 4),
        // Day strip with swipe
        GestureDetector(
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity.abs() < 100) return; // threshold
            if (velocity > 0) {
              // Swipe right → previous week
              onDateSelected(selectedDate.subtract(const Duration(days: 7)));
            } else {
              // Swipe left → next week
              onDateSelected(selectedDate.add(const Duration(days: 7)));
            }
          },
          child: Row(
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
          ),
        ),
      ],
    );
  }

  /// Week header: chevrons + month/week label + "오늘" button
  Widget _buildWeekHeader(DateTime todayOnly) {
    final weekEnd = _weekStart.add(const Duration(days: 6));
    final monthLabel = _weekStart.month == weekEnd.month
        ? '${_weekStart.month}월'
        : '${_weekStart.month}월~${weekEnd.month}월';
    final weekLabel = '$monthLabel ${_weekStart.day}~${weekEnd.day}일';

    return Row(
      children: [
        // Previous week button
        _NavChevron(
          icon: Icons.chevron_left,
          onTap: () => onDateSelected(
            selectedDate.subtract(const Duration(days: 7)),
          ),
        ),
        const SizedBox(width: 4),
        // Week label
        Text(
          weekLabel,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        // Next week button
        _NavChevron(
          icon: Icons.chevron_right,
          onTap: () => onDateSelected(
            selectedDate.add(const Duration(days: 7)),
          ),
        ),
        const Spacer(),
        // "오늘" jump button (only when not on current week)
        if (!_isCurrentWeek)
          GestureDetector(
            onTap: () => onDateSelected(todayOnly),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '오늘',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Small chevron button for week navigation
class _NavChevron extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavChevron({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 18,
          color: AppColors.textSecondaryLight,
        ),
      ),
    );
  }
}
