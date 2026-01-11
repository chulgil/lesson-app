// Provider for managing orphaned recordings (recordings not linked to any section).
//
// Part of the backup restore feature enhancement.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../practice/domain/entities/practice_repertoire.dart';
import '../../../practice/presentation/providers/practice_repertoire_crud_provider.dart';
import '../../../practice/presentation/providers/practice_repertoire_repository_provider.dart';

part 'orphan_recording_provider.g.dart';

/// Diagnostic info for orphan recordings screen.
class OrphanRecordingsDiagnostic {
  final int totalRecordingsInHive;
  final int totalSections;
  final int orphanCount;
  final int recordingsWithFiles;
  final int recordingsWithMissingFiles;
  final int recordingsWithMatchingSections;
  final List<PracticeRecording> orphans;

  OrphanRecordingsDiagnostic({
    required this.totalRecordingsInHive,
    required this.totalSections,
    required this.orphanCount,
    required this.recordingsWithFiles,
    required this.recordingsWithMissingFiles,
    required this.recordingsWithMatchingSections,
    required this.orphans,
  });
}

/// Provider for orphaned recordings with diagnostic info.
@riverpod
Future<OrphanRecordingsDiagnostic> orphanedRecordingsWithDiagnostic(Ref ref) async {
  final repository = ref.watch(practiceRepertoireRepositoryProvider);

  // Get diagnostic counts
  final stats = await repository.getRecordingStats();
  final orphans = await repository.getOrphanedRecordings();

  final totalRecordings = stats['totalRecordings'] ?? 0;
  final recordingsWithFiles = stats['recordingsWithFiles'] ?? 0;
  final recordingsWithMissingFiles = stats['recordingsWithMissingFiles'] ?? 0;

  return OrphanRecordingsDiagnostic(
    totalRecordingsInHive: totalRecordings,
    totalSections: stats['totalSections'] ?? 0,
    orphanCount: orphans.length,
    recordingsWithFiles: recordingsWithFiles,
    recordingsWithMissingFiles: recordingsWithMissingFiles,
    recordingsWithMatchingSections: recordingsWithFiles - orphans.length,
    orphans: orphans,
  );
}

/// Provider for orphaned recordings list.
@riverpod
Future<List<PracticeRecording>> orphanedRecordings(Ref ref) async {
  final repository = ref.watch(practiceRepertoireRepositoryProvider);
  return repository.getOrphanedRecordings();
}

/// Provider for all sections with their repertoire info (for assignment picker).
/// Returns all sections from all users (not filtered by studentId).
@riverpod
Future<List<({PracticeRepertoire repertoire, PracticeSection section})>>
    allSectionsForAssignment(Ref ref) async {
  final repository = ref.watch(practiceRepertoireRepositoryProvider);
  return repository.getAllSectionsForAssignment();
}

/// Provider for all recordings with their section and repertoire info.
@riverpod
Future<List<({PracticeRecording recording, PracticeSection? section, PracticeRepertoire? repertoire})>>
    allRecordingsWithSectionInfo(Ref ref) async {
  final repository = ref.watch(practiceRepertoireRepositoryProvider);
  return repository.getAllRecordingsWithSectionInfo();
}

/// Notifier for managing orphan recording operations.
@riverpod
class OrphanRecordingManager extends _$OrphanRecordingManager {
  @override
  FutureOr<void> build() {}

  /// Reload data from Hive, repair file paths, and refresh orphaned recordings list.
  Future<void> refreshFromHive() async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(practiceRepertoireRepositoryProvider);

      // First, repair any file paths that point to wrong app container
      final repairedCount = await repository.repairRecordingFilePaths();
      if (repairedCount > 0) {
        // Paths were repaired, data already reloaded
      } else {
        // No repairs needed, just reload
        await repository.reloadFromHive();
      }

      // Invalidate providers to refresh
      ref.invalidate(orphanedRecordingsProvider);
      ref.invalidate(orphanedRecordingsWithDiagnosticProvider);

      state = const AsyncValue.data(null);
    } catch (e) {
      debugPrint('Error refreshing from Hive: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Reassign a recording to a new section.
  Future<bool> reassignRecording(String recordingId, String newSectionId) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(practiceRepertoireRepositoryProvider);
      await repository.reassignRecording(recordingId, newSectionId);

      // Invalidate recording-related providers to refresh
      ref.invalidate(orphanedRecordingsProvider);
      ref.invalidate(orphanedRecordingsWithDiagnosticProvider);
      ref.invalidate(allRecordingsWithSectionInfoProvider);

      // Invalidate the target section provider so section detail screen refreshes
      ref.invalidate(sectionProvider(newSectionId));

      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      debugPrint('Error reassigning recording: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  /// Delete a recording permanently.
  Future<bool> deleteRecording(String recordingId) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(practiceRepertoireRepositoryProvider);
      await repository.deleteRecording(recordingId);

      // Invalidate recording-related providers to refresh
      ref.invalidate(orphanedRecordingsProvider);
      ref.invalidate(orphanedRecordingsWithDiagnosticProvider);
      ref.invalidate(allRecordingsWithSectionInfoProvider);

      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      debugPrint('Error deleting recording: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  /// Import a recording from external file.
  Future<bool> importRecording(String sourceFilePath, int durationSeconds) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(practiceRepertoireRepositoryProvider);
      await repository.importRecording(sourceFilePath, durationSeconds);

      // Invalidate recording-related providers to refresh
      ref.invalidate(orphanedRecordingsProvider);
      ref.invalidate(orphanedRecordingsWithDiagnosticProvider);
      ref.invalidate(allRecordingsWithSectionInfoProvider);

      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      debugPrint('Error importing recording: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }
}
