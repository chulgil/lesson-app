import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/academy/data/repositories/mock_bulk_closure_repository.dart';
import 'package:lessonaza/features/academy/domain/entities/bulk_closure.dart';

/// Repository contract test for [MockBulkClosureRepository] (G15).
///
/// 정책 SSOT: docs/specs/web/academy/owner_bulk_closure_spec.md.
void main() {
  group('MockBulkClosureRepository', () {
    late MockBulkClosureRepository repo;
    final teacherMemberId = 'tm-1';
    final futureWindow = DateTime.now().add(const Duration(minutes: 50));
    final pastWindow = DateTime.now().subtract(const Duration(minutes: 5));

    BulkClosure makeClosure({
      String id = 'c1',
      ClosureStatus status = ClosureStatus.proposed,
      DateTime? endsAt,
      List<AffectedLesson> lessons = const [],
    }) {
      return BulkClosure(
        id: id,
        academyId: 'a1',
        closureDate: DateTime(2026, 8, 15),
        reason: '광복절 휴원',
        status: status,
        opinionWindowEndsAt: endsAt,
        affectedLessons: lessons,
      );
    }

    setUp(() {
      repo = MockBulkClosureRepository();
    });

    test('listByTeacherMember returns only registered closures', () async {
      repo.addClosure(teacherMemberId, makeClosure(id: 'c1'));
      repo.addClosure('other-teacher', makeClosure(id: 'c2'));

      final result = await repo.listByTeacherMember(teacherMemberId);

      expect(result, hasLength(1));
      expect(result.first.id, 'c1');
    });

    test('submitTeacherOpinion stores comment within window', () async {
      repo.addClosure(teacherMemberId, makeClosure(endsAt: futureWindow));

      await repo.submitTeacherOpinion('c1', '발표회와 겹칩니다');

      final updated = await repo.getById('c1');
      expect(updated?.teacherComment, '발표회와 겹칩니다');
    });

    test('submitTeacherOpinion throws when window expired', () async {
      repo.addClosure(teacherMemberId, makeClosure(endsAt: pastWindow));

      expect(() => repo.submitTeacherOpinion('c1', '의견'), throwsException);
    });

    test('submitTeacherOpinion throws when status != proposed', () async {
      repo.addClosure(
        teacherMemberId,
        makeClosure(status: ClosureStatus.applied, endsAt: futureWindow),
      );

      expect(() => repo.submitTeacherOpinion('c1', '의견'), throwsException);
    });

    test('submitMakeupSchedule updates lessons and flips to makeupCompleted '
        'when every lesson has a makeup time', () async {
      final lessons = [
        AffectedLesson(
          lessonId: 'L1',
          studentId: 's1',
          studentName: '박학생',
          originalStartAt: DateTime(2026, 8, 15, 14),
          originalEndAt: DateTime(2026, 8, 15, 15),
        ),
        AffectedLesson(
          lessonId: 'L2',
          studentId: 's2',
          studentName: '이학생',
          originalStartAt: DateTime(2026, 8, 15, 15),
          originalEndAt: DateTime(2026, 8, 15, 16),
        ),
      ];
      repo.addClosure(
        teacherMemberId,
        makeClosure(status: ClosureStatus.applied, lessons: lessons),
      );

      await repo.submitMakeupSchedule('c1', {
        'L1': DateTime(2026, 8, 22, 14),
        'L2': DateTime(2026, 8, 22, 15),
      });

      final updated = await repo.getById('c1');
      expect(updated?.status, ClosureStatus.makeupCompleted);
      expect(updated?.affectedLessons.every((l) => l.makeupAt != null), isTrue);
    });

    test('submitMakeupSchedule keeps status=applied when some lessons '
        'still have no makeup time', () async {
      final lessons = [
        AffectedLesson(
          lessonId: 'L1',
          studentId: 's1',
          studentName: '박학생',
          originalStartAt: DateTime(2026, 8, 15, 14),
          originalEndAt: DateTime(2026, 8, 15, 15),
        ),
        AffectedLesson(
          lessonId: 'L2',
          studentId: 's2',
          studentName: '이학생',
          originalStartAt: DateTime(2026, 8, 15, 15),
          originalEndAt: DateTime(2026, 8, 15, 16),
        ),
      ];
      repo.addClosure(
        teacherMemberId,
        makeClosure(status: ClosureStatus.applied, lessons: lessons),
      );

      await repo.submitMakeupSchedule('c1', {'L1': DateTime(2026, 8, 22, 14)});

      final updated = await repo.getById('c1');
      expect(updated?.status, ClosureStatus.applied);
    });

    test('submitMakeupSchedule throws when status != applied', () async {
      repo.addClosure(
        teacherMemberId,
        makeClosure(status: ClosureStatus.proposed, endsAt: futureWindow),
      );

      expect(() => repo.submitMakeupSchedule('c1', const {}), throwsException);
    });
  });
}
