import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/onboarding/presentation/screens/student_tutorial_screen.dart';
import 'package:lessonaza/features/onboarding/presentation/widgets/student_tutorial/feedback_step.dart';
import 'package:lessonaza/features/onboarding/presentation/widgets/student_tutorial/metronome_step.dart';
import 'package:lessonaza/features/onboarding/presentation/widgets/student_tutorial/recording_step.dart';
import 'package:lessonaza/features/onboarding/presentation/widgets/student_tutorial/tuner_step.dart';

void main() {
  testWidgets('student tutorial renders step 1 with disabled next button', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const StudentTutorialScreen(),
        ),
      ),
    );

    expect(find.text('1. 메트로놈 켜보기'), findsOneWidget);
    expect(find.text('건너뛰기'), findsOneWidget);

    final nextButton = find.widgetWithText(ElevatedButton, '다음');
    expect(tester.widget<ElevatedButton>(nextButton).onPressed, isNull);

    expect(tester.takeException(), isNull);
  });

  testWidgets('tuner step completes after tapping a note chip', (tester) async {
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TunerStep(completed: false, onComplete: () => completed = true),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('student_tutorial_tuner_chip_A4')),
    );
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('feedback step completes after expanding the card', (
    tester,
  ) async {
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: FeedbackStep(
            completed: false,
            onComplete: () => completed = true,
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('student_tutorial_feedback_card')),
    );
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('metronome step renders without exception', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: MetronomeStep(completed: false, onComplete: () {}),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('recording step renders without exception', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: RecordingStep(completed: false, onComplete: () {}),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
