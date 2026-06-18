// W2 Task 2.3 — CategoryCard widget smoke test.
// HARD-GATE: design-principles.md (widget-smoke-test).
// spec §7.2 시안 + §11.1 상태 라벨 규칙.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/profile/presentation/providers/category_status_provider.dart';
import 'package:lessonaza/features/profile/presentation/widgets/category_card.dart';

void main() {
  Widget wrap(Widget child, {double? width}) {
    return MaterialApp(
      home: Scaffold(body: SizedBox(width: width ?? 360, child: child)),
    );
  }

  group('CategoryCard widget smoke + 상태 (W2 Task 2.3)', () {
    testWidgets('Complete 상태 — 설정완료 라벨 + 노란점 없음', (tester) async {
      await tester.pumpWidget(
        wrap(
          CategoryCard(
            title: '운영시간',
            icon: Icons.access_time,
            status: const CategoryStatusComplete(),
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('운영시간'), findsOneWidget);
      expect(find.text(AppStrings.categoryStatusComplete), findsOneWidget);
      expect(find.byKey(const Key('category_card_dot_warning')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Partial 상태 (hintKey 없음) — N/M 라벨', (tester) async {
      await tester.pumpWidget(
        wrap(
          CategoryCard(
            title: '내 프로필',
            icon: Icons.person,
            status: const CategoryStatusPartial(filled: 2, total: 3),
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2/3 항목'), findsOneWidget);
      expect(find.byKey(const Key('category_card_dot_warning')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Partial 상태 (hintKey 있음) — hint 라벨 + 노란점 없음', (tester) async {
      await tester.pumpWidget(
        wrap(
          CategoryCard(
            title: '운영시간',
            icon: Icons.access_time,
            status: const CategoryStatusPartial(
              filled: 1,
              total: 2,
              hintKey: categoryHintKeyBreakTimeMissing,
            ),
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.categoryHintBreakTimeMissing),
        findsOneWidget,
      );
      expect(find.byKey(const Key('category_card_dot_warning')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Empty 상태 — 미설정 라벨 + 노란점 표시', (tester) async {
      await tester.pumpWidget(
        wrap(
          CategoryCard(
            title: '수강권·정산',
            icon: Icons.payments,
            status: const CategoryStatusEmpty(),
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.categoryStatusEmpty), findsOneWidget);
      expect(
        find.byKey(const Key('category_card_dot_warning')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Neutral 상태 — 기본값 라벨', (tester) async {
      await tester.pumpWidget(
        wrap(
          CategoryCard(
            title: '알림·소식·지원',
            icon: Icons.settings,
            status: const CategoryStatusNeutral(),
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.categoryStatusNeutralDefault),
        findsOneWidget,
      );
      expect(find.byKey(const Key('category_card_dot_warning')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('showNewBadge true — NEW 배지 노출', (tester) async {
      await tester.pumpWidget(
        wrap(
          CategoryCard(
            title: '수업방식',
            icon: Icons.school,
            status: const CategoryStatusComplete(),
            onTap: () {},
            showNewBadge: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('category_card_badge_new')), findsOneWidget);
      expect(find.text(AppStrings.categoryNewBadge), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('showNewBadge false (기본) — NEW 배지 숨김', (tester) async {
      await tester.pumpWidget(
        wrap(
          CategoryCard(
            title: '수업방식',
            icon: Icons.school,
            status: const CategoryStatusComplete(),
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('category_card_badge_new')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('탭 → onTap 콜백 호출', (tester) async {
      var tapCount = 0;
      await tester.pumpWidget(
        wrap(
          CategoryCard(
            title: '운영시간',
            icon: Icons.access_time,
            status: const CategoryStatusComplete(),
            onTap: () => tapCount++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CategoryCard));
      await tester.pumpAndSettle();

      expect(tapCount, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('좁은 width (280px) — BoxConstraints 크래시 없음', (tester) async {
      // Row 안에 Expanded + 다중 라벨 + chevron 이 좁은 폭에서도 안전한지 검증.
      await tester.pumpWidget(
        wrap(
          CategoryCard(
            title: '수강권·정산',
            icon: Icons.payments,
            status: const CategoryStatusEmpty(),
            onTap: () {},
            showNewBadge: true,
          ),
          width: 280,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
