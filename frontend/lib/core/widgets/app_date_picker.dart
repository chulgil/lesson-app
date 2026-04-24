import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Shared date picker utility with improved UX visibility.
///
/// Usage:
/// ```dart
/// final date = await AppDatePicker.show(
///   context: context,
///   initialDate: DateTime.now(),
///   firstDate: DateTime(2020),
///   lastDate: DateTime(2030),
/// );
/// ```
class AppDatePicker {
  AppDatePicker._();

  /// Shows a date picker with improved button visibility.
  ///
  /// Returns the selected date or null if cancelled.
  static Future<DateTime?> show({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    String? helpText,
    String cancelText = '취소',
    String confirmText = '확인',
  }) async {
    // Ensure initialDate is within valid range
    DateTime validInitialDate = initialDate;
    if (initialDate.isBefore(firstDate)) {
      validInitialDate = firstDate;
    } else if (initialDate.isAfter(lastDate)) {
      validInitialDate = lastDate;
    }

    return showDatePicker(
      context: context,
      initialDate: validInitialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('ko', 'KR'),
      helpText: helpText,
      cancelText: cancelText,
      confirmText: confirmText,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.ink,
              onPrimary: AppColors.paper,
              surface: AppColors.paper,
              onSurface: AppColors.ink,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: AppColors.paper,
              headerBackgroundColor: AppColors.ink,
              headerForegroundColor: AppColors.paper,
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.paper;
                }
                if (states.contains(WidgetState.disabled)) {
                  return AppColors.inkQuaternary;
                }
                return AppColors.ink;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.ink;
                }
                return null;
              }),
              todayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.paper;
                }
                return AppColors.ink;
              }),
              todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.ink;
                }
                return null;
              }),
              todayBorder: BorderSide(color: AppColors.ink, width: 1.5),
              // Improved action button styles for visibility
              cancelButtonStyle: ButtonStyle(
                foregroundColor: WidgetStateProperty.all(
                  AppColors.inkSecondary,
                ),
                textStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              confirmButtonStyle: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(AppColors.ink),
                foregroundColor: WidgetStateProperty.all(AppColors.paper),
                textStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.ink,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  /// Shows a date range picker with improved visibility.
  static Future<DateTimeRange?> showRange({
    required BuildContext context,
    DateTimeRange? initialDateRange,
    required DateTime firstDate,
    required DateTime lastDate,
    String? helpText,
    String cancelText = '취소',
    String confirmText = '확인',
    String saveText = '저장',
  }) async {
    return showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('ko', 'KR'),
      helpText: helpText,
      cancelText: cancelText,
      confirmText: confirmText,
      saveText: saveText,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.ink,
              onPrimary: AppColors.paper,
              surface: AppColors.paper,
              onSurface: AppColors.ink,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: AppColors.paper,
              headerBackgroundColor: AppColors.ink,
              headerForegroundColor: AppColors.paper,
              rangePickerBackgroundColor: AppColors.paper,
              rangePickerHeaderBackgroundColor: AppColors.ink,
              rangePickerHeaderForegroundColor: AppColors.paper,
              rangeSelectionBackgroundColor: AppColors.paperAccent.withValues(
                alpha: 0.3,
              ),
              // Action button styles
              cancelButtonStyle: ButtonStyle(
                foregroundColor: WidgetStateProperty.all(
                  AppColors.inkSecondary,
                ),
                textStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              confirmButtonStyle: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(AppColors.ink),
                foregroundColor: WidgetStateProperty.all(AppColors.paper),
                textStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
