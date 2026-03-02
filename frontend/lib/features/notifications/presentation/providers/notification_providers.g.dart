// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notificationApiRepositoryHash() =>
    r'7353adb52930040f49f8a22bb1bdeae5275338fa';

/// Notification repository provider (only used for remote mode).
///
/// Copied from [notificationApiRepository].
@ProviderFor(notificationApiRepository)
final notificationApiRepositoryProvider =
    Provider<NotificationRepository?>.internal(
  notificationApiRepository,
  name: r'notificationApiRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationApiRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotificationApiRepositoryRef = ProviderRef<NotificationRepository?>;
String _$notificationServiceHash() =>
    r'86fee7f1e80c839a0014f1d8283c4fb9e26a098f';

/// Provider for the notification service
///
/// Copied from [notificationService].
@ProviderFor(notificationService)
final notificationServiceProvider =
    AutoDisposeProvider<LocalNotificationService>.internal(
  notificationService,
  name: r'notificationServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotificationServiceRef
    = AutoDisposeProviderRef<LocalNotificationService>;
String _$practiceReminderSchedulerHash() =>
    r'f388c881d6a641da18b453517714def7184fc9cf';

/// Provider for practice reminder scheduler
///
/// Copied from [practiceReminderScheduler].
@ProviderFor(practiceReminderScheduler)
final practiceReminderSchedulerProvider =
    AutoDisposeProvider<PracticeReminderScheduler>.internal(
  practiceReminderScheduler,
  name: r'practiceReminderSchedulerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$practiceReminderSchedulerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PracticeReminderSchedulerRef
    = AutoDisposeProviderRef<PracticeReminderScheduler>;
String _$connectionNotificationServiceHash() =>
    r'b1391822b0f1b87683afdc51f61b1a4ddac01507';

/// Provider for connection notification service
///
/// Copied from [connectionNotificationService].
@ProviderFor(connectionNotificationService)
final connectionNotificationServiceProvider =
    AutoDisposeProvider<ConnectionNotificationService>.internal(
  connectionNotificationService,
  name: r'connectionNotificationServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$connectionNotificationServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ConnectionNotificationServiceRef
    = AutoDisposeProviderRef<ConnectionNotificationService>;
String _$proposalNotificationServiceHash() =>
    r'3e5db6623f296dacd657222e0182961aee51c83e';

/// Provider for proposal notification service
///
/// Copied from [proposalNotificationService].
@ProviderFor(proposalNotificationService)
final proposalNotificationServiceProvider =
    AutoDisposeProvider<ProposalNotificationService>.internal(
  proposalNotificationService,
  name: r'proposalNotificationServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$proposalNotificationServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProposalNotificationServiceRef
    = AutoDisposeProviderRef<ProposalNotificationService>;
String _$userNotificationsHash() => r'7458c3c54f429d3ec639c0951e4f0770de1cbb80';

/// Provider for user's notifications list
///
/// Copied from [userNotifications].
@ProviderFor(userNotifications)
final userNotificationsProvider =
    AutoDisposeFutureProvider<List<AppNotification>>.internal(
  userNotifications,
  name: r'userNotificationsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userNotificationsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserNotificationsRef
    = AutoDisposeFutureProviderRef<List<AppNotification>>;
String _$unreadNotificationCountHash() =>
    r'b141f148010c268b94f20f01579a288a73fa1ffe';

/// Provider for unread notification count (for badge)
///
/// Copied from [unreadNotificationCount].
@ProviderFor(unreadNotificationCount)
final unreadNotificationCountProvider = AutoDisposeProvider<int>.internal(
  unreadNotificationCount,
  name: r'unreadNotificationCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$unreadNotificationCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UnreadNotificationCountRef = AutoDisposeProviderRef<int>;
String _$studentNotificationSettingsNotifierHash() =>
    r'1ba126cc1f0e619eb2a9e35832cfc9ac602d1103';

/// Provider for student notification settings
/// TODO: Load from Hive storage
///
/// Copied from [StudentNotificationSettingsNotifier].
@ProviderFor(StudentNotificationSettingsNotifier)
final studentNotificationSettingsNotifierProvider = AutoDisposeNotifierProvider<
    StudentNotificationSettingsNotifier, StudentNotificationSettings>.internal(
  StudentNotificationSettingsNotifier.new,
  name: r'studentNotificationSettingsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$studentNotificationSettingsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$StudentNotificationSettingsNotifier
    = AutoDisposeNotifier<StudentNotificationSettings>;
String _$teacherNotificationSettingsNotifierHash() =>
    r'3cc1ec9b32a722f0236deb69e6f2cb53fe694e72';

/// Provider for teacher notification settings
/// TODO: Load from Hive storage
///
/// Copied from [TeacherNotificationSettingsNotifier].
@ProviderFor(TeacherNotificationSettingsNotifier)
final teacherNotificationSettingsNotifierProvider = AutoDisposeNotifierProvider<
    TeacherNotificationSettingsNotifier, TeacherNotificationSettings>.internal(
  TeacherNotificationSettingsNotifier.new,
  name: r'teacherNotificationSettingsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$teacherNotificationSettingsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TeacherNotificationSettingsNotifier
    = AutoDisposeNotifier<TeacherNotificationSettings>;
String _$notificationActionsHash() =>
    r'1c405e5a278e513847f77d920a193f970c40d892';

/// Notifier for notification actions (mark as read, delete, etc.)
///
/// Copied from [NotificationActions].
@ProviderFor(NotificationActions)
final notificationActionsProvider =
    AutoDisposeNotifierProvider<NotificationActions, void>.internal(
  NotificationActions.new,
  name: r'notificationActionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationActionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NotificationActions = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
