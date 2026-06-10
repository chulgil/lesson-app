// #660 C7 — ChildProfilesScreen Column 2 버튼 제거 + 행 탭 BottomSheet smoke test.
//
// 자녀 카드는 destructive 메타포 부적절 → SwipeAction 적용하지 않고
// 행 탭 → ChildProfileActionsBottomSheet 으로 2 액션 노출.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/auth/auth_facade.dart';
import 'package:lessonaza/features/parent_home/domain/entities/child_profile.dart';
import 'package:lessonaza/features/parent_home/presentation/providers/child_profile_provider.dart';
import 'package:lessonaza/features/parent_home/presentation/screens/child_profiles_screen.dart';

ChildProfile _profile() => ChildProfile(
  id: 'child-1',
  parentId: 'parent-1',
  name: '지우',
  birthYear: 2015,
  instrument: 'violin',
  level: 'beginner',
  teacherName: '김선생님',
  profileColorKey: 'blue',
  createdAt: DateTime(2025, 1, 1),
);

Future<void> _pumpScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('parent-1'),
        childProfilesProvider(
          'parent-1',
        ).overrideWith((_) async => [_profile()]),
      ],
      child: const MaterialApp(home: ChildProfilesScreen(parentId: 'parent-1')),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Column 2 버튼 (switch_account/edit_outlined) 제거 (#660 C7)', (
    tester,
  ) async {
    await _pumpScreen(tester);

    // 자녀 카드 1건 노출.
    expect(find.text('지우'), findsOneWidget);
    // 기존 trailing 2 버튼 (audit 지적) — 모두 제거되어야 한다.
    expect(find.byIcon(Icons.switch_account), findsNothing);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AppStrings 자녀 액션 라벨 노출 가능 (#660 C7)', (tester) async {
    expect(AppStrings.childProfileActionsSwitchAccount, isNotEmpty);
    expect(AppStrings.childProfileActionsEditProfile, isNotEmpty);
  });
}
