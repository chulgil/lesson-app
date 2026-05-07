import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/onboarding/presentation/screens/tutorial_screen.dart';

void main() {
  testWidgets('teacher tutorial requires interaction across three steps', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light, home: const TutorialScreen()),
      ),
    );

    expect(find.text('1. 선생님 기본 정보'), findsOneWidget);
    expect(find.text('2. 샘플 학생 만들기'), findsNothing);

    final nextButton = find.widgetWithText(ElevatedButton, '다음');
    expect(tester.widget<ElevatedButton>(nextButton).onPressed, isNull);

    await tester.enterText(find.byKey(const ValueKey('tutorial_name')), '김선생');
    await tester.tap(find.text('피아노'));
    await tester.pumpAndSettle();

    expect(tester.widget<ElevatedButton>(nextButton).onPressed, isNotNull);
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    expect(find.text('2. 샘플 학생 만들기'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(nextButton).onPressed, isNull);

    await tester.tap(find.text('샘플 학생 생성'));
    await tester.pumpAndSettle();

    expect(tester.widget<ElevatedButton>(nextButton).onPressed, isNotNull);
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    expect(find.text('3. 첫 레슨 노트'), findsOneWidget);
    final startButton = find.widgetWithText(ElevatedButton, '시작하기');
    expect(tester.widget<ElevatedButton>(startButton).onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('tutorial_note')),
      '오늘은 오른손 멜로디를 부드럽게 연결하는 연습을 했습니다.',
    );
    await tester.pumpAndSettle();

    expect(tester.widget<ElevatedButton>(startButton).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });
}
