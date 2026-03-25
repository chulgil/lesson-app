import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/recording.dart';
import '../../domain/repositories/recording_repository.dart';

/// Remote implementation of [RecordingRepository] using FastAPI backend.
///
/// Handles server-side recording metadata and file uploads.
/// Local-only operations (path migration, cleanup) return no-ops.
class RemoteRecordingRepository implements RecordingRepository {
  final ApiClient _apiClient;

  RemoteRecordingRepository(this._apiClient);

  @override
  Future<List<Recording>> getRecordingsForRepertoire(
    String repertoireId,
  ) async {
    final response = await _apiClient.get(
      '/recordings',
      queryParameters: {'section_id': repertoireId},
    );
    final items = response.data['items'] as List<dynamic>;
    return items
        .map((e) => _recordingFromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Recording>> getRecordingsForStudent(String studentId) async {
    final response = await _apiClient.get(
      '/recordings',
      queryParameters: {'student_id': studentId},
    );
    final items = response.data['items'] as List<dynamic>;
    return items
        .map((e) => _recordingFromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Recording?> getRecording(String id) async {
    final response = await _apiClient.get('/recordings/$id');
    return _recordingFromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Recording?> getRepresentativeRecording(String repertoireId) async {
    final recordings = await getRecordingsForRepertoire(repertoireId);
    try {
      return recordings.firstWhere((r) => r.isRepresentative);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveRecording(Recording recording) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(recording.localPath),
      'section_id': recording.repertoireId,
      'duration_seconds': recording.durationSeconds,
    });
    await _apiClient.post(
      '/recordings/upload',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  @override
  Future<void> deleteRecording(String id) async {
    await _apiClient.delete('/recordings/$id');
  }

  @override
  Future<void> setRepresentative(String id) async {
    await _apiClient.patch('/recordings/$id/representative');
  }

  @override
  Future<void> clearRepresentative(String repertoireId) async {
    // Server handles clearing previous representative when setting a new one
  }

  @override
  Future<void> markAsShared(String id) async {
    await _apiClient.post('/recordings/$id/share');
  }

  @override
  Future<int> cleanupOrphanedRecordings() async {
    // Local-only operation — no-op for remote
    return 0;
  }

  @override
  Future<int> migrateAndRecoverPaths() async {
    // Local-only operation — no-op for remote
    return 0;
  }

  // --- Manual JSON helpers (Recording doesn't have @JsonSerializable) ---

  Recording _recordingFromJson(Map<String, dynamic> json) {
    return Recording(
      id: json['id'] as String,
      repertoireId: json['section_id'] as String? ?? '',
      studentId: json['student_id'] as String? ?? '',
      type: _parseRecordingType(json['type'] as String?),
      localPath: json['server_url'] as String? ?? '',
      serverUrl: json['server_url'] as String?,
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      isRepresentative: json['is_representative'] as bool? ?? false,
      recordedAt:
          json['recorded_at'] != null
              ? DateTime.parse(json['recorded_at'] as String)
              : DateTime.now(),
      sharedAt:
          json['shared_at'] != null
              ? DateTime.parse(json['shared_at'] as String)
              : null,
      storageStatus: _parseStorageStatus(json['storage_status'] as String?),
      title: json['title'] as String?,
    );
  }

  RecordingType _parseRecordingType(String? value) {
    if (value == null) return RecordingType.student;
    try {
      return RecordingType.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return RecordingType.student;
    }
  }

  StorageStatus _parseStorageStatus(String? value) {
    if (value == null) return StorageStatus.active;
    try {
      return StorageStatus.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return StorageStatus.active;
    }
  }
}
