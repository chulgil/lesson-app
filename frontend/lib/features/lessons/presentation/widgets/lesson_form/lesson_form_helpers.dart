import 'package:flutter/material.dart';

/// Helper function to format time
String formatLessonTime(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

/// Select date helper
Future<DateTime?> selectLessonDate(
  BuildContext context,
  DateTime initialDate,
) async {
  final now = DateTime.now();
  final firstDate = now.subtract(const Duration(days: 7));
  // Clamp initialDate within the allowed range
  final clampedInitial = initialDate.isBefore(firstDate) ? firstDate : initialDate;

  return showDatePicker(
    context: context,
    initialDate: clampedInitial,
    firstDate: firstDate,
    lastDate: now.add(const Duration(days: 365)),
    locale: const Locale('ko'),
  );
}

/// Select time helper
Future<TimeOfDay?> selectLessonTime(
  BuildContext context,
  TimeOfDay initialTime,
) async {
  return showTimePicker(
    context: context,
    initialTime: initialTime,
    builder: (context, child) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      );
    },
  );
}

/// Check if the selected date+time is in the past
bool isLessonDateTimeInPast(DateTime date, TimeOfDay time) {
  final lessonDateTime = DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
  return lessonDateTime.isBefore(DateTime.now());
}

/// Select date helper for edit screen (allows past dates)
Future<DateTime?> selectLessonDateForEdit(
  BuildContext context,
  DateTime initialDate,
) async {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime.now().subtract(const Duration(days: 365)),
    lastDate: DateTime.now().add(const Duration(days: 365)),
    locale: const Locale('ko'),
  );
}
