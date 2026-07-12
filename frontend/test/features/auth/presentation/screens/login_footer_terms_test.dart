// 운영배포 게이트 감사(2026-07-12) — 로그인 footer TERMS·PRIVACY 배선.
//
// footer 가 정적 텍스트라 약관/개인정보처리방침에 로그인 화면에서 접근할 수
// 없었다 (가입 흐름에만 존재). 탭 시 온보딩과 동일한 열람 시트를 연다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/auth/presentation/screens/login_screen.dart';

Future<void> _pumpLogin(WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(child: MaterialApp(home: LoginScreen())),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('footer TERMS 탭 → 이용약관 열람 시트', (WidgetTester tester) async {
    await _pumpLogin(tester);

    final terms = find.text('TERMS');
    expect(terms, findsOneWidget);
    await tester.ensureVisible(terms);
    await tester.tap(terms);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.authTermsOfServiceTitle), findsOneWidget);
    expect(find.textContaining('제1조'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('footer PRIVACY 탭 → 개인정보처리방침 열람 시트', (WidgetTester tester) async {
    await _pumpLogin(tester);

    final privacy = find.text('PRIVACY');
    expect(privacy, findsOneWidget);
    await tester.ensureVisible(privacy);
    await tester.tap(privacy);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.authPrivacyPolicy), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
