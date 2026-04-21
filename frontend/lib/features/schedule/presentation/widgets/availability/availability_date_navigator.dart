import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Date navigation widget with swipe and button controls
class AvailabilityDateNavigator extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final bool allowPastDates;

  const AvailabilityDateNavigator({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    this.allowPastDates = false,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final selectedOnly = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final canGoPrevious = allowPastDates || selectedOnly.isAfter(todayOnly);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;

        if (details.primaryVelocity! < -100) {
          // Swipe left -> next day
          _nextDay();
        } else if (details.primaryVelocity! > 100 && canGoPrevious) {
          // Swipe right -> previous day
          _previousDay();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space2,
          vertical: AppSpacing.space3,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Previous button
            IconButton(
              onPressed: canGoPrevious ? _previousDay : null,
              icon: const Icon(Icons.chevron_left),
              color: canGoPrevious
                  ? AppColors.inkSecondary
                  : AppColors.inkTertiary,
            ),

            // Date display
            GestureDetector(
              onTap: () => _showDatePicker(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space4,
                  vertical: AppSpacing.space2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  border: Border.all(color: AppColors.inkQuaternary),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatDate(selectedDate),
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: AppColors.inkSecondary,
                    ),
                  ],
                ),
              ),
            ),

            // Next button
            IconButton(
              onPressed: _nextDay,
              icon: const Icon(Icons.chevron_right),
              color: AppColors.inkSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _previousDay() {
    onDateChanged(selectedDate.subtract(const Duration(days: 1)));
  }

  void _nextDay() {
    onDateChanged(selectedDate.add(const Duration(days: 1)));
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: allowPastDates ? today.subtract(const Duration(days: 365)) : today,
      lastDate: today.add(const Duration(days: 365)),
      locale: const Locale('ko', 'KR'),
    );

    if (picked != null) {
      onDateChanged(picked);
    }
  }

  String _formatDate(DateTime date) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[date.weekday - 1];
    return '${date.month}/${date.day}($weekday)';
  }
}
