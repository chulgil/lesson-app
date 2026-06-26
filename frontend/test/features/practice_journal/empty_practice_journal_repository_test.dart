import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice_journal/data/repositories/empty_practice_journal_repository.dart';
import 'package:lessonaza/features/practice_journal/domain/entities/endorsement.dart';
import 'package:lessonaza/features/practice_journal/domain/entities/guardian_seal.dart';
import 'package:lessonaza/features/practice_journal/domain/entities/practice_mark.dart';

/// #424: remote 모드 EmptyPracticeJournalRepository 의 변이 4종은 throw 하지 않고
/// no-op 으로 동작해야 한다. 이전엔 UnsupportedError 를 던져 recordPractice 본경로
/// (heatmap→journal→quest)의 quest bump 가 스킵되고 곡완성 archive 가 크래시했다.
void main() {
  late EmptyPracticeJournalRepository repo;
  setUp(() => repo = EmptyPracticeJournalRepository());

  test('upsertMark no-op — throw 하지 않는다', () async {
    await repo.upsertMark('c1', DateTime.utc(2026, 6, 11), MarkIntensity.full);
    await repo.upsertMark('c1', DateTime.utc(2026, 6, 12), MarkIntensity.short);
    // 여기 도달 = throw 없음 (이전엔 UnsupportedError)
  });

  test('addGuardianSeal / addEndorsement no-op', () async {
    await repo.addGuardianSeal(
      'c1',
      GuardianSeal(weekStart: DateTime.utc(2026, 6, 8), guardianUserId: 'g1'),
    );
    await repo.addEndorsement(
      'c1',
      Endorsement(
        by: EndorsedBy.teacher,
        date: DateTime.utc(2026, 6, 11),
        authorUserId: 't1',
        note: 'good',
      ),
    );
  });

  test('bindVolume 은 입력을 echo 한 BoundVolume 반환 (미영속 placeholder)', () async {
    final vol = await repo.bindVolume(
      childProfileId: 'c1',
      pieceId: 'p1',
      pieceName: '비발디 사계',
    );
    expect(vol.childProfileId, 'c1');
    expect(vol.pieceId, 'p1');
    expect(vol.pieceName, '비발디 사계');
    expect(vol.volumeNo, 0);
  });

  test('읽기는 빈 값 반환', () async {
    expect(await repo.getBoundVolumes('c1'), isEmpty);
  });
}
