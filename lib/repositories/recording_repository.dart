import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/recording.dart';

/// Repository for managing recording data with local storage.
abstract class RecordingRepository {
  /// Get all recordings for a repertoire.
  Future<List<Recording>> getRecordingsForRepertoire(String repertoireId);

  /// Get all recordings for a student.
  Future<List<Recording>> getRecordingsForStudent(String studentId);

  /// Get a recording by ID.
  Future<Recording?> getRecording(String id);

  /// Get the representative recording for a repertoire.
  Future<Recording?> getRepresentativeRecording(String repertoireId);

  /// Save a recording.
  Future<void> saveRecording(Recording recording);

  /// Delete a recording.
  Future<void> deleteRecording(String id);

  /// Set a recording as representative.
  Future<void> setRepresentative(String id);

  /// Clear representative status for a repertoire.
  Future<void> clearRepresentative(String repertoireId);

  /// Mark recording as shared.
  Future<void> markAsShared(String id);

  /// Clean up orphaned recordings (DB entries without actual files).
  /// Returns the number of cleaned up recordings.
  Future<int> cleanupOrphanedRecordings();

  /// Migrate and recover recording paths.
  /// Tries to fix paths that became invalid due to container UUID changes.
  /// Returns the number of recovered recordings.
  Future<int> migrateAndRecoverPaths();
}

/// Hive-based implementation of RecordingRepository.
class HiveRecordingRepository implements RecordingRepository {
  static const String _boxName = 'recordings';

  Box<Recording>? _box;

  Future<Box<Recording>> get _recordingsBox async {
    if (_box != null && _box!.isOpen) {
      return _box!;
    }
    _box = await Hive.openBox<Recording>(_boxName);
    debugPrint('=== RecordingRepository: Box opened ===');
    debugPrint('RecordingRepository: Total recordings in box: ${_box!.length}');
    debugPrint('RecordingRepository: Box path: ${_box!.path}');

    // Log all recordings for debugging
    for (final recording in _box!.values) {
      debugPrint('  - ID: ${recording.id.substring(0, 8)}..., '
          'repertoireId: ${recording.repertoireId}, '
          'path: ${recording.localPath}');
    }
    debugPrint('=== End of box contents ===');
    return _box!;
  }

  @override
  Future<List<Recording>> getRecordingsForRepertoire(String repertoireId) async {
    final box = await _recordingsBox;
    final recordings = box.values
        .where((r) => r.repertoireId == repertoireId)
        .toList();

    // Sort by recorded date, newest first
    recordings.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    debugPrint('RecordingRepository: Found ${recordings.length} recordings for repertoire $repertoireId');
    return recordings;
  }

  @override
  Future<List<Recording>> getRecordingsForStudent(String studentId) async {
    final box = await _recordingsBox;
    final recordings = box.values
        .where((r) => r.studentId == studentId)
        .toList();

    // Sort by recorded date, newest first
    recordings.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    debugPrint('RecordingRepository: Found ${recordings.length} recordings for student $studentId');
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
    debugPrint('=== RecordingRepository: Saving recording ===');
    debugPrint('  ID: ${recording.id}');
    debugPrint('  repertoireId: ${recording.repertoireId}');
    debugPrint('  localPath: ${recording.localPath}');
    debugPrint('  Box length before: ${box.length}');

    await box.put(recording.id, recording);
    await box.flush(); // Ensure data is written to disk immediately

    debugPrint('  Box length after: ${box.length}');
    debugPrint('  Box path: ${box.path}');
    debugPrint('=== Recording saved and flushed ===');
  }

  @override
  Future<void> deleteRecording(String id) async {
    final box = await _recordingsBox;
    final recording = box.get(id);

    if (recording != null) {
      // Delete the local file
      try {
        final file = File(recording.localPath);
        if (await file.exists()) {
          await file.delete();
          debugPrint('RecordingRepository: Deleted file ${recording.localPath}');
        }
      } catch (e) {
        debugPrint('RecordingRepository: Failed to delete file: $e');
      }

      // Remove from database
      await box.delete(id);
      await box.flush();
      debugPrint('RecordingRepository: Deleted recording $id (flushed)');
    }
  }

  @override
  Future<void> setRepresentative(String id) async {
    final box = await _recordingsBox;
    final recording = box.get(id);

    if (recording != null) {
      // Clear existing representative for the same repertoire
      await clearRepresentative(recording.repertoireId);

      // Set as representative
      final updated = recording.copyWith(isRepresentative: true);
      await box.put(id, updated);
      await box.flush();
      debugPrint('RecordingRepository: Set recording $id as representative (flushed)');
    }
  }

