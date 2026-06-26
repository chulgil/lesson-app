import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/student_home/student_home_ui_facade.dart';

void main() {
  testWidgets('LanguageSelectSheet renders Korean only without exceptions', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LanguageSelectSheet())),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // 지원 언어(한국어)와 설정 헤더가 보인다.
    expect(find.text(AppStrings.studentHomeLanguageKorean), findsOneWidget);
    expect(find.text(AppStrings.studentHomeLanguageSettings), findsOneWidget);
  });

  testWidgets(
    'LanguageSelectSheet has no EN/JP coming-soon NO-OP rows (#506)',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LanguageSelectSheet())),
      );
      await tester.pumpAndSettle();

      // EN/JP 허위 affordance 제거 — "준비 중" 배지/언어 항목이 없어야 한다.
      expect(find.text('English'), findsNothing);
      expect(find.text('日本語'), findsNothing);
      expect(find.text('준비 중'), findsNothing);
    },
  );
}
