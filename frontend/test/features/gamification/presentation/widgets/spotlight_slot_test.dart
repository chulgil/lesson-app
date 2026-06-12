import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/gamification/domain/entities/spotlight_prompt.dart';
import 'package:lessonaza/features/gamification/domain/entities/spotlight_type.dart';
import 'package:lessonaza/features/gamification/presentation/widgets/spotlight_slot.dart';

void main() {
  SpotlightPrompt make({
    SpotlightType type = SpotlightType.teacherRec,
    String title = '바이올린 비브라토 입문',
  }) => SpotlightPrompt(
    id: 'p1',
    studentId: 's1',
    type: type,
    title: title,
    queuedAt: DateTime.utc(2026, 6, 12),
  );

  Future<void> pumpSlot(
    WidgetTester tester, {
    required SpotlightPrompt prompt,
    required VoidCallback onAccept,
    required VoidCallback onDecline,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpotlightSlot(
            prompt: prompt,
            onAccept: onAccept,
            onDecline: onDecline,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'smoke — no exception');
  }

  testWidgets('renders without exception (smoke HARD-GATE)', (tester) async {
    await pumpSlot(tester, prompt: make(), onAccept: () {}, onDecline: () {});
  });

  testWidgets('teacherRec header — "선생님이 추천했어요"', (tester) async {
    await pumpSlot(
      tester,
      prompt: make(type: SpotlightType.teacherRec),
      onAccept: () {},
      onDecline: () {},
    );
    expect(find.text(AppStrings.spotlightHeaderTeacherRec), findsOneWidget);
  });

  testWidgets('seasonEvent header — "이번 달 추천"', (tester) async {
    await pumpSlot(
      tester,
      prompt: make(type: SpotlightType.seasonEvent),
      onAccept: () {},
      onDecline: () {},
    );
    expect(find.text(AppStrings.spotlightHeaderSeasonEvent), findsOneWidget);
  });

  testWidgets('routineSuggestion header — "이거 어때요?"', (tester) async {
    await pumpSlot(
      tester,
      prompt: make(type: SpotlightType.routineSuggestion),
      onAccept: () {},
      onDecline: () {},
    );
    expect(
      find.text(AppStrings.spotlightHeaderRoutineSuggestion),
      findsOneWidget,
    );
  });

  testWidgets('title 표시 + ellipsis 안전 (long title)', (tester) async {
    await pumpSlot(
      tester,
      prompt: make(title: '한 줄을 넘는 매우 긴 제목으로 ellipsis 회귀 검증용 텍스트'),
      onAccept: () {},
      onDecline: () {},
    );
    expect(find.byKey(const ValueKey('spotlight_title')), findsOneWidget);
  });

  testWidgets('"지금 볼래" tap → onAccept 호출', (tester) async {
    var acceptCount = 0;
    var declineCount = 0;
    await pumpSlot(
      tester,
      prompt: make(),
      onAccept: () => acceptCount++,
      onDecline: () => declineCount++,
    );

    await tester.tap(find.byKey(const ValueKey('spotlight_accept')));
    await tester.pumpAndSettle();
    expect(acceptCount, 1);
    expect(declineCount, 0);
  });

  testWidgets('"다음에" tap → onDecline 호출', (tester) async {
    var acceptCount = 0;
    var declineCount = 0;
    await pumpSlot(
      tester,
      prompt: make(),
      onAccept: () => acceptCount++,
      onDecline: () => declineCount++,
    );

    await tester.tap(find.byKey(const ValueKey('spotlight_decline')));
    await tester.pumpAndSettle();
    expect(declineCount, 1);
    expect(acceptCount, 0);
  });

  testWidgets('두 버튼 동등 비중 — Expanded 안 같은 minimumSize', (tester) async {
    await pumpSlot(tester, prompt: make(), onAccept: () {}, onDecline: () {});

    final acceptSize = tester.getSize(
      find.byKey(const ValueKey('spotlight_accept')),
    );
    final declineSize = tester.getSize(
      find.byKey(const ValueKey('spotlight_decline')),
    );
    // Expanded 안 같은 폭 + buttonHeightSmall 높이.
    expect(
      (acceptSize.width - declineSize.width).abs(),
      lessThan(0.5),
      reason: '동일 비중 (§7.4)',
    );
    expect(acceptSize.height, declineSize.height);
  });

  testWidgets('금지 메시징 — "꼭 해야" / "필수" 미노출 (§7.4)', (tester) async {
    for (final type in SpotlightType.values) {
      await pumpSlot(
        tester,
        prompt: make(type: type),
        onAccept: () {},
        onDecline: () {},
      );
      expect(find.textContaining('꼭 해야'), findsNothing);
      expect(find.textContaining('필수'), findsNothing);
    }
  });
}