  @override
  Future<void> clearRepresentative(String repertoireId) async {
    final box = await _recordingsBox;
    final recordings = box.values
        .where((r) => r.repertoireId == repertoireId && r.isRepresentative)
        .toList();

    for (final recording in recordings) {
      final updated = recording.copyWith(isRepresentative: false);
      await box.put(recording.id, updated);
    }
    if (recordings.isNotEmpty) {
      await box.flush();
    }
    debugPrint('RecordingRepository: Cleared representative for repertoire $repertoireId');
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
      debugPrint('RecordingRepository: Marked recording $id as shared (flushed)');
    }
  }

  @override
  Future<int> cleanupOrphanedRecordings() async {
    // Note: migrateAndRecoverPaths() should be called separately before this
    final box = await _recordingsBox;
    final orphanedIds = <String>[];

    debugPrint('=== RecordingRepository: Checking for orphaned recordings ===');

    for (final recording in box.values) {
      final file = File(recording.localPath);
      if (!await file.exists()) {
        orphanedIds.add(recording.id);
        debugPrint('  Orphaned: ${recording.id.substring(0, 8)}... (file not found: ${recording.localPath})');
      }
    }

    if (orphanedIds.isEmpty) {
      debugPrint('  No orphaned recordings found');
      return 0;
    }

    // Delete orphaned recordings from DB
    for (final id in orphanedIds) {
      await box.delete(id);
    }
    await box.flush();

    debugPrint('  Cleaned up ${orphanedIds.length} orphaned recordings');
    debugPrint('=== Cleanup complete ===');

    return orphanedIds.length;
  }

  @override
  Future<int> migrateAndRecoverPaths() async {
    final box = await _recordingsBox;
    final appDir = await getApplicationDocumentsDirectory();
    final currentBasePath = appDir.path;
    int recoveredCount = 0;

    debugPrint('=== RecordingRepository: Migrating and recovering paths ===');
    debugPrint('  Current base path: $currentBasePath');

    for (final recording in box.values.toList()) {
      final storedPath = recording.localPath;
      final file = File(storedPath);

      // Skip if file exists at stored path
      if (await file.exists()) {
        continue;
      }

      debugPrint('  Checking: ${recording.id.substring(0, 8)}...');
      debugPrint('    Stored path: $storedPath');

      // Try to recover the path
      String? newPath;

      // Strategy 1: Extract relative path and reconstruct with current base
      // iOS path format: /var/mobile/Containers/Data/Application/[UUID]/Documents/recordings/...
      final documentsIndex = storedPath.indexOf('/Documents/');
      if (documentsIndex != -1) {
        final relativePath = storedPath.substring(documentsIndex + '/Documents/'.length);
        final reconstructedPath = '$currentBasePath/$relativePath';
        final reconstructedFile = File(reconstructedPath);
        if (await reconstructedFile.exists()) {
          newPath = reconstructedPath;
          debugPrint('    Strategy 1 (path reconstruction) succeeded');
        }
      }

      // Strategy 2: Search by filename in recordings directory
      if (newPath == null) {
        final fileName = storedPath.split('/').last;
        final recordingsDir = Directory('$currentBasePath/recordings');
        if (await recordingsDir.exists()) {
          await for (final entity in recordingsDir.list(recursive: true)) {
            if (entity is File && entity.path.endsWith(fileName)) {
              newPath = entity.path;
              debugPrint('    Strategy 2 (filename search) succeeded');
              break;
            }
          }
        }
      }

      // Update path if recovered
      if (newPath != null) {
        debugPrint('    Recovered path: $newPath');
        final updated = recording.copyWith(localPath: newPath);
        await box.put(recording.id, updated);
        recoveredCount++;
      } else {
        debugPrint('    Could not recover - file may be deleted');
      }
    }

    if (recoveredCount > 0) {
      await box.flush();
      debugPrint('  Recovered $recoveredCount recordings');
    } else {
      debugPrint('  No paths needed recovery');
    }

    debugPrint('=== Migration complete ===');
    return recoveredCount;
  }
}

/// Mock implementation for testing.
class MockRecordingRepository implements RecordingRepository {
  final Map<String, Recording> _recordings = {};

  @override
  Future<List<Recording>> getRecordingsForRepertoire(String repertoireId) async {
    final recordings = _recordings.values
        .where((r) => r.repertoireId == repertoireId)
        .toList();
    recordings.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return recordings;
  }

  @override
  Future<List<Recording>> getRecordingsForStudent(String studentId) async {
    final recordings = _recordings.values
        .where((r) => r.studentId == studentId)
        .toList();
    recordings.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return recordings;
  }

  @override
  Future<Recording?> getRecording(String id) async {
    return _recordings[id];
  }

  @override
  Future<Recording?> getRepresentativeRecording(String repertoireId) async {
    try {
      return _recordings.values.firstWhere(
        (r) => r.repertoireId == repertoireId && r.isRepresentative,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveRecording(Recording recording) async {
    _recordings[recording.id] = recording;
  }

  @override
  Future<void> deleteRecording(String id) async {
    _recordings.remove(id);
  }

  @override
  Future<void> setRepresentative(String id) async {
    final recording = _recordings[id];
    if (recording != null) {
      await clearRepresentative(recording.repertoireId);
      _recordings[id] = recording.copyWith(isRepresentative: true);
    }
  }

  @override
  Future<void> clearRepresentative(String repertoireId) async {
    for (final entry in _recordings.entries) {
      if (entry.value.repertoireId == repertoireId && entry.value.isRepresentative) {
        _recordings[entry.key] = entry.value.copyWith(isRepresentative: false);
      }
    }
  }

  @override
  Future<void> markAsShared(String id) async {
    final recording = _recordings[id];
    if (recording != null) {
      _recordings[id] = recording.copyWith(
        sharedAt: DateTime.now(),
        storageStatus: StorageStatus.active,
      );
    }
  }

  @override
  Future<int> cleanupOrphanedRecordings() async {
    // Mock implementation - no actual file system access
    return 0;
  }

  @override
  Future<int> migrateAndRecoverPaths() async {
    // Mock implementation - no actual file system access
    return 0;
  }
}
