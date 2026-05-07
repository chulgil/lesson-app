// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_preferences_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notificationPreferencesNotifierHash() =>
    r'9d4d7c050ccf1a633d05efba0921a47b3800b78e';

/// Hive-backed provider for per-category notification preferences.
///
/// keepAlive: app-wide setting, should not be disposed during session.
///
/// Copied from [NotificationPreferencesNotifier].
@ProviderFor(NotificationPreferencesNotifier)
final notificationPreferencesNotifierProvider = NotifierProvider<
    NotificationPreferencesNotifier, NotificationPreferences>.internal(
  NotificationPreferencesNotifier.new,
  name: r'notificationPreferencesNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationPreferencesNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NotificationPreferencesNotifier = Notifier<NotificationPreferences>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
