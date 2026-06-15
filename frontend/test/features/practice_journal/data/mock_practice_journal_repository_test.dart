import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice_journal/data/repositories/mock_practice_journal_repository.dart';
import 'package:lessonaza/features/practice_journal/domain/entities/endorsement.dart';
import 'package:lessonaza/features/practice_journal/domain/entities/guardian_seal.dart';
import 'package:lessonaza/features/practice_journal/domain/entities/practice_mark.dart';

void main() {
  test('업서트/주간 도장 중복 방지/무효 검인 거부', () async {
    final repo = MockPracticeJournalRepository();
    await repo.upsertMark('c1', DateTime.utc(2026, 6, 15), MarkIntensity.short);
    await repo.upsertMark('c1', DateTime.utc(2026, 6, 15), MarkIntensity.full);
    var l = await repo.getLedger('c1', 2026, 6);
    expect(l.marks.length, 1);
    expect(l.marks.single.intensity, MarkIntensity.full);

    final ws = DateTime.utc(2026, 6, 15);
    await repo.addGuardianSeal(
      'c1',
      GuardianSeal(weekStart: ws, guardianUserId: 'p1'),
    );
    await repo.addGuardianSeal(
      'c1',
      GuardianSeal(weekStart: ws, guardianUserId: 'p1', cheerNote: '재시도'),
    );
    l = await repo.getLedger('c1', 2026, 6);
    expect(l.seals.length, 1); // 주당 1개

    expect(
      () => repo.addEndorsement(
        'c1',
        Endorsement(
          by: EndorsedBy.teacher,
          date: DateTime.utc(2026, 6, 15),
          authorUserId: 't1',
          note: 'x',
        ),
      ), // 과제참조 없음 → 무효
      throwsArgumentError,
    );
  });
}
