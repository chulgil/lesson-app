// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
