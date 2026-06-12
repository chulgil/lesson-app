import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/domain/entities/spotlight_prompt.dart';
import 'package:lessonaza/features/gamification/domain/entities/spotlight_type.dart';
import 'package:lessonaza/features/gamification/presentation/widgets/practice_celebration_overlay.dart';

Future<void> _pump(
  WidgetTester tester, {
  int minutes = 12,
  int streak = 3,
  required VoidCallback onDismiss,
  Duration total = const Duration(milliseconds: 1500),
  SpotlightPrompt? spotlightPrompt,
  ValueChanged<SpotlightPrompt>? onSpotlightAccept,
  ValueChanged<SpotlightPrompt>? onSpotlightDecline,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PracticeCelebrationOverlay(
          practiceMinutes: minutes,
          streakDays: streak,
          onDismiss: onDismiss,
          totalDuration: total,
          spotlightPrompt: spotlightPrompt,
          onSpotlightAccept: onSpotlightAccept,
          onSpotlightDecline: onSpotlightDecline,
        ),
      ),
    ),
  );
}

SpotlightPrompt _makePrompt({
  String id = 'p1',
  SpotlightType type = SpotlightType.teacherRec,
  String title = '바이올린 비브라토 입문',
}) => SpotlightPrompt(
  id: id,
  studentId: 's1',
  type: type,
  title: title,
  queuedAt: DateTime.utc(2026, 6, 12),
);

void main() {
  testWidgets('renders minutes / streak / sparkle text', (tester) async {
    await _pump(tester, onDismiss: () {});
    expect(find.byKey(const ValueKey('celebration_minutes')), findsOneWidget);
    expect(find.text('12분 했어요!'), findsOneWidget);
    expect(find.byKey(const ValueKey('celebration_streak')), findsOneWidget);
    expect(find.text('🔥 3일 연속'), findsOneWidget);
    expect(find.text('✨'), findsOneWidget);
    expect(tester.takeException(), isNull);
    // 명시적으로 timer 회수
    await tester.pumpAndSettle();
  });

  testWidgets('invokes onDismiss after totalDuration (1500ms default)', (
    tester,
  ) async {
    var dismissed = 0;
    await _pump(tester, onDismiss: () => dismissed++);
    expect(dismissed, 0);
    await tester.pumpAndSettle();
    expect(dismissed, 1);
  });

  testWidgets('does not invoke onDismiss before totalDuration elapses', (
    tester,
  ) async {
    var dismissed = 0;
    await _pump(
      tester,
      onDismiss: () => dismissed++,
      total: const Duration(milliseconds: 1000),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(dismissed, 0);
    await tester.pumpAndSettle();
    expect(dismissed, 1);
  });

  testWidgets('onDismiss fires exactly once even with custom totalDuration', (
    tester,
  ) async {
    var dismissed = 0;
    await _pump(
      tester,
      onDismiss: () => dismissed++,
      total: const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 200));
    expect(dismissed, 1);
  });

  testWidgets('renders on narrow viewport without exception', (tester) async {
    tester.view.physicalSize = const Size(375 * 3, 667 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    await _pump(tester, minutes: 999, streak: 999, onDismiss: () {});
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
  });

  group('P3 — SpotlightSlot 통합', () {
    testWidgets('spotlightPrompt=null 회귀 — 1.5초 후 onDismiss (P1 SC-1)', (
      tester,
    ) async {
      var dismissed = 0;
      await _pump(tester, onDismiss: () => dismissed++);
      await tester.pumpAndSettle();
      expect(dismissed, 1, reason: 'spotlight 없으면 기존 동작');
      expect(find.byKey(const ValueKey('spotlight_slot')), findsNothing);
    });

    testWidgets('spotlightPrompt!=null — 1.5초 축하 후 slot 표시 + onDismiss 보류', (
      tester,
    ) async {
      var dismissed = 0;
      await _pump(
        tester,
        spotlightPrompt: _makePrompt(),
        onDismiss: () => dismissed++,
      );
      // 1.5초 축하 phase + setState 적용 + rebuild
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('spotlight_slot')), findsOneWidget);
      expect(dismissed, 0, reason: 'slot 표시 동안 dismiss 보류');
    });

    testWidgets('"지금 볼래" tap → onSpotlightAccept + onDismiss', (tester) async {
      var dismissed = 0;
      SpotlightPrompt? accepted;
      SpotlightPrompt? declined;
      final prompt = _makePrompt();
      await _pump(
        tester,
        spotlightPrompt: prompt,
        onDismiss: () => dismissed++,
        onSpotlightAccept: (p) => accepted = p,
        onSpotlightDecline: (p) => declined = p,
      );
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('spotlight_accept')));
      await tester.pumpAndSettle();

      expect(accepted?.id, prompt.id);
      expect(declined, isNull);
      expect(dismissed, 1);
    });

    testWidgets('"다음에" tap → onSpotlightDecline + onDismiss', (tester) async {
      var dismissed = 0;
      SpotlightPrompt? accepted;
      SpotlightPrompt? declined;
      final prompt = _makePrompt();
      await _pump(
        tester,
        spotlightPrompt: prompt,
        onDismiss: () => dismissed++,
        onSpotlightAccept: (p) => accepted = p,
        onSpotlightDecline: (p) => declined = p,
      );
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('spotlight_decline')));
      await tester.pumpAndSettle();

      expect(declined?.id, prompt.id);
      expect(accepted, isNull);
      expect(dismissed, 1);
    });

    testWidgets('1.5초 이전엔 spotlight slot 미노출 (축하 phase 유지)', (tester) async {
      await _pump(tester, spotlightPrompt: _makePrompt(), onDismiss: () {});
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const ValueKey('spotlight_slot')), findsNothing);
      expect(find.byKey(const ValueKey('celebration_minutes')), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });
}
