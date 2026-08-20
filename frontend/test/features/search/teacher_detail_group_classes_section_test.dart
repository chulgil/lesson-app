import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_profile.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_search.dart';
import 'package:lessonaza/features/profile/profile_facade.dart';
import 'package:lessonaza/features/schedule/data/repositories/mock_group_class_repository.dart';
import 'package:lessonaza/features/schedule/domain/entities/group_class.dart';
import 'package:lessonaza/features/schedule/presentation/providers/group_class_providers.dart';
import 'package:lessonaza/features/schedule/schedule_ui_facade.dart';
import 'package:lessonaza/features/search/presentation/screens/teacher_detail_screen.dart';
import 'package:lessonaza/features/search/search_facade.dart';
import 'package:lessonaza/features/students/students_facade.dart';
import 'package:lessonaza/features/subscription/subscription_facade.dart';

/// J12 P1-2 — 교사 상세의 "개설 클래스" 섹션 (D3: 학생 탐색 표면).
///
/// 계약:
///   ① 개설 클래스가 있으면 섹션 제목 + 반/특강 배지 + 클래스명이 렌더된다
///   ② 개설 클래스가 없으면 섹션 자체가 숨는다 (공개 프로필 빈 상태 노이즈 금지)
///
/// J15b — 반(regular) 행에만 신청 CTA 가 붙는다:
///   ③ 반 행은 신청 CTA 를 노출하고, 특강(dropIn) 행은 노출하지 않는다
///   ④ 신청 탭 은 그 반을 지정해 기존 통합 신청 흐름으로 넘긴다
void main() {
  const teacherId = 'teacher_1';
  const studentId = 'student_1';

  final profile = TeacherPublicProfile(
    id: teacherId,
    name: '김선생',
    instruments: const ['바이올린'],
    introduction: '소개',
    completionLevel: ProfileCompletionLevel.standard,
  );

  final student = Student(
    id: studentId,
    name: '박학생',
    instrument: '바이올린',
    createdAt: DateTime(2026, 1, 1),
  );

  List<Override> detailOverrides() => [
    teacherPublicProfileProvider(teacherId).overrideWith((ref) async => profile),
    myDisconnectedConnectionsProvider.overrideWith((ref) async => []),
    currentStudentProvider.overrideWith((ref) async => student),
    activeSubscriptionBetweenProvider(
      studentId: studentId,
      teacherId: teacherId,
    ).overrideWith((ref) async => null),
  ];

  /// Pump the detail screen with either a seeded repository or an explicit
  /// class list — the list form pins one class shape per assertion.
  Future<void> pumpDetail(
    WidgetTester tester, {
    MockGroupClassRepository? repository,
    List<GroupClass>? classes,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...detailOverrides(),
          groupClassRepositoryProvider.overrideWithValue(
            repository ?? MockGroupClassRepository(seed: false),
          ),
          if (classes != null)
            teacherGroupClassesProvider(
              teacherId,
            ).overrideWith((ref) async => classes),
        ],
        child: const MaterialApp(
          home: TeacherDetailScreen(teacherId: teacherId),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('① 개설 클래스가 있으면 섹션에 반·특강이 나열된다', (tester) async {
    // 시드 = 정규 반 1 + 특강 1, 둘 다 teacher_1 소유.
    await pumpDetail(tester, repository: MockGroupClassRepository());

    expect(
      find.text(AppStrings.groupClassesTeacherDetailTitle),
      findsOneWidget,
    );
    expect(find.text('목요일 앙상블반'), findsOneWidget);
    expect(find.text('원데이 보잉 특강'), findsOneWidget);
    // 반 / 특강 을 배지로 구분한다 (dropIn 라벨은 '특강').
    expect(find.text(AppStrings.groupClassRegular), findsOneWidget);
    expect(find.text(AppStrings.groupClassDropin), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('② 개설 클래스가 없으면 섹션이 숨는다', (tester) async {
    await pumpDetail(tester, repository: MockGroupClassRepository(seed: false));

    expect(find.text(AppStrings.groupClassesTeacherDetailTitle), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('③ 반·특강이 함께 있으면 신청 CTA 는 반 행에만 하나 붙는다', (tester) async {
    await pumpDetail(tester, classes: [_regularClass, _dropInClass]);

    expect(find.text(AppStrings.groupClassRegular), findsOneWidget);
    expect(find.text(AppStrings.groupClassDropin), findsOneWidget);
    expect(find.text(AppStrings.groupClassEnrollAction), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('③-b 특강만 있으면 신청 CTA 가 없다', (tester) async {
    // 게이트가 '개설 클래스 유무' 가 아니라 '타입' 임을 고정한다.
    await pumpDetail(tester, classes: [_dropInClass]);

    expect(find.text(AppStrings.groupClassesTeacherDetailTitle), findsOneWidget);
    expect(find.text(AppStrings.groupClassEnrollAction), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('④ 신청 탭 은 그 반을 지정해 통합 신청 흐름으로 넘긴다', (tester) async {
    UnifiedLessonRequestParams? handedOver;

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const TeacherDetailScreen(teacherId: teacherId),
        ),
        GoRoute(
          path: AppRoutes.lessonBooking,
          builder: (_, state) {
            handedOver = state.extra as UnifiedLessonRequestParams?;
            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...detailOverrides(),
          teacherGroupClassesProvider(
            teacherId,
          ).overrideWith((ref) async => [_regularClass]),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.groupClassEnrollAction));
    await tester.pumpAndSettle();

    expect(handedOver, isNotNull);
    expect(handedOver!.groupClassId, _regularClass.id);
    expect(handedOver!.teacherId, teacherId);
    expect(tester.takeException(), isNull);
  });
}

final _regularClass = GroupClass(
  id: 'group_class_regular',
  teacherId: 'teacher_1',
  name: '목요일 앙상블반',
  type: GroupClassType.regular,
  maxCapacity: 4,
  durationMinutes: 60,
  createdAt: DateTime(2026, 8, 1),
);

final _dropInClass = GroupClass(
  id: 'group_class_dropin',
  teacherId: 'teacher_1',
  name: '원데이 보잉 특강',
  type: GroupClassType.dropIn,
  maxCapacity: 6,
  durationMinutes: 90,
  createdAt: DateTime(2026, 8, 2),
);
