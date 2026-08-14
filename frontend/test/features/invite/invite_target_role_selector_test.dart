// #1267 — QR/코드 대상 역할 사전결정: InviteTargetRoleSelector 위젯 스모크 테스트
// (ux-rules.md HARD-GATE — top-level 위젯 신규 추가).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/invite/presentation/widgets/invite_target_role_selector.dart';
import 'package:lessonaza/features/profile/domain/entities/invite.dart';

void main() {
  testWidgets('3장의 대상 역할 카드를 모두 렌더링한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: InviteTargetRoleSelector(onSelect: (_) {})),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.inviteTargetRoleTeacherLabel), findsOneWidget);
    expect(find.text(AppStrings.inviteTargetRoleStudentLabel), findsOneWidget);
    expect(find.text(AppStrings.inviteTargetRoleParentLabel), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('카드를 탭하면 해당 대상 역할로 onSelect 가 호출된다', (tester) async {
    InviteTargetRole? selected;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: InviteTargetRoleSelector(onSelect: (role) => selected = role),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.inviteTargetRoleStudentLabel));
    await tester.pumpAndSettle();

    expect(selected, InviteTargetRole.student);
  });

  testWidgets('isLoading=true 이면 카드 탭이 무시된다', (tester) async {
    var callCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: InviteTargetRoleSelector(
            isLoading: true,
            onSelect: (_) => callCount++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.inviteTargetRoleTeacherLabel));
    await tester.pumpAndSettle();

    expect(callCount, 0);
  });
}
