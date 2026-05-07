// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_stats_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$studentsByStatusHash() => r'92e3da08bc85cafbf34f84a09db61e671dcd5806';

/// Students grouped by practice status
///
/// Copied from [studentsByStatus].
@ProviderFor(studentsByStatus)
final studentsByStatusProvider =
    Provider<AsyncValue<Map<PracticeStatus, List<Student>>>>.internal(
  studentsByStatus,
  name: r'studentsByStatusProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$studentsByStatusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef StudentsByStatusRef
    = ProviderRef<AsyncValue<Map<PracticeStatus, List<Student>>>>;
String _$studentCountsHash() => r'8f299504bd776ccd908b0cf41d5a3fb51b79bb0a';

/// Students count by status for dashboard
///
/// Copied from [studentCounts].
@ProviderFor(studentCounts)
final studentCountsProvider = Provider<AsyncValue<Map<String, int>>>.internal(
  studentCounts,
  name: r'studentCountsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$studentCountsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef StudentCountsRef = ProviderRef<AsyncValue<Map<String, int>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
