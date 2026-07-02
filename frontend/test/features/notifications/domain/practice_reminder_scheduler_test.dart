import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/notifications/domain/entities/notification.dart';
import 'package:lessonaza/features/notifications/domain/services/notification_service.dart';
import 'package:lessonaza/features/notifications/domain/services/practice_reminder_scheduler.dart';

class _FakeRecurringService implements RecurringNotificationService {
  final List<AppNotification> weekly = [];
  final List<String> cancelled = [];

  @override
  Future<void> scheduleWeeklyNotification(AppNotification notification) async {
    weekly.add(notification);
  }

  @override
  Future<void> cancelNotification(String id) async {
    cancelled.add(id);
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> showNotification(AppNotification notification) async {}

  @override
  Future<void> scheduleNotification(AppNotification notification) async {}

  @override
  Future<void> cancelAllNotifications() async {}

  @override
  Stream<AppNotification> get onNotificationTapped => const Stream.empty();
}

void main() {
  late _FakeRecurringService service;
  late DateTime now;
  late PracticeReminderScheduler scheduler;

  setUp(() {
    service = _FakeRecurringService();
    now = DateTime(2026, 7, 2, 12); // fixed reference clock
    scheduler = PracticeReminderScheduler(service, clock: () => now);
  });

  group('scheduleWeeklyReminders', () {
    test('schedules one weekly notification per selected day', () async {
      await scheduler.scheduleWeeklyReminders(
        userId: 'stu1',
        hour: 18,
        minute: 30,
        weekdays: {0, 2, 6}, // Mon, Wed, Sun (UI convention)
        title: 't',
        body: 'b',
      );

      expect(service.weekly, hasLength(3));
      expect(service.weekly.map((n) => n.scheduledAt!.weekday).toSet(), {
        DateTime.monday,
        DateTime.wednesday,
        DateTime.sunday,
      });
      for (final n in service.weekly) {
        expect(n.type, NotificationType.practiceReminder);
        expect(n.scheduledAt!.hour, 18);
        expect(n.scheduledAt!.minute, 30);
        expect(n.scheduledAt!.isAfter(now), isTrue);
        // Next occurrence is within the coming 7 days.
        expect(n.scheduledAt!.difference(now).inDays, lessThanOrEqualTo(7));
      }
    });

    test('resyncs by cancelling all 7 weekday slots first', () async {
      await scheduler.scheduleWeeklyReminders(
        userId: 'stu1',
        hour: 17,
        minute: 0,
        weekdays: {0},
        title: 't',
        body: 'b',
      );

      expect(service.cancelled, hasLength(7));
      expect(
        service.cancelled,
        everyElement(startsWith('practice_reminder_weekly_stu1_')),
      );
    });

    test('a slot exactly at the current instant rolls to next week', () async {
      // Target the clock's own weekday at the clock's exact time.
      final uiDay = now.weekday - 1;
      await scheduler.scheduleWeeklyReminders(
        userId: 'stu1',
        hour: now.hour,
        minute: now.minute,
        weekdays: {uiDay},
        title: 't',
        body: 'b',
      );

      final scheduled = service.weekly.single.scheduledAt!;
      expect(scheduled.weekday, now.weekday);
      expect(scheduled.difference(now).inDays, 7);
    });

    test('notification ids are stable per user+weekday', () async {
      await scheduler.scheduleWeeklyReminders(
        userId: 'stu1',
        hour: 17,
        minute: 0,
        weekdays: {0},
        title: 't',
        body: 'b',
      );
      expect(service.weekly.single.id, 'practice_reminder_weekly_stu1_1');
    });
  });

  group('cancelWeeklyReminders', () {
    test('cancels every weekday slot', () async {
      await scheduler.cancelWeeklyReminders('stu9');
      expect(service.cancelled, hasLength(7));
      expect(service.cancelled.first, 'practice_reminder_weekly_stu9_1');
      expect(service.cancelled.last, 'practice_reminder_weekly_stu9_7');
    });
  });
}
