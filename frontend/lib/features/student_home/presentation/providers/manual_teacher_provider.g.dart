// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manual_teacher_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$manualTeacherRepositoryHash() =>
    r'1377f25775bcb51e6cbca3a3d7e9774d001ec356';

/// Repository provider for manual teachers.
///
/// Copied from [manualTeacherRepository].
@ProviderFor(manualTeacherRepository)
final manualTeacherRepositoryProvider =
    Provider<MockManualTeacherRepository>.internal(
  manualTeacherRepository,
  name: r'manualTeacherRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$manualTeacherRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ManualTeacherRepositoryRef = ProviderRef<MockManualTeacherRepository>;
String _$manualTeacherNotifierHash() =>
    r'e7362e2d047cf27c87ec968fe1c786a02438e1b4';

/// AsyncNotifier for manual teacher CRUD operations.
///
/// Copied from [ManualTeacherNotifier].
@ProviderFor(ManualTeacherNotifier)
final manualTeacherNotifierProvider =
    AsyncNotifierProvider<ManualTeacherNotifier, List<ManualTeacher>>.internal(
  ManualTeacherNotifier.new,
  name: r'manualTeacherNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$manualTeacherNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ManualTeacherNotifier = AsyncNotifier<List<ManualTeacher>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
