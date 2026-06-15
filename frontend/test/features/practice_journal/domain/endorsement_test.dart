import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice_journal/domain/entities/endorsement.dart';
import 'package:lessonaza/features/practice_journal/domain/entities/guardian_seal.dart';

void main() {
  test('Endorsement 규칙: teacher=과제참조 필수, self=참조 없음', () {
    final t = Endorsement(
      by: EndorsedBy.teacher,
      date: DateTime.utc(2026, 6, 15),
      authorUserId: 't1',
      assignmentRef: 'a1',
      note: '왼손 천천히',
    );
    final s = Endorsement(
      by: EndorsedBy.self,
      date: DateTime.utc(2026, 6, 15),
      authorUserId: 's1',
      assignmentRef: null,
      note: '오늘 잘됨',
    );
    expect(t.isValid, isTrue);
    expect(s.isValid, isTrue);
    // teacher 인데 과제 참조 없음 → 무효
    expect(t.copyWith(clearAssignment: true).isValid, isFalse);
    // json 왕복
    expect(Endorsement.fromJson(t.toJson()).by, EndorsedBy.teacher);
    final seal = GuardianSeal(
      weekStart: DateTime.utc(2026, 6, 15),
      guardianUserId: 'p1',
      cheerNote: '잘했어',
    );
    expect(GuardianSeal.fromJson(seal.toJson()).guardianUserId, 'p1');
  });
}
