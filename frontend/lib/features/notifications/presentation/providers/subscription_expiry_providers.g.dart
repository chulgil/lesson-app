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
String _$subscriptionExpiryReminderSettingsHash() =>
    r'41253d5bc792d7963144f9cad432b964e3170a4f';

/// 현재 설정값 — TODO: 설정 저장소 연동 시 교체. 현재는 defaults.
///
/// Copied from [subscriptionExpiryReminderSettings].
@ProviderFor(subscriptionExpiryReminderSettings)
final subscriptionExpiryReminderSettingsProvider =
    AutoDisposeProvider<SubscriptionExpiryReminderSettings>.internal(
  subscriptionExpiryReminderSettings,
  name: r'subscriptionExpiryReminderSettingsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$subscriptionExpiryReminderSettingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SubscriptionExpiryReminderSettingsRef
    = AutoDisposeProviderRef<SubscriptionExpiryReminderSettings>;
String _$subscriptionExpiryReminderRefreshHash() =>
    r'e534c125fe3cff5311a9278eac6b30eafcd91e4f';

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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
