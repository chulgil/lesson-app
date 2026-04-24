import '../../../subscription/domain/entities/subscription.dart';
import '../entities/notification.dart';
import '../entities/subscription_expiry_reminder_settings.dart';

/// 스케줄러 의존성 계약 — `NotificationSchedulerService` 와 호환되는 최소 인터페이스.
///
/// 도메인 서비스는 구체 스케줄러에 묶이지 않고 단위 테스트에서 Fake 주입이 가능하도록
/// 이 작은 인터페이스만 바라본다.
abstract class SubscriptionExpiryScheduler {
  Future<void> scheduleNotification(AppNotification notification);
  Future<void> cancelNotification(String id);
}

typedef StudentNameResolver = String Function(String studentId);

/// 수강권 만료 자동 갱신 알림 스케줄러.
///
/// Spec: docs/specs/student/enrollment_management_ux_spec.md §3.4
///
/// - 활성 수강권 기준 D-14 / D-7 / D-1 / D-0 총 4회 알림 등록
/// - D-0 = `subscriptionExpired`, 나머지 = `subscriptionExpiringSoon`
/// - 알림 ID 규칙: `sub_expiry_{subscriptionId}_d{offset}`
/// - 과거 시점 D-day 는 자동 스킵 (오늘이 D-10 이면 D-14 제외)
/// - 만료/일시정지 수강권은 전체 스킵
class SubscriptionExpiryNotificationService {
  final SubscriptionExpiryScheduler _scheduler;
  final DateTime Function() _clock;

  SubscriptionExpiryNotificationService({
    required SubscriptionExpiryScheduler scheduler,
    DateTime Function()? clock,
  }) : _scheduler = scheduler,
       _clock = clock ?? DateTime.now;

  static const _offsets = <int>[14, 7, 1, 0];

  /// 한 건의 수강권에 대해 D-14/D-7/D-1/D-0 알림을 일괄 등록한다.
  Future<void> scheduleForSubscription({
    required String teacherId,
    required Subscription subscription,
    required String studentName,
    required SubscriptionExpiryReminderSettings settings,
  }) async {
    if (!settings.enabled) return;
    if (subscription.endDate == null) return;
    if (subscription.status != SubscriptionStatus.active &&
        subscription.status != SubscriptionStatus.expiringSoon) {
      return;
    }

    final now = _clock();
    final today = DateTime(now.year, now.month, now.day);
    final endDate = subscription.endDate!;

    for (final offset in _offsets) {
      if (!_isOffsetEnabled(settings, offset)) continue;

      final scheduledDay = endDate.subtract(Duration(days: offset));
      // 아침 9시 알림
      final scheduledAt = DateTime(
        scheduledDay.year,
        scheduledDay.month,
        scheduledDay.day,
        9,
      );

      if (scheduledAt.isBefore(today)) continue;

      final notification = _build(
        teacherId: teacherId,
        subscription: subscription,
        studentName: studentName,
        offset: offset,
        scheduledAt: scheduledAt,
        now: now,
      );

      await _scheduler.scheduleNotification(notification);
    }
  }

  /// 배치 등록 — 여러 수강권에 대해 순차 스케줄.
  Future<void> scheduleForSubscriptions({
    required String teacherId,
    required List<Subscription> subscriptions,
    required StudentNameResolver studentNameResolver,
    required SubscriptionExpiryReminderSettings settings,
  }) async {
    for (final subscription in subscriptions) {
      await scheduleForSubscription(
        teacherId: teacherId,
        subscription: subscription,
        studentName: studentNameResolver(subscription.studentId),
        settings: settings,
      );
    }
  }

  /// 특정 수강권의 4개 예약된 알림을 모두 취소한다.
  ///
  /// 수강권이 갱신되거나 삭제될 때 호출한다.
  Future<void> cancelForSubscription(String subscriptionId) async {
    for (final offset in _offsets) {
      await _scheduler.cancelNotification(_idFor(subscriptionId, offset));
    }
  }

  bool _isOffsetEnabled(
    SubscriptionExpiryReminderSettings settings,
    int offset,
  ) {
    switch (offset) {
      case 14:
        return settings.remindAtD14;
      case 7:
        return settings.remindAtD7;
      case 1:
        return settings.remindAtD1;
      case 0:
        return settings.remindAtD0;
      default:
        return false;
    }
  }

  String _idFor(String subscriptionId, int offset) =>
      'sub_expiry_${subscriptionId}_d$offset';

  AppNotification _build({
    required String teacherId,
    required Subscription subscription,
    required String studentName,
    required int offset,
    required DateTime scheduledAt,
    required DateTime now,
  }) {
    final isD0 = offset == 0;
    final type =
        isD0
            ? NotificationType.subscriptionExpired
            : NotificationType.subscriptionExpiringSoon;

    final (title, body) = _copyFor(studentName: studentName, offset: offset);

    return AppNotification(
      id: _idFor(subscription.id, offset),
      userId: teacherId,
      type: type,
      priority: type.defaultPriority,
      title: title,
      body: body,
      data: {
        'subscriptionId': subscription.id,
        'studentId': subscription.studentId,
        'offsetDays': offset,
      },
      createdAt: now,
      scheduledAt: scheduledAt,
    );
  }

  (String, String) _copyFor({
    required String studentName,
    required int offset,
  }) {
    switch (offset) {
      case 14:
        return ('수강권 만료 2주 전', '$studentName 학생 수강권이 14일 후 만료됩니다');
      case 7:
        return ('수강권 만료 1주 전', '$studentName 학생 수강권이 7일 후 만료 — 갱신 제안을 준비하세요');
      case 1:
        return ('내일 수강권 만료', '내일 $studentName 학생 수강권이 만료됩니다');
      case 0:
      default:
        return ('수강권 만료', '$studentName 학생 수강권이 오늘 만료되었습니다');
    }
  }
}
