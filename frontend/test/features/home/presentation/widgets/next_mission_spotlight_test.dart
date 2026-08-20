// W4 Task 4.4 — NextMissionSpotlight smoke + 동작 회귀 테스트.
// HARD-GATE: design-principles.md (widget-smoke-test).
// spec §9.1 Step 3 — 가입 후 메인 첫 진입 1회 spotlight.
//
// UXC-2 (2026-08-20): 노출 조건이 `questFirstShownProvider` 타임스탬프에서
// `nextMissionSpotlightDismissedProvider` 로 분리됐다. 첫 도착 기록은
// home_screen 이 post-frame 에 즉시 남기므로, 그 값이 노출 조건이면
// spotlight 가 플래시하거나 아예 뜨지 않았다.
//
// Verifies:
// - dismissed == false → spotlight 노출 (타이틀/힌트/CTA)
// - dismissed == true → spotlight 미노출 (SizedBox.shrink)
// - 첫 도착 타임스탬프가 이미 기록돼 있어도 spotlight 는 유지 (UXC-2 회귀)
// - [시작] 탭 → markDismissed 호출 + onStart 콜백
// - [나중에] 탭 → markDismissed 호출 + spotlight 사라짐

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/home/presentation/widgets/next_mission_spotlight.dart';
import 'package:lessonaza/features/profile/presentation/providers/quest_first_shown_provider.dart';

void main() {
  Widget wrap({
    bool dismissed = false,
    DateTime? firstShownAt,
    VoidCallback? onStart,
  }) {
    return ProviderScope(
      overrides: [
        nextMissionSpotlightDismissedProvider.overrideWith(
          () => _FakeSpotlightDismissed(dismissed),
        ),
        questFirstShownProvider.overrideWith(
          () => _FakeQuestFirstShown(firstShownAt),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              const Center(child: Text('DASHBOARD')),
              NextMissionSpotlight(onStart: onStart),
            ],
          ),
        ),
      ),
    );
  }

  setUp(() {
    _FakeSpotlightDismissed.markDismissedCallCount = 0;
    _FakeQuestFirstShown.markShownCallCount = 0;
  });

  group('NextMissionSpotlight (W4 Task 4.4)', () {
    testWidgets('dismissed == false → spotlight 노출', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.nextMissionSpotlightTitle), findsOneWidget);
      expect(find.text(AppStrings.nextMissionSpotlightHint), findsOneWidget);
      expect(find.text(AppStrings.nextMissionSpotlightStart), findsOneWidget);
      expect(find.text(AppStrings.nextMissionSpotlightLater), findsOneWidget);
      // 배경 dashboard 도 함께 노출 (Stack overlay).
      expect(find.text('DASHBOARD'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dismissed == true → spotlight 미노출 (두 번째 진입)', (tester) async {
      await tester.pumpWidget(wrap(dismissed: true));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.nextMissionSpotlightTitle), findsNothing);
      expect(find.text(AppStrings.nextMissionSpotlightStart), findsNothing);
      // Dashboard 만 노출.
      expect(find.text('DASHBOARD'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // UXC-2 회귀 — 이 테스트가 플래그 레이스의 오라클이다.
    // home_screen 이 첫 도착 시각을 기록한 뒤에도 spotlight 는 살아 있어야
    // 하고, 오직 [시작]/[나중에] 탭으로만 사라져야 한다.
    testWidgets('첫 도착 타임스탬프가 기록돼 있어도 spotlight 는 유지된다 (UXC-2)', (tester) async {
      await tester.pumpWidget(
        wrap(firstShownAt: DateTime.utc(2026, 8, 20, 10, 0)),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.nextMissionSpotlightTitle), findsOneWidget);
      expect(find.text(AppStrings.nextMissionSpotlightStart), findsOneWidget);
      expect(tester.takeException(), isNull);

      // [나중에] 탭 — 이때만 소거된다.
      await tester.tap(find.text(AppStrings.nextMissionSpotlightLater));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.nextMissionSpotlightTitle), findsNothing);
      // 첫 도착 타임스탬프는 spotlight 소거와 무관하게 그대로 유지
      // (QuestBoardCard 의 5분 윈도우가 이 값을 쓴다).
      expect(_FakeQuestFirstShown.markShownCallCount, 0);
    });

    testWidgets('[시작] 탭 → markDismissed + onStart 콜백', (tester) async {
      var started = false;
      await tester.pumpWidget(wrap(onStart: () => started = true));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.nextMissionSpotlightStart));
      await tester.pumpAndSettle();

      expect(_FakeSpotlightDismissed.markDismissedCallCount >= 1, isTrue);
      expect(started, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('[나중에] 탭 → markDismissed + spotlight 사라짐', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.nextMissionSpotlightLater));
      await tester.pumpAndSettle();

      expect(_FakeSpotlightDismissed.markDismissedCallCount >= 1, isTrue);
      // markDismissed 후 value 갱신 → spotlight 사라짐.
      expect(find.text(AppStrings.nextMissionSpotlightTitle), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

/// In-memory [NextMissionSpotlightDismissed] for spotlight tests.
class _FakeSpotlightDismissed extends NextMissionSpotlightDismissed {
  _FakeSpotlightDismissed(this._initial);

  static int markDismissedCallCount = 0;

  final bool _initial;
  bool? _value;

  @override
  Future<bool> build() async => _value ??= _initial;

  @override
  Future<void> markDismissed() async {
    markDismissedCallCount++;
    _value = true;
    state = const AsyncData(true);
  }
}

/// In-memory [QuestFirstShown] — 첫 도착 타임스탬프가 spotlight 노출에
/// 영향을 주지 않는지 확인하기 위한 spy.
class _FakeQuestFirstShown extends QuestFirstShown {
  _FakeQuestFirstShown(this._initial);

  static int markShownCallCount = 0;

  final DateTime? _initial;
  DateTime? _value;

  @override
  Future<DateTime?> build() async => _value ??= _initial;

  @override
  Future<void> markShown() async {
    markShownCallCount++;
    _value = DateTime.utc(2026, 8, 20);
    state = AsyncData(_value);
  }
}
