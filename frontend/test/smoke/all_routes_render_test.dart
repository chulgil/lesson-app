// #751 — 전 화면 렌더 스모크 하네스 (실 GoRouter + 2 뷰포트).
//
// 목적: 화면-흐름 런타임 크래시(RenderBox/RenderMetaData NEEDS-LAYOUT,
// RenderFlex overflow)를 자동 검출. flutter analyze(정적) + 고립 위젯
// pump(false-green)가 놓친 #746/#747 류 재발 방지.
//
// 설계: #731 Gate 3 e2e 하네스(`bootAsRole`)를 재사용해 실 라우터를 띄우고,
// 실제 GoRouter 네비게이션으로 각 라우트를 mobile(375)·desktop(1440) 두
// 뷰포트에서 렌더 → 매 단계 `expect(tester.takeException(), isNull)`.
// 고립 pump 금지(false-green 원인) — 실 라우터 흐름으로만 재현.
//
// 실행: flutter test test/smoke/all_routes_render_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/features/students/presentation/screens/add_student_screen.dart';

import '../e2e/helpers/e2e_harness.dart';

/// 두 표준 뷰포트 — mobile 375, desktop 1440 (이번 크래시는 desktop 특이성).
const _mobile = Size(375, 812);
const _desktop = Size(1440, 900);

void main() {
  setUpAll(initE2eEnvironment);
  tearDownAll(disposeE2eEnvironment);

  /// 로그인된 셸에서 [route]로 실 라우터 이동 후 [size] 뷰포트로 렌더 검증.
  Future<void> goAndAssert(
    WidgetTester tester,
    String route,
    Size size, {
    Finder? expectScreen,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    final ctx = tester.element(find.byType(Scaffold).first);
    GoRouter.of(ctx).go(route);
    await settle(tester);
    if (expectScreen != null) {
      expect(
        expectScreen,
        findsOneWidget,
        reason: '$route 도달(@${size.width.toInt()})',
      );
    }
    expect(
      tester.takeException(),
      isNull,
      reason: '$route 렌더 크래시 없음 (@${size.width.toInt()})',
    );
  }

  testWidgets('#746 학생 직접 등록 폼 — desktop·mobile 렌더 크래시 없음', (tester) async {
    await bootAsRole(tester, DevAccount.teacher);

    // desktop 먼저 — #746 은 macOS desktop(mouse_tracker) 특이 크래시였음.
    await goAndAssert(
      tester,
      AppRoutes.addStudent,
      _desktop,
      expectScreen: find.byType(AddStudentScreen),
    );
    await goAndAssert(
      tester,
      AppRoutes.addStudent,
      _mobile,
      expectScreen: find.byType(AddStudentScreen),
    );
  });

  // #750 — 주소 행 mobile(375) 가로 오버플로우. 독립 버그가 아니라 #746
  // RenderMetaData 크래시의 다운스트림 증상이었다: 크래시 cascade 가 폼에 비정상
  // 93px 제약을 전파 → rigid 우편번호(SizedBox 130)가 넘쳐 58px 오버플로우.
  // #746 수정(SizedBox→Expanded + 크래시 제거)이 함께 해소. takeException 만으로는
  // Expanded 가 압축을 흡수해 통과할 수 있으므로, 본문이 93px 로 붕괴하지 않고
  // full-width 로 렌더되는지까지 검증해 근본(비정상 제약) 회귀를 막는다.
  testWidgets('#750 학생 직접 등록 — mobile(375) 주소 행 오버플로우 없음 + 폼 full-width', (
    tester,
  ) async {
    await bootAsRole(tester, DevAccount.teacher);

    tester.view.physicalSize = _mobile;
    tester.view.devicePixelRatio = 1.0;
    GoRouter.of(
      tester.element(find.byType(Scaffold).first),
    ).go(AppRoutes.addStudent);
    await settle(tester);

    expect(find.byType(AddStudentScreen), findsOneWidget);
    // 주소 행 등 전 화면에 RenderFlex overflow / RenderMetaData 없음.
    expect(
      tester.takeException(),
      isNull,
      reason: '학생 작성 화면 mobile(375) 렌더 크래시/오버플로우 없음 (#750)',
    );
    // 본문이 93px 로 압축되지 않고 full-width(≈375) 로 렌더되는지 — 93px 면 280px
    // 요일 행이 먼저 오버플로우하고 본문 폭이 ~93px 로 붕괴. #750 근본 회귀 가드.
    final body = find.byType(SingleChildScrollView);
    expect(body, findsOneWidget);
    final bodyWidth = tester.getSize(body).width;
    expect(
      bodyWidth,
      greaterThan(300),
      reason:
          '폼 본문이 full-width 여야 함 (93px 압축 회귀 가드). 실제 ${bodyWidth.toInt()}px',
    );
  });

  testWidgets('교사 무파라미터 top-level 라우트 — 2 뷰포트 렌더 크래시 없음', (tester) async {
    await bootAsRole(tester, DevAccount.teacher);
    const routes = [
      AppRoutes.students,
      AppRoutes.addStudentMethod,
      AppRoutes.lessons,
      AppRoutes.addLesson,
      AppRoutes.home,
    ];
    for (final route in routes) {
      await goAndAssert(tester, route, _desktop);
      await goAndAssert(tester, route, _mobile);
    }
  });
}
