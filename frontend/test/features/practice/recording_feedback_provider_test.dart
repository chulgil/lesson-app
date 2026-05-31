import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lessonaza/features/practice/domain/entities/recording_feedback.dart';
import 'package:lessonaza/features/practice/domain/repositories/recording_feedback_repository.dart';
import 'package:lessonaza/features/practice/presentation/providers/recording_feedback_provider.dart';

class FakeRecordingFeedbackRepository implements RecordingFeedbackRepository {
  final List<String> createdContents = [];
  final Map<String, List<RecordingFeedback>> feedbacksByRecording;

  FakeRecordingFeedbackRepository({Map<String, List<RecordingFeedback>>? seed})
    : feedbacksByRecording = seed ?? {};

  @override
  Future<List<RecordingFeedback>> list(String recordingId) async {
    return feedbacksByRecording[recordingId] ?? const [];
  }

  @override
  Future<RecordingFeedback> create({
    required String recordingId,
    required String content,
    String? teacherId,
  }) async {
    createdContents.add(content);
    final feedback = RecordingFeedback(
      id: 'feedback-${createdContents.length}',
      recordingId: recordingId,
      teacherId: teacherId ?? '',
      content: content,
      createdAt: DateTime(2026, 5, 31),
    );
    feedbacksByRecording[recordingId] = [
      ...(feedbacksByRecording[recordingId] ?? const []),
      feedback,
    ];
    return feedback;
  }

  @override
  Future<RecordingFeedback> update({
    required String recordingId,
    required String feedbackId,
    required String content,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> delete({
    required String recordingId,
    required String feedbackId,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  test('loads feedbacks from repository after provider build', () async {
    final repository = FakeRecordingFeedbackRepository(
      seed: {
        'recording-1': [
          RecordingFeedback(
            id: 'feedback-1',
            recordingId: 'recording-1',
            teacherId: 'teacher-1',
            content: '이미 남긴 피드백',
            createdAt: DateTime(2026, 5, 31),
          ),
        ],
      },
    );
    final container = ProviderContainer(
      overrides: [
        recordingFeedbackRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(recordingFeedbackListProvider('recording-1')),
      isEmpty,
    );
    await Future<void>.delayed(Duration.zero);

    expect(
      container
          .read(recordingFeedbackListProvider('recording-1'))
          .single
          .content,
      '이미 남긴 피드백',
    );
  });

  test('add writes through repository and appends returned feedback', () async {
    final repository = FakeRecordingFeedbackRepository();
    final container = ProviderContainer(
      overrides: [
        recordingFeedbackRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(recordingFeedbackListProvider('recording-1').notifier)
        .add(teacherId: 'teacher-1', content: ' 좋아졌어요. ');

    expect(repository.createdContents, ['좋아졌어요.']);
    expect(
      container
          .read(recordingFeedbackListProvider('recording-1'))
          .single
          .content,
      '좋아졌어요.',
    );
  });
}
