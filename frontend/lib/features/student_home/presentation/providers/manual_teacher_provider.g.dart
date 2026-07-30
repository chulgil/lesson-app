// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manual_teacher_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$manualTeacherRepositoryHash() =>
    r'e52915a31fb10e51034b12833f23330337444918';

/// Repository provider for manual teachers — switches between Mock and Remote.
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
    r'1a4ed0097c9ff11a5c0454449cf96410d583da37';

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
