import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/schedule/data/repositories/mock_group_class_repository.dart';
import 'package:lessonaza/features/schedule/domain/entities/group_class.dart';
import 'package:lessonaza/features/schedule/presentation/providers/group_class_providers.dart';
import 'package:lessonaza/features/student_home/presentation/widgets/student_group_class_card.dart';

/// J12 P1-2 — 아젠다 반 행의 렌더 계약과 상세 연결 (widget smoke, HARD-GATE).
void main() {
  const studentId = 'student_1';

  // mock 시드와 같은 id — 시드 회차 'schedule_group_class_1' 이 이 반에 달린다.
  final ensemble = GroupClass(
    id: 'group_class_1',
    teacherId: 'teacher_1',
    name: '목요일 앙상블반',
    type: GroupClassType.regular,
    maxCapacity: 4,
    durationMinutes: 60,
    repeatDaysOfWeek: const [4],
    repeatTimeOfDay: '17:00',
    createdAt: DateTime(2026),
  );

  ({GoRouter router, List<String> landed}) buildRouter(GroupClass groupClass) {
    final landed = <String>[];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder:
              (context, state) => Scaffold(
                body: StudentGroupClassCard(
                  groupClass: groupClass,
                  studentId: studentId,
                  date: DateTime.now(),
                ),
              ),
        ),
        GoRoute(
          path: AppRoutes.groupClassDetail,
          builder: (context, state) {
            landed.add('detail:${state.pathParameters['id']}');
            return const Scaffold(body: Text('detail'));
          },
        ),
      ],
    );
    return (router: router, landed: landed);
  }

  Future<({List<String> landed})> pumpCard(WidgetTester tester) async {
    final r = buildRouter(ensemble);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupClassRepositoryProvider.overrideWithValue(
            MockGroupClassRepository(),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: r.router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (landed: r.landed);
  }

  testWidgets('반 이름 · 유형 배지 · 시간 요약을 렌더한다 (크래시 없음)', (tester) async {
    await pumpCard(tester);

    expect(find.text('목요일 앙상블반'), findsOneWidget);
    expect(find.text(AppStrings.groupClassRegular), findsOneWidget);
    expect(
      find.text(AppStrings.groupClassAgendaSummary('17:00', 60)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('행을 누르면 회차를 해석해 그룹 클래스 상세로 이동한다', (tester) async {
    final r = await pumpCard(tester);

    await tester.tap(find.text('목요일 앙상블반'));
    await tester.pumpAndSettle();

    expect(r.landed, ['detail:schedule_group_class_1']);
    expect(tester.takeException(), isNull);
  });
}
