// 2026-06-12 — 라우트 teacherId 하드코딩 폴백 회귀 테스트.
//
// 베타(remote) 버그: 쿼리 없이 push 시 'teacher_1' 하드코딩 폴백 →
// 화면 조회는 teacher_1 / 저장은 토큰 본인 계정 — 쓰기-읽기 대상 불일치로
// "시간대 추가해도 무반응". 폴백은 반드시 현재 로그인 사용자여야 한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/core/router/routes/schedule_routes.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/auth/auth_facade.dart'
    show currentUserIdProvider;
import 'package:lessonaza/features/schedule/presentation/providers/teacher_availability_providers.dart';
import 'package:lessonaza/features/schedule/presentation/screens/teacher_availability_split_page.dart';

void main() {
  const realUserId = 'uuid-real-teacher-42';

  Future<GoRouter> pumpRouter(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SizedBox()),
        ...scheduleRoutes,
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue(realUserId),
          // leaf 데이터 로드는 우회 — 라우팅 파라미터만 검증.
          teacherAvailabilityProvider(
            realUserId,
          ).overrideWith((ref) async => null),
          teacherAvailabilityProvider(
            'explicit-teacher',
          ).overrideWith((ref) async => null),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('teacherAvailability — 쿼리 없으면 현재 로그인 사용자로 폴백 (베타 무반응 회귀)', (
    tester,
  ) async {
    final router = await pumpRouter(tester);

    router.push(AppRoutes.teacherAvailability);
    await tester.pumpAndSettle();

    final page = tester.widget<TeacherAvailabilitySplitPage>(
      find.byType(TeacherAvailabilitySplitPage),
    );
    expect(
      page.teacherId,
      realUserId,
      reason: "하드코딩 'teacher_1' 폴백은 remote 에서 조회/저장 대상 불일치를 만든다",
    );
  });

  testWidgets('teacherAvailability — 쿼리가 있으면 그 값을 사용', (tester) async {
    final router = await pumpRouter(tester);

    router.push('${AppRoutes.teacherAvailability}?teacherId=explicit-teacher');
    await tester.pumpAndSettle();

    final page = tester.widget<TeacherAvailabilitySplitPage>(
      find.byType(TeacherAvailabilitySplitPage),
    );
    expect(page.teacherId, 'explicit-teacher');
  });
}
