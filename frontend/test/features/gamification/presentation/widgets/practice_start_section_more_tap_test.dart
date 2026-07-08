import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/features/gamification/domain/entities/growth_heatmap.dart';
import 'package:lessonaza/features/gamification/presentation/providers/growth_heatmap_provider.dart';
import 'package:lessonaza/features/gamification/presentation/widgets/practice_start_section.dart';
import 'package:lessonaza/features/practice/presentation/providers/practice_repertoire_crud_provider.dart';
import 'package:lessonaza/features/students/domain/entities/student.dart';
import 'package:lessonaza/features/students/presentation/providers/student_crud_provider.dart';

/// Job 9 Task 9.2 / AC-6.4 — PracticeStartSection 점점점 (· · ·) tap 시
/// `/student/growth-detail?studentId=<id>` 로 라우팅 검증.
///
/// 패턴: GoRouter spy mock + 동기 Future (feedback_spy_mock_for_router_tests).
/// Future.delayed 회피 — pumpAndSettle 후 즉시 검증.
void main() {
  testWidgets('점점점 tap → /student/growth-detail 라우팅 (spy mock + 동기)', (
    tester,
  ) async {
    final mockStudent = Student(
      id: 's1',
      name: '민지',
      instrument: 'piano',
      nickname: '민지짱',
      createdAt: DateTime(2026, 1, 1),
    );
    final mockHeatmap = GrowthHeatmap(studentId: 's1', days: const {});

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder:
              (context, state) =>
                  const Scaffold(body: PracticeStartSection(studentId: 's1')),
        ),
        GoRoute(
          path: AppRoutes.studentGrowthDetail,
          builder: (context, state) {
            final studentId = state.uri.queryParameters['studentId'] ?? '';
            return Scaffold(
              body: Text(
                'GROWTH_DETAIL_TARGET:$studentId',
                key: const ValueKey('growth_detail_target'),
              ),
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studentProvider('s1').overrideWith((ref) async => mockStudent),
          growthHeatmapProvider('s1').overrideWith((ref) async => mockHeatmap),
          studentRepertoiresProvider(
            's1',
          ).overrideWith((ref) async => const []),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // PracticeStartCard 의 더보기 (점점점) 버튼 존재 확인
    final moreButton = find.byKey(const ValueKey('practice_start_card_more'));
    expect(
      moreButton,
      findsOneWidget,
      reason: 'PracticeStartCard 의 onMoreTap wiring 으로 점점점 노출',
    );

    // tap → 라우팅
    await tester.tap(moreButton);
    await tester.pumpAndSettle();

    // /student/growth-detail 으로 이동했는지 확인 (studentId param 포함)
    expect(
      find.byKey(const ValueKey('growth_detail_target')),
      findsOneWidget,
      reason: '점점점 탭 → /student/growth-detail?studentId=s1 라우팅 (spy mock)',
    );
    expect(find.text('GROWTH_DETAIL_TARGET:s1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
