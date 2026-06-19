// Red-Green gating tests for onboarding re-show suppression (#81).
//
// 버그: decline("내가 정할래") 는 quest 를 만들지 않으므로 quests.isEmpty 가
// 유지 → 매 mount 마다 onboarding 재노출 (무한 루프).
//
// 계약:
//   - dismissed=false + quests 0개 → onboarding 노출 (RED 대조군: 플래그 없으면
//     여전히 노출됨을 증명).
//   - decline 시 store.markDismissed 호출 + 플래그 영속.
//   - dismissed=true + quests 0개 → 다음 mount 에서 onboarding 미노출, child 렌더.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/presentation/providers/gamification_onboarding_dismissed_provider.dart';
import 'package:lessonaza/features/gamification/presentation/providers/student_quest_provider.dart';
import 'package:lessonaza/features/gamification/presentation/screens/student_gamification_onboarding_screen.dart';
import 'package:lessonaza/features/gamification/presentation/widgets/student_gamification_onboarding_trigger.dart';

/// In-memory fake — markDismissed 호출 추적.
class FakeGamificationOnboardingDismissStore
    implements GamificationOnboardingDismissStore {
  final Set<String> dismissed;

  FakeGamificationOnboardingDismissStore({Set<String>? seed})
    : dismissed = seed ?? <String>{};

  @override
  Future<bool> isDismissed(String studentId) async =>
      dismissed.contains(studentId);

  @override
  Future<void> markDismissed(String studentId) async {
    dismissed.add(studentId);
  }
}

void main() {
  const studentId = 'student_1';

  Widget harness({
    required GamificationOnboardingDismissStore store,
    required Widget child,
  }) {
    return ProviderScope(
      overrides: [
        activeQuestsProvider(studentId).overrideWith((ref) async => const []),
        gamificationOnboardingDismissStoreProvider.overrideWithValue(store),
      ],
      child: MaterialApp(
        home: StudentGamificationOnboardingTrigger(
          studentId: studentId,
          child: child,
        ),
      ),
    );
  }

  testWidgets('RED 대조군: dismissed=false + quest 0개 → onboarding 노출', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        store: FakeGamificationOnboardingDismissStore(),
        child: const Text('dashboard-body'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(StudentGamificationOnboardingScreen), findsOneWidget);
    expect(find.text('dashboard-body'), findsNothing);
  });

  testWidgets('dismissed=true + quest 0개 → onboarding 미노출, child 렌더 (#81)', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        store: FakeGamificationOnboardingDismissStore(seed: {studentId}),
        child: const Text('dashboard-body'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(StudentGamificationOnboardingScreen), findsNothing);
    expect(find.text('dashboard-body'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'decline → store.markDismissed 호출 → 재mount 시 onboarding 미노출 (#81)',
    (tester) async {
      final store = FakeGamificationOnboardingDismissStore();

      await tester.pumpWidget(
        harness(store: store, child: const Text('dashboard-body')),
      );
      await tester.pumpAndSettle();

      // 1차 mount: 노출됨.
      expect(find.byType(StudentGamificationOnboardingScreen), findsOneWidget);

      // decline 콜백 실행 (accepted=false).
      final screen = tester.widget<StudentGamificationOnboardingScreen>(
        find.byType(StudentGamificationOnboardingScreen),
      );
      screen.onResult('violin', false);
      // onResult 는 void 반환(내부 async fire-and-forget) — 보류 microtask 를
      // pump 로 비워 markDismissed 완료를 보장.
      await tester.pump(Duration.zero);
      await tester.pumpAndSettle();

      // 플래그 영속 확인.
      expect(store.dismissed.contains(studentId), isTrue);

      // 재mount (새 ProviderScope, 같은 영속 store) → 미노출.
      await tester.pumpWidget(
        harness(store: store, child: const Text('dashboard-body')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StudentGamificationOnboardingScreen), findsNothing);
      expect(find.text('dashboard-body'), findsOneWidget);
    },
  );
}
