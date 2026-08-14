// #1267 — QR/코드 대상 역할 사전결정: InviteConfirmScreen 이 target-role
// 불일치를 기존 "본인 코드는 사용할 수 없어요" 블록 패턴을 재사용해 차단하는지
// 검증. 학부모의 학생용 QR 대리 스캔(엣지 케이스) 을 포함한다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/auth/auth_facade.dart';
import 'package:lessonaza/features/invite/presentation/screens/invite_confirm_screen.dart';
import 'package:lessonaza/features/profile/domain/entities/invite.dart';
import 'package:lessonaza/features/profile/presentation/providers/invite_provider.dart';

// ---------------------------------------------------------------------------
// Stubs — mirrors invite_confirm_error_chain_test.dart's pattern.
// ---------------------------------------------------------------------------

class _FakeInviteRole extends CurrentInviteUserRole {
  _FakeInviteRole(this._role);
  final InviteUserRole _role;

  @override
  InviteUserRole build() => _role;
}

class _FakeUserId extends CurrentInviteUserId {
  @override
  String build() => 'user-1';
}

Invite _invite({
  required InviteUserRole creatorRole,
  InviteTargetRole? targetRole,
}) {
  return Invite(
    id: 'inv-1267',
    creatorId: 'teacher-1',
    creatorName: '김선생',
    creatorRole: creatorRole,
    inviteCode: 'ABC123',
    inviteUrl: 'lessonapp://invite/ABC123',
    qrCodeData: 'lessonapp://invite/ABC123',
    status: InviteStatus.active,
    expiresAt: DateTime(2027),
    createdAt: DateTime(2026),
    targetRole: targetRole,
  );
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required Invite invite,
  required InviteUserRole inviteRole,
  required UserRole actualRole,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentInviteUserRoleProvider.overrideWith(
          () => _FakeInviteRole(inviteRole),
        ),
        currentInviteUserIdProvider.overrideWith(() => _FakeUserId()),
        currentUserRoleProvider.overrideWith((ref) => actualRole),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              height: 900,
              child: InviteConfirmScreen(invite: invite),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('InviteConfirmScreen — target role mismatch (#1267)', () {
    testWidgets('학부모가 학생용 초대를 스캔하면 대상 불일치로 차단된다 (대리 가입 시도)', (tester) async {
      final invite = _invite(
        creatorRole: InviteUserRole.teacher,
        targetRole: InviteTargetRole.student,
      );

      await _pumpScreen(
        tester,
        invite: invite,
        // currentInviteUserRoleProvider maps parent -> student, so the
        // legacy self-code check alone would NOT catch this (student !=
        // teacher creator). Only the new target-role check does.
        inviteRole: InviteUserRole.student,
        actualRole: UserRole.parent,
      );

      expect(
        find.text(AppStrings.inviteTargetRoleMismatchTitle),
        findsOneWidget,
      );
      expect(
        find.text(
          AppStrings.inviteTargetRoleMismatchBodyFormat(
            AppStrings.inviteTargetRoleStudentLabel,
          ),
        ),
        findsOneWidget,
      );
      // The normal connect flow must not be offered.
      expect(find.text(AppStrings.inviteSendConnectionRequest), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('역할이 대상과 일치하면 정상 연결 요청 화면을 보여준다', (tester) async {
      final invite = _invite(
        creatorRole: InviteUserRole.teacher,
        targetRole: InviteTargetRole.student,
      );

      await _pumpScreen(
        tester,
        invite: invite,
        inviteRole: InviteUserRole.student,
        actualRole: UserRole.student,
      );

      expect(find.text(AppStrings.inviteSendConnectionRequest), findsOneWidget);
      expect(find.text(AppStrings.inviteTargetRoleMismatchTitle), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('레거시 초대(targetRole=null)는 기존 셀프코드 차단만 적용된다 (AC4)', (
      tester,
    ) async {
      final invite = _invite(creatorRole: InviteUserRole.teacher);

      await _pumpScreen(
        tester,
        invite: invite,
        // Legacy self-code case: scanner's invite-role equals the creator's.
        inviteRole: InviteUserRole.teacher,
        actualRole: UserRole.teacher,
      );

      // Existing self-code block, NOT the new target-mismatch copy.
      expect(find.text(AppStrings.inviteCannotConnect), findsOneWidget);
      expect(find.text(AppStrings.inviteTargetRoleMismatchTitle), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
