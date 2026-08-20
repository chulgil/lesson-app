import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:lessonaza/core/widgets/swipe_action_tile.dart';
import 'package:lessonaza/features/schedule/data/repositories/mock_group_class_repository.dart';
import 'package:lessonaza/features/schedule/presentation/providers/group_class_providers.dart';
import 'package:lessonaza/features/schedule/presentation/screens/group_class_members_screen.dart';
import 'package:lessonaza/features/schedule/presentation/screens/group_classes_screen.dart';
import 'package:lessonaza/features/students/students_facade.dart';

/// AC-11 — 교사 코호트 멤버 관리 (spec §2 P2-4).
///
/// 계약:
///   ① 로스터가 정원 요약과 함께 렌더된다 (서버 이름 / 로컬 폴백 두 경로)
///   ② 배정: 담당 학생을 고르면 로스터에 나타나고 정원 카운트가 오른다
///   ③ 정원이 차면 배정 액션 자체가 사라진다 (정원 초과 차단)
///   ④ 내보내기: destructive 스와이프 → 확인 다이얼로그 → 로스터에서 빠진다
///   ⑤ 진입점: 반 행의 좌→우 편의 스와이프가 로스터 라우트로 이동. 특강은 없다
Student _student(String id, String name) =>
    Student(id: id, name: name, instrument: '바이올린', createdAt: DateTime(2026));

void main() {
  // mock seed: group_class_1 = 목요일 앙상블반 (정규, 정원 4, student_1 배정),
  // group_class_2 = 원데이 보잉 특강 (드롭인).
  const classId = 'group_class_1';
  const teacherId = 'teacher_1';

  final students = <Student>[
    _student('student_1', '김민준'),
    _student('student_2', '이서연'),
    _student('student_3', '박지호'),
    _student('student_4', '최유진'),
  ];

  Future<void> pumpRoster(
    WidgetTester tester,
    MockGroupClassRepository repository,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupClassRepositoryProvider.overrideWithValue(repository),
          studentsProvider.overrideWith((ref) async => students),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const GroupClassMembersScreen(classId: classId),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('① 로스터는 서버가 준 학생 이름과 정원 요약을 렌더한다', (tester) async {
    // 서버는 student_name 을 조인해 내려준다 — 그 경로를 그대로 태운다.
    await pumpRoster(
      tester,
      MockGroupClassRepository(studentNames: const {'student_1': '김민준'}),
    );

    expect(find.text('김민준'), findsOneWidget);
    expect(
      find.text(AppStrings.groupClassMembersCapacity(1, 4)),
      findsOneWidget,
    );
    expect(find.text(AppStrings.groupClassMembersFullNotice), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('① 서버 이름이 없으면 담당 학생 목록에서 이름을 채운다', (tester) async {
    await pumpRoster(tester, MockGroupClassRepository());

    expect(find.text('김민준'), findsOneWidget);
    expect(find.text(AppStrings.groupClassMembersUnknownStudent), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('② 학생을 배정하면 로스터에 나타나고 정원 카운트가 오른다', (tester) async {
    await pumpRoster(tester, MockGroupClassRepository());

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // 이미 배정된 student_1 은 후보에서 빠진다.
    expect(find.text('김민준'), findsOneWidget); // 로스터 행만
    expect(find.text('이서연'), findsOneWidget); // 시트 후보

    await tester.tap(find.text('이서연'));
    await tester.pumpAndSettle();

    expect(find.text('이서연'), findsOneWidget);
    expect(
      find.text(AppStrings.groupClassMembersCapacity(2, 4)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('③ 정원이 차면 배정 액션이 사라진다', (tester) async {
    final repository = MockGroupClassRepository();
    // 정원 4 — 시드 1명 + 3명이면 만석.
    for (final id in ['student_2', 'student_3', 'student_4']) {
      repository.enrol(studentId: id, classId: classId);
    }

    await pumpRoster(tester, repository);

    expect(
      find.text(AppStrings.groupClassMembersCapacity(4, 4)),
      findsOneWidget,
    );
    expect(find.text(AppStrings.groupClassMembersFullNotice), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('④ 내보내기는 확인을 받은 뒤 로스터에서 제거한다', (tester) async {
    await pumpRoster(tester, MockGroupClassRepository());

    final remove =
        tester
            .widget<SwipeActionTile>(find.byType(SwipeActionTile).first)
            .actions
            .single;
    expect(remove.label, AppStrings.groupClassMembersRemoveAction);
    expect(remove.tone, SwipeActionTone.destructive);

    remove.onPressed();
    await tester.pumpAndSettle();

    // 확인 다이얼로그 없이 즉시 삭제되지 않는다.
    expect(find.byType(NotebookAlertDialog), findsOneWidget);
    expect(find.text('김민준'), findsWidgets);

    await tester.tap(
      find.descendant(
        of: find.byType(NotebookAlertDialog),
        matching: find.text(AppStrings.groupClassMembersRemoveAction),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('김민준'), findsNothing);
    expect(find.text(AppStrings.groupClassMembersEmptyTitle), findsOneWidget);
    expect(
      find.text(AppStrings.groupClassMembersCapacity(0, 4)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  group('⑤ 진입점 — 내 클래스 목록의 좌→우 편의 스와이프', () {
    /// 목록 + 실제 로스터 라우트. 착지 경로를 기록한다 (spy).
    ({GoRouter router, List<String> landed}) buildRouter() {
      final landed = <String>[];
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder:
                (context, state) =>
                    const GroupClassesRoute(teacherId: teacherId),
          ),
          GoRoute(
            path: AppRoutes.groupClassMembers,
            builder: (context, state) {
              landed.add('members:${state.pathParameters['id']}');
              return GroupClassMembersScreen(
                classId: state.pathParameters['id']!,
              );
            },
          ),
        ],
      );
      return (router: router, landed: landed);
    }

    Future<({List<String> landed})> pumpList(WidgetTester tester) async {
      final r = buildRouter();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupClassRepositoryProvider.overrideWithValue(
              MockGroupClassRepository(),
            ),
            studentsProvider.overrideWith((ref) async => students),
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

    /// 목록에서 이름으로 행의 스와이프 타일을 찾는다.
    SwipeActionTile tileFor(WidgetTester tester, String className) =>
        tester.widget<SwipeActionTile>(
          find.ancestor(
            of: find.text(className),
            matching: find.byType(SwipeActionTile),
          ),
        );

    testWidgets('반 행의 편의 액션은 로스터 화면으로 이동한다', (tester) async {
      final r = await pumpList(tester);

      final members = tileFor(tester, '목요일 앙상블반').startActions.single;
      expect(members.label, AppStrings.groupClassMembersEntryAction);
      expect(members.tone, SwipeActionTone.convenience);

      members.onPressed();
      await tester.pumpAndSettle();

      expect(r.landed, ['members:group_class_1']);
      expect(find.text(AppStrings.groupClassMembersTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('특강 행에는 로스터 액션이 없다', (tester) async {
      await pumpList(tester);

      // 드롭인은 고정 로스터가 없다 — 회차별 예약 흐름을 쓴다.
      expect(tileFor(tester, '원데이 보잉 특강').startActions, isEmpty);
      expect(tester.takeException(), isNull);
    });
  });
}
