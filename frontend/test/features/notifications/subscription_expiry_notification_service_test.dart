import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/notifications/domain/entities/notification.dart';
import 'package:lessonaza/features/notifications/domain/entities/subscription_expiry_reminder_settings.dart';
import 'package:lessonaza/features/notifications/domain/services/subscription_expiry_notification_service.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';

class _FakeScheduler implements SubscriptionExpiryScheduler {
  final List<AppNotification> scheduled = [];
  final List<String> cancelled = [];

  @override
  Future<void> scheduleNotification(AppNotification notification) async {
    scheduled.add(notification);
  }

  @override
  Future<void> cancelNotification(String id) async {
    cancelled.add(id);
  }
}

void main() {
  group('SubscriptionExpiryNotificationService', () {
    late _FakeScheduler scheduler;
    late SubscriptionExpiryNotificationService service;
    late DateTime now;

    setUp(() {
      scheduler = _FakeScheduler();
      now = DateTime(2026, 4, 24, 9);
      service = SubscriptionExpiryNotificationService(
        scheduler: scheduler,
        clock: () => now,
      );
    });

    Subscription sub({
      String id = 'sub_1',
      String studentId = 'student_1',
      SubscriptionStatus status = SubscriptionStatus.active,
      DateTime? endDate,
    }) {
      return Subscription(
        id: id,
        studentId: studentId,
        membershipId: 'cm_1',
        type: SubscriptionType.package,
        totalLessons: 8,
        usedLessons: 0,
        startDate: now.subtract(const Duration(days: 30)),
        endDate: endDate,
        amount: 200000,
        status: status,
        createdAt: now.subtract(const Duration(days: 30)),
      );
    }

    test('활성 수강권 D-14 / D-7 / D-1 / D-0 총 4건 등록', () async {
      // 만료일이 14일 뒤
      final subscription = sub(endDate: DateTime(2026, 5, 8));

      await service.scheduleForSubscription(
        teacherId: 'teacher_1',
        subscription: subscription,
        studentName: '김민지',
        settings: SubscriptionExpiryReminderSettings.defaults,
      );

      expect(scheduler.scheduled.length, 4);
      final ids = scheduler.scheduled.map((n) => n.id).toSet();
      expect(ids, {
        'sub_expiry_sub_1_d14',
        'sub_expiry_sub_1_d7',
        'sub_expiry_sub_1_d1',
        'sub_expiry_sub_1_d0',
      });
    });

    test('학생 이름이 title/body에 포함', () async {
      final subscription = sub(endDate: DateTime(2026, 5, 1));

      await service.scheduleForSubscription(
        teacherId: 'teacher_1',
        subscription: subscription,
        studentName: '김민지',
        settings: SubscriptionExpiryReminderSettings.defaults,
      );

      final d1 = scheduler.scheduled.firstWhere((n) => n.id.endsWith('_d1'));
      expect(d1.body.contains('김민지'), isTrue);
    });

    test('D-0는 만료 당일 아침 — subscriptionExpired 타입', () async {
      final subscription = sub(endDate: DateTime(2026, 5, 1));

      await service.scheduleForSubscription(
        teacherId: 'teacher_1',
        subscription: subscription,
        studentName: '학생',
        settings: SubscriptionExpiryReminderSettings.defaults,
      );

      final d0 = scheduler.scheduled.firstWhere((n) => n.id.endsWith('_d0'));
      expect(d0.type, NotificationType.subscriptionExpired);
      final others = scheduler.scheduled.where((n) => !n.id.endsWith('_d0'));
      for (final n in others) {
        expect(n.type, NotificationType.subscriptionExpiringSoon);
      }
    });

    test('이미 지난 D-day 는 스케줄하지 않음', () async {
      // 만료일이 2일 뒤 — D-14, D-7 은 과거
      final subscription = sub(endDate: DateTime(2026, 4, 26));

      await service.scheduleForSubscription(
        teacherId: 'teacher_1',
        subscription: subscription,
        studentName: '학생',
        settings: SubscriptionExpiryReminderSettings.defaults,
      );

      final ids = scheduler.scheduled.map((n) => n.id).toSet();
      expect(ids, {'sub_expiry_sub_1_d1', 'sub_expiry_sub_1_d0'});
    });

    test('만료된 수강권은 아무것도 스케줄하지 않음', () async {
      final subscription = sub(
        endDate: DateTime(2026, 5, 1),
        status: SubscriptionStatus.expired,
      );

      await service.scheduleForSubscription(
        teacherId: 'teacher_1',
        subscription: subscription,
        studentName: '학생',
        settings: SubscriptionExpiryReminderSettings.defaults,
      );

      expect(scheduler.scheduled, isEmpty);
    });

    test('endDate 없는 수강권은 스킵', () async {
      final subscription = sub(endDate: null);

      await service.scheduleForSubscription(
        teacherId: 'teacher_1',
        subscription: subscription,
        studentName: '학생',
        settings: SubscriptionExpiryReminderSettings.defaults,
      );

      expect(scheduler.scheduled, isEmpty);
    });

    test('master 토글 OFF → 아무것도 스케줄하지 않음', () async {
      final subscription = sub(endDate: DateTime(2026, 5, 8));

      await service.scheduleForSubscription(
        teacherId: 'teacher_1',
        subscription: subscription,
        studentName: '학생',
        settings: const SubscriptionExpiryReminderSettings(enabled: false),
      );

      expect(scheduler.scheduled, isEmpty);
    });

    test('개별 offset 토글 OFF → 해당 offset만 제외', () async {
      final subscription = sub(endDate: DateTime(2026, 5, 8));

      await service.scheduleForSubscription(
        teacherId: 'teacher_1',
        subscription: subscription,
        studentName: '학생',
        settings: const SubscriptionExpiryReminderSettings(
          enabled: true,
          remindAtD14: true,
          remindAtD7: false, // D-7 off
          remindAtD1: true,
          remindAtD0: true,
        ),
      );

      final ids = scheduler.scheduled.map((n) => n.id).toSet();
      expect(ids, {
        'sub_expiry_sub_1_d14',
        'sub_expiry_sub_1_d1',
        'sub_expiry_sub_1_d0',
      });
    });

    test('cancelForSubscription — 4개 ID 모두 취소 요청', () async {
      await service.cancelForSubscription('sub_1');

      expect(scheduler.cancelled, [
        'sub_expiry_sub_1_d14',
        'sub_expiry_sub_1_d7',
        'sub_expiry_sub_1_d1',
        'sub_expiry_sub_1_d0',
      ]);
    });

    test('배치 모드: scheduleForSubscriptions 여러 건 동시 등록', () async {
      await service.scheduleForSubscriptions(
        teacherId: 'teacher_1',
        subscriptions: [
          sub(id: 'sub_a', endDate: DateTime(2026, 5, 8)),
          sub(
            id: 'sub_b',
            studentId: 'student_2',
            endDate: DateTime(2026, 5, 1),
          ),
        ],
        studentNameResolver: (sid) => sid == 'student_1' ? '학생A' : '학생B',
        settings: SubscriptionExpiryReminderSettings.defaults,
      );

      // sub_a (D-14): 4건, sub_b (D-7): 3건 (D-14 과거)
      expect(scheduler.scheduled.length, 7);
    });
  });

  group('SubscriptionExpiryReminderSettings', () {
    test('defaults — master ON + 모든 offset ON', () {
      const s = SubscriptionExpiryReminderSettings.defaults;
      expect(s.enabled, isTrue);
      expect(s.remindAtD14, isTrue);
      expect(s.remindAtD7, isTrue);
      expect(s.remindAtD1, isTrue);
      expect(s.remindAtD0, isTrue);
    });

    test('copyWith — master 만 변경', () {
      const s = SubscriptionExpiryReminderSettings.defaults;
      final off = s.copyWith(enabled: false);
      expect(off.enabled, isFalse);
      expect(off.remindAtD14, isTrue);
    });

    test('toJson/fromJson round trip', () {
      const s = SubscriptionExpiryReminderSettings(
        enabled: true,
        remindAtD14: true,
        remindAtD7: false,
        remindAtD1: true,
        remindAtD0: true,
      );
      final json = s.toJson();
      final restored = SubscriptionExpiryReminderSettings.fromJson(json);
      expect(restored.enabled, s.enabled);
      expect(restored.remindAtD14, s.remindAtD14);
      expect(restored.remindAtD7, s.remindAtD7);
      expect(restored.remindAtD1, s.remindAtD1);
      expect(restored.remindAtD0, s.remindAtD0);
    });
  });
}
