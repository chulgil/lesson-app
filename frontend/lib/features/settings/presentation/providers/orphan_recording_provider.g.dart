// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'orphan_recording_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$orphanedRecordingsWithDiagnosticHash() =>
    r'17c3eb4c30c1c5c6aca4aa797646e259faf9f9c9';

/// Provider for orphaned recordings with diagnostic info.
///
/// Copied from [orphanedRecordingsWithDiagnostic].
@ProviderFor(orphanedRecordingsWithDiagnostic)
final orphanedRecordingsWithDiagnosticProvider =
    AutoDisposeFutureProvider<OrphanRecordingsDiagnostic>.internal(
  orphanedRecordingsWithDiagnostic,
  name: r'orphanedRecordingsWithDiagnosticProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$orphanedRecordingsWithDiagnosticHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OrphanedRecordingsWithDiagnosticRef
    = AutoDisposeFutureProviderRef<OrphanRecordingsDiagnostic>;
String _$orphanedRecordingsHash() =>
    r'f697abeffb78644cb84f91022c1f36ccd1b6cacc';

/// Provider for orphaned recordings list.
///
/// Copied from [orphanedRecordings].
@ProviderFor(orphanedRecordings)
final orphanedRecordingsProvider =
    AutoDisposeFutureProvider<List<PracticeRecording>>.internal(
  orphanedRecordings,
  name: r'orphanedRecordingsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$orphanedRecordingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OrphanedRecordingsRef
    = AutoDisposeFutureProviderRef<List<PracticeRecording>>;
String _$allSectionsForAssignmentHash() =>
    r'498d20275c8164ed379a17762d1d0671622d9092';

/// Provider for all sections with their repertoire info (for assignment picker).
/// Returns all sections from all users (not filtered by studentId).
///
/// Copied from [allSectionsForAssignment].
@ProviderFor(allSectionsForAssignment)
final allSectionsForAssignmentProvider = AutoDisposeFutureProvider<
    List<({PracticeRepertoire repertoire, PracticeSection section})>>.internal(
  allSectionsForAssignment,
  name: r'allSectionsForAssignmentProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$allSectionsForAssignmentHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllSectionsForAssignmentRef = AutoDisposeFutureProviderRef<
    List<({PracticeRepertoire repertoire, PracticeSection section})>>;
String _$allRecordingsWithSectionInfoHash() =>
    r'22cc1742b450b1befe5ed9b787baecef502d8891';

/// Provider for all recordings with their section and repertoire info.
///
/// Copied from [allRecordingsWithSectionInfo].
@ProviderFor(allRecordingsWithSectionInfo)
final allRecordingsWithSectionInfoProvider = AutoDisposeFutureProvider<
    List<
        ({
          PracticeRecording recording,
          PracticeSection? section,
          PracticeRepertoire? repertoire
        })>>.internal(
  allRecordingsWithSectionInfo,
  name: r'allRecordingsWithSectionInfoProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$allRecordingsWithSectionInfoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllRecordingsWithSectionInfoRef = AutoDisposeFutureProviderRef<
    List<
        ({
          PracticeRecording recording,
          PracticeSection? section,
          PracticeRepertoire? repertoire
        })>>;
String _$orphanRecordingManagerHash() =>
    r'26392f163cbd2ae555ef8ab5fd8e2c03cc1083f6';

/// Notifier for managing orphan recording operations.
///
/// Copied from [OrphanRecordingManager].
@ProviderFor(OrphanRecordingManager)
final orphanRecordingManagerProvider =
    AutoDisposeAsyncNotifierProvider<OrphanRecordingManager, void>.internal(
  OrphanRecordingManager.new,
  name: r'orphanRecordingManagerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$orphanRecordingManagerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$OrphanRecordingManager = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
