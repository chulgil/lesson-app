// #1165 — 보강 크레딧 진입점 배선 검증.
//
// MakeupCreditScreen 은 라우트만 등록되고 네비게이션이 0건이었다.
//   - 학생: 수강권 목록 하단 MakeupCreditSummaryCard → makeupCredits push.
//   - 선생님: 학생 상세(정보 탭) 인라인 TeacherMakeupCreditSection.
// 렌더/탭/빈 상태 graceful + 소스 계약(학생 상세 배선)을 검증한다.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/features/subscription/data/repositories/mock_makeup_credit_repository.dart';
import 'package:lessonaza/features/subscription/domain/entities/makeup_credit.dart';
import 'package:lessonaza/features/subscription/presentation/providers/makeup_credit_providers.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/makeup_credit_summary_card.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/teacher_makeup_credit_section.dart';

Widget _scoped(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: [
      makeupCreditRepositoryProvider.overrideWithValue(
        MockMakeupCreditRepository(),
      ),
      ...overrides,
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('MakeupCreditSummaryCard (학생)', () {
    testWidgets('크레딧 이력이 있으면 요약을 렌더한다', (tester) async {
      await tester.pumpWidget(_scoped(MakeupCreditSummaryCard(onTap: () {})));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.makeupCreditTitle), findsOneWidget);
      // 보유 잔액 라벨 ("보유: N회") 이 요약 라인에 포함된다.
      expect(find.textContaining('보유:'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('탭 시 onTap 이 호출된다', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _scoped(MakeupCreditSummaryCard(onTap: () => tapped = true)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.makeupCreditTitle));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('크레딧 이력이 없으면 아무것도 그리지 않는다', (tester) async {
      await tester.pumpWidget(
        _scoped(
          MakeupCreditSummaryCard(onTap: () {}),
          overrides: [
            studentMakeupCreditsProvider.overrideWith(
              (ref) async => <MakeupCredit>[],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.makeupCreditTitle), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('탭 시 makeupCredits 라우트로 이동한다', (tester) async {
      final visited = <String>[];
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder:
                (ctx, state) => Scaffold(
                  body: MakeupCreditSummaryCard(
                    onTap: () => ctx.push(AppRoutes.makeupCredits),
                  ),
                ),
          ),
          GoRoute(
            path: AppRoutes.makeupCredits,
            builder: (ctx, state) {
              visited.add(AppRoutes.makeupCredits);
              return const Scaffold(body: Text('makeup'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            makeupCreditRepositoryProvider.overrideWithValue(
              MockMakeupCreditRepository(),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.makeupCreditTitle));
      await tester.pumpAndSettle();

      expect(visited, contains(AppRoutes.makeupCredits));
      expect(tester.takeException(), isNull);
    });
  });

  group('TeacherMakeupCreditSection (선생님 — 학생 상세)', () {
    testWidgets('발급한 크레딧이 없으면 빈 상태 문구로 graceful 하게 렌더한다', (tester) async {
      // 'no-credit-student' 는 Mock 에 크레딧이 없어 listTeacherCredits 가 빈 목록.
      await tester.pumpWidget(
        _scoped(
          const TeacherMakeupCreditSection(studentId: 'no-credit-student'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.makeupCreditManageTitle), findsOneWidget);
      expect(find.text(AppStrings.makeupCreditEmpty), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  test('student_info_tab 이 TeacherMakeupCreditSection 을 인라인 배선한다', () {
    final source =
        File(
          'lib/features/students/presentation/widgets/student_detail/student_info_tab.dart',
        ).readAsStringSync();

    expect(
      source,
      contains('TeacherMakeupCreditSection(studentId: student.id)'),
    );
  });
}
