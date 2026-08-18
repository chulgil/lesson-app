import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/core/widgets/swipe_action_tile.dart';
import 'package:lessonaza/features/schedule/data/repositories/mock_group_class_repository.dart';
import 'package:lessonaza/features/schedule/domain/entities/group_class.dart';
import 'package:lessonaza/features/schedule/domain/entities/group_class_draft.dart';
import 'package:lessonaza/features/schedule/presentation/providers/group_class_providers.dart';
import 'package:lessonaza/features/schedule/presentation/screens/group_classes_screen.dart';

/// 반복 요일만 있고 회차는 열리지 않은 반 — mock 은 생성 시 회차를 만들지 않는다
/// (실제로는 백엔드가 반복 규칙을 확장한다).
GroupClassDraft _draftWithoutSession() => const GroupClassDraft(
  name: '회차 없는 반',
  type: GroupClassType.regular,
  maxCapacity: 4,
  durationMinutes: 60,
  noShowPolicy: NoShowPolicy.deductCredit,
  bookingDeadlineMinutes: 60,
  cancelDeadlineMinutes: 1440,
  repeatDaysOfWeek: [4],
  repeatTimeOfDay: '17:00',
);

/// J12 P1-2 — 고아 0: 내 클래스 목록에서 출석·폼으로 실제 push 되는지.
///
/// 계약:
///   ① 행 탭 → 회차를 해석해 출석 화면으로 push (교사 화면 — 학생 상세 아님)
///   ② 편집 스와이프 액션 → 클래스 폼 라우트로 push
///   ③ 열린 회차가 없으면 안내만 하고 이동하지 않는다 (dead-end 대신 스낵바)
void main() {
  const teacherId = 'teacher_1';

  /// 목록 + 두 목적지 라우트. 착지한 경로를 기록한다 (spy).
  ({GoRouter router, List<String> landed}) buildRouter() {
    final landed = <String>[];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder:
              (context, state) => const GroupClassesRoute(teacherId: teacherId),
        ),
        GoRoute(
          path: AppRoutes.groupClassAttendance,
          builder: (context, state) {
            landed.add('attendance:${state.pathParameters['id']}');
            return const Scaffold(body: Text('attendance'));
          },
        ),
        GoRoute(
          path: AppRoutes.groupClassForm,
          builder: (context, state) {
            landed.add('form');
            return const Scaffold(body: Text('form'));
          },
        ),
      ],
    );
    return (router: router, landed: landed);
  }

  Future<({List<String> landed})> pumpList(
    WidgetTester tester,
    MockGroupClassRepository repository,
  ) async {
    final r = buildRouter();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [groupClassRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: r.router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (landed: r.landed);
  }

  testWidgets('① 행을 누르면 회차를 해석해 출석 화면으로 이동한다', (tester) async {
    final repository = MockGroupClassRepository();
    final r = await pumpList(tester, repository);

    await tester.tap(find.text('목요일 앙상블반'));
    await tester.pumpAndSettle();

    expect(r.landed, ['attendance:schedule_group_class_1']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('② 편집 스와이프 액션은 클래스 폼 라우트로 이동한다', (tester) async {
    final r = await pumpList(tester, MockGroupClassRepository());

    final edit =
        tester
            .widget<SwipeActionTile>(find.byType(SwipeActionTile).first)
            .actions
            .first;
    expect(edit.label, AppStrings.swipeActionEdit);
    edit.onPressed();
    await tester.pumpAndSettle();

    expect(r.landed, ['form']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('③ 열린 회차가 없으면 이동 대신 안내만 한다', (tester) async {
    // seed:false 로 시작해 회차 없는 클래스를 하나만 넣는다. runAsync 밖에서
    // repository future 를 await 하면 fake async zone 에서 교착한다.
    final repository = MockGroupClassRepository(seed: false);
    await tester.runAsync(() => repository.createClass(_draftWithoutSession()));
    final r = await pumpList(tester, repository);

    await tester.tap(find.text('회차 없는 반'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(r.landed, isEmpty);
    expect(find.text(AppStrings.groupClassesNoSessionYet), findsOneWidget);
    expect(tester.takeException(), isNull);

    // 스낵바 자동 닫힘 타이머를 흘려보내 teardown 의 pending timer 실패를 막는다.
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
