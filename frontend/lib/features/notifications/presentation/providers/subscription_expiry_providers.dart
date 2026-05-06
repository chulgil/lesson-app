import 'dart:async';
import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/auth_facade.dart';
import '../../../students/students_facade.dart';
import '../../../subscription/subscription_facade.dart';
import '../../domain/entities/notification.dart';
import '../../domain/entities/subscription_expiry_reminder_settings.dart';
import '../../domain/services/notification_scheduler_service.dart';
import '../../domain/services/subscription_expiry_notification_service.dart';
import 'notification_providers.dart';

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

/// 수강권 만료 알림 설정 — Hive `settings` 박스에 JSON 영속.
///
/// Spec: docs/specs/student/enrollment_management_ux_spec.md §3.4
///
/// Phase 5b: master + D14/D7/D1/D0 개별 토글 제공.
final subscriptionExpiryReminderSettingsProvider =
    subscriptionExpiryReminderSettingsNotifierProvider;

@Riverpod(keepAlive: true)
class SubscriptionExpiryReminderSettingsNotifier
    extends _$SubscriptionExpiryReminderSettingsNotifier {
  static const _boxName = 'settings';
  static const _hiveKey = 'subscription_expiry_reminder_settings';

  @override
  SubscriptionExpiryReminderSettings build() {
    unawaited(_loadFromHive());
    return SubscriptionExpiryReminderSettings.defaults;
  }

  Future<void> _loadFromHive() async {
    try {
      final box = await Hive.openBox(_boxName);
      final raw = box.get(_hiveKey) as String?;
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        state = SubscriptionExpiryReminderSettings.fromJson(map);
      }
    } catch (_) {
      // Silently default to defaults
    }
  }

  Future<void> _persist() async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_hiveKey, jsonEncode(state.toJson()));
    } catch (_) {
      // Persist failure is non-critical
    }
  }

  void toggleEnabled(bool value) {
    state = state.copyWith(enabled: value);
    _persist();
  }

  void toggleD14(bool value) {
    state = state.copyWith(remindAtD14: value);
    _persist();
  }

  void toggleD7(bool value) {
    state = state.copyWith(remindAtD7: value);
    _persist();
  }

  void toggleD1(bool value) {
    state = state.copyWith(remindAtD1: value);
    _persist();
  }

  void toggleD0(bool value) {
    state = state.copyWith(remindAtD0: value);
    _persist();
  }
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
