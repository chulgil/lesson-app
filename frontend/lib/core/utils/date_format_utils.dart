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

/// 과거 날짜를 일 단위 상대 표기로 (오늘 / 어제 / N일 전 / N주 전 / N개월 전 / N년 전).
/// 분·시간 단위는 [formatRelativeTime] 참조.
String formatRelativeDay(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inDays == 0) return '오늘';
  if (diff.inDays == 1) return '어제';
  if (diff.inDays < 7) return '${diff.inDays}일 전';
  if (diff.inDays < 30) return '${diff.inDays ~/ 7}주 전';
  if (diff.inDays < 365) return '${diff.inDays ~/ 30}개월 전';
  return '${diff.inDays ~/ 365}년 전';
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

/// Format date as M월 d일 요일 (e.g., 4월 5일 토요일)
String formatDateMDWithDayLong(DateTime date) {
  const dayNames = ['', '월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
  return '${date.month}월 ${date.day}일 ${dayNames[date.weekday]}';
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

/// Format day-of-week index (0=월, 6=일) as full Korean label (e.g., '월요일')
/// Returns empty string for out-of-range values.
String dayOfWeekLabel(int day) {
  const days = ['월', '화', '수', '목', '금', '토', '일'];
  if (day < 0 || day > 6) return '';
  return '${days[day]}요일';
}

/// Format date as M/d (e.g., 4/5)
String formatDateMD(DateTime date) {
  return '${date.month}/${date.day}';
}

/// Format date as M월 d일 (e.g., 4월 5일)
String formatDateMDKorean(DateTime date) {
  return '${date.month}월 ${date.day}일';
}

/// Format date as M월 d일 (요일) (e.g., 4월 5일 (토))
String formatDateMDWithDayParens(DateTime date) {
  const dayNames = ['', '월', '화', '수', '목', '금', '토', '일'];
  return '${date.month}월 ${date.day}일 (${dayNames[date.weekday]})';
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

/// Format date as yyyy년 M월 d일 (no weekday, e.g., 2026년 4월 5일)
String formatDateYMDKorean(DateTime date) {
  return '${date.year}년 ${date.month}월 ${date.day}일';
}

/// Format date as yyyy.M.d (e.g., 2026.4.5)
String formatDateYMDShort(DateTime date) {
  return '${date.year}.${date.month}.${date.day}';
}

/// Format date as yyyy.M.d HH:mm (e.g., 2026.4.5 14:00)
String formatDateTimeYMDHM(DateTime date) {
  return '${formatDateYMDShort(date)} ${formatTimeHM(date)}';
}

/// Format date as yyyy-MM-dd HH:mm (e.g., 2026-04-05 14:00)
/// Use for logs, backup timestamps, and ISO-style displays.
String formatDateTimeDash(DateTime date) {
  final y = date.year.toString();
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d ${formatTimeHM(date)}';
}

/// Format date as yyyy-MM-dd (e.g., 2026-04-05)
String formatDateDashPadded(DateTime date) {
  final y = date.year.toString();
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Format date as yyyy.MM.dd HH:mm (e.g., 2026.04.05 14:00)
/// Padded variant used for recording list timestamps.
String formatDateTimeDotPadded(DateTime date) {
  final y = date.year.toString();
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y.$m.$d ${formatTimeHM(date)}';
}

/// Format time as 오전/오후 H:mm (e.g., 오후 2:30)
String formatTimeAMPM(DateTime date) {
  final hour = date.hour;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = hour < 12 ? AppStrings.timeAM : AppStrings.timePM;
  final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  return '$period $displayHour:$minute';
}
