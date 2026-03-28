// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manual_teacher_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$manualTeacherRepositoryHash() =>
    r'9d3d4084365ff42d62f29baa4626ca12f02decf4';

/// Repository provider for manual teachers.
///
/// Copied from [manualTeacherRepository].
@ProviderFor(manualTeacherRepository)
final manualTeacherRepositoryProvider =
    Provider<ManualTeacherRepository>.internal(
  manualTeacherRepository,
  name: r'manualTeacherRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$manualTeacherRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ManualTeacherRepositoryRef = ProviderRef<ManualTeacherRepository>;
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
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
