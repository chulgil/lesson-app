// #660 C7 — ChildProfileActionsBottomSheet smoke test.
//
// 자녀 카드 destructive 메타포 부적합 → SwipeAction 미적용,
// 행 탭 → 본 BottomSheet 의 2 액션으로 통합.

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
  required VoidCallback onSwitchToChild,
  required VoidCallback onEditProfile,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ChildProfileActionsBottomSheet(
          profile: _profile(),
          onSwitchToChild: onSwitchToChild,
          onEditProfile: onEditProfile,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('2 액션 ListTile 노출 + 이름 표시', (tester) async {
    await _pump(tester, onSwitchToChild: () {}, onEditProfile: () {});

    expect(find.text('지우'), findsOneWidget);
    expect(
      find.text(AppStrings.childProfileActionsSwitchAccount),
      findsOneWidget,
    );
    expect(
      find.text(AppStrings.childProfileActionsEditProfile),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('학생 계정 전환 탭 → 콜백 호출', (tester) async {
    var switched = false;
    await _pump(
      tester,
      onSwitchToChild: () => switched = true,
      onEditProfile: () {},
    );

    await tester.tap(find.text(AppStrings.childProfileActionsSwitchAccount));
    await tester.pumpAndSettle();
    expect(switched, isTrue);
  });

  testWidgets('프로필 편집 탭 → 콜백 호출', (tester) async {
    var edited = false;
    await _pump(
      tester,
      onSwitchToChild: () {},
      onEditProfile: () => edited = true,
    );

    await tester.tap(find.text(AppStrings.childProfileActionsEditProfile));
    await tester.pumpAndSettle();
    expect(edited, isTrue);
  });
}
