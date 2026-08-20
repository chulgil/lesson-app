// #1186 — 로그인 화면 문구·폰트 회귀 가드.
//
// 1. 슬로건은 역할 중립이어야 한다 — 로그인 시점엔 선생님/학생/학부모를
//    알 수 없으므로 '선생님을 위한' 전용 문구 금지.
// 2. '학부모이신가요?' 링크는 소셜 버튼 라벨과 동일한 폰트(buttonLabelSerif,
//    Playfair)를 사용한다 — 손글씨체(hand/Gaegu) 사용 시 주변과 불일치
//    (이전 요청 미반영 재발 방지).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/notebook_typography.dart';
import 'package:lessonaza/features/auth/presentation/screens/login_screen.dart';

Future<void> _pumpLogin(WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(child: MaterialApp(home: LoginScreen())),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('슬로건은 역할 중립 문구를 사용한다', (WidgetTester tester) async {
    await _pumpLogin(tester);

    expect(find.textContaining('선생님을 위한'), findsNothing);
    expect(find.text(AppStrings.authSlogan), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('#1287 UXC-4a 로그인 화면은 앱 용도를 1문장으로 알려준다', (
    WidgetTester tester,
  ) async {
    await _pumpLogin(tester);

    // 슬로건은 장식이라 "무슨 앱인지" 를 말하지 않는다. 가입 전 유일한 WHAT 문장.
    expect(find.text(AppStrings.authValueProposition), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('학부모 링크는 소셜 버튼 라벨과 동일한 폰트를 사용한다', (WidgetTester tester) async {
    await _pumpLogin(tester);

    final linkFinder = find.text(AppStrings.authParentLoginLink);
    expect(linkFinder, findsOneWidget);

    final linkStyle = tester.widget<Text>(linkFinder).style!;
    final buttonFamily = NotebookTypography.buttonLabelSerif.fontFamily;
    expect(
      linkStyle.fontFamily,
      buttonFamily,
      reason: '학부모 링크 폰트는 버튼 라벨(Playfair)과 동일해야 한다 — 손글씨체 금지',
    );
    // 링크 어포던스(밑줄)는 유지한다.
    expect(linkStyle.decoration, TextDecoration.underline);
  });
}
