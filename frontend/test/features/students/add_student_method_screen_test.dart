import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/students/presentation/screens/add_student_method_screen.dart';

void main() {
  Widget buildSubject() {
    return MaterialApp(
      theme: AppTheme.light,
      home: const AddStudentMethodScreen(),
    );
  }

  testWidgets('직접 등록 카드가 초대 카드보다 위(1차 CTA)에 위치한다 (#798 UX #29)', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    final directFinder = find.text(AppStrings.studentDirectRegister);
    final inviteFinder = find.text(AppStrings.studentInviteTitle);

    expect(directFinder, findsOneWidget);
    expect(inviteFinder, findsOneWidget);

    // 직접 등록 카드가 초대 카드보다 화면 상단(y 좌표 작음)에 위치해야 한다.
    final directY = tester.getTopLeft(directFinder).dy;
    final inviteY = tester.getTopLeft(inviteFinder).dy;
    expect(directY, lessThan(inviteY), reason: '직접 등록이 초대보다 위에 있어야 한다');
  });

  testWidgets('320px 좁은 화면에서 렌더 크래시 없음', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('직접 등록 버튼(작성하기)이 FilledButton(1차 CTA)으로 렌더된다', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    final directButton = find.text(AppStrings.studentAddMethodDirectButton);
    expect(directButton, findsOneWidget);

    // 직접 등록(isPrimary=true) → FilledButton 이어야 한다
    final filledButton = find.ancestor(
      of: directButton,
      matching: find.byType(FilledButton),
    );
    expect(
      filledButton,
      findsOneWidget,
      reason: '직접 등록 카드의 버튼은 isPrimary=true → FilledButton',
    );
  });
}
