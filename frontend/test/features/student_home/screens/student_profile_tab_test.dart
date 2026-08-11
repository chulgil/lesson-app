import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/student_home/presentation/providers/student_home_profile_provider.dart';
import 'package:lessonaza/features/student_home/presentation/screens/student_profile_tab.dart';

void main() {
  group('StudentProfileTab — #89 masthead/menu 정비 smoke', () {
    const fakeProfile = StudentHomeProfileState(
      studentId: 'student-1',
      name: '홍길동',
      initial: '홍',
      email: 'hong@example.com',
      instrument: '바이올린',
      lessonCountLabel: '12회',
      practiceTimeLabel: '8시간',
      lessonPeriodLabel: '3개월',
      repertoireCount: 2,
      teacherSubtitle: '김선생님',
    );

    Future<void> pumpTab(WidgetTester tester) async {
      // 440x900: pre-existing masthead 폭 오버플로 회피 (별도 이슈).
      await tester.binding.setSurfaceSize(const Size(440, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentHomeProfileProvider.overrideWithValue(fakeProfile),
          ],
          child: const MaterialApp(home: Scaffold(body: StudentProfileTab())),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders without exceptions after masthead gear removal', (
      tester,
    ) async {
      await pumpTab(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'masthead no longer shows a settings gear (duplicate removed)',
      (tester) async {
        await pumpTab(tester);
        // #89: masthead gear (Icons.settings_outlined) was a duplicate of the
        // explicit "알림 설정" menu item and has been removed.
        expect(find.byIcon(Icons.settings_outlined), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('"내 레슨 요청" 메뉴 행이 제거됨 (P1: 레슨 탭 상단 섹션으로 이동, 중복 메뉴 금지)', (
      tester,
    ) async {
      await pumpTab(tester);
      // 대기중 신청 진입점이 레슨 탭으로 이동했으므로 프로필의 별도 항목은
      // 제거된다 — 아이콘 재사용 없음(assignment_outlined 는 이 행 전용).
      expect(find.byIcon(Icons.assignment_outlined), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
