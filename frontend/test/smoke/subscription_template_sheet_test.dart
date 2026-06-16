// 수강권 템플릿 관리 + → 템플릿 추가 시트 렌더 회귀 (실 라우터).
//
// 사용자 보고: 프로필 → 수강권 → 수강권 관리(템플릿) → 상단 + → 추가 시트가
// `notebook_bottom_sheet.dart:49` Column 에서 세로 22px overflow (RenderFlex,
// size 459x773). 폼이 가용 높이를 초과하는데 스크롤되지 않아 발생.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lessonaza/core/router/app_routes.dart';

import '../e2e/helpers/e2e_harness.dart';

void main() {
  setUpAll(initE2eEnvironment);
  tearDownAll(disposeE2eEnvironment);

  testWidgets('교사 수강권 템플릿 관리 + → 템플릿 추가 시트 렌더 오버플로우 없음', (tester) async {
    await bootAsRole(tester, DevAccount.teacher);

    // 사용자 케이스 재현: 에러 RenderFlex size 459x773 → 가용 높이 773 에서
    // 폼이 안 들어감.
    tester.view.physicalSize = const Size(459, 773);
    tester.view.devicePixelRatio = 1.0;

    GoRouter.of(
      tester.element(find.byType(Navigator).first),
    ).go(AppRoutes.subscriptionTemplates);
    await settle(tester);
    expect(tester.takeException(), isNull, reason: '수강권 템플릿 관리 화면 진입 렌더');

    // 상단 + 액션(DetailAppBarAction.add, tooltip 'add') → 템플릿 추가 시트.
    final addBtn = find.byTooltip('add');
    expect(addBtn, findsOneWidget, reason: '상단 + 액션 버튼');
    await tester.tap(addBtn);
    await settle(tester);

    expect(
      tester.takeException(),
      isNull,
      reason: '템플릿 추가 시트 렌더 오버플로우 없음 (notebook_bottom_sheet Column 22px)',
    );
  });
}
