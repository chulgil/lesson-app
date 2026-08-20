import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_profile.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_search.dart';
import 'package:lessonaza/features/profile/profile_facade.dart';
import 'package:lessonaza/features/search/presentation/screens/teacher_detail_screen.dart';
import 'package:lessonaza/features/search/search_facade.dart';
import 'package:lessonaza/features/students/students_facade.dart';
import 'package:lessonaza/features/subscription/subscription_facade.dart';

/// #1219 — 선생님 상세의 CTA 는 수강권 보유 여부로 갈린다.
///
/// 스펙 `student_direct_booking_spec.md` §8: "수강권 보유 시 직접 예약 우선".
/// 보유 → 선착순 직접 예약(`/schedule/booking/direct`), 미보유 → 기존 레슨
/// 신청(`/schedule/book-lesson`).
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

  Subscription activeSubscription() => Subscription(
    id: 'sub_1',
    studentId: studentId,
    membershipId: 'mem_1',
    type: SubscriptionType.package,
    totalLessons: 8,
    usedLessons: 3,
    amount: 240000,
    status: SubscriptionStatus.active,
    createdAt: DateTime(2026, 7, 1),
  );

  /// 화면 + 두 목적지 라우트. 착지한 경로를 기록한다 (spy).
  ({GoRouter router, List<String> landed}) buildRouter() {
    final landed = <String>[];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder:
              (context, state) =>
                  const TeacherDetailScreen(teacherId: teacherId),
        ),
        GoRoute(
          path: AppRoutes.lessonDirectBooking,
          builder: (context, state) {
            landed.add('direct');
            return const Scaffold(body: Text('direct booking'));
          },
        ),
        GoRoute(
          path: AppRoutes.lessonBooking,
          builder: (context, state) {
            landed.add('request');
            return const Scaffold(body: Text('lesson request'));
          },
        ),
      ],
    );
    return (router: router, landed: landed);
  }

  List<Override> overrides({required Subscription? subscription}) => [
    teacherPublicProfileProvider(
      teacherId,
    ).overrideWith((ref) async => profile),
    myDisconnectedConnectionsProvider.overrideWith((ref) async => []),
    currentStudentProvider.overrideWith((ref) async => student),
    activeSubscriptionBetweenProvider(
      studentId: studentId,
      teacherId: teacherId,
    ).overrideWith((ref) async => subscription),
  ];

  testWidgets('활성 수강권 보유 → 직접 예약(선착순) 화면으로 진입', (tester) async {
    final r = buildRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(subscription: activeSubscription()),
        child: MaterialApp.router(routerConfig: r.router),
      ),
    );
    await tester.pumpAndSettle();

    final cta = find.text(AppStrings.bookAction);
    expect(cta, findsOneWidget, reason: '수강권 보유 학생에게는 직접 예약 CTA 가 보여야 한다');
    expect(find.text(AppStrings.searchLessonApply), findsNothing);

    // 개설 클래스 섹션이 자라면 CTA 가 접힘 아래로 내려간다 — 실제 화면은
    // 스크롤되므로 탭 전에 노출시킨다.
    await tester.ensureVisible(cta);
    await tester.pumpAndSettle();
    await tester.tap(cta);
    await tester.pumpAndSettle();

    expect(r.landed, ['direct']);
  });

  testWidgets('활성 수강권 없음 → 기존 레슨 신청 화면으로 진입 (회귀 방지)', (tester) async {
    final r = buildRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(subscription: null),
        child: MaterialApp.router(routerConfig: r.router),
      ),
    );
    await tester.pumpAndSettle();

    final cta = find.text(AppStrings.searchLessonApply);
    expect(cta, findsOneWidget);
    expect(find.text(AppStrings.bookAction), findsNothing);

    // 개설 클래스 섹션이 자라면 CTA 가 접힘 아래로 내려간다 — 실제 화면은
    // 스크롤되므로 탭 전에 노출시킨다.
    await tester.ensureVisible(cta);
    await tester.pumpAndSettle();
    await tester.tap(cta);
    await tester.pumpAndSettle();

    expect(r.landed, ['request']);
  });
}
