/// Teacher feedback on a shared recording.
class RecordingFeedback {
  const RecordingFeedback({
    required this.id,
    required this.recordingId,
    required this.teacherId,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String recordingId;
  final String teacherId;
  final String content;
  final DateTime createdAt;
}
