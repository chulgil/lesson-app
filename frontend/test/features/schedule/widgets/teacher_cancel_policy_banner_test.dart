import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/features/schedule/presentation/widgets/teacher_cancel_policy_banner.dart';

void main() {
  group('TeacherCancelPolicyBanner', () {
    testWidgets(
      'shows banner within 12h, teacher ownership (no academy line)',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: TeacherCancelPolicyBanner(
                hoursUntilLesson: 8.0,
                isAcademyOwnership: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('12시간 이내 취소입니다'), findsOneWidget);
        expect(find.text('학생 변경권 +1 자동 적립'), findsOneWidget);
        expect(find.text('학생에게 사과 카톡 자동 발송'), findsOneWidget);
        expect(find.text('학원 관리자에게 알림 발송'), findsNothing);
        expect(find.text('보강 일정은 강사님이 직접 안내·재입력'), findsOneWidget);
        expect(find.text('다음 레슨 추가 시간 안내'), findsOneWidget);
      },
    );

    testWidgets('shows academy notification line when academy ownership', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TeacherCancelPolicyBanner(
              hoursUntilLesson: 2.5,
              isAcademyOwnership: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('학원 관리자에게 알림 발송'), findsOneWidget);
    });

    testWidgets('hides banner when > 12h', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TeacherCancelPolicyBanner(hoursUntilLesson: 24.0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('12시간 이내 취소입니다'), findsNothing);
    });

    testWidgets('uses custom compensation message when provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TeacherCancelPolicyBanner(
              hoursUntilLesson: 6.0,
              compensationMessage: '다음 레슨 시 15분 추가로 보강드릴 예정입니다.',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('"다음 레슨 시 15분 추가로 보강드릴 예정입니다."'), findsOneWidget);
    });

    testWidgets('renders inside narrow Row without crash', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: Row(
                children: [
                  Expanded(
                    child: TeacherCancelPolicyBanner(
                      hoursUntilLesson: 5.0,
                      isAcademyOwnership: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
