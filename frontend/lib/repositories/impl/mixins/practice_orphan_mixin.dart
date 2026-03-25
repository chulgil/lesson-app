import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../practice_repertoire_repository.dart';
import '../../../features/practice/domain/entities/practice_repertoire.dart';
import '../practice_repository_base.dart';

/// Mixin for orphan recording operations
mixin PracticeOrphanMixin on PracticeRepositoryBase
    implements PracticeRepertoireRepository {
  @override
  Future<List<PracticeRecording>> getOrphanedRecordings() async {
    await ensureInitialized();

    // First, try to repair file paths
    await repairRecordingFilePaths();

    // Get all existing section IDs
    final existingSectionIds = <String>{};
    for (final reps in repertoires.values) {
      for (final repertoire in reps) {
        for (final section in repertoire.sections) {
          existingSectionIds.add(section.id);
        }
      }
    }

    // Find recordings whose sectionId doesn't match any existing section
    final orphanedRecordings = <PracticeRecording>[];
    try {
      final box = await practiceRecordingsBox;

      for (final recording in box.values) {
        final hasMatchingSection =
            existingSectionIds.contains(recording.sectionId);
        if (!hasMatchingSection) {
          orphanedRecordings.add(recording);
        }
      }
    } catch (e) {
      // Ignore errors getting orphaned recordings
    }

    // Sort by creation date (newest first)
    orphanedRecordings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return orphanedRecordings;
  }

  @override
  Future<void> reassignRecording(
      String recordingId, String newSectionId) async {
    await ensureInitialized();

    // Get the recording from Hive
    final box = await practiceRecordingsBox;
    final recording = box.get(recordingId);
    if (recording == null) {
      throw Exception('Recording not found');
    }

    // Create updated recording with new sectionId
    final updatedRecording = PracticeRecording(
      id: recording.id,
      sectionId: newSectionId,
      filePath: recording.filePath,
      durationSeconds: recording.durationSeconds,
      bpm: recording.bpm,
      isRepresentative: false, // Reset representative status
      createdAt: recording.createdAt,
    );

    // Update in Hive
    await box.put(recordingId, updatedRecording);
    await box.flush();

    // Add to section in memory
    for (final reps in repertoires.values) {
      for (int i = 0; i < reps.length; i++) {
        final repertoire = reps[i];
        final sectionIndex =
            repertoire.sections.indexWhere((s) => s.id == newSectionId);
        if (sectionIndex != -1) {
          final section = repertoire.sections[sectionIndex];
          final updatedRecordings =
              List<PracticeRecording>.from(section.recordings)
                ..add(updatedRecording);
          final updatedSection = section.copyWith(
            recordings: updatedRecordings,
            updatedAt: DateTime.now(),
          );
          final updatedSections =
              List<PracticeSection>.from(repertoire.sections);
          updatedSections[sectionIndex] = updatedSection;
          reps[i] = repertoire.copyWith(
            sections: updatedSections,
            updatedAt: DateTime.now(),
          );

          // Persist to Hive
          await saveRepertoiresToHive();

          return;
        }
      }
    }
    throw Exception('Section not found');
  }

  @override
  Future<List<({PracticeRepertoire repertoire, PracticeSection section})>>
      getAllSectionsWithRepertoire(String studentId) async {
    await ensureInitialized();

    final result =
        <({PracticeRepertoire repertoire, PracticeSection section})>[];
    final reps = repertoires[studentId] ?? [];

    for (final repertoire in reps) {
      if (repertoire.isArchived) continue; // Skip archived repertoires
      for (final section in repertoire.sections) {
        result.add((repertoire: repertoire, section: section));
      }
    }

    return result;
  }

  @override
  Future<List<({PracticeRepertoire repertoire, PracticeSection section})>>
      getAllSectionsForAssignment() async {
    await ensureInitialized();

    final result =
        <({PracticeRepertoire repertoire, PracticeSection section})>[];

    // Iterate through all users' repertoires
    for (final reps in repertoires.values) {
      for (final repertoire in reps) {
        if (repertoire.isArchived) continue; // Skip archived repertoires
        for (final section in repertoire.sections) {
          result.add((repertoire: repertoire, section: section));
        }
      }
    }

    return result;
  }

  @override
  Future<
      List<
          ({
            PracticeRecording recording,
            PracticeSection? section,
            PracticeRepertoire? repertoire
          })>> getAllRecordingsWithSectionInfo() async {
    await ensureInitialized();

    final box = await practiceRecordingsBox;
    final allRecordings = box.values.toList();

    // Build a map of sectionId -> (section, repertoire) for quick lookup
    final sectionMap =
        <String, ({PracticeSection section, PracticeRepertoire repertoire})>{};
    for (final reps in repertoires.values) {
      for (final repertoire in reps) {
        for (final section in repertoire.sections) {
          sectionMap[section.id] = (section: section, repertoire: repertoire);
        }
      }
    }

    // Build result with section info
    final result = <({
      PracticeRecording recording,
      PracticeSection? section,
      PracticeRepertoire? repertoire
    })>[];
    for (final recording in allRecordings) {
      final sectionInfo = sectionMap[recording.sectionId];
      result.add((
        recording: recording,
        section: sectionInfo?.section,
        repertoire: sectionInfo?.repertoire,
      ));
    }

    // Sort by createdAt descending (newest first)
    result.sort((a, b) => b.recording.createdAt.compareTo(a.recording.createdAt));

    return result;
  }

  @override
  Future<void> reloadFromHive() async {
    // Clear in-memory cache
    repertoires.clear();
    isInitialized = false;

    // Reload from Hive
    await loadPersistedRepertoires();
    await loadPersistedRecordings();
    isInitialized = true;
  }

  @override
  Future<int> repairRecordingFilePaths() async {
    await ensureInitialized();

    final box = await practiceRecordingsBox;
    final docsDir = await getApplicationDocumentsDirectory();
    final currentDocsPath = docsDir.path;
    int repairedCount = 0;

    for (final recording in box.values.toList()) {
      final originalPath = recording.filePath;

      // Check if path needs repair (points to different app container)
      if (!originalPath.startsWith(currentDocsPath)) {
        // Find 'recordings/' in the path and rebuild
        final recordingsIndex = originalPath.indexOf('recordings/');
        if (recordingsIndex != -1) {
          final relativePath = originalPath.substring(recordingsIndex);
          final newPath = '$currentDocsPath/$relativePath';

          // Check if file exists at new path
          final newFile = File(newPath);
          if (await newFile.exists()) {
            // Update recording with correct path
            final updatedRecording = PracticeRecording(
              id: recording.id,
              sectionId: recording.sectionId,
              filePath: newPath,
              durationSeconds: recording.durationSeconds,
              bpm: recording.bpm,
              isRepresentative: recording.isRepresentative,
              createdAt: recording.createdAt,
            );
            await box.put(recording.id, updatedRecording);
            repairedCount++;
          }
        }
      }
    }

    if (repairedCount > 0) {
      await box.flush();
      // Reload to update in-memory cache
      await reloadFromHive();
    }

    return repairedCount;
  }

  @override
  Future<Map<String, int>> getRecordingStats() async {
    await ensureInitialized();

    // Count total sections
    int totalSections = 0;
    for (final reps in repertoires.values) {
      for (final repertoire in reps) {
        totalSections += repertoire.sections.length;
      }
    }

    // Count total recordings in Hive
    final box = await practiceRecordingsBox;
    final totalRecordings = box.length;

    // Count recordings with files that exist
    int recordingsWithFiles = 0;
    int recordingsWithMissingFiles = 0;
    for (final recording in box.values) {
      final file = File(recording.filePath);
      if (await file.exists()) {
        recordingsWithFiles++;
      } else {
        recordingsWithMissingFiles++;
      }
    }

    return {
      'totalRecordings': totalRecordings,
      'totalSections': totalSections,
      'recordingsWithFiles': recordingsWithFiles,
      'recordingsWithMissingFiles': recordingsWithMissingFiles,
    };
  }
}
