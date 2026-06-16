import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice_journal/data/repositories/mock_practice_journal_repository.dart';

void main() {
  group('BoundVolume 제본 (mock repository)', () {
    test('첫 제본은 volumeNo 1, 자녀별 1부터 증가', () async {
      final repo = MockPracticeJournalRepository();
      final v1 = await repo.bindVolume(
        childProfileId: 'c1',
        pieceId: 'p1',
        pieceName: '나비야',
      );
      final v2 = await repo.bindVolume(
        childProfileId: 'c1',
        pieceId: 'p2',
        pieceName: '작은별',
      );
      expect(v1.volumeNo, 1);
      expect(v2.volumeNo, 2);
      expect(v1.pieceName, '나비야');
    });

    test('같은 pieceId 재제본은 멱등 — 기존 완성본 반환, 권 수 불변', () async {
      final repo = MockPracticeJournalRepository();
      final first = await repo.bindVolume(
        childProfileId: 'c1',
        pieceId: 'p1',
        pieceName: '나비야',
      );
      final again = await repo.bindVolume(
        childProfileId: 'c1',
        pieceId: 'p1',
        pieceName: '나비야',
      );
      expect(again.volumeNo, first.volumeNo);
      final volumes = await repo.getBoundVolumes('c1');
      expect(volumes.length, 1);
    });

    test('volumeNo는 자녀 프로필별로 독립 (각자 1부터)', () async {
      final repo = MockPracticeJournalRepository();
      await repo.bindVolume(
        childProfileId: 'c1',
        pieceId: 'p1',
        pieceName: '나비야',
      );
      final childBFirst = await repo.bindVolume(
        childProfileId: 'c2',
        pieceId: 'p9',
        pieceName: '비행기',
      );
      expect(childBFirst.volumeNo, 1);
    });

    test('getBoundVolumes는 volumeNo 오름차순', () async {
      final repo = MockPracticeJournalRepository();
      await repo.bindVolume(
        childProfileId: 'c1',
        pieceId: 'p1',
        pieceName: 'A',
      );
      await repo.bindVolume(
        childProfileId: 'c1',
        pieceId: 'p2',
        pieceName: 'B',
      );
      await repo.bindVolume(
        childProfileId: 'c1',
        pieceId: 'p3',
        pieceName: 'C',
      );
      final volumes = await repo.getBoundVolumes('c1');
      expect(volumes.map((v) => v.volumeNo).toList(), [1, 2, 3]);
    });

    test('완성본 없는 자녀는 빈 목록', () async {
      final repo = MockPracticeJournalRepository();
      expect(await repo.getBoundVolumes('nobody'), isEmpty);
    });
  });
}
