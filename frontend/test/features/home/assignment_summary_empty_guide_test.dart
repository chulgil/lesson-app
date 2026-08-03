import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/home/presentation/providers/assignment_summary_provider.dart';
import 'package:lessonaza/features/home/presentation/widgets/assignment_summary_section.dart';

/// #625 (0702 감사) — 과제 0건일 때 섹션을 숨기지 않고(기능 인지 불가 dead-end)
/// 헤더 + '첫 과제 내기' CTA 가이드를 노출한다.
Future<GoRouter> _pump(WidgetTester tester, WeeklyAssignmentSummary summary) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder:
            (_, __) => const Scaffold(
              body: SingleChildScrollView(child: AssignmentSummarySection()),
            ),
      ),
      GoRoute(
        path: AppRoutes.assignmentDashboard,
        builder: (_, __) => const Scaffold(body: Text('assignment-dashboard')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        weeklyAssignmentSummaryProvider.overrideWith((ref) async => summary),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('과제 0건 → 숨김 대신 빈 상태 가이드 + CTA 노출', (tester) async {
    await _pump(
      tester,
      const WeeklyAssignmentSummary(
        totalItems: 0,
        completedItems: 0,
        incompleteStudents: [],
      ),
    );

    expect(find.text(AppStrings.weeklyAssignmentTitle), findsOneWidget);
    expect(find.text(AppStrings.weeklyAssignmentEmpty), findsOneWidget);
    expect(find.text(AppStrings.weeklyAssignmentFirstCta), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('첫 과제 내기 탭 → 과제 대시보드로 이동', (tester) async {
    await _pump(
      tester,
      const WeeklyAssignmentSummary(
        totalItems: 0,
        completedItems: 0,
        incompleteStudents: [],
      ),
    );

    await tester.tap(find.text(AppStrings.weeklyAssignmentFirstCta));
    await tester.pumpAndSettle();

    expect(find.text('assignment-dashboard'), findsOneWidget);
  });

  testWidgets('과제 있으면 기존 진행률 뷰 유지 (회귀 0)', (tester) async {
    await _pump(
      tester,
      const WeeklyAssignmentSummary(
        totalItems: 4,
        completedItems: 2,
        incompleteStudents: [],
      ),
    );

    expect(find.text(AppStrings.completionRateLabel), findsOneWidget);
    expect(find.text(AppStrings.weeklyAssignmentFirstCta), findsNothing);
  });
}
