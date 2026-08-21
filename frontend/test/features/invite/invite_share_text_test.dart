// #1290 — 초대 공유 텍스트 분기: parent 대상 초대는 학부모 전용 템플릿을
// 사용해야 한다 (기존: 대상 역할과 무관하게 학생용 메시지 발송).

import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/invite/presentation/screens/invite_screen.dart';
import 'package:lessonaza/features/profile/domain/entities/invite.dart';

Invite _invite(InviteTargetRole? targetRole) => Invite(
  id: 'invite-1',
  creatorId: 'teacher-1',
  creatorRole: InviteUserRole.teacher,
  inviteCode: '654321',
  inviteUrl: 'lessonapp://invite/654321',
  qrCodeData: 'lessonapp://invite/654321',
  createdAt: DateTime(2026),
  expiresAt: DateTime(2027),
  targetRole: targetRole,
);

void main() {
  group('buildInviteShareText (#1290)', () {
    test('parent 대상 초대는 학부모 전용 메시지를 사용한다', () {
      final text = buildInviteShareText(
        _invite(InviteTargetRole.parent),
        roleText: AppStrings.teacher,
        senderName: '김선생',
        instruments: const ['바이올린'],
      );

      expect(text, contains(AppStrings.inviteParentShareHeader));
      expect(text, contains('654321'));
      expect(text, contains(AppStrings.inviteParentShareValidity));
    });

    test('student 대상 초대는 기존 일반 메시지를 유지한다', () {
      final text = buildInviteShareText(
        _invite(InviteTargetRole.student),
        roleText: AppStrings.teacher,
        senderName: '김선생',
        instruments: const ['바이올린'],
      );

      expect(text, contains('김선생'));
      expect(text, contains('lessonapp://invite/654321'));
      expect(text.contains(AppStrings.inviteParentShareHeader), isFalse);
    });

    test('targetRole 이 없는 레거시 초대도 일반 메시지를 유지한다', () {
      final text = buildInviteShareText(
        _invite(null),
        roleText: AppStrings.teacher,
      );

      expect(text, contains('654321'));
      expect(text.contains(AppStrings.inviteParentShareHeader), isFalse);
    });
  });
}
