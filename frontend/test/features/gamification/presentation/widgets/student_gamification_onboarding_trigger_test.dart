// Tests for StudentGamificationOnboardingTrigger (Job 6 Task 6.2 회귀).
//
// 회귀 배경 (2026-06-12): trigger 가 StudentDashboardTab 의
// SingleChildScrollView **내부** 슬롯에 배치되어, quest 0개 시 full-screen
// `StudentGamificationOnboardingScreen` (Scaffold) 이 unbounded height 로
// inline 렌더 → RenderCustomMultiChildLayoutBox infinite size 크래시.
//
// 계약:
// - quest 0개 → onboarding 화면이 **화면 전체** 를 차지 (child 미렌더)
// - quest 1개+ → child 렌더
// - trigger 는 bounded height 컨텍스트 (화면 root) 에서 사용해야 함
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/domain/entities/challenge.dart';
import 'package:lessonaza/features/gamification/domain/entities/quest_origin.dart';
import 'package:lessonaza/features/gamification/domain/entities/student_quest.dart';
import 'package:lessonaza/features/gamification/presentation/providers/gamification_onboarding_dismissed_provider.dart';
import 'package:lessonaza/features/gamification/presentation/providers/student_quest_provider.dart';
import 'package:lessonaza/features/gamification/presentation/screens/student_gamification_onboarding_screen.dart';
import 'package:lessonaza/features/gamification/presentation/widgets/student_gamification_onboarding_trigger.dart';

StudentQuest _quest(String studentId) {
  final today = DateTime(2026, 6, 12);
  return StudentQuest(
    id: 'q1',
    studentId: studentId,
    origin: QuestOrigin.systemRoutine,
    title: '스케일 5분',
    type: ActivityType.practiceMinutes,
    targetValue: 5,
    currentValue: 0,
    startDate: today,
    endDate: today.add(const Duration(days: 7)),
  );
}

class _FakeOnboardingDismissStore
    implements GamificationOnboardingDismissStore {
  @override
  Future<bool> isDismissed(String studentId) async => false;
  @override
  Future<void> markDismissed(String studentId) async {}
}

void main() {
  const studentId = 'student_1';

  Widget harness({required List<StudentQuest> quests, required Widget child}) {
    return ProviderScope(
      overrides: [
        activeQuestsProvider(studentId).overrideWith((ref) async => quests),
        gamificationOnboardingDismissStoreProvider.overrideWithValue(
          _FakeOnboardingDismissStore(),
        ),
      ],
      child: MaterialApp(
        home: StudentGamificationOnboardingTrigger(
          studentId: studentId,
          child: child,
        ),
      ),
    );
  }

  group('StudentGamificationOnboardingTrigger (Job 6 Task 6.2)', () {
    testWidgets('quest 0개 → onboarding 화면 표시, child 미렌더', (tester) async {
      await tester.pumpWidget(
        harness(quests: const [], child: const Text('dashboard-body')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StudentGamificationOnboardingScreen), findsOneWidget);
      expect(find.text('dashboard-body'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('quest 1개+ → child 렌더, onboarding 없음', (tester) async {
      await tester.pumpWidget(
        harness(
          quests: [_quest(studentId)],
          child: const Text('dashboard-body'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StudentGamificationOnboardingScreen), findsNothing);
      expect(find.text('dashboard-body'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('child 가 SingleChildScrollView 여도 onboarding 전환 시 크래시 없음 '
        '(2026-06-12 unbounded height 회귀)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        harness(
          quests: const [],
          child: const SingleChildScrollView(child: Text('scroll-body')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StudentGamificationOnboardingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
