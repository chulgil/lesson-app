import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/practice/domain/entities/recording.dart';
import 'package:lessonaza/features/practice/presentation/providers/recording_provider.dart';
import 'package:lessonaza/features/practice/presentation/screens/practice_recording_screen.dart';

class _FakeRecordingNotifier extends RecordingNotifier {
  @override
  RecordingState build(String repertoireId, String studentId) {
    final now = DateTime(2026, 5, 7);
    return RecordingState(
      isLoading: false,
      recordings: [
        Recording(
          id: 'recording_1',
          repertoireId: repertoireId,
          studentId: studentId,
          type: RecordingType.student,
          localPath: '/tmp/recording.wav',
          durationSeconds: 42,
          isRepresentative: true,
          recordedAt: now,
        ),
      ],
    );
  }
}

void main() {
  testWidgets('shows explicit teacher share action', (tester) async {
    const repertoireId = 'repertoire_1';
    const studentId = 'student_1';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          microphonePermissionProvider.overrideWith((ref) async => true),
          recordingNotifierProvider(
            repertoireId,
            studentId,
          ).overrideWith(_FakeRecordingNotifier.new),
        ],
        child: const MaterialApp(
          home: PracticeRecordingScreen(
            repertoireId: repertoireId,
            repertoireName: 'Canon',
            studentId: studentId,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text(AppStrings.practiceShareToTeacherAction), findsOneWidget);
  });
}
