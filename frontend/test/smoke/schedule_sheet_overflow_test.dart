// 바텀시트 헬퍼 오용 sweep (#754 동형) — schedule 시트 세로 오버플로우 회귀.
//
// self-surfaced 시트(자체 Container+SingleChildScrollView)를 showNotebookBottomSheet
// 에 넘기면 NotebookBottomSheet 의 Column(min) 이 unbounded 높이를 줘 스크롤이
// 무력화 → 폼이 가용 높이를 넘으면 세로 overflow. 실 라우터로 재현.
//
// 주의: "#754 동형"이라도 콘텐츠가 짧으면 가용 높이에 들어가 overflow 가 발생하지
// 않는다(정적 shape ≠ 실제 버그). 현실적 높이(640)에서 실제 manifest 여부를 확인.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/features/schedule/presentation/widgets/schedule_edit_bottom_sheet.dart';

import '../e2e/helpers/e2e_harness.dart';

void main() {
  setUpAll(initE2eEnvironment);
  tearDownAll(disposeE2eEnvironment);

  testWidgets('교사 주간 일정 추가/편집 시트 — 좁은 높이(640) 렌더 오버플로우 없음', (tester) async {
    await bootAsRole(tester, DevAccount.teacher);
    tester.view.physicalSize = const Size(390, 640);
    tester.view.devicePixelRatio = 1.0;

    GoRouter.of(
      tester.element(find.byType(Navigator).first),
    ).go(AppRoutes.teacherAvailability);
    await settle(tester);
    expect(tester.takeException(), isNull, reason: 'availability 진입 렌더');

    // 요일 카드의 '+ 시간대 추가' CTA → ScheduleEditBottomSheet.
    final addSlot = find.text(AppStrings.weeklyScheduleAddSlotAction);
    expect(addSlot, findsWidgets, reason: '+ 시간대 추가 CTA');
    await tester.ensureVisible(addSlot.first);
    await settle(tester);
    await tester.tap(addSlot.first);
    await settle(tester);

    // 시트가 실제로 열렸는지 단언(false-green 방지).
    expect(
      find.byType(ScheduleEditBottomSheet),
      findsOneWidget,
      reason: 'ScheduleEditBottomSheet 가 열려야 함',
    );
    expect(
      tester.takeException(),
      isNull,
      reason: '주간 일정 편집 시트 렌더 오버플로우 없음 (#754 동형)',
    );
  });

  testWidgets('교사 특별일정(시간 예외) 추가 시트 — 좁은 높이(640) 렌더 오버플로우 없음', (tester) async {
    await bootAsRole(tester, DevAccount.teacher);
    tester.view.physicalSize = const Size(390, 640);
    tester.view.devicePixelRatio = 1.0;

    GoRouter.of(
      tester.element(find.byType(Navigator).first),
    ).go(AppRoutes.teacherAvailability);
    await settle(tester);

    final manageBtn = find.text(AppStrings.manageSpecialSchedules);
    expect(manageBtn, findsWidgets, reason: '특별 일정 관리 버튼');
    await tester.ensureVisible(manageBtn.first);
    await settle(tester);
    await tester.tap(manageBtn.first);
    await settle(tester);
    expect(tester.takeException(), isNull, reason: 'TimeExceptionScreen 진입 렌더');

    final addBtn = find.byTooltip('add');
    expect(addBtn, findsWidgets, reason: '+ 액션');
    await tester.tap(addBtn.last);
    await settle(tester);
    expect(
      tester.takeException(),
      isNull,
      reason: '시간 예외 추가 시트 렌더 오버플로우 없음 (#754 동형)',
    );
  });
}
