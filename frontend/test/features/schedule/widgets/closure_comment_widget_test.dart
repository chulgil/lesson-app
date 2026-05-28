import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/features/schedule/presentation/widgets/closure_comment_widget.dart';

void main() {
  group('ClosureCommentWidget', () {
    testWidgets('renders title, hint, auto-apply notice in open window', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClosureCommentWidget(
              minutesUntilAutoApply: 47,
              onSubmit: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('의견 입력 (학원 관리자에게 전달)'), findsOneWidget);
      expect(find.text('47분 후 자동 적용됩니다.'), findsOneWidget);
      expect(find.text('학원 관리자가 즉시 적용할 수도 있습니다.'), findsOneWidget);
    });

    testWidgets('submit triggers callback with trimmed text', (tester) async {
      String? received;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClosureCommentWidget(
              minutesUntilAutoApply: 30,
              onSubmit: (text) => received = text,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '  보강 가능합니다  ');
      await tester.tap(find.text('의견 보내기'));
      await tester.pumpAndSettle();

      expect(received, '보강 가능합니다');
    });

    testWidgets('shows closed notice when window is closed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClosureCommentWidget(
              minutesUntilAutoApply: 0,
              isWindowClosed: true,
              onSubmit: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('의견 윈도우가 종료되었습니다.'), findsOneWidget);
      expect(find.text('학원 관리자가 즉시 적용할 수도 있습니다.'), findsNothing);
    });

    testWidgets('shows submitted state when comment provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClosureCommentWidget(
              minutesUntilAutoApply: 45,
              submittedComment: '기존 의견',
              onSubmit: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('의견이 전송되었습니다.'), findsOneWidget);
    });

    testWidgets('empty input does not trigger submit', (tester) async {
      var called = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClosureCommentWidget(
              minutesUntilAutoApply: 30,
              onSubmit: (_) => called = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('의견 보내기'));
      await tester.pumpAndSettle();

      expect(called, isFalse);
    });
  });
}
