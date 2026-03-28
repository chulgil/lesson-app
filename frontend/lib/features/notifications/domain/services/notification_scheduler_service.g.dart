// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_scheduler_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notificationSchedulerServiceHash() =>
    r'6e6c4197ea64610ffced172f7b23fb97707e72ff';

/// Service for scheduling future notifications.
///
/// Handles:
/// - Scheduling notifications for future delivery
/// - Cancelling scheduled notifications
/// - Managing notification queue
///
/// Note: In production, this would integrate with:
/// - flutter_local_notifications for local scheduling
/// - Firebase Cloud Messaging for push notifications
/// - Backend scheduler for reliable delivery
///
/// Copied from [notificationSchedulerService].
@ProviderFor(notificationSchedulerService)
final notificationSchedulerServiceProvider =
    Provider<NotificationSchedulerService>.internal(
  notificationSchedulerService,
  name: r'notificationSchedulerServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationSchedulerServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef NotificationSchedulerServiceRef
    = ProviderRef<NotificationSchedulerService>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
