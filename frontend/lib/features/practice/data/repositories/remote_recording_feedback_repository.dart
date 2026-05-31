import '../../../../core/network/api_client.dart';
import '../../domain/entities/recording_feedback.dart';
import '../../domain/repositories/recording_feedback_repository.dart';

class RemoteRecordingFeedbackRepository implements RecordingFeedbackRepository {
  RemoteRecordingFeedbackRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<RecordingFeedback>> list(String recordingId) async {
    final response = await _apiClient.get('/recordings/$recordingId/feedback');
    final items = response.data as List<dynamic>;
    return items
        .map((item) => _fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<RecordingFeedback> create({
    required String recordingId,
    required String content,
    String? teacherId,
  }) async {
    final response = await _apiClient.post(
      '/recordings/$recordingId/feedback',
      data: {'content': content.trim()},
    );
    return _fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<RecordingFeedback> update({
    required String recordingId,
    required String feedbackId,
    required String content,
  }) async {
    final response = await _apiClient.put(
      '/recordings/$recordingId/feedback/$feedbackId',
      data: {'content': content.trim()},
    );
    return _fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> delete({
    required String recordingId,
    required String feedbackId,
  }) async {
    await _apiClient.delete('/recordings/$recordingId/feedback/$feedbackId');
  }

  RecordingFeedback _fromJson(Map<String, dynamic> json) {
    return RecordingFeedback(
      id: json['id'] as String,
      recordingId: (json['recordingId'] ?? json['recording_id']) as String,
      teacherId: (json['teacherId'] ?? json['teacher_id']) as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(
        (json['createdAt'] ?? json['created_at']) as String,
      ),
    );
  }
}
