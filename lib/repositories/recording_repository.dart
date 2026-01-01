import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
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
    debugPrint('RecordingRepository: Opened box with ${_box!.length} recordings');
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
    await box.put(recording.id, recording);
    await box.flush(); // Ensure data is written to disk immediately
    debugPrint('RecordingRepository: Saved recording ${recording.id} (flushed)');
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
}
