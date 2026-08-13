import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/features/profile/presentation/widgets/profile_visibility_widgets.dart';

/// G6/W3 — 강사 설정 화면 학원 공개 노출 동의 토글 위젯 회귀 테스트.
///
/// AcademyVisibilitySection 은 ProfileVisibilityScreen 에 통합되어 학원 소속
/// 강사에게만 노출되고, 학원별 토글 ON/OFF 를 PATCH 콜백으로 전달한다.
void main() {
  group('AcademyVisibilitySection', () {
    testWidgets('renders nothing when academies list is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AcademyVisibilitySection(
              academies: const [],
              onToggle: (_, __) {},
              onViewActivity: (_) {},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('학원별 공개 페이지 노출'), findsNothing);
      expect(find.byType(Switch), findsNothing);
    });

    testWidgets('renders one toggle per academy', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AcademyVisibilitySection(
              academies: const [
                AcademyVisibilityItem(
                  academyId: 'acad_1',
                  academyName: 'OO음악학원',
                  consent: true,
                  actorMemberId: 'member_1',
                ),
                AcademyVisibilityItem(
                  academyId: 'acad_2',
                  academyName: 'XX피아노학원',
                  consent: false,
                  actorMemberId: 'member_2',
                ),
              ],
              onToggle: (_, __) {},
              onViewActivity: (_) {},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('학원별 공개 페이지 노출'), findsOneWidget);
      expect(find.text('OO음악학원'), findsOneWidget);
      expect(find.text('XX피아노학원'), findsOneWidget);
      expect(find.byType(Switch), findsNWidgets(2));
    });

    testWidgets('tapping the activity entry invokes onViewActivity with the '
        "tapped academy's actorMemberId (#1264 orphan screen wiring)", (
      tester,
    ) async {
      const item = AcademyVisibilityItem(
        academyId: 'acad_1',
        academyName: 'OO음악학원',
        consent: true,
        actorMemberId: 'member_1',
      );
      AcademyVisibilityItem? tapped;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AcademyVisibilitySection(
              academies: const [item],
              onToggle: (_, __) {},
              onViewActivity: (academy) => tapped = academy,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(tapped, item);
      expect(tapped?.actorMemberId, 'member_1');
    });

    testWidgets('toggling switch invokes onToggle with new value', (
      tester,
    ) async {
      final invocations = <(String, bool)>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AcademyVisibilitySection(
              academies: const [
                AcademyVisibilityItem(
                  academyId: 'acad_1',
                  academyName: 'OO음악학원',
                  consent: false,
                  actorMemberId: 'member_1',
                ),
              ],
              onToggle: (id, value) => invocations.add((id, value)),
              onViewActivity: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(invocations, [('acad_1', true)]);
    });

    testWidgets('isLoading disables switches', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AcademyVisibilitySection(
              academies: const [
                AcademyVisibilityItem(
                  academyId: 'acad_1',
                  academyName: 'OO음악학원',
                  consent: true,
                  actorMemberId: 'member_1',
                ),
              ],
              onToggle: (_, __) {},
              onViewActivity: (_) {},
              isLoading: true,
            ),
          ),
        ),
      );

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.onChanged, isNull);
    });
  });
}
