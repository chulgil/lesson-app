import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/recording_feedback.dart';

part 'recording_feedback_provider.g.dart';

/// In-memory store of teacher feedbacks keyed by recordingId.
/// Mock-only — persistence/backend wired when API is available.
@Riverpod(keepAlive: true)
class RecordingFeedbackList extends _$RecordingFeedbackList {
  @override
  List<RecordingFeedback> build(String recordingId) => const [];

  void add({required String teacherId, required String content}) {
    final feedback = RecordingFeedback(
      id: 'fb_${DateTime.now().microsecondsSinceEpoch}',
      recordingId: recordingId,
      teacherId: teacherId,
      content: content.trim(),
      createdAt: DateTime.now(),
    );
    state = [...state, feedback];
  }
}

/// Count of feedbacks for a recording (for list indicators).
@riverpod
int recordingFeedbackCount(Ref ref, String recordingId) {
  return ref.watch(recordingFeedbackListProvider(recordingId)).length;
}
