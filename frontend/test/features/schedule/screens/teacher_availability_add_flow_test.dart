// 2026-06-12 사용자 버그 재현 — "시간대 추가 눌러도 주간 레슨 시간에 반영 안 됨".
//
// 기존 split page 테스트는 leaf `teacherAvailabilityProvider` 만 override 해
// repo/notifier 경로를 우회한다. 이 테스트는 **진짜 Mock repository** 를 통과하는
// E2E 흐름으로 add 가 끊기는 지점을 자동 판정한다:
//
//   [시간대 추가] tap → 시트 → 요일 선택 → [저장] tap
//   → notifier.addWeeklySchedule → MockRepo → invalidate → 리스트 갱신
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/schedule/presentation/screens/teacher_availability_split_page.dart';
import 'package:lessonaza/features/schedule/presentation/widgets/schedule_edit_bottom_sheet.dart';

void main() {
  Future<void> pumpRealRepoSplitPage(
    WidgetTester tester, {
    required String teacherId,
  }) async {
    tester.view.physicalSize = const Size(1280, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        // 의도적으로 override 없음 — EnvironmentConfig.useMockData 기본 true
        // 이므로 MockTeacherAvailabilityRepository 실경로를 사용한다.
        child: MaterialApp(
          theme: AppTheme.light,
          home: TeacherAvailabilitySplitPage(teacherId: teacherId),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> addSlotViaSheet(
    WidgetTester tester, {
    required String day,
  }) async {
    // 첫 번째 [시간대 추가] CTA (월요일 카드) tap.
    final addButtons = find.text('시간대 추가');
    expect(addButtons, findsWidgets, reason: 'CTA 가 렌더되어야 한다');
    await tester.tap(addButtons.first);
    await tester.pumpAndSettle();

    // 시트가 떠야 한다.
    expect(
      find.byType(ScheduleEditBottomSheet),
      findsOneWidget,
      reason: '[시간대 추가] tap 이 시트를 띄워야 한다 (무반응 회귀 감지)',
    );

    // 요일 chip 선택 (시트 안의 chip).
    final chip = find.widgetWithText(ChoiceChip, day);
    expect(chip, findsOneWidget);
    await tester.tap(chip);
    await tester.pumpAndSettle();

    // [추가] tap (시트 confirm 버튼 — 신규는 AppStrings.add).
    final saveButton = find.widgetWithText(FilledButton, '추가');
    expect(
      saveButton,
      findsOneWidget,
      reason: '시트 confirm 버튼이 viewport 안에 있어야 한다',
    );
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
  }

  testWidgets('mock 시드 존재 (teacher_1) — 추가한 시간대가 리스트에 즉시 반영', (tester) async {
    await pumpRealRepoSplitPage(tester, teacherId: 'teacher_1');

    // 시드: 화/목/토 14:00-18:00 등. 월요일은 휴무.
    expect(find.text('14:00 - 18:00'), findsWidgets);

    await addSlotViaSheet(tester, day: '월');

    // 시트 기본 시간이 무엇이든, 월요일 카드에 새 행이 생겨 "휴무" 이
    // 사라져야 한다. (시트 기본 14:00-18:00 가정 — 시드와 동일 텍스트가
    // 1개 늘어난 것으로도 판정 가능하나, 휴무 라벨 감소가 더 견고)
    expect(tester.takeException(), isNull, reason: 'add 흐름에서 예외가 나면 안 된다');
    // 월요일이 더 이상 비어 있지 않음 — 휴무 라벨이 줄었는지 확인.
    // 시드에서 월/수/금/일 4개 요일이 휴무 → 추가 후 3개.
    expect(
      find.textContaining('· ${AppStrings.dayOff}'),
      findsNWidgets(3),
      reason: '월요일에 시간대가 추가되어 휴무 라벨이 4→3 으로 줄어야 한다',
    );
  });

  testWidgets('시드 없는 teacherId — 첫 추가가 기본값 생성으로 성공 (PR #701 회귀 가드)', (
    tester,
  ) async {
    await pumpRealRepoSplitPage(tester, teacherId: 'teacher_brand_new');

    // 레코드 없음 → 모든 요일 휴무 (7개).
    expect(find.textContaining('· ${AppStrings.dayOff}'), findsNWidgets(7));

    await addSlotViaSheet(tester, day: '월');

    expect(tester.takeException(), isNull);
    expect(
      find.textContaining('· ${AppStrings.dayOff}'),
      findsNWidgets(6),
      reason: '첫 설정 사용자도 추가 즉시 반영되어야 한다 (silent fail 금지)',
    );
  });
}
