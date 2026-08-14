import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/gamification/gamification_facade.dart'
    show todayPracticeMinutesProvider, weeklyPracticeMinutesProvider;
import 'package:lessonaza/features/practice/domain/entities/entities.dart';
import 'package:lessonaza/features/practice/presentation/providers/goal_achievement_storage_provider.dart';
import 'package:lessonaza/features/practice/presentation/providers/practice_goal_provider.dart';
import 'package:lessonaza/features/practice/presentation/widgets/goal/goal_progress_widget.dart';

void main() {
  group('GoalProgressWidget', () {
    Widget wrap(Widget child, List<Override> overrides) {
      return ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SizedBox(width: 360, child: child),
                const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ),
        ),
      );
    }

    GoalStatus buildStatus({
      PracticeGoal? goal,
      int timeSeconds = 0,
      int sections = 0,
      int weeklySeconds = 0,
      int weeklyDays = 0,
    }) {
      final today = DateTime.now();
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final normalizedWeekStart = DateTime(
        weekStart.year,
        weekStart.month,
        weekStart.day,
      );
      return GoalStatus(
        goal: goal,
        todayProgress: DailyPracticeProgress(
          date: today,
          practiceTimeSeconds: timeSeconds,
          completedSectionCount: sections,
        ),
        weeklyProgress: WeeklyPracticeProgress(
          weekStart: normalizedWeekStart,
          totalTimeSeconds: weeklySeconds,
          practiceDayCount: weeklyDays,
          dailyProgress: const [],
        ),
      );
    }

    List<Override> overridesFor(GoalStatus status) {
      return [
        goalStatusProvider('s1').overrideWith((_) async => status),
        goalAchievementStorageProvider(
          's1',
        ).overrideWith(_FakeGoalAchievementStorage.new),
      ];
    }

    testWidgets('renders empty CTA when no goal is set', (tester) async {
      final status = buildStatus();
      await tester.pumpWidget(
        wrap(const GoalProgressWidget(studentId: 's1'), overridesFor(status)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.goalProgressEmptyTitle), findsOneWidget);
      expect(find.text(AppStrings.goalProgressEmptyAction), findsOneWidget);
    });

    testWidgets('renders daily and weekly progress bars for active goal', (
      tester,
    ) async {
      final goal = PracticeGoal(
        id: 'g1',
        studentId: 's1',
        dailyTimeMinutes: 30,
        dailySectionCount: 3,
        weeklyTimeMinutes: 180,
        weeklyDayCount: 5,
        isActive: true,
        createdAt: DateTime(2026, 6, 1),
      );
      final status = buildStatus(
        goal: goal,
        timeSeconds: 15 * 60,
        sections: 1,
        weeklySeconds: 60 * 60,
        weeklyDays: 2,
      );

      await tester.pumpWidget(
        wrap(const GoalProgressWidget(studentId: 's1'), overridesFor(status)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.goalProgressTitle), findsOneWidget);
      expect(find.text(AppStrings.goalProgressDaily), findsOneWidget);
      expect(find.text(AppStrings.goalProgressWeekly), findsOneWidget);
      // Time label appears at least once for daily and once for weekly.
      expect(find.text(AppStrings.goalProgressTime), findsNWidgets(2));
    });

    testWidgets('survives narrow Column layout without BoxConstraints crash', (
      tester,
    ) async {
      final goal = PracticeGoal(
        id: 'g1',
        studentId: 's1',
        dailyTimeMinutes: 30,
        isActive: true,
        createdAt: DateTime(2026, 6, 1),
      );
      final status = buildStatus(
        goal: goal,
        timeSeconds: 45 * 60, // achieved
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: overridesFor(status),
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 280,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [GoalProgressWidget(studentId: 's1')],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '#1273 회귀 — 진행바가 practice-logs(스트릭 전용) 근접-0 대신 히트맵 파생 분을 반영한다',
      (tester) async {
        final goal = PracticeGoal(
          id: 'g1',
          studentId: 's1',
          dailyTimeMinutes: 30,
          weeklyTimeMinutes: 180,
          isActive: true,
          createdAt: DateTime(2026, 6, 1),
        );
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final normalizedWeekStart = DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day,
        );

        await tester.pumpWidget(
          wrap(const GoalProgressWidget(studentId: 's1'), [
            practiceGoalProvider('s1').overrideWith((_) async => goal),
            // practice-logs 파이프라인은 스트릭 전용으로 남는다(#1273 결정) —
            // 실사용에서 항상 관측되던 1분 minimal streak log 를 그대로
            // 재현해, goalStatusProvider 가 이 값을 더 이상 시간 진행값으로
            // 쓰지 않음을 검증한다.
            todayProgressProvider('s1').overrideWith(
              (_) async => DailyPracticeProgress(
                date: now,
                practiceTimeSeconds: 60,
                completedSectionCount: 0,
              ),
            ),
            weeklyProgressProvider('s1').overrideWith(
              (_) async => WeeklyPracticeProgress(
                weekStart: normalizedWeekStart,
                totalTimeSeconds: 60,
                practiceDayCount: 0,
                dailyProgress: const [],
              ),
            ),
            // 히트맵 파생 소스 — 실제 누적 연습 분 (#1269 과 동일 소스).
            todayPracticeMinutesProvider('s1').overrideWith((_) async => 20),
            weeklyPracticeMinutesProvider('s1').overrideWith((_) async => 90),
            goalAchievementStorageProvider(
              's1',
            ).overrideWith(_FakeGoalAchievementStorage.new),
          ]),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        // 20분/90분(1시간 30분) — 히트맵 파생 값. practice-logs 파이프라인의
        // 1분/1분 근접-0 값이 아니어야 한다.
        expect(find.text('20분 / 30분'), findsOneWidget);
        expect(find.text('1시간 30분 / 3시간'), findsOneWidget);
        expect(find.textContaining('1분 / 30분'), findsNothing);
        expect(find.textContaining('1분 / 3시간'), findsNothing);
      },
    );
  });
}

/// In-memory stub that avoids touching Hive in widget tests.
class _FakeGoalAchievementStorage extends GoalAchievementStorage {
  GoalAchievementState _state = const GoalAchievementState();

  @override
  Future<GoalAchievementState> build(String studentId) async => _state;

  @override
  Future<void> markDailyAchieved(DateTime date) async {
    _state = _state.copyWith(
      lastDailyAchievedDate: DateTime(date.year, date.month, date.day),
    );
    state = AsyncData(_state);
  }

  @override
  Future<void> markWeeklyAchieved(DateTime weekStart) async {
    _state = _state.copyWith(
      lastWeeklyAchievedWeekStart: DateTime(
        weekStart.year,
        weekStart.month,
        weekStart.day,
      ),
    );
    state = AsyncData(_state);
  }
}
