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
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime.now(),
    lastDate: DateTime.now().add(const Duration(days: 365)),
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
