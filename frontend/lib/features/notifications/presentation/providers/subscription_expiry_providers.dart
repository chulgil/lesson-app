import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../../students/presentation/providers/student_crud_provider.dart';
import '../../../subscription/domain/entities/subscription.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../../domain/entities/notification.dart';
import '../../domain/entities/subscription_expiry_reminder_settings.dart';
import '../../domain/services/notification_scheduler_service.dart';
import '../../domain/services/subscription_expiry_notification_service.dart';

part 'subscription_expiry_providers.g.dart';

/// `NotificationSchedulerService` 를 도메인 서비스의 작은 인터페이스에 맞추는 어댑터.
class _SchedulerAdapter implements SubscriptionExpiryScheduler {
  final NotificationSchedulerService _delegate;
  _SchedulerAdapter(this._delegate);

  @override
  Future<void> scheduleNotification(AppNotification notification) =>
      _delegate.scheduleNotification(notification);

  @override
  Future<void> cancelNotification(String id) =>
      _delegate.cancelNotification(id);
}

/// 수강권 만료 알림 서비스 싱글턴.
///
/// Spec: docs/specs/student/enrollment_management_ux_spec.md §3.4
@Riverpod(keepAlive: true)
SubscriptionExpiryNotificationService subscriptionExpiryNotificationService(
  SubscriptionExpiryNotificationServiceRef ref,
) {
  final scheduler = ref.watch(notificationSchedulerServiceProvider);
  return SubscriptionExpiryNotificationService(
    scheduler: _SchedulerAdapter(scheduler),
  );
}

/// 현재 설정값 — TODO: 설정 저장소 연동 시 교체. 현재는 defaults.
@riverpod
SubscriptionExpiryReminderSettings subscriptionExpiryReminderSettings(
  SubscriptionExpiryReminderSettingsRef ref,
) {
  return SubscriptionExpiryReminderSettings.defaults;
}

/// 교사의 전체 활성 수강권에 대해 만료 알림을 자동 재등록한다.
///
/// 수강권 목록 / 학생 목록 / 설정 중 하나라도 바뀌면 재계산.
/// 앱 상단에서 이 프로바이더를 `ref.listen` 하여 side-effect 만 트리거한다.
@riverpod
Future<int> subscriptionExpiryReminderRefresh(
  SubscriptionExpiryReminderRefreshRef ref,
) async {
  final teacherId = ref.watch(currentUserIdProvider);
  if (teacherId.isEmpty) return 0;

  final settings = ref.watch(subscriptionExpiryReminderSettingsProvider);
  if (!settings.enabled) return 0;

  final students = await ref.watch(studentsNotifierProvider.future);
  if (students.isEmpty) return 0;

  final nameMap = <String, String>{for (final s in students) s.id: s.name};

  final activeSubs = <Subscription>[];
  for (final student in students) {
    final subs = await ref.watch(
      studentSubscriptionsProvider(student.id).future,
    );
    activeSubs.addAll(
      subs.where(
        (s) =>
            s.status == SubscriptionStatus.active ||
            s.status == SubscriptionStatus.expiringSoon,
      ),
    );
  }

  if (activeSubs.isEmpty) return 0;

  final service = ref.read(subscriptionExpiryNotificationServiceProvider);
  await service.scheduleForSubscriptions(
    teacherId: teacherId,
    subscriptions: activeSubs,
    studentNameResolver: (sid) => nameMap[sid] ?? '학생',
    settings: settings,
  );

  return activeSubs.length;
}
