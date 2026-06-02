import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/features/auth/presentation/widgets/terms_agreement_section.dart';

/// #430 G1 — 약관 동의 섹션 위젯 스모크 테스트.
///
/// 정책: 필수 묶음(서비스 이용약관 + 개인정보 처리방침) + 마케팅 동의(선택)
/// 의 2단 구조. 필수 두 항목이 모두 체크되어야 `requiredAccepted = true`
/// 가 emit 된다.
void main() {
  group('TermsAgreementSection', () {
    Future<void> pumpSection(
      WidgetTester tester, {
      required ValueChanged<TermsAgreementState> onChanged,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TermsAgreementSection(onChanged: onChanged),
            ),
          ),
        ),
      );
    }

    testWidgets('initial state has no consent and no exception', (
      tester,
    ) async {
      TermsAgreementState? last;
      await pumpSection(tester, onChanged: (s) => last = s);

      expect(tester.takeException(), isNull);
      expect(find.text('전체 동의'), findsOneWidget);
      expect(find.text('[필수]'), findsNWidgets(2));
      expect(find.text('[선택]'), findsOneWidget);
      expect(last, isNull); // no emit before user interaction
    });

    testWidgets(
      'tapping select-all emits requiredAccepted true with marketing',
      (tester) async {
        TermsAgreementState? last;
        await pumpSection(tester, onChanged: (s) => last = s);

        await tester.tap(find.text('전체 동의'));
        await tester.pump();

        expect(last, isNotNull);
        expect(last!.requiredAccepted, isTrue);
        expect(last!.marketingConsent, isTrue);
      },
    );

    testWidgets(
      'tapping only required items emits requiredAccepted true without marketing',
      (tester) async {
        TermsAgreementState? last;
        await pumpSection(tester, onChanged: (s) => last = s);

        // Tap two required items
        final requiredItems = find.text('[필수]');
        await tester.tap(requiredItems.first);
        await tester.pump();
        expect(last!.requiredAccepted, isFalse); // only one of two

        await tester.tap(requiredItems.last);
        await tester.pump();
        expect(last!.requiredAccepted, isTrue);
        expect(last!.marketingConsent, isFalse);
      },
    );

    testWidgets('marketing only does not satisfy requiredAccepted', (
      tester,
    ) async {
      TermsAgreementState? last;
      await pumpSection(tester, onChanged: (s) => last = s);

      await tester.tap(find.text('[선택]'));
      await tester.pump();

      expect(last!.requiredAccepted, isFalse);
      expect(last!.marketingConsent, isTrue);
    });
  });
}
