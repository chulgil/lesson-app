import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/profile/domain/entities/invite.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_student_relation.dart';
import 'package:lessonaza/features/profile/presentation/extensions/profile_domain_visuals.dart';

void main() {
  group('Profile domain visuals', () {
    test('provides invite labels in the presentation layer', () {
      expect(InviteMethod.qrCode.label, 'QR 코드');
      expect(InviteMethod.urlLink.label, 'URL 링크');
      expect(InviteMethod.inviteCode.label, '초대 코드');
      expect(InviteMethod.inAppSearch.label, '앱 내 검색');

      expect(InviteStatus.active.label, '활성');
      expect(InviteStatus.used.label, '사용됨');
      expect(InviteStatus.expired.label, '만료됨');
      expect(InviteStatus.revoked.label, '취소됨');

      expect(InviteUserRole.teacher.label, '선생님');
      expect(InviteUserRole.student.label, '학생');
    });

    test('provides connection request labels in the presentation layer', () {
      expect(ConnectionRequestStatus.pending.label, '대기중');
      expect(ConnectionRequestStatus.accepted.label, '수락됨');
      expect(ConnectionRequestStatus.rejected.label, '거절됨');
      expect(ConnectionRequestStatus.cancelled.label, '취소됨');
      expect(ConnectionRequestStatus.expired.label, '만료됨');
    });

    test('formats invite expiration text in the presentation layer', () {
      final now = DateTime.now();

      expect(
        _invite(
          expiresAt: now.subtract(const Duration(minutes: 1)),
        ).formattedExpiry,
        '만료됨',
      );
      expect(
        _invite(expiresAt: now.add(const Duration(days: 2))).formattedExpiry,
        '1일 남음',
      );
      expect(
        _invite(expiresAt: now.add(const Duration(hours: 2))).formattedExpiry,
        '1시간 남음',
      );
      expect(
        _invite(expiresAt: now.add(const Duration(minutes: 2))).formattedExpiry,
        '1분 남음',
      );
      expect(
        _invite(
          expiresAt: now.add(const Duration(seconds: 20)),
        ).formattedExpiry,
        '곧 만료',
      );
    });

    test('provides relation lesson type labels in the presentation layer', () {
      expect(RelationLessonType.trial.label, '체험 레슨');
      expect(RelationLessonType.regular.label, '정기 레슨');
      expect(RelationLessonType.oneTime.label, '1회 추가 레슨');

      expect(RelationLessonType.trial.description, '첫 만남을 위한 1회 레슨');
      expect(RelationLessonType.regular.description, '매주 고정 시간 레슨');
      expect(RelationLessonType.oneTime.description, '단발성 추가 레슨');
    });

    test('provides relation status labels in the presentation layer', () {
      expect(RelationStatus.none.label, '처음 만남');
      expect(RelationStatus.active.label, '정규레슨 진행중');
      expect(RelationStatus.inactive.label, '이전 레슨 이력');
    });
  });
}

Invite _invite({required DateTime expiresAt}) {
  final now = DateTime.now();
  return Invite(
    id: 'invite-1',
    creatorId: 'teacher-1',
    creatorRole: InviteUserRole.teacher,
    inviteCode: '123456',
    inviteUrl: 'lessonaza://invite/123456',
    qrCodeData: 'lessonaza://invite/123456',
    createdAt: now,
    expiresAt: expiresAt,
  );
}
