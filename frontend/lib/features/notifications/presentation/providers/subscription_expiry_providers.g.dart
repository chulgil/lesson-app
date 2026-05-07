// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_expiry_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$subscriptionExpiryNotificationServiceHash() =>
    r'5c3db9824becf3612134acc4e55ff721b9a592f1';

/// 수강권 만료 알림 서비스 싱글턴.
///
/// Spec: docs/specs/student/enrollment_management_ux_spec.md §3.4
///
/// Copied from [subscriptionExpiryNotificationService].
@ProviderFor(subscriptionExpiryNotificationService)
final subscriptionExpiryNotificationServiceProvider =
    Provider<SubscriptionExpiryNotificationService>.internal(
  subscriptionExpiryNotificationService,
  name: r'subscriptionExpiryNotificationServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$subscriptionExpiryNotificationServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SubscriptionExpiryNotificationServiceRef
    = ProviderRef<SubscriptionExpiryNotificationService>;
String _$subscriptionExpiryReminderRefreshHash() =>
    r'a195fd42d2902c94a7e8398c89f8c3c40d0670dc';

/// 교사의 전체 활성 수강권에 대해 만료 알림을 자동 재등록한다.
///
/// 수강권 목록 / 학생 목록 / 설정 중 하나라도 바뀌면 재계산.
/// 앱 상단에서 이 프로바이더를 `ref.listen` 하여 side-effect 만 트리거한다.
///
/// Copied from [subscriptionExpiryReminderRefresh].
@ProviderFor(subscriptionExpiryReminderRefresh)
final subscriptionExpiryReminderRefreshProvider =
    AutoDisposeFutureProvider<int>.internal(
  subscriptionExpiryReminderRefresh,
  name: r'subscriptionExpiryReminderRefreshProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$subscriptionExpiryReminderRefreshHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SubscriptionExpiryReminderRefreshRef
    = AutoDisposeFutureProviderRef<int>;
String _$subscriptionExpiryReminderSettingsNotifierHash() =>
    r'01abc172eafe8a91139fd1b8b32e0b09d063df44';

/// 수강권 만료 알림 설정 — Hive `settings` 박스에 JSON 영속.
///
/// Spec: docs/specs/student/enrollment_management_ux_spec.md §3.4
///
/// Phase 5b: master + D14/D7/D1/D0 개별 토글 제공.
///
/// Copied from [SubscriptionExpiryReminderSettingsNotifier].
@ProviderFor(SubscriptionExpiryReminderSettingsNotifier)
final subscriptionExpiryReminderSettingsNotifierProvider = NotifierProvider<
    SubscriptionExpiryReminderSettingsNotifier,
    SubscriptionExpiryReminderSettings>.internal(
  SubscriptionExpiryReminderSettingsNotifier.new,
  name: r'subscriptionExpiryReminderSettingsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$subscriptionExpiryReminderSettingsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SubscriptionExpiryReminderSettingsNotifier
    = Notifier<SubscriptionExpiryReminderSettings>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
