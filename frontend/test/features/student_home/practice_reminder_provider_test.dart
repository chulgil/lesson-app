import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lessonaza/features/auth/auth_facade.dart';
import 'package:lessonaza/features/notifications/domain/entities/notification.dart';
import 'package:lessonaza/features/notifications/domain/services/notification_service.dart';
import 'package:lessonaza/features/notifications/notifications_facade.dart';
import 'package:lessonaza/features/student_home/presentation/providers/practice_reminder_provider.dart';

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
  late Directory tempDir;
  late _FakeRecurringService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('practice_reminder_test');
    Hive.init(tempDir.path);
    await Hive.openBox('notification_settings');
    service = _FakeRecurringService();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  ProviderContainer container({String userId = 'stu1'}) {
    final c = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWith((ref) => userId),
        practiceReminderSchedulerProvider.overrideWith(
          (ref) => PracticeReminderScheduler(
            service,
            clock: () => DateTime(2026, 7, 2, 12),
          ),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('mutations persist to Hive under a user-scoped key', () async {
    final c = container();
    c.read(practiceReminderProvider.notifier).setTime(19, 30);
    await Future<void>.delayed(Duration.zero);

    final raw =
        Hive.box('notification_settings').get('student:stu1:practiceReminder')
            as String?;
    expect(raw, isNotNull);
    final json = jsonDecode(raw!) as Map<String, dynamic>;
    expect(json['hour'], 19);
    expect(json['minute'], 30);
  });

  test('a fresh container restores the persisted state (#503)', () async {
    final c1 = container();
    c1.read(practiceReminderProvider.notifier).setTime(7, 15);
    c1.read(practiceReminderProvider.notifier).toggleDay(0);
    await Future<void>.delayed(Duration.zero);

    final c2 = container();
    final restored = c2.read(practiceReminderProvider);
    expect(restored.hour, 7);
    expect(restored.minute, 15);
    expect(restored.selectedDays.contains(0), isFalse);
  });

  test(
    'enabling state schedules weekly reminders through the facade',
    () async {
      final c = container();
      c.read(practiceReminderProvider.notifier).setTime(18, 0);
      await Future<void>.delayed(Duration.zero);

      expect(service.weekly, isNotEmpty);
      expect(service.weekly.first.type, NotificationType.practiceReminder);
      expect(service.weekly.first.scheduledAt!.hour, 18);
      // Default state selects all 7 days.
      expect(service.weekly, hasLength(7));
    },
  );

  test('disabling cancels the weekly schedule and persists', () async {
    final c = container();
    c.read(practiceReminderProvider.notifier).toggleEnabled(false);
    await Future<void>.delayed(Duration.zero);

    expect(service.weekly, isEmpty);
    expect(service.cancelled, hasLength(7));

    final raw =
        Hive.box('notification_settings').get('student:stu1:practiceReminder')
            as String?;
    expect((jsonDecode(raw!) as Map<String, dynamic>)['isEnabled'], isFalse);
  });

  test('the last remaining day cannot be deselected', () {
    final c = container();
    final notifier = c.read(practiceReminderProvider.notifier);
    for (var day = 0; day < 6; day++) {
      notifier.toggleDay(day);
    }
    expect(c.read(practiceReminderProvider).selectedDays, {6});

    notifier.toggleDay(6);
    expect(c.read(practiceReminderProvider).selectedDays, {6});
  });
}
