import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Week calendar widget with date selection - large card style design
class WeekCalendarWidget extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final Set<DateTime>? practicedDates; // Dates with practice records

  const WeekCalendarWidget({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.practicedDates,
  });

  @override
  State<WeekCalendarWidget> createState() => _WeekCalendarWidgetState();
}

class _WeekCalendarWidgetState extends State<WeekCalendarWidget> {
  late DateTime _currentWeekStart;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _currentWeekStart = _getWeekStart(widget.selectedDate);
  }

  @override
  void didUpdateWidget(WeekCalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _currentWeekStart = _getWeekStart(widget.selectedDate);
    }
  }

  DateTime _getWeekStart(DateTime date) {
    // Get Monday of the week (weekday: 1=Mon, 7=Sun)
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: weekday - 1));
  }

  DateTime _getMonthStart(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  void _previousWeek() {
    setState(() {
      if (_isExpanded) {
        // Go to previous month
        final prevMonth = DateTime(
          _currentWeekStart.year,
          _currentWeekStart.month - 1,
          1,
        );
        _currentWeekStart = _getWeekStart(prevMonth);
      } else {
        _currentWeekStart =
            _currentWeekStart.subtract(const Duration(days: 7));
      }
    });
  }

  void _nextWeek() {
    setState(() {
      if (_isExpanded) {
        // Go to next month
        final nextMonth = DateTime(
          _currentWeekStart.year,
          _currentWeekStart.month + 1,
          1,
        );
        _currentWeekStart = _getWeekStart(nextMonth);
      } else {
        _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
      }
    });
  }

  void _goToToday() {
    final today = DateTime.now();
    setState(() {
      _currentWeekStart = _getWeekStart(today);
    });
    widget.onDateSelected(DateTime(today.year, today.month, today.day));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _hasPractice(DateTime date) {
    if (widget.practicedDates == null) return false;
    return widget.practicedDates!.any((d) => _isSameDay(d, date));
  }

  String _getHeaderText() {
    final month = _currentWeekStart.month;
    final year = _currentWeekStart.year;
    return '$year년 $month월';
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with navigation
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space3,
              AppSpacing.space4,
              AppSpacing.space3,
              AppSpacing.space3,
            ),
            child: Row(
              children: [
                // Left navigation
                _buildNavButton(
                  icon: Icons.chevron_left,
                  onPressed: _previousWeek,
                ),

                // Center - Month/Year text
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getHeaderText(),
                          style: AppTypography.headingMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 24,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ],
                    ),
                  ),
                ),

                // Right - Today button & navigation
                _buildTodayButton(),
                const SizedBox(width: AppSpacing.space1),
                _buildNavButton(
                  icon: Icons.chevron_right,
                  onPressed: _nextWeek,
                ),
              ],
            ),
          ),

          // Calendar container with white background
          Container(
            margin: const EdgeInsets.fromLTRB(
              AppSpacing.space3,
              0,
              AppSpacing.space3,
              AppSpacing.space3,
            ),
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Column(
              children: [
                // Day headers
                Row(
                  children: ['월', '화', '수', '목', '금', '토', '일']
                      .map((day) => Expanded(
                            child: Center(
                              child: Text(
                                day,
                                style: AppTypography.bodySmall.copyWith(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),

                const SizedBox(height: AppSpacing.space3),

                // Calendar days
                _isExpanded
                    ? _buildMonthView(todayOnly)
                    : _buildWeekView(todayOnly),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        iconSize: 24,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
      ),
    );
  }

  Widget _buildTodayButton() {
    return GestureDetector(
      onTap: _goToToday,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '오늘',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildWeekView(DateTime today) {
    return Row(
      children: List.generate(7, (index) {
        final date = _currentWeekStart.add(Duration(days: index));
        return Expanded(
          child: _buildDayCell(date, today),
        );
      }),
    );
  }

  Widget _buildMonthView(DateTime today) {
    final monthStart = _getMonthStart(_currentWeekStart);
    final firstWeekday = monthStart.weekday; // 1=Mon, 7=Sun
    final daysInMonth =
        DateTime(monthStart.year, monthStart.month + 1, 0).day;

    // Calculate number of weeks needed
    final totalCells = firstWeekday - 1 + daysInMonth;
    final weeks = (totalCells / 7).ceil();

    return Column(
      children: List.generate(weeks, (weekIndex) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: List.generate(7, (dayIndex) {
              final cellIndex = weekIndex * 7 + dayIndex;
              final dayNumber = cellIndex - (firstWeekday - 1) + 1;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const Expanded(child: SizedBox(height: 52));
              }

              final date = DateTime(
                monthStart.year,
                monthStart.month,
                dayNumber,
              );
              return Expanded(
                child: _buildDayCell(date, today),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildDayCell(DateTime date, DateTime today) {
    final isSelected = _isSameDay(date, widget.selectedDate);
    final isToday = _isSameDay(date, today);
    final hasPractice = _hasPractice(date);
    final isFuture = date.isAfter(today);

    return GestureDetector(
      onTap: () {
        widget.onDateSelected(date);
      },
      child: Container(
        height: 52,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : isToday
                  ? Colors.white.withValues(alpha: 0.25)
                  : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: AppTypography.headingSmall.copyWith(
                color: isSelected
                    ? AppColors.primary
                    : isFuture
                        ? Colors.white.withValues(alpha: 0.4)
                        : Colors.white,
                fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            if (hasPractice)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.success
                      : Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
