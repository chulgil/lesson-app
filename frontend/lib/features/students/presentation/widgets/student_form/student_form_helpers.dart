import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Standard input decoration for student form fields.
InputDecoration studentInputDecoration({
  required String label,
  required String hint,
  required IconData prefixIcon,
  bool isRequired = false,
}) {
  return InputDecoration(
    labelText: isRequired ? '$label *' : label,
    hintText: hint,
    prefixIcon: Icon(prefixIcon),
    border: const OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.inkQuaternary),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: AppColors.inkQuaternary),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: AppColors.paperAccent, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.paperAccent),
    ),
    filled: true,
    fillColor: AppColors.paper,
  );
}

/// Format time as HH:mm.
String formatTime(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

/// Format amount in 만원 units (e.g., 200000 -> "20만원", 65000 -> "6.5만원").
String formatCurrencyInMan(int amount) {
  final manWon = amount / 10000;
  if (manWon == manWon.toInt()) {
    return '${manWon.toInt()}만원';
  } else {
    return '${manWon.toStringAsFixed(1)}만원';
  }
}

/// Show time picker and return selected time.
Future<TimeOfDay?> selectTime(
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
