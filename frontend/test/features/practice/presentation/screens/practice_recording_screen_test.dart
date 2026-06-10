import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/widgets/swipe_action_tile.dart';
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
  Future<void> pumpScreen(WidgetTester tester) async {
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
    // SwipeActionTile AnimatedContainer 가 settle 못 하는 경우가 있어 명시 pump 만.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('shows explicit teacher share action', (tester) async {
    await pumpScreen(tester);
    expect(find.text(AppStrings.practiceShareToTeacherAction), findsOneWidget);
  });

  testWidgets('does not render PopupMenuButton (swipe consistency D1)', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(
      find.byType(PopupMenuButton<String>),
      findsNothing,
      reason:
          '_RecordingItem 의 PopupMenuButton 은 SwipeActionTile + BottomSheet 로 대체되어야 한다.',
    );
  });

  testWidgets(
    'renders SwipeActionTile for recording row (swipe destructive 단일)',
    (tester) async {
      await pumpScreen(tester);
      expect(
        find.byType(SwipeActionTile),
        findsWidgets,
        reason: '_RecordingItem 은 SwipeActionTile 로 래핑되어야 한다.',
      );
    },
  );
}
