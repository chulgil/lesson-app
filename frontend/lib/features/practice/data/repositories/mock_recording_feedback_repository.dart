import '../../domain/entities/recording_feedback.dart';
import '../../domain/repositories/recording_feedback_repository.dart';

class MockRecordingFeedbackRepository implements RecordingFeedbackRepository {
  final Map<String, List<RecordingFeedback>> _feedbacksByRecording = {};

  @override
  Future<List<RecordingFeedback>> list(String recordingId) async {
    return List.unmodifiable(_feedbacksByRecording[recordingId] ?? const []);
  }

  @override
  Future<RecordingFeedback> create({
    required String recordingId,
    required String content,
    String? teacherId,
  }) async {
    final feedback = RecordingFeedback(
      id: 'fb_${DateTime.now().microsecondsSinceEpoch}',
      recordingId: recordingId,
      teacherId: teacherId ?? '',
      content: content.trim(),
      createdAt: DateTime.now(),
    );
    _feedbacksByRecording[recordingId] = [
      ...(_feedbacksByRecording[recordingId] ?? const []),
      feedback,
    ];
    return feedback;
  }

  @override
  Future<RecordingFeedback> update({
    required String recordingId,
    required String feedbackId,
    required String content,
  }) async {
    final feedbacks = _feedbacksByRecording[recordingId] ?? const [];
    final index = feedbacks.indexWhere((feedback) => feedback.id == feedbackId);
    if (index == -1) {
      throw StateError('Feedback not found: $feedbackId');
    }
    final updated = RecordingFeedback(
      id: feedbacks[index].id,
      recordingId: feedbacks[index].recordingId,
      teacherId: feedbacks[index].teacherId,
      content: content.trim(),
      createdAt: feedbacks[index].createdAt,
    );
    _feedbacksByRecording[recordingId] = [
      ...feedbacks.take(index),
      updated,
      ...feedbacks.skip(index + 1),
    ];
    return updated;
  }

  @override
  Future<void> delete({
    required String recordingId,
    required String feedbackId,
  }) async {
    _feedbacksByRecording[recordingId] =
        (_feedbacksByRecording[recordingId] ?? const [])
            .where((feedback) => feedback.id != feedbackId)
            .toList();
  }
}
