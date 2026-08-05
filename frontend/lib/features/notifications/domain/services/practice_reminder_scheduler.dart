import '../entities/notification.dart';
import 'notification_service.dart';

/// Schedules the student's weekly practice reminders.
///
/// Consumes primitives only (no presentation state) so the student_home
/// provider can pass its own persisted settings; title/body are injected by
/// the caller to keep user-facing strings out of the domain layer.
class PracticeReminderScheduler {
  PracticeReminderScheduler(this._notificationService, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final RecurringNotificationService _notificationService;
  final DateTime Function() _clock;

  /// Weekly-recurring reminder per selected day.
  ///
  /// [weekdays] uses the UI convention 0=Mon .. 6=Sun. Existing entries are
  /// cancelled first so this call is a full resync of the 7-day window.
  Future<void> scheduleWeeklyReminders({
    required String userId,
    required int hour,
    required int minute,
    required Set<int> weekdays,
    required String title,
    required String body,
  }) async {
    await cancelWeeklyReminders(userId);

    for (final day in weekdays) {
      final weekday = day + 1; // DateTime.weekday: 1=Mon .. 7=Sun
      final notification = AppNotification(
        id: _notificationId(userId, weekday),
        userId: userId,
        type: NotificationType.practiceReminder,
        priority: NotificationPriority.normal,
        title: title,
        body: body,
        createdAt: _clock(),
        scheduledAt: _nextOccurrence(weekday, hour, minute),
      );
      await _notificationService.scheduleWeeklyNotification(notification);
    }
  }

  /// Cancels reminders for every weekday slot of [userId].
  Future<void> cancelWeeklyReminders(String userId) async {
    for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
      await _notificationService.cancelNotification(
        _notificationId(userId, weekday),
      );
    }
  }

  String _notificationId(String userId, int weekday) =>
      'practice_reminder_weekly_${userId}_$weekday';

  DateTime _nextOccurrence(int weekday, int hour, int minute) {
    final now = _clock();
    var candidate = DateTime(now.year, now.month, now.day, hour, minute);
    while (candidate.weekday != weekday || !candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }
}
