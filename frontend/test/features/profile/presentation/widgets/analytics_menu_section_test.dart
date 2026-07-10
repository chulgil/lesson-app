// #1164 — 프로필 탭 통계·분석 섹션 진입점 배선 검증.
//
// TeacherAttendanceScreen 은 라우트만 등록되고 네비게이션이 0건이었다.
// AnalyticsMenuSection 이 진입점을 복원하는지(렌더 + 탭 → teacherAttendance push)
// 를 검증한다. profile_tab.dart 전체 마운트는 provider 의존성이 과도하므로
// 섹션 위젯을 직접 검증하고, 라우트 상수 배선은 소스 계약으로 고정한다.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/features/profile/presentation/widgets/analytics_menu_section.dart';

void main() {
  testWidgets('섹션 헤더 + 출석 현황 메뉴 행이 렌더된다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AnalyticsMenuSection(onAttendanceTap: () {})),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.profileAnalyticsSectionTitle), findsOneWidget);
    expect(find.text(AppStrings.attendanceTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('출석 현황 행 탭 → onAttendanceTap 호출됨', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnalyticsMenuSection(onAttendanceTap: () => tapped = true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.attendanceTitle));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('행 탭 시 teacherAttendance 라우트로 이동한다', (tester) async {
    final visited = <String>[];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder:
              (ctx, state) => Scaffold(
                body: AnalyticsMenuSection(
                  onAttendanceTap: () => ctx.push(AppRoutes.teacherAttendance),
                ),
              ),
        ),
        GoRoute(
          path: AppRoutes.teacherAttendance,
          builder: (ctx, state) {
            visited.add(AppRoutes.teacherAttendance);
            return const Scaffold(body: Text('attendance'));
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.attendanceTitle));
    await tester.pumpAndSettle();

    expect(visited, contains(AppRoutes.teacherAttendance));
    expect(tester.takeException(), isNull);
  });

  test('profile_tab 이 통계·분석 섹션을 teacherAttendance 로 배선한다', () {
    final source =
        File(
          'lib/features/profile/presentation/screens/profile_tab.dart',
        ).readAsStringSync();

    expect(source, contains('AnalyticsMenuSection('));
    expect(source, contains('context.push(AppRoutes.teacherAttendance)'));
  });
}
