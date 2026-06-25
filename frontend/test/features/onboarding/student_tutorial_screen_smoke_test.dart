import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/onboarding/presentation/screens/student_tutorial_screen.dart';
import 'package:lessonaza/features/onboarding/presentation/widgets/student_tutorial/metronome_step.dart';
import 'package:lessonaza/features/onboarding/presentation/widgets/student_tutorial/recording_step.dart';
import 'package:lessonaza/features/onboarding/presentation/widgets/student_tutorial/tuner_step.dart';

void main() {
  // 버그 B 재진단(2026-06-25): 메모리의 "중첩 SingleChildScrollView → unbounded
  // 크래시"는 재현되지 않는다 — SingleChildScrollView 는 ListView 와 달리 unbounded
  // 세로 제약에서 자식 높이로 shrink-wrap 한다(예외/무한높이 없음).
  // 그러나 _StudentTutorialPage(SingleChildScrollView) 안의 step 이 또 root 로
  // SingleChildScrollView 를 두는 건 **스크롤하지 않는 중복 래퍼 + 경쟁 제스처 인식기**
  // (보고된 "스크롤/터치 안 됨"의 유력 원인). step 은 중첩 스크롤을 두지 않아야 한다.

  testWidgets('StudentTutorialScreen 첫 step 은 중첩 SingleChildScrollView 가 없다', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: StudentTutorialScreen())),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(MetronomeStep), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MetronomeStep),
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
      reason: 'step 이 페이지 스크롤 안에서 또 SingleChildScrollView 를 둠 (버그 B)',
    );
  });

  testWidgets('모든 tutorial step 위젯은 자체 SingleChildScrollView 를 두지 않는다', (
    tester,
  ) async {
    final steps = <Widget>[
      MetronomeStep(completed: false, onComplete: () {}),
      TunerStep(completed: false, onComplete: () {}),
      RecordingStep(completed: false, onComplete: () {}),
    ];

    for (final step in steps) {
      // 실제 페이지처럼 바깥 스크롤로 감싸 pump (오버플로 false-RED 방지)
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: SingleChildScrollView(child: step))),
      );

      expect(
        tester.takeException(),
        isNull,
        reason: '${step.runtimeType} 렌더 예외',
      );
      expect(
        find.descendant(
          of: find.byWidget(step),
          matching: find.byType(SingleChildScrollView),
        ),
        findsNothing,
        reason: '${step.runtimeType} 가 중첩 SingleChildScrollView 보유 (버그 B)',
      );
    }
  });
}
