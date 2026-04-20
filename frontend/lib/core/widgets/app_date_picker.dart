import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

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
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surfaceLight,
              onSurface: AppColors.textPrimaryLight,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: AppColors.surfaceLight,
              headerBackgroundColor: AppColors.primary,
              headerForegroundColor: Colors.white,
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                if (states.contains(WidgetState.disabled)) {
                  return AppColors.textDisabledLight;
                }
                return AppColors.textPrimaryLight;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primary;
                }
                return null;
              }),
              todayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return AppColors.primary;
              }),
              todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primary;
                }
                return null;
              }),
              todayBorder: BorderSide(color: AppColors.primary, width: 1.5),
              // Improved action button styles for visibility
              cancelButtonStyle: ButtonStyle(
                foregroundColor: WidgetStateProperty.all(
                  AppColors.textSecondaryLight,
                ),
                textStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              confirmButtonStyle: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(AppColors.primary),
                foregroundColor: WidgetStateProperty.all(Colors.white),
                textStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                  ),
                ),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
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
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surfaceLight,
              onSurface: AppColors.textPrimaryLight,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: AppColors.surfaceLight,
              headerBackgroundColor: AppColors.primary,
              headerForegroundColor: Colors.white,
              rangePickerBackgroundColor: AppColors.surfaceLight,
              rangePickerHeaderBackgroundColor: AppColors.primary,
              rangePickerHeaderForegroundColor: Colors.white,
              rangeSelectionBackgroundColor: AppColors.primaryLight.withValues(
                alpha: 0.3,
              ),
              // Action button styles
              cancelButtonStyle: ButtonStyle(
                foregroundColor: WidgetStateProperty.all(
                  AppColors.textSecondaryLight,
                ),
                textStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              confirmButtonStyle: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(AppColors.primary),
                foregroundColor: WidgetStateProperty.all(Colors.white),
                textStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                  ),
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
