// #660 C7 — ChildProfileActionsBottomSheet smoke test.
//
// 자녀 카드 destructive 메타포 부적합 → SwipeAction 미적용,
// 행 탭 → 본 BottomSheet 액션으로 통합.
// #749 — 미구현 '학생 계정 전환' no-op 액션 제거(편집 단일 액션).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/parent_home/domain/entities/child_profile.dart';
import 'package:lessonaza/features/parent_home/presentation/widgets/child_profile_actions_bottom_sheet.dart';

ChildProfile _profile() => ChildProfile(
  id: 'child-1',
  parentId: 'parent-1',
  name: '지우',
  birthYear: 2015,
  instrument: 'violin',
  level: 'beginner',
  profileColorKey: 'blue',
  createdAt: DateTime(2025, 1, 1),
);

Future<void> _pump(
  WidgetTester tester, {
  required VoidCallback onEditProfile,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ChildProfileActionsBottomSheet(
          profile: _profile(),
          onEditProfile: onEditProfile,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('편집 액션 노출 + 이름 표시, 미구현 계정전환 액션 제거(#749)', (tester) async {
    await _pump(tester, onEditProfile: () {});

    expect(find.text('지우'), findsOneWidget);
    expect(
      find.text(AppStrings.childProfileActionsEditProfile),
      findsOneWidget,
    );
    // #749: no-op '학생 계정 전환' 액션은 제거됨
    expect(
      find.text(AppStrings.childProfileActionsSwitchAccount),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('프로필 편집 탭 → 콜백 호출', (tester) async {
    var edited = false;
    await _pump(tester, onEditProfile: () => edited = true);

    await tester.tap(find.text(AppStrings.childProfileActionsEditProfile));
    await tester.pumpAndSettle();
    expect(edited, isTrue);
  });
}
