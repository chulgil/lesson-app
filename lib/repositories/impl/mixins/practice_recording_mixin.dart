import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../practice_repertoire_repository.dart';
import '../../../models/practice_repertoire.dart';
import '../practice_repository_base.dart';

/// Mixin for recording operations
mixin PracticeRecordingMixin on PracticeRepositoryBase
    implements PracticeRepertoireRepository {
  @override
  Future<PracticeRecording> createRecording(PracticeRecording recording) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newRecording = PracticeRecording(
      id: uuid.v4(),
      sectionId: recording.sectionId,
      filePath: recording.filePath,
      durationSeconds: recording.durationSeconds,
      bpm: recording.bpm,
      isRepresentative: recording.isRepresentative,
      createdAt: DateTime.now(),
    );

    // Save to Hive for persistence
    try {
      final box = await practiceRecordingsBox;
      await box.put(newRecording.id, newRecording);
      await box.flush();
    } catch (e) {
      // Ignore errors persisting recording
    }

    // Find and update the section in memory
    for (final reps in repertoires.values) {
      for (int i = 0; i < reps.length; i++) {
        final repertoire = reps[i];
        final sectionIndex =
            repertoire.sections.indexWhere((s) => s.id == recording.sectionId);
        if (sectionIndex != -1) {
          final section = repertoire.sections[sectionIndex];

          // If this is marked as representative, unmark others
          List<PracticeRecording> updatedRecordings;
          if (newRecording.isRepresentative) {
            updatedRecordings = section.recordings
                .map((r) => r.copyWith(isRepresentative: false))
                .toList();
          } else {
            updatedRecordings = List.from(section.recordings);
          }
          updatedRecordings.add(newRecording);

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

          return newRecording;
        }
      }
    }
    throw Exception('Section not found');
  }

  @override
  Future<void> deleteRecording(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Get file path before deleting from Hive
    String? filePath;
    try {
      final box = await practiceRecordingsBox;
      final recording = box.get(id);
      if (recording != null) {
        filePath = recording.filePath;
      }
    } catch (e) {
      // Ignore errors getting recording for file deletion
    }

    // Delete actual audio file and trim metadata
    if (filePath != null) {
      try {
        final audioFile = File(filePath);
        if (await audioFile.exists()) {
          await audioFile.delete();
        }
        // Also delete .trim metadata file if exists
        final trimFile = File('$filePath.trim');
        if (await trimFile.exists()) {
          await trimFile.delete();
        }
      } catch (e) {
        // Ignore errors deleting audio file
      }
    }

    // Delete from Hive
    try {
      final box = await practiceRecordingsBox;
      await box.delete(id);
      await box.flush();
    } catch (e) {
      // Ignore errors deleting recording from Hive
    }

    // Delete from memory
    for (final reps in repertoires.values) {
      for (int i = 0; i < reps.length; i++) {
        final repertoire = reps[i];
        for (int j = 0; j < repertoire.sections.length; j++) {
          final section = repertoire.sections[j];
          final recordingIndex =
              section.recordings.indexWhere((r) => r.id == id);
          if (recordingIndex != -1) {
            final deletedRecording = section.recordings[recordingIndex];
            final wasRepresentative = deletedRecording.isRepresentative;

            var updatedRecordings =
                List<PracticeRecording>.from(section.recordings);
            updatedRecordings.removeAt(recordingIndex);

            // Auto-select newest recording as representative if deleted was representative
            if (wasRepresentative && updatedRecordings.isNotEmpty) {
              // Sort by createdAt descending and set newest as representative
              updatedRecordings
                  .sort((a, b) => b.createdAt.compareTo(a.createdAt));
              final newestId = updatedRecordings.first.id;
              updatedRecordings = updatedRecordings
                  .map((r) => r.copyWith(isRepresentative: r.id == newestId))
                  .toList();
            }

            final updatedSection = section.copyWith(
              recordings: updatedRecordings,
              updatedAt: DateTime.now(),
            );
            final updatedSections =
                List<PracticeSection>.from(repertoire.sections);
            updatedSections[j] = updatedSection;
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
    }
  }

  @override
  Future<PracticeSection> setRepresentativeRecording(
      String sectionId, String recordingId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    for (final reps in repertoires.values) {
      for (int i = 0; i < reps.length; i++) {
        final repertoire = reps[i];
        final sectionIndex =
            repertoire.sections.indexWhere((s) => s.id == sectionId);
        if (sectionIndex != -1) {
          final section = repertoire.sections[sectionIndex];
          final updatedRecordings = section.recordings
              .map((r) => r.copyWith(isRepresentative: r.id == recordingId))
              .toList();
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

          return updatedSection;
        }
      }
    }
    throw Exception('Section not found');
  }

  @override
  Future<PracticeRecording> importRecording(
      String sourceFilePath, int durationSeconds) async {
    await ensureInitialized();

    // Create 'imported' directory for imported recordings
    final appDir = await getApplicationDocumentsDirectory();
    final importedDir = Directory('${appDir.path}/recordings/imported');
    if (!await importedDir.exists()) {
      await importedDir.create(recursive: true);
    }

    // Copy file to app's recordings directory
    final sourceFile = File(sourceFilePath);
    final extension = sourceFilePath.split('.').last;
    final newFileName = '${uuid.v4()}.$extension';
    final newFilePath = '${importedDir.path}/$newFileName';

    await sourceFile.copy(newFilePath);

    // Create new recording entry with 'imported' as sectionId (will be orphaned)
    final newRecording = PracticeRecording(
      id: uuid.v4(),
      sectionId:
          'imported_${DateTime.now().millisecondsSinceEpoch}', // Unique orphan ID
      filePath: newFilePath,
      durationSeconds: durationSeconds,
      bpm: null,
      isRepresentative: false,
      createdAt: DateTime.now(),
    );

    // Save to Hive
    final box = await practiceRecordingsBox;
    await box.put(newRecording.id, newRecording);
    await box.flush();

    return newRecording;
  }
}
