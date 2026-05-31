import '../entities/recording_feedback.dart';

abstract class RecordingFeedbackRepository {
  Future<List<RecordingFeedback>> list(String recordingId);

  Future<RecordingFeedback> create({
    required String recordingId,
    required String content,
    String? teacherId,
  });

  Future<RecordingFeedback> update({
    required String recordingId,
    required String feedbackId,
    required String content,
  });

  Future<void> delete({
    required String recordingId,
    required String feedbackId,
  });
}
