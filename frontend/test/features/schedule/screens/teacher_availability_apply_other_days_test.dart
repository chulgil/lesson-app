// "다른 요일에도 적용" — 시간대 추가 시트에서 같은 시간대를 다른 요일에도
// 한 번에 적용하는 흐름의 회귀 가드.
//
// teacher_availability_add_flow_test.dart 와 동일하게 **진짜 Mock repository**
// 를 통과하는 E2E 흐름으로 검증한다 (leaf provider override 로는 notifier/
// repository 경로가 우회되어 겹침 판정·스킵 로직을 검증할 수 없다).
//
// 시드(teacher_1): 화/목 14:00-18:00, 토 10:00-18:00. 월/수/금/일은 휴무.
// 시트 기본 시간은 14:00-18:00 — 화요일과 정확히 겹친다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/schedule/presentation/screens/teacher_availability_split_page.dart';
import 'package:lessonaza/features/schedule/presentation/widgets/schedule_edit_bottom_sheet.dart';

void main() {
  Future<void> pumpRealRepoSplitPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        // 의도적으로 override 없음 — MockTeacherAvailabilityRepository 실경로.
        child: MaterialApp(
          theme: AppTheme.light,
          home: const TeacherAvailabilitySplitPage(teacherId: 'teacher_1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 월요일 카드의 [시간대 추가] CTA로 시트를 연다 (preselectedDay=0, 기본
  /// 14:00-18:00 유지). [additionalDays]에 있는 요일 chip을 "다른 요일에도
  /// 적용" 섹션에서 선택한 뒤 [추가]를 탭한다.
  Future<void> addMondaySlotAndApplyToDays(
    WidgetTester tester, {
    required List<String> additionalDays,
  }) async {
    final addButtons = find.text('시간대 추가');
    expect(addButtons, findsWidgets, reason: 'CTA 가 렌더되어야 한다');
    await tester.tap(addButtons.first);
    await tester.pumpAndSettle();

    expect(find.byType(ScheduleEditBottomSheet), findsOneWidget);
    expect(
      find.text(AppStrings.weeklyScheduleApplyOtherDaysLabel),
      findsOneWidget,
      reason: '신규 추가 흐름에서는 "다른 요일에도 적용" 섹션이 보여야 한다',
    );

    for (final day in additionalDays) {
      final chip = find.widgetWithText(FilterChip, day);
      expect(chip, findsOneWidget, reason: '$day 요일 FilterChip 이 있어야 한다');
      await tester.tap(chip);
      await tester.pumpAndSettle();
    }

    final saveButton = find.widgetWithText(FilledButton, '추가');
    expect(saveButton, findsOneWidget);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
  }

  testWidgets('추가 요일을 선택하면 각 요일에 동일 시간대가 생성된다', (tester) async {
    await pumpRealRepoSplitPage(tester);

    // 시드: 화/목 14:00-18:00 (2건). 월/수/금/일 4개 요일이 휴무.
    expect(find.text('14:00 - 18:00'), findsNWidgets(2));
    expect(find.textContaining('· ${AppStrings.dayOff}'), findsNWidgets(4));

    // 월요일에 추가하면서 수/금 (둘 다 비어 있어 겹침 없음) 에도 적용.
    await addMondaySlotAndApplyToDays(tester, additionalDays: const ['수', '금']);

    expect(tester.takeException(), isNull);
    // 월 + 수 + 금 3곳에 새로 생겨 기존 화/목 2건과 합쳐 5건.
    expect(find.text('14:00 - 18:00'), findsNWidgets(5));
    // 4개 휴무 요일 중 3개(월/수/금)가 채워져 일요일만 남는다.
    expect(find.textContaining('· ${AppStrings.dayOff}'), findsNWidgets(1));
    // 3개 요일 모두 성공 — 성공 토스트가 뜬다.
    expect(
      find.text(AppStrings.weeklyScheduleAppliedToOtherDays(2)),
      findsOneWidget,
    );
  });

  testWidgets('추가 요일을 선택하지 않으면 기존 동작과 동일하다 (스낵바 없음)', (tester) async {
    await pumpRealRepoSplitPage(tester);

    expect(find.textContaining('· ${AppStrings.dayOff}'), findsNWidgets(4));

    await addMondaySlotAndApplyToDays(tester, additionalDays: const []);

    expect(tester.takeException(), isNull);
    // 월요일만 채워져 휴무 요일이 4 → 3.
    expect(find.textContaining('· ${AppStrings.dayOff}'), findsNWidgets(3));
    // "다른 요일" 관련 토스트는 전혀 뜨지 않는다 (기본 흐름 그대로).
    expect(
      find.text(AppStrings.weeklyScheduleAppliedToOtherDays(0)),
      findsNothing,
    );
    expect(find.textContaining('개 요일에'), findsNothing);
  });

  testWidgets('겹치는 요일은 건너뛰고 나머지는 정상 추가되며 스낵바로 안내한다', (tester) async {
    await pumpRealRepoSplitPage(tester);

    // 화요일은 이미 14:00-18:00 이 있어 정확히 겹친다 — 스킵 대상.
    // 수요일은 비어 있어 정상 추가된다.
    await addMondaySlotAndApplyToDays(tester, additionalDays: const ['화', '수']);

    expect(tester.takeException(), isNull);

    // 겹침 판정 대상인 화요일은 중복 생성되지 않는다: 화(기존)+목(기존)+
    // 월(신규)+수(신규) = 4건. 화가 중복됐다면 5건이 됐을 것.
    expect(find.text('14:00 - 18:00'), findsNWidgets(4));

    // 월/수 두 곳만 채워져 휴무 4 → 2 (화는 이미 휴무가 아니었으므로 무관).
    expect(find.textContaining('· ${AppStrings.dayOff}'), findsNWidgets(2));

    // 부분 성공 스낵바 — 1개 요일(수) 적용, 화요일은 겹쳐 제외.
    expect(
      find.text(AppStrings.weeklyScheduleAppliedWithSkipped(1, '화')),
      findsOneWidget,
    );
  });
}
