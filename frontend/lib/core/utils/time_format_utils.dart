/// Time formatting utilities for practice time display.
library;

/// Format seconds to Korean time text (e.g., "1시간 30분", "45분")
String formatPracticeTime(int seconds) {
  final minutes = seconds ~/ 60;
  if (minutes >= 60) {
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    return remaining > 0 ? '$hours시간 $remaining분' : '$hours시간';
  }
  return '$minutes분';
}

/// Format minutes to Korean time text
String formatMinutesToText(int minutes) {
  if (minutes >= 60) {
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    return remaining > 0 ? '$hours시간 $remaining분' : '$hours시간';
  }
  return '$minutes분';
}

/// Get week number of the month for a given date
int getWeekOfMonth(DateTime date) {
  final firstDayOfMonth = DateTime(date.year, date.month, 1);
  final firstMondayOffset = (8 - firstDayOfMonth.weekday) % 7;
  final firstMonday = firstDayOfMonth.add(Duration(days: firstMondayOffset));

  if (date.isBefore(firstMonday)) return 1;
  return ((date.day - firstMonday.day) ~/ 7) + 2;
}

/// Get Monday of the week containing the given date
DateTime getMondayOfWeek(DateTime date) {
  final weekStart = date.subtract(Duration(days: date.weekday - 1));
  return DateTime(weekStart.year, weekStart.month, weekStart.day);
}
