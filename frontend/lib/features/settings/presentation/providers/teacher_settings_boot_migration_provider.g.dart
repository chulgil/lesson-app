// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher_settings_boot_migration_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$teacherSettingsBootMigrationHash() =>
    r'a5fc0a044ec3ac58dd7fe13956f72a6314382e58';

/// Resolves to `true` once the W1 migration has run (or was already done).
///
/// Returns `false` only on a hard failure (Hive unavailable, repository
/// threw) so callers can choose to retry on the next boot.
///
/// Copied from [teacherSettingsBootMigration].
@ProviderFor(teacherSettingsBootMigration)
final teacherSettingsBootMigrationProvider = FutureProvider<bool>.internal(
  teacherSettingsBootMigration,
  name: r'teacherSettingsBootMigrationProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$teacherSettingsBootMigrationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TeacherSettingsBootMigrationRef = FutureProviderRef<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
