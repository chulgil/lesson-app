import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice_journal/data/repositories/mock_practice_journal_repository.dart';
import 'package:lessonaza/features/practice_journal/domain/entities/practice_mark.dart';
import 'package:lessonaza/features/practice_journal/domain/journal_thresholds.dart';

// 헬퍼: durationMinutes → intensity (서비스가 쓰는 규칙을 단위로 검증)
MarkIntensity intensityFor(int minutes) =>
    minutes >= JournalThresholds.fullMinutes
        ? MarkIntensity.full
        : MarkIntensity.short;

void main() {
  test('연습 기록 시 자녀 장부에 도장 1개 파생(임계값으로 강도 결정)', () async {
    final journal = MockPracticeJournalRepository();
    final date = DateTime.utc(2026, 6, 15);
    // 서비스 훅이 호출할 동작을 직접 검증(통합은 위젯/통합테스트에서)
    await journal.upsertMark('c1', date, intensityFor(12)); // 12분 → full
    final l = await journal.getLedger('c1', 2026, 6);
    expect(l.marks.single.intensity, MarkIntensity.full);
    expect(intensityFor(3), MarkIntensity.short);
  });
}
