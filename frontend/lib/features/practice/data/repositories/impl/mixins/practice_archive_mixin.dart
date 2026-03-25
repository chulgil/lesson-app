import 'dart:io';

import '../../../../domain/repositories/practice_repertoire_repository.dart';
import '../../../../domain/entities/practice_repertoire.dart';
import '../practice_repository_base.dart';

/// Mixin for archive operations
mixin PracticeArchiveMixin on PracticeRepositoryBase
    implements PracticeRepertoireRepository {
  @override
  Future<List<PracticeRepertoire>> getActiveRepertoires(
      String studentId) async {
    await ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 200));
    final reps = repertoires[studentId] ?? [];
    return reps.where((r) => !r.isArchived).toList();
  }

  @override
  Future<List<PracticeRepertoire>> getArchivedRepertoires(
      String studentId) async {
    await ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 200));
    final reps = repertoires[studentId] ?? [];
    return reps.where((r) => r.isArchived).toList();
  }

  @override
  Future<PracticeRepertoire> archiveRepertoire(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();

    for (final reps in repertoires.values) {
      final index = reps.indexWhere((r) => r.id == id);
      if (index != -1) {
        final updated = reps[index].copyWith(
          isArchived: true,
          archivedAt: now,
          updatedAt: now,
        );
        reps[index] = updated;

        // Persist to Hive
        await saveRepertoiresToHive();

        return updated;
      }
    }
    throw Exception('Repertoire not found');
  }

  @override
  Future<PracticeRepertoire> restoreRepertoire(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();

    for (final reps in repertoires.values) {
      final index = reps.indexWhere((r) => r.id == id);
      if (index != -1) {
        final updated = reps[index].copyWith(
          isArchived: false,
          updatedAt: now,
        );
        // Clear archivedAt by recreating
        final cleared = PracticeRepertoire(
          id: updated.id,
          studentId: updated.studentId,
          name: updated.name,
          description: updated.description,
          startDate: updated.startDate,
          endDate: updated.endDate,
          sections: updated.sections,
          createdAt: updated.createdAt,
          updatedAt: now,
          isArchived: false,
          archivedAt: null,
        );
        reps[index] = cleared;

        // Persist to Hive
        await saveRepertoiresToHive();

        return cleared;
      }
    }
    throw Exception('Repertoire not found');
  }

  @override
  Future<void> permanentlyDeleteRepertoire(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));

    for (final reps in repertoires.values) {
      final index = reps.indexWhere((r) => r.id == id);
      if (index != -1) {
        // Delete all recordings associated with this repertoire
        final repertoire = reps[index];
        for (final section in repertoire.sections) {
          for (final recording in section.recordings) {
            try {
              final audioFile = File(recording.filePath);
              if (await audioFile.exists()) {
                await audioFile.delete();
              }
              final trimFile = File('${recording.filePath}.trim');
              if (await trimFile.exists()) {
                await trimFile.delete();
              }
              // Delete from Hive
              final box = await practiceRecordingsBox;
              await box.delete(recording.id);
            } catch (e) {
              // Ignore errors deleting recording file
            }
          }
        }
        reps.removeAt(index);

        // Persist to Hive
        await saveRepertoiresToHive();

        return;
      }
    }
  }
}
