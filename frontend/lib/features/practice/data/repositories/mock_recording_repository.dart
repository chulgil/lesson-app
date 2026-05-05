import '../../domain/entities/recording.dart';
import '../../domain/repositories/recording_repository.dart';

/// Mock implementation for testing.
class MockRecordingRepository implements RecordingRepository {
  final Map<String, Recording> _recordings = {};

  @override
  Future<List<Recording>> getRecordingsForRepertoire(
    String repertoireId,
  ) async {
    final recordings =
        _recordings.values
            .where((r) => r.repertoireId == repertoireId)
            .toList();
    recordings.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return recordings;
  }

  @override
  Future<List<Recording>> getRecordingsForStudent(String studentId) async {
    final recordings =
        _recordings.values.where((r) => r.studentId == studentId).toList();
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
      if (entry.value.repertoireId == repertoireId &&
          entry.value.isRepresentative) {
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
    return 0;
  }

  @override
  Future<int> migrateAndRecoverPaths() async {
    return 0;
  }
}
