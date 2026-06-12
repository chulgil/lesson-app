// W4 Task 4.4 — NextMissionSpotlight smoke + 동작 회귀 테스트.
// HARD-GATE: design-principles.md (widget-smoke-test).
// spec §9.1 Step 3 — 가입 후 메인 첫 진입 1회 spotlight.
//
// Verifies:
// - questFirstShownProvider value == null → spotlight 노출 (타이틀/힌트/CTA)
// - questFirstShownProvider value != null → spotlight 미노출 (SizedBox.shrink)
// - [시작] 탭 → markShown 호출 + onStart 콜백
// - [나중에] 탭 → markShown 호출 + spotlight 사라짐

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/home/presentation/widgets/next_mission_spotlight.dart';
import 'package:lessonaza/features/profile/presentation/providers/quest_first_shown_provider.dart';

void main() {
  Widget wrap({DateTime? initialValue, VoidCallback? onStart}) {
    return ProviderScope(
      overrides: [
        questFirstShownProvider.overrideWith(
          () => _FakeQuestFirstShown(initialValue),
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

  group('NextMissionSpotlight (W4 Task 4.4)', () {
    testWidgets('value == null → spotlight 노출', (tester) async {
      _FakeQuestFirstShown.markShownCallCount = 0;
      await tester.pumpWidget(wrap(initialValue: null));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.nextMissionSpotlightTitle), findsOneWidget);
      expect(find.text(AppStrings.nextMissionSpotlightHint), findsOneWidget);
      expect(find.text(AppStrings.nextMissionSpotlightStart), findsOneWidget);
      expect(find.text(AppStrings.nextMissionSpotlightLater), findsOneWidget);
      // 배경 dashboard 도 함께 노출 (Stack overlay).
      expect(find.text('DASHBOARD'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('value != null → spotlight 미노출 (두 번째 진입)', (tester) async {
      _FakeQuestFirstShown.markShownCallCount = 0;
      await tester.pumpWidget(
        wrap(initialValue: DateTime.utc(2026, 6, 11, 10, 0)),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.nextMissionSpotlightTitle), findsNothing);
      expect(find.text(AppStrings.nextMissionSpotlightStart), findsNothing);
      // Dashboard 만 노출.
      expect(find.text('DASHBOARD'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('[시작] 탭 → markShown + onStart 콜백', (tester) async {
      _FakeQuestFirstShown.markShownCallCount = 0;
      var started = false;
      await tester.pumpWidget(
        wrap(initialValue: null, onStart: () => started = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.nextMissionSpotlightStart));
      await tester.pumpAndSettle();

      expect(_FakeQuestFirstShown.markShownCallCount >= 1, isTrue);
      expect(started, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('[나중에] 탭 → markShown + spotlight 사라짐', (tester) async {
      _FakeQuestFirstShown.markShownCallCount = 0;
      await tester.pumpWidget(wrap(initialValue: null));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.nextMissionSpotlightLater));
      await tester.pumpAndSettle();

      expect(_FakeQuestFirstShown.markShownCallCount >= 1, isTrue);
      // markShown 후 value 갱신 → spotlight 사라짐.
      expect(find.text(AppStrings.nextMissionSpotlightTitle), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

/// In-memory [QuestFirstShown] for spotlight tests.
class _FakeQuestFirstShown extends QuestFirstShown {
  _FakeQuestFirstShown(this._initial);

  static int markShownCallCount = 0;

  final DateTime? _initial;
  DateTime? _value;

  @override
  Future<DateTime?> build() async {
    _value ??= _initial;
    return _value;
  }

  @override
  Future<void> markShown() async {
    markShownCallCount++;
    _value = DateTime.utc(2026, 6, 12);
    state = AsyncData(_value);
  }
}
