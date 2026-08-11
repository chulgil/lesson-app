import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/practice/domain/entities/recording.dart';
import 'package:lessonaza/features/practice/domain/entities/recording_feedback.dart';
import 'package:lessonaza/features/practice/presentation/providers/recording_feedback_provider.dart';
import 'package:lessonaza/features/practice/presentation/providers/recording_provider.dart';
import 'package:lessonaza/features/practice/presentation/screens/recording_detail_screen.dart';

const _recordingId = 'recording_1';

Recording _recording() => Recording(
  id: _recordingId,
  repertoireId: 'repertoire_1',
  studentId: 'student_1',
  type: RecordingType.student,
  localPath: '/tmp/recording.wav',
  durationSeconds: 42,
  recordedAt: DateTime(2026, 5, 7),
  sharedAt: DateTime(2026, 5, 7),
);

RecordingFeedback _feedback(String id, String content) => RecordingFeedback(
  id: id,
  recordingId: _recordingId,
  teacherId: 'teacher_1',
  content: content,
  createdAt: DateTime(2026, 5, 8),
);

/// Fixed-data fake so the smoke test doesn't depend on repository selection.
class _FakeFeedbackList extends RecordingFeedbackList {
  _FakeFeedbackList(this._feedbacks);

  final List<RecordingFeedback> _feedbacks;

  @override
  List<RecordingFeedback> build(String recordingId) => _feedbacks;
}

Widget _harness(List<Override> overrides) => ProviderScope(
  overrides: overrides,
  child: const MaterialApp(
    home: RecordingDetailScreen(recordingId: _recordingId),
  ),
);

void main() {
  group('RecordingDetailScreen', () {
    testWidgets('smoke — renders player + feedback without exceptions', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness([
          recordingByIdProvider(
            _recordingId,
          ).overrideWith((ref) async => _recording()),
          recordingFeedbackListProvider(
            _recordingId,
          ).overrideWith(() => _FakeFeedbackList([_feedback('fb_1', '좋아요!')])),
        ]),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('좋아요!'), findsOneWidget);
    });

    testWidgets('empty feedback shows EmptyStateWidget message', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness([
          recordingByIdProvider(
            _recordingId,
          ).overrideWith((ref) async => _recording()),
          recordingFeedbackListProvider(
            _recordingId,
          ).overrideWith(() => _FakeFeedbackList(const [])),
        ]),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.recordingFeedbackEmpty), findsOneWidget);
    });

    testWidgets('recording not found shows EmptyStateWidget message', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness([
          recordingByIdProvider(_recordingId).overrideWith((ref) async => null),
        ]),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.recordingDetailNotFound), findsOneWidget);
    });
  });
}
