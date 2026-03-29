/// Centralized date formatting utilities
/// All date displays should use these functions for consistency
library;

/// Format date as YYYY.MM.DD (e.g., 2026.03.11)
String formatDateYMD(DateTime date) {
  return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
}

/// Format date as YYYY.MM.DD with day name (e.g., 2026.03.11 (화))
String formatDateYMDWithDay(DateTime date) {
  const dayNames = ['', '월', '화', '수', '목', '금', '토', '일'];
  return '${formatDateYMD(date)} (${dayNames[date.weekday]})';
}

/// Format relative time from [dateTime] to now (e.g., "2시간 전", "3일 전")
String formatRelativeTime(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);

  if (diff.inMinutes < 1) return '방금 전';
  if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
  if (diff.inHours < 24) return '${diff.inHours}시간 전';
  if (diff.inDays < 7) return '${diff.inDays}일 전';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}주 전';
  return formatDateYMD(dateTime);
}

/// Whether [createdAt] is older than [days] (default 5 for 7-day expiry urgency)
bool isRequestUrgent(DateTime createdAt, {int days = 5}) {
  return DateTime.now().difference(createdAt).inDays >= days;
}
