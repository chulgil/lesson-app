/// Date utility functions for lesson scheduling
class LessonDateUtils {
  LessonDateUtils._();

  /// Korean weekday names (1=월 to 7=일)
  static const List<String> weekdayNamesKorean = [
    '월', '화', '수', '목', '금', '토', '일',
  ];

  /// Full Korean weekday names (1=월요일 to 7=일요일)
  static const List<String> weekdayFullNamesKorean = [
    '월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일',
  ];

  /// Get short Korean weekday name (1=월, 2=화, ...)
  /// [weekday] should be 1-7 (1=Monday, 7=Sunday)
  static String getWeekdayNameKorean(int weekday) {
    if (weekday < 1 || weekday > 7) {
      throw ArgumentError('Weekday must be between 1 and 7, got: $weekday');
    }
    return weekdayNamesKorean[weekday - 1];
  }

  /// Get full Korean weekday name (1=월요일, 2=화요일, ...)
  /// [weekday] should be 1-7 (1=Monday, 7=Sunday)
  static String getWeekdayFullNameKorean(int weekday) {
    if (weekday < 1 || weekday > 7) {
      throw ArgumentError('Weekday must be between 1 and 7, got: $weekday');
    }
    return weekdayFullNamesKorean[weekday - 1];
  }

  /// Format schedule display (e.g., "화요일 15:00" or "매주 화요일 15:00")
  static String formatScheduleDisplay({
    required int weekday,
    required String time,
    bool includeWeekly = false,
  }) {
    final dayName = getWeekdayFullNameKorean(weekday);
    return includeWeekly ? '매주 $dayName $time' : '$dayName $time';
  }

  /// Get the week number of the month for a given date (ISO week, Monday start)
  /// Week 1: Days 1-7 that include Monday
  /// Example: Dec 15, 2024 (Sunday) -> Week 3
  static int getWeekOfMonth(DateTime date) {
    // Get the first day of the month
    final firstDayOfMonth = DateTime(date.year, date.month, 1);

    // Find the first Monday of the month (or the Monday before if month starts mid-week)
    final firstMonday = firstDayOfMonth.weekday == DateTime.monday
        ? firstDayOfMonth
        : firstDayOfMonth
            .add(Duration(days: (8 - firstDayOfMonth.weekday) % 7));

    // If the date is before the first Monday, it's week 1
    if (date.isBefore(firstMonday)) {
      return 1;
    }

    // Calculate week number
    final daysSinceFirstMonday = date.difference(firstMonday).inDays;
    return (daysSinceFirstMonday ~/ 7) + (date.isBefore(firstMonday) ? 1 : 2);
  }

  /// Get total weeks in a month
  /// A month has 5 weeks if the last day falls in week 5
  static int getTotalWeeksInMonth(int year, int month) {
    final lastDay = DateTime(year, month + 1, 0);
    return getWeekOfMonth(lastDay);
  }

  /// Calculate remaining weeks from start date to end of month
  /// Includes the current week
  static int getRemainingWeeksInMonth(DateTime startDate) {
    final totalWeeks = getTotalWeeksInMonth(startDate.year, startDate.month);
    final currentWeek = getWeekOfMonth(startDate);
    return totalWeeks - currentWeek + 1;
  }

  /// Calculate prorated fee for the first month
  /// Formula: monthlyFee × (remainingWeeks / 4)
  ///
  /// Parameters:
  /// - monthlyFee: Full monthly fee
  /// - startDate: Lesson start date
  /// - lessonsPerWeek: Number of lessons per week (1 or 2)
  ///
  /// Returns a record with:
  /// - proratedFee: Calculated prorated fee (rounded to nearest 1000)
  /// - remainingWeeks: Number of remaining weeks
  /// - totalWeeks: Total weeks in the month
  static ({int proratedFee, int remainingWeeks, int totalWeeks}) calculateProratedFee({
    required int monthlyFee,
    required DateTime startDate,
    required int lessonsPerWeek,
  }) {
    final totalWeeks = getTotalWeeksInMonth(startDate.year, startDate.month);
    final remainingWeeks = getRemainingWeeksInMonth(startDate);

    // Calculate prorated fee: monthlyFee × (remainingWeeks / 4)
    // Round to nearest 1000 won
    final rawFee = (monthlyFee * remainingWeeks / 4).round();
    final proratedFee = ((rawFee + 500) ~/ 1000) * 1000;

    return (
      proratedFee: proratedFee,
      remainingWeeks: remainingWeeks,
      totalWeeks: totalWeeks,
    );
  }

  /// Check if a month has 5 weeks
  static bool hasWeek5(int year, int month) {
    return getTotalWeeksInMonth(year, month) >= 5;
  }

  /// Get the Monday of the week containing the given date
  static DateTime getMondayOfWeek(DateTime date) {
    final daysFromMonday = (date.weekday - DateTime.monday) % 7;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  /// Get all dates of a specific weekday in a month from a start date
  /// Useful for counting actual lesson dates
  static List<DateTime> getLessonDatesInMonth({
    required DateTime startDate,
    required int weekday, // 1 = Monday, 7 = Sunday
  }) {
    final dates = <DateTime>[];
    final lastDayOfMonth = DateTime(startDate.year, startDate.month + 1, 0);

    // Find the first occurrence of the weekday on or after startDate
    var current = startDate;
    while (current.weekday != weekday) {
      current = current.add(const Duration(days: 1));
    }

    // Collect all occurrences until end of month
    while (current.isBefore(lastDayOfMonth) ||
        current.isAtSameMomentAs(lastDayOfMonth)) {
      dates.add(current);
      current = current.add(const Duration(days: 7));
    }

    return dates;
  }

  /// Format week info for display
  /// Example: "3주분" or "2주분 (5주차 휴강)"
  static String formatWeekInfo(int remainingWeeks, int totalWeeks) {
    if (totalWeeks >= 5) {
      return '$remainingWeeks주분 (5주차 휴강)';
    }
    return '$remainingWeeks주분';
  }
}
