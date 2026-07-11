import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/gamification/presentation/widgets/practice_start_card.dart';

/// Slice 2 — [PracticeStartCard] "이어서" 칩 노출 조건 검증.
/// continuePieceName + onContinueTap 이 함께 주어질 때만 칩(key
/// 'practice_start_continue')이 나타나고, 둘 중 하나라도 null 이면 숨는다.

Future<void> _pump(
  WidgetTester tester, {
  String? continuePieceName,
  VoidCallback? onContinueTap,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: PracticeStartCard(
          studentName: '민지',
          streakDays: 3,
          yesterdayMinutes: 25,
          onStartTap: () {},
          continuePieceName: continuePieceName,
          onContinueTap: onContinueTap,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('chip shows and is tappable when pieceName + onContinueTap set', (
    tester,
  ) async {
    var taps = 0;
    await _pump(tester, continuePieceName: '캐논', onContinueTap: () => taps++);

    expect(
      find.byKey(const ValueKey('practice_start_continue')),
      findsOneWidget,
    );
    expect(find.text('이어서: 캐논'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('practice_start_continue')));
    await tester.pump();

    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chip absent when continuePieceName is null', (tester) async {
    await _pump(tester, continuePieceName: null, onContinueTap: () {});

    expect(find.byKey(const ValueKey('practice_start_continue')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chip absent when onContinueTap is null', (tester) async {
    await _pump(tester, continuePieceName: '캐논', onContinueTap: null);

    expect(find.byKey(const ValueKey('practice_start_continue')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
