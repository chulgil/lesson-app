import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Collapsible calendar widget with month/week toggle
/// Expands/collapses based on external scroll notification
/// Designed with classical music aesthetic
class CollapsibleCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final bool isExpanded;
  final Set<DateTime>? markedDates; // Dates with lessons or practice
  final VoidCallback? onToggleExpand; // Callback when header is tapped to toggle

  const CollapsibleCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.isExpanded = true, // Default to month view
    this.markedDates,
    this.onToggleExpand,
  });

  @override
  State<CollapsibleCalendar> createState() => _CollapsibleCalendarState();
}

class _CollapsibleCalendarState extends State<CollapsibleCalendar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month, 1);

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    // Set initial state
    if (widget.isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(CollapsibleCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Animate when expansion state changes
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }

    // Update month when selected date changes to a different month
    if (widget.selectedDate.month != oldWidget.selectedDate.month ||
        widget.selectedDate.year != oldWidget.selectedDate.year) {
      setState(() {
        _currentMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month, 1);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: weekday - 1));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _hasMarker(DateTime date) {
    if (widget.markedDates == null) return false;
    return widget.markedDates!.any((d) => _isSameDay(d, date));
  }

  void _goToPrevious() {
    if (widget.isExpanded) {
      // Month view - go to previous month
      setState(() {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
      });
    } else {
      // Week view - go to previous week
      final newDate = widget.selectedDate.subtract(const Duration(days: 7));
      widget.onDateSelected(newDate);
      setState(() {
        _currentMonth = DateTime(newDate.year, newDate.month, 1);
      });
    }
  }

  void _goToNext() {
    if (widget.isExpanded) {
      // Month view - go to next month
      setState(() {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
      });
    } else {
      // Week view - go to next week
      final newDate = widget.selectedDate.add(const Duration(days: 7));
      widget.onDateSelected(newDate);
      setState(() {
        _currentMonth = DateTime(newDate.year, newDate.month, 1);
      });
    }
  }

  void _goToToday() {
    final today = DateTime.now();
    setState(() {
      _currentMonth = DateTime(today.year, today.month, 1);
    });
    widget.onDateSelected(DateTime(today.year, today.month, today.day));
  }

  void _onHeaderTap() {
    // Notify parent to toggle expansion state
    widget.onToggleExpand?.call();
  }

  String _getHeaderText() {
    if (widget.isExpanded) {
      // Month view - show "YYYY년 M월"
      return DateFormat('yyyy년 M월', 'ko').format(_currentMonth);
    } else {
      // Week view - show week range "M월 D일 - D일"
      final weekStart = _getWeekStart(widget.selectedDate);
      final weekEnd = weekStart.add(const Duration(days: 6));

      if (weekStart.month == weekEnd.month) {
        return '${weekStart.month}월 ${weekStart.day}일 - ${weekEnd.day}일';
      } else {
        return '${weekStart.month}월 ${weekStart.day}일 - ${weekEnd.month}월 ${weekEnd.day}일';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with navigation - clean and simple
          GestureDetector(
            onTap: _onHeaderTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space4,
                AppSpacing.space4,
                AppSpacing.space4,
                AppSpacing.space2,
              ),
              child: Row(
                children: [
                  // Previous button
                  _buildNavButton(
                    icon: Icons.chevron_left,
                    onPressed: _goToPrevious,
                  ),

                  // Center - Date range
                  Expanded(
                    child: Center(
                      child: Text(
                        _getHeaderText(),
                        style: AppTypography.headingMedium.copyWith(
                          color: AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // Next button
                  _buildNavButton(
                    icon: Icons.chevron_right,
                    onPressed: _goToNext,
                  ),
                ],
              ),
            ),
          ),

          // Calendar body - clean and simple
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.space4,
                  AppSpacing.space3,
                  AppSpacing.space4,
                  AppSpacing.space4,
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
                                      color: AppColors.textSecondaryLight,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),

                    const SizedBox(height: AppSpacing.space3),

                    // Calendar days
                    _buildCalendarBody(todayOnly),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondaryLight,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: AppColors.textPrimaryLight,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildCalendarBody(DateTime today) {
    // Calculate which week contains the selected date
    final selectedWeekStart = _getWeekStart(widget.selectedDate);

    // Build month view
    final monthView = _buildMonthView(today);

    // Build week view (focused on selected date's week)
    final weekView = _buildWeekView(today, selectedWeekStart);

    // Cross-fade between month and week view
    return AnimatedCrossFade(
      firstChild: monthView,
      secondChild: weekView,
      crossFadeState: widget.isExpanded
          ? CrossFadeState.showFirst
          : CrossFadeState.showSecond,
      duration: const Duration(milliseconds: 300),
      sizeCurve: Curves.easeInOut,
    );
  }

  Widget _buildWeekView(DateTime today, DateTime weekStart) {
    return Row(
      children: List.generate(7, (index) {
        final date = weekStart.add(Duration(days: index));
        return Expanded(
          child: _buildDayCell(date, today),
        );
      }),
    );
  }

  Widget _buildMonthView(DateTime today) {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday; // 1=Mon, 7=Sun
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;

    // Calculate number of weeks needed
    final totalCells = firstWeekday - 1 + daysInMonth;
    final weeks = (totalCells / 7).ceil();

    return Column(
      children: List.generate(weeks, (weekIndex) {
        return Padding(
          padding: EdgeInsets.only(bottom: weekIndex < weeks - 1 ? 8 : 0),
          child: Row(
            children: List.generate(7, (dayIndex) {
              final cellIndex = weekIndex * 7 + dayIndex;
              final dayNumber = cellIndex - (firstWeekday - 1) + 1;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                // Empty cell for days outside current month
                return const Expanded(child: SizedBox(height: 48));
              }

              final date = DateTime(
                _currentMonth.year,
                _currentMonth.month,
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
    final hasMarker = _hasMarker(date);
    final isCurrentMonth = date.month == _currentMonth.month;

    // Determine text color
    Color getTextColor() {
      if (isSelected) {
        return Colors.white;
      }
      if (!isCurrentMonth) {
        return AppColors.textDisabledLight;
      }
      return AppColors.textPrimaryLight;
    }

    return GestureDetector(
      onTap: () {
        widget.onDateSelected(date);
      },
      child: Container(
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : isToday
                  ? AppColors.primaryLight.withValues(alpha: 0.3)
                  : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: AppTypography.bodyLarge.copyWith(
                color: getTextColor(),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 18,
              ),
            ),
            if (hasMarker)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A wrapper that provides scroll-based calendar expansion control
class ScrollableCalendarView extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final Set<DateTime>? markedDates;
  final Widget Function(DateTime selectedDate) contentBuilder;

  const ScrollableCalendarView({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.contentBuilder,
    this.markedDates,
  });

  @override
  State<ScrollableCalendarView> createState() => _ScrollableCalendarViewState();
}

class _ScrollableCalendarViewState extends State<ScrollableCalendarView> {
  bool _isCalendarExpanded = true;
  final ScrollController _scrollController = ScrollController();
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final offset = _scrollController.offset;
    final delta = offset - _lastScrollOffset;

    // Only react to significant scroll movements
    if (delta.abs() > 10) {
      if (delta > 0 && _isCalendarExpanded) {
        // Scrolling down - collapse calendar
        setState(() {
          _isCalendarExpanded = false;
        });
      } else if (delta < 0 && !_isCalendarExpanded && offset < 50) {
        // Scrolling up near top - expand calendar
        setState(() {
          _isCalendarExpanded = true;
        });
      }
      _lastScrollOffset = offset;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Collapsible Calendar
        Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: CollapsibleCalendar(
            selectedDate: widget.selectedDate,
            onDateSelected: widget.onDateSelected,
            isExpanded: _isCalendarExpanded,
            markedDates: widget.markedDates,
          ),
        ),

        // Scrollable content
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              // Let scroll controller handle it
              return false;
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: widget.contentBuilder(widget.selectedDate),
            ),
          ),
        ),
      ],
    );
  }
}
