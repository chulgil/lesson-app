// #779 — 신원 스트립 전화/문자 1탭 단축 버튼 테스트.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/students/presentation/widgets/student_detail/student_contact_actions.dart';

void main() {
  Widget host(String? phone) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: Center(child: StudentContactActions(phone: phone))),
  );

  testWidgets('전화번호 있으면 전화/문자 2개 버튼 노출', (tester) async {
    await tester.pumpWidget(host('010-1234-5678'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.studentContactCallShort), findsOneWidget);
    expect(find.text(AppStrings.studentContactMessageShort), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('전화번호 없으면 미노출 (SizedBox.shrink)', (tester) async {
    await tester.pumpWidget(host(null));
    await tester.pumpAndSettle();

    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.text(AppStrings.studentContactCallShort), findsNothing);
  });

  testWidgets('빈 문자열 전화번호도 미노출', (tester) async {
    await tester.pumpWidget(host(''));
    await tester.pumpAndSettle();

    expect(find.byType(OutlinedButton), findsNothing);
  });
}
