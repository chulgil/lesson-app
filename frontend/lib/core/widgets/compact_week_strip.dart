import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Compact week date strip — shared across teacher and student views.
///
/// Shows 7-day row with today highlight, marker dot indicators,
/// swipe gesture for week navigation, date picker on label tap,
/// and "오늘" jump button.
///
/// [markerDates] accepts any `Set<DateTime>` — lessons, practices,
/// requests, etc. Dots are shown for dates with markers.
class CompactWeekStrip extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  /// Dates to show dot indicators for (lessons, practices, etc.)
  final Set<DateTime>? markerDates;

  const CompactWeekStrip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.markerDates,
  });

  DateTime get _weekStart {
    final weekday = selectedDate.weekday;
    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    ).subtract(Duration(days: weekday - 1));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _hasMarker(DateTime date) {
    if (markerDates == null) return false;
    return markerDates!.any((d) => _isSameDay(d, date));
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
        _buildWeekHeader(context, todayOnly),
        const SizedBox(height: 4),
        // Day strip with swipe
        GestureDetector(
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity.abs() < 100) return;
            if (velocity > 0) {
              onDateSelected(selectedDate.subtract(const Duration(days: 7)));
            } else {
              onDateSelected(selectedDate.add(const Duration(days: 7)));
            }
          },
          child: Row(
            children: List.generate(7, (index) {
              final date = _weekStart.add(Duration(days: index));
              final isSelected = _isSameDay(date, selectedDate);
              final isToday = _isSameDay(date, todayOnly);
              final hasMarker = _hasMarker(date);

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onDateSelected(date),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration:
                        isSelected
                            ? BoxDecoration(
                              color: AppColors.paperAccent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMedium,
                              ),
                            )
                            : null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          dayNames[index],
                          style: AppTypography.caption.copyWith(
                            color:
                                isToday
                                    ? AppColors.paperAccent
                                    : AppColors.inkTertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration:
                              isToday
                                  ? BoxDecoration(
                                    color:
                                        isSelected
                                            ? AppColors.paperAccent
                                            : AppColors.paperAccent.withValues(
                                              alpha: 0.15,
                                            ),
                                    shape: BoxShape.circle,
                                  )
                                  : isSelected
                                  ? BoxDecoration(
                                    color: AppColors.paperAccent,
                                    shape: BoxShape.circle,
                                  )
                                  : null,
                          child: Text(
                            '${date.day}',
                            style: AppTypography.bodySmall.copyWith(
                              color:
                                  (isSelected || isToday)
                                      ? (isSelected
                                          ? Colors.white
                                          : AppColors.paperAccent)
                                      : AppColors.ink,
                              fontWeight:
                                  (isToday || isSelected)
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color:
                                hasMarker
                                    ? AppColors.paperAccent.withValues(alpha: 0.5)
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

  Widget _buildWeekHeader(BuildContext context, DateTime todayOnly) {
    final weekEnd = _weekStart.add(const Duration(days: 6));
    final monthLabel =
        _weekStart.month == weekEnd.month
            ? '${_weekStart.month}월'
            : '${_weekStart.month}월~${weekEnd.month}월';
    final weekLabel = '$monthLabel ${_weekStart.day}~${weekEnd.day}일';

    return Row(
      children: [
        _NavChevron(
          icon: Icons.chevron_left,
          onTap:
              () => onDateSelected(
                selectedDate.subtract(const Duration(days: 7)),
              ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2024),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              onDateSelected(picked);
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                weekLabel,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.calendar_month,
                size: 14,
                color: AppColors.inkTertiary,
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        _NavChevron(
          icon: Icons.chevron_right,
          onTap:
              () => onDateSelected(selectedDate.add(const Duration(days: 7))),
        ),
        const Spacer(),
        if (!_isCurrentWeek)
          GestureDetector(
            onTap: () => onDateSelected(todayOnly),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.paperAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              ),
              child: Text(
                '오늘',
                style: AppTypography.caption.copyWith(
                  color: AppColors.paperAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

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
        child: Icon(icon, size: 18, color: AppColors.inkSecondary),
      ),
    );
  }
}
