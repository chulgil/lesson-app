/// Centralized date formatting utilities
/// All date displays should use these functions for consistency
library;

import '../l10n/app_strings.dart';

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

/// Format date as M/d(요일) (e.g., 4/5(토))
String formatDateMDWithDay(DateTime date) {
  const dayNames = ['', '월', '화', '수', '목', '금', '토', '일'];
  return '${date.month}/${date.day}(${dayNames[date.weekday]})';
}

/// Format date as yyyy년 M월 (e.g., 2026년 4월)
String formatYearMonth(DateTime date) {
  return '${date.year}년 ${date.month}월';
}

/// Format weekday as single Korean char (e.g., '월', '화')
String formatWeekdayShort(DateTime date) {
  const dayNames = ['', '월', '화', '수', '목', '금', '토', '일'];
  return dayNames[date.weekday];
}

/// Format date as M/d (e.g., 4/5)
String formatDateMD(DateTime date) {
  return '${date.month}/${date.day}';
}

/// Format time as HH:mm (e.g., 14:00)
String formatTimeHM(DateTime date) {
  return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

/// Format date as M/d(요일) HH:mm (e.g., 4/5(토) 14:00)
String formatDateTimeMDHM(DateTime date) {
  return '${formatDateMDWithDay(date)} ${formatTimeHM(date)}';
}

/// Format date as yyyy년 M월 d일 (요일) (e.g., 2026년 4월 5일 (토))
String formatDateYMDLong(DateTime date) {
  const dayNames = ['', '월', '화', '수', '목', '금', '토', '일'];
  return '${date.year}년 ${date.month}월 ${date.day}일 (${dayNames[date.weekday]})';
}

/// Format date as yyyy.M.d (e.g., 2026.4.5)
String formatDateYMDShort(DateTime date) {
  return '${date.year}.${date.month}.${date.day}';
}

/// Format date as yyyy.M.d HH:mm (e.g., 2026.4.5 14:00)
String formatDateTimeYMDHM(DateTime date) {
  return '${formatDateYMDShort(date)} ${formatTimeHM(date)}';
}

/// Format time as 오전/오후 H:mm (e.g., 오후 2:30)
String formatTimeAMPM(DateTime date) {
  final hour = date.hour;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = hour < 12 ? AppStrings.timeAM : AppStrings.timePM;
  final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  return '$period $displayHour:$minute';
}
