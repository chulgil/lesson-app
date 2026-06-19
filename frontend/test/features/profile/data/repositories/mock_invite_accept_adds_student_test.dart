// #848 — mock parity: accepting an app connection request must surface the
// connected student in the teacher roster (MockStudentRepository.getStudents),
// mirroring BE `_attach_student_to_teacher` (creates/attaches a Student on
// accept). Previously the dev mock created only the Connection → "성공인데
// 안보임".

import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/profile/data/repositories/mock_invite_repository.dart';
import 'package:lessonaza/features/profile/domain/entities/invite.dart';
import 'package:lessonaza/features/students/data/repositories/mock_student_repository.dart';

void main() {
  // The connection-attached roster is process-static — isolate every test.
  setUp(MockStudentRepository.resetConnectedStudents);
  tearDown(MockStudentRepository.resetConnectedStudents);

  test(
    'accepting a connection attaches the student to the teacher roster',
    () async {
      final invite = MockInviteRepository();
      final students = MockStudentRepository();

      const newStudentId = 'student-848c';

      // Before: roster does not contain the new student.
      final before = await students.getStudents();
      expect(before.any((s) => s.id == newStudentId), isFalse);

      // A student requests a connection to the teacher, then the teacher accepts.
      final request = await invite.createConnectionRequest(
        requesterId: newStudentId,
        requesterRole: InviteUserRole.student,
        targetId: 'teacher_1',
        targetRole: InviteUserRole.teacher,
        method: InviteMethod.inviteCode,
      );
      await invite.acceptConnectionRequest(request.id);

      // After: the connected student now appears in the roster.
      final after = await students.getStudents();
      expect(after.any((s) => s.id == newStudentId), isTrue);
    },
  );

  test('registering the same connected student twice is idempotent', () async {
    final students = MockStudentRepository();

    MockStudentRepository.registerConnectedStudent(
      studentId: 'dup-1',
      studentName: '학생',
    );
    MockStudentRepository.registerConnectedStudent(
      studentId: 'dup-1',
      studentName: '학생',
    );

    final list = await students.getStudents();
    expect(list.where((s) => s.id == 'dup-1').length, 1);
  });
}
