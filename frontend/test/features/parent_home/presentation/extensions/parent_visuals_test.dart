import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/features/parent_home/domain/entities/parent.dart';
import 'package:lessonaza/features/parent_home/presentation/extensions/parent_home_domain_visuals.dart';

void main() {
  group('ParentVisuals', () {
    test('provides parent permission labels', () {
      expect(ParentPermission.viewOnly.label, '열람 전용');
      expect(ParentPermission.managePayments.label, '입금 상태 관리');
      expect(ParentPermission.manageLessons.label, '레슨 관리');
      expect(ParentPermission.fullAccess.label, '전체 권한');
    });

    test('provides parent status labels and colors', () {
      expect(ParentStatus.pending.label, '초대 대기');
      expect(ParentStatus.active.label, '활성');
      expect(ParentStatus.inactive.label, '비활성');

      expect(ParentStatus.pending.color, AppColors.paperAccent);
      expect(ParentStatus.active.color, AppColors.paperOk);
      expect(ParentStatus.inactive.color, AppColors.inkTertiary);
    });

    test('provides invitation source labels', () {
      expect(InvitationSource.student.label, '학생 초대');
      expect(InvitationSource.teacher.label, '선생님 초대');
    });
  });
}
