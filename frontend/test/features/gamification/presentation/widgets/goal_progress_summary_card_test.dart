// GoalProgressSummaryCard 위젯 테스트 — #1269 목표 위젯 단일화.
//
// [daily_goal_card_test.dart](삭제됨) 의 시나리오 커버리지를 유지하되, 데이터
// 소스를 device-local DailyPracticeGoal 대신 원격 영속 PracticeGoal 로
// 전환한다 — practiceGoalProvider/todayPracticeMinutesProvider 를 직접
// override 하므로 Hive 초기화가 필요 없다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/gamification/presentation/providers/today_practice_minutes_provider.dart';
import 'package:lessonaza/features/gamification/presentation/widgets/goal_progress_summary_card.dart';
import 'package:lessonaza/features/practice/domain/entities/entities.dart';
import 'package:lessonaza/features/practice/practice_facade.dart';

Widget _wrap(Widget child, List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

List<Override> _overridesFor({PracticeGoal? goal, int todayMinutes = 0}) {
  return [
    practiceGoalProvider('s1').overrideWith((ref) async => goal),
    todayPracticeMinutesProvider(
      's1',
    ).overrideWith((ref) async => todayMinutes),
  ];
}

void main() {
  group('GoalProgressSummaryCard — #1269 목표 위젯 단일화', () {
    testWidgets('목표 미설정 — 빈 상태 CTA (widget smoke test HARD-GATE)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const GoalProgressSummaryCard(studentId: 's1'), _overridesFor()),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.goalProgressEmptyTitle), findsOneWidget);
      expect(find.text(AppStrings.goalProgressEmptyAction), findsOneWidget);
    });

    testWidgets('0분 — 진행바 0, 시작 유도 문구', (tester) async {
      final goal = PracticeGoal(
        id: 'g1',
        studentId: 's1',
        dailyTimeMinutes: 15,
        createdAt: DateTime(2026, 6, 1),
      );
      await tester.pumpWidget(
        _wrap(
          const GoalProgressSummaryCard(studentId: 's1'),
          _overridesFor(goal: goal),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final bar = tester.widget<LinearProgressIndicator>(
        find.byKey(const ValueKey('goal_summary_progress_bar')),
      );
      expect(bar.value, 0.0);
      expect(find.text(AppStrings.dailyGoalStartPrompt), findsOneWidget);
      expect(find.text('0/15분'), findsOneWidget);
    });

    testWidgets('부분 진행(7/15) — 진행바 비율 + 잔여 문구', (tester) async {
      final goal = PracticeGoal(
        id: 'g1',
        studentId: 's1',
        dailyTimeMinutes: 15,
        createdAt: DateTime(2026, 6, 1),
      );
      await tester.pumpWidget(
        _wrap(
          const GoalProgressSummaryCard(studentId: 's1'),
          _overridesFor(goal: goal, todayMinutes: 7),
        ),
      );
      await tester.pumpAndSettle();

      final bar = tester.widget<LinearProgressIndicator>(
        find.byKey(const ValueKey('goal_summary_progress_bar')),
      );
      expect(bar.value, closeTo(7 / 15, 0.001));
      expect(find.text('7/15분'), findsOneWidget);
      expect(find.text(AppStrings.dailyGoalRemainingLabel(8)), findsOneWidget);
    });

    testWidgets('100% 초과(30/15) — 진행바 상한 1.0, 라벨은 실제 분 유지', (tester) async {
      final goal = PracticeGoal(
        id: 'g1',
        studentId: 's1',
        dailyTimeMinutes: 15,
        createdAt: DateTime(2026, 6, 1),
      );
      await tester.pumpWidget(
        _wrap(
          const GoalProgressSummaryCard(studentId: 's1'),
          _overridesFor(goal: goal, todayMinutes: 30),
        ),
      );
      await tester.pumpAndSettle();

      final bar = tester.widget<LinearProgressIndicator>(
        find.byKey(const ValueKey('goal_summary_progress_bar')),
      );
      expect(bar.value, 1.0, reason: '진행바는 100% 상한 — 밀린/초과분 누적 표시 없음');
      expect(find.text('30/15분'), findsOneWidget, reason: '라벨은 실제 연습분을 유지');
      expect(find.text(AppStrings.dailyGoalAchievedLabel), findsOneWidget);
    });
  });
}
