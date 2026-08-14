// #1267 — QR/코드 대상 역할 사전결정: InviteTargetRole 직렬화 + Invite
// null-compat (레거시 초대는 targetRole 미지정 필드로 계속 동작해야 한다).

import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/profile/domain/entities/invite.dart';

Invite _baseInvite({InviteTargetRole? targetRole}) {
  return Invite(
    id: 'invite-1',
    creatorId: 'teacher-1',
    creatorRole: InviteUserRole.teacher,
    inviteCode: '111111',
    inviteUrl: 'lessonapp://invite/111111',
    qrCodeData: 'lessonapp://invite/111111',
    createdAt: DateTime(2026, 1, 1),
    expiresAt: DateTime(2026, 1, 8),
    targetRole: targetRole,
  );
}

void main() {
  group('InviteTargetRole.wireValue', () {
    test('round-trips through fromWire for every value', () {
      for (final role in InviteTargetRole.values) {
        expect(InviteTargetRole.fromWire(role.wireValue), role);
      }
    });
  });

  group('InviteTargetRole.fromWire', () {
    test('null input -> null (legacy invite, no target field)', () {
      expect(InviteTargetRole.fromWire(null), isNull);
    });

    test('unknown value -> null (defensive, does not throw)', () {
      expect(InviteTargetRole.fromWire('academy_admin'), isNull);
    });

    test('"teacher" -> InviteTargetRole.teacher', () {
      expect(InviteTargetRole.fromWire('teacher'), InviteTargetRole.teacher);
    });

    test('"student" -> InviteTargetRole.student', () {
      expect(InviteTargetRole.fromWire('student'), InviteTargetRole.student);
    });

    test('"parent" -> InviteTargetRole.parent', () {
      expect(InviteTargetRole.fromWire('parent'), InviteTargetRole.parent);
    });
  });

  group('Invite.targetRole null-compat', () {
    test('defaults to null (legacy invites keep working untouched)', () {
      final invite = _baseInvite();
      expect(invite.targetRole, isNull);
    });

    test('copyWith(targetRole: ...) sets a target on a legacy invite', () {
      final invite = _baseInvite();
      final updated = invite.copyWith(targetRole: InviteTargetRole.student);
      expect(updated.targetRole, InviteTargetRole.student);
      // Surgical: nothing else changes.
      expect(updated.id, invite.id);
      expect(updated.inviteCode, invite.inviteCode);
    });

    test(
      'a target-role invite keeps its target through unrelated copyWith',
      () {
        final invite = _baseInvite(targetRole: InviteTargetRole.parent);
        final updated = invite.copyWith(useCount: 1);
        expect(updated.targetRole, InviteTargetRole.parent);
        expect(updated.useCount, 1);
      },
    );
  });
}
