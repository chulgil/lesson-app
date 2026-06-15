import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice_journal/domain/entities/practice_ledger.dart';
import 'package:lessonaza/features/practice_journal/domain/entities/practice_mark.dart';

void main() {
  test('도장은 (날짜)당 1개, full 이 short 갱신, 주간 카운트', () {
    var l = PracticeLedger.empty(childProfileId: 'c1', year: 2026, month: 6);
    l = l.upsertMark(DateTime.utc(2026, 6, 15), MarkIntensity.short);
    l = l.upsertMark(
      DateTime.utc(2026, 6, 15),
      MarkIntensity.full,
    ); // 같은 날 → 갱신
    expect(l.marks.length, 1);
    expect(l.marks.single.intensity, MarkIntensity.full);
    l = l.upsertMark(DateTime.utc(2026, 6, 16), MarkIntensity.short);
    expect(l.markCount, 2); // 누적(연속 아님)
  });
}
