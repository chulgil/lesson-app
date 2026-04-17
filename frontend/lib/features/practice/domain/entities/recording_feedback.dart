import 'package:flutter/foundation.dart';

/// Teacher feedback on a shared recording.
@immutable
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
