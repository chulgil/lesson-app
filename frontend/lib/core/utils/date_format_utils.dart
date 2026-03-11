/// Centralized date formatting utilities
/// All date displays should use these functions for consistency

/// Format date as YYYY.MM.DD (e.g., 2026.03.11)
String formatDateYMD(DateTime date) {
  return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
}

/// Format date as YYYY.MM.DD with day name (e.g., 2026.03.11 (화))
String formatDateYMDWithDay(DateTime date) {
  const dayNames = ['', '월', '화', '수', '목', '금', '토', '일'];
  return '${formatDateYMD(date)} (${dayNames[date.weekday]})';
}
