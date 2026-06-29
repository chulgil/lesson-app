import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/recording.dart';
import '../../domain/repositories/recording_repository.dart';

/// Hive-based implementation of RecordingRepository.
class HiveRecordingRepository implements RecordingRepository {
  static const String _boxName = 'recordings';

  Box<Recording>? _box;

  Future<Box<Recording>> get _recordingsBox async {
    if (_box != null && _box!.isOpen) {
      return _box!;
    }
    _box = await Hive.openBox<Recording>(_boxName);
    return _box!;
  }

  @override
  Future<List<Recording>> getRecordingsForRepertoire(
    String repertoireId,
  ) async {
    final box = await _recordingsBox;
    final recordings =
        box.values.where((r) => r.repertoireId == repertoireId).toList();

    recordings.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    return recordings;
  }

  @override
  Future<List<Recording>> getRecordingsForStudent(String studentId) async {
    final box = await _recordingsBox;
    final recordings =
        box.values.where((r) => r.studentId == studentId).toList();

    recordings.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    return recordings;
  }

  @override
  Future<Recording?> getRecording(String id) async {
    final box = await _recordingsBox;
    return box.get(id);
  }

  @override
  Future<Recording?> getRepresentativeRecording(String repertoireId) async {
    final box = await _recordingsBox;
    try {
      return box.values.firstWhere(
        (r) => r.repertoireId == repertoireId && r.isRepresentative,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveRecording(Recording recording) async {
    final box = await _recordingsBox;

    await box.put(recording.id, recording);
    await box.flush();
  }

  @override
  Future<void> deleteRecording(String id) async {
    final box = await _recordingsBox;
    final recording = box.get(id);

    if (recording != null) {
      try {
        final file = File(recording.localPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Ignore file deletion errors.
      }

      await box.delete(id);

      // #749: if the representative was deleted, promote the most recent
      // remaining recording in the same repertoire so it never loses one.
      if (recording.isRepresentative) {
        final heir = Recording.pickRepresentativeHeir(
          box.values.where((r) => r.repertoireId == recording.repertoireId),
        );
        if (heir != null) {
          await box.put(heir.id, heir.copyWith(isRepresentative: true));
        }
      }

      await box.flush();
    }
  }

  @override
  Future<void> setRepresentative(String id) async {
    final box = await _recordingsBox;
    final recording = box.get(id);

    if (recording != null) {
      await clearRepresentative(recording.repertoireId);

      final updated = recording.copyWith(isRepresentative: true);
      await box.put(id, updated);
      await box.flush();
    }
  }

  @override
  Future<void> clearRepresentative(String repertoireId) async {
    final box = await _recordingsBox;
    final recordings =
        box.values
            .where((r) => r.repertoireId == repertoireId && r.isRepresentative)
            .toList();

    for (final recording in recordings) {
      final updated = recording.copyWith(isRepresentative: false);
      await box.put(recording.id, updated);
    }
    if (recordings.isNotEmpty) {
      await box.flush();
    }
  }

  @override
  Future<void> markAsShared(String id) async {
    final box = await _recordingsBox;
    final recording = box.get(id);

    if (recording != null) {
      final updated = recording.copyWith(
        sharedAt: DateTime.now(),
        storageStatus: StorageStatus.active,
      );
      await box.put(id, updated);
      await box.flush();
    }
  }

  @override
  Future<int> cleanupOrphanedRecordings() async {
    final box = await _recordingsBox;
    final orphanedIds = <String>[];

    for (final recording in box.values) {
      final file = File(recording.localPath);
      if (!await file.exists()) {
        orphanedIds.add(recording.id);
      }
    }

    if (orphanedIds.isEmpty) {
      return 0;
    }

    for (final id in orphanedIds) {
      await box.delete(id);
    }
    await box.flush();

    return orphanedIds.length;
  }

  @override
  Future<int> migrateAndRecoverPaths() async {
    final box = await _recordingsBox;
    final appDir = await getApplicationDocumentsDirectory();
    final currentBasePath = appDir.path;
    int recoveredCount = 0;

    for (final recording in box.values.toList()) {
      final storedPath = recording.localPath;
      final file = File(storedPath);

      if (await file.exists()) {
        continue;
      }

      String? newPath;

      final documentsIndex = storedPath.indexOf('/Documents/');
      if (documentsIndex != -1) {
        final relativePath = storedPath.substring(
          documentsIndex + '/Documents/'.length,
        );
        final reconstructedPath = '$currentBasePath/$relativePath';
        final reconstructedFile = File(reconstructedPath);
        if (await reconstructedFile.exists()) {
          newPath = reconstructedPath;
        }
      }

      if (newPath == null) {
        final fileName = storedPath.split('/').last;
        final recordingsDir = Directory('$currentBasePath/recordings');
        if (await recordingsDir.exists()) {
          await for (final entity in recordingsDir.list(recursive: true)) {
            if (entity is File && entity.path.endsWith(fileName)) {
              newPath = entity.path;
              break;
            }
          }
        }
      }

      if (newPath != null) {
        final updated = recording.copyWith(localPath: newPath);
        await box.put(recording.id, updated);
        recoveredCount++;
      }
    }

    if (recoveredCount > 0) {
      await box.flush();
    }

    return recoveredCount;
  }
}
